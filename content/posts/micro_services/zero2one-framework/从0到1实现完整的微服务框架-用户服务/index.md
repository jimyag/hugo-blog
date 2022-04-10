---
title: 从0到1实现完整的微服务框架-用户服务
tags:
  - 微服务
  - gRPC
categories:
  - - 微服务
  - - gRPC
slug: ../../dc2dadae
date: 2022-03-25 20:42:57
series: [ "从0到1实现完整的微服务框架" ] 
---

本篇主要介绍实现用户服务中的相关内容。

<!--more-->

## 开始

新建项目

```sh
mkdir shop
cd shop
mkdir api,docs,service
```

本项目采用的是分层的微服务架构，api主要是对外提供的http接口，docs放相关的文档，service主要提供对内的grpc服务。

```shell
shop
├── api
│   └── user-api	// 用户服务的api
│       ├── api		// http接口
│       ├── config	// 相关配置文件的go内容
│       ├── global	// 全局变量 数据库连接
│       ├── initialize	// 初始化相关的
│       ├── middlewares	// 中间件
│       ├── proto	// proto文件
│       ├── router	// 路由
│       └── util
│   
├── docs
│   └── service
└── service
    └── user_srv
        ├── config	// 配置文件
        ├── db		// 数据库相关的
        │   ├── migration	// 数据库同步
        │   └── query		// curd	的 SQL 语句
        ├── global	// 全局变量
        ├── handler	// 服务处理
        ├── initialize
        ├── model	// 数据库表结构对应的model
        ├── proto	
        └── util
```

## 用户表结构

进入`service/user_srv`初始化mod

```	shell
go mod init github.com/jimyag/shop/service/user
```

用户信息中要包含一下信息

```sql
CREATE TABLE "user"
(
    "id"         bigserial PRIMARY KEY, -- 自增id
    "created_at" timestamptz    NOT NULL DEFAULT (now()), -- 信息创建时间
    "updated_at" timestamptz    NOT NULL DEFAULT (now()), -- 信息修改时间
    "deleted_at" timestamptz             DEFAULT null,  -- 信息删除时间， 这是的删除使用的是软删除，只是给用户信息打个标记，提示该用户已经被删除了
    "email"      varchar UNIQUE NOT NULL,	-- 邮件
    "password"   varchar        NOT NULL,	-- 密码
    "nickname"   varchar        NOT NULL,	-- 昵称
    "gender"     varchar(6)     NOT NULL DEFAULT 'male',	-- 性别
    "role"       int8           NOT NULL DEFAULT 1		-- 权限
);
CREATE INDEX ON "user" ("email");

COMMENT ON COLUMN "user"."email" IS 'user email';

COMMENT ON COLUMN "user"."password" IS 'user password';

COMMENT ON COLUMN "user"."nickname" IS 'user nickname default email';

COMMENT ON COLUMN "user"."gender" IS 'male man ,female women';

COMMENT ON COLUMN "user"."role" IS '1 user 2 admin';

```

进入`user-srv/db`文件，执行

```shell
migrate create -ext sql -dir migration -seq init_schema_user
D:\repository\shop\service\user_srv\db\migration\000001_init_schema_user.up.sql
D:\repository\shop\service\user_srv\db\migration\000001_init_schema_user.down.sql
```

生成同步表结构,

将上述的`sql`语句写入到`shop\service\user_srv\db\migration\000001_init_schema_user.up.sql`中，

在`shop\service\user_srv\db\migration\000001_init_schema_user.down.sql`中写入

```shell
DROP TABLE IF EXISTS "user";
```

`up`是用来同步数据库

`down`是用来回滚数据库

### 创建user数据库

相关文档会在`docs`中进行更新，推荐保存下来用到的各个端口，以防后面冲突。

```shell
docker run --name shop-user -p 35432:5432 -e POSTGRES_PASSWORD=postgres -e TZ=PRC -d postgres:14-alpine
```

创建用户数据库

```shell
docker exec -it shop-user createdb --username=postgres --owner=postgres shop
```

删除用户数据库的命令

```shell
docker exec -it shop-user dropdb  --username=postgres shop
```

### 数据库迁移

生成用户表，

```shell
migrate -path db/migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up
```

删除用户表，（如果可以用到的话）

```shell
migrate -path db/migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose down
```

### 生成curd代码

在wsl中 初始化

```shell
docker run --rm -v /mnt/d/repository/shop/service/user_srv:/src -w /src kjconroy/sqlc init
```

在生成的`sqlc.yaml`中写入

```yaml
version: 1
packages:
  - path: "./model" # 生成go 代码的位置
    name: "model"  # 生成 go package 的名字
    engine: "postgresql" # 使用的数据库引擎
    schema: "./db/migration/" # 迁移表的sql语句 我们使用migrate中的up文件
    queries: "./db/query" # CRUD的sql
    emit_json_tags: true  # 添加json在生成的struct中
    emit_prepared_queries: false
    emit_interface: true # 生成接口
    emit_exact_table_names: false # 表名是否带s
```

在`shop\service\user_srv\db\query\user.sql`curd的SQL语句

```sql
-- name: CreateUser :one
INSERT INTO "user"(email,
                   password,
                   nickname,
                   gender,
                   role)
VALUES ($1, $2, $3, $4, $5)
returning *;

-- name: GetUserById :one
SELECT *
FROM "user"
WHERE id = $1
LIMIT 1;

-- name: GetUserByEmail :one
SELECT *
FROM "user"
WHERE email = $1
LIMIT 1;

-- name: ListUsers :many
select *
from "user"
where deleted_at IS NULL
order by id
limit $1 offset $2;


-- name: DeleteUser :execrows
update "user"
set deleted_at =$2
where id = $1
  and deleted_at is null;

-- name: UpdateUser :one
update "user"
set updated_at = $1,
    nickname   = $2,
    gender     = $3,
    role       = $4,
    password   = $5
where id = $6
returning *;
```

生成curd代码

```shell
docker run --rm -v /mnt/d/repository/shop/service/user_srv:/src -w /src kjconroy/sqlc generate
```

这里的`/mnt/d/repository/shop/service/user_srv`是我当前项目的所在的位置

这时，会在`shop\service\user_srv\model`中生成四个文件。

```shell
├── db.go
├── models.go
├── querier.go
├── user.sql.go
```

### 测试连接数据库

在`shop\service\user_srv\model`新建文件夹`main/main.go`

`shop\service\user_srv\model\main\main.go`

```go
package main

import (
	"context"
	"database/sql"
	"log"

	_ "github.com/lib/pq"

	"github.com/jimyag/shop/service/user/model"
)

const (
	DbDriver = "postgres" // 数据库的驱动
	DbSource = "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" // 数据库的链接
    // 驱动://用户名:密码@数据库的地址:端口号/数据库名称？sslmode=disable   
)

func main() {
	db, err := sql.Open(DbDriver, DbSource)
	if err != nil {
		log.Fatalln("cannot connect to db :", err)
	}
	log.Println("connect db ....")
	sqlStore := model.NewSqlStore(db)
	user, err := sqlStore.GetUserByEmail(context.Background(), "jimyag1@126.com")
	log.Println(user)
}
```

### 测试生成的curd代码

在`shop\service\user_srv\model`新建两个文件，`main_test.go`,`user.sql_test.go`

```shell
.
├── db.go
├── main
│   └── main.go
├── main_test.go
├── models.go
├── querier.go
├── user.sql.go
└── user.sql_test.go
```

这两个是为了测试生成的curd代码是否正确。

`shop/service/user_srv/model/main_test.go`中添加一下内容，这里是一个main测试，在当前包中所有的测试之前都会执行这个方法。

```go
package model

import (
	"database/sql"
	"log"
	"os"
	"testing"

	_ "github.com/lib/pq"
)

const (
	DbDriver = "postgres"
	DbSource = "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable"
)

var (
	testQueries *Queries
	testDB      *sql.DB
)

func TestMain(m *testing.M) {
	var err error
	testDB, err = sql.Open(DbDriver, DbSource)
	if err != nil {
		log.Fatalln("cannot connect to db :", err)
	}
	testQueries = New(testDB)
	log.Println("connect db success....")
	// m.Run() 返回一个退出的代码，告诉我们测试是否通过
	// 使用 os.Exit() 将测试的结果报告给测试运行程序
	os.Exit(m.Run())
}
```

为了测试随机生成相关的用户名密码性别，我们可以创建一个测试的工具包`shop\service\user_srv\util\test_util\test_util.go`

```go
package test_util

import (
	"crypto/sha512"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/anaskhan96/go-password-encoder"
)

const (
	alphabet = "abcdefghijklmopqrstuvwxyz"
)

var (
	Options = &password.Options{SaltLen: 16, Iterations: 100, KeyLen: 32, HashFunction: sha512.New}
)

func init() {
	// 设置随机数种子
	rand.Seed(time.Now().UnixNano())
}

func RandomString(n int) string {
	var sb strings.Builder
	k := len(alphabet)

	for i := 0; i < n; i++ {
		c := alphabet[rand.Intn(k)]
		sb.WriteByte(c)
	}
	return sb.String()
}
func RandomInt(min, max int64) int64 {
	return min + rand.Int63n(max-min+1)
}

func RandomEmail() string {
	return fmt.Sprintf("jimyag%s@126.com", RandomString(3))
}

type Password struct {
	RawPassword       string
	Slat              string
	EncryptedPassword string
}

func RandomPassword() (p Password) {
	rawPassword := RandomString(10)
	slat, encryptedPassword := password.Encode(rawPassword, Options)
	p = Password{
		RawPassword:       rawPassword,
		Slat:              slat,
		EncryptedPassword: fmt.Sprintf("$pbkdf2-sha512$%s$%s", slat, encryptedPassword),
	}
	return
}

func RandomNickName() string {
	return fmt.Sprintf("jimyag%s", RandomString(5))
}

func RandomGender() string {
	gender := []string{"male", "female", "middle"}
	n := len(gender)
	return gender[rand.Intn(n)]
}
```

这里随机生成的`password`我们之后再做说明。

在`shop\service\user_srv\model\user.sql_test.go`添加，执行测试。

```go
package model

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/jimyag/shop/service/user/util/test_util"
)

func createRandomUser(t *testing.T) (User, test_util.Password) {
	p := test_util.RandomPassword()
	arg := CreateUserParams{
		Email:    test_util.RandomEmail(),
		Password: p.EncryptedPassword,
		Nickname: test_util.RandomNickName(),
		Gender:   test_util.RandomGender(),
		Role:     0,
	}
	user, err := testQueries.CreateUser(context.Background(), arg)

	require.NoError(t, err)
	require.NotEmpty(t, user)

	require.Equal(t, arg.Email, user.Email)
	require.Equal(t, arg.Password, user.Password)
	require.Equal(t, arg.Role, user.Role)
	require.Equal(t, arg.Gender, user.Gender)
	require.Equal(t, arg.Nickname, user.Nickname)

	require.NotZero(t, user.ID)
	require.NotZero(t, user.CreatedAt)
	require.NotZero(t, user.UpdatedAt)

	return user, p
}

func TestQueries_CreateUser(t *testing.T) {
	user, _ := createRandomUser(t)
	arg := CreateUserParams{
		Email:    user.Email,
		Password: user.Password,
		Nickname: user.Nickname,
		Gender:   user.Gender,
		Role:     user.Role,
	}
	// 再次创建用户会失败
	newUser, err := testQueries.CreateUser(context.Background(), arg)
	require.Error(t, err)
	require.Empty(t, newUser)
}
... 其余详细的测试代码见 https://github.com/jimyag/shop/blob/master/service/user_srv/model/user.sql_test.go
```

到这里我们数据库方面的都已经测试好了。

### 关于用户密码的加密

我们使用一个随机的盐并加密用户的密码，在保存用户密码时，可以保存加密的算法，盐值、加密后的密码。例如

`$pbkdf2-sha512$ScHj3WqUbGWBx0i5$a777173035ac06d8557b603593b49d26961c4cd1d2adaeff`

并且这几个要用特殊的标志分隔开。

这样可以保证每一个用户的盐都是随机的，生成的密码更安全。

## 定义用户proto

在`shop\service\user_srv\proto`中新建`user.proto`文件，并写入以下内容。

```protobuf
syntax = "proto3";

option go_package = ".;proto";

service User{
  rpc GetUserList(PageIngo) returns(UserListResponse){}; // 获得用户列表
  rpc GetUserByEmail(EmailRequest) returns(UserInfoResponse){}; // 使用邮箱获得用户信息
  rpc GetUserById(IdRequest) returns(UserInfoResponse){}; // 使用Id获得用户信息
  rpc CreateUser(CreateUserRequest)returns(UserInfoResponse){}; // 添加用户
  rpc UpdateUser(UpdateUserRequest)returns(UserInfoResponse){}; // 更新用户信息
  rpc CheckPassword(PasswordCheckInfo) returns(CheckPasswordResponse){}; //检查用户密码
}

message PasswordCheckInfo{
  string password = 1;
  string encryptedPassword = 2;
}

message CheckPasswordResponse{
  bool success = 1;
}

message UpdateUserRequest{
  int32 id = 1;
  string email = 2;
  string password = 3;
  string nickname = 4;
  string gender = 5;
  int32 role = 6;
}

message CreateUserRequest{
  string email = 1;
  string password = 2;
  string nickname = 3;
  string gender = 4;
  int32 role = 5;
}

message EmailRequest{
  string email = 1;
}

message IdRequest{
  uint32 id = 1;
}

message PageIngo{
  uint32 pageNum = 1;
  uint32 pageSize = 2;
}

message UserInfoResponse{
  int32 id = 1;
  int64 created_at = 2;
  int64 updated_at = 3;
  string email = 4;
  string password = 5;
  string nickname = 6;
  string gender = 7;
  int32 role = 8;
}

message UserListResponse{
  int32 total = 1;
  repeated UserInfoResponse data = 2;
}
```

生成用户的pb文件。在`shop\service\user_srv\proto`中执行

```shell
protoc -I . user.proto --go_out=plugins=grpc:.
```

即可在当前文件夹(`shop\service\user_srv\proto`)下生成`user.pb.go`

`user.pb.go`的文件中，有server和client要实现的接口

```go
// client 要实现的接口
type UserClient interface {
	GetUserList(ctx context.Context, in *PageIngo, opts ...grpc.CallOption) (*UserListResponse, error)
	GetUserByEmail(ctx context.Context, in *EmailRequest, opts ...grpc.CallOption) (*UserInfoResponse, error)
	GetUserById(ctx context.Context, in *IdRequest, opts ...grpc.CallOption) (*UserInfoResponse, error)
	CreateUser(ctx context.Context, in *CreateUserRequest, opts ...grpc.CallOption) (*UserInfoResponse, error)
	UpdateUser(ctx context.Context, in *UpdateUserRequest, opts ...grpc.CallOption) (*UserInfoResponse, error)
	CheckPassword(ctx context.Context, in *PasswordCheckInfo, opts ...grpc.CallOption) (*CheckPasswordResponse, error)
}
// server要实现的接口
// UserServer is the server API for User service.
type UserServer interface {
	GetUserList(context.Context, *PageIngo) (*UserListResponse, error)
	GetUserByEmail(context.Context, *EmailRequest) (*UserInfoResponse, error)
	GetUserById(context.Context, *IdRequest) (*UserInfoResponse, error)
	CreateUser(context.Context, *CreateUserRequest) (*UserInfoResponse, error)
	UpdateUser(context.Context, *UpdateUserRequest) (*UserInfoResponse, error)
	CheckPassword(context.Context, *PasswordCheckInfo) (*CheckPasswordResponse, error)
}
```

## 实现grpc用户的相关接口

在实现grpc生成的用户接口之前，我们首先封装数据库。

在`shop\service\user_srv\model`新建`store.go`文件，

定义一个store的接口，这个是方便之后实现不同的存储。可以使用内存做存储，也可以使用数据库，当然我们这里使用的是数据库做存储。

```go
type Store interface {
	CreateUserTx(ctx context.Context, arg CreateUserParams) (User, error)
	UpdateUserTx(ctx context.Context, arg UpdateUserParams) (User, error)
	Querier
}
```

`CreateUserTx`和`UpdateUserTx`对应的是创建用户和更新用户的事务，在此过程要执行多个SQL操作，我们用事务进行封装。

`Querier`是生成curd的接口。

定义一个SQLstore，并且实现store的接口，代码如下，完整的代码见[store.go)](https://github.com/jimyag/shop/blob/master/service/user_srv/model/store.go)

```go
package model

import (
   "context"
   "database/sql"
   "fmt"
   "time"

   "google.golang.org/grpc/codes"
   "google.golang.org/grpc/status"
)

type Store interface {
   CreateUserTx(ctx context.Context, arg CreateUserParams) (User, error)
   UpdateUserTx(ctx context.Context, arg UpdateUserParams) (User, error)
   Querier
}

type SqlStore struct {
   *Queries
   db *sql.DB
}

func NewSqlStore(db *sql.DB) Store {
   return &SqlStore{
      Queries: New(db),
      db:      db,
   }
}

// 这是一个执行事务的方法，如果在执行中遇到错误，会自动回滚。
func (store *SqlStore) execTx(ctx context.Context, fn func(queries *Queries) error) error {
   tx, err := store.db.BeginTx(ctx, nil)
   if err != nil {
      return err
   }

   q := New(tx)
   err = fn(q)
   if err != nil {
      if rbErr := tx.Rollback(); rbErr != nil {
         return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
      }
      return err
   }

   return tx.Commit()
}

func (store *SqlStore) CreateUserTx(ctx context.Context, arg CreateUserParams) (User, error) {
	... https://github.com/jimyag/shop/blob/master/service/user_srv/model/store.go
}

func (store *SqlStore) UpdateUserTx(ctx context.Context, arg UpdateUserParams) (User, error) {
    .... 省略，https://github.com/jimyag/shop/blob/master/service/user_srv/model/store.go
}
```

### 实现grpc的接口

实现grpc时，我们需要一个结构体`UserServer`，在实现这些接口的时候，我们需要用到`数据库`相关的操作，还还记得我们之前封装的接口`Store`嘛，这时候，就可以把它匿名传入。

在`shop\service\user_srv\handler`中新建文件`user.go`并写入一下内容grpc的接口，这边只实现一个稍微复杂的，其余的可以参考这个复杂的或者在[shop/user.go ](https://github.com/jimyag/shop/blob/master/service/user_srv/handler/user.go)中查看。

```go
package handler

import (
	"context"
	"crypto/sha512"
	"strings"
	"time"

	"github.com/anaskhan96/go-password-encoder"
	"github.com/opentracing/opentracing-go"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/jimyag/shop/service/user/model"
	"github.com/jimyag/shop/service/user/proto"
)

type UserServer struct {
	model.Store
}

// 将userModel转换为UserInfo的响应
func userModel2UserInfoResponse(user model.User) *proto.UserInfoResponse {
	return &proto.UserInfoResponse{
		Id:        int32(user.ID),
		CreatedAt: user.CreatedAt.Unix(),
		UpdatedAt: user.UpdatedAt.Unix(),
		Email:     user.Email,
		Password:  user.Password,
		Nickname:  user.Nickname,
		Gender:    user.Gender,
		Role:      int32(user.Role),
	}
}

func (u *UserServer) GetUserList(ctx context.Context, req *proto.PageIngo) (*proto.UserListResponse, error) {
    ....
}
func (u *UserServer) GetUserByEmail(ctx context.Context, req *proto.EmailRequest) (*proto.UserInfoResponse, error) {
	...
}
func (u *UserServer) GetUserById(ctx context.Context, req *proto.IdRequest) (*proto.UserInfoResponse, error) {
	...
}
func (u *UserServer) CreateUser(ctx context.Context, req *proto.CreateUserRequest) (*proto.UserInfoResponse, error) {
	...
}
func (u *UserServer) UpdateUser(ctx context.Context, req *proto.UpdateUserRequest) (*proto.UserInfoResponse, error) {
    // 拿到请求过来的信息，组成更新用户的参数
	arg := model.UpdateUserParams{
		UpdatedAt: time.Now(),
		Nickname:  req.GetNickname(),
		Gender:    req.GetGender(),
		Role:      int64(req.GetRole()),
		Password:  req.Password,
		ID:        int64(req.Id),
	}
    // 执行更新用户的事务，如果有错误就返回相应的错误。
	// 已经处理过错误了
	user, err := u.Store.UpdateUserTx(ctx, arg)
	if err != nil {
		return nil, err
	}
    // 如果没有错所谓就将响应返回
	rsp := userModel2UserInfoResponse(user)
	return rsp, nil
}
func (u *UserServer) CheckPassword(ctx context.Context, req *proto.PasswordCheckInfo) (*proto.CheckPasswordResponse, error) {
	options := &password.Options{SaltLen: 16, Iterations: 100, KeyLen: 32, HashFunction: sha512.New}
	encryptedPasswordInfo := strings.Split(req.GetEncryptedPassword(), "$")
	check := password.Verify(req.Password, encryptedPasswordInfo[2], encryptedPasswordInfo[3], options)
	return &proto.CheckPasswordResponse{Success: check}, nil
}

```

### 测试grpc接口

在`shop\service\user_srv\main.go`创建一个服务端。

```go
package main

import (
	"flag"
	"fmt"
	"github.com/jimyag/shop/service/user/golbal"
	"github.com/jimyag/shop/service/user/handler"
	"github.com/jimyag/shop/service/user/model"
	"github.com/jimyag/shop/service/user/proto"
	"google.golang.org/grpc"
	"log"
	"net"
)

func main() {
    // 默认地址是本地地址:50051端口
	IP := flag.String("ip", "0.0.0.0", "ip地址")
	Port := flag.Int("port", 50051, "端口号")
	flag.Parse()
	log.Printf("server ready run %s:%d.....", *IP, *Port)

    // grpc的server
	server := grpc.NewServer()
	sqlStore := model.NewSqlStore(golbal.DB)
    // user的server
	userServer := handler.UserServer{Store: sqlStore}
    // 将userServer注册到grpcServer上
	proto.RegisterUserServer(server, &userServer)
    // 监听端口
	lis, err := net.Listen("tcp", fmt.Sprintf("%s:%d", *IP, *Port))
	if err != nil {
		log.Fatalf("cannot listen %s:%d.....\n", *IP, *Port)
	}
    // server 启动
	err = server.Serve(lis)
	if err != nil {
		log.Fatalf("cannot run server.....")
	}
	log.Printf("server running %s:%d.....", *IP, *Port)
}
```

在`shop\service\user_srv\handler`新建两个grpc的测试文件

```go
package handler

import (
	"log"
	"os"
	"testing"

	"google.golang.org/grpc"

	"github.com/jimyag/shop/service/user/proto"
)

var (
	userClient proto.UserClient
)

const (
	target = "127.0.0.1:50051"
)

func TestMain(m *testing.M) {
	conn, err := grpc.Dial(target, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("cannot dial %s :%v\n", target, err)
	}
	userClient = proto.NewUserClient(conn)

	log.Printf("dial %s success....\n", target)
	os.Exit(m.Run())
}
```

```go
package handler

import (
	"context"
	"fmt"
	"testing"

	"github.com/anaskhan96/go-password-encoder"
	"github.com/stretchr/testify/require"

	"github.com/jimyag/shop/service/user/proto"
	"github.com/jimyag/shop/service/user/util/test_util"
)

func createUser(t *testing.T) (*proto.UserInfoResponse, test_util.Password) {
	p := test_util.RandomPassword()
	request := proto.CreateUserRequest{
		Email:    test_util.RandomEmail(),
		Password: p.EncryptedPassword,
		Nickname: test_util.RandomNickName(),
		Gender:   test_util.RandomGender(),
		Role:     0,
	}
	rsp, err := userClient.CreateUser(context.Background(), &request)
	require.NoError(t, err)
	require.NotEmpty(t, rsp)

	require.Equal(t, request.Email, rsp.GetEmail())
	require.Equal(t, request.Password, rsp.GetPassword())
	require.Equal(t, request.Nickname, rsp.GetNickname())
	require.Equal(t, request.Gender, rsp.GetGender())
	require.Equal(t, request.Role, rsp.GetRole())
	return rsp, p
}

func TestUserServer_CreateUser(t *testing.T) {
	rsp, p := createUser(t)
	request := proto.CreateUserRequest{
		Email:    rsp.GetEmail(),
		Password: p.EncryptedPassword,
		Nickname: rsp.GetNickname(),
		Gender:   rsp.GetGender(),
		Role:     0,
	}
	newRsp, err := userClient.CreateUser(context.Background(), &request)
	require.Error(t, err)
	require.Empty(t, newRsp)
}

func TestUserServer_GetUserById(t *testing.T) {
    ... https://github.com/jimyag/shop/tree/master/service/user_srv/handler
}

func TestUserServer_GetUserByEmail(t *testing.T) {
	...https://github.com/jimyag/shop/tree/master/service/user_srv/handler
}

func TestUserServer_GetUserList(t *testing.T) {
	...https://github.com/jimyag/shop/tree/master/service/user_srv/handler
}

func TestUserServer_UpdateUser(t *testing.T) {
	...https://github.com/jimyag/shop/tree/master/service/user_srv/handler
}

func TestUserServer_CheckPassword(t *testing.T) {
	...https://github.com/jimyag/shop/tree/master/service/user_srv/handler
}
```

到这里grpc相关的逻辑就已经实现完了。

目前的目录结构如下。

```shell
.
├── config
├── db
│   ├── migration
│   │   ├── 000001_init_schema_user.down.sql
│   │   └── 000001_init_schema_user.up.sql
│   └── query
│       └── user.sql
├── global
├── go.mod
├── go.sum
├── handler
│   ├── main_test.go
│   ├── user.go
│   └── user_test.go
├── initialize
├── main.go
├── model
│   ├── db.go
│   ├── main
│   │   └── main.go
│   ├── main_test.go
│   ├── models.go
│   ├── querier.go
│   ├── store.go
│   ├── user.sql.go
│   └── user.sql_test.go
├── proto
│   ├── user.pb.go
│   └── user.proto
├── sqlc.yaml
└── util
    └── test_util
        └── test_util.go
```

### 问题

#### 设计一个通用的用户模型

如果让你设计一个用户服务具备通用性，比如可以让所有的系统都可以公共代码?但是不同的系统在user表上可能会有不同的字段，如何设计表让系统具备通用性的同时还能具备好的扩展性?

##### 思路

1. 基本上所有的系统用户都需要用户名和密码、登录时间等，这些可以设计成一张通用表。
2. 如何可以扩展表并且不会对现有的表产生影响?

##### 拓展

扩展接口,比如将-整套的用户服务完善好, 把一整套的用户相关接口都自己实现好。

#### 设计一个生成基本service微服务脚手架

自己写一个exe文件可以使得生成基本的service微服务脚手架，这个脚本可以在启动的时候让用户输入一些信息,你觉得有哪些信息可以通过用户输入进行配置?

- 某些库可以选择。
- 选择注册中心

##### 思路点拨

1. 对于service和web端来说,两种代码的目录结构会不一致,所以该命令行可以支持两种类型。
2. 比如后期可以考虑服务名称、否支持服务注册等都考虑进去

##### 进一步思考

命令行模式基本是微服务中必备的，go-micro和go-zero等解决方案都支持通过命令行生成模板目录,大家自
己也应该考虑后期处于维护的角度去长期维护这个脚本,随着以后自己的项目越来越完善，这个命令行业需要跟
着升级

## 实现用户服务的web层服务

用户`api`层的目录如下

```shell
├── api
│   └── user-api	// 用户服务的api
│       ├── api		// http接口
│       ├── config	// 相关配置文件的go内容
│       ├── global	// 全局变量 数据库连接
│       ├── initialize	// 初始化相关的
│       ├── middlewares	// 中间件
│       ├── proto	// proto文件
│       ├── router	// 路由
│       └── util
```

首先我们将之前`shop\service\user_srv\proto`文件夹中的文件`user.pb.go`和`user.proto`复制到`shop\api\user-api\proto`。这里把之前的proto文件复制过来是因为在客户端中还要继续使用proto文件中内容，这里有个问题就说如果api端修改了proto文件，那么grpc server端也要修改相应的proto文件。当然大家把api和srv放在一起也是可以的，这就要看个人的喜好了。其实把api和srv放在一起更好一点。

这个等我们再把第一个服务完成之后，我们会将这个两个合在一起。

### 使用全局的zaplogger

在global`shop\api\user-api\global\global.go`中定义全局的logger

```go
package global

import (
    "go.uber.org/zap"
)

var (
    Logger           *zap.Logger
)
```

#### 初始化logger

在`shop\api\user-api\initialize\logger.go`初始化`global.Logger`

```go
package initialize

import (
	"log"

	"go.uber.org/zap"

	"github.com/jimyag/shop/api/user/global"
)

func InitLogger() {
	var err error
	global.Logger, err = zap.NewProduction()
	if err != nil {
		log.Fatalf("初始化 logger 失败 :%v\n", err)
	}

	global.Logger.Info("初始化 logger 成功.....")
}
```

之后就可以在在项目中使用`global.Logger`来打日志了。

### 连接到grpc的服务端

在global`shop\api\user-api\global\global.go`中定义全局的用户client

```go
package global

import (
    "go.uber.org/zap"
    
	"github.com/jimyag/shop/api/user/proto"
)

var (
    Logger           *zap.Logger
	UserSrvClient    proto.UserClient
)
```

#### 初始化userclient

在`shop\api\user-api\initialize\src_conn.go`中添加初始化userclient的代码

```go
package initialize

import (
	"fmt"
	"go.uber.org/zap"
	"google.golang.org/grpc"

	"github.com/jimyag/shop/api/user/global"
	"github.com/jimyag/shop/api/user/proto"
	"github.com/jimyag/shop/api/user/util/otgrpc"
)

func InitSrvConnOld1() {
	var userSrvHost string = "localhost"
	var userSrvPort int = 50051
    
	userConn, err := grpc.Dial(fmt.Sprintf("%s:%d",
		userSrvHost,
		userSrvPort),
		grpc.WithInsecure())
	if err != nil {
		global.Logger.Fatal("用户服务连接失败", zap.String("err", err.Error()))
	}
	// 已经事先建立好连接，后续就不用在此tcp三次握手
	// 一个连接多个gor 共用，grpc 的连接池
	// todo 连接池
	global.UserSrvClient = proto.NewUserClient(userConn)
}
```

### 编写第一个http接口

在`shop\api\user-api\api\user.go`中填写获得用户列表的接口

```go
package api

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/jimyag/shop/api/user/global"
	"github.com/jimyag/shop/api/user/proto"
)

// 这里是用来grpc中的错误的
func HandleGrpcErrorToHttp(err error, ctx *gin.Context) {
	if err == nil {
		return
	}
    // 这里使用了grpc自己状态码，在grpc中不用我们自己维护状态码了
	if e, ok := status.FromError(err); ok {
		switch e.Code() {
		case codes.NotFound:
			ctx.JSON(http.StatusNotFound, gin.H{
				"msg": e.Message(),
			})
		case codes.Internal:
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"msg": "内部错误",
			})
		default:
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"msg": "未知错误",
			})
		}

	}
}

func GetUserList(ctx *gin.Context) {
    // 写死的获得第一页的五个人的信息（从第一页开始）
	rsp, err := global.UserSrvClient.GetUserList(ctx, &proto.PageIngo{
		PageNum:  1,
		PageSize: 5,
	})
	if err != nil {
		fmt.Println(err)
		global.Logger.Error("查询用户列表失败")
		HandleGrpcErrorToHttp(err, ctx)
		return
	}
	result := make([]interface{}, 0)
	for _, datum := range rsp.Data {
		data := make(map[string]interface{})
		data["id"] = datum.Id
		data["nickname"] = datum.Nickname
		data["gender"] = datum.Gender
		data["email"] = datum.Email
		data["role"] = datum.Role
		result = append(result, data)
	}
    // 包装响应
	ctx.JSON(http.StatusOK, gin.H{
		"data": result,
	})
}
```

### 初始化路由

在`shop\api\user-api\router`中新建文件`user.go`初始化user的路由

```go
package router

import (
	"github.com/gin-gonic/gin"

	"github.com/jimyag/shop/api/user/api"
)

func InitUserRouter(router *gin.RouterGroup) {
	userRouter := router.Group("user")
	{
		userRouter.GET("list", api.GetUserList)
	}
}
```

在全局路由中注册`shop\api\user-api\initialize\router.go`

```go
package initialize

import (
	"github.com/gin-gonic/gin"

	router2 "github.com/jimyag/shop/api/user/router"
)

func Routers() *gin.Engine {
	router := gin.Default()
	apiGroup := router.Group("/user/v1")
	router2.InitUserRouter(apiGroup)
	return router
}
```

### 测试运行

`shop\api\user-api\main.go`

```go
package main

import (
	"fmt"

	"go.uber.org/zap"

	"github.com/jimyag/shop/api/user/global"
	"github.com/jimyag/shop/api/user/initialize"
)

func main() {
	initialize.InitLogger()
	initialize.InitSrvConn()
	// 初始化router
	router := initialize.Routers()
	err := router.Run(fmt.Sprintf("127.0.0.1:%d", 8888))
	if err != nil {
		zap.L().Info("启动失败")
		return
	}
}
```

现在我们第一个http的接口就已经写好了，其余的http的接口均在[user-api](https://github.com/jimyag/shop/tree/master/api/user-api)

## 使用viper加载配置文件

在上述内容中，我们看到许多的配置文件都是写死的，万一我们的配置的端口发送变动，这时候就要挨个改配置文件，很是麻烦，我们可以将这些配置写入到指定的配置文件中去。

在`shop\api\user-api\config\config.go`中

```go
package config

// user grpc 服务的配置
type UserSrvConfig struct {
	Host     string `mapstructure:"host"`
	HostPort int    `mapstructure:"host-port"`
	Name     string `mapstructure:"name"`
}
// 用户http服务的配置
type ServerInfo struct {
	Name       string        `mapstructure:"name"`
	Port       int           `mapstructure:"port"`
	UserSrv    UserSrvConfig `mapstructure:"user-srv"`
}
```

在`shop\api\user-api\config-debug.yaml`和`shop\api\user-api\config-release.yaml`中写入

```yaml
name: 'user-api'
port: 8021

user-srv:
  host: '192.168.0.2'
  host-port: 50051
  name: "user-srv"
```

这里将开发环境和线上环境进行隔离开，可以通过读取环境变量来判断是开发环境还是线上环境，这里开发环境和线上环境的配置是相同的。

在全局变量文件`shop\api\user-api\global\global.go`中添加

```go
ServerConfig     *config.ServerInfo
```

初始化加载配置文件`shop\api\user-api\initialize\config.go`

```go
package initialize

import (
	"fmt"

	"github.com/fsnotify/fsnotify"
	"github.com/spf13/viper"
	_ "github.com/spf13/viper/remote"
	"go.uber.org/zap"

	"github.com/jimyag/shop/api/user/global"
)
// 加载环境变量
func getEnvBool(env string) bool {
	viper.AutomaticEnv()
	return viper.GetBool(env)
}

// LoadConfigInfo 加载本地的 consul 文件
func LoadConfigInfo() {
    // 默认是读取线上环境的配置
	configFilePath := "config-release.yaml"
    // 如果环境变量中"shop_debug"为true就读取开发环境配置
    if getEnvBool("shop_debug"){
        configFilePath := "config-debug.yaml"
    }
	v := viper.New()
	v.SetConfigFile(configFilePath)
	if err := v.ReadInConfig(); err != nil {
		global.Logger.Fatal("加载配置文件失败.....",
			zap.Error(err),
			zap.String("path", configFilePath),
		)
	}

	global.Logger.Info("配置加载成功....",
		zap.String("path", configFilePath),
	)
	if err := v.Unmarshal(&global.ServerConfig ); err != nil {
		global.Logger.Fatal("解析配置文件失败....",
			zap.Error(err),
			zap.String("path", configFilePath),
		)
	}
	global.Logger.Info("成功加载配置文件",
		zap.String("path", configFilePath),
		zap.Any("content", global.ServerConfig ),
	)
    // 这里做的是监听配置文件的变化，变化之后的操作。
	v.WatchConfig()
	v.OnConfigChange(func(in fsnotify.Event) {
		global.Logger.Info("配置文件产生变化....",
			zap.String("name", in.String()),
			zap.String("path", configFilePath),
		)

		if err := v.ReadInConfig(); err != nil {
			global.Logger.Fatal("修改的配置文件字段出错",
				zap.String("field", in.String()),
				zap.Error(err),
			)
		}
		if err := v.Unmarshal(&global.ServerConfig); err != nil {
			global.Logger.Fatal("解析配置文件出错",
				zap.String("field", in.String()),
				zap.Error(err),
			)
		}
		global.Logger.Info("配置文件内容", zap.Any("config", global.ServerConfig))
	})
}
```

现在我们就可以将用到的所有的配置都可以使用`global.ServerConfig .XXX`来代替了。这里的替换不做过多说明。

在`shop\api\user-api\main.go`中记得要初始化全局的配置文件。

```go
initialize.InitLogger()
// 变更的从这里开始
initialize.LoadConfigInfo()
// 这里结束
initialize.InitSrvConn()
```

## 表单数据验证

在写登录接口之前我们首先要处理表单验证，表单验证可以提前帮助我们优雅判断传入的数据是否合法。

### 定义验证结构体

首先我们`shop\api\user-api\model\request\user.go`新建使用邮件和密码登录参数

```go
package request

// 这里的validate标签就代表是要进行验证，label是我们自定义的标签，可以在之后的翻译中使用。
type PasswordLoginForm struct {
	Email    string `json:"email" validate:"required,email" label:"邮件"`
	Password string `json:"password" validate:"required,min=6,max=20" label:"您的密码"`
}
```

### 初始化翻译器

在使用表单验证的时候需要用到`Translator和validator.Validate`我们在全局变量`shop\api\user-api\global\global.go`中声明他们

```go
import (
    ut "github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
)
var(
    // 增加的 其余的省略
    Trans            ut.Translator
	Validate         *validator.Validate
)
```

由于在做验证的时候我们首先要初始化这两个全局变量，在`shop\api\user-api\initialize\validator.go`初始化包

```go
package initialize

import (
	"reflect"

	"github.com/go-playground/locales/zh"
	ut "github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
	zhtranslations "github.com/go-playground/validator/v10/translations/zh"

	"github.com/jimyag/shop/api/user/global"
)

func InitValidateAndTrans() {
	global.Validate = validator.New()
    // 第一个是备用翻译，后面的才是主要的翻译
	uni := ut.New(zh.New(), zh.New())
	var ok bool
    // 拿到中文的翻译器
	global.Trans, ok = uni.GetTranslator("zh")
	if !ok {
		global.Logger.Error("得到翻译器失败...")
	}
    // 将翻译器注册
	err := zhtranslations.RegisterDefaultTranslations(global.Validate, global.Trans)
	if err != nil {
		global.Logger.Error("注册翻译器失败......")
	}
    // 这里是我们自定义的标签名的翻译，可以更好展示错误信息，
    // 比如定义一个结构体字段，role 权限，如果不定义自己标签进行说明，对看的人不友好。
	global.Validate.RegisterTagNameFunc(func(field reflect.StructField) string {
		label := field.Tag.Get("label")
		return label
	})
	global.Logger.Info("翻译器注册成功......")
}
```

### 验证逻辑

在初始翻译相关的之后，我们就可以验证了。在`shop\api\user-api\util\validate\validator.go`中

```go
package validate

import (
	"github.com/go-playground/validator/v10"

	"github.com/jimyag/shop/api/user/global"
)
// 由于我们传进来的都是结构体，所有我们就用结构体进行验证
func Validate(data interface{}) (interface{}, error) {

	err := global.Validate.Struct(data)
	if err != nil {
        // 如果有错误，就将他断言为validator的错误
		errs, ok := err.(validator.ValidationErrors)
		if ok {
            // 将多余的信息去掉
			errMsg := make([]interface{}, 0)
			for _, fieldError := range errs {
				errMsg = append(errMsg, fieldError.Translate(global.Trans))
			}
			return errMsg, err

        }else{
            return errs,err
        }
	}
	return nil, nil
}

```

### 如何使用

在`shop\api\user-api\api\user.go`继续写入

```go
// 省略其余的
import	"github.com/jimyag/shop/api/user/util/validate"

func PasswordLogin(ctx *gin.Context) {
	passwordLoginForm := request.PasswordLoginForm{}
	if err := ctx.ShouldBindJSON(&passwordLoginForm); err != nil {
		global.Logger.Info("ssss")
	}
    // 获得传来的数据之后，直接验证
	msg, e := validate.Validate(passwordLoginForm)
	if e != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": msg,
		})
	} else {
        .... 省略其余的逻辑，之后再写
		ctx.JSON(http.StatusOK, gin.H{
			"msg": "成功",
		})
	}
	return
}
```

### 封装统一的响应

在之前我们的响应都是通过`ctx.JSON(http.StatusOK, gin.H{"msg": "成功",})`来实现的，这里我们将其封装一下。

在`shop\api\user-api\model\response\common.go`封装

```go
package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)
// 响应的结构体
type Response struct {
	Code int         `json:"code"`
	Data interface{} `json:"data"`
	Msg  interface{} `json:"msg"`
}
// 成功或者失败
const (
	SUCCESS = 0
	ERROR   = 500
)

var codeMsg = map[int]string{
	SUCCESS: "成功",
	ERROR:   "失败",
}

func getErrMsg(code int) string {
	return codeMsg[code]
}
// 无论成功或者失败都是http.StatusOK
func result(code int, data interface{}, msg interface{}, context *gin.Context) {
	context.JSON(http.StatusOK, Response{
		code,
		data,
		msg,
	})
}

func Ok(context *gin.Context) {
	result(SUCCESS, nil, getErrMsg(SUCCESS), context)
}
func Fail(context *gin.Context) {
	result(ERROR, nil, getErrMsg(ERROR), context)
}

func OkWithData(data interface{}, context *gin.Context) {
	result(SUCCESS, data, getErrMsg(SUCCESS), context)
}
.... 省略
```

对于处理grpc的错误的方法也进行封装

`shop\api\user-api\util\handle_grpc_error\handle_grpc_error.go`

```go
package handle_grpc_error

import (
	"github.com/gin-gonic/gin"
	"google.golang.org/grpc/status"

	"github.com/jimyag/shop/api/user/model/response"
)

func HandleGrpcErrorToHttp(err error, ctx *gin.Context) {
	if err == nil {
		return
	}
	if e, ok := status.FromError(err); ok {
		response.FailWithMsg(e.Message(), ctx)
	}
}
```

以使用邮箱和密码登录为例子，我们可以这样实现

```go
func PasswordLogin(ctx *gin.Context) {
	passwordLoginForm := request.PasswordLoginForm{}
	_ = ctx.ShouldBindJSON(&passwordLoginForm)

	msg, e := validate.Validate(passwordLoginForm)
	if e != nil {
		response.FailWithMsg(msg, ctx)
		return
	}

	user, err := global.UserSrvClient.GetUserByEmail(ctx, &proto.EmailRequest{Email: passwordLoginForm.Email})
	if err != nil {
		response.FailWithMsg("用户不存在", ctx)
		return
	}
	checkP := proto.PasswordCheckInfo{
		Password:          passwordLoginForm.Password,
		EncryptedPassword: user.GetPassword(),
	}
	password, err := global.UserSrvClient.CheckPassword(ctx, &checkP)
	if err != nil {
		response.FailWithMsg("登录失败", ctx)
		return
	}
	if !password.GetSuccess() {
		response.FailWithMsg("邮箱或密码错误", ctx)
		return
	}
    // todo 没有完成
	response.OkWithMsg("登录成功", ctx)
}
```

其余的响应可以一起改了

## PASETO认证

在登录的时候，我们需要保存用户的状态，这里使用PASETO进行认证。用户登录成功之后就颁发token

对于用户的状态我们要保存`uid,role`，除此之外还有过期签发时间，过期时间。

我们声明载体`shop\api\user-api\util\paseto\payload.go`

```go
package paseto

import (
	"errors"
	"time"
)

// Different types of error returned by the VerifyToken function
var (
	ErrInvalidToken = errors.New("token is invalid")
	ErrExpiredToken = errors.New("token has expired")
)

type Payload struct {
	IssuedAt  time.Time
	ExpiredAt time.Time
	UID       int32
	Nickname  string
	Role      int32
}

// NewPayload creates a new token payload with a specific username and duration
func NewPayload(uid int32, nickname string, role int32) (*Payload, error) {

	payload := &Payload{
		UID:      uid,
		Nickname: nickname,
		Role:     role,
	}
	return payload, nil
}

// Valid checks if the token payload is valid or not
func (payload *Payload) Valid() error {
	if time.Now().After(payload.ExpiredAt) {
		return ErrExpiredToken
	}
	return nil
}

```

PASETO的使用很简单只要两个方法就能实现验证。`shop\api\user-api\util\paseto\paseto.go`

```go
package paseto

import (
	"crypto/ed25519"
	"time"

	"github.com/o1egl/paseto"
)

// PasetoMaker is a PASETO token maker
type PasetoMaker struct {
	pastor     *paseto.V2
	privateKey ed25519.PrivateKey
	publicKey  ed25519.PublicKey
	duration   time.Duration
}

// NewPasetoMaker creates a new PasetoMaker
func NewPasetoMaker(privateKey ed25519.PrivateKey, publicKey ed25519.PublicKey, duration time.Duration) (*PasetoMaker, error) {
	maker := &PasetoMaker{
		pastor:     paseto.NewV2(),
		privateKey: privateKey,
		publicKey:  publicKey,
		duration:   duration,
	}
	return maker, nil
}

// CreateToken creates a new token for a specific username and duration
func (maker *PasetoMaker) CreateToken(payload *Payload) (string, error) {
	payload.IssuedAt = time.Now()
	payload.ExpiredAt = time.Now().Add(time.Hour * maker.duration)
	token, err := maker.pastor.Sign(maker.privateKey, payload, nil)
	return token, err
}

// VerifyToken checks if the token is valid or not
func (maker *PasetoMaker) VerifyToken(token string) (*Payload, error) {
	payload := &Payload{}

	err := maker.pastor.Verify(token, maker.publicKey, payload, nil)
	if err != nil {
		return nil, ErrInvalidToken
	}
	if payload.Valid() != nil {
		return nil, err
	}
	return payload, nil
}
```

这里使用的是一种非对称加密的方式，私钥负责颁发，公钥负责校验。

从配置文件加载公钥私钥以及过期时间省略，由于我们一直要用到签发token和校验token的，把它加到全局变量中。

之后在登录的逻辑中`shop\api\user-api\api\user.go:func PasswordLogin(ctx *gin.Context)`

```go
	// todo 没有完成
	payload, _ := paseto.NewPayload(user.Id, user.Nickname, user.Role)
	token, err := global.PasetoMaker.CreateToken(payload)
	if err != nil {
		global.Logger.Info("创建Token失败", zap.Error(err))
		response.FailWithMsg("登录失败，请稍后", ctx)
		return
	}
	res := make(map[string]string)
	res["token"] = token
	response.OkWithDataMsg(res, "登录成功", ctx)
```

这时候，对于获取用户信息的请求，我们就需要做认证了。

使用中间件进行拦截。

`shop\api\user-api\middlewares\paseto.go`

```go
package middlewares

import (
	"errors"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/jimyag/shop/api/user/global"
	"github.com/jimyag/shop/api/user/model/response"
	"github.com/jimyag/shop/api/user/util/paseto"
)

func Paseto() gin.HandlerFunc {
	return func(context *gin.Context) {
        // 使用的是bearer token的格式
		tokenHeader := context.Request.Header.Get("Authorization")
		if tokenHeader == "" {
			response.FailWithMsg("token 无效", context)
			context.Abort()
			return
		}
        // 解析
		check := strings.SplitN(tokenHeader, " ", 2)
		if len(check) != 2 && check[0] != "Bearer" {
			response.FailWithMsg("token 格式错误", context)
			context.Abort()
			return
		}
		payload, err := global.PasetoMaker.VerifyToken(check[1])
		if errors.Is(err, paseto.ErrInvalidToken) {
			response.FailWithMsg("token 格式错误", context)
			context.Abort()
			return
		} else if errors.Is(err, paseto.ErrExpiredToken) {
			response.FailWithMsg("token 过期", context)
			context.Abort()
			return
		}
		context.Set("payload", payload)
	}
}
```


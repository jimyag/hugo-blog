---
title: 从0到1实现完整的微服务框架-库存服务
tags:
  - 微服务
  - gRPC
categories:
  - - 微服务
  - - gRPC
slug: ../../c501f7ad
date: 2022-03-31 16:21:29
series: [ "从0到1实现完整的微服务框架" ] 
---

在分布式系统中，数据一致性是非常重要。在此项目中库存的增减也有同样的问题。

<!--more-->

## 快速启动库存服务

复制之前的`用户服务`的代码，

### 生成表结构

```shell
$migrate create -ext sql -dir migration -seq init_schema_inventory
D:\repository\shop\service\inventory_srv\db\migration\000001_init_schema_inventory.up.sql
D:\repository\shop\service\inventory_srv\db\migration\000001_init_schema_inventory.down.sql
```

复制生成的表结构到up文件中

```sql
CREATE TABLE "inventory"
(
    "id"         bigserial PRIMARY KEY,
    "created_at" timestamptz NOT NULL DEFAULT (now()),
    "updated_at" timestamptz NOT NULL DEFAULT (now()),
    "deleted_at" timestamptz          DEFAULT null,
    "goods"      integer     NOT NULL,
    "sticks"     integer     NOT NULL,
    "version"    integer     NOT NULL
);

CREATE INDEX ON "inventory" ("goods");

```

`down`

```sql
DROP TABLE IF EXISTS "inventory";
```



### 创建inventory数据库

```shell
docker run --name shop-inventory -p 35433:5432 -e POSTGRES_PASSWORD=postgres -e TZ=PRC -d postgres:14-alpine
3536ecfbb483a64fadaa9e3e253c50b1082dbd71b290f7b36ebd2276c8a74dce
```

### 创建数据库

```shell
docker exec -it shop-inventory createdb --username=postgres --owner=postgres shop
```

### 删除数据库

```shell
docker exec -it shop-inventory dropdb  --username=postgres shop
```

### 数据库迁移

```shell
migrate -path db/migration -database "postgresql://postgres:postgres@localhost:35433/shop?sslmode=disable" -verbose up
2022/03/30 22:27:06 Start buffering 1/u init_schema_inventory
2022/03/30 22:27:06 Read and execute 1/u init_schema_inventory
2022/03/30 22:27:06 Finished 1/u init_schema_inventory (read 15.2808ms, ran 22.4171ms)
2022/03/30 22:27:06 Finished after 61.9324ms
2022/03/30 22:27:06 Closing source and database

```

```shell
migrate -path db/migration -database "postgresql://postgres:postgres@localhost:35433/shop?sslmode=disable" -verbose down
2022/03/30 22:26:59 Are you sure you want to apply all down migrations? [y/N]
y
2022/03/30 22:27:01 Applying all down migrations
2022/03/30 22:27:01 Start buffering 1/d init_schema_inventory
2022/03/30 22:27:01 Read and execute 1/d init_schema_inventory
2022/03/30 22:27:01 Finished 1/d init_schema_inventory (read 9.3861ms, ran 15.3116ms)
2022/03/30 22:27:01 Finished after 1.9435943s
2022/03/30 22:27:01 Closing source and database
```

### 生成curd代码

在wsl中 初始化

```shell
root@Jimyag:/mnt/c/Users/jimyag# docker run --rm -v /mnt/d/repository/shop/service/inventory_srv:/src -w /src kjconroy/sqlc init
```

写入如下

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

在`./db/query`中写入

```sql
-- name: CreateInventory :one
INSERT INTO "inventory"(goods,
                        sticks,
                        version)
VALUES ($1, $2, $3)
returning *;

-- name: GetInventoryByGoodsID :one
SELECT *
FROM "inventory"
WHERE goods = $1
LIMIT 1;


-- name: UpdateInventory :one
update "inventory"
set updated_at = $1,
    sticks     = sticks + sqlc.arg(counts)
where goods = $2
returning *;
```

生成curd代码

```shell
docker run --rm -v /mnt/d/repository/shop/service/inventory_srv:/src -w /src kjconroy/sqlc generate
```

### protoc生成go代码

```protobuf
syntax = "proto3";
option go_package = ".;proto";

service inventory{
  rpc SetInv(GoodInvInfo) returns(Empty);// 设置库存
  rpc InvDetail(GoodInvInfo) returns(GoodInvInfo);// 获取库存信息
  rpc Sell(SellInfo)returns(Empty) ; // 库存扣减
  rpc Rollback(SellInfo) returns(Empty);// 归还库存
}
message SellInfo{
  repeated GoodInvInfo goodsInfo = 1;
}
message GoodInvInfo{
  int32 goodsId = 1;
  int32 num = 2;
}
message Empty {}
```

cd到.proto文件

```shell
protoc -I . inventory.proto --go_out=plugins=grpc:.
```

### 封装数据库curd

`shop\service\inventory_srv\model\store.go`

```go
package model

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"go.uber.org/zap"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/jimyag/shop/service/inventory/global"
	"github.com/jimyag/shop/service/inventory/proto"
)

type Store interface {
	SetInvTx(ctx context.Context, arg CreateInventoryParams) (Inventory, error)
	SellTx(ctx context.Context, arg *proto.SellInfo) error
	RollBackTx(ctx context.Context, arg *proto.SellInfo) error
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

func (store *SqlStore) SetInvTx(ctx context.Context, arg CreateInventoryParams) (Inventory, error) {
	var inventory Inventory
	var err error
	err = store.execTx(ctx, func(queries *Queries) error {
		inventory, err = queries.GetInventoryByGoodsID(ctx, arg.Goods)
		if err != nil {
			if err == sql.ErrNoRows {
				// 没有找到
				inventory, err = queries.CreateInventory(ctx, arg)
				return nil
			} else {
				global.Logger.Error("", zap.Error(err))
				return status.Error(codes.Internal, "内部错误")
			}
		}
		global.Logger.Info("", zap.Any("", inventory))
		// 找到了

		updateArg := UpdateInventoryParams{
			UpdatedAt: time.Now(),
			Goods:     inventory.Goods,
			Counts:    arg.Sticks,
		}
		inventory, err = queries.UpdateInventory(ctx, updateArg)
		return err
	})

	return inventory, err
}

func (store *SqlStore) SellTx(ctx context.Context, arg *proto.SellInfo) error {
	// 本地事务  要不都卖，要不都不卖
	// 拿到所有的商品，
	// 		判断是否有库存
	// 		判断库存是否够
	// 		扣减库存 - 库存 会出现数据不一致的问题
	err := store.execTx(ctx, func(queries *Queries) error {
		var inventory Inventory
		var err error
		for _, info := range arg.GetGoodsInfo() {
			inventory, err = queries.GetInventoryByGoodsID(ctx, info.GoodsId)
			if err != nil {
				if err == sql.ErrNoRows {
					return status.Error(codes.NotFound, "没有该货物")
				} else {
					return status.Error(codes.Internal, "内部错误")
				}
			}
			if inventory.Sticks < info.Num {
				return status.Error(codes.InvalidArgument, "货物不够")
			}
			updateArg := UpdateInventoryParams{}
			updateArg.Goods = info.GoodsId
			updateArg.Counts = -info.Num // 这边应该时负数
			updateArg.UpdatedAt = time.Now()
			inventory, err = queries.UpdateInventory(ctx, updateArg)
			if err != nil {
				return err
			}
		}
		return nil
	})
	return err
}

func (store *SqlStore) RollBackTx(ctx context.Context, arg *proto.SellInfo) error {
	err := store.execTx(ctx, func(queries *Queries) error {
		var err error
		for _, info := range arg.GetGoodsInfo() {
			_, err = queries.GetInventoryByGoodsID(ctx, info.GoodsId)
			if err != nil {
				if err == sql.ErrNoRows {
					return status.Error(codes.NotFound, "没有该货物")
				} else {
					return status.Error(codes.Internal, "内部错误")
				}
			}
			updateArg := UpdateInventoryParams{}
			updateArg.Goods = info.GoodsId
			updateArg.Counts = info.Num // 这边应该时正数
			updateArg.UpdatedAt = time.Now()
			_, err = queries.UpdateInventory(ctx, updateArg)
			if err != nil {
				return err
			}
		}
		return nil
	})
	return err
}
```

### 测试

`shop\service\inventory_srv\handler\inventory_test.go`

```go
package handler

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/jimyag/shop/service/inventory/proto"
)

func TestSetInv(t *testing.T) {
	in := proto.GoodInvInfo{
		GoodsId: 1,
		Num:     10,
	}
	inventory, err := inventoryClient.SetInv(context.Background(), &in)
	require.NoError(t, err)
	require.NotNil(t, inventory)
}

func TestInvDetail(t *testing.T) {
	in := proto.GoodInvInfo{
		GoodsId: 1,
		Num:     10,
	}
	inventory, err := inventoryClient.InvDetail(context.Background(), &in)
	require.NoError(t, err)
	require.NotNil(t, inventory)
	require.Equal(t, in.Num, inventory.Num)
	require.Equal(t, in.GoodsId, inventory.GoodsId)
}

func TestSell(t *testing.T) {
	in := proto.GoodInvInfo{
		GoodsId: 5,
		Num:     1,
	}
	inventory, err := inventoryClient.SetInv(context.Background(), &in)
	require.NoError(t, err)
	require.NotNil(t, inventory)

	ins := proto.SellInfo{
		GoodsInfo: []*proto.GoodInvInfo{
			{
				GoodsId: 1,
				Num:     10,
			},
			{
				GoodsId: 4,
				Num:     100,
			},
		},
	}
	inventory, err = inventoryClient.Sell(context.Background(), &ins)
	require.Error(t, err)
	require.Nil(t, inventory)

}

func TestRollBack(t *testing.T) {
	in := proto.SellInfo{
		GoodsInfo: []*proto.GoodInvInfo{
			{
				GoodsId: 1,
				Num:     10,
			},
		},
	}
	inventory, err := inventoryClient.Rollback(context.Background(), &in)
	require.NoError(t, err)
	require.NotNil(t, inventory)

	in = proto.SellInfo{
		GoodsInfo: []*proto.GoodInvInfo{
			{
				GoodsId: 1,
				Num:     10,
			},
			{
				GoodsId: 10000,
				Num:     1,
			},
		},
	}
	inventory, err = inventoryClient.Rollback(context.Background(), &in)
	require.Error(t, err)
	require.Nil(t, inventory)
}

```

## 库存服务的锁问题

对于减少库存也就是`出售商品`，多个携程同时对数据库进行修改，虽然我们使用了事务，但是这也不能避免。

```mermaid
graph TB
	subgraph g1
	goroutinue1 --> 查询服务1 --> 判断逻辑1 --> 业务逻辑1 --> 更新数据1
	end

	subgraph g2
	goroutinue2 --> 查询服务  --> 判断逻辑 --> 业务逻辑 --> 更新数据 
	end
	
```

两个goroutine同时对数据库进行curd，在开始我们执行事务，这是g1拿到查询的值为100，g2拿到查询的值为100，g1进行更新数据更新为99，g2更新为99，两个事务提交。这时候发现数据已经不一致了。这时候我们给这个事务加锁，是可以解决这个问题的。但是这样的性能太低了，如果我只修改某一个商品的库存，那么所有的库存都要被加锁，以及我们如果有多个服务，一个系统锁只能管住一个服务实例，有多个实例即一个分布式系统时，我们就需要分布式锁。

### 基于mysql的悲观锁，乐观锁

#### 悲观锁

悲观锁是一种思想，一种互斥锁，串行化了

mysql 的 for update 

@@autocommit

要关闭auto commit

```sql
select * form test where goods=12 for update
-- 只会锁住满足条件的数据 只有 goods 是索引的话才会这样 如果where的条件没有索引，行锁会升级成表锁
-- 只锁更新的语句
-- 如果没有满足条件的结果，不会缩表， where 字段为索引
-- 如果不满足条件不是索引还是会缩表
```

#### 乐观锁

用到version 

查询数据的时候查询版本号，

```sql
update inv set stocks = stocks-2 version = version +1 where goods =421 and version =version
```

同时过来只有一个可以成功，但是其余的都要重试

### 基于redis的分布式锁

#### 实现原理

##### **实现原理 判断某个key是否存在且为1，不存在 设置key为1**

1. 判断421是否为1
2. 如果没有，设置为1
3. 如果有，就轮询等待
4. 业务逻辑做完，就删除这个key

##### 1和2应该是一起的是一个原子操作，redis实现了一个命令`setnx`如果key不存在，设置指定的值，上述过程就变为

1. setnx(421,1)
2. 业务逻辑
3. 删除这个key

##### 如果服务挂掉了？业务逻辑挂了，没有完成，就不会删除这个key，其他的都一直在等待这个。

解决方案：

1. 设置过期时间(过期之后自动删除)

如果设置了过期时间，比如是`8秒`，我的业务需要10秒中才能完成，怎么办？

1. 在过期之前刷新一下过期时间
2. 但是需要自己启动一个携程刷新
   1. 延时的接口可能会带来负面影响--。如果某一个服务hung住了，本来是2s就能执行完，但是你hung住（由于各种原因，比如硬件问题）就会一直申请延长锁，导致别人永远获取不到锁，

#### 分布式锁解决的问题 --基于lua脚本去做

1. 互斥性 -setnx
2. 死锁
3. 安全性
   1. 锁只能被持有该锁的用户删除，不能被其他用户删除，
      1. 设置的value是多少，只有当是的gor才能直到，
      2. 在删除的时候取出redis中的值和当前自己保存下来的值对比，如果一样删除



#### 多节点redis实现的分布式锁算法(RedLock):有效防止单点故障

在一个系统中，我们有多个redis的实例，有一个是redis的master节点，其余的都是redis的slaver节点当一个服务向redis的某个节点拿到锁之后，reids的集群会自动同步所有的锁的状况，这里的同步我们先不做关心。

在这个时候，master宕机了，他们之间的同步服务用不了了？？，这时候应该怎么办？

##### 红锁的原理：

有5台redis的实例，在获取锁(setnx)的时候应该在5台实例上都获得锁,这五台都是相同级别的，

在获得锁的时候，如果两个服务同时获得锁，一个获得了一部分，一个获得了另一部分，如果要求全部设置上的话，就都会失败，那么重试的话，就不会成功。这时应该拿到多数的台数就算成功。5台的话谁先拿到3台就成功，如果有三个服务分别拿了221，那么就重试，直到有人拿到一半以上。这里拿锁是同时去拿，同时开gor去拿锁，如果某个服务没有拿到多数的锁就应该释放当前的锁。

#### 别人总结的

假设有5个完全独立的redis主服务器

1. 获取当前时间戳
2. client尝试按照顺序使用相同的key,value获取所有redis服务的锁，在获取锁的过程中的获取时间比锁过期时间短
   很多，这是为了不要过长时间等待已经关闭的redis服务。且试着获取下一个redis实例。
   比如: TTL为5s,设置获取锁最多用1s,所以如果一秒内无法获取锁， 就放弃获取这个锁，从而尝试获取下个锁
3. client通过获取所有能获取的锁后的时间减去第一步的时间， 这个时间差要小于TTL时间并且至少有3个redis实例
   成功获取锁,才算真正的获取锁成功
4. 如果成功获取锁，则锁的真正有效时间是TTL减去第三步的时间差的时间;比如: TTL是5s,获取所有锁用了2s,
   则真正锁有效时间为3s(其实应该再减去时钟漂移);
5. 如果客户端由于某些原因获取锁失败,便会开始解锁所有redis实例;因为可能已经获取了小于3个锁，必须释
   放，否则影响其他client获取锁

##### 什么是时钟漂移

如果redis服务器的机器时钟发生了向前跳跃,就会导致这个key过早超时失效，比如说客户端1拿到锁后，key的过
期时间是12:02分，但redis服务器本身的时钟比客户端快了2分钟，导致key在12:00的时候就失效了，这时候,如
果客户端1还没有释放锁的话，就可能导致多个客户端同时持有同-把锁的问题。

##### RedLock算法是否是异步算法? ?

可以看成是同步算法;因为即使进程间(多个电脑间)没有同步时钟，但是每个进程时间流速大致相同;并且时
钟漂移相对于TTL叫小，可以忽略,所以可以看成同步算法; (不够严谨， 算法上要算上时钟漂移，因为如果两个
电脑在地球两端，则时钟漂移非常大)

##### RedLock失败重试

当client不能获取锁时，应该在随机时间后重试获取锁;且最好在同-时刻并发的把set命令发送给所有redis实
例;而且对于已经获取锁的client在完成任务后要及时释放锁，这是为了节省时间;

##### RedLock释放锁

由于释放锁时会判断这个锁的value是不是自己设置的,如果是才删除;所以在释放锁时非常简单,只要向所有实
例都发出释放锁的命令，不用考虑能否成功释放锁;

##### RedLock注意点(Safety arguments) :

1.先假设client获取所有实例，所有实例包含相同的key和过期时间(TTL) ,但每个实例set命令时间不同导致不能同时
过期，第一个set命令之前是T1,最后一个set命令后为T2,则此client有效获取锁的最小时间为TTL-(T2-T1)-时钟漂移;
2.对于以N/2+ 1(也就是一半以,上)的方式判断获取锁成功,是因为如果小于一半判断为成功的话，有可能出现多
个client都成功获取锁的情况，从而使锁失效
3.-个client锁定大多数事例耗费的时间大于或接近锁的过期时间，就认为锁无效,并且解锁这个redis实例(不执行
业务) ;只要在TTL时间内成功获取一半以上的锁便是有效锁:否则无效

##### 系统有活性的三个特征

1.能够自动释放锁
2.在获取锁失败(不到一半以上)，或任务完成后 能够自动释放锁,不用等到其自动过期
3.在client重试获取哦锁前(第-次失败到第二 次重试时间间隔) 大于第一次获取锁消耗的时间;
4.重试获取锁要有-定次数限制

##### RedLock性能及崩溃恢复的相关解决方法

1.如果redis没有持久化功能，在clientA获取锁成功后，所有redis重启，clientB能够再次获取到锁，这样违法了锁
的排他互斥性;
2.如果启动AOF永久化存储，事情会好些，举例:当我们重启redis后， 由于redis过期机制是按照unix时间戳走的,
所以在重启后，然后会按照规定的时间过期，不影响业务;但是由于AOF同步到磁盘的方式默认是每秒-次,如果在
一秒内断电， 会导致数据丢失,立即重启会造成锁互斥性失效;但如果同步磁盘仿式使用Always(每一个写命令 都同
步到硬盘)造成性能急剧下降;所以在锁完全有效性和性能方面要有所取舍;
3.有效解决既保证锁完全有效性及性能高效及即使断电情况的方法是redis同步到磁盘方式保持默认的每秒,在
redis无论因为什么原因停掉后要等待TTL时间后再重启(学名:延迟重启) ;缺点是在TTL时间内服务相当于暂停状态;

##### 总结

1.TTL时长要大于正常业务执行的时间+获取所有redis服务消耗时间+时钟漂移
2.获取redis所有服务消耗时间要远小于TTL时间,并且获取成功的锁个数要在总数的一般以上:N/2+1
3.尝试获取每个redis实例锁时的时间要远小于TTL时间
4.尝试获取所有锁失败后重新尝试一定要有一定次数限制
5.在redis崩溃后(无论-个还是所有)，要延迟TTL 时间重启redis
6.在实现多redis节点时要结合单节点分布式锁算法共同实现

## 在项目中使用

```go
package main

import (
	"fmt"
	"sync"
	"time"

	goredislib "github.com/go-redis/redis/v8"
	"github.com/go-redsync/redsync/v4"
	"github.com/go-redsync/redsync/v4/redis/goredis/v8"
)

func main() {
	// Create a pool with go-redis (or redigo) which is the pool redisync will
	// use while communicating with Redis. This can also be any pool that
	// implements the `redis.Pool` interface.
	client := goredislib.NewClient(&goredislib.Options{
		Addr: "localhost:36379",
	})
	pool := goredis.NewPool(client) // or, pool := redigo.NewPool(...)

	// Create an instance of redisync to be used to obtain a mutual exclusion
	// lock.
	rs := redsync.New(pool)

	// Obtain a new mutex by using the same name for all instances wanting the
	// same lock.

	gNum := 2
	mutexname := "my-global-mutex"
	var wg sync.WaitGroup
	wg.Add(gNum)
	for i := 0; i < gNum; i++ {

		mutex := rs.NewMutex(mutexname)
		fmt.Println("开始获取锁")
		if err := mutex.Lock(); err != nil {
			panic(err)
		}
		fmt.Println("获取锁成功")
		time.Sleep(time.Second * 5)
		fmt.Println("开始释放锁")
		if ok, err := mutex.Unlock(); !ok || err != nil {
			panic("unlock failed")
		}
		fmt.Println("释放锁成功")
		wg.Done()
	}
	wg.Wait()
}
```

1. 设置全局的`rs = redsync.New(pool)`

2. 初始化全局的rs

3. 在需要用到的地方

   ```go
   mutex := rs.NewMutex(mutexname)
   fmt.Println("开始获取锁")
   if err := mutex.Lock(); err != nil {
   	panic(err)
       //错误处理
   }
   // 处理业务代码
   ...
   // 处理业务结束
   if ok, err := mutex.Unlock(); !ok || err != nil {
   	panic("unlock failed")
       // 处理错误
   }
   ```


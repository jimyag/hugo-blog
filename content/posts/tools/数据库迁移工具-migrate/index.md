---
title: 数据库迁移工具-migrate
tags:
  - 工具
  - 教程
  - 数据库
categories:
  - - 工具
  - - 教程
  - - 数据库
slug: ../e7121931
date: 2022-03-24 19:44:28
---

在项目中，因需求的变更常常影响到数据库表结构的设计及数据的更新，导致大量的 sql 脚本难以维护。正因为如此，数据库迁移工具的设计之前，就旨在帮助开发者更合理、有效地管理数据库。

<!--more-->

### 安装migrate

根据[migrate/cmd/migrate at master · golang-migrate/migrate (github.com)](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate)中的提示选择对应的版本进行安装。

以windows为例，在[[Releases · golang-migrate/migrate (github.com)](https://github.com/golang-migrate/migrate/releases)](https://github.com/golang-migrate/migrate)中选择一个版本，找到`windows`的对应版本，我这里下载`migrate.windows-amd64`，将里面对应的.exe可执行文件添加到环境变量中。

我将可执行文件放到`GOPATH/bin`中。

`GOPATH`的路径可通过`go env  GOPATH `得到。

```sh
C:\Users\jimyag>migrate -version
4.15.1
```

安装成功。

### 使用migrate

```sh
mkdir migration
```

```sh
migrate create -ext sql -dir migration -seq init_schema_user
```

将文件拓展名设为`sql`

要存储的目录为`.\migration\`,

`-seq`迁移文件的顺序版本号

`init_schema` 迁移的名称

执行完命令会生成两个文件

```sh
migration
├── 000001_init_schema_user.down.sql
├── 000001_init_schema_user.up.sql
```

在`000001_init_schema_user.down.sql`中添加如下内容

```sql
CREATE TABLE "accounts" (
                            "id" bigserial PRIMARY KEY,
                            "owner" varchar NOT NULL,
                            "balance" bigint NOT NULL,
                            "currency" varchar NOT NULL,
                            "created_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "entries" (
                           "id" bigserial PRIMARY KEY,
                           "account_id" bigint NOT NULL,
                           "amount" bigint NOT NULL,
                           "created_at" timestamp NOT NULL DEFAULT (now())
);

CREATE TABLE "transfers" (
                             "id" bigserial PRIMARY KEY,
                             "from_account_id" bigint NOT NULL,
                             "to_account_id" bigint NOT NULL,
                             "amount" bigint NOT NULL,
                             "created_at" timestamp NOT NULL DEFAULT (now())
);

ALTER TABLE "entries" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("id");

ALTER TABLE "transfers" ADD FOREIGN KEY ("from_account_id") REFERENCES "accounts" ("id");

ALTER TABLE "transfers" ADD FOREIGN KEY ("to_account_id") REFERENCES "accounts" ("id");

CREATE INDEX ON "accounts" ("owner");

CREATE INDEX ON "entries" ("account_id");

CREATE INDEX ON "transfers" ("from_account_id");

CREATE INDEX ON "transfers" ("to_account_id");

CREATE INDEX ON "transfers" ("from_account_id", "to_account_id");
```

在`000001_init_schema_user.up.sql`写入一下文件。

```sql
DROP TABLE IF EXISTS  entries;
DROP TABLE IF EXISTS  transfers;
DROP TABLE IF EXISTS  accounts;
```

创建数据库

```shell
docker run --name test-pg -p 35432:5432 -e POSTGRES_PASSWORD=postgres -e TZ=PRC -d postgres:14-alpine
```

创建一个`shop`的数据库。

```shell
docker exec -it test-pg createdb --username=postgres --owner=postgres shop
```

生成表结构。

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up
2022/03/24 20:30:43 Start buffering 1/u init_schema_user
2022/03/24 20:30:43 Read and execute 1/u init_schema_user
2022/03/24 20:30:43 Finished 1/u init_schema_user (read 9.4412ms, ran 8.1883ms)
2022/03/24 20:30:43 Finished after 38.1796ms
2022/03/24 20:30:43 Closing source and database
```

进入docker中

```shell
> docker exec -it test-pg /bin/sh
```
```shell
> psql -U postgres
```
已经有了之前的`shop`数据库

```shell
> postgres=# \list
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 shop      | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
```
进入`shop`中

```shell
> postgres=# \c shop
You are now connected to database "shop" as user "postgres".
```
出现了四张表

```shell
> select tablename from pg_tables where schemaname='public';
     tablename
-------------------
 schema_migrations
 accounts
 entries
 transfers
(4 rows)
```

`schema_migrations`是用来同步表用的。

回滚表，输入y

```sh
>migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose down
2022/03/24 20:48:35 Are you sure you want to apply all down migrations? [y/N]
y
2022/03/24 20:48:37 Applying all down migrations
2022/03/24 20:48:37 Start buffering 1/d init_schema_user
2022/03/24 20:48:37 Read and execute 1/d init_schema_user
2022/03/24 20:48:37 Finished 1/d init_schema_user (read 8.0654ms, ran 25.5793ms)
2022/03/24 20:48:37 Finished after 2.240096s
2022/03/24 20:48:37 Closing source and database
>shop=# select tablename from pg_tables where schemaname='public';
     tablename
-------------------
 schema_migrations
(1 row)
```

发现只剩`同步表了`

#### 多次同步

为了测试 migrations up [N] 执行多次修改的情形，第二次修改我们使用事务为 account表增加 COLUMN，

```shell
D:\Computer\Desktop>migrate create -ext sql -dir migration -seq add_mood_to_user
D:\Computer\Desktop\migration\000002_add_mood_to_user.up.sql
D:\Computer\Desktop\migration\000002_add_mood_to_user.down.sql
```

在`000002_add_mood_to_user.up.sql`中添加

```sql
BEGIN;
CREATE TYPE enum_mood AS ENUM (
	'happy',
	'sad',
	'neutral'
);
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS mood enum_mood;
COMMIT;
```

在`000002_add_mood_to_user.down.sql`中添加

```sql
BEGIN;

ALTER TABLE accounts DROP COLUMN IF EXISTS mood;
DROP TYPE enum_mood;

COMMIT;
```

```shell
D:\Computer\Desktop>migrate create -ext sql -dir migration -seq add_roleid_to_users
D:\Computer\Desktop\migration\000003_add_roleid_to_users.up.sql
D:\Computer\Desktop\migration\000003_add_roleid_to_users.down.sql
```
在`000003_add_roleid_to_users.up.sql`中添加

```sql
BEGIN;
CREATE TYPE enum_mood AS ENUM (
	'happy',
	'sad',
	'neutral'
);
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS mood enum_mood;
COMMIT;
```

在`000003_add_roleid_to_users.down.sql`中添加

```sql
BEGIN;

ALTER TABLE accounts DROP COLUMN IF EXISTS mood;
DROP TYPE enum_mood;

COMMIT;
```

`migration`中有以下文件

```sh
2022/03/24  20:46                97 000001_init_schema_user.down.sql
2022/03/24  20:46             1,489 000001_init_schema_user.up.sql
2022/03/24  20:58                91 000002_add_mood_to_user.down.sql
2022/03/24  20:57               147 000002_add_mood_to_user.up.sql
2022/03/24  21:02                51 000003_add_roleid_to_users.down.sql
2022/03/24  21:02                62 000003_add_roleid_to_users.up.sql
```

```shell
> migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up
2022/03/24 21:04:15 Start buffering 1/u init_schema_user
2022/03/24 21:04:15 Start buffering 2/u add_mood_to_user
2022/03/24 21:04:15 Start buffering 3/u add_roleid_to_users
2022/03/24 21:04:15 Read and execute 1/u init_schema_user
2022/03/24 21:04:15 Finished 1/u init_schema_user (read 8.7174ms, ran 124.6018ms)
2022/03/24 21:04:15 Read and execute 2/u add_mood_to_user
2022/03/24 21:04:15 Finished 2/u add_mood_to_user (read 141.2056ms, ran 10.1257ms)
2022/03/24 21:04:15 Read and execute 3/u add_roleid_to_users
2022/03/24 21:04:15 Finished 3/u add_roleid_to_users (read 159.2213ms, ran 9.0379ms)
2022/03/24 21:04:15 Finished after 189.4334ms
2022/03/24 21:04:15 Closing source and database
```

以上可以看到所有的都已经同步成功，并且是按照序号的顺序进行执行。

```shell
> migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose down
2022/03/24 21:04:39 Are you sure you want to apply all down migrations? [y/N]
y
2022/03/24 21:04:41 Applying all down migrations
2022/03/24 21:04:41 Start buffering 3/d add_roleid_to_users
2022/03/24 21:04:41 Start buffering 2/d add_mood_to_user
2022/03/24 21:04:41 Start buffering 1/d init_schema_user
2022/03/24 21:04:41 Read and execute 3/d add_roleid_to_users
2022/03/24 21:04:41 Finished 3/d add_roleid_to_users (read 9.9293ms, ran 12.7524ms)
2022/03/24 21:04:41 Read and execute 2/d add_mood_to_user
2022/03/24 21:04:41 Finished 2/d add_mood_to_user (read 30.9375ms, ran 10.6209ms)
2022/03/24 21:04:41 Read and execute 1/d init_schema_user
2022/03/24 21:04:41 Finished 1/d init_schema_user (read 47.6036ms, ran 18.4846ms)
2022/03/24 21:04:41 Finished after 1.6015872s
2022/03/24 21:04:41 Closing source and database
```

以上可以看到所有的回滚成功，并按照序号的逆序进行。

#### 测试失败的情况

我们回滚所有操作。

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose down
```

然后执行`注意有2`，

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up 2
2022/03/24 21:10:33 Start buffering 1/u init_schema_user
2022/03/24 21:10:33 Start buffering 2/u add_mood_to_user
2022/03/24 21:10:33 Read and execute 1/u init_schema_user
2022/03/24 21:10:33 Finished 1/u init_schema_user (read 10.4179ms, ran 54.5128ms)
2022/03/24 21:10:33 Read and execute 2/u add_mood_to_user
2022/03/24 21:10:33 Finished 2/u add_mood_to_user (read 73.7285ms, ran 11.7561ms)
2022/03/24 21:10:33 Finished after 107.6561ms
2022/03/24 21:10:33 Closing source and database
```

这时候已经应用了前两个同步。

接下来修改，`000003_add_roleid_to_users.up.sql`使其语法错误。

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up 1
2022/03/24 21:13:46 Start buffering 3/u add_roleid_to_users
2022/03/24 21:13:46 Read and execute 3/u add_roleid_to_users
2022/03/24 21:13:46 error: migration failed: syntax error at or near "%" (column 63) in line 1: ALTER TABLE accounts ADD COLUMN IF NOT EXISTS role_id INTEGER;% (details: pq: syntax error at or near "%")
```

此时执行，发现错误。

这时候，我们进入数据库中查看`schema_migrations`表中的数据

```sql
select * from shop.public.schema_migrations;
 version | dirty
---------+-------
       3 | true
```

这时候显示，当前处于版本3，并且有脏数据。

如果我们修改正确`000003_add_roleid_to_users.up.sql`再执行`up 1`命令

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up 1
2022/03/24 21:18:15 error: Dirty database version 3. Fix and force version.
```

这时候需要使用`migrate force 3` 来确认说 version=3 的错误问题已修复，

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose force 3
2022/03/24 21:19:34 Finished after 100.3292ms
2022/03/24 21:19:34 Closing source and database
```

而且需要执行 `migrate down 1` 将 version 回退到 version=2 ，才能继续执行。

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose down 1
2022/03/24 21:19:58 Start buffering 3/d add_roleid_to_users
2022/03/24 21:19:58 Read and execute 3/d add_roleid_to_users
2022/03/24 21:19:58 Finished 3/d add_roleid_to_users (read 9.7019ms, ran 10.2768ms)
2022/03/24 21:19:58 Finished after 40.0968ms
2022/03/24 21:19:58 Closing source and database
```

同步到版本3

```shell
migrate -path ./migration -database "postgresql://postgres:postgres@localhost:35432/shop?sslmode=disable" -verbose up 1
2022/03/24 21:20:19 Start buffering 3/u add_roleid_to_users
2022/03/24 21:20:19 Read and execute 3/u add_roleid_to_users
2022/03/24 21:20:19 Finished 3/u add_roleid_to_users (read 10.9011ms, ran 11.6158ms)
2022/03/24 21:20:19 Finished after 45.0244ms
2022/03/24 21:20:19 Closing source and database
```

### migrate的工作流程

#### up

原有的数据通过产生的`up`文件向上更改

当我们使用命令`migrate up`时，产生的up脚本会按照前缀的顺序依次执行

#### down

新的数据通过`down`脚本进行还原

当我们使用命令`migrate down`时，产生的down脚本会按照前缀顺序的逆序进行执行



### 参考

[golang数据库迁移工具golang-migrate使用_doyzfly的博客-CSDN博客_golang migrate](https://blog.csdn.net/doyzfly/article/details/121096806)

[migrate/cmd/migrate at master · golang-migrate/migrate (github.com)](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate)

[migrate/GETTING_STARTED.md at master · golang-migrate/migrate (github.com)](https://github.com/golang-migrate/migrate/blob/master/GETTING_STARTED.md)




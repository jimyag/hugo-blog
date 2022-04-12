---
title: 在GORM中使用Postgres自定义数据类型
tags:
  - GORM
  - Postgres
categories:
  - 教程
slug: /1fb2f937
date: 2021-12-22 12:32:29
---

项目中使用到了postgres的枚举类型，但是使用GORM自动迁移表的时候出现了

```sql
 CREATE TABLE "user" ("id" bigserial,
                      "created_at" timestamptz,
                      "updated_at" timestamptz,
                      "deleted_at" timestamptz,
                      "username" varchar(20),unique,
                      "password" varchar(20),
                      "email" varchar(32),unique,
                      "authority" enum('root', 'one', 'two', 'three', 'four'),default:'one',
                      PRIMARY KEY ("id"))
错误: 语法错误 在 "," 或附近的 (SQLSTATE 42601)
```

在[gorm/issues](https://github.com/go-gorm/gorm/issues/1978#issuecomment-476673540)中找到了解决方案

<!--more-->

#### 在pg中创建自定义类型

```sql
CREATE TYPE authority AS ENUM (
    'root',
    'one',
    'two',
    'three',
    'four');
```

#### 定义自定义的数据类型的model

```go
import (
	"database/sql/driver"
)
type Authority string
// 'root', 'one', 'two', 'three', 'four'
const (
	root  Authority = "root"
	one   Authority = "one"
	two   Authority = "two"
	three Authority = "three"
	four  Authority = "four"
)
func (p *Authority) Scan(value interface{}) error {
	*p = Authority(value.([]byte))
	return nil
}
func (p Authority) Value() (driver.Value, error) {
	return string(p), nil
}
```

#### 定义一个要使用的Model

```go
type User struct {
	global.Model
	Username  string `gorm:"type:varchar(20)" json:"username" `
	Password  string `gorm:"type:varchar(20)" json:"password"`
	Email     string `gorm:"type:varchar(32)" json:"email" `
	Authority string `gorm:"type:authority" json:"authority"`
}
```

现在你就可以使用GORM的`AutoMigrate()`自动迁移表了

```go
err = DB.AutoMigrate(&User{})
	if err != nil {
		fmt.Println("数据库创建失败", err)
		return nil
}
```


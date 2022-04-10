---
title: 从0到1实现完整的微服务框架-负载均衡
tags:
  - 微服务
  - gRPC
  - 负载均衡
categories:
  - - 微服务
  - - gRPC
  - - 负载均衡
slug: ../../a97428cc
date: 2022-03-28 20:56:26
series: [ "从0到1实现完整的微服务框架" ] 
---

本文主要介绍如何在grpc中使用负载均衡。

<!--more-->

我们使用的是别人写好的一个包[mbobakov/grpc-consul-resolver](https://github.com/mbobakov/grpc-consul-resolver),这个包的使用也很简单，只需要导入进来，在初始化的时候添加

```go
package main

import (
	"time"
	"log"

    // 添加的
	_ "github.com/mbobakov/grpc-consul-resolver" // It's important

	"google.golang.org/grpc"
)

func main() {
    conn, err := grpc.Dial(
        "consul://127.0.0.1:8500/whoami?wait=14s&tag=manual",
        grpc.WithInsecure(),
        // 添加的
        grpc.WithDefaultServiceConfig(`{"loadBalancingPolicy": "round_robin"}`),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer conn.Close()
    ...
}
```

在这里我们要做一个关于优雅终止的。当我们要结束掉进程之后，我们要把服务在注册中心注销掉。

`shop\service\user_srv\main.go`最后

```go
	// 由于我们要一直监听操作，这些启动一个协程
	go func() {
		err = server.Serve(lis)
		if err != nil {
			global.Logger.Fatal("cannot run server.....")
		}
	}()
	// 优雅退出
	quit := make(chan os.Signal)
	// 监听信号
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	if err = client.Agent().ServiceDeregister(serviceID.String()); err != nil {
		global.Logger.Info("服务注销失败", zap.String("serviceID", serviceID.String()))
	}
	cl.Close()
	global.Logger.Info("服务已注销", zap.String("serviceID", serviceID.String()))
```


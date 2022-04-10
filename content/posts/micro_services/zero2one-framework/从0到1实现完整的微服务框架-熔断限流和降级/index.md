---
title: 从0到1实现完整的微服务框架-熔断限流和降级
tags:
  - 微服务
  - gRPC
  - 熔断
  - 限流
  - 降级
categories:
  - - 微服务
  - - gRPC
  - - 熔断
  - - 限流
  - - 降级
slug: ../../71ef7b9d
date: 2022-03-29 13:58:43
series: [ "从0到1实现完整的微服务框架" ] 
---

使用sentinel实现熔断限流和降级。

<!--more-->

## 服务雪崩

服务提供者不可用导致 服务调用的不可用，并将不可用现象放大

服务雪崩三个阶段

1. 服务提供者不可用
   1. 硬件故障
   2. 程序bug
   3. 缓存击穿
   4. 用户大量请求
2. 重试加大请求流量
   1. 用户重试
   2. 代码逻辑重试
3. 服务调用者不可用
   1. 同步等待造成资源耗尽。

应对的策略

1. 应用库容
   1. 增加机器数量
   2. 升级规格
2. 流控  不至于让服务挂掉
   1. 限流
   2. 关闭重试
3. 缓存
   1. 缓存预加载
4. 服务降级  当前访问用户过多，请稍后重试
   1. 服务接口拒绝服务
   2. 页面拒绝服务
   3. 延迟持久化
   4. 随机拒绝
5. 服务熔断 调用方调用都超时？保险丝 

## 服务限流

`shop\api\user-api\initialize\sentinel.go`

```go
package initialize

import (
	sentinel "github.com/alibaba/sentinel-golang/api"
	"github.com/alibaba/sentinel-golang/core/flow"
	"go.uber.org/zap"

	"github.com/jimyag/shop/api/user/global"
)

func InitSentinel() {
	err := sentinel.InitDefault()
	if err != nil {
		global.Logger.Fatal("初始化 sentinel 失败 .....", zap.Error(err))
	}

	_, err = flow.LoadRules([]*flow.Rule{
		{
			Resource:               "get-user-list",
			TokenCalculateStrategy: flow.Direct,
			ControlBehavior:        flow.Reject,
			Threshold:              100, // 通过几个
			StatIntervalInMs:       1,   // 多少秒
		},
	})
	if err != nil {
		global.Logger.Fatal("加载 sentinel 配置失败....", zap.Error(err))
	}
	global.Logger.Info("加载 sentinel 配置成功....", zap.Error(err))
}
```

`shop\api\user-api\api\user.go`

```go
func GetUserList(ctx *gin.Context) {
	pageNum := ctx.DefaultQuery("pageNum", "1")
	pageNumInt, err := strconv.Atoi(pageNum)
	if err != nil {
		global.Logger.Info("pageNum invalid")
	}
	pageSize := ctx.DefaultQuery("pageSize", "5")
	pageSizeInt, err := strconv.Atoi(pageSize)
	if err != nil {
		global.Logger.Info("pageNum invalid")
	}
    // 增加的开始
	e, b := sentinel.Entry("get-user-list", sentinel.WithTrafficType(base.Inbound))
	if b != nil {
		// block le
		response.FailWithMsg("请求频率过快，请稍后重试", ctx)
		return
	}
    // 增加的结束
	rsp, err := global.UserSrvClient.GetUserList(ctx, &proto.PageIngo{
		PageNum:  uint32(pageNumInt),
		PageSize: uint32(pageSizeInt),
	})
	if err != nil {
		handle_grpc_error.HandleGrpcErrorToHttp(err, ctx)
		return
	}
    // 增加的开始
    e.Exit()
    // 增加的结束
    // ....
}
```






---
title: 从0到1实现完整的微服务框架-链路追踪
tags:
  - 微服务
  - gRPC
  - 链路追踪
categories:
  - - 微服务
  - - gRPC
  - - 链路追踪
slug: ../../c8b300d9
date: 2022-03-28 22:13:56
series: [ "从0到1实现完整的微服务框架" ] 
---

在分布式系统，尤其是微服务系统中，一次外部请求往往需要内部多个模块，多个中间件，多台机器的相互调用才能完成。在这一系列的调用中，可能有些是串行的，而有些是并行的。在这种情况下，我们如何才能确定这整个请求调用了哪些应用？哪些模块？哪些节点？以及它们的先后顺序和各部分的性能如何呢？

这就是涉及到链路追踪。

<!--more-->

## jaeger安装

```shell
docker run -d --name jaeger   -e COLLECTOR_ZIPKIN_HOST_PORT=:9411   -p 5775:5775/udp   -p 6831:6831/udp   -p 6832:6832/udp   -p 5778:5778   -p 16686:16686   -p 14250:14250   -p 14268:14268   -p 14269:14269   -p 9411:9411 jaegertracing/all-in-one:1.32
```

## api层添加链路追踪

链路追踪的起点在每次发起http请求的地方，这时候就需要一个拦截器来生成tracer

`shop\api\user-api\middlewares\tracing.go`

```go
package middlewares

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/uber/jaeger-client-go"
	jaegercfg "github.com/uber/jaeger-client-go/config"
	"go.uber.org/zap"

	"github.com/jimyag/shop/api/user/global"
)

func Tracing() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		cfg := jaegercfg.Configuration{
			Sampler: &jaegercfg.SamplerConfig{
				Type:  jaeger.SamplerTypeConst,
				Param: 1, // 全部采样
			},
			Reporter: &jaegercfg.ReporterConfig{
				LogSpans: true,
				LocalAgentHostPort: fmt.Sprintf("%s:%d", 
					global.ServerConfig.JaegerInfo.Host, // jaeger 位置
					global.ServerConfig.JaegerInfo.Port, // 6831
				),
			},
			ServiceName: global.ServerConfig.Name,
		}
		tracer, close, err := cfg.NewTracer(jaegercfg.Logger(jaeger.StdLogger))
		if err != nil {
			global.Logger.Fatal("创建 tracer 失败", zap.Error(err))
		}
		defer close.Close()
		startSpan := tracer.StartSpan(ctx.Request.URL.Path)
		defer startSpan.Finish()
		ctx.Set("tracer", tracer)
		ctx.Set("parentSpan", startSpan)
		ctx.Next()
	}
}
```

将这个中间件配置到需要链路追踪的router上

`shop\api\user-api\initialize\router.go`全局都加

```go
router.Use(middlewares.Tracing())
```

由于我们使用了`负载均衡`,所以对于其他的grpc的链接要加一个拦截器，来将context加入到grpc服务中。

```go
package initialize

import (
	"fmt"

	"github.com/hashicorp/consul/api"
	_ "github.com/mbobakov/grpc-consul-resolver"
	"github.com/opentracing/opentracing-go"
	"go.uber.org/zap"
	"google.golang.org/grpc"

	"github.com/jimyag/shop/api/user/global"
	"github.com/jimyag/shop/api/user/proto"
	"github.com/jimyag/shop/api/user/util/otgrpc"
)

func InitSrvConn() {
	// consul
	conn, err := grpc.Dial(
		fmt.Sprintf("consul://%s:%d/%s?wait=14s",
			global.ServerConfig.ConsulInfo.Host,
			global.ServerConfig.ConsulInfo.Port,
			global.ServerConfig.UserSrv.Name,
		),
		grpc.WithInsecure(),
		grpc.WithDefaultServiceConfig(`{"loadBalancingPolicy": "round_robin"}`),
        // 添加的
		grpc.WithUnaryInterceptor(
			otgrpc.OpenTracingClientInterceptor(
				opentracing.GlobalTracer(),
			),
		),
        // 结束
	)
	if err != nil {
		global.Logger.Fatal("用户服务发现错误", zap.Error(err))
	}
	global.UserSrvClient = proto.NewUserClient(conn)

}
```

`shop\api\user-api\util\otgrpc\client.go:31`修改源码

```go
func OpenTracingClientInterceptor(tracer opentracing.Tracer, optFuncs ...Option) grpc.UnaryClientInterceptor {
	otgrpcOpts := newOptions()
	otgrpcOpts.apply(optFuncs...)
	return func(
		ctx context.Context,
		method string,
		req, resp interface{},
		cc *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		opts ...grpc.CallOption,
	) error {
		var err error
		var parentCtx opentracing.SpanContext
		// 从 context 提取 父span
		if parent := opentracing.SpanFromContext(ctx); parent != nil {
			parentCtx = parent.Context()
		}
        // 修改的
		switch ctx.(type) {
		case *gin.Context:
			iTracer, ok := ctx.(*gin.Context).Get("tracer")
			if ok {
				tracer = iTracer.(opentracing.Tracer)
			}

			parentSpan, ok := ctx.(*gin.Context).Get("parentSpan")
			if ok {
				parentCtx = parentSpan.(*jaegerClient.Span).Context()
			}

		}

		if otgrpcOpts.inclusionFunc != nil &&
			!otgrpcOpts.inclusionFunc(parentCtx, method, req, resp) {
			return invoker(ctx, method, req, resp, cc, opts...)
		}
		clientSpan := tracer.StartSpan(
			method,
			opentracing.ChildOf(parentCtx),
			ext.SpanKindRPCClient,
			gRPCComponentTag,
		)
		defer clientSpan.Finish()
		// 使用metadata机制传递
		ctx = injectSpanContext(ctx, tracer, clientSpan)
		if otgrpcOpts.logPayloads {
			clientSpan.LogFields(log.Object("gRPC request", req))
		}
		err = invoker(ctx, method, req, resp, cc, opts...)
		if err == nil {
			if otgrpcOpts.logPayloads {
				clientSpan.LogFields(log.Object("gRPC response", resp))
			}
		} else {
			SetSpanTags(clientSpan, err, true)
			clientSpan.LogFields(log.String("event", "error"), log.String("message", err.Error()))
		}
		if otgrpcOpts.decorator != nil {
			otgrpcOpts.decorator(clientSpan, method, req, resp, err)
		}
		return err
	}
}
```

这里修改源码是拿到context中的`tracer`和`parentSpan`

## grpc集成jaeger

在服务端还有子的过程

client拦截器的原理

从context拿到父亲的span

```go
// 通过parentSpan生成当前的span
clientSpan := tracer.StartSpan(
			method,
			opentracing.ChildOf(parentCtx),
			ext.SpanKindRPCClient,
			gRPCComponentTag,
		)
		defer clientSpan.Finish()
```

通过metadata的机制，将它的内容写到metadata中去

```go
// 使用metadata机制传递
		ctx = injectSpanContext(ctx, tracer, clientSpan)
```

然后通过`shop\api\user-api\util\otgrpc\client.go:243`

```go
func injectSpanContext(ctx context.Context, tracer opentracing.Tracer, clientSpan opentracing.Span) context.Context {
	md, ok := metadata.FromOutgoingContext(ctx)
	if !ok {
		md = metadata.New(nil)
	} else {
		md = md.Copy()
	}
	mdWriter := metadataReaderWriter{md}
	// 将服务端想要的信息注入到metadata中
	err := tracer.Inject(clientSpan.Context(), opentracing.HTTPHeaders, mdWriter)
	// We have no better place to record an error than the Span itself :-/
	if err != nil {
		clientSpan.LogFields(log.String("event", "Tracer.Inject() failed"), log.Error(err))
	}
	return metadata.NewOutgoingContext(ctx, md)
}
```

如何写到opentracing中去这是有一个标准，是由opentracing做的，如何提取也是由它来做的。

将服务端想要的信息注入到metadata中去，如果注入、拿数据我们不用关心。

**在grpc服务端**

```go
// For example:
//
//     s := grpc.NewServer(
//         ...,  // (existing ServerOptions)
//         grpc.UnaryInterceptor(otgrpc.OpenTracingServerInterceptor(tracer)))
```

只要在new grpcserver的时候添加一个服务端的拦截器就行

`shop\service\user_srv\main.go`

```go
// 初始化jaeger
	cfg := jaegercfg.Configuration{
		Sampler: &jaegercfg.SamplerConfig{
			Type:  jaeger.SamplerTypeConst,
			Param: 1, // 全部采样
		},
		Reporter: &jaegercfg.ReporterConfig{
			LogSpans: true,
			LocalAgentHostPort: fmt.Sprintf("%s:%d",
				global.RemoteConfig.JaegerInfo.Host,
				global.RemoteConfig.JaegerInfo.Port,
			),
		},
		ServiceName: "user-srv",
	}
	// 初始化一jaeger
	tracer, cl, err := cfg.NewTracer(jaegercfg.Logger(jaeger.StdLogger))
	if err != nil {
		global.Logger.Fatal("创建 tracer 失败", zap.Error(err))
	}
	opentracing.SetGlobalTracer(tracer)
	// 注册服务
	server := 		grpc.NewServer(grpc.UnaryInterceptor(otgrpc.OpenTracingServerInterceptor(tracer)))
```

我们这边可以自己生成tracer，没有必要用服务端的tracer，我们只要处理好父子关系就好，当整个服务挂了之后cl.Close()

在grpc的服务中如何拿到tracer，

`shop\service\user_srv\util\otgrpc\server.go:39`从context中拿到span

```go
spanContext, err := extractSpanContext(ctx, tracer)
```

```go
func extractSpanContext(ctx context.Context, tracer opentracing.Tracer) (opentracing.SpanContext, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		md = metadata.New(nil)
	}
    // 与之前的Inject对应
	return tracer.Extract(opentracing.HTTPHeaders, metadataReaderWriter{md})
}

```

在服务中使用：

`D:\repository\shop\service\user_srv\handler\user.go`

```go
func (u *UserServer) GetUserList(ctx context.Context, req *proto.PageIngo) (*proto.UserListResponse, error) {
	// 省略之前的
    // 从context总拿到parentSpan
	parentSpan := opentracing.SpanFromContext(ctx)
    // 生成一个span并设置它的父亲
	getUserListSpan := opentracing.GlobalTracer().StartSpan("get user list form database", opentracing.ChildOf(parentSpan.Context()))
	users, err := u.Store.ListUsers(ctx, arg)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "获得用户列表信息失败")
	}
	getUserListSpan.Finish()
    // 追踪结束。
    // 省略其他
}
```




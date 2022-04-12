---
title: 从0到1实现完整的微服务框架-服务注册、发现、配置中心
tags:
  - 微服务
  - gRPC
  - 配置中心
  - 服务发现
  - 服务注册
categories:
  - - 微服务
  - - gRPC
  - - 配置中心
  - - 服务发现
  - - 服务注册
slug: /5763d21a
date: 2022-03-28 13:08:53
series: [ "从0到1实现完整的微服务框架" ] 
---

当某一个服务要以集群的形式进行部署，这时候就要用到服务注册和服务发现。主要介绍使用consul进行服务发现、服务注册以及配置中心。

<!--more-->

​	假如这个产品已经在线上运行，有一天运营想搞一场促销活动，那么我们相对应的【用户服务】可能就要新开启三个微服务实例来支撑这场促销活动。而与此同时，作为苦逼程序员的你就只有手动去 API gateway 中添加新增的这三个微服务实例的 ip 与port ，一个真正在线的微服务系统可能有成百上千微服务，难道也要一个一个去手动添加吗？有没有让系统自动去实现这些操作的方法呢？答案当然是有的。
​	当我们新添加一个微服务实例的时候，微服务就会将自己的 ip 与 port 发送到注册中心，在注册中心里面记录起来。当 API gateway 需要访问某些微服务的时候，就会去注册中心取到相应的 ip 与 port。从而实现自动化操作。

## consul安装

```shell
docker run -d -p 8500:8500 -p 8300:8300 -p 8301:8301 -p 8302:8302 -p 8600:8600/udp consul consul agent -dev -client=0.0.0.0
```

`8600`dns端口,`8500`http端口

## grpc的健康检查

```go
import (
    "google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
)
	// 注册 grpc 健康检查
	grpc_health_v1.RegisterHealthServer(server, health.NewServer())
```

只需在`shop\service\user_srv\main.go`main方法中的注册服务之后添加这一句就可以

```go
	// 省略之前的
	server := grpc.NewServer()
	sqlStore := model.NewSqlStore(global.DB)
	userServer := handler.UserServer{Store: sqlStore}

	port, err := util.GetFreePort()
	...
	proto.RegisterUserServer(server, &userServer)
	... 省略listen
	// 注册 grpc 健康检查
	grpc_health_v1.RegisterHealthServer(server, health.NewServer())

```

## 将grpc的服务注册到consul

添加consul的配置`shop\service\user_srv\config\consul_info.go`

```go
type ServerConfig struct{
    Host string `mapstructure:"host"` // 服务启动的host
	Port int    `mapstructure:"port"` // 服务启动的port
	Name string `mapstructure:"name"` // 服务的名称
    Consul 	Consul `mapstructure:"consul"` // consul的配置
}

type Consul struct {
    Host string `mapstructure:"host"` // consul的host
	Port int    `mapstructure:"port"` // consul的port
}
```

这里问什么要在`severConfig`中添加一个`name`，是因为每一个服务都有一个自己的服务名称，在http客户端之后找服务的时候就找服务名下的一个服务就行。

在`main`中

```go
import(
    "github.com/hashicorp/consul/api
)

func main(){
	// consul服务注册
	apiCfg := api.DefaultConfig()
	apiCfg.Address = fmt.Sprintf("%s:%d",
		global.ServerConfig.Consul.Host,
		global.ServerConfig.Consul.Port,
	)
    client, err := api.NewClient(apiCfg)
	if err != nil {
		global.Logger.Fatal(err.Error())
	}

	// 检查对象 consul 做健康检查的ip
	check := api.AgentServiceCheck{
		GRPC: fmt.Sprintf("%s:%d",
			global.ServerConfig.Host, // 这里就是你要检测那个服务的host和port
			global.ServerConfig.Port,
		),
		Timeout:                        "3s",
		Interval:                       "5s",
		DeregisterCriticalServiceAfter: "100s", // 健康检查失败超过100s之后就会删除这个服务
	}
    // 一个服务中可以
    var serviceID uuid.UUID
	for {
		serviceID, err = uuid.NewRandom()
		if err == nil {
			break
		}
	}

	// consul 做健康检查的ip
	serviceRegistration := api.AgentServiceRegistration{
		ID:      serviceID.String(),
		Name:    global.RemoteConfig.ServiceInfo.Name,
		Port:    global.RemoteConfig.ServiceInfo.Port,
		Address: global.RemoteConfig.ServiceInfo.Host,
	}

	serviceRegistration.Check = &check
	err = client.Agent().ServiceRegister(&serviceRegistration)
	if err != nil {
		log.Fatalln("注册失败", err)
	}
	global.Logger.Info("启动 grpc 健康检查")
    
}
```

至此，已经将gRPC的服务注册到consul中去了。

## 在api中服务发现

同样我们添加`consul`的配置

```yaml
name: 'user-api'
port: 8021

consul-info:
  host: "192.168.0.2"
  port: 8500
```

在之前的初始化`UserClient`时，我们是写死的host:port这时候，我们可以使用

```go
import(
    "fmt"

	"github.com/hashicorp/consul/api"
)
// 部分import

func InitSrvConn() {
	cfg := api.DefaultConfig()
	cfg.Address = fmt.Sprintf("%s:%d",
		global.ServerConfig.ConsulInfo.Host,
		global.ServerConfig.ConsulInfo.Port,
	)
    // 连接到consul
	client, err := api.NewClient(cfg)
	if err != nil {
		global.Logger.Fatal("创建 consul 客户端失败", zap.Error(err))
	}
	// 这里一定要有 ""
    // 从consul中拉取服务，这里的服务也是从配置文件中拉
	services, err := client.Agent().ServicesWithFilter(fmt.Sprintf(`Service == "%s"`, 		global.ServerConfig.UserSrv.Name))
	if err != nil {
		global.Logger.Fatal("获取服务失败", zap.Error(err))
	}
	var userSrvHost string
	var userSrvPort int
	for _, value := range services {
		userSrvPort = value.Port
		userSrvHost = value.Address
		break
	}
    // 在拿到host和post之后，就和之前的一样了。
    // 关键是拿到 host和port
    
```

## 用consul做注册中心

在consul是有存储kv的数据库，基于这个我们就可以将配置保存在consul中。具体的实现也很简单，之前我们用viper读本地的配置文件，而viper的强大在于他也能读远程的配置文件。

这时候，我们本地只需要保存consul的配置就行，首先加载consul的位置，之后从consul中读取配置文件，就可以。

`shop\api\user-api\initialize\config.go`这是api的加载配置文件，同样，srv也是一样的。

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

func getEnvBool(env string) bool {
	viper.AutomaticEnv()
	return viper.GetBool(env)
}

// LoadConsulConfigInfo 加载本地的 consul 文件
func LoadConsulConfigInfo() {
	configFilePath := "consul-info.yaml"

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
	if err := v.Unmarshal(&global.ConsulCenterInfo); err != nil {
		global.Logger.Fatal("解析配置文件失败....",
			zap.Error(err),
			zap.String("path", configFilePath),
		)
	}
	global.Logger.Info("成功加载配置文件",
		zap.String("path", configFilePath),
		zap.Any("content", global.ConsulCenterInfo),
	)
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
		if err := v.Unmarshal(&global.ConsulCenterInfo); err != nil {
			global.Logger.Fatal("解析配置文件出错",
				zap.String("field", in.String()),
				zap.Error(err),
			)
		}
		global.Logger.Info("配置文件内容", zap.Any("config", global.ConsulCenterInfo))
	})
}

func LoadRemoteConfig() {
	remoteViper := viper.New()
	path := global.ConsulCenterInfo.ReleasePath
	if debug := getEnvBool(global.ConsulCenterInfo.EnvName); debug {
		path = global.ConsulCenterInfo.DebugPath
	}
	remoteViper.SetConfigType(global.ConsulCenterInfo.FileType)
	err := remoteViper.AddRemoteProvider(global.ConsulCenterInfo.Type,
		fmt.Sprintf("%s:%d", global.ConsulCenterInfo.Host,
			global.ConsulCenterInfo.Port,
		),
		path,
	)
	if err != nil {
		global.Logger.Fatal("添加配置文件失败", zap.Error(err))
		return
	}

	err = remoteViper.ReadRemoteConfig()
	if err != nil {
		global.Logger.Fatal("读取远端配置文件失败", zap.Error(err))
	}
	err = remoteViper.Unmarshal(&global.ServerConfig)
	if err != nil {
		global.Logger.Fatal("解析远端配置文件失败", zap.Error(err))
	}
	global.Logger.Info("成功加载远端配置文件....", zap.Any("config", global.ServerConfig))
}
```

`debug.yaml`远程的配置文件的内容

```yaml
name: 'user-api'
port: 8021

user-srv:
  host: '192.168.0.2'
  host-port: 50051
  name: "user-srv"

consul-info:
  host: "192.168.0.2"
  port: 8500
```

```yaml
host: "192.168.0.2"
port: 8500
release-path: "shop/user/api/release.yaml"
debug-path: "shop/user/api/debug.yaml"   
file-type: "yaml"
type: "consul"
env-name: "shop_debug"
```




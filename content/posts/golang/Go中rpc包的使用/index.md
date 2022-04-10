---
title: Go中rpc包的使用
tags:
  - Go
  - RPC
  - 教程
categories:
  - - Go
  - - RPC
  - - 教程
slug: ../11a90fe7
date: 2022-03-25 14:15:03
---

Go语言的RPC包的路径为`net/rpc`，也就是放在了net包目录下面。因此我们可以猜测该RPC包是建立在net包基础之上的。我们基于http实现了一个打印例子。下面我们尝试基于rpc实现一个类似的例子。

<!--more-->

### 服务端

```go
packagemain

import(
	"log"
	"net"
	"net/rpc"
)

type HelloServicestruct{
}

func(s*HelloService)Hello(request string, reply*string)error{
	//返回值是通过修改request的值
	*reply = "Hello" + request
	return nil
}

func main(){

	//1.实例化一个server
	listener,err:=net.Listen("tcp",":1234")
	if err!=nil{
		log.Fatalln(err)
	}
	//2.注册处理逻辑
	err=rpc.RegisterName("HelloService",&HelloService{})
	if err!=nil{
		return
	}
	//3.启动服务
	conn,err:=listener.Accept()//当一个新的链接进来的时候，
	rpc.ServeConn(conn)

//一连串的代码大部分都是net的包好像和rpc没有什么关系
//1.go语言的rpc序列化的反序列协议是Gob
}
```

其中Hello方法必须满足Go语言的RPC规则：

1. 方法只能有两个可序列化的参数，其中第二个参数是指针类型，并且返回一个error类型，同时必须是公开的方法。

然后就可以将`HelloService`类型的对象注册为一个RPC服务：(TCP RPC服务)。

其中`rpc.Register()`函数调用会将对象类型中所有满足RPC规则的对象方法注册为RPC函数，所有注册的方法会放在`“HelloService”`服务空间之下。

然后我们建立一个唯一的TCP链接，并且通过`rpc.ServeConn()`函数在该TCP链接上为对方提供RPC服务。

### 客户端

```go
package main

import(
	"log"
	"net/rpc"
)

func main(){

	//1.建立连接
	client,err:=rpc.Dial("tcp","localhost:1234")
	if err!=nil{
		log.Fatalln(err)
	}
	var reply=new(string)//在内存中分配变量，并把指针赋值给变量
	//varreplystring//此时的string已经有地址了，而且还有零值使用&reply传递参数
	//这里调用的服务的方法是服务名.方法名
	err=client.Call("HelloService.Hello","jimyag",reply)
	if err!=nil{
		log.Fatalln(err)
	}
	log.Printf(*reply)
}
```

首先是通过rpc.Dial拨号RPC服务，然后通过client.Call调用具体的RPC方法。在调用client.Call时，第一个参数是用点号链接的RPC服务名字和方法名字，第二和第三个参数分别我们定义RPC方法的两个参数。

### 改进rpc的调用过程

#### 改进1

前面的rpc调用虽然简单，但是和普通的http的调用差异不大，这次我们解决下面的问题

1. serviceName统一和名称冲突的问题
   - 多个server的包中serviceName同名的问题
   - server端和client端如何统一serviceName

上述实现中服务名称是在客户端和服务端写死的，如果有一方改动，那么双方都要改动

目录结构

```shell
.
├── client
│   └── main.go
├── handle
│   └── handle.go
└── server
    └── main.go
```

新建`handler/handler.go`文件内容如下： 

```go
package handle

const (
    // 解决命名冲突
	HelloServiceName = "handle/HelloService"
)
```

为什么要新建这个文件？

是为了解耦。

##### 服务端

```go
package main

import (
	"net"
	"net/rpc"

	"test-rpc/handle" // 自己的包名
)

type HelloService struct {
}

func (S *HelloService) Hello(request string, reply *string) error {
	*reply = "hello " + request
	return nil
}
func main() {
	_ = rpc.RegisterName(handle.HelloServiceName, &HelloService{})
	lisener, err := net.Listen("tcp", ":1234")
	if err != nil {
		panic("监听端口失败")
	}
	conn, err := lisener.Accept()
	if err != nil {
		panic("建立连接失败")
	}

	rpc.ServeConn(conn)
}
```

##### 客户端

```go
package main

import (
   "fmt"
   "net/rpc"

   "test-rpc/handle" // 自己的包名
)

func main() {
   client, err := rpc.Dial("tcp", "localhost:1234")
   if err != nil {
      panic("连接到服务器失败")
   }

   var reply string
    // 只要加上调用的方法名即可
   err = client.Call(handle.HelloServiceName+".Hello", "jimyag", &reply)
   if err != nil {
      panic("服务调用失败")
   }

   fmt.Println(reply)
}
```

#### 改进2

以上，我们解耦了服务名。但是，对于服务端和客户端来说，他们只要管调用相关的方法就行，不要管相关的实现。

那么我们可以封装一个client和server端的代理，让client和server端就像调用本地方法一样。

继续屏蔽`HelloserviceName`和`Hello`函数名称

##### 目录结构

```shell
.
├── client
│   └── main.go
├── client_proxy
│   └── client_proxy.go
├── handle
│   └── handle.go
├── server
│   └── main.go
└── server_porxy
    └── server_proxy.go
```

##### `handle.go`

```go
package handle

type HelloService struct{}

func (s *HelloService) Hello(request string, reply *string) error {
   *reply = "hello " + request
   return nil
}
```

##### `server_proxy.go`

在提供的服务中通过interface进行封装，在这里我们关心的调用的函数，而不是某个结构体。所以封装的时候传入的参数为interface

```go
package server_porxy

import "net/rpc"

const HelloServiceName = "handler/HelloService"

type HelloServiceInterface interface {
   Hello(request string, reply *string) error
}

// 封装服务的注册
func RegisterHelloService(srv HelloServiceInterface) error {
   return rpc.RegisterName(HelloServiceName, srv)
}
```

##### `server.go`

服务端调用的时候,就可以直接注册一个hello的服务。

```go
package main

import (
   "net"
   "net/rpc"

   "test-rpc3/handle" // 项目包名
   "test-rpc3/server_porxy" // 项目包名
)

func main() {
   helloHandler := &handle.HelloService{}
   _ = server_porxy.RegisterHelloService(helloHandler)
   listener, err := net.Listen("tcp", ":1234")
   if err != nil {
      panic("监听端口失败")
   }
   conn, err := listener.Accept()
   if err != nil {
      panic("建立链接失败")
   }
   rpc.ServeConn(conn)
}
```

##### `client_proxy.go`

客户端调用远程的方法时候，要像调用本地方法一样进行调用。封装一个hello的client，只需要调用client里面的方法就行。

```go
package client_proxy

import "net/rpc"

const HelloServiceName = "handler/HelloService"

// 将hello client暴露出去
type HelloServiceClient struct {
   *rpc.Client
}

func NewClient(address string) HelloServiceClient {
   conn, err := rpc.Dial("tcp", address)
   if err != nil {
      panic("连接服务器错误")
   }
   return HelloServiceClient{conn}
}

func (c *HelloServiceClient) Hello(request string, reply *string) error {
   err := c.Call(HelloServiceName+".Hello", request, reply)
   if err != nil {
      return err
   }
   return nil
}
```

##### `client.go`

```go
package main

import (
   "fmt"

   "test-rpc3/client_proxy"
)

func main() {
   client := client_proxy.NewClient("localhost:1234")
   var reply string
   err := client.Hello("jimyag", &reply)
   if err != nil {
      panic("调用失败")
   }
   fmt.Println(reply)
}
```

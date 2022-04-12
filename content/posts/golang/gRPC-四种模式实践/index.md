---
title: gRPC-四种模式实践
tags:
  - 教程
  - gRPC
categories:
  - - 教程
  - - gRPC
slug: /3259ac99
date: 2022-03-09 09:41:28
---

本文介绍如何使用gRPC的四种模式

gRPC共有四种模式：简单模式、服务端流模式、客户端流模式、双向流模式。

<!--more-->

在开始之前，我们首先新建`proto/hello.proto`文件

```protobuf
// 表示当前使用的语法版本
syntax = "proto3";

//.代表当前文件夹，分号后面是生成go文件引入的包名，abc具体的值根据项目需求而定。
// 生成.go 文件的package
option go_package = ".;abc";


// 定义一个Request
// 类型 变量名 标志（标志在相同目录中必须唯一）
message LoginRequest{
  string username = 1;
  string password = 2;
}

message LoginResponse{
  int32 code = 1;
  string meg = 2;
}

// 定义一个服务
service HelloService{
  // 一元到一元 的服务
  rpc HelloUnaryToUnary(LoginRequest) returns(LoginResponse){};
  // 一元到流的服务 服务端流
  rpc HelloUnary2Stream(LoginRequest) returns(stream LoginResponse){};
  // 流到一元的服务 客户端流
  rpc HelloStream2Unary(stream LoginRequest) returns(LoginResponse){};
  // 双向流的服务
  rpc HelloStream2Stream(stream LoginRequest) returns(stream LoginResponse){};
}

```

在此之前我们还要下载go的依赖

在项目中

```powershell
go mod init test
go get -u google.golang.org/grpc
go get -u github.com/golang/protobuf
go get -u github.com/golang/protobuf/protoc-gen-go
go get github.com/google/uuid
```

此外还要安装`protoc`安装完成之后，在项目根目录执行

```powershell
protoc --proto_path=proto proto/*.proto --go_out=plugins=grpc:./proto
```

在proto文件下就会有`hello.pb.go`生成。

### 简单模式

类似于普通的http请求，客户端请求request服务端进行响应response。

我说一句话你说一句话。

我们首先实现客户端。`client/main.go`

```go
package main

import (
	"context"
	"fmt"
	"github.com/google/uuid"
	"google.golang.org/grpc"
	"io"
	"log"
	abc "test/proto"
)

func main() {
    // 1. 创建一个连接 
	conn, err := grpc.Dial("127.0.0.1:8888", grpc.WithInsecure())
	if err != nil {
		log.Fatal("cannot dial server :", err)
	}
    // 记着close
	defer conn.Close()

    // 2. 创建一个client proto生成的go文件中有一个创建 client的方法
	client := abc.NewHelloServiceClient(conn)
	
    // 客户端
	{
        
        req := &abc.LoginRequest{Username: "admin", Password: "123456"}
        // 3. 调用服务，传一个request
		response, err := client.HelloUnaryToUnary(context.Background(), req)
		if err != nil {
			log.Fatalf("cannot receive response :%v", err)
		}
		
		log.Printf("response :%v\n", response)
	}
```

实现服务端`server/server/hello_service.go`

```go
package server

import (
	"github.com/google/uuid"
	"golang.org/x/net/context"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"io"
	"log"
	abc "test/proto"
)

// 定义server的结构体
type HelloServer struct {
}

func NewHelloServer() *HelloServer {
	return &HelloServer{}
}

// 实现一元-一元服务
func (server *HelloServer) HelloUnaryToUnary(ctx context.Context, req *abc.LoginRequest) (*abc.LoginResponse, error) {
    // 这是一个简单是示例，所以就直接写死了
    // 拿到 request ，如果符合要求就响应 成功，不符合要求就响应 没有该用户。
	if req.GetUsername() == "admin" && req.GetPassword() == "123456" {
		log.Printf("request :%v", req)
		resp := &abc.LoginResponse{
			Code: 200,
			Meg:  "成功",
		}
		return resp, nil
	} else {
		resp := &abc.LoginResponse{
			Code: 404,
			Meg:  "没有该用户",
		}
		return resp, nil
	}
}

// 空实现
func (server *HelloServer) HelloUnary2Stream(req *abc.LoginRequest, stream abc.HelloService_HelloUnary2StreamServer) error {
	return nil
}
// 空实现
func (server *HelloServer) HelloStream2Unary(stream abc.HelloService_HelloStream2UnaryServer) error {
	return nil
}
// 空实现
func (server *HelloServer) HelloStream2Stream(stream abc.HelloService_HelloStream2StreamServer) error {
	return nil
}
```

实现服务端`server/main.go`

```go
package main

import (
	"google.golang.org/grpc"
	"log"
	"net"
	abc "test/proto"
	"test/server/server"
)

func main() {
    // 1. 拿出服务
	grpcSever := grpc.NewServer()

	// 2. 挂载方法 就是上面实现的方法
	helloService := server.NewHelloServer()
    
    // 3. 注册服务
	abc.RegisterHelloServiceServer(grpcSever, helloService)
	log.Printf("gRPC is running ......")

    // 4. 创建监听
	listen, err := net.Listen("tcp", ":8888")
	if err != nil {
		log.Fatalf("cannot listen port 8888 :%v", err)
	}
	err = grpcSever.Serve(listen)
	if err != nil {
		log.Fatalf("gRPC server err: %s\n", err)
	}
}
```

我们分别启动服务端和客户端。

在`server/`目录

```powershell
go run .\main.go
2022/03/09 10:15:08 gRPC is running ......
2022/03/09 10:15:22 request :username:"admin"  password:"123456"
```

在`client/`目录

```powershell
go run .\main.go
2022/03/09 10:15:22 response :code:200 meg:"成功"
```

现在我们就实现了一个简单的一元服务。

### 服务端流模式

客户端发送一个request，服务端的是一个响应流。

我说一句话，你说一大堆。

`client.go`中括号以外的内容都能复用。

```go
{
    // 客户端向服务端发一条消息，
	stream, err := client.HelloUnary2Stream(context.Background(), req)
	if err != nil {
		log.Fatalf("cannot receiver stream :%v", err)
    }
	// 客户端不断收服务端的消息流
	for {
        // 接受服务端的流
		resp, err := stream.Recv()
        // 没有错误就是收到了
		if err == nil {
			log.Printf("receiver :%v", resp)
		}
        // 接受完了就要结束了
		if err == io.EOF {
			log.Printf("receiver end...")
			break
		}
		if err != nil {
			log.Fatalf("unknow error:%v", err)
		}
	}
    // 接受完了之后关闭通道
    err=  stream.CloseSend()
	if err!=nil{
		log.Fatal("cannot close stream")
	}
    
}
```

实现`func (server *HelloServer) HelloUnary2Stream(req *abc.LoginRequest, stream abc.HelloService_HelloUnary2StreamServer) error`方法

```go
func (server *HelloServer) HelloUnary2Stream(req *abc.LoginRequest, stream abc.HelloService_HelloUnary2StreamServer) error {
	// 服务端收到一条消息
	log.Printf("request :%v", req)
	// 不断向客服端发消息
	for i := 0; i < 10; i++ {
		username, _ := uuid.NewRandom()
		response := &abc.LoginResponse{Code: int32(i), Meg: username.String()}
		err := stream.Send(response)
		log.Printf("send %v %v", response.Code, response.Meg)
		if err != nil {
			return err
		}
	}
	return nil
}
```

服务端

```go
PS D:\code\go\test\server> go run .\main.go
2022/03/09 10:34:28 gRPC is running ......
2022/03/09 10:34:35 request :username:"admin"  password:"123456"
2022/03/09 10:34:35 send 0 6497cd6a-11ce-4d76-b9a6-7e2da224199b
2022/03/09 10:34:35 send 1 1119826f-c7c1-41cb-8d17-19c827d53281
2022/03/09 10:34:35 send 2 7c90922f-212d-4524-b225-d6c2c2e0977a
2022/03/09 10:34:35 send 3 11cafa80-ce70-4e22-98a4-6af1e6c2b545
2022/03/09 10:34:35 send 4 ed87b66c-6d18-4de8-9285-d8587a8f6a53
2022/03/09 10:34:35 send 5 a0db893c-9dfa-4dac-9b77-a39e88763f0d
2022/03/09 10:34:35 send 6 9914e70f-a732-4002-b000-7ded2c66918e
2022/03/09 10:34:35 send 7 b0933c28-078c-48c6-903d-b3b936fa325f
2022/03/09 10:34:35 send 8 e24a9de1-f662-47c9-b7ea-bd9126687b97
2022/03/09 10:34:35 send 9 18e6e09a-206c-4240-9a27-2f27cf5fa0e0
```

客户端

```go
2022/03/09 10:34:35 receiver :meg:"6497cd6a-11ce-4d76-b9a6-7e2da224199b"
2022/03/09 10:34:35 receiver :code:1  meg:"1119826f-c7c1-41cb-8d17-19c827d53281"
2022/03/09 10:34:35 receiver :code:2  meg:"7c90922f-212d-4524-b225-d6c2c2e0977a"
2022/03/09 10:34:35 receiver :code:3  meg:"11cafa80-ce70-4e22-98a4-6af1e6c2b545"
2022/03/09 10:34:35 receiver :code:4  meg:"ed87b66c-6d18-4de8-9285-d8587a8f6a53"
2022/03/09 10:34:35 receiver :code:5  meg:"a0db893c-9dfa-4dac-9b77-a39e88763f0d"
2022/03/09 10:34:35 receiver :code:6  meg:"9914e70f-a732-4002-b000-7ded2c66918e"
2022/03/09 10:34:35 receiver :code:7  meg:"b0933c28-078c-48c6-903d-b3b936fa325f"
2022/03/09 10:34:35 receiver :code:8  meg:"e24a9de1-f662-47c9-b7ea-bd9126687b97"
2022/03/09 10:34:35 receiver :code:9  meg:"18e6e09a-206c-4240-9a27-2f27cf5fa0e0"
2022/03/09 10:34:35 receiver end...
```

### 客户端流模式

客户端发送流，服务端只是一个响应。

我说了一大堆，你回了一句话。

`client.go`

```go
{
	stream, err := client.HelloStream2Unary(context.Background())
	if err != nil {
		log.Fatal("cannot send ")
	}

	// 发送10条请求流
	for i := 0; i < 10; i++ {
		req := &abc.LoginRequest{Username: uuid.NewString(), Password: uuid.NewString()}
		err := stream.Send(req)
		if err != nil {
			log.Fatalf("cannot send %v ,err:%v", req, err)
		}
	}
	log.Printf("send end...")
	// 关闭 发送通道
	err = stream.CloseSend()
	if err != nil {
		log.Fatal("cannot close stream")
	}
	// 接受响应
	res, err := stream.CloseAndRecv()
	if err != nil {
		log.Fatal("cannot receive response")
	}
	log.Printf("receive response %v", res)
}
```

`server.go`

```go
func (server *HelloServer) HelloStream2Unary(stream abc.HelloService_HelloStream2UnaryServer) error {
   for {
      req, err := stream.Recv()
      if err == io.EOF {
         log.Print("no more data")
         break
      }
      if err != nil {
         return logErr(status.Errorf(codes.Unknown, "cannot receive request"))
      }

      log.Printf("receiver :%v", req)
   }
   err := stream.SendAndClose(&abc.LoginResponse{Code: 200, Meg: "接受完毕"})
   if err != nil {
      return logErr(status.Errorf(codes.Unknown, "cannot send response"))
   }
   return nil
}
```

服务端

```powershell
2022/03/09 10:53:26 receiver :username:"6a57a4d0-aaa3-41de-bd16-2da29d3a0ff5" password:"1aade1e4-135d-4734-a29c-6a3fd23a5597"
2022/03/09 10:53:26 receiver :username:"7e04862e-efae-439e-94e5-ee0e394002d6" password:"2837e260-c90a-433c-9822-a378ff99fbe9"
2022/03/09 10:53:26 receiver :username:"4204b5b5-3df0-4a61-91f1-6940b14e809f" password:"c139d1f7-89c0-4628-961b-db3c0b2fa23a"
2022/03/09 10:53:26 receiver :username:"52c5153d-f35d-4bc6-ad8c-127df19250fe" password:"1985a5cc-b200-431c-959e-9220a1c8fa85"
2022/03/09 10:53:26 receiver :username:"6f0fc379-93c9-46f5-a374-9d9851a9f56a" password:"2166039e-1b97-4887-a0d1-d6a61bafef87"
2022/03/09 10:53:26 receiver :username:"da7e2195-ec64-448c-b8e6-1e58580b1637" password:"279d7b32-ffcd-4be2-8111-e0cb557e6bd0"
2022/03/09 10:53:26 receiver :username:"7dc698a9-e77a-491d-99f3-d36f17f8ffc0" password:"1b449f77-c6e1-413d-a88f-6b7a8f7b1bb7"
2022/03/09 10:53:26 receiver :username:"186de3d9-de9c-4243-aef7-fc9800991349" password:"731f6ef2-8241-400e-bc57-509cb8cc75e8"
2022/03/09 10:53:26 receiver :username:"5fa98e03-4a95-4653-bc1a-4f0356bcca07" password:"f3cc126c-b4c8-474a-b93e-6d4064545f84"
2022/03/09 10:53:26 receiver :username:"b2157cc2-8244-4e10-887f-b82e29617ce2" password:"f0a5c65e-dcf9-454e-88dd-0b985c2a7cdf"
2022/03/09 10:53:26 no more data
```

客户端

```powershell
go run .\main.go
2022/03/09 10:53:26 send req :username:"6a57a4d0-aaa3-41de-bd16-2da29d3a0ff5" password:"1aade1e4-135d-4734-a29c-6a3fd23a5597"
2022/03/09 10:53:26 send req :username:"7e04862e-efae-439e-94e5-ee0e394002d6" password:"2837e260-c90a-433c-9822-a378ff99fbe9"
2022/03/09 10:53:26 send req :username:"4204b5b5-3df0-4a61-91f1-6940b14e809f" password:"c139d1f7-89c0-4628-961b-db3c0b2fa23a"
2022/03/09 10:53:26 send req :username:"52c5153d-f35d-4bc6-ad8c-127df19250fe" password:"1985a5cc-b200-431c-959e-9220a1c8fa85"
2022/03/09 10:53:26 send req :username:"6f0fc379-93c9-46f5-a374-9d9851a9f56a" password:"2166039e-1b97-4887-a0d1-d6a61bafef87"
2022/03/09 10:53:26 send req :username:"da7e2195-ec64-448c-b8e6-1e58580b1637" password:"279d7b32-ffcd-4be2-8111-e0cb557e6bd0"
2022/03/09 10:53:26 send req :username:"7dc698a9-e77a-491d-99f3-d36f17f8ffc0" password:"1b449f77-c6e1-413d-a88f-6b7a8f7b1bb7"
2022/03/09 10:53:26 send req :username:"186de3d9-de9c-4243-aef7-fc9800991349" password:"731f6ef2-8241-400e-bc57-509cb8cc75e8"
2022/03/09 10:53:26 send req :username:"5fa98e03-4a95-4653-bc1a-4f0356bcca07" password:"f3cc126c-b4c8-474a-b93e-6d4064545f84"
2022/03/09 10:53:26 send req :username:"b2157cc2-8244-4e10-887f-b82e29617ce2" password:"f0a5c65e-dcf9-454e-88dd-0b985c2a7cdf"
2022/03/09 10:53:26 send end...
2022/03/09 10:53:26 receive response code:200 meg:"接受完毕"
```

### 双向流模式。

两个都不断在向对方发送流。

两个人都在不断说话。可能是你说一句我回0-N句，我说一句你回0-N。

`client.go`

```go
{
		stream, err := client.HelloStream2Stream(context.Background())
		if err != nil {
			log.Fatalf("unknow error %v", err)
		}
		// 由于双方都需要不断发收，所以不能阻塞在一处，通过 chan 进行error的通信
		waitResponse := make(chan error)
		// 开启一个携程，专门收
		go func() {
			for {
				res, err := stream.Recv()
				if err == io.EOF {
					log.Printf("no more response")
					waitResponse <- nil
					return
				}
				if err != nil {
					waitResponse <- fmt.Errorf("cannot receive stream response %v", err)
					return
				}

				log.Printf("received response :%v", res)
			}
		}()

		// 继续发
		for i := 0; i < 10; i++ {
			req := &abc.LoginRequest{Username: uuid.NewString(), Password: uuid.NewString()}
			err := stream.Send(req)
			log.Printf("send %v", req)
			if err != nil {
				log.Fatal("unknow")
			}
		}
		// 关闭发送
		err = stream.CloseSend()
		if err != nil {
			log.Fatal(err)
		}
		// 如果没有遇到error 会一直阻塞到这，直到遇到error
		err = <-waitResponse
		log.Printf("end  %v", err)

	}
```

`server.go`

```go
func (server *HelloServer) HelloStream2Stream(stream abc.HelloService_HelloStream2StreamServer) error {
   for {
      // 不断接受
      req, err := stream.Recv()
      if err == io.EOF {
         log.Printf("no more data")
         break
      }
      if err != nil {
         return logErr(status.Errorf(codes.Unknown, "cannot receive stream request :%v", err))
      }

      log.Printf("receive data: %v  %v", req.Username, req.Password)

      // 将接受到的发送
      res := &abc.LoginResponse{Code: 200, Meg: "receive data username " + req.Username}
      err = stream.Send(res)
      if err != nil {
         return logErr(status.Errorf(codes.Unknown, "cannot send response %v", err))
      }

   }
   return nil
}

// 打印并返回
func logErr(err error) error {
   if err != nil {
      log.Print(err)
   }
   return err
}
```

服务端

```
2022/03/09 10:53:26 receiver :username:"6a57a4d0-aaa3-41de-bd16-2da29d3a0ff5" password:"1aade1e4-135d-4734-a29c-6a3fd23a5597"
2022/03/09 10:53:26 receiver :username:"7e04862e-efae-439e-94e5-ee0e394002d6" password:"2837e260-c90a-433c-9822-a378ff99fbe9"
2022/03/09 10:53:26 receiver :username:"4204b5b5-3df0-4a61-91f1-6940b14e809f" password:"c139d1f7-89c0-4628-961b-db3c0b2fa23a"
2022/03/09 10:53:26 receiver :username:"52c5153d-f35d-4bc6-ad8c-127df19250fe" password:"1985a5cc-b200-431c-959e-9220a1c8fa85"
2022/03/09 10:53:26 receiver :username:"6f0fc379-93c9-46f5-a374-9d9851a9f56a" password:"2166039e-1b97-4887-a0d1-d6a61bafef87"
2022/03/09 10:53:26 receiver :username:"da7e2195-ec64-448c-b8e6-1e58580b1637" password:"279d7b32-ffcd-4be2-8111-e0cb557e6bd0"
2022/03/09 10:53:26 receiver :username:"7dc698a9-e77a-491d-99f3-d36f17f8ffc0" password:"1b449f77-c6e1-413d-a88f-6b7a8f7b1bb7"
2022/03/09 10:53:26 receiver :username:"186de3d9-de9c-4243-aef7-fc9800991349" password:"731f6ef2-8241-400e-bc57-509cb8cc75e8"
2022/03/09 10:53:26 receiver :username:"5fa98e03-4a95-4653-bc1a-4f0356bcca07" password:"f3cc126c-b4c8-474a-b93e-6d4064545f84"
2022/03/09 10:53:26 receiver :username:"b2157cc2-8244-4e10-887f-b82e29617ce2" password:"f0a5c65e-dcf9-454e-88dd-0b985c2a7cdf"
2022/03/09 10:53:26 no more data
```



客户端

```powershell
go run .\main.go
2022/03/09 10:53:26 send req :username:"6a57a4d0-aaa3-41de-bd16-2da29d3a0ff5" password:"1aade1e4-135d-4734-a29c-6a3fd23a5597"
2022/03/09 10:53:26 send req :username:"7e04862e-efae-439e-94e5-ee0e394002d6" password:"2837e260-c90a-433c-9822-a378ff99fbe9"
2022/03/09 10:53:26 send req :username:"4204b5b5-3df0-4a61-91f1-6940b14e809f" password:"c139d1f7-89c0-4628-961b-db3c0b2fa23a"
2022/03/09 10:53:26 send req :username:"52c5153d-f35d-4bc6-ad8c-127df19250fe" password:"1985a5cc-b200-431c-959e-9220a1c8fa85"
2022/03/09 10:53:26 send req :username:"6f0fc379-93c9-46f5-a374-9d9851a9f56a" password:"2166039e-1b97-4887-a0d1-d6a61bafef87"
2022/03/09 10:53:26 send req :username:"da7e2195-ec64-448c-b8e6-1e58580b1637" password:"279d7b32-ffcd-4be2-8111-e0cb557e6bd0"
2022/03/09 10:53:26 send req :username:"7dc698a9-e77a-491d-99f3-d36f17f8ffc0" password:"1b449f77-c6e1-413d-a88f-6b7a8f7b1bb7"
2022/03/09 10:53:26 send req :username:"186de3d9-de9c-4243-aef7-fc9800991349" password:"731f6ef2-8241-400e-bc57-509cb8cc75e8"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username 4b6bcd51-652a-4a8c-af34-85a667ad4957"
2022/03/09 10:56:49 send username:"d9a3e249-c85e-4a4f-84a5-e43a787dced0" password:"e5e34dbb-585e-4b5e-83f4-e38f367f8bc0"
2022/03/09 10:56:49 send username:"1905bdd1-0a77-4d34-ae38-102038d8a4a9" password:"93bd9964-9c15-40a8-8005-f84d8aada832"
2022/03/09 10:56:49 send username:"a1d2b612-03b5-4166-aa1a-ea29e27c8f9e" password:"5b7d1fec-fba3-4120-b24b-8ee6c8f34713"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username 12903ede-ead0-48d9-8240-6f51c9816ac1"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username 91e8bf53-38c7-493d-b9ab-b3ce273a4780"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username c47db986-b1a1-443b-8e39-e815ea4c65a8"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username f8fa740e-c286-4cc4-829b-d36e571084ab"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username de6112ca-8abf-4c08-9f52-f14f448f5772"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username d9a3e249-c85e-4a4f-84a5-e43a787dced0"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username 1905bdd1-0a77-4d34-ae38-102038d8a4a9"
2022/03/09 10:56:49 received response :code:200 meg:"receive data username a1d2b612-03b5-4166-aa1a-ea29e27c8f9e"
2022/03/09 10:56:49 no more response
2022/03/09 10:56:49 <nil>
```


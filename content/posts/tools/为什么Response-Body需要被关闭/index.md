---
title: 为什么Request.Body需要被关闭
tags:
  - Go
  - 踩坑
  - 源码
categories:
  - Go
  - 踩坑
slug: /60b013aa
date: 2022-02-24 15:31:16
---

面试时被问到为什么request中的body被访问一次就不能再次访问了。

<!--more-->

```go
// Body is the request's body.
//
// For client requests, a nil body means the request has no body, such as a GET request. 
// 对于客户端请求，nil 正文表示请求没有body 例如 GET 请求。
// The HTTP Client's Transport is responsible for calling the Close method.
// 对于HTTP 客户端的传输负责调用 Close 方法。
// For server requests, the Request Body is always non-nil but will return EOF immediately when no body is present.
// 对于服务器请求，Request Body 始终为非 nil，但在没有 body 时将立即返回 EOF。
// The Server will close the request body. The ServeHTTP Handler does not need to.
// Server 将关闭请求正文。ServeHTTP 处理程序不需要这样做。
// Body must allow Read to be called concurrently with Close.
// body 必须允许与"关闭"同时调用"读取"。
// In particular, calling Close should unblock a Read waiting for input.
// 特别是，调用 Close 应取消阻止等待输入的读取。
Body io.ReadCloser


```

以上是http包文档说明。但是为什么body需要被关闭呢，不关闭会如何？

要了解body，首先要了解http事务是如何处理的。http事务是交由底层的Transport处理的。

1. 从连接池获取一个连接，这个连接的功能由3个goroutine协同实现，一个主**goroutine**，一个**readLoop**(net/http/response.go:2052)，一个**writeLoop**(net/http/response.go:2383)，后两个goroutine生命周期和连接一致。

   虽说readLoop和writeLoop名字叫循环（也确实是for循环），但实际上是一次循环就完整处理一个http事务，**循环本身仅仅是为了连接复用**，所以为了便于理解其逻辑可以忽略它的循环结构。

2. 接下来三个goroutine协同完成http事务：

   1. 主goroutine将request同时发给readLoop和writeLoop。
   2. writeLoop发送request，然后将状态（error）发送给主goroutine和readLoop。
   3. readLoop解析头部 ，然后将状态（error）和response发送给主goroutine。
   4. 主goroutine返回用户代码，readLoop等待body读取完成。
   5. readLoop回收连接。

了解http事务的处理流程，然后我们回过头来看看神秘的body到底是什么

```go
//源码版本 1.17
// src/net/http/transfer.go:483 body解析方法
func readTransfer(msg interface{}, r *bufio.Reader) (err error)
...
// src/net/http/transfer.go:560 解析chunked
t.Body = &body{src: internal.NewChunkedReader(r), hdr: msg, r: r, closing: t.Close}

// src/net/http/transfer.go:565 产生eof
t.Body = &body{src: io.LimitReader(r, realLength), closing: t.Close}

// src/net/http/transport.go:2167 发送eof信号
body := &bodyEOFSignal{

// src/net/http/transport.go:2191 gzip解码
resp.Body = &gzipReader{body: body}
```

body实际上是一个嵌套了多层的net.TCPConn：

1. bufio.Reader，这层尝试将多次小的读操作替换为一次大的读操作，减少系统调用的次数，提高性能；
2. io.LimitedReader，tcp连接在读取完body后不会关闭，继续读会导致阻塞，所以需要LimitedReader在body读完后发出eof终止读取；
3. chunkedReader，解析chunked格式编码（如果不是chunked略过）；
4. bodyEOFSignal，在读到eof，或者是提前关闭body时会对readLoop发出回收连接的通知；
5. gzipReader，解析gzip压缩（如果不是gizp压缩略过）；

从上面可以看出如果body既没有被完全读取，也没有被关闭，那么这次http事务就没有完成，除非连接因超时终止了，否则相关资源无法被回收。

如果请求头或响应头指明Connection: close呢？还是无法回收，因为close表示在http事务完成后断开连接，而事务尚未完成自然不会断开，更不会回收。

从实现上看只要body被读完，连接就能被回收，只有需要抛弃body时才需要close，似乎不关闭也可以。但那些正常情况能读完的body，即第一种情况，在出现错误时就不会被读完，即转为第二种情况。而分情况处理则增加了维护者的心智负担，所以始终close body是最佳选择

简单的来说就是，原生的http包里，每发生一次http请求，在过程中会生成两个协程，一个负责写入request (persistConn.writeLoop)，一个负责读response (persistConn.readLoop), 这两个方法，。由于两个协程是用for+select构成的，所以在没有接收到结束信号

- （获取 writeLoop 返回的写入错误
-  pc.closech的关闭信息，
- 连接超时的信息
- readLoop的 resp
- cancel
- ctx done的信息

之前，都会阻塞住，导致goroutine无法退出，当请求量过大时，gotoutine不能及时释放，就会导致gotoutine数量突增。

只要这时候只要你读取完body的内容，他就会自动关闭。这样就可以防止内存泄漏。



参考

[《GO goroutine暴涨与response.Body.Close()的关联》 - 热爱可抵岁月漫长 (jiangailang.cn)](https://www.jiangailang.cn/145.html)

[[golang\]为什么Response.Body需要被关闭 - 简书 (jianshu.com)](https://www.jianshu.com/p/407fada3cc9d)

[Go http 请求（get/post）必须要手动 resp.Body.Close (zhangjiee.com)](http://www.zhangjiee.com/blog/2018/go-http-get-close-body.html)

---
title: 安装Go1.18环境
tags:
  - Go
  - 教程
categories:
  - - Go
  - - 教程
slug: ../1dc739af
date: 2022-03-16 07:33:51
---

Go1.18在今天（3-16）已经发布，Go 1.18 是一个包含大量新功能的版本，同时不仅改善了性能，也对语言本身做了有史以来最大的改变。毫不夸张地说，Go 1.18 的部分设计十多年前，在第一次发布 Go 时就开始了构思(例如泛型，最早的时候在2009年Russ Cox 在博客里面讨论过泛型如何设计https://research.swtch.com/generic)。

如果你想探索使用泛型优化和简化代码的最佳方法。查看最新版本的发行说明(https://go.dev/doc/go1.18) 有更多关于在 Go 1.18 中使用泛型的详细信息。

<!--more-->



### 安装Go1.18

确保已经存在Go环境并且版本大于1.13.

```powershell
go install golang.org/dl/go1.18@latest
```

```go
go1.18 download
```

### 使用

```powershell
go1.18 env
```

配置代理

```powershell
go1.18 env -w GOPROXY=https://goproxy.cn,direct
```

开启go module

```powershell
go1.18 env -w GO111MODULE=on
```



### 参考

[GoCN](https://mp.weixin.qq.com/s/O4EAhlQBJYPJuqK_WIA8dA)

[在同一机器上安装Go的不同版本 | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/17eab2e7/)

---
title: 在同一机器上安装Go的不同版本
tags:
  - Go
  - 教程
categories:
  - - Go
  - - 教程
slug: /17eab2e7
date: 2022-02-17 23:28:32
---

go1.18已经支持泛型，但是目前工作使用的是1.17。如何在不卸载原有版本情况下下载1.18beta版本？

<!--more-->

首先确保机器已经有Go环境。

在[Downloads - The Go Programming Language](https://go.dev/dl/)找到想要下载的版本，我这里是要下载1.18beta2版本的，执行

```shell
go install golang.org/dl/go1.18beta2@latest
```

之后执行

```shell
go install 
```

等待下载完成即可。

查看GOROOT

```shell
C:\Users\jimyag>go1.18beta2 env GOROOT
C:\Users\jimyag\sdk\go1.18beta2
```

在Goland中，`setting->GO->GOROOT` 选择上述的位置（`C:\Users\jimyag\sdk\go1.18beta2`）即可


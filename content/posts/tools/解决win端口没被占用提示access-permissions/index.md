---
title: "解决win端口没被占用提示access Permissions"
date: 2022-04-12T22:32:00+08:00
draft: false
slug: /bf108eb3
tags: ["踩坑","教程"]
categories: ["踩坑","教程"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ ] 
pinned: false
weight: 100
---

Win10端口没被却占用提示`An attempt was made to access a socket in a way forbidden by its access permissions`,我不理解

<!--more-->

搜索发现是`hyper-v`的问题

## 查看动态端口范围

```powershell
netsh int ipv4 show dynamicport tcp

C:\Users\jimyag>netsh int ipv4 show dynamicport tcp

协议 tcp 动态端口范围

启动端口 : 1024
端口数 : 13977
```

我们可以看到Windows系统默认的 `TCP` 动态端口范围为：1024~13977。当我们开启`Hyper-V`后，系统默认会分配给一些保留端口供`Hyper-V` 使用

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
C:\Users\jimyag>netsh interface ipv4 show excludedportrange protocol=tcp

协议 tcp 端口排除范围

开始端口 结束端口

1026 1125
1226 1325
1326 1425
1426 1525
1526 1625
2180 2279
... ...
```

## 解决方案

**`修改动态端口的起始`**

使用管理员身份运行cmd

```powershell
C:\WINDOWS\system32>netsh int ipv4 set dynamicport tcp start=49152 num=16383
确定。


C:\WINDOWS\system32>netsh int ipv4 set dynamicport udp start=49152 num=16383
确定。
```

然后检查结果

```powershell
C:\Users\jimyag>netsh int ipv4 show dynamicport tcp

协议 tcp 动态端口范围
---------------------------------
启动端口        : 49152
端口数          : 16383
```

## 参考

[修改Hyper-V动态端口范围以解决Windows 10下Docker等应用端口占用问题](https://www.loserhub.cn/posts/details/8c5e0cd3e3e24a31beaebf91e908abb7)

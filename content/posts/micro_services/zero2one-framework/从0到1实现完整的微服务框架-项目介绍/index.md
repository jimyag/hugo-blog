---
title: 从0到1实现完整的微服务框架-项目介绍
tags:
  - 微服务
  - gRPC
categories:
  - - 微服务
  - - gRPC
slug: /5f073a52
date: 2022-03-25 20:26:35
series: [ "从0到1实现完整的微服务框架" ] 
---

本系列使用gRPC从0到1实现一个完整的微服务的商城项目。主要用到的技术栈有：gin、postgresql、paseto、sqlc、migrate、docker、consul、jaeger、protobuf、elasticsearch。

<!--more-->

项目中一共涉及到：

1. 用户服务
2. 商品服务
3. 库存服务
4. 订单和购物车服务
5. 收藏、收货地址、留言服务
6. elasticsearch实现搜索服务



项目中用到的基础知识的博客如下：

[从单体应用到微服务 | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/acba46c5/)

[为什么paseto比jwt好？ | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/d5376d72/)

[从SQL生成可直接调用的go接口-sqlc | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/900c3133/)

[数据库迁移工具-migrate | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/e7121931/)

[RPC基础介绍 | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/8d24f484/)

[Go中rpc包的使用 | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/11a90fe7/)

[Gin Web Framework (gin-gonic.com)](https://gin-gonic.com/zh-cn/)

[Docker基础入门 | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/8b63f587/)

[Casbin-入门demo | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/112bfef3/)

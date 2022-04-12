---
title: query和params传参的区别
tags:
  - Web
categories:
  - 基础
slug: /77535737
date: 2022-01-09 20:54:07
---

query和params传参的区别

<!--more-->

通过 url 传递参数控制页面显示数据的两种方式

### query 

传统问号传参url 格式：xxx.com/product?id=123模板内获取数据，？之后的信息

### params

动态路由匹配url 格式：xxx.com/product/123模板内获取数据，用冒号的形式标记参数可以继续拼接 /student/:id/:name/:age/:address他必须严格按照 url 的配置格式访问

---
title: golang-import自己的proto文件报红
tags:
  - 踩坑
categories:
  - 教程
slug: /155b4227
date: 2022-02-13 16:03:36
---

写proto时，在引入其它自己的定义的proto，之后会发现goland提示import路径不存在

<!--more-->

在实际生成代码中却没有关系，说明Goland配置有问题？

![image-20220213160751616](index/image-20220213160751616.png)

报红解决。

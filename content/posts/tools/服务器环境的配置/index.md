---
title: "服务器环境的配置"
date: 2022-04-11T17:06:27+08:00
draft: false
slug: /173a3c06
tags: ["教程"]
categories: ["教程"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [  ] 
pinned: false
weight: 100
---

新购买的服务器的环境配置

<!--more-->

## 修改主机名

```shell
[root@VM-0-16-centos ~]# hostnamectl set-hostname jimyag
[root@VM-0-16-centos ~]# vim /etc/hosts
127.0.0.1 jimyag
127.0.0.1 localhost.localdomain localhost
127.0.0.1 localhost4.localdomain4 localhost4

::1 jimyag jimyag
::1 localhost.localdomain localhost
::1 localhost6.localdomain6 localhost6
[root@VM-0-16-centos ~]# reboot
```

## 更新源

```shell
yum update
```

## 安装docker

```shell
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

```

```shell
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
```

```shell
yum install -y docker-ce
```

```shell
systemctl start docker.service
```

```shell
systemctl enable docker.service
```

```shell
curl -L https://get.daocloud.io/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
```

```shell
chmod +x /usr/local/bin/docker-compose
```

## go环境安装

[在Linux安装Go环境 | 步履不停 (jimyag.cn)](https://jimyag.cn/posts/c56e43df/)

## git配置.配置一个用于提交代码的用户，输入指令：

git config --global user.name "Your Name"
同时配置一个用户的邮箱，输入命令：

```shell
git config --global user.email "email@example.com"
```

生成公钥和私钥（用于github）

```shell
ssh-keygen -t rsa -C "youremail@example.com"
```

## 参考

[DaoCloud | Docker 极速下载](http://get.daocloud.io/#install-compose)

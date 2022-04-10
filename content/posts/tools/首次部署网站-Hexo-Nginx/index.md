---
title: 首次部署网站-Hexo-Nginx 
tags:
    - Web 
    - 教程 
categories:
    - Web 
slug: ../19323af8 
date: 2021-07-31 15:20:40
mathjax: true
---

去年在好友 [晚风吹行舟](https://wanfengcxz.cn/) 的帮助下购买了腾讯云的主机以及域名，但这些在很长时间内都是闲置状态。 暑期这段时间收到了腾讯云服务电话，域名备案需要更新，顺便将自己网站进行完善。

<!--more-->

## 环境准备

### Git安装及配置

#### 安装Git

1. 选择最新版本，或者其他版本进行下载，双击可执行文件并一路点击`Next`安装[Git下载](https://git-scm.com/download/win)
2. 在终端执行  

```shell
git --version
```

3. 查看git版本，如出现下面提示则`Git`安装成功

```shell
git version 2.28.0.windows.1  
```

#### 配置Git

1. 打开Git Bash（在任意地方右击，点击Git Bash Here）
2. 配置用户名。在终端中使用下面的命令可以设置git自己的名字和电子邮件。这是因为Git是分布式版本控制系统，所以，每个机器都必须自报家门：你的名字和Email地址。

```shell
git config --global user.name "name"  # (name:你的名字)
```

3. 配置邮箱

```shell
git config --global user.email "xxx@xxx.com" # 邮箱，
```

4. 生成ssh的Key  

```shell
 ssh-keygen -t rsa -C 'github邮箱号' -f ~/.ssh/id_rsa_github  
```
​	这时会在用户目录(C:Users\xxx\.ssh)下生成以下文件  

   -  id_rsa_github
   -  id_rsa_github.pub  


5. 登陆Github，在`Settings` > `SSH and GPG keys` 找到`New SSH key` 输入Title名，在Key中填入`id_rsa_github.pub`的内容，点击`Add SSH key`。

至此，Git已经配置完成

### Node.js安装

1. 选择最新版本，或者其他版本进行下载，双击可执行文件并一路点击`Next`进行安装。[Node.js下载](https://nodejs.org/zh-cn/)
2. 在终端输入以下命令，如出现版本号代表安装完成。

```shell
node -v
npm -v
```

3. npm换源(可选)

```shell
npm config set registry https://registry.npm.taobao.org
```

### [Hexo配置](https://hexo.io/zh-cn/docs/)

1. Hexo安装，执行以下命令，等待安装完成

```shell
npm install -g hexo-cli
```

2. 生成Hexo。 执行以下命令，生成一个博客，安装过程中，他会自动生成一个文件夹，这个文件夹就是Hexo的配置文件。 “blog”是你要生成博客的文件夹名称，可以根据自己的喜好来取名。

```shell
hexo init blog
```

3. 进入刚刚生成的配置文件夹，执行以下命令启动Hexo

```shell
cd blog
hexo server
```

4. 在浏览器中地址栏中输入"127.0.0.1:4000"即可看到Hexo的“Hello World”界面

## Hexo部署至腾讯云

### 部署环境准备

1. 环境

- 本地Windows10
- 腾讯云CentOS7.6

2. 准备

- 已准备好的Hexo本地博客
- 用于连接服务器的工具[MobaXterm](https://mobaxterm.mobatek.net/)

### 服务器配置Git

1. 安装Git

```shell
sudo yum install -y git
```

2. 创建Git用户并且修改权限

```shell
adduser username 
passwd username 
chmod 740 /etc/sudoers 
vim /etc/sudoers
```

​		修改内容如下

```text
root    ALL=(ALL)       ALL
username     ALL=(ALL)       ALL
```

3. 本地Win10创建密匙

```shell
ssh-keygen -t rsa
```

4. 在服务器中切换Git用户，并将Win10中"id_rsa.pub"文件复制到服务器中'~/.ssh/authorized_keys'

```shell
su username
mkdir ~/.ssh
vim ~/.ssh/authorized_keys
```

### 服务器网站配置

1. 创建网站目录并且设置权限

```shell
su root
mkdir /home/hexo
chown username:username -R /home/hexo
```

2. 安装Nginx，并启动服务

```shell
yum install -y nginx
systemctl start nginx.service    #启动服务
```

3. 修改Nginx配置文件

```shell
vim /etc/nginx/nginx.conf 
server {
  listen 80 default_server; 
  listen [::]:80 default_server;
  server_name jimyag.cn; #你的域名
  root /home/hexo; #网站目录
}
```

4. 重启Nginx

```shell
systemctl restart nginx.service
```

5. 建立Git仓库

```shell
su root
cd /home/username
git init --bare blog.git
chown username:username -R blog.git
```

6. 同步网站根目录

```shell
vim blog.git/hooks/post-receive

#!/bin/sh
git --work-tree=/home/hexo --git-dir=/home/username/blog.git checkout -f
```

7. 修改权限

```shell
chmod +x /home/username/blog.git/hooks/post-receive
```

8. 在Win10本地Hexo目录修改_config.yml文件

```text
deploy:
  type: git
  repository: username@ip:/home/username/blog.git    #用户名@服务器Ip:git仓库位置
  branch: master
```

9. 在Win10GitBash部署

```shell
hexo clean
hexo g -d
```

##   网站配置

1. 个性化配置参考教程 [B站](https://www.bilibili.com/video/BV16W411t7mq?p=1)
2. 参考博客

>[Hexo换主题乱码](https://www.cnblogs.com/lanhuakai/p/14588669.html)
>
>[CentOS修改主机名](https://blog.csdn.net/zifengzwz/article/details/108838842)
>
>[Deployer not found](https://blog.csdn.net/weixin_36401046/article/details/52940313)
>
>[nginx跳转到https](https://blog.csdn.net/hbysj/article/details/114071207)
>
>[主题博客个性化配置](https://blog.csdn.net/as480133937/article/details/100138838)
>
>[主题侧边栏日志](https://blog.csdn.net/qq_38765633/article/details/104929566)
>
>[增加备案号 ](https://yejiayong.com/为NexT主题的Hexo博客增加备案号/)
>
>[添加文章更新时间](https://blog.csdn.net/ganzhilin520/article/details/79053399)
>
>[npm换源](https://blog.csdn.net/happy_Du/article/details/114485704)
>
>[设置博客目录](https://blog.csdn.net/wugenqiang/article/details/88609066)


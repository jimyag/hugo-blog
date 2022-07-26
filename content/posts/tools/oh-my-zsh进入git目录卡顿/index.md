---
title: "Oh My Zsh进入git目录卡顿"
date: 2022-07-26T23:26:27+08:00
draft: false
slug: /0f0b28a1
tags: ["git","oh-my-zsh"]
categories: []
featured: false 
comment: false 
toc: true 
diagram: true 
series: [  ] 
pinned: false
weight: 100
---

描述

在 clone 下的 git 仓库中查看文件，发现很卡顿。一条`ls`的命令都需要 7,8 秒。

<!--more-->

这个是因为在进入目录的时候，oh-my-zsh 的 git prompt 每次都会在你的命令结束之后之心 git status 来检测当前的分支，当仓库很大的时候就会非常慢了。

这个我们直接关闭就好了。

设置 oh-my-zsh 不读取文件变化信息（在 git 项目目录执行下列命令）

```Bash
git config --add oh-my-zsh.hide-dirty 1
```

如果想恢复显示，可以将 1 改为 0，或者

```Bash
git config --remove-section oh-my-zsh
```

如果你还觉得慢，可以再设置 oh-my-zsh 不读取任何 git 信息

```Bash
git config --add oh-my-zsh.hide-status 1
```

如果你实在太卡，以至于仓库都进不去了，那么可以添加 --global ，在所有仓库都禁用这个功能

```Bash
git config --global --add oh-my-zsh.hide-dirty 1
git config --global --add oh-my-zsh.hide-status 1
```

查看配置信息

```Bash
# 当前仓库
git config --local -e
# 全局设置
git config --global -e
```

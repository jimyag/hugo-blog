---
title: "Git开发分支落后远程主分支"
date: 2022-08-02T11:36:30+08:00
draft: false
slug: /9c78a390
tags: ["Git"]
categories: []
featured: false 
comment: false 
toc: true 
diagram: true 
series: [] 
pinned: false
weight: 100
---

我们平时开发的时候都是从主仓库 fork 到自己仓库，然后将 fork 的仓库 clone 到本地进行开发，本地创建对应的开发分支A，开发完成以后再将A分支提交到 fork 的仓库，之后提交 pr 到主仓库。 但是一般而言，我们都是整个团队在开发，等开发完了，需要合并到远程分支的时候，远程分支已经有很多次提交（commit)了，自己的分支已经落后主分支很多版本，切换回主分支的时候就不在最新commit上了。

<!--more-->

## 解决思路

远程仓库主分支为 qbox/develop , fork 仓库主分支orgin/develop

假设当前开发的分支名为 KODO-11324 ,

1.  在 fork 仓库主分支拉取最新的代码
2.  根据主分支（develop）代码在本地创建新的临时分支，命名为tmp
3.  将临时分支（tmp）合并到开发分支 KODO-11324
4.  解决合并后的冲突
5.  提交开发分支（KODO-11324）并push到fork仓库
6.  开发分支（KODO-11324）提交 pr 到主仓库

## 实现

### 在 fork 仓库主分支拉取最新的代码

切换到本地主分支

```bash
git checkout orgin/develop
```

拉取最新代码

```bash
git pull qbox develop
```

### 根据主分支在本地创建新的临时分支

```bash
git checkout -b tmp
```

### 将临时分支合并到开发分支

切换到开发分支 KODO-11324

```bash
git checkout KODO-11324
```

临时分支合并到开发分支

```bash
git merge tmp
```

### 解决冲突

手动解决冲突

### 开发分支 push 到 fork 仓库

```bash
git push orgin HEAD 
枚举对象中: 186, 完成.
对象计数中: 100% (172/172), 完成.
使用 4 个线程进行压缩
压缩对象中: 100% (108/108), 完成.
写入对象中: 100% (134/134), 12.87 KiB | 1.07 MiB/s, 完成.
总共 134（差异 91），复用 0（差异 0），包复用 0
remote: Resolving deltas: 100% (91/91), completed with 25 local objects.
remote: 
remote: Create a pull request for 'KODO-11324' on GitHub by visiting:
remote:      <https://github.com/jimyag/project-name/pull/new/KODO-11324>
remote: 
To github.com:jimyag/kodo.git
 * [new branch]          HEAD -> KODO-11324
```

### 提交 pr

点击 https://github.com/jimyag/project-name/pull/new/KODO-11324 即可提交 pr

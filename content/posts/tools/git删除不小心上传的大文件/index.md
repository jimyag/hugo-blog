---
title: "Git删除不小心上传的大文件"
date: 2022-04-25T15:07:07+08:00
draft: false
slug: b983a6c5
tags: ["踩坑","Git"]
categories: ["踩坑"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [  ] 
pinned: false
weight: 100
---

在git中不小心上传了大文件，推送到GitHub时被拒绝。

<!--more-->

The size of file ‘xxx‘ has exceeded the upper limited size (100 MB) in commit

我们在git中上传文件时不小心上传了压缩之后的`public.zip`文件，文件大小有108MB，超过了GitHub单个文件记录，被拒绝了。

如何删除呢？

```shell
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch public.zip" --prune-empty --tag-name-filter cat -- --all
```

其中`public.zip`就是要删除的大文件名称

运行结果如下

```powershell
WARNING: git-filter-branch has a glut of gotchas generating mangled history
         rewrites.  Hit Ctrl-C before proceeding to abort, then use an
         alternative filtering tool such as 'git filter-repo'
         (https://github.com/newren/git-filter-repo/) instead.  See the
         filter-branch manual page for more details; to squelch this warning,
         set FILTER_BRANCH_SQUELCH_WARNING=1.
Proceeding with filter-branch...

Rewrite 7934e441f11564177dafeea762d2dddf0662ba6e (35/41) (24 seconds passed, remaining 4 predicted)    rm 'public.zip'
Rewrite 8f0fca234e1d7deeabb26c93b35e2bf13aeb1542 (35/41) (24 seconds passed, remaining 4 predicted)    rm 'public.zip'
Rewrite 7ed0cf806e6d4eb132addcc0c36b4660243df528 (37/41) (25 seconds passed, remaining 2 predicted)    rm 'public.zip'
Rewrite 539b54782f23819f728f487b792abb3e47e68409 (37/41) (25 seconds passed, remaining 2 predicted)    rm 'public.zip'
Rewrite b02dae8bb5c48dac8f528bd26aa97e83c955e09f (39/41) (27 seconds passed, remaining 1 predicted)    rm 'public.zip'
Rewrite b2dd2b219d797742da52fa18c227cb7e9fcb5a23 (39/41) (27 seconds passed, remaining 1 predicted)    rm 'public.zip'
Rewrite 04f754981ba819d3229b2aaef8b4d3be880a79d6 (41/41) (28 seconds passed, remaining 0 predicted)
Ref 'refs/heads/master' was rewritten
WARNING: Ref 'refs/remotes/origin/master' is unchanged
```

**注意**一定要时双引号，要不然会出现`fatal: bad revision 'rm'`的错误。

[(21条消息) git 操作问题清单 | 删除大文件，版本回退，pull合并...._qyhyzard的博客-CSDN博客](https://blog.csdn.net/CVSvsvsvsvs/article/details/90680894)

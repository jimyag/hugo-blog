---
title: LeetCode-472-连接词
tags:
  - 困难
categories:
  - LeetCode
slug: /a9eb621
date: 2021-12-28 09:29:23
series: [ "leetcode" ] 
---

### 题目

给你一个 不含重复 单词的字符串数组 words ，请你找出并返回 words 中的所有 连接词 。

连接词 定义为：一个完全由给定数组中的至少两个较短单词组成的字符串。


<!--more-->

### 示例


```tex
输入：words = ["cat","cats","catsdogcats","dog","dogcatsdog","hippopotamuses","rat","ratcatdogcat"]
输出：["catsdogcats","dogcatsdog","ratcatdogcat"]
解释："catsdogcats" 由 "cats", "dog" 和 "cats" 组成; 
     "dogcatsdog" 由 "dog", "cats" 和 "dog" 组成; 
     "ratcatdogcat" 由 "rat", "cat", "dog" 和 "cat" 组成。
```
```tex
输入：words = ["cat","dog","catdog"]
输出：["catdog"]
```

### 解答

### 代码


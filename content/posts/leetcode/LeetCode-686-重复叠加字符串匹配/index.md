---
title: LeetCode-686-重复叠加字符串匹配
tags:
  - 中等
  - 模拟
  - 字符串
categories:
  - LeetCode
slug: /cb644e85
date: 2021-12-22 09:21:49
series: [ "leetcode" ] 
---

### 题目

给定两个字符串 a 和 b，寻找重复叠加字符串 a 的最小次数，使得字符串 b 成为叠加后的字符串 a 的子串，如果不存在则返回 -1。

注意：字符串 "abc" 重复叠加 0 次是 ""，重复叠加 1 次是 "abc"，重复叠加 2 次是 "abcabc"。

<!--more-->

### 示例


```tex
输入：a = "abcd", b = "cdabcdab"
输出：3
解释：a 重复叠加三遍后为 "abcdabcdabcd", 此时 b 是其子串。
```
```tex
输入：a = "a", b = "aa"
输出：2
```
```tex
输入：a = "a", b = "a"
输出：1
```
```tex
输入：a = "abc", b = "wxyz"
输出：-1
```

### 解答

根据题意进行模拟，如果`a`的长度小于`b`的长度，`newA` = `newA+a`，直到`newA.size()>=b.size()`结束，在此期间记录加了几次`a`，然后判断`b`是否是`newA`的子串。如果不是子串还要判断`newA.size()`是否等于`b.size()`，就像示例1一样，虽然a叠加两边之后和b的size一样，`b`不是`a`的子串，但是再叠加一次，`b`就是`a`的子串了。

### 代码

```c++
int repeatedStringMatch(string a, string b) {
        string newA = a;
        int ans = 1;
        while (newA.size() < b.size()) {
            ans++;
            cout << "newA.size() = " << newA.size() << endl;
            newA = newA + a;
        }
        string::size_type sizeType = newA.find(b);
        if (sizeType == string::npos) {
            newA += a;
            sizeType = newA.find(b);
            if (sizeType == string::npos) {
                return -1;
            } else {
                return ans + 1;
            }
        }

        return ans;
    }
```


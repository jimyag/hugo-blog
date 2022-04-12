---
title: LeetCode-507-完美数
tags:
  - 简单
  - 数学
categories:
  - LeetCode
slug: /9c98d12
date: 2021-12-31 08:16:09
series: [ "leetcode" ] 
---

### 题目

对于一个 正整数，如果它和除了它自身以外的所有 正因子 之和相等，我们称它为 「完美数」。

给定一个 整数 n， 如果是完美数，返回 true，否则返回 false

<!--more-->

### 示例

```tex
输入：num = 28
输出：true
解释：28 = 1 + 2 + 4 + 7 + 14
1, 2, 4, 7, 和 14 是 28 的所有正因子。
```
```tex
输入：num = 6
输出：true
```
```tex
输入：num = 496
输出：true
```
```tex
输入：num = 8128
输出：true
```
```tex
输入：num = 2
输出：false
```

### 解答

枚举因子

### 代码

```c++
bool checkPerfectNumber(int num) {
    set<int> s;
    int ans = 0;
    for (int i = 1; i < num / 2; i++) {
        if (num % i == 0) {
            s.insert(i);
            s.insert(num / i);
        }
    }
    for (const auto &item: s) {
        cout << item << endl;
        ans += item;
    }
    ans = ans - num;
    return ans == num;
}
```

```c++
bool checkPerfectNumber(int num) {
       if (num == 1) return false;
        int ans = 1;
        for (int i = 2; i <= num / i; i++) {
            if (num % i == 0) ans += i + num / i;
        }
        return ans == num;
    }
```


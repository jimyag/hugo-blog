---
title: LeetCode-997-找到小镇的法官
tags:
  - 简单
categories:
  - LeetCode
slug: ../e18d9e0d
date: 2021-12-19 22:14:28
series: [ "leetcode" ] 
---

### 题目

在一个小镇里，按从 1 到 n 为 n 个人进行编号。传言称，这些人中有一个是小镇上的秘密法官。

如果小镇的法官真的存在，那么：

小镇的法官不相信任何人。
每个人（除了小镇法官外）都信任小镇的法官。
只有一个人同时满足条件 1 和条件 2 。
给定数组 trust，该数组由信任对 trust[i] = [a, b] 组成，表示编号为 a 的人信任编号为 b 的人。

如果小镇存在秘密法官并且可以确定他的身份，请返回该法官的编号。否则，返回 -1。

<!--more-->

### 示例

```tex
输入：n = 2, trust = [[1,2]]
输出：2
```

```tex
输入：n = 3, trust = [[1,3],[2,3]]
输出：3
```

```tex
输入：n = 3, trust = [[1,3],[2,3],[3,1]]
输出：-1
```

```tex
输入：n = 3, trust = [[1,2],[2,3]]
输出：-1
```

```tex
输入：n = 4, trust = [[1,3],[1,4],[2,3],[2,4],[4,3]]
输出：3
```

### 解答

和题目[LeetCode-851-喧闹和富有)](https://jimyag.cn/posts/3f29dc95/#more)是有些共同特征的，在这个题目中，`信任`是不能传递的，我们也不能使用DFS去找到他们都信任的人。只有法官一个人是不相信任何人的，而剩下的`n-1`个人都相信法官，用题目中给的信任关系，构建一个有向图，我们要找到是，出度为0，入度为n-1的节点。由于法官不会相信其他人，如果有人相信`i`那么`v[edge[1]]++`，`i`相信别人就`v[edge[1]]--`

### 代码

```c++
int findJudge(int n, vector<vector<int>>& trust) {
    vector<int> v(n + 1);
    for (auto& edge : trust) {
        v[edge[0]]--;
        v[edge[1]]++;
    }
    for (int i = 1; i <= n; ++i) {
        if (v[i]== n-1) {
            return i;
        }
    }
    return -1;
}
```

```c++
int findJudge(int n, vector<vector<int>>& trust) {
	vector<int> inDegrees(n + 1);
    vector<int> outDegrees(n + 1);
    for (auto& edge : trust) {
        int x = edge[0], y = edge[1];
        ++inDegrees[y];
        ++outDegrees[x];
    }
    for (int i = 1; i <= n; ++i) {
        if (inDegrees[i] == n - 1 && outDegrees[i] == 0) {
            return i;
        }
    }
    return -1;
}
```


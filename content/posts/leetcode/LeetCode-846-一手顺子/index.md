---
title: LeetCode-846-一手顺子
tags:
  - 中等
  - 优先队列
  - 模拟
categories:
  - LeetCode
slug: ../111b38ee
date: 2021-12-30 10:06:01
series: [ "leetcode" ] 
---

### 题目

Alice 手中有一把牌，她想要重新排列这些牌，分成若干组，使每一组的牌数都是 groupSize ，并且由 groupSize 张连续的牌组成。

给你一个整数数组 hand 其中 hand[i] 是写在第 i 张牌，和一个整数 groupSize 。如果她可能重新排列这些牌，返回 true ；否则，返回 false 。

<!--more-->

### 示例

```tex
输入：hand = [1,2,3,6,2,3,4,7,8], groupSize = 3
输出：true
解释：Alice 手中的牌可以被重新排列为 [1,2,3]，[2,3,4]，[6,7,8]。
```

```tex
输入：hand = [1,2,3,4,5], groupSize = 4
输出：false
解释：Alice 手中的牌无法被重新排列成几个大小为 4 的组。
```

### 解答

题目的意思是给出一组牌，判断能否组成n个连子。统计牌的个数之后，每次取最小的一个牌组成连子，如果最小的牌的张数没了，那么久继续挑选下一个小的牌，最小的牌存在。

### 代码

```C++
bool isNStraightHand(vector<int> &hand, int groupSize) {
    // 不能整除直接返回
    if (hand.size() % groupSize != 0) {
        return false;
    }
    // 统计每张牌的个数
    map<int, int> nums;
    // 最小的牌
    priority_queue<int, vector<int>, greater<>> p_q;
    for (int temp: hand) {
        p_q.push(temp);
        nums[temp]++;
    }
    for (int i = 0; i < (hand.size() / groupSize); i++) {
        int pre;
        // 找一组牌是否连续
        for (int j = 0; j < groupSize; j++) {
            // 找到第一个小的牌
            if (j == 0) {
                do {
                    pre = p_q.top();
                    p_q.pop();
                    // 如果这个牌已经被用完了，就把重新选一张牌当做最小的牌
                } while (nums.find(pre) == nums.end() || nums[pre] < 1);
                // 找到最小牌之后就把这个牌数减小
                nums[pre]--;
                continue;
            }
            int current = pre+1;
            if (nums.find(current) == nums.end() || nums[current] < 1) {
                return false;
            }
            nums[current]--;
            pre =current;
        }
    }
    return true;
}
```


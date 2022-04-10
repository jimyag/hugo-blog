---
title: LeetCode-475-供暖器
tags:
  - 中等
categories:
  - LeetCode
slug: ../e63dcfe3
date: 2021-12-20 09:31:58
series: [ "leetcode" ] 
---

### 题目

冬季已经来临。 你的任务是设计一个有固定加热半径的供暖器向所有房屋供暖。

在加热器的加热半径范围内的每个房屋都可以获得供暖。

现在，给出位于一条水平线上的房屋 houses 和供暖器 heaters 的位置，请你找出并返回可以覆盖所有房屋的最小加热半径。

说明：所有供暖器都遵循你的半径标准，加热的半径也一样。

<!--more-->

### 示例

``` tex
输入: houses = [1,2,3], heaters = [2]
输出: 1
解释: 仅在位置2上有一个供暖器。如果我们将加热半径设为1，那么所有房屋就都能得到供暖。
```
``` tex
输入: houses = [1,2,3,4], heaters = [1,4]
输出: 1
解释: 在位置1, 4上有两个供暖器。我们需要将加热半径设为1，这样所有房屋就都能得到供暖。
```

```tex
输入：houses = [1,5], heaters = [2]
输出：3
```

### 解答

1. 对于每个房屋，要么用前面的暖气，要么用后面的，二者取近的，得到距离；
2. 对于所有的房屋，选择最大的上述距离。

### 代码

```c++
int findRadius(vector<int> &houses, vector<int> &heaters) {
    sort(heaters.begin(), heaters.end());
    sort(houses.begin(), houses.end());
    int ans = 0;
    for (int house: houses) {
        // 找到比该房间右边的第一个暖气的索引
        int currentRightHeater = upper_bound(heaters.begin(), heaters.end(), house) - heaters.begin();
        int currentLeftHeater = currentRightHeater - 1;
        int rightDistance = currentRightHeater >= heaters.size() ? INT_MAX : heaters[currentRightHeater] - house;
        int leftDistance = currentLeftHeater < 0 ? INT_MAX : house - heaters[currentLeftHeater];
        // 他要用最近的一个这样才能保证最小，
        int curDistance = min(leftDistance, rightDistance);
        // 在所有的房屋都要满足要求，则要取最大的一个
        ans = max(ans, curDistance);
    }
    return ans;
}
```

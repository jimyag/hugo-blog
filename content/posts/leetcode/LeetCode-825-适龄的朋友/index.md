---
title: LeetCode-825-适龄的朋友
tags:
  - 中等
categories:
  - LeetCode
slug: /69e04ce
date: 2021-12-27 09:42:27
series: [ "leetcode" ] 
---

### 题目

在社交媒体网站上有 n 个用户。给你一个整数数组 ages ，其中 ages[i] 是第 i 个用户的年龄。

如果下述任意一个条件为真，那么用户 x 将不会向用户 y`（x != y）`发送好友请求：

- `age[y] <= 0.5 * age[x] + 7`
- `age[y] > age[x]`
- `age[y] > 100 && age[x] < 100`

否则，x 将会向 y 发送一条好友请求。

注意，如果 x 向 y 发送一条好友请求，y 不必也向 x 发送一条好友请求。另外，用户不会向自己发送好友请求。

返回在该社交媒体网站上产生的好友请求总数。

<!--more-->

### 示例

```tex
输入：ages = [16,16]
输出：2
解释：2 人互发好友请求。
```
```tex
输入：ages = [16,17,18]
输出：2
解释：产生的好友请求为 17 -> 16 ，18 -> 17 。
```
```tex
输入：ages = [20,30,100,110,120]
输出：3
解释：产生的好友请求为 110 -> 100 ，120 -> 110 ，120 -> 100 。
```

### 解答

要想x给y发送一条好友请求，那么就要满足：

1. `age[y]>  0.5 * age[x] + 7`
2. `age[y] <= age[x]`
3. `age[y] <= 100 || age[x] >= 100`

在条件`2和3`中，条件2包含了条件3。x给y发送一条好友请求、可以化简为。

` 0.5 * age[x] + 7 <age[y]<=age[x] `

在这种条件下x可以给y发消息，那么对于每一个y只要找到给他发消息的x就行。

### 代码

```c++
int numFriendRequests(vector<int> &ages) {
    sort(ages.begin(), ages.end());
    int ans = 0;
    int left_x = 0;
    int right_x = 0;
    
    for (int y_index = 0; y_index < ages.size(); y_index++) {
        // 对于每一个y找到比他年龄小的的满足范围的人
        // 从0开始找到最后一个不满的要求的人
        while (left_x < y_index && !isSend(ages[left_x], ages[y_index])) left_x++;
        // 右边的比y要大
        if (right_x < y_index) right_x = y_index;
        // 找到满足要求的最后一个人
        while (right_x < ages.size() && isSend(ages[right_x], ages[y_index])) right_x++;
        // 减去自己
        if (right_x > left_x) {
            ans += right_x - left_x - 1;
        }
    }
    return ans;

}

bool isSend(int x_age, int y_age) {
    if (0.5 * x_age + 7 >= y_age)return false;
    if (x_age < y_age) return false;
    if (x_age < 100 && y_age > 100) return false;
    return true;
}
```


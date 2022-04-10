---
title: LeetCode-1995-统计特殊四元组
tags:
  - 简单
  - 暴力
  - 动态规划
categories:
  - LeetCode
slug: ../ace15a6d
date: 2021-12-29 10:51:23
series: [ "leetcode" ] 
---

### 题目

给你一个 下标从 0 开始 的整数数组 nums ，返回满足下述条件的 不同 四元组 (a, b, c, d) 的 数目 ：

nums[a] + nums[b] + nums[c] == nums[d] ，且
a < b < c < d

<!--more-->

### 示例
```tex
输入：nums = [1,2,3,6]
输出：1
解释：满足要求的唯一一个四元组是 (0, 1, 2, 3) 因为 1 + 2 + 3 == 6 。
```
```tex
输入：nums = [3,3,6,4,5]
输出：0
解释：[3,3,6,4,5] 中不存在满足要求的四元组。
```
```tex
输入：nums = [1,1,1,3,5]
输出：4
解释：满足要求的 4 个四元组如下：
- (0, 1, 2, 3): 1 + 1 + 1 == 3
- (0, 1, 3, 4): 1 + 1 + 3 == 5
- (0, 2, 3, 4): 1 + 1 + 3 == 5
- (1, 2, 3, 4): 1 + 1 + 3 == 5
```

### 解答

#### 思路1

暴力枚举，结果通过了？？

#### 思路2

来自三叶姐姐的解题思路,利用等式关系 nums[a] + nums[b] + nums[c] = nums[d]nums[a]+nums[b]+nums[c]=nums[d]，具有明确的「数值」和「个数」关系，可将问题抽象为组合优化问题求方案数。

限制组合个数的维度有两个，均为「恰好」限制，转换为「二维费用背包问题求方案数」问题。

定义 `f[i][j][k]`为考虑前 i 个物品（下标从 1 开始），凑成数值恰好 j，使用个数恰好为 k 的方案数。

最终答案为 $$\sum_{i = 3}^{n - 1}(f[i][nums[i]][3])$$起始状态 `f[0][0][0]=1` 代表不考虑任何物品时，所用个数为 0，凑成数值为 0 的方案数为 1。

不失一般性考虑 $$f[i][j][k]$$ 该如何转移，根据 $$nums[i - 1]$$ 是否参与组合进行分情况讨论：

nums[i - 1] 不参与组成，此时有：$$f[i - 1][j][k]$$
nums[i - 1] 参与组成，此时有：$$f[i - 1][j - t][k - 1]$$
最终 $$f[i][j][k]$$为上述两种情况之和，最终统计 $$\sum_{i = 3}^{n - 1}(f[i][nums[i]][3])$$即是答案。

### 代码

```C++
int countQuadruplets(vector<int> &nums) {
    int ans = 0;
    for (int i = 0; i < nums.size() - 3; i++) {
        for (int j = i + 1; j < nums.size() - 2; j++) {
            for (int k = j + 1; k < nums.size() - 1; k++) {
                for (int m = k + 1; m < nums.size(); m++) {
                    if (nums[i] + nums[j] + nums[k] == nums[m]) {
                        ans += 1;
                    }
                }
            }
        }
    }
    return ans;
}
```

```c++
int dp[55][105][4] = {0};// dp[i][j][k] 表示 前 i 个元素 中选择 k 个元素 构成大小 j 的方案数
    int countQuadruplets(vector<int>& nums) {
        int n = nums.size();
        int res = 0;
        dp[0][0][0] = 1;
        for(int i = 1;i <= n;i ++) {
            int v = nums[i - 1];
            dp[i][0][0] = 1;
            for(int j = 1;j < 105;j ++) {
                for(int k = 1;k < 4;k ++) {
                    dp[i][j][k] += dp[i - 1][j][k];
                    if(j - v >= 0 && k - 1 >= 0) dp[i][j][k] += dp[i - 1][j - v][k - 1];
                }
            }
        }
        for(int i = 3;i < n;i ++) {
            res += dp[i][nums[i]][3];
        }
        return res;
    }
```


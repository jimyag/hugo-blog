---
title: "Newcoder Top 101 二分查找排序"
date: 2022-04-30T16:36:19+08:00
draft: false
slug: 85d3feae
tags: ["算法","牛客TOP101"]
categories: ["算法"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ "牛客TOP101"] 
pinned: false
weight: 100
---

牛客算法必刷TOP101，包含：链表、二分查找/排序、二叉树、堆/栈/队列、哈希、递归/回溯、动态规划、字符串、双指针、贪心算法、模拟总共101道题。

此部分是**二分查找/排序专题**。

[牛客网 (nowcoder.com)](https://www.nowcoder.com/exam/oj?page=1&tab=算法篇&topicId=295)

<!--more-->

### 二分查找-I

#### 描述

请实现无重复数字的升序数组的二分查找

给定一个 元素升序的、无重复数字的整型数组 `nums `和一个目标值 `target `，写一个函数搜索 `nums `中的 `target`，如果目标值存在返回下标（下标从 0 开始），否则返回 -1

数据范围：$0 \le len(nums) \le 2\times10^5$ ， 数组中任意值满足 $|val| \le 10^9$

进阶：时间复杂度 O(\log n)*O*(log*n*) ，空间复杂度 O(1)*O*(1)

#### 示例1

输入：

```
[-1,0,3,4,6,10,13,14],13
```

返回值：

```
6
```

说明：

```
13 出现在nums中并且下标为 6     
```

#### 示例2

输入：

```
[],3
```

返回值：

```
-1
```

说明：

```
nums为空，返回-1     
```

#### 示例3

输入：

```
[-1,0,3,4,6,10,13,14],2
```

返回值：

```
-1
```

说明：

```
2 不存在nums中因此返回 -1     
```

#### 解析

##### 解析1-二分查找

对于有序的列表要找某个元素，二分查找是最快的一个。如果是升序的，从中间开始，当前的元素（中间）的值>目标值，就说明当前的值大了，需要在小的一部分找。修改右边的指针为mid-1,如果当前的元素<目标值，那么就要修改左边指针为mid+1，如果相等，则返回当前下标。

```c++
 int search(vector<int>& nums, int target) {
        int left = 0;
        int right = nums.size()-1;
        while(left<=right){
            int mid = (left+right)>>1;
            if(nums[mid]==target){
                return mid;
            }else if(nums[mid]>target){
                right = mid-1;
            }else{
                left = mid+1;
            }
        }
        return -1;
    }
```





### 总结

#### 刷题时间

| 时间 | 题目       |
| ---- | ---------- |
| 4-29 | 二分查找-I |


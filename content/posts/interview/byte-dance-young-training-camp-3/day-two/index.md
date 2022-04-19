---
title: "【第三届字节跳动青训营｜刷题打卡】DAY2"
date: 2022-04-19T19:18:38+08:00
draft: false
slug: 537fd5d3
tags: ["面试","Go"]
categories: ["面试"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ "第三届字节跳动青训营" ] 
pinned: false
weight: 100
---

【第三届字节跳动青训营｜刷题打卡】DAY2

<!--more-->

### 【多选】下列关于Join 运算不正确的是：

a. Nested Loop Join 不能使用索引做优化。
 b. 如果左表太大，不能放入内存中，则不能使用 Hash Join。
 c. 如果 Join 的一个输入表在 Join Key 上有序，则一定会使用 Sort Merge Join。
 d. Broadcast Join 适用于一张表很小，另一张表很大的场景。

#### 自己解析

A:可以做 [Nested Loop Join - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/81398139)

B: 可以使用，[数据库多表连接方式介绍－HASH-JOIN - _雨 - 博客园 (cnblogs.com)](https://www.cnblogs.com/shangyu/p/6055181.html)

C：不是的[(21条消息) Merge join、Hash join、Nested loop join对比分析_KPLives的博客-CSDN博客](https://blog.csdn.net/horace20/article/details/16360109)

D: 正确的



### 给定一个正整数数组 arrs 和整数 K ，请找出该数组内乘积小于等于 k 的连续的子数组的个数，算法时间复杂度o(n)

#### 解析

对于连续的子数组的问题想到了双指针的方法。第一版的代码如下。但是这个代码其实还是暴力搜索，每遇到一个`arr[i]`就从i开始枚举，满足要求的加入到`res`中，不满足就下一个。相当于时间复杂度为On^2

```c++
int subArr(vector<int> &arr, int target) {
    int slow = 0, fast = 0;
    int res = 0;
    for (; slow < arr.size(); slow++) {
        int temp = 1;
        for (fast = slow; fast < arr.size(); fast++) {
            temp *= arr[fast];
            if (temp <= target) {
                res++;
            } else {
                break;
            }
        }
    }
    return res;
}
```

我们知道，每次都是乘以`正整数`，每次相乘只会越来越大。我们要想办法用到`越乘越大`这个特性。

定义一个慢指针`slow`，所求的个数`res`，当前的乘积`mul`。

快指针`fast`快速向前计算连续数组的乘积，如果计算的乘积`大于`目标值`target`了，就移动`slow`指针，直到`mul`小于`target`。

剩下一个最棘手的问题`如何求res`

首先我们看下代码

```c++
int subArr(vector<int> &arr, int target) {
    int slow = 0;
    int res = 0;
    int mul = 1;
    for (int fast = 0; fast < arr.size(); fast++) {
        // 计算当前的乘积
        mul *= arr[fast];
        // 如果乘积超过了慢指针就要开始移动。
        while (mul > target) {
            // mul = mul/arr[slow];
            // slow ++; 的简写
            mul /= arr[slow++];
        }
        // 快指针每向有移动一次增加的符合条件的个数。
        res += (fast - slow + 1);

    }
    return res;
}
```

1. 我们要维护一个滑窗。窗口不断向右滑动，窗口右边界(fast)为固定轴，左边界(slow)则是一个变动轴。

2. 此窗口代表的意义为：以窗口右边界为结束点的区间，其满足乘积小于target所能维持的最大窗口。
   **因此，本题最重要的是求窗口在每个位置时，窗口的最大长度。(最大长度是重点)**

3. 最终的答案便是窗口在每个位置的最大长度的累计和。
   为什么呢？这个就需要我们找规律了。因为针对上一位置的窗口，移动一次后相对增加出来的个数便是`(fast - slow + 1)`。

> 举个例子:
>
> 窗口左边界：l,窗口右边界：r
>
> k=100
>
> 位置i：    		0, 1, 2, 3
>
> 数组nums： 10, 5, 2, 6
>
> 窗口1(l=1,r=2)：   l, r   
>
> 窗口2(l=1,r=3):    l,    r
>
> 窗口1中符合的有[5],[2],[5,2]
>
> 窗口2中符合的有[5],[2],[5,2],[6],[2,6],[5,2,6]


​	可以看出，`窗口2`对比`窗口1`多出来的数组都是由于窗口`右滑一次`所带来的，即**多出来的那几个必然是包含新窗口的边界fast**

​	因此可以得出，最终答案可以是每次窗口最大长度的累加。

4. 为了求出每次窗口的最大长度(或理解为宽度也许)，我们可能需要对变动轴左边界(l)进行调整。
   即调整左边界，使之能达到求出窗口的最大长度








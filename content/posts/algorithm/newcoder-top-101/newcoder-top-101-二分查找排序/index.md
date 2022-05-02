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

# 二分查找-I

## 描述

请实现无重复数字的升序数组的二分查找

给定一个 元素升序的、无重复数字的整型数组 `nums `和一个目标值 `target `，写一个函数搜索 `nums `中的 `target`，如果目标值存在返回下标（下标从 0 开始），否则返回 -1

数据范围：$0 \le len(nums) \le 2\times10^5$ ， 数组中任意值满足 $|val| \le 10^9$

进阶：时间复杂度 O(\log n)*O*(log*n*) ，空间复杂度 O(1)*O*(1)

## 示例1

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

## 示例2

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

## 示例3

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

## 解析

### 解析1-二分查找

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

# 二维数组中的查找

## 描述

在一个二维数组array中（每个一维数组的长度相同），每一行都按照从左到右递增的顺序排序，每一列都按照从上到下递增的顺序排序。请完成一个函数，输入这样的一个二维数组和一个整数，判断数组中是否含有该整数。

> [
>
> [1,2,8,9],
> [2,4,9,12],
> [4,7,10,13],
> [6,8,11,15]
>
> ]

给定 target = 7，返回 true。

给定 target = 3，返回 false。

数据范围：矩阵的长宽满足$ 0 \le n,m \le 500$ ， 矩阵中的值满足 $0 \le val \le 10^9$
进阶：空间复杂度 O(1) ，时间复杂度 O(n+m)

## 示例1

输入：

```
7,[[1,2,8,9],[2,4,9,12],[4,7,10,13],[6,8,11,15]]
```

返回值：

```
true
```

说明：

```
存在7，返回true   
```

## 示例2

输入：

```
1,[[2]]
```

返回值：

```
false
```

复制

## 示例3

输入：

```
3,[[1,2,8,9],[2,4,9,12],[4,7,10,13],[6,8,11,15]]
```

复制

返回值：

```
false
```

说明：

```
不存在3，返回false   
```

## 解析

### 解析1-从[0][0]开始二分查找

从\[0][0]开始找目标值要处理这种情况，当前的值比目标值大，改后退还是如何前进。这样思考的情况太多，所以删除，

### 解析2-从数组左下角开始查找。

从左下角开始找起可以避免当前的值比目标值大了之后处理麻烦的情况。当前的值比目标值小，列索引++，如果当前值比目标大，行--。

如果越界了都没找到，就是没有。

```c++
bool Find(int target, vector<vector<int> > array) {
        int hang = array.size()-1;
        int lies = array[0].size();
        int lie = 0;
        while(lie<lies&&hang>-1){
            if(array[hang][lie]==target){
                return true;
            }else if(array[hang][lie]>target){
                hang--;
            }else{
                lie++;
            }
        }
        return false;
    }
```

# 寻找峰值

## 描述

给定一个长度为n的数组nums，请你找到峰值并返回其索引。数组可能包含多个峰值，在这种情况下，返回任何一个所在位置即可。

1.峰值元素是指其值严格大于左右相邻值的元素。严格大于即不能有等于

2.假设 nums[-1] = nums[n] = $-\infty$

3.对于所有有效的 `i` 都有 `nums[i] != nums[i + 1]`

4.你可以使用`O(logN)`的时间复杂度实现此问题吗？

数据范围：

$1 \le nums.length \le 2\times 10^5$

$-2^{31}<= nums[i] <= 2^{31} - 1$

如输入[2,4,1,2,7,8,4]时，会形成两个山峰，一个是索引为1，峰值为4的山峰，另一个是索引为5，峰值为8的山峰，如下图所示：

![img](index/9EB9CD58B9EA5E04C890326B5C1F471F.png)

## 示例1

输入：

```
[2,4,1,2,7,8,4]
```

返回值：

```
1
```

说明：

```
4和8都是峰值元素，返回4的索引1或者8的索引5都可以     
```

## 示例2

输入：

```
[1,2,3,1]
```

返回值：

```
2
```

说明：

```
3 是峰值元素，返回其索引 2 
```

## 解析

### 解析1-寻找最大值

由于是要找峰值，那么也就是极大值，只要找到最大值那么他一定是极大值。

```c++
int findPeakElement(vector<int>& nums) {
        int index = 0;
         for(int i = 1;i<nums.size();i++){
             if(nums[i]>nums[index]){
                 index = i;
             }
             
         }
         return index;
    }
```

### 解析2-二分查找

由于题目给出的条件，两边(inde = -1,index = nums.size())都是最小值。只有当前序列是递增的时候才会出现山峰，如果当前序列是递减的，那么他可能就不会有山峰。

```c++
    int findPeakElement(vector<int>& nums) {
        int left = 0;
        int right = nums.size()-1;
            while(left<right){
                int mid = (left+right)>>1;
                if(nums[mid]>nums[mid+1]){
                    right = mid;
                }else{
                    left = mid+1;
                }
            }
        return right;
    }
```

# 旋转数组的最小数字

## 描述

有一个长度为 n 的非降序数组，比如[1,2,3,4,5]，将它进行旋转，即把一个数组最开始的若干个元素搬到数组的末尾，变成一个旋转数组，比如变成了[3,4,5,1,2]，或者[4,5,1,2,3]这样的。请问，给定这样一个旋转数组，求数组中的最小值。

数据范围：$1 \le n \le 10000$，数组中任意元素的值: $0 \le val \le 10000$

要求：空间复杂度：O(1) ，时间复杂度：O(logn)

## 示例1

输入：

```
[3,4,5,1,2]
```

返回值：

```
1
```

## 示例2

输入：

```
[3,100,200,3]
```

返回值：

```
3
```

## 解析

### 解析1-遍历

遍历一遍找到最小值就行。

### 解析2-二分

查看比较中间的值和right的值

1. mid的值大于right值，就说明截断的值在右边，下一次从mid+1到right搜索就好了
2. mid的值小于right的值，截断的值在左边，就从left到right搜索
3. 当这两个值相等时候，不能判断在哪里，所以就要减少right进行搜索

```c++
int minNumberInRotateArray(vector<int> rotateArray) {
        if(rotateArray.size()==0){
            return 0;
        }
        int left = 0;
        int right = rotateArray.size()-1;
        while(left<right){
            int mid = (left+right)>>1;
            if(rotateArray[mid]>rotateArray[right]){
                left = mid+1;
            }else if(rotateArray[mid]<rotateArray[right]){
                right = mid;
            }else{
                right--;
            }
        }
        return rotateArray[left];
    }
```



# 总结

## 刷题时间

| 时间 | 题目               |
| ---- | ------------------ |
| 4-29 | 二分查找-I         |
| 4-29 | 二维数组中的查找   |
| 4-30 | 寻找峰值           |
| 5-2  | 旋转数组的最小数字 |

## 技巧总结

1. 二分查找一定要清楚`left`和`right`的关系，他们两个能不能相等，相等代表的是
2. 二维数组中的查找，虽然是知道二分查找，但是要记住从那开始

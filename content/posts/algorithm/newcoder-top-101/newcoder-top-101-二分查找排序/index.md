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

# 数组中的逆序对

## 描述

在数组中的两个数字，如果前面一个数字大于后面的数字，则这两个数字组成一个逆序对。输入一个数组,求出这个数组中的逆序对的总数P。并将P对1000000007取模的结果输出。 即输出P mod 1000000007


数据范围： 对于 50% 的数据, $size\leq 10^4$
对于 100% 的数据, $size\leq 10^5$

数组中所有数字的值满足 $0 \le val \le 1000000$

要求：空间复杂度 O(n)，时间复杂度 O(nlogn)

### 输入描述：

题目保证输入的数组中没有的相同的数字

## 示例1

输入：

```
[1,2,3,4,5,6,7,0]
```

返回值：

```
7
```

## 示例2

输入：

```
[1,2,3]
```

返回值：

```
0
```

## 解析

### 解析1-暴力求解

按照定义进行模拟就可以。时间复杂度O(n^2)

### 解析2-归并排序

我们举个例子,对于序列`1,2,3,4,5`的逆序对数是0，但是对于`5,4,3,2,1`的逆序对数是`4+3+2+1`个，只要是部分有序的，我们就可以O(1)的时间复杂度求得逆序数。对于我们使用的归并排序，所有排序的数组是部分有序的，比如要归并`2,4,6,8`和`1,3,5,7`,1小，归并1，但是左边的序列都比`1`大，都可以组成逆序数，逆序数数量`+4`，

| 左边    | 右边    | 归并数  | 逆序数                                                    |
| ------- | ------- | ------- | --------------------------------------------------------- |
| 2,4,6,8 | 1,3,5,7 | -       | 0                                                         |
| 2,4,6,8 | 3,5,7   | 1       | 0+4，（1比左边的2小，就是和左边的所有数都可以组成逆序数） |
| 4,6,8   | 3,5,7   | 1，2    | 0+4+0(3比左边的2大，也就是和左边的组成不了逆序数)         |
| 4,6,8   | 5,7     | 1，2，3 | 0+4+0+3，(3比4小，和左边的所有数都可以组成逆序数)         |
| ....    | ...     | ...     | ...                                                       |

这样就可以求得所有的逆序数对数了。

```c++
const int kmod = 1000000007;
    int InversePairs(vector<int> data) {
        int ret = 0;
        vector<int> tmp(data.size());
        mergeSort(data, tmp, 0, data.size() - 1, ret);
        return ret;
    }
    void mergeSort(vector<int>&array,vector<int>&temp,int left,int right,int &ret){
        if(left==right){
            return ;
        }
        int mid = left+((right-left)>>1);
        mergeSort(array,temp,left, mid,ret);
        mergeSort(array,temp,mid+1, right,ret);
        merge(array,temp,left,mid,right,ret);
    }
    void merge(vector<int>&array,vector<int>&temp,int left,int mid,int right,int &ret){
        int k = 0;
        int l = left,r = mid+1;
        while(l<=mid&&r<=right){
            // 左边的比右边的大，
            if(array[l]>array[r]){
                temp[k++] = array[r++];
                // 计算逆序对数了
                ret+=(mid-l+1);
                ret%=kmod;
            }else{
                temp[k++] = array[l++];
            }
        }
        while(l<=mid){
            temp[k++] = array[l++];
        }
        while(r<=right){
            temp[k++] = array[r++];
        }
        for(k = 0,l=left;l<=right;l++,k++){
            array[l] = temp[k];
        }
    }
```

# 比较版本号

## 描述

牛客项目发布项目版本时会有版本号，比如1.02.11，2.14.4等等

现在给你2个版本号version1和version2，请你比较他们的大小

版本号是由修订号组成，修订号与修订号之间由一个"."连接。1个修订号可能有多位数字组成，修订号可能包含前导0，且是合法的。例如，1.02.11，0.1，0.2都是合法的版本号

每个版本号至少包含1个修订号。

修订号从左到右编号，下标从0开始，最左边的修订号下标为0，下一个修订号下标为1，以此类推。

比较规则：

一. 比较版本号时，请按从左到右的顺序依次比较它们的修订号。比较修订号时，只需比较忽略任何前导零后的整数值。比如"0.1"和"0.01"的版本号是相等的

二. 如果版本号没有指定某个下标处的修订号，则该修订号视为0。例如，"1.1"的版本号小于"1.1.1"。因为"1.1"的版本号相当于"1.1.0"，第3位修订号的下标为0，小于1

三. version1 > version2 返回1，如果 version1 < version2 返回-1，不然返回0.

数据范围：

1 <= version1.length, version2.length <= 1000

version1 和 version2 的修订号不会超过int的表达范围，即不超过 **32 位整数** 的范围
进阶：  时间复杂度 O(n)

## 示例1

输入：

```
"1.1","2.1"
```

返回值：

```
-1
```

说明：

```
version1 中下标为 0 的修订号是 "1"，version2 中下标为 0 的修订号是 "2" 。1 < 2，所以 version1 < version2，返回-1
           
```

## 示例2

输入：

```
"1.1","1.01"
```

返回值：

```
0
```

说明：

```
version2忽略前导0，为"1.1"，和version相同，返回0           
```

## 示例3

输入：

```
"1.1","1.1.1"
```

返回值：

```
-1
```

说明：

```
"1.1"的版本号小于"1.1.1"。因为"1.1"的版本号相当于"1.1.0"，第3位修订号的下标为0，小于1，所以version1 < version2，返回-1           
```

## 示例4

输入：

```
"2.0.1","2"
```

返回值：

```
1
```

说明：

```
version1的下标2>version2的下标2，返回1           
```

## 示例5

输入：

```
"0.226","0.36"
```

返回值：

```
1
```

说明：

```
226>36，version1的下标2>version2的下标2，返回1   
```

## 解析

### 解析1-模拟

由于版本号是以`.`分割的，可以将分割的结果进行对比，判断那个大。对于有`前导0`的数字的比较，可以将字符串转换为数字进行比较

```c++
int compare(string version1, string version2){
    int len1 = version1.size();
    int len2 = version2.size();
    int l1 = 0,l2 = 0;
    while(l1<len1||l2<len2){
        long long num1 = 0;
        // 用. 分割
        while(l1<len1&&version1[l1]!='.'){
            num1 = num1*10 +(version1[l1]-'0');
            l1++;
        }
        // 跳过.
        l1++;
        
        long long num2 = 0;
        while(l2<len2&&version2[l2]!='.'){
            num2 = num2*10 +(version2[l2]-'0');
            l2++;
        }
        l2++;
        
        if(num1>num2){
            return 1;
        }
        if(num1<num2){
            return -1;
        }
    }
    return 0;
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
| 5-3  | 数组中的逆序对     |

## 技巧总结

1. 二分查找一定要清楚`left`和`right`的关系，他们两个能不能相等，相等代表的是
2. 二维数组中的查找，虽然是知道二分查找，但是要记住从那开始
2. 数组中的逆序对要多刷。理解这个思想。

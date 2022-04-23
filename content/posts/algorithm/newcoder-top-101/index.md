---
title: "Newcoder Top 101"
date: 2022-04-22T22:48:43+08:00
draft: true
slug: 70f03d51
tags: ["算法","牛客TOP101"]
categories: ["算法"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ ] 
pinned: false
weight: 100
---

牛客算法必刷TOP101，包含：链表、二分查找/排序、二叉树、堆/栈/队列、哈希、递归/回溯、动态规划、字符串、双指针、贪心算法、模拟总共101道题。

[牛客网 (nowcoder.com)](https://www.nowcoder.com/exam/oj?page=1&tab=算法篇&topicId=295)

<!--more-->

## 链表

### 反转链表

#### 描述

给定一个单链表的头结点**pHead**(该头节点是有值的，比如在下图，它的val是1)，长度为n，反转该链表后，返回新链表的表头。

数据范围： 0≤*n*≤1000

要求：空间复杂度 O*(1) ，时间复杂度 O*(*n) 。

如当输入链表{1,2,3}时，

经反转后，原链表变为{3,2,1}，所以对应的输出为{3,2,1}。

以上转换过程如下图所示：

![img](index/4A47A0DB6E60853DEDFCFDF08A5CA249.png)

#### 示例1

输入：

```tex
{1,2,3}
```

返回值：

```tex
{3,2,1}	
```

#### 示例2

输入：

```tex
{}
```

返回值：

```
{}
```

说明：

```tex
空链表则输出空                  
```

#### 解法

##### 原地置换

分别用三个指针`pre`,`cur`,`next`代表之前的结点，当前的结点，下一个结点。改变链表的指向关系就可以原地改变顺序。

以下是模拟的过程

![image-20220423232617157](index/image-20220423232617157.png)

![image-20220423233014470](index/image-20220423233014470.png)

![image-20220423233045147](index/image-20220423233045147.png)

![image-20220423233056631](index/image-20220423233056631.png)

代码如下：

```c++
class Solution {
public:
    ListNode* ReverseList(ListNode* pHead) {
        ListNode*pre = nullptr;
        ListNode*cur = pHead;
        while(cur){
            ListNode*next = cur->next; // 第四步
            cur->next = pre; //第一步
            pre = cur; //第二步
            cur = next; // 第三步
        }
        return pre;
    }
};
```


---
title: "Newcoder Top 101"
date: 2022-04-22T22:48:43+08:00
draft: false
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

### 链表内指定区间反转

#### 描述

将一个节点数为 size 链表 m 位置到 n 位置之间的区间反转，要求时间复杂度 O(n)*O*(*n*)，空间复杂度 O(1)*O*(1)。
例如：
给出的链表为 1→2→3→4→5→NULL, m*=2,*n=4,
返回 1→4→3→2→5→NULL

要求：时间复杂度 O(n)*O*(*n*) ，空间复杂度 O(n)*O*(*n*)

进阶：时间复杂度 O(n)*O*(*n*)，空间复杂度 O(1)*O*(1)

#### 示例1

输入：

```
{1,2,3,4,5},2,4
```

返回值：

```
{1,4,3,2,5}
```

#### 示例2

输入：

```
{5},1,1
```

返回值：

```
{5}
```

#### 解析

##### 解法一

对于这道题，我们可以参考反转链表的题，只需要直到指定的区间的链表，然后断开，将这个区间的链表进行反转。

注意，由于在此过程中需要保存区间左边和右边的链表，所以需要加上一个新的头结点来处理边界问题。

```c++
// 反转当前链表
ListNode *reverse(ListNode *head) {
    ListNode *pre = nullptr;
    ListNode *cur = head;
    ListNode *next = nullptr;
    while (cur) {
        next = cur->next;
        cur->
                next = pre;
        pre = cur;
        cur = next;
    }
    return pre;
}


ListNode *reverseBetween(ListNode *head, int m, int n) {
    if (head->next == nullptr || head == nullptr || m == n) {
        return
                head;
    }
    // 防止出现pre的问题
    auto *newHead = new ListNode(0);
    newHead->next = head;
    ListNode *pre = newHead;
    // 从哪里开始的
    ListNode *begin = head;
    // 结束的最后一个结点
    ListNode *end = nullptr;
    // 结束断开的下一个
    ListNode *endEnd = nullptr;
    // 找到从哪里开始断开
    for (int i = 0; i < m - 1; i++) {
        pre = begin;
        begin = begin->next;
    }
    // 断开左边的
    pre->next = nullptr;

    // 从哪里结束
    end = begin;
    for (int i = m; i < n; i++) {
        end = end->next;
    }
    // 右边断开的
    endEnd = end->next;
    // 断开
    end->next = nullptr;
    // 反转区间的链表
    end = reverse(begin);
    // 反转之后接上， 区间头变成尾，尾巴变成了头
    pre->next = end;
    begin->next = endEnd;
    return newHead->next;
}

```

#### 解法二

利用头插法将新遍历的结点放到前面来。

![image-20220424134152549](index/image-20220424134152549.png)

1. 将cur的next指向next的next
2. next的next指向pre的next
3. pre的next指向next。

```c++
ListNode *reverseBetween(ListNode *head, int m, int n) {
    // 防止出现pre的问题
    auto *newHead = new ListNode(0);
    newHead->next = head;
    ListNode *pre = newHead;	
    for(int i = 1;i<m;i++){
        pre = pre->next;
    }
    cur = pre->next;
    for(int i = m;i<n;i++){
        ListNode*next = cur->next;
        cur->next= next->next;
        next->next= pre->next;
        pre->next= next;
    }
    return newHead->next;
}
```

### 链表中的节点每k个一组翻转

#### 描述

将给出的链表中的节点每 k 个一组翻转，返回翻转后的链表
如果链表中的节点数不是 k 的倍数，将最后剩下的节点保持原样
你不能更改节点中的值，只能更改节点本身。

数据范围： 0≤*n*≤2000 ， 1≤*k*≤2000 ，链表中每个元素都满足 0≤val≤1000
要求空间复杂度 O(1)，时间复杂度 O(n)

例如：

给定的链表是 1→2→3→4→5

对于 k=2 , 你应该返回 2→1→4→3→5

对于 k=3 , 你应该返回 3→2→1→4→5

#### 示例1

输入：

```
{1,2,3,4,5},2
```

复制

返回值：

```
{2,1,4,3,5}
```

复制

#### 示例2

输入：

```
{},1
```

复制

返回值：

```
{}
```

#### 解析

通过链表指定区间的反转我们知道了利用头插法进行转换链表，这个题也是类似。都反转，对每一组都是指定区间的反转。只需要将k个结点分为一组就行。

```c++
    ListNode* reverseKGroup(ListNode* head, int k) {
        int len = 0;
        ListNode*cur = head;
        ListNode*newHead = new ListNode(0);
        newHead->next = head;
        // 求出总共有多长
        while(cur){
            len++;
            cur = cur->next;
        }
        ListNode *pre = newHead;
        cur = head;
        // 分成多少组
        for(int i = 0;i<len/k;i++){
            // 组内进行区间反转
            for(int j = 1;j<k;j++){
                ListNode*next = cur->next;
                cur->next=next->next;
                next->next= pre->next;
                pre->next= next;
            }
            pre = cur;
            cur = cur->next;
        }
        return newHead->next;
    }
```

### 合并两个排序的链表

#### 描述

输入两个递增的链表，单个链表的长度为n，合并这两个链表并使新链表中的节点仍然是递增排序的。

如输入{1,3,5},{2,4,6}时，合并后的链表为{1,2,3,4,5,6}，所以对应的输出为{1,2,3,4,5,6}

#### 示例1

输入：

```
{1,3,5},{2,4,6}
```

返回值：

```
{1,2,3,4,5,6}
```

复制

#### 示例2

输入：

```
{},{}
```

返回值：

```
{}
```

#### 示例3

输入：

```
{-1,2,4},{1,3,4}
```

返回值：

```
{-1,1,2,3,4,4}
```

#### 解析

##### 解法一

利用归并排序的思想，进行模拟即可。

```c++
ListNode* Merge(ListNode* pHead1, ListNode* pHead2) {
    ListNode *res = new ListNode(0);
    ListNode *cur = res;
    while(pHead1&&pHead2){
        if(pHead1->val<=pHead2->val){
            cur->next = pHead1;
            pHead1 = pHead1->next;
        }else{
            cur->next = pHead2;
            pHead2 = pHead2->next;
      	}
        cur = cur->next;
    }
    if(pHead1){
        cur->next = pHead1;
    }
    if(pHead2){
        cur->next = pHead2;
    }
    return res->next;
}
```

##### 解法二

我们利用归并思想不断合并两个链表，每当我们添加完一个节点后，该节点指针后移，相当于这个链表剩余部分与另一个链表剩余部分合并，两个链表剩余部分合并就是原问题两个有序链表合并的子问题，因此也可以使用递归：

- **终止条件：** 当一个链表已经因为递归到了末尾，另一个链表剩余部分一定都大于前面的，因此我们可以将另一个链表剩余部分拼在结果后面，结束递归。
- **返回值：** 每次返回拼接好的较大部分的子链表。
- **本级任务：** 每级不断进入下一个较小的值后的链表部分与另一个链表剩余部分，再将本次的节点接在后面较大值拼好的结果前面。

**具体做法：**

- step 1：每次比较两个链表当前节点的值，然后取较小值的链表指针往后，另一个不变，两段子链表作为新的链表送入递归中。
- step 2：递归回来的结果我们要加在当前较小值的节点后面，相当于不断在较小值后面添加节点。
- step 3：递归的终止是两个链表有一个为空。

```c++
// 每次返回拼接好的较大部分的子链表
ListNode* Merge(ListNode* pHead1, ListNode* pHead2) {
    //一个已经为空了，返回另一个
    if(pHead1==nullptr){
        return pHead2;
    }
    if(pHead2==nullptr){
        return pHead1;
    }

    if(pHead1->val<=pHead2->val){
        pHead1->next = Merge(pHead1->next, pHead2);
        return pHead1;
    }else{
        pHead2->next = Merge(pHead1, pHead2->next);
        return pHead2;
    }
}
```


---
title: "Newcoder Top 101 二叉树"
date: 2022-05-03T20:16:44+08:00
draft: false
slug: e62967f0
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

此部分是**二叉树专题**。

[牛客网 (nowcoder.com)](https://www.nowcoder.com/exam/oj?page=1&tab=算法篇&topicId=295)

<!--more-->

## 二叉树的前序遍历

### 描述

给你二叉树的根节点 root ，返回它节点值的 前序 遍历。

数据范围：二叉树的节点数量满足$ 0 \le n \le 100$ ，二叉树节点的值满足 $1 \le val \le 100$  ，树的各节点的值各不相同

示例 1：

![img](index/FE67E09E9BA5661A7AB9DF9638FB1FAC.png)

### 示例1

输入：

```
{1,#,2,3}
```

返回值：

```
[1,2,3]
```

### 解析

#### 解析1-递归

按照前序遍历的定义，先遍历中间结点，接着遍历左孩子，在遍历右孩子。

```c++
void preorderTraversal(vector<int> &res,TreeNode*root){
        if(root==nullptr){
            return ;
        }
        res.push_back(root->val);
        preorderTraversal(res, root->left);
        preorderTraversal(res, root->right);
    }
    
    vector<int> preorderTraversal(TreeNode* root) {
        vector<int> res;
        preorderTraversal(res,root);
        return res;
    }
```

#### 解析2-迭代法

递归的方式使用到了函数栈，我们也可以自己用栈进行模拟。

对于前序遍历，我们先访问中间结点，再访问左边结点，最后访问右结点。但是根据栈的特性：先进后出。应该先放入右结点，再放入左结点。

```c++
vector<int> preorderTraversal(TreeNode* root){
    vector<int> res;
    if(root==nullptr){
        return res;
    }
    // 辅助栈
    stack<TreeNode*> help;
    help.push(root);
    // 不为空就继续
    while(!help.empty()){
        TreeNode*temp = help.top();
        help.pop();
        res.push_back(temp->val);
        // 要先放入右孩子
        if(temp->right){
            help.push(temp->right);
        }
        // 再放入左孩子
        if(temp->left){
            help.push(temp->left);
        }
    }
    return res;
}
```

## 二叉树的中序遍历

### 描述

给定一个二叉树的根节点root，返回它的中序遍历结果。

数据范围：树上节点数满足 $0 \le n \le 1000$，树上每个节点的值满足 $0 \le val \le 1000$
进阶：空间复杂度 O(n)，时间复杂度 O(n)

### 示例1

输入：

```
{1,2,#,#,3}
```

返回值：

```
[2,3,1]
```

说明：

![img](index/DB3124E4AB48ACA166EAC6A59F5ADCE9.png)

### 示例2

输入：

```
{}
```

返回值：

```
[]
```

### 示例3

输入：

```
{1,2}
```

返回值：

```
[2,1]
```

说明：

![img](index/348BF14EF65EB6D94D5EAD8895712DF1.png)

### 示例4

输入：

```
{1,#,2}
```

返回值：

```
[1,2]
```

说明：

![img](index/FF7B3016FB0274E8D3CBD7C082DBFFC9.png)

### 解析

#### 解析1-递归法

根据题意进行模拟

```c++
void inorderTraversal(vector<int> &res,TreeNode* root){
        if(root==nullptr){
            return ;
        }
        if(root->left){
            inorderTraversal(res,root->left);
        }
        res.push_back(root->val);
        if(root->right){
            inorderTraversal(res,root->right);
        }
    }
    vector<int> inorderTraversal(TreeNode* root) {
        vector<int>res;
        inorderTraversal(res,root);
        return res;
    }
```

#### 解析2-迭代法

由于中序遍历是先访问左孩子，我们就要先找到左孩子，一直要找到树叶的左孩子。一直深度优先找到左孩子，然后访问左孩子，之后访问中间结点，之后对右孩子进行这样迭代遍历。

```c++
vector<int> inorderTraversal(TreeNode* root){
    vector<int>res;
    if(root==nullptr){
        return res;
    }
    stack<TreeNode*>help;
    while(root||!help.empty()){
        while(root){
            help.push(root);
            root = root->left;
        }
        TreeNode*temp = help.top();
        help.pop();
        res.push_back(temp->val);
        root = temp->right;
    }
    return res;
}
```





## 总结

### 刷题时间

| 时间 | 题目     |
| ---- | -------- |
| 5-3  | 前序遍历 |
| 5-3  | 中序遍历 |

### 总结

1. 前序遍历要先遍历中间结点，之后遍历左孩子，再遍历右孩子，但是要先在栈中放入右孩子，再放入左孩子。
2. 中序遍历是要先遍历左孩子，之后遍历中间结点，再遍历右孩子。要找到最左边的孩子，就要深度优先可是进行搜索(root = root->left),之后访问中间结点。对访问的中间结点的右孩子也执行这个过程。


---
title: LeetCode-911-在线选举
tags:
  - 中等
categories:
  - LeetCode
slug: /acd85fa1
date: 2021-12-11 16:56:15
series: [ "leetcode" ] 
---



### 题目

给你两个整数数组 persons 和 times 。在选举中，第 i 张票是在时刻为 times[i] 时投给候选人 persons[i] 的。

对于发生在时刻 t 的每个查询，需要找出在 t 时刻在选举中领先的候选人的编号。

在 t 时刻投出的选票也将被计入我们的查询之中。在平局的情况下，最近获得投票的候选人将会获胜。

实现 TopVotedCandidate 类：

TopVotedCandidate(int[] persons, int[] times) 使用 persons 和 times 数组初始化对象。
int q(int t) 根据前面描述的规则，返回在时刻 t 在选举中领先的候选人的编号。

<!--more-->

### 示例

```tex
输入：
["TopVotedCandidate", "q", "q", "q", "q", "q", "q"]
[[[0, 1, 1, 0, 0, 1, 0], [0, 5, 10, 15, 20, 25, 30]], [3], [12], [25], [15], [24], [8]]
输出：
[null, 0, 1, 1, 0, 0, 1]

解释：
TopVotedCandidate topVotedCandidate = new TopVotedCandidate([0, 1, 1, 0, 0, 1, 0], [0, 5, 10, 15, 20, 25, 30]);
topVotedCandidate.q(3); // 返回 0 ，在时刻 3 ，票数分布为 [0] ，编号为 0 的候选人领先。
topVotedCandidate.q(12); // 返回 1 ，在时刻 12 ，票数分布为 [0,1,1] ，编号为 1 的候选人领先。
topVotedCandidate.q(25); // 返回 1 ，在时刻 25 ，票数分布为 [0,1,1,0,0,1] ，编号为 1 的候选人领先。（在平局的情况下，1 是最近获得投票的候选人）。
topVotedCandidate.q(15); // 返回 0
topVotedCandidate.q(24); // 返回 0
topVotedCandidate.q(8); // 返回 1

```

### 解释

对于给的示例进行解释，

首先初始化投票信息。

| 投给的候选人 | 时间 | 当前`0候选人`票数 | 当前`1候选人`票数 | 当前时间段领先的候选人    |
| ------------ | ---- | ----------------- | ----------------- | ------------------------- |
| 0号          | 0    | 1票               | 0票               | 0号                       |
| 1号          | 5    | 1票               | 1票（最近被投的） | 1号（最近被投的领先）     |
| 1号          | 10   | 1票               | 2票               | 1号（1<2票）              |
| 0号          | 15   | 2票（最近被投的） | 2票               | 0号（2==2）（最近被投的） |
| 0号          | 20   | 3票               | 2票               | 0号（3>2）                |
| 1号          | 25   | 3票               | 3票（最近被投的） | 1号(3==3)（最近被投的）   |
| 0号          | 30   | 4票               | 3票               | 0号(4>3)                  |

我们可以在初始化的时候进行预处理，构造一个某个时间段领先的候选人的表。如下

| 时间 | 领先的候选人 |
| :--: | :----------: |
|  0   |      0       |
|  5   |      1       |
|  10  |      1       |
|  15  |      0       |
|  20  |      0       |
|  25  |      1       |
|  30  |      0       |

如果给定一个时间`t`我们只需要找到比`t`小的最大的时间所对应的候选人是谁。

如给定时间`t=12`找到比12小的中最大的是`10`，此时对应领先的`1`号。

如给定时间`t=15`找到比15小的中最大的是`15`（比15<=15），此时对应领先的`0`号。

**注意：题目给的persons的取值范围，不是仅仅两个人**

```c++
class TopVotedCandidate {
public:
    vector<int> tops;
    vector<int> times;

    TopVotedCandidate(vector<int>& persons, vector<int>& times) {
        unordered_map<int, int> voteCounts;
        voteCounts[-1] = -1;
        int top = -1;
        for (auto & p : persons) {
            voteCounts[p]++;
            if (voteCounts[p] >= voteCounts[top]) {
                top = p;
            }
            tops.emplace_back(top);
        }
        this->times = times;
    }

    int q(int t) {
        // 找出比目标元素大的第一个元素
        int pos = upper_bound(times.begin(), times.end(), t) - times.begin() - 1;
        return tops[pos];
    }
};
```

`tops`就是我们所构造的表。

### 备注：

`unordered_map`:

#### 简介

1. unordered_map是一个将key和value关联起来的容器，它可以高效的根据单个key值查找对应的value。
2. key值应该是唯一的，key和value的数据类型可以不相同。
3. unordered_map存储元素时是没有顺序的，只是根据key的哈希值，将元素存在指定位置，所以根据key查找单个value时非常高效，平均可以在常数时间内完成。
4. unordered_map查询单个key的时候效率比map高，但是要查询某一范围内的key值时比map效率低。
5. 可以使用[]操作符来访问key值对应的value值。

#### map与unordered_map的区别

- **运行效率方面**：unordered_map最高，而map效率较低但 提供了稳定效率和有序的序列。
- **占用内存方面**：map内存占用略低，unordered_map内存占用略高,而且是线性成比例的。
- map: #include < map >
- unordered_map: #include < unordered_map >

#### 成员函数

##### 迭代器

| 方法             | 说明                                                |
| ---------------- | --------------------------------------------------- |
| begin            | 返回指向容器起始位置的迭代器（iterator）            |
| end              | 返回指向容器末尾位置的迭代器                        |
| cbegin           | 返回指向容器起始位置的常迭代器（const_iterator）    |
| cend             | 返回指向容器末尾位置的常迭代器                      |
| size             | 返回 unordered_map 支持的最大元素个数               |
| empty            | 判断是否为空                                        |
| operator[]       | 访问元素                                            |
| at               | 访问元素                                            |
| insert           | 插入元素                                            |
| erase            | 删除元素                                            |
| swap             | 交换内容                                            |
| clear            | 清空内容                                            |
| emplace          | 构造及插入一个元素                                  |
| emplace_hint     | 按提示构造及插入一个元素                            |
| find             | 通过给定主键查找元素,没找到：返回unordered_map::end |
| count            | 返回匹配给定主键的元素的个数                        |
| equal_range      | 返回值匹配给定搜索值的元素组成的范围                |
| bucket_count     | 返回槽（Bucket）数                                  |
| max_bucket_count | 返回最大槽数                                        |
| bucket_size      | 返回槽大小                                          |
| bucket           | 返回元素所在槽的序号                                |
| load_factor      | 返回载入因子，即一个元素槽（Bucket）的最大元素数    |
| max_load_factor  | 返回或设置最大载入因子                              |
| rehash           | 设置槽数                                            |
| reserve          | 请求改变容器容量                                    |

`upper_bound`

#### 简介

```c++
//查找[first, last)区域中第一个大于 val 的元素。
ForwardIterator upper_bound (ForwardIterator first, ForwardIterator last,const T& val);

//查找[first, last)区域中第一个不符合 comp 规则的元素
ForwardIterator upper_bound (ForwardIterator first, ForwardIterator last,const T& val, Compare comp);

```

```c++
#include <iostream>     // std::cout
#include <algorithm>    // std::upper_bound
#include <vector>       // std::vector
using namespace std;
//以普通函数的方式定义查找规则
bool mycomp(int i, int j) { return i > j; }
//以函数对象的形式定义查找规则
class mycomp2 {
public:
    bool operator()(const int& i, const int& j) {
        return i > j;
    }
};
int main() {
    int a[5] = { 1,2,3,4,5 };
    //从 a 数组中找到第一个大于 3 的元素
    int *p = upper_bound(a, a + 5, 3);
    cout << "*p = " << *p << endl;
    vector<int> myvector{ 4,5,3,1,2 };
    //根据 mycomp2 规则，从 myvector 容器中找到第一个违背 mycomp2 规则的元素
    vector<int>::iterator iter = upper_bound(myvector.begin(), myvector.end(), 3, mycomp2());
    cout << "*iter = " << *iter;
    return 0;
}
```

`结果`

```c++
*p = 4
*iter = 1
```


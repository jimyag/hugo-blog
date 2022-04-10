---
title: LeetCode-1185-一周中的第几天
tags:
  - 模拟
  - 简单
categories:
  - LeetCode
slug: ../95bcecc9
date: 2022-01-03 12:14:06
series: [ "leetcode" ] 
---

### 题目

给你一个日期，请你设计一个算法来判断它是对应一周中的哪一天。

输入为三个整数：day、month 和 year，分别表示日、月、年。

您返回的结果必须是这几个值中的一个 {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}。

<!--more-->

### 示例

#### 示例 1
```tex
输入：day = 31, month = 8, year = 2019
输出："Saturday"
```
#### 示例 2
```tex
输入：day = 18, month = 7, year = 1999
输出："Sunday"
```
#### 示例 3
```tex
输入：day = 15, month = 8, year = 1993
输出："Sunday"
```

### 解答

题目规定输入的日期一定是在 19711971 到 21002100 年之间的有效日期，即在 19711971 年 11 月 11 日，到 21002100 年 1212 月 3131 日之间。通过查询日历可知，19701970 年 1212 月 3131 日是星期四，我们只需要算出输入的日期距离 19701970 年 1212 月 3131 日有几天，再加上 33 后对 77 求余，即可得到输入日期是一周中的第几天。

求输入的日期距离 19701970 年 1212 月 3131 日的天数，可以分为三部分分别计算后求和：

1. 输入年份之前的年份的天数贡献；

2. 输入年份中，输入月份之前的月份的天数贡献；
3. 输入月份中的天数贡献。

例如，如果输入是 21002100 年 1212 月 3131 日，即可分为三部分分别计算后求和：

1. 19711971 年 11 月 11 到 20992099 年 1212 月 3131 日之间所有的天数；
2. 21002100 年 11 月 11 日到 21002100 年 1111 月 3131 日之间所有的天数；
3. 21002100 年 1212 月 11 日到 21002100 年 1212 月 3131 日之间所有的天数。

其中（1）和（2）部分的计算需要考虑到闰年的影响。当年份是 400400 的倍数或者是 44 的倍数且不是 100100 的倍数时，该年会在二月份多出一天。

### 代码

```c++
string dayOfTheWeek(int day, int month, int year) {
        vector<string> week = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
        vector<int> monthDays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30};
        /* 输入年份之前的年份的天数贡献 */
        int days = 365 * (year - 1971) + (year - 1969) / 4;
        /* 输入年份中，输入月份之前的月份的天数贡献 */
        for (int i = 0; i < month - 1; ++i) {
            days += monthDays[i];
        }
        if ((year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) && month >= 3) {
            days += 1;
        }
        /* 输入月份中的天数贡献 */
        days += day;
        return week[(days + 3) % 7];
    }
```

```c++
string dayOfTheWeek(int day, int month, int year) {
    string res[] = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
    if (month == 1 || month == 2) {
        month = month + 12;
        year--;
    }
    int index = 0;
    //基姆拉尔森计算公式
    index = (day + 2 * month + 3 * (month + 1) / 5 + year + year / 4 - year / 100 + year / 400) % 7;
    return res[index];
}
```

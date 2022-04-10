---
title: LeetCode-1154-一年中的第几天
tags:
  - 简单
categories:
  - LeetCode
slug: ../bd5751e9
date: 2021-12-21 08:58:18
series: [ "leetcode" ] 
---

### 题目

给你一个字符串 date ，按 YYYY-MM-DD 格式表示一个 现行公元纪年法 日期。请你计算并返回该日期是当年的第几天。

通常情况下，我们认为 1 月 1 日是每年的第 1 天，1 月 2 日是每年的第 2 天，依此类推。每个月的天数与现行公元纪年法（格里高利历）一致。

<!--more-->

### 示例

```tex
输入：date = "2019-01-09"
输出：9
```
```tex
输入：date = "2019-02-10"
输出：41
```
```tex
输入：date = "2003-03-01"
输出：60
```
```tex
输入：date = "2004-03-01"
输出：61
```

### 解答

按照题目意思进行模拟即可，在模拟过程中不能加上本月的时间，2月10号就是31+10。

### 代码

```c++
int dayOfYear(string date) {
    vector<string> result = split(date, "-");
    int year = stoi(result[0]);
    int month = stoi(result[1]);
    int day = stoi(result[2]);
    vector<int> days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    int ans = 0;
    if (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) {
        days[1] = 29;
    }
    for (int i = 0; i < month - 1; i++) {
        ans += days[i];
    }
    ans += day;
    return ans;
}

vector<string> split(const string &s, const string &seperator) {
    vector<string> result;
    typedef string::size_type string_size;
    string_size i = 0;

    while (i != s.size()) {
        //找到字符串中首个不等于分隔符的字母；
        int flag = 0;
        while (i != s.size() && flag == 0) {
            flag = 1;
            for (char x: seperator) {
                if (s[i] == x) {
                    ++i;
                    flag = 0;
                    break;

                }
            }
        }

        //找到又一个分隔符，将两个分隔符之间的字符串取出；
        flag = 0;
        string_size j = i;
        while (j != s.size() && flag == 0) {
            for (char x: seperator) {
                if (s[j] == x) {
                    flag = 1;
                    break;
                }
            }
            if (flag == 0)
                ++j;
        }
        if (i != j) {
            result.push_back(s.substr(i, j - i));
            i = j;
        }
    }
    return result;
}
```

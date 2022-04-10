---
title: LeetCode-630-课程表3
tags:
  - 困难
  - 贪心
categories:
  - LeetCode
slug: ../52f591e7
date: 2021-12-14 09:04:00
series: [ "leetcode" ] 
---

### 题目

这里有 n 门不同的在线课程，按从 1 到 n 编号。给你一个数组 courses ，其中 courses[i] = [durationi, lastDayi] 表示第 i 门课将会 持续 上 durationi 天课，并且必须在不晚于 lastDayi 的时候完成。

你的学期从第 1 天开始。且不能同时修读两门及两门以上的课程。

返回你最多可以修读的课程数目。

<!--more-->

### 示例

```tex
输入：courses = [[100, 200], [200, 1300], [1000, 1250], [2000, 3200]]
输出：3
解释：
这里一共有 4 门课程，但是你最多可以修 3 门：
首先，修第 1 门课，耗费 100 天，在第 100 天完成，在第 101 天开始下门课。
第二，修第 3 门课，耗费 1000 天，在第 1100 天完成，在第 1101 天开始下门课程。
第三，修第 2 门课，耗时 200 天，在第 1300 天完成。
第 4 门课现在不能修，因为将会在第 3300 天完成它，这已经超出了关闭日期。
```

```tex
输入：courses = [[1,2]]
输出：1
```

```tex
输入：courses = [[3,2],[4,3]]
输出：0
```

### 解答

要尽可能多的课程被选择，我们优先选择结束时间最早的课程，这样才能保证前面的课程是能被选择的，光靠这个进行选择是不行的。例如：[1,2] 、[3, 4]、[2, 5]这三门课的时候，如果按照上述方法进行选择，那么结果是：选择第一个课程，在选择第二个课程时候截止时间到了，不行，只能选择第三号课程。我们观察可以发现，其实可以先选三号课程，在选择2号课程。也就是在上述条件的基础上，优先选择**学习时长更短(duration)**的课程。使用大根堆可以满足我们的要求，我们在选择课程的时候做一判断：

1. 如果总学习时间+当前课程的学习时间<该课程的结束时间，那么这个课可以选择；
2. 如果不满足条件1，但是满足，在已经选择的课程中，最长的课程时间>当前的课程持续时间，那么就选择当前的课程，并把之前选择的最长的课程取消选择。

### 代码

```c++
// 贪心，按照结束时间的进行升序排列
sort(courses.begin(), courses.end(), [](const auto &c0, const auto &c1) {
    return c0[1] < c1[1];
});
// 最长的持续时间在前面
priority_queue<int> maxHeap;
// 优先队列中所有课程的总时间
int hadLearnedTime = 0;

for (const auto &course: courses) {
    int currentCourseDuration = course[0], currentCourseLastDay = course[1];
    //如果总时长不会超过截止时间，那么，当前这门课程可以选择，直接入堆
    if (hadLearnedTime + currentCourseDuration <= currentCourseLastDay) {
        hadLearnedTime += currentCourseDuration;
        maxHeap.push(currentCourseDuration);
    } else if (!maxHeap.empty() && maxHeap.top() > currentCourseDuration) {
        // 出现冲突，优先选择学习时长更短的课程
        hadLearnedTime = hadLearnedTime - maxHeap.top() + currentCourseDuration;
        maxHeap.pop();
        maxHeap.push(currentCourseDuration);
    }
}
return maxHeap.size();
```


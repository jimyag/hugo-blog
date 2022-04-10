---
title: LeetCode-71-简化路径
tags:
  - Linux
  - 中等
categories:
  - LeetCode
slug: ../30245f9e
date: 2022-01-06 22:08:14
series: [ "leetcode" ] 
---

### 题目

给你一个字符串 path ，表示指向某一文件或目录的 Unix 风格 绝对路径 （以 '/' 开头），请你将其转化为更加简洁的规范路径。

在 Unix 风格的文件系统中，一个点（.）表示当前目录本身；此外，两个点 （..） 表示将目录切换到上一级（指向父目录）；两者都可以是复杂相对路径的组成部分。任意多个连续的斜杠（即，'//'）都被视为单个斜杠 '/' 。 对于此问题，任何其他格式的点（例如，'...'）均被视为文件/目录名称。

请注意，返回的 规范路径 必须遵循下述格式：

始终以斜杠 '/' 开头。
两个目录名之间必须只有一个斜杠 '/' 。
最后一个目录名（如果存在）不能 以 '/' 结尾。
此外，路径仅包含从根目录到目标文件或目录的路径上的目录（即，不含 '.' 或 '..'）。
返回简化后得到的 规范路径 。

<!--more-->

### 示例

#### 示例 1
```tex
输入：path = "/home/"
输出："/home"
解释：注意，最后一个目录名后面没有斜杠。 
```
#### 示例 2
```tex
输入：path = "/../"
输出："/"
解释：从根目录向上一级是不可行的，因为根目录是你可以到达的最高级。
```
#### 示例 3
```tex
输入：path = "/home//foo/"
输出："/home/foo"
解释：在规范路径中，多个连续斜杠需要用一个斜杠替换。
```
#### 示例 4
```tex
输入：path = "/a/./b/../../c/"
输出："/c"
```
### 解答

#### 模拟

​	题目中已经解释过Linux文件的结构规范，在学过编译原理之后，我们可以把它划分为三个操作

1. ".." 后退上一级
2. "."在当前目录 忽略
3. 其他 进入下一目录

既然要有后退我们可以用栈来处理这个

将path通过'/'分割为不同的`操作`，对应的进行处理就行

处理完之后的栈就是层级的文件（名）,在每一个文件(名)前面加上'/'就是我们想要的结果了

#### 调包

goland的包

### 代码

```c++
string simplifyPath(string path) {
    stack<string> file;
    // 处理分割文件
    for (int i = 0; i < path.size(); i++) {
        if (path[i] == '/') {
            string temp = "";
            int j = i + 1;
            for (; j < path.size(); j++) {
                if (path[j] != '/') {
                    temp = temp + path[j];
                } else {
                    break;
                }
            }
            // 是否要后退
            if (temp == ".." && !file.empty()) {
                file.pop();
            }
            // 是否忽略
           // if (temp=="."){}
            
            // 进入下一目录
            if (temp != ".." && temp != "." && temp != "") {
                file.push(temp);
            }
            i = j - 1;
        }
    }
    string ans = "";
    int n = file.size();
    for (int i = 0; i < n; i++) {
        ans = "/" + file.top() + ans;
        file.pop();
    }
    // file 为空就要返回/
    if(ans==""){
        ans="/";
    }
    return ans;
}
```

```go
func simplifyPath(path string) string {
	return filepath.Clean(path)
}
```


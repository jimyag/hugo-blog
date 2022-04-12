---
title: LeetCode-第69场双周赛
tags:
  - 周赛
categories:
  - LeetCode
slug: /3087638f
date: 2022-01-08 23:52:25
series: [ "leetcode" ] 
---

双周赛太离谱了，签到完就溜。

<!--more-->

### 将标题首字母大写

给你一个字符串 `title` ，它由单个空格连接一个或多个单词组成，每个单词都只包含英文字母。请你按以下规则将每个单词的首字母 **大写** ：

- 如果单词的长度为 `1` 或者 `2` ，所有字母变成小写。
- 否则，将单词首字母大写，剩余字母变成小写。

请你返回 **大写后** 的 `title` 。

### 示例

#### **示例 1**

```
输入：title = "capiTalIze tHe titLe"
输出："Capitalize The Title"
解释：
由于所有单词的长度都至少为 3 ，将每个单词首字母大写，剩余字母变为小写。
```

#### **示例 2**

```
输入：title = "First leTTeR of EACH Word"
输出："First Letter of Each Word"
解释：
单词 "of" 长度为 2 ，所以它保持完全小写。
其他单词长度都至少为 3 ，所以其他单词首字母大写，剩余字母小写。
```

#### **示例 3**

```
输入：title = "i lOve leetcode"
输出："i Love Leetcode"
解释：
单词 "i" 长度为 1 ，所以它保留小写。
其他单词长度都至少为 3 ，所以其他单词首字母大写，剩余字母小写。
```

### 解答

将字符串以空格进行分割，并把分割新字符串转换为小写。

判断长度是否大于2，大于2的首字母大写

### 代码

```c++
string capitalizeTitle(string title) {
        vector<string> s;
        for (int i = 0; i < title.size(); i++) {
            string temp = "";
            int j = i;
            for (; j < title.size(); j++) {
                if (title[j] >= 'A' && title[j] <= 'Z') {
                    title[j] = tolower(title[j]);
                }
                if (title[j] != ' ') {
                    temp = temp + title[j];
                } else {
                    break;
                }
            }
            i = j;
            s.emplace_back(temp);
        }
        string ans = "";
        for (string a: s) {
            if (a.size() > 2) {
                a[0] = toupper(a[0]);
            }
            ans += a + ' ';
        }
        ans.pop_back();
        return ans;
    }
```

### 链表最大孪生和

在一个大小为 `n` 且 `n` 为 **偶数** 的链表中，对于 `0 <= i <= (n / 2) - 1` 的 `i` ，第 `i` 个节点（下标从 **0** 开始）的孪生节点为第 `(n-1-i)` 个节点 。

- 比方说，`n = 4` 那么节点 `0` 是节点 `3` 的孪生节点，节点 `1` 是节点 `2` 的孪生节点。这是长度为 `n = 4` 的链表中所有的孪生节点。

**孪生和** 定义为一个节点和它孪生节点两者值之和。

给你一个长度为偶数的链表的头节点 `head` ，请你返回链表的 **最大孪生和** 。

### 示例

#### 示例 1：

```
输入：head = [5,4,2,1]
输出：6
解释：
节点 0 和节点 1 分别是节点 3 和 2 的孪生节点。孪生和都为 6 。
链表中没有其他孪生节点。
所以，链表的最大孪生和是 6 。
```

#### **示例 2**

```
输入：head = [4,2,2,3]
输出：7
解释：
链表中的孪生节点为：
- 节点 0 是节点 3 的孪生节点，孪生和为 4 + 3 = 7 。
- 节点 1 是节点 2 的孪生节点，孪生和为 2 + 2 = 4 。
所以，最大孪生和为 max(7, 4) = 7 。
```

#### **示例 3**

```
输入：head = [1,100000]
输出：100001
解释：
链表中只有一对孪生节点，孪生和为 1 + 100000 = 100001 。
```

### 解答

按照题目要求模拟即可

### 代码

```c++
 int pairSum(ListNode* head) {
        vector<int> val;
        while (head != nullptr) {
            val.emplace_back(head->val);
            head = head->next;
        }
         if (val.size() == 2) {
            return val[0] + val[1];
        }
        int ans = 0;
        for (int i = 0; i <= val.size() / 2 - 1; i++) {
            int temp = val[i] + val[val.size() - i - 1];
            if (temp > ans) {
                ans = temp;
            }
        }
        return ans;
```

### 连接两字母单词得到的最长回文串

给你一个字符串数组 `words` 。`words` 中每个元素都是一个包含 **两个** 小写英文字母的单词。

请你从 `words` 中选择一些元素并按 **任意顺序** 连接它们，并得到一个 **尽可能长的回文串** 。每个元素 **至多** 只能使用一次。

请你返回你能得到的最长回文串的 **长度** 。如果没办法得到任何一个回文串，请你返回 `0` 。

**回文串** 指的是从前往后和从后往前读一样的字符串。

### 示例

#### 示例 1

```
输入：words = ["lc","cl","gg"]
输出：6
解释：一个最长的回文串为 "lc" + "gg" + "cl" = "lcggcl" ，长度为 6 。
"clgglc" 是另一个可以得到的最长回文串。
```

#### 示例 2

```
输入：words = ["ab","ty","yt","lc","cl","ab"]
输出：8
解释：最长回文串是 "ty" + "lc" + "cl" + "yt" = "tylcclyt" ，长度为 8 。
"lcyttycl" 是另一个可以得到的最长回文串。
```

#### 示例 3

```
输入：words = ["cc","ll","xx"]
输出：2
解释：最长回文串是 "cc" ，长度为 2 。
"ll" 是另一个可以得到的最长回文串。"xx" 也是。
```

### 解答

只处理完了相反的字符，相同的字符没有处理

### 代码

```C++
bool isAllSame(string s) {
    return s[0] == s[1];
}

int longestPalindrome(vector<string> words) {
    int ans = 0;
    // 处理完可以两两相反的
    for (int i = 0; i < words.size(); i++) {
        for (int j = i; j < words.size(); j++) {
            string *temp = new string(words[j]);
            reverse(temp->begin(), temp->end());
            if (words[i] == *temp) {
                ans += 4;
            }
        }
    }
    // 处理两两相同的，
    // 如果两两相反的为空
    // //找到两两相同的
    return ans;
```


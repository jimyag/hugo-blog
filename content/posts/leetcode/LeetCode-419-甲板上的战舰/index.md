---
title: LeetCode-419-甲板上的战舰
tags:
  - 中等
  - DFS
categories:
  - LeetCode
slug: /aa19f9bb
date: 2021-12-18 15:48:25
series: [ "leetcode" ] 
---

### 题目

给你一个大小为 m x n 的矩阵 board 表示甲板，其中，每个单元格可以是一艘战舰 'X' 或者是一个空位 '.' ，返回在甲板 board 上放置的 战舰 的数量。

战舰 只能水平或者垂直放置在 board 上。换句话说，战舰只能按 1 x k（1 行，k 列）或 k x 1（k 行，1 列）的形状建造，其中 k 可以是任意大小。两艘战舰之间至少有一个水平或垂直的空位分隔 （即没有相邻的战舰）。

<!--more-->

### 示例

![image-20211218160923014](index/image-20211218160923014.png)

```tex
输入：board = [["."]]
输出：0
```

### 解答

#### 方法1

题目的意思是只要横竖连在一块的`X`都算是一个战舰，找出有多少个战舰就行。

那么就对有战舰的地方进行对`row`和`column`进行深度优先搜索，就可以找到当前战舰的一部分，既然是这个战舰的一部分，可以消除这个'X'以免在后面中被重复计算到。

#### 方法2

题目进阶要求一次扫描算法，只使用 O(1)O(1) 额外空间，并且不修改甲板的值。因为题目中给定的两艘战舰之间至少有一个水平或垂直的空位分隔，任意两个战舰之间是不相邻的，因此我们可以通过枚举每个战舰的左上顶点即可统计战舰的个数。假设矩阵的行数为 row，矩阵的列数col，矩阵中的位置`[i][j]`为战舰的左上顶点，需满足以下条件：

满足当前位置所在的值 `board[i][j]` =`X`；

满足当前位置的左则为空位，即`board[i][j-1]` =`.`

满足当前位置的上方为空位，即`board[i-1][j]` =`.`

我们统计出所有战舰的左上顶点的个数即为所有战舰的个数。

### 代码

#### 方法1

```C++
int countBattleships(vector<vector<char>> &board) {
    int ans = 0;
    for (int row = 0; row < board.size(); row++) {
        for (int column = 0; column < board[row].size(); ++column) {
            if (board[row][column] == 'X') {
                dfs(board, row, column);
                ans++;
            }
        }
    }
    return ans;

}


void dfs(vector<vector<char>> &board, int row, int column) {
    if (row >= board.size() || column >= board[row].size() || board[row][column] == '.') {
        return;
    }
    board[row][column] = '.';
    dfs(board, row, column + 1);
    dfs(board, row + 1, column);
}
```

#### 方法2

```c++
int countBattleships(vector<vector<char>>& board) {
        int row = board.size();
        int col = board[0].size();
        int ans = 0;
        for (int i = 0; i < row; ++i) {
            for (int j = 0; j < col; ++j) { 
                if (board[i][j] == 'X') {
                    if (i > 0 && board[i - 1][j] == 'X') {
                        continue;
                    }
                    if (j > 0 && board[i][j - 1] == 'X') {
                        continue;
                    }
                    ans++;
                }
            }
        }
        return ans;
    }
```




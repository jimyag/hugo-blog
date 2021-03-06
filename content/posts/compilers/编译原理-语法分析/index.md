---
title: 编译原理-作业
tags:
  - 复习资料
categories:
  - 编译原理
slug: /29dc6b0
date: 2021-10-06 19:08:03
---

课上不努力、课后徒伤悲。好好听网课，好好学习！

<!--more-->

### FIRST集合

#### 定义

FIRST(X)是X所有可能推导的开头终结符号或可能推导的`ε`所构成的集合。

#### 构造FIRST集合

对于每个非终结符或终结符X连续使用以下规则，直至每个X的FIRST集合不再增大为止

1. 若左边第一个符号是**终结符**或者是**ε**，将其放在FIRST(X)中;
2. 若左边第一个符号是**非终结符**，将其FIRST集合中**非ε**元素加入FIRST(X)中;
3. 若左边第一个符号是**非终结符**而且紧随其后有很多**非终结符**，要注意是否有**ε**;
  1. 若第i个非终结符的FIRST集中有ε，则把第i+1个非终结符的FIRST集合除ε的元素加入FRIST(X);
  2. 若所有非终结符的FIRST集中都有ε，则把ε加入FIRST(X);

重复使用以上规则，直至每个X的FIRST集合不再增大为止。

#### 例题

> 对于文法G(E):
>
> > $$E-> TE^{\prime} $$
> >
> > $$E^{\prime}-> +TE^{\prime} |ε $$
> >
> > $$T->FT^{\prime}$$
> >
> > $$T^{\prime}->*FT^{\prime}|ε$$
> >
> > $$F->(E)|i$$
>
> 构造每个非终结符的FIRST集合

我们使用上述规则进行构造

##### 第一轮

###### E-> TE1

左边第一个是非终结符、紧随其后的也是终结符符合`2`,`3`规则，但是他们的FISRT集合都为空。

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |                         |                |                         |                |

###### E1-> +TE1|ε

规则 `1`：左边第一个是终结符和**ε**，将他们放进FIRST\{E1}集中

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |                |                         |                |

###### T->FT1

规则`2`: 将FIRSR{F}中的**非ε**元素加入FIRST(T)，FIRST{T}为空

规则`3`:FIRST{T}和FIRST{F1}为空

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |                |                         |                |

###### T1->*FT1|ε

规则`1`:将 *，ε加入FIRST{T1}

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |                |          *，ε           |                |

###### F->(E)|i

规则`1`:将 （，i加入FIRST{F}

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |                |          *，ε           |     （，i      |

FIRST集合还在增大所以继续下一轮

##### 第二轮

###### E-> TE1

规则`2`: FISRT{T}为空

规则`3`:   FISRT{T}为空

不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |                |          *，ε           |     （，i      |

###### E1-> +TE1|ε

规则 `1`：左边第一个是终结符和**ε**，将他们放进FIRST\{E1}集中。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |                |          *，ε           |     （，i      |

###### T->FT1

**规则`2`: 将FIRSR{F}中的非ε元素加入FIRST(T) 变化了。**

规则`3`:FIRST{F}没有ε，不用考虑了。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### T1->*FT1|ε

规则`1`:将 *，ε加入FIRST{T1}。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### F->(E)|i

规则`1`:将 （，i加入FIRST{F}不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|                |          +，ε           |     （，i      |          *，ε           |     （，i      |

有变化，继续从头开始扫描

##### 第三轮

###### E-> TE1

**规则`2`: 把FISRT{T}放入FISRT{E}中** 有变化

规则`3`:   FISRT{T}中没有**ε**，不用管

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### E1-> +TE1|ε

规则 `1`：左边第一个是终结符和**ε**，将他们放进FIRST\{E1}集中。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### T->FT1

规则`2`: 将FIRSR{F}中的非ε元素加入FIRST(T)。已经放过了

规则`3`:FIRST{F}没有ε，不用考虑了。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### T1->*FT1|ε

规则`1`:将 *，ε加入FIRST{T1}。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### F->(E)|i

规则`1`:将 （，i加入FIRST{F}不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

有变化，继续从头开始扫描

##### 第四轮

###### E-> TE1

规则`2`: 把FISRT{T}放入FISRT{E}中 。没有增大

规则`3`:   FISRT{T}中没有**ε**，不用管

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### E1-> +TE1|ε

规则 `1`：左边第一个是终结符和**ε**，将他们放进FIRST\{E1}集中。没有增大

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### T->FT1

规则`2`: 将FIRSR{F}中的非ε元素加入FIRST(T)。没有增大

规则`3`:FIRST{F}没有ε，不用考虑了。不变

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### T1->*FT1|ε

规则`1`:将 *，ε加入FIRST{T1}。没有增大

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

###### F->(E)|i

规则`1`:将 （，i加入FIRST{F} 没有增大

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

没有增大 结束。

最终结果为：

| $$FIRST\{E\}$$ | $$FIRST\{E^{\prime}\}$$ | $$FIRST\{T\}$$ | $$FIRST\{T^{\prime}\}$$ | $$FIRST\{F\}$$ |
| :------------: | :---------------------: | :------------: | :---------------------: | :------------: |
|     （，i      |          +，ε           |     （，i      |          *，ε           |     （，i      |

### FOLLOW集合

#### 定义

FOLLOW(A)是所有矩形中出现在紧接A之后的终结符或#所构成的集合

#### 构造FOLLOW集合、

对于每个非终结符A，连续使用以下规则，直至每个FOLLOW集合不再增大

1. 对于文法的开始符号S，置#于FOLLOW(S)中
2. 若A-> αBβ是一个产生式，则把FISRT{β}中非**ε**元素放入FOLLOW{B}中
3. 若 A-> αB 或 A-> αBβ 【ε∈FISRT{B}】则把FOLLOW{A}中的元素放入FOLLOW{B}。

αβ是由终结符和非终结符构成的

#### 例题

> 对于文法G(E):
>
> > $$E-> TE^{\prime} $$
> >
> > $$E^{\prime}-> +TE^{\prime} |ε $$
> >
> > $$T->FT^{\prime}$$
> >
> > $$T^{\prime}->*FT^{\prime}|ε$$
> >
> > $$F->(E)|i$$
>
> 构造每个非终结符的FOLLOW集合

根据规则`1`将# 放入FOLLOW{E}中

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|       ＃        |                          |                 |                          |                 |

##### 第一轮

###### E-> TE1

规则２：α为空，B为T，E１为β。将FISRT{E１}中非**ε**元素放入FOLLOW{T}中

规则３：α为T，B为E１　FOLLOW{E}中的元素放入FOLLOW{Ｅ１}。

规则３：α为空，B为T，E１为β，FISRT{E１}中有**ε**，将FOLLOW{E}中的元素放入FOLLOW{T}。

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|       ＃        |            ＃            |      +，＃      |                          |                 |

###### E1-> +TE1|ε

规则２：α为＋，B为T，β为E１，将FISRT{E１}中非**ε**元素放入FOLLOW{T}中　

规则３：α为＋T，B为E１　FOLLOW{E}中的元素放入FOLLOW{Ｅ１}。

规则３：α为空，B为T，E１为β，FISRT{E１}中有**ε**，将FOLLOW{E}中的元素放入FOLLOW{T}。

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|       ＃        |            ＃            |      +，＃      |                          |                 |

###### T->FT1

规则２：α为空，B为F，T１为β。将FISRT{T１}中非**ε**元素放入FOLLOW{F}中

规则３：α为F，B为T１　FOLLOW{T}中的元素放入FOLLOW{T１}。

规则３：α为空，B为F，T１为β，FISRT{T１}中有**ε**，将FOLLOW{T}中的元素放入FOLLOW{F}。

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|       ＃        |            ＃            |      +，＃      |          +，＃           |    *，+，＃     |

###### T1->*FT1|ε

规则２：α为＊，B为F，T１为β。将FISRT{T１}中非**ε**元素放入FOLLOW{F}中

规则３：α为＊F，B为T１　FOLLOW{T１}中的元素放入FOLLOW{T１}。不变

规则３：α为＊，B为F，T１为β，FISRT{T１}中有**ε**，将FOLLOW{T１}中的元素放入FOLLOW{F}。不变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|       ＃        |            ＃            |      +，＃      |          +，＃           |    *，+，＃     |

###### F->(E)|i

规则２：α为（，B为E，）为β。将FISRT{）}中非**ε**元素放入FOLLOW{E}中

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |            ＃            |      +，＃      |          +，＃           |        *        |

##### 第二轮

###### E-> TE1

规则２：α为空，B为T，E１为β。将FISRT{E１}中非**ε**元素放入FOLLOW{T}中。已经放过

规则３：α为T，B为E１　FOLLOW{E}中的元素放入FOLLOW{Ｅ１}。

规则３：α为空，B为T，E１为β，FISRT{E１}中有**ε**，将FOLLOW{E}中的元素放入FOLLOW{T}。已经放过

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |      +，＃      |          +，＃           |    *，+，＃     |

###### E1-> +TE1|ε

规则２：α为＋，B为T，β为E１，将FISRT{E１}中非**ε**元素放入FOLLOW{T}中

规则３：α为＋T，B为E１　FOLLOW{E}中的元素放入FOLLOW{Ｅ１}。没变

规则３：α为空，B为T，E１为β，FISRT{E１}中有**ε**，将FOLLOW{E}中的元素放入FOLLOW{T}。没变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |          +，＃           |    *，+，＃     |

###### T->FT1

规则２：α为空，B为F，T１为β。将FISRT{T１}中非**ε**元素放入FOLLOW{F}中。没变

规则３：α为F，B为T１　FOLLOW{T}中的元素放入FOLLOW{T１}。变了

规则３：α为空，B为F，T１为β，FISRT{T１}中有**ε**，将FOLLOW{T}中的元素放入FOLLOW{F}。变了

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

###### T1->*FT1|ε

规则２：α为＊，B为F，T１为β。将FISRT{T１}中非**ε**元素放入FOLLOW{F}中。已经放过

规则３：α为＊F，B为T１　FOLLOW{T１}中的元素放入FOLLOW{T１}。不变

规则３：α为＊，B为F，T１为β，FISRT{T１}中有**ε**，将FOLLOW{T１}中的元素放入FOLLOW{F}。不变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

###### F->(E)|i

规则２：α为（，B为E，）为β。将FISRT{）}中非**ε**元素放入FOLLOW{E}中。不变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

##### 第三轮

###### E-> TE1

规则２：α为空，B为T，E１为β。将FISRT{E１}中非**ε**元素放入FOLLOW{T}中。已经放过

规则３：α为T，B为E１　FOLLOW{E}中的元素放入FOLLOW{Ｅ１}。没变

规则３：α为空，B为T，E１为β，FISRT{E１}中有**ε**，将FOLLOW{E}中的元素放入FOLLOW{T}。已经放过

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |      +，＃      |          +，＃           |    *，+，＃     |

###### E1-> +TE1|ε

规则２：α为＋，B为T，β为E１，将FISRT{E１}中非**ε**元素放入FOLLOW{T}中。已经放过

规则３：α为＋T，B为E１　FOLLOW{E}中的元素放入FOLLOW{Ｅ１}。没变

规则３：α为空，B为T，E１为β，FISRT{E１}中有**ε**，将FOLLOW{E}中的元素放入FOLLOW{T}。没变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |          +，＃           |    *，+，＃     |

###### T->FT1

规则２：α为空，B为F，T１为β。将FISRT{T１}中非**ε**元素放入FOLLOW{F}中。已经放过

规则３：α为F，B为T１　FOLLOW{T}中的元素放入FOLLOW{T１}。没变

规则３：α为空，B为F，T１为β，FISRT{T１}中有**ε**，将FOLLOW{T}中的元素放入FOLLOW{F}。没变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

###### T1->*FT1|ε

规则２：α为＊，B为F，T１为β。将FISRT{T１}中非**ε**元素放入FOLLOW{F}中。已经放过

规则３：α为＊F，B为T１　FOLLOW{T１}中的元素放入FOLLOW{T１}。不变

规则３：α为＊，B为F，T１为β，FISRT{T１}中有**ε**，将FOLLOW{T１}中的元素放入FOLLOW{F}。不变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

###### F->(E)|i

规则２：α为（，B为E，）为β。将FISRT{）}中非**ε**元素放入FOLLOW{E}中。不变

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

所有的FOLLOW已经没在变化了，这时候已经计算完了。

最后的结果为：

| $$FOLLOW\{E\}$$ | $$FOLLOW\{E^{\prime}\}$$ | $$FOLLOW\{T\}$$ | $$FOLLOW\{T^{\prime}\}$$ | $$FOLLOW\{F\}$$ |
| :-------------: | :----------------------: | :-------------: | :----------------------: | :-------------: |
|     ＃，）      |          ＃，）          |    +，＃，）    |        +，＃，）         |  *，+，＃，）   |

### 消除左递归

#### 法一

将左递归变为右递归

> P->Pα|β
>
> 变为
>
> P->βP1
>
> P1->αP1|ε

对于文法`P->Pα|β`我们可以推导出他能识别的串，它是以β开头后面接着0-n个α的串；βαααααα....

#### 法二

##### 条件

1. 不含以**ε**为右部的产生式
2. 不含回路（p->p）

##### 方法

1. 对非终结符进行排列P1.....Pn
2. 从P1到Pn遍历,把Pi改为`α|Pi+1|Pi+2|...|Pn`
   1. 从j=1 到j=i-1把形如Pi->Pjγ的改写为`Pi->ζ1γ|ζ2γ|...|ζkγ ` 其中`Pj->ζ1|ζ2|...|ζk`。此时就可以得到形如 `Pi->α|Pi|Pi|...|Pi+k|...`
   2. 使用直接消除Pi使用`方法一`
3. 化简`2`，去除从开始符号出发永远无法到达的非终结符产生规则

#### 例题

> 考虑文法G[S]
>
> > S->(T)|a+S|a
> >
> > T->T，S|S
>
> 消除左递归

##### 第一步

只有两个非终结符，按照一定顺序排序，按照T，S的顺序排列

##### 第二步

1. 先处理T

   > T->T，S|S 

   由于T在前面，S在后面，所以S不处理(2.1)。由于本身有左递归，使用方法一直接消除左递归

   > T->ST1
   >
   > T1-> ,ST1|ε

2. 处理S

   > S->(T)|a+S|a

   由于T在S的前面，所以要将T处理掉。T又有（T->ST1）进行替换

   > S->(ST1)|a+S|a

   不含有左递归，处理结束

3. 化简

   > S->(ST1)|a+S|a
   >
   > T->ST1
   >
   > T1-> ,ST1|ε

   从开始符号都可以到达，所以不用去掉

##### 结果为

> S->(ST1)|a+S|a
>
> T->ST1
>
> T1-> ,ST1|ε

### 提取左公共因子

对于规则S   

> S ->  aB1|aB2|aB3|aB4|...|aBn|y   

可以改写为

> S-> aS1|y
> S1 -> B1|B2|B3...|Bn   



### FISRTVT集合

#### 方法

1. A->a.....  则将a加入FIRSTVT(A)中
2. A->B.... 将FIRSTVT(B)加入到FIRSTVT(A)中
3. A->Ba... 

#### 例题

已给文法：

> G[S]:
> S→a|b|(B)
> A→S, A|S
> B→A

求非终结符的FISRTVT集合

##### 求FIRSTVT(S)

> S→a|b|(B)

根据规则`1`可得

FIRSTVT(S)= {a,b,(}

##### 求FIRSTVT(A)

> A→S, A|S

根据规则`2`可得，应该FISRTVT(S)中的放入FIRSTVT(A)中

FIRSTVT(A) = {a,b,(}

根据规则`3`，应该把`,`放入FIRSTVT(A)中

FIRSTVT(A) = {a,b,(,逗号}

##### 求FIRSTVT(B)

> B→A

根据规则`3`，应该FISRTVT(A)中的放入FIRSTVT(B)中

FIRSTVT(B) = {a,b,(,逗号}

|      |   FISRTVT    |
| :--: | :----------: |
|  S   |   {a,b,(}    |
|  A   | {a,b,(,逗号} |
|  B   | {a,b,(,逗号} |

### LASTVT集合

#### 方法

1. A->.....a  把a加入LASTVT(A)中
2. A->.....B  把LASTVT(B)加入LASTVT(A)中
3. A->....aB 把a加入LASTVT(A)中

#### 例题

已给文法：

> G[S]:
> S→a|b|(B)
> A→S, A|S
> B→A

求非终结符的LASTVT集合

##### 求LASTVT(S)

> S→a|b|(B)

根据规则`1`可得

LASTVT(S)= {a,b,)}

##### 求LASTVT(A)

> A→S, A|S

根据规则`2`可得，应该LASTVT(S)中的放入LASTVT(A)中

LASTVT(A) = {a,b,)}

根据规则`3`，应该把`,`放入LASTVT(A)中

LASTVT(A) = {a,b,),逗号}

##### 求LASTVT(B)

> B→A

根据规则`3`，应该LASTVT(A)中的放入LASTVT(B)中

FIRSTVT(B) = {a,b,),逗号}

|      |    LASTVT    |
| :--: | :----------: |
|  S   |   {a,b,)}    |
|  A   | {a,b,),逗号} |
|  B   | {a,b,),逗号} |

### 算符优先文法OPG的条件

1. OPG文法条件
   1. 无S->...AB...
   2. 无ε产生式
2. 两两终结符间至多一种优先关系

### 判断算符优先级

#### 方法一

1. 找出所有非终结符，画出一下表格

   |      | a    | b    | c    | ...  | n    |
   | ---- | ---- | ---- | ---- | ---- | ---- |
   | a    |      |      |      |      |      |
   | b    |      |      |      |      |      |
   | c    |      |      |      |      |      |
   | ...  |      |      |      |      |      |
   | n    |      |      |      |      |      |

2. ＝ 找aQb形式的，a=b，横排找a，竖排找b

3. <  找aQ形式的，a与FISRSTVT(Q)的每个元素交叉处填`<`，a为横排元素

4. \>  找Qa形式的，在竖排中找到a，在横排中找到LASTVT(Q)中的元素，相交处填`>`

5. \# < FIRSTVT(A)

6. LASTVT(A)>#

#### 例题

已给文法：

> G[S]:
> S→a|b|(B)
> A→S, A|S
> B→A

判断算符优先级

根据上面我们已经求出非终结符的FIRSTVT和LASTVT集合。列表

|      | a    | b    | （   | ）   | ，   |
| ---- | ---- | ---- | ---- | ---- | ---- |
| a    |      |      |      |      |      |
| b    |      |      |      |      |      |
| （   |      |      |      |      |      |
| ）   |      |      |      |      |      |
| ，   |      |      |      |      |      |

1. =  我们可以找到`(B)`是符合要求的，则

|      | a    | b    | （   | ）   | ，   |
| ---- | ---- | ---- | ---- | ---- | ---- |
| a    |      |      |      |      |      |
| b    |      |      |      |      |      |
| （   |      |      |      | =    |      |
| ）   |      |      |      |      |      |
| ，   |      |      |      |      |      |

2.  < 我们找到aQ形式的，有`(B`,`,A` 则从横排找`(`,在竖排中找到FIRSTVT(B)，在交叉处填上`<`。在横排中找到`，`在竖排中国找到FIRSTVT(A)中的元素，在交叉处填上`<`

|      | a    | b    | （   | ）   | ，   |
| ---- | ---- | ---- | ---- | ---- | ---- |
| a    |      |      |      |      |      |
| b    |      |      |      |      |      |
| （   | <    | <    | <    | =    | <    |
| ）   |      |      |      |      |      |
| ，   | <    | <    | <    |      | <    |

3. \> 我们找到Qa形式的，有`B)`,`S,` ，在竖排中找到`)`,在横排中找到LASTVT(B)中的元素，在交叉处填上`>`, 在竖排找到`,` 在横排找到LASTVT(S)，在交叉处填上`>`


   |      | a    | b    | （   | ）   | ，   |
   | ---- | ---- | ---- | ---- | ---- | ---- |
   | a    |      |      |      | >    | >    |
   | b    |      |      |      | >    | >    |
   | （   | <    | <    | <    | =    | <    |
   | ）   |      |      |      | >    | >    |
   | ，   | <    | <    | <    | >    | <    |


4. \# < FIRSTVT(A)  横纵额外添加一列(行)`#`


   |      | a    | b    | （   | ）   | ，   | #    |
   | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
   | a    |      |      |      | >    | >    | >    |
   | b    |      |      |      | >    | >    | >    |
   | （   | <    | <    | <    | =    | <    |      |
   | ）   |      |      |      | >    | >    | >    |
   | ，   | <    | <    | <    | >    | <    |      |
   | #    | <    | <    | <    |      | <    | >    |

   \# < FIRSTVT(S) 

   \# < FIRSTVT(A) 

   \# < FIRSTVT(B) 

5. LASTVTVT(A)>#  

   LASTVTVT(S)>#

   LASTVTVT(A)>#

   LASTVTVT(B)>#

#### 结果如下

|      | a    | b    | （   | ）   | ，   | #    |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| a    |      |      |      | >    | >    | >    |
| b    |      |      |      | >    | >    | >    |
| （   | <    | <    | <    | =    | <    |      |
| ）   |      |      |      | >    | >    | >    |
| ，   | <    | <    | <    | >    | <    |      |
| #    | <    | <    | <    |      | <    | >    |

#### 方法二

1. 对于文法的开始符号S，增加拓广文法S1->#S#

2. 找出所有非终结符，画出一下表格

   |      | a    | b    | c    | ...  | n    | #    |
   | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
   | a    |      |      |      |      |      |      |
   | b    |      |      |      |      |      |      |
   | c    |      |      |      |      |      |      |
   | ...  |      |      |      |      |      |      |
   | n    |      |      |      |      |      |      |
   | #    |      |      |      |      |      |      |

3. ＝ 找aQb形式的，a=b，横排找a，竖排找b

4. <  找aQ形式的，a与FISRSTVT(Q)的每个元素交叉处填`<`，a为横排元素

5. \>  找Qa形式的，在竖排中找到a，在横排中找到LASTVT(Q)中的元素，相交处填`>`

此方法不用额外判断`#`的优先级，在与其他的处理过程中，会一同处理

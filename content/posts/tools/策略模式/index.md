---
title: 策略模式
tags:
  - 策略模式
categories:
  - 设计模式
slug: /72e3b671
date: 2021-12-11 16:48:29
---

在现实生活中常常遇到实现某种目标存在多种策略可供选择的情况，例如，出行旅游可以乘坐飞机、乘坐火车、骑自行车或自己开私家车等，超市促销可以釆用打折、送商品、送积分等方法。

<!--more-->

```go
struct Order{}
order Order = 订单信息
if payType == 微信支付{
    微信支付流程
} else if payType == 支付宝{
    支付宝支付流程
} else if payType == 银行卡{
    银行卡支付流程
} else {
    暂不支持的支付方式
}
```

如上代码，虽然写起来简单，但违反了面向对象的 2 个基本原则：

- `单一职责原则`：一个类只有1个发生变化的原因
  之后修改任何逻辑，当前方法都会被修改
- `开闭原则`：对扩展开放，对修改关闭
  当我们需要增加、减少某种支付方式(积分支付/组合支付)，或者增加优惠券等功能时，不可避免的要修改该段代码

特别是当 `if-else` 块中的代码量比较大时，后续的扩展和维护会变得非常复杂且容易出错。在阿里《Java开发手册》中，有这样的规则：`超过3层的 if-else 的逻辑判断代码可以使用卫语句、策略模式、状态模式等来实现`。

策略模式是解决过多 `if-else`（或者 `switch-case`） 代码块的方法之一，提高代码的可维护性、可扩展性和可读性。

### 定义

该模式定义了一系列算法，并将每个算法封装起来，使它们可以相互替换，且算法的变化不会影响使用算法的客户。策略模式属于对象行为模式，它通过对算法进行封装，把**使用算法的责任**和**算法的实现**分割开来，并委派给不同的对象对这些算法进行管理。

### 理解

策略，也就是计策的意思。刘备每到关键时刻就可以打开一个(封装的)锦囊，得到一个战胜敌人的策略(火攻、水攻等等)；再例如我们想去黄山旅游，我们可以选择不同的策略(飞机、火车、开车)，不管是使用哪种策略，不会影响我们抵达黄山游览，只是耗时长短的问题。

### 代码

这里我们用最容易理解的计算器为例。计算器支持加、减、乘、除等等计算方法(策略)。只要我们输入两数字，使用其中一个策略即可得到一个结果。对于计算器使用者来说，无需关心实际的算法运算过程，只需要输入数字即可。而对于算法的实现者来说，新的算法策略只要能接受两个参数入参进行运算，即可对接到计算器中，扩展了计算器的功能。

这里我们先定义一个通用的计算策略`Calc`，接收两个参数`a`和`b`

```go
type Strategy interface{
    Calc(a,b int) int
}
```

#### 加法策略

```go
//AddStrategy 加法策略
type AddStrategy struct {
}

func (t AddStrategy) Calc(a, b int) int {
    return a + b
}
```

#### 实现减法策略

```go
//SubStrategy 减法策略
type SubStrategy struct {
}

func (t SubStrategy) Calc(a, b int) int {
    return a - b
}
```

#### 将策略对接到实际的计算器中

```go
//Calculator 计算器
type Calculator struct {
    s Strategy
}

func (t *Calculator) setStrategy(s Strategy) { 
    t.s = s
}
func (t Calculator) GetResult(a, b int) int {
    return t.s.Calc(a, b)
}
```

对于计算器来说，他只需要使用`setStrategy`设置不同的计算策略，通过`GetResult`函数获取结果。

开始使用计算器计算

```go
func main() {
    add := AddStrategy{} //加法策略
    sub := SubStrategy{} //减法策略
    //计算器通过setStrategy设置不同策略，解耦了计算器和算法实现类
    cal := &Calculator{}
    cal.setStrategy(add)
    fmt.Println("加法策略结果:", cal.GetResult(1, 1))
    cal.setStrategy(sub)
    fmt.Println("减法策略结果:", cal.GetResult(1, 1))
}
```

输出结果

```text
加法策略结果: 2
减法策略结果: 0
```

### 总结

策略模式的重点在于策略的设定，以及普通类`Calculator`与策略`Strategy`的对接。通过更换实现同一个接口`Strategy`的不同策略类`AddStrategy`和`SubStrategy`。降低了`Calculator`的维护成本，解耦和计算器和算法实现，符合设计模式的开放闭合原则。



### 完整代码如下

```go
package main

import "fmt"

//这里以计算器为例，包含两种功能 （加法、减法）
/*
//这种代码优点，如果只有这两种计算方法，编写简单容易理解。如果后续计算器包含很多计算方法(乘法、除法) Cal 结构体就需要不同的修改。违背了代码放开闭合原则。好的代码，应该是支持扩展，减少对原有代码修改，可以快速满足不同用户的需求。
type Cal struct{

}

func (t Cal)Add(a,b int) int{
	return a+b
}

func (t Cal)Sub(a,b int)int{
	return a-b
}
*/

//Strategy 定义策略接口
type Strategy interface {
	Calc(a, b int) int
}

//AddStrategy 加法策略
type AddStrategy struct {
}

func (t AddStrategy) Calc(a, b int) int {
	return a + b
}

//SubStrategy 减法策略
type SubStrategy struct {
}

func (t SubStrategy) Calc(a, b int) int {
	return a - b
}

//Calculator 计算器
type Calculator struct {
	s Strategy
}

func (t *Calculator) setStrategy(s Strategy) {
	t.s = s
}
func (t Calculator) GetResult(a, b int) int {
	return t.s.Calc(a, b)
}
func main() {
	add := AddStrategy{}
	sub := SubStrategy{}
	//计算器通过setStrategy设置不同策略，解耦了计算器和算法实现类
	cal := &Calculator{}
	cal.setStrategy(add)
	fmt.Println("加法策略结果:", cal.GetResult(1, 1))
	cal.setStrategy(sub)
	fmt.Println("减法策略结果:", cal.GetResult(1, 1))
}
```

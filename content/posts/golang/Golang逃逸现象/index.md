---
title: Golang逃逸现象
tags:
  - 教程
  - 逃逸分析
categories:
  - - Go
  - - 教程
slug: ../427ffcfc
date: 2022-01-18 14:34:24
---

go语言编译器会自动决定把一个变量放在栈还是放在堆，编译器会做**逃逸分析(escape analysis)**，**当发现变量的作用域没有跑出函数范围，就可以在栈上，反之则必须分配在堆**。
go语言声称这样可以释放程序员关于内存的使用限制，更多的让程序员关注于程序功能逻辑本身。

<!--more-->

### 什么是堆？什么是栈？

简单说：

- 堆：一般来讲是人为手动进行管理，手动申请、分配、释放。一般所涉及的内存大小并不定，一般会存放较大的对象。另外其分配相对慢，涉及到的指令动作也相对多
- 栈：由编译器进行管理，自动申请、分配、释放。一般不会太大，我们常见的函数参数（不同平台允许存放的数量不同），局部变量等等都会存放在栈上

### 逃逸分析

逃逸分析是一种确定指针动态范围的方法，简单来说就是分析在程序的哪些地方可以访问到该指针。

通俗地讲，逃逸分析就是确定一个变量要放堆上还是栈上，规则如下：

- 是否有在其他地方（非局部）被引用。只要有可能被引用了，那么它一定分配到堆上。否则分配到栈上
- 即使没有被外部引用，但对象过大，无法存放在栈区上。依然有可能分配到堆上

对此你可以理解为，逃逸分析是编译器用于决定变量分配到堆上还是栈上的一种行为。

### 为什么需要逃逸

其实就是为了尽可能在栈上分配内存，我们可以反过来想，如果变量都分配到堆上了会出现什么事情？例如：

1. 垃圾回收（GC）的压力不断增大
2. 申请、分配、回收内存的系统开销增大（相对于栈）
3. 动态分配产生一定量的内存碎片

其实总的来说，就是频繁申请、分配堆内存是有一定 “代价” 的。会影响应用程序运行的效率，间接影响到整体系统。因此 “按需分配” 最大限度的灵活利用资源，才是正确的治理之道。这就是为什么需要逃逸分析的原因。

### Golang编译器的逃逸分析

我们再看如下代码:

```go
package main

func foo(argVal int) *int {

	var fooVal1 int = 11
	var fooVal2 int = 12
	var fooVal3 int = 13
	var fooVal4 int = 14
	var fooVal5 int = 15
	//此处循环是防止go编译器将foo优化成inline(内联函数)
	//如果是内联函数，main调用foo将是原地展开，所以foo_val1-5相当于main作用域的变量
	//即使foo_val3发生逃逸，地址与其他也是连续的
	for i := 0; i < 5; i++ {
		println(&argVal, &fooVal1, &fooVal2, &fooVal3, &fooVal4, &fooVal5)
	}

	//返回foo_val3给main函数
	return &fooVal3
}

func main() {
	mainVal := foo(666)

	println(*mainVal, mainVal)
}
```

运行结果如下

```bash
0xc000049f60 0xc000049f58 0xc000049f50 0xc000049f48 0xc000049f40 0xc000049f38
0xc000049f60 0xc000049f58 0xc000049f50 0xc000049f48 0xc000049f40 0xc000049f38
0xc000049f60 0xc000049f58 0xc000049f50 0xc000049f48 0xc000049f40 0xc000049f38
0xc000049f60 0xc000049f58 0xc000049f50 0xc000049f48 0xc000049f40 0xc000049f38
0xc000049f60 0xc000049f58 0xc000049f50 0xc000049f48 0xc000049f40 0xc000049f38
13 0xc000049f48
```

我们能看到`foo_val3`是返回给main的局部变量, 其中他的地址应该是`0xc000049f48`,很明显与其他的foo_val1、2、3、4不是连续的.

我们用`go tool compile`测试一下

```bash
D:\code\go\test>go tool compile -m main.go
main.go:3:6: can inline foo
main.go:21:6: can inline main
main.go:22:16: inlining call to foo
main.go:7:6: moved to heap: fooVal3
```

果然,在编译的时候, `foo_val3`具有被编译器判定为逃逸变量, 将`foo_val3`放在堆中开辟.

### new的变量在栈还是堆?

那么对于new出来的变量,是一定在heap中开辟的吗,我们来看看

```go
package main

func foo(argVal int) *int {

   var fooVal1 *int = new(int)
   var fooVal2 *int = new(int)
   var fooVal3 *int = new(int)
   var fooVal4 *int = new(int)
   var fooVal5 *int = new(int)

   //此处循环是防止go编译器将foo优化成inline(内联函数)
   //如果是内联函数，main调用foo将是原地展开，所以foo_val1-5相当于main作用域的变量
   //即使foo_val3发生逃逸，地址与其他也是连续的
   for i := 0; i < 5; i++ {
      println(argVal, fooVal1, fooVal2, fooVal3, fooVal4, fooVal5)
   }

   //返回foo_val3给main函数
   return fooVal3
}

func main() {
   mainVal := foo(666)

   println(*mainVal, mainVal)
}
```

我们将foo_val1-5全部用new的方式来开辟, 编译运行看结果

```bash
666 0xc000049f40 0xc000049f68 0xc000049f60 0xc000049f58 0xc000049f50
666 0xc000049f40 0xc000049f68 0xc000049f60 0xc000049f58 0xc000049f50
666 0xc000049f40 0xc000049f68 0xc000049f60 0xc000049f58 0xc000049f50
666 0xc000049f40 0xc000049f68 0xc000049f60 0xc000049f58 0xc000049f50
666 0xc000049f40 0xc000049f68 0xc000049f60 0xc000049f58 0xc000049f50
0 0xc000049f60
```

很明显, `foo_val3`的地址`0xc000049f60`依然与其他的不是连续的. 依然具备逃逸行为.

### 逃逸规则

我们其实都知道一个普遍的规则，就是如果变量需要使用堆空间，那么他就应该进行逃逸。但是实际上Golang并不仅仅把逃逸的规则如此泛泛。Golang会有很多场景具备出现逃逸的现象。

一般我们给一个引用类对象中的引用类成员进行赋值，可能出现逃逸现象。可以理解为访问一个引用对象实际上底层就是通过一个指针来间接的访问了，但如果再访问里面的引用成员就会有第二次间接访问，这样操作这部分对象的话，极大可能会出现逃逸的现象。

Go语言中的引用类型有func（函数类型），interface（接口类型），slice（切片类型），map（字典类型），channel（管道类型），*（指针类型）等。

那么我们下面的一些操作场景是产生逃逸的。

#### `[]interface{}`数据类型，通过`[]`赋值必定会出现逃逸。

```go
package main

func main() {
   data := []interface{}{100, 200}
   data[0] = 100
}
```

```bash
D:\code\go\test>go tool compile -m main.go
main.go:3:6: can inline main
main.go:4:23: []interface {}{...} does not escape
main.go:4:24: 100 does not escape
main.go:4:29: 200 does not escape
main.go:5:10: 100 escapes to heap
```

我们能看到，`data[0] = 100` 发生了逃逸现象。

#### `map[string]interface{}`类型尝试通过赋值，必定会出现逃逸。

```go
package main

func main() {
   data := make(map[string]interface{})
   data["key"] = 200
}
```

```bash
D:\code\go\test>go tool compile -m main.go
main.go:3:6: can inline main
main.go:4:14: make(map[string]interface {}) does not escape
main.go:5:14: 200 escapes to heap
```

我们能看到，`data["key"] = 200` 发生了逃逸。

#### `map[interface{}]interface{}`类型尝试通过赋值，会导致key和value的赋值，出现逃逸。

```go
package main

func main() {
   data := make(map[interface{}]interface{})
   data[100] = "dddd"
}
```

```bash
D:\code\go\test>go tool compile -m main.go
main.go:3:6: can inline main
main.go:4:14: make(map[interface {}]interface {}) does not escape
main.go:5:6: 100 escapes to heap
main.go:5:12: "dddd" escapes to heap
```

我们能看到，`data[100] = "dddd"` 中，100和"dddd"均发生了逃逸。

#### `map[string][]string`数据类型，赋值会发生`[]string`发生逃逸。

```go
package main

func main() {
    data := make(map[string][]string)
    data["key"] = []string{"value"}
}
```

```bash
D:\code\go\test>go tool compile -m main.go
main.go:3:6: can inline main
main.go:4:14: make(map[string][]string) does not escape
main.go:5:24: []string{...} escapes to heap
```

我们能看到，`[]string{...}`切片发生了逃逸。

#### `[]*int`数据类型，赋值的右值会发生逃逸现象。

```go
package main

func main() {
    a := 10
    data := []*int{nil}
    data[0] = &a
}
```

我们通过编译看看逃逸结果

```bash
go tool compile -m 5.go
5.go:3:6: can inline main
5.go:4:2: moved to heap: a
5.go:6:16: []*int{...} does not escape
```

其中 `moved to heap: a`，最终将变量a 移动到了堆上。

#### `func(*int)`函数类型，进行函数赋值，会使传递的形参出现逃逸现象。

```go
package main

import "fmt"

func foo(a *int) {
    return
}

func main() {
    data := 10
    f := foo
    f(&data)
    fmt.Println(data)
}
```

我们通过编译看看逃逸结果

```go
aceld:test ldb$ go tool compile -m 6.go
6.go:5:6: can inline foo
6.go:12:3: inlining call to foo
6.go:14:13: inlining call to fmt.Println
6.go:5:10: a does not escape
6.go:14:13: data escapes to heap
6.go:14:13: []interface {}{...} does not escape
:1: .this does not escape
```

我们会看到data已经被逃逸到堆上。

#### `func([]string)`: 函数类型，进行`[]string{"value"}`赋值，会使传递的参数出现逃逸现象。

```go
package main

import "fmt"

func foo(a []string) {
    return
}

func main() {
    s := []string{"aceld"}
    foo(s)
    fmt.Println(s)
}
```

我们通过编译看看逃逸结果

```bash
go tool compile -m 7.go
7.go:5:6: can inline foo
7.go:11:5: inlining call to foo
7.go:13:13: inlining call to fmt.Println
7.go:5:10: a does not escape
7.go:10:15: []string{...} escapes to heap
7.go:13:13: s escapes to heap
7.go:13:13: []interface {}{...} does not escape
 :1: .this does not escape
```

我们看到 `s escapes to heap`，s被逃逸到堆上。

#### `chan []string`数据类型，想当前channel中传输`[]string{"value"}`会发生逃逸现象。

```go
package main

func main() {
    ch := make(chan []string)

    s := []string{"aceld"}

    go func() {
        ch <- s
    }()
}
```

我们通过编译看看逃逸结果

```bash
go tool compile -m 8.go
8.go:8:5: can inline main.func1
8.go:6:15: []string{...} escapes to heap
8.go:8:5: func literal escapes to heap
```

我们看到`[]string{...} escapes to heap`, s被逃逸到堆上。

### 总结

我们得出了指针**必然发生逃逸**的三种情况

- 在某个函数中new或字面量创建出的变量，将其指针作为函数返回值，则该变量一定发生逃逸（构造函数返回的指针变量一定逃逸）；
- 被已经逃逸的变量引用的指针，一定发生逃逸；
- 被指针类型的slice、map和chan引用的指针，一定发生逃逸；

同时我们也得出一些**必然不会逃逸**的情况：

- 指针被未发生逃逸的变量引用；
- 仅仅在函数内对变量做取址操作，而未将指针传出；

### 参考

[golang 逃逸分析与栈、堆分配分析_惜暮-CSDN博客_golang 堆栈分配](https://blog.csdn.net/u010853261/article/details/102846449)

[3、Golang中逃逸现象, 变量“何时栈?何时堆?” · Golang修养之路 · 看云 (kancloud.cn)](https://www.kancloud.cn/aceld/golang/1958306)

[golang 逃逸分析详解 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/91559562)

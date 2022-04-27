---
title: "Go泛型的限制和对中间件的影响"
date: 2022-04-26T23:52:28+08:00
draft: false
slug: 33cd41f9
tags: ["Go","泛型"]
categories: ["Go"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [] 
pinned: false
weight: 100
---

本文是基于GoCN 2022年第八期泛型的讲座的笔记。

<!--more-->

## 泛型的简介

### 基本语法

支持接口、结构体、方法

```go
type Set[T any] interface {
	Put(key T) error
	Exist(key T) error
	Get(key T) (T, error)
}

type HashSet[T any]struct{
    val T
}

func Print[T any](t T){
    fmt.Printf("%v",t)
}
```

### 约束

约束是泛型里面新引入的语法元素。约束简单来说就是，类型参数所要满足的条件。 约束具体来说可以分成： 

#### 基本类型和内置类型

基本类型和内置 虽然也能作为约束，但是实际中可能并不常用。这样不具备任何意义

```go
func PrintBool[T bool](v T) {
	fmt.Printf("%v", v)
}

func PrintSlice[T []int](v T) {
	fmt.Printf("%v", v)
}

func PrintArray[T [3]int](v T) {
	fmt.Printf("%v", v)
}

func PrintMap[T map[string]int](v T) {
	fmt.Printf("%v", v)
}

func PrintChan[T chan int](v T) {
	val := <-v
	fmt.Printf("%v", val)
}
```

基本类型和内置虽然也能作为约束，但是实际中可能并不常用。 channel 这边类型推断看上去还 是不太智能的样子，还得自己手动转换

```go
func PrintChan[T chan int](v T) {
	val := <-v
	fmt.Printf("%v", val)
}

func PrintOnlyReadChan[T <-chan int](v T) {
	val := <-v
	fmt.Printf("%v", val)
}

func main() {
	ch := make(chan int, 2)
	ch <- 1
	ch <- 2
	PrintChan(ch)
	// han int does not implement <-chan int
	//PrintOnlyReadChan(ch)
    // 必须将chan手动转换为<-chan  go1.18
	var ch1 <-chan int
	ch1 = ch
	PrintOnlyReadChan(ch1)
}
```

#### 内置约束

any 和 comparable。前者代表任意的类型，后者代表的是可比较类型，也就是 Go 在没有泛型时候就有的可 

比较的概念。

例如在和 map 结合使用的时候，Key 必须满足 comparable 的约束。 严格来说，any 和 comparable 也只不过 是内置类型。

> comparable是golang新引入的预定义标识符，是一个接口，指代可以使用==或!=来进行比较的类型集合。
>
> comparable仅能用于泛型中的类型限定（type constraint）。
>
> 可直接作为类型限定使用，也可嵌入到类型限定中使用。

```go
type HashSet[T comparable, V any] map[T]V

func main() {
	set := HashSet[string, int]{}
	set["a"] = 1
}
```

#### 普通接口

这种方法应该是最常用的，如果限制HashMap必须实现Hashable的接口，就可以保证，这个结构体一定有这个方法，也就能确定他的HashCode一定是int

```go
type Hashable interface {
	HashCode() int
}

type HashMap[K Hashable, V comparable] struct {
}

func (h *HashMap[K, V]) HashCode() int {
	return 1
}

func main() {
	hash := HashMap[Hashable, int]{}
	hash.HashCode()
}
```

#### 普通结构体

普通的结构体用作泛型约束，将无法调用任何方法，任何字段。也就是说，当成整体来用是可以的，但是不能访问字段或者方法。

这里所报的错误，可以了解到go的泛型其实是以`鸭子类型`为设计理念，强调的是method不是字段。

```go
type User struct {
	Name string
	Age  int
}

func (u *User) GetAge() int {
	return u.Age
}

func PrintUser[T User](v T) {
	// ok
	fmt.Printf("%v", v)
	// v.GetAge undefined (type T has no field or method GetAge)
	//fmt.Printf("%v", v.GetAge())
    // v.Name undefined (type T has no field or method Name)
	//fmt.Printf("%v", v.Name
}

func main() {
	u := User{Name: "jimyag", Age: 20}
    PrintUser(u)
}
```

#### type X Y 定义的类型

如果Y是结构体，那么X就会受到结构体的约束。

如果Y是一个接口，那么X就是使用

```go
type Buyer User

func (b *Buyer) GetName() string {
	return b.Name
}

func PrintBuyer[T Buyer](v T) {
	// ok
	fmt.Printf("%v", v)
	// v.GetName undefined (type T has no field or method GetName)
	//fmt.Printf("%v", v.GetName())
}

func main() {
	b := Buyer{Name: "jimyag", Age: 20}
	PrintBuyer(b)
}
```

#### 约束接口

用符号 `|` 来组合类型，用符号 `~` 来表达 type X Y 这种形式的衍生类型。

如果是衍生类型，那么像`type Age int`也可以被用作`int`

```go
type Number interface {
   int | int64
}

type Number2 interface {
   ~int | ~int64
}

func NumberGet[n Number](v n) n {
   fmt.Printf("%v", v)
   return v
}
func NumberGet2[n Number2](v n) n {
   fmt.Printf("%v", v)
   return v
}

type Age int

func main() {
   foo := int(1)
   NumberGet(foo)
   NumberGet2(foo)
   foo2 := Age(1)
   // Age does not implement Number (possibly missing ~ for int in constraint Number)
   //NumberGet(foo2)
   NumberGet2(foo2)
}
```

## 限制

**无法限制必须组合某个结构体** 

结构体可以作为泛型参数，但是无法访问任何字段和方法。由此带来的就是我们在 Go 内无法做到类似于别的语言用泛型表达`类型必须继承某个抽象类`的效果。

换言之，我们无法限定类型必须要组合某个类型。

```go
type User struct {
	Name string
	Age  int
}

func (u *User) GetAge() int {
	return u.Age
}

func PrintUser[T User](v T) {
	// ok
	fmt.Printf("%v", v)
	// v.GetAge undefined (type T has no field or method GetAge)
	//fmt.Printf("%v", v.GetAge())
}

type Gopher struct {
	User
	Language string
}

func main() {
	g := Gopher{
		User:     User{Name: "gopher", Age: 1},
		Language: "",
	}
	// Gopher does not implement User
	// PrintUser(g)
}
```

业务开发受限更多，尤其是希望在公司推行一些规范的时候，无法利用泛型来加强 检测。例如要求所有的数据库实体都必须组合一个 BaseEntity，BaseEntity 里面 有公司在数据库表创建方面的各种强制字段。类似与上面的User一样，就不行。

### 约束类型只能用于泛型

约束类型无法被用作类型声明，只能用于泛型。 这导致我们无法表达：我只接收特定几种类型作为输入的语义。 假如说我现在想要实现一个求和的函数，能够将 int 类型和 float 类型进行相加。

```go
type Number interface {
	int | int64
}

type Number2 interface {
	~int | ~int64
}

func Sum[T Number](a ...T) T {
	var result T
	for _, v := range a {
		result += v
	}
	return result
}
func main() {
	res := Sum[int](1, 2, 3, 4, 5)
	fmt.Printf("%v", res)
}
```

Number是一个泛型约束类型，所以无法 被用作普通的类型，它只能出现在泛型里面。所以下边的写法是错误的。 同样的，也无法声明一个 Number 变量

```go
// 这是一个错误的声明
func Sum2[T Number](a ...Number) T {
	var result T
	for _, v := range a {
		result += v
	}
	return result
}
```

我们日常开发，或者说中间件开发的过程 中，经常会碰到某个接口只接收特定几种类型的情况，目前的做法都是将参数声明成 interface{} 并且结合 swich\-case 来处理，在最后肯定是在 default 里面 进行错误输入处理。 

这种样板代码将会长期存在。

```go
func Sum3(a ...interface{}) float64 {
   var result float64 = 0
   for _, v := range a {
      switch va := v.(type) {

      case float64:
         result += va

      case int:
         result += float64(va)

      default:
         panic("unsupported type")
      }
   }
   return result
}
```

### 结构体和接口无法声明泛型方法

接口或者结构体都可以是泛型的，但是它们不能声明泛型方法。**这是最强的限制，没有之一**。 它几乎断绝了所有的客户端类型的中间件利用泛型的道路。

```go
type Stream[T any] struct {
	values []T
}

// Filter 这个方法不是一个泛型方法，因为他没有泛型参数 虽然他的接收器是一个泛型
func (s *Stream[T]) Filter(func(t T) bool) *Stream[T] {
	return s
}

// Map syntax error: method must have no type parameters
func (s *Stream[T]) Map[E any](func(t T) E) *Stream[E] {
	return s
}
```

下面的写法也全部无法通过编译

```go
type Cache interface {
   Get[K any](key string) (K, error)
}

type Orm interface {
   Create[K any](k K) (K, error)
}

type Config interface {
   Get[K any](key string) (K, error)
}

type HttpClient interface {
   Get[K any](key string) (K, error)
}
```

> interface method must have no type parameters
> undefined: K

如果硬要使用泛型，就需要将泛型声明在类型定义上，而后在每次使用的时候都需要用具体类型来创建一

个实例。 

```go
type CacheV1[T any] interface {
	Get(key string) (T, error)
}

var intCache CacheV1[int]

var stringCache CacheV1[string]

type OrmV1[T any] interface {
	Create(t T) (T, error)
}

var userOrm OrmV1[User]
```

这种做法严重违背了单例设计原则。 

客户端类型的中间件和我们日常开发最贴近，但是因为泛型的这一个限制，不能太期望这一类的客户端中间件会带来大的变更。

### switch 无法操作类型参数

虽然在大多数场景下，使用了泛型参数，内部还要 switch 是一个很奇怪的用法。 但是偶尔还是可能需要这么一个语法特性。 

目前来说，Go 泛型支持不是很好。 switch 类型参数这个特性还处于 proposal 戒断

```go
func Get[T any](key string) (T, error) {
	var t T
	// cannot use type switch on type parameter value t (variable of type T constrained by any)
	switch t.(type) {

	// cannot use 10 (untyped int constant) as T value in assignment
	case int:
		t = 10
		return t, nil
	}
	return t, nil
}

func GetV1[T any](key string) (T, error) {
	// 无法将类型作为 switch 对象
	switch T {
	case int:
		return 10, nil
	}
	return T, nil
}
```

类似的需求还是只能通过指针来达成目标, 并且指针要赋值给一个 interface{} 类 型才能进一步进行 switch.

```go
func GetV2[T any](key string) (T, error) {
	var t T
	var tp interface{} = &t
	switch val := tp.(type) {
	case *int:
		*val = 10
		return t, nil
	}
	return t, nil
}
```

## 影响

### 数据结构与算法的类库

前述的这些限制对数据结构与算法的类库几乎没有影响。所以它们会迎来比较大的发展。 

数据结构：例如 Map，Set 等。目前来看默认的 map 的核心缺陷在于 key 必须是comparable 的，而在一些使用复杂结构体作为 key 的场景下，难以使用。以及 map 的变种，例如有序 map，追求高效率 的小 map。 又如树形结构

### 池

池一类的也可以迎来一定的改进。 

比如典型的 sync.Pool 可以考虑使用泛型进行封装。 也可以设计通用的资源池。这一类的资源 池可以满足： 

- 资源一定时间不被使用就会被释放 

- 控制住空闲资源的数量 

连接池、对象池可以看做是这种通用资源池的特例

```go
type Pool[T any] struct {
	pool sync.Pool
}

func NewPool[T any](factory func() T) *Pool[T] {
	return &Pool[T]{
		pool: sync.Pool{
			New: func() interface{} {
				return factory()
			},
		},
	}
}

func (p *Pool[T]) Get() T {
	return p.pool.Get().(T)
}
```

### 缓存模式会有显著改进

缓存模式可以说将迎来显著地，用户体验 上的改进。

 核心在于早期我们设计缓存模式接口，如 ~write\-through~, ~read\-through~ 的时候， 要么直接使用` interface{}`，用户则会陷 入类型断言中。 要么使用具体类型，或者复制粘贴代码， 或者使用代码生成策略。 

但是因为 `T any` 不能被看成是 `interface{}`，所以虽然代码看起来是装饰器，但是 `ReadThroughCache` 在 Go 里面并不被认为实现了 Cache 接口。至少在`goland`看来不是

```go
type Cache interface {
	Get(key string) (interface{}, error)
	Set(key string, value interface{}) error
}

type ReadThroughCache[T any] struct {
	cache    Cache
	readFunc func() (T, error)
}

func (c *ReadThroughCache[T]) Get(key string) (T, error) {
	var t T
	return t, nil
}

func (c *ReadThroughCache[T]) Set(key string, value T) error {
	return nil
}

var a Cache = &ReadThroughCache[interface{}]{}

func main() {
	a.Set("", "")
	a.Get("")
}
```

## 参考

[2022 开源说 第八期 泛型_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1Hr4y1q7Eo)

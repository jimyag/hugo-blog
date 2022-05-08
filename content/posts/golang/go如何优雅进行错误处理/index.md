---
title: "Go如何优雅进行错误处理"
date: 2022-05-08T10:15:35+08:00
draft: false
slug: 608465d8
tags: ["错误处理"]
categories: ["Go"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ ] 
pinned: false
weight: 100


---

介绍Go语言如何优雅的处理错误。

<!--more-->

# Error vs Exception

Go 的处理异常逻辑是不引入 `exception`，支持多参数返回，所以你很容易的在函数签名中带上实现了 `error interface` 的对象，交由调用者来判定。

如果一个函数返回了` (value, error)`，你不能对这个 value 做任何假设，必须先判定 error。唯一可以忽略 `error `的情况就是，如果你连 `value `也不关心。

Go 中有 `panic `的机制，如果你认为和其他语言的 `exception `一样，那你就错了。

当我们抛出异常的时候，相当于你把 exception 扔给了调用者来处理。比如，你在 C++ 中，把 string 转为 int，如果转换失败，会抛出异常。或者在 Java 中转换 String 为 Date 失败时，会抛出异常。

Go panic 意味着 fatal error（就是挂了）。不能假设调用者来解决 panic，意味着代码不能继续运行。使用多个返回值和一个简单的约定，Go 解决了让程序员知道什么时候出了问题，并为真正的异常情况保留了 panic。panic和recover不要一起使用，**自己panic了就不要recover了**，**但是第三方库的panic有时候需要recover**。

对于真正意外的情况，那些表示不可恢复的程序错误，例如索引越界、不可恢复的环境问题、栈溢出，我们才使用 panic。对于其他的错误情况，我们应该是期望使用 error 来进行判定。

You only need to check the error value if you care about the result.  -- Dave

This [blog](https://devblogs.microsoft.com/oldnewthing/?p=36693) post from Microsoft’s engineering blog in 2005 still holds true today, namely:

My point isn’t that exceptions are bad. My point is that exceptions are too hard and I’m not smart enough to handle them.

- 简单
- 考虑失败，而不是成功（plan for failure, not success）
- 没有隐藏的控制流
- 完全交给你来控制 error
- Error are values

# Sentinel Error

预定义的特定错误，我们叫为 `sentinel error`，这个名字来源于计算机编程中使用一个特定值来表示不可能进行进一步处理的做法。所以对于 Go，我们使用特定的值来表示错误。

```go
if err == ErrSomething { … }
```

类似的 `io.EOF`，或者更底层的 `syscall.ENOENT`。

使用 sentinel 值是最不灵活的错误处理策略，因为调用方必须使用 `==` 将结果与预先声明的值进行比较。当您想要提供更多的上下文时，这就出现了一个问题，**因为返回一个不同的错误将破坏相等性检查**。

甚至是一些有意义的 fmt.Errorf 携带一些上下文，也会破坏调用者的 `==` ，调用者将被迫查看 `error.Error()` 方法的输出，以查看它是否与特定的字符串匹配。
**所以要不依赖于检查 error.Error 的输出。**

-  不应该依赖检测 error.Error 的输出，**Error 方法存在于 error 接口主要用于方便程序员使用**，但不是程序（编写测试可能会依赖这个返回）。这个输出的字符串用于记录日志、输出到 stdout 等。
- Sentinel errors 成为你 API 公共部分。
  -  如果您的公共函数或方法返回一个特定值的错误，那么该值必须是公共的，当然要有文档记录，**这会增加 API 的表面积**。
  -  如果 API 定义了一个返回特定错误的 interface，则该接口的所有实现都将被限制为仅返回该错误，即使它们可以提供更具描述性的错误。比如 `io.Reader`。像 `io.Copy` 这类函数需要 `reader `的实现者返回 io.EOF 来告诉调用者没有更多数据了，但这又不是错误。
  
-  Sentinel errors 在两个包之间**创建了依赖**。
  -  sentinel errors 最糟糕的问题是它们在两个包之间创建了源代码依赖关系。**例如，检查错误是否等于 io.EOF，您的代码必须导入 io 包。**这个特定的例子听起来并不那么糟糕，因为它非常常见，但是想象一下，当项目中的许多包导出错误值时，存在耦合，项目中的其他包必须导入这些错误值才能检查特定的错误条件（**in the form of an import loop）**。

-  结论: 尽可能避免 sentinel errors。
      我的建议是避免在编写的代码中使用 sentinel errors。在标准库中有一些使用它们的情况，但这不是一个您应该模仿的模式。

# Error types

Error type 是实现了 error 接口的自定义类型。例如 MyError 类型记录了文件和行号以展示发生了什么。

```go
type MyError struct {
	Msg  string
	File string
	Line int
}

func (e *MyError) Error() string {
	return fmt.Sprintf("%s:%d: %s", e.File, e.Line, e.Msg)
}
func test() error {
	return &MyError{"test", "main.go", 10}
}
```

因为 MyError 是一个 type，调用者可以使用断言转换成这个类型，来获取更多的上下文信息。

```go
func main() {
	err := test()
	switch err.(type) {
	case nil:
		// do nothing
	case *MyError:
		fmt.Println(err.(*MyError).Msg)
	default:
		fmt.Println(err)
	}

```

与错误值相比，错误类型的一大改进是它们能够包装底层错误以提供更多上下文。
一个不错的例子就是 `os.PathError`  它提供了底层执行了什么操作、那个路径出了什么问题。

```go
// go1.18/src/io/fs/fs.go:242
// PathError records an error and the operation and file path that caused it.
type PathError struct {
	Op   string
	Path string
	Err  error
}

func (e *PathError) Error() string { return e.Op + " " + e.Path + ": " + e.Err.Error() }

func (e *PathError) Unwrap() error { return e.Err }

// Timeout reports whether this error represents a timeout.
func (e *PathError) Timeout() bool {
	t, ok := e.Err.(interface{ Timeout() bool })
	return ok && t.Timeout()
}
```

调用者要使用类型断言和类型 switch，就要让自定义的 error 变为 public。**这种模型会导致和调用者产生强耦合，从而导致 API 变得脆弱。**

结论是尽量避免使用 error types，虽然错误类型比 sentinel errors 更好，因为它们可以捕获关于出错的更多上下文，但是 error types 共享 error values 许多相同的问题。因此，我(啊别人的)的建议是避免错误类型，或者至少避免将它们作为公共 API 的一部分。

# Opaque errors

在我看来，这是最灵活的错误处理策略，因为它要求代码和调用者之间的耦合最少。因为虽然您知道发生了错误，但您没有能力看到错误的内部。作为调用者，关于操作的结果，您所知道的就是它起作用了，或者没有起作用（成功还是失败）。这就是不透明错误处理的全部功能–只需返回错误而不假设其内容。

```go
package main

import "github.com/quux/bar"

func fn()error {
	x,err:=bar.Foo()
	if err!=nil {
		return err
	}
	return nil
}

func main() {
	fn()
}
```

Assert errors for behaviour, not type

在少数情况下，这种二分错误处理方法是不够的。例如，与进程外的世界进行交互（如网络活动），需要调用方调查错误的性质，以确定重试该操作是否合理。在这种情况下，我们可以断言错误实现了特定的行为，而不是断言错误是特定的类型或值。考虑这个例子：

```go
type temporary interface {
	Temporary() bool
}

func IsTemporary(err error) bool {
	if temp, ok := err.(temporary); ok {
		return ok && temp.Temporary()
	}
	return false
}
```

这里的关键是，这个逻辑可以在不导入定义错误的包或者实际上不了解 err 的底层类型的情况下实现——我们只对它的行为感兴趣。

# Handling Error

## Indented flow is for errors

无错误的正常流程代码，将成为一条直线，而不是缩进的代码。

```go
f,err:=os.Open(path)
if err!=nil{
    // 处理错误
}
// 逻辑


f,err:=os.Open(path)
if err==nil{
	// 逻辑    
}
// 处理错误
```

## Eliminate error handling by eliminating errors

下面的代码有啥问题？

```go
func AuthRequest(r *Request)error{
    err:=auth(r.User)
    if err!=nil{
        return err
    }
    return nil
}

func AuthRequest(r *Request)error{
    return auth(r.User)
}
```

统计 `io.Reader` 读取内容的行数,处理了两次错误

```go
func CountLines(r io.Reader) (int, error) {
	var (
		br    = bufio.NewReader(r)
		lines int
		err   error
	)
	for {
		_, err = br.ReadString('\n')
		lines++
		if err != nil {
			break
		}
	}
	if err != io.EOF {
		return 0, err
	}
	return lines, nil
}
```

改进版，只需要接受最终有无错误就行

```go
func CountLines(r io.Reader)(int,error){
    sc:=bufio.NewScanner(r)
    lines:=0
    for sc.Scan(){
        lines++
    }
    return lines,sc.Err()
}
```

例如下面的例子，总共要处理`4`次错误

```go
type Header struct {
	Key, Value string
}

type Status struct {
	Code   int
	Reason string
}

func WriteResponse(w *io.Writer, status Status, headers []Header, body io.Reader) error {
	_, err := fmt.Fprint(*w, "HTTP/1.1", status.Code, status.Reason)
	if err != nil {
		return err
	}
	for _, h := range headers {
		_, err := fmt.Fprint(*w, "\n", h.Key, ":", h.Value)
		if err != nil {
			return err
		}
	}
	_, err = fmt.Fprint(*w, "\n\n")
	if err != nil {
		return err
	}
	_, err = io.Copy(*w, body)
	return err
}
```

经过改进，将错误处理统一集中到`Write`中。并最终返回，看起来好像没有处理错误一样。

```go
type errWrite struct {
	io.Writer
	err error
}

func (e *errWrite) Write(p []byte) (n int, err error) {
	if e.err != nil {
		return 0, e.err
	}
	n, e.err = e.Writer.Write(p)
	return n, e.err
}

func WriteResponse(w *io.Writer, status Status, headers []Header, body io.Reader) error {
	ew := &errWrite{Writer: *w}
	fmt.Fprint(ew, "HTTP/1.1", status.Code, status.Reason)

	for _, h := range headers {
		fmt.Fprint(ew, "\r\n", h.Key, ":", h.Value)
	}
	fmt.Fprint(ew, "\r\n\r\n")
	io.Copy(ew, body)

	return ew.err
}
```

# Wrap erros

如果 authenticate 返回错误，则 AuthenticateRequest 会将错误返回给调用方，调用者可能也会这样做，依此类推。在程序的顶部，程序的主体将把错误打印到屏幕或日志文件中，打印出来的只是：没有这样的文件或目录？？？？？到底是那个文件或者目录没有。

```go
func AuthRequest(r *Request)error{
    return auth(r.User)
}
```

没有生成错误的 file:line 信息。没有导致错误的调用堆栈的堆栈跟踪。这段代码的作者将被迫进行长时间的代码分割，以发现是哪个代码路径触发了文件未找到错误。

```go
func AuthRequest(r *Request)error{
    err:=auth(r.User)
    if err!=nil{
        return fmt.Errorf("auth failed: %v",err)
    }
    return nil
}
```

但是正如我们前面看到的，这种模式与 sentinel errors 或 type assertions 的使用不兼容，因为将错误值转换为字符串，将其与另一个字符串合并，然后将其转换回 fmt.Errorf  破坏了原始错误，导致等值判定失败。

You should only handle errors once. Handling an error means inspecting the error value, and making a single decision.

我们经常发现类似的代码，在错误处理中，带了两个任务: 记录日志并且再次返回错误。这个还是看要求，打印之后返回也可以。

```go
func WriteAll(w io.Writer, b []byte) (err error) {
	_, err = w.Write(b)
	if err != nil {
		log.Println("unable WriteAll:", err)
		return err
	}
	return nil
}
```

在这个例子中，如果在 w.Write 过程中发生了一个错误，那么一行代码将被写入日志文件中，记录错误发生的文件和行，并且错误也会返回给调用者，调用者可能会记录并返回它，一直返回到程序的顶部。

```go
func WriteConfig(w io.Writer, config *Config) (err error) {
	buf, err := json.Marshal(config)
	if err != nil {
		log.Println("unable Marshal:", err)
		return err
	}
	if err := WriteAll(w, buf); err != nil {
		log.Println("unable WriteAll:", err)
		return err
	}
	return nil
}

func main() {
	err := WriteConfig(os.Stdout, &config)
	fmt.Println(err) // io.EOF
}

```

Go 中的错误处理契约规定，在出现错误的情况下，不能对其他返回值的内容做出任何假设。由于 JSON 序列化失败，buf  的内容是未知的，可能它不包含任何内容，但更糟糕的是，它可能包含一个半写的 JSON 片段。
由于程序员在检查并记录错误后忘记 return，损坏的缓冲区将被传递给 WriteAll，这可能会成功，因此配置文件将被错误地写入。但是，该函数返回的结果是正确的。

```go
func WriteConfig(w io.Writer, config *Config) (err error) {
	buf, err := json.Marshal(config)
	if err != nil {
		log.Println("unable Marshal:", err)
		// oops, forgot to return err
	}
	if err := WriteAll(w, buf); err != nil {
		log.Println("unable WriteAll:", err)
		return err
	}
	return nil
}
```

日志记录与错误无关且对调试没有帮助的信息应被视为噪音，应予以质疑。记录的原因是因为某些东西失败了，而日志包含了答案。

- The error has been logged.
- The application is back to 100% integrity.
- The current error is not reported any longer.
- 错误要被日志记录。
- 应用程序处理错误，保证100%完整性。
- 之后不再报告当前错误。

## pkg/errors

使用第三方的包处理错误

```go
package main

import (
	"fmt"
	"os"

	"github.com/pkg/errors"
)

func ReadFile(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, errors.Wrap(err, "open file failed")
	}
	defer f.Close()
	// ...
	return nil, nil
}

func main() {
	_, err := ReadFile("/tmp/file")
	if err != nil {
		fmt.Printf("original error: %T %v\n\n", errors.Cause(err), errors.Cause(err))
		fmt.Printf("stack trace: \n%+v\n", err)
		os.Exit(1)
	}
}
```

打印有堆栈信息，以及其他的详细的信息

```powershell
original error: *fs.PathError open /tmp/file: The system cannot find the path specified.


stack trace: 
open /tmp/file: The system cannot find the path specified.
open file failed
main.ReadFile
        D:/code/go/test/cto/001-error/main.go:13
main.main
        D:/code/go/test/cto/001-error/main.go:21
runtime.main
        C:/Users/jimyag/sdk/go1.18/src/runtime/proc.go:250
runtime.goexit
        C:/Users/jimyag/sdk/go1.18/src/runtime/asm_amd64.s:1571


```

区别`WithMessage`和`Warp`。前者是在原有的错误基础上添加一条错误消息，后者是通过当前的错误信息和堆栈信息组成一个新的错误。

```go
package main

import (
	"fmt"
	"os"

	"github.com/pkg/errors"
)

func ReadFile(path string) ([]byte, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, errors.Wrap(err, "open file failed")
	}
	defer f.Close()
	// ...
	return nil, nil
}

func ReadConfig(path string) ([]byte, error) {
	data, err := ReadFile(path)
	if err != nil {
		return nil, errors.WithMessage(err, "read file failed")
	}
	return data, nil
}

func main() {
	_, err := ReadConfig("/tmp/file")
	if err != nil {
		fmt.Printf("%+v\n", err)
		os.Exit(1)
	}
}
```

结果

```powershell
C:\Users\jimyag\AppData\Local\Temp\GoLand\___go_build_test_cto_001_error.exe
open /tmp/file: The system cannot find the path specified.
open file failed
main.ReadFile
        D:/code/go/test/cto/001-error/main.go:13
main.ReadConfig
        D:/code/go/test/cto/001-error/main.go:21
main.main
        D:/code/go/test/cto/001-error/main.go:29
runtime.main
        C:/Users/jimyag/sdk/go1.18/src/runtime/proc.go:250
runtime.goexit
        C:/Users/jimyag/sdk/go1.18/src/runtime/asm_amd64.s:1571
read file failed

```



在你的应用代码中，使用 errors.New 或者  errros.Errorf 返回错误。

如果调用其他包内的函数，通常简单的直接返回。

```go
func parseArgs(args []string) error {
	if len(args) != 2 {
		return errors.Errorf("two arguments required")
	}
	return nil
}

func fo() error {
	err := parseArgs([]string{"one", "two"})
	if err != nil {
		return err
	}
	return nil
}
```

如果和其他库进行协作，考虑使用 errors.Wrap 或者 errors.Wrapf 保存堆栈信息。同样适用于和标准库协作的时候。

```go
f,err:=os.Open(path)
if err!=nil{
    return errors.Warpf(err,"failed to open %q",path)
}
```

直接返回错误，而不是每个错误产生的地方到处打日志。

在程序的顶部或者是工作的 goroutine 顶部（请求入口），使用 %+v  把堆栈详情记录。

```go
func main(){
    err:=app.Run()
    if err!=nil{
        fmt.Printf("FATAL:%+v\n",err)
        os.Exit(1)
    }
}
```

使用 `errors.Cause` 获取 root error，再进行和 sentinel error 判定。

总结:

- Packages that are reusable across many projects only return root error values.

  选择 wrap error 是只有 applications 可以选择应用的策略。具有最高可重用性的包只能返回根错误值。此机制与 Go 标准库中使用的相同（kit 库的 sql.ErrNoRows）。

- If the error is not going to be handled, wrap and return up the call stack.

  这是关于函数/方法调用返回的每个错误的基本问题。如果函数/方法不打算处理错误，那么用足够的上下文 wrap errors 并将其返回到调用堆栈中。例如，额外的上下文可以是使用的输入参数或失败的查询语句。确定您记录的上下文是足够多还是太多的一个好方法是检查日志并验证它们在开发期间是否为您工作。

- Once an error is handled, it is not allowed to be passed up the call stack any longer.

  一旦确定函数/方法将处理错误，错误就不再是错误。如果函数/方法仍然需要发出返回，则它不能返回错误值。它应该只返回零（比如降级处理中，你返回了降级数据，然后需要 return nil）。

# 1.13新特性

go1.13为 errors 和 fmt 标准库包引入了新特性，以简化处理包含其他错误的错误。其中最重要的是: 包含另一个错误的 error 可以实现返回底层错误的 Unwrap 方法。如果 e1.Unwrap() 返回 e2，那么我们说 e1 包装 e2，您可以展开 e1 以获得 e2。
按照此约定，我们可以为的 QueryError 类型指定一个 Unwrap 方法，该方法返回其包含的错误。

```go
func (e *QueryError)Unwarp()error{
    return e.Err
}
```

go1.13 errors 包包含两个用于检查错误的新函数：Is 和 As。

```go
// if err == ErrNotFound
if errors.Is(err,ErrorNotFound){
    //
}

// if e,ok:=err.(*QueryError);ok{ ...}
var e *QueryError
if errors.As(err,&e){
    //
}
```

如前所述，使用 fmt.Errorf 向错误添加附加信息

```go
if err!=nil{
    return fmt.Errorf("decompress %v: %v",name,err)
}
```

在 Go 1.13中 fmt.Errorf 支持新的 %w 谓词。

```go
if err!=nil{
    return fmt.Errorf("decompress %v: %w",name,err)
}
```

用 %w 包装错误可用于 errors.Is 以及 errors.As:

```go
err:=fmt.Errorf("access denied  %w",ErrPermisson)
...
if errors.Is(err,ErrPermisson){
    
}
...
```

# 总结

对于错误处理用`pkg/errors`好一点，它也兼容了`1.13`的`Is`和`As`。

对于一个底层库的开发不要使用`pkg/errors`,要生成对应的根错误来进行排查。

# 版权

以上内容根据极客时间的0.99元的错误处理课程总结而来。本文仅供学习和交流使用，如有不当之处，请联系我删除。


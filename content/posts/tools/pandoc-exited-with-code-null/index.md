---
title: pandoc exited with code null
tags:
  - NexT
categories:
  - NexT
  - Hexo
slug: /80ae3d28
date: 2022-02-12 00:18:31
---

你是否也遇到了这个问题 `pandoc exited with code null.`
昨天还可以生成，今天就完了。

<!--more-->

```shell
jimyag@MacBook-Pro jimyag-blog % hexo serve
INFO Validating config
INFO ==================================
 ███╗  ██╗███████╗██╗ ██╗████████╗
 ████╗ ██║██╔════╝╚██╗██╔╝╚══██╔══╝
 ██╔██╗ ██║█████╗  ╚███╔╝  ██║
 ██║╚██╗██║██╔══╝  ██╔██╗  ██║
 ██║ ╚████║███████╗██╔╝ ██╗  ██║
 ╚═╝ ╚═══╝╚══════╝╚═╝ ╚═╝  ╚═╝
========================================
NexT version 8.8.2
Documentation: https://theme-next.js.org
========================================
INFO Start processing
ERROR {
 err: Error: 
 [ERROR][hexo-renderer-pandoc] On /Users/jimyag/repo/jimyag-blog/themes/next/languages/README.md
 [ERROR][hexo-renderer-pandoc] pandoc exited with code null.
   at Hexo.pandocRenderer (/Users/jimyag/repo/jimyag-blog/node_modules/hexo-renderer-pandoc/index.js:114:11)
   at Hexo.tryCatcher (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/util.js:16:23)
   at Hexo.<anonymous> (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/method.js:15:34)
   at /Users/jimyag/repo/jimyag-blog/node_modules/hexo/lib/hexo/render.js:75:22
   at tryCatcher (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/util.js:16:23)
   at Promise._settlePromiseFromHandler (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:547:31)
   at Promise._settlePromise (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:604:18)
   at Promise._settlePromise0 (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:649:10)
   at Promise._settlePromises (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:729:18)
   at _drainQueueStep (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:93:12)
   at _drainQueue (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:86:9)
   at Async._drainQueues (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:102:5)
   at Immediate.Async.drainQueues [as _onImmediate] (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:15:14)
   at processImmediate (node:internal/timers:466:21)
} Process failed: %s languages/README.md
FATAL {
 err: Error: 
 [ERROR][hexo-renderer-pandoc] On /Users/jimyag/repo/jimyag-blog/source/_posts/TCP-IP协议三次握手、四次挥手.md
 [ERROR][hexo-renderer-pandoc] pandoc exited with code null.
   at Hexo.pandocRenderer (/Users/jimyag/repo/jimyag-blog/node_modules/hexo-renderer-pandoc/index.js:114:11)
   at Hexo.tryCatcher (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/util.js:16:23)
   at Hexo.<anonymous> (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/method.js:15:34
   at /Users/jimyag/repo/jimyag-blog/node_modules/hexo/lib/hexo/render.js:75:22
   at tryCatcher (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/util.js:16:23)
   at Promise._settlePromiseFromHandler (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:547:31)
   at Promise._settlePromise (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:604:18)
   at Promise._settlePromiseCtx (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/promise.js:641:10)
   at _drainQueueStep (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:97:12)
   at _drainQueue (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:86:9)
   at Async._drainQueues (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:102:5)
   at Immediate.Async.drainQueues [as _onImmediate] (/Users/jimyag/repo/jimyag-blog/node_modules/bluebird/js/release/async.js:15:14)
   at processImmediate (node:internal/timers:466:21)
} Something's wrong. Maybe you can find the solution here: %s https://hexo.io/docs/troubleshooting.html
```

这是hexo-renderer-pandoc包的问题。把它删掉就解决了

```shell
npm remove --save hexo-renderer-pandoc
```

命令删不了的话，直接在文件夹里删，在 `node_modules` 里找到 `hexo-renderer-pandoc` 删掉。

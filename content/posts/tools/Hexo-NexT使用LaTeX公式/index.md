---
title: Hexo-NexT使用LaTeX公式
tags:
  - Web
  - 教程
categories:
  - Web
slug: ../37cab689
date: 2021-08-03 12:55:25
---

在使用next主题的过程中，碰到写的markdown中有LaTeX公式不显示的问题，遂查找资料解决。

<!--more-->

1. 更换Hexo默认渲染引擎

   Hexo默认的渲染引擎是 marked，但是 marked 不支持 MathJax。所以需要更换Hexo的markdown渲染引擎为hexo-renderer-kramed引擎，后者支持MathJax公式输出。

   ```shell
   npm uninstall hexo-renderer-marked --save
   npm install hexo-renderer-kramed --save
   ```

2. 激活MathJax

   在`/blog/themes/next/config.yml`中找到`# MathJax Support`修改为

   ```txt
   mathjax:
     enable: true
     per_page: true
   ```

3. 修改kramed语法解释

   在`/blog/node_modules/kramed/lib/rules/inline.js `将

   ```shell
     escape: /^\\([\\`*{}\[\]()#$+\-.!_>])/,
     autolink: /^<([^ >]+(@|:\/)[^ >]+)>/,
     url: noop,
     html: /^<!--[\s\S]*?-->|^<(\w+(?!:\/|[^\w\s@]*@)\b)*?(?:"[^"]*"|'[^']*'|[^'">])*?>([\s\S]*?)?<\/\1>|^<(\w+(?!:\/|[^\w\s@]*@)\b)(?:"[^"]*"|'[^']*'|[^'">])*?>/,
     link: /^!?\[(inside)\]\(href\)/,
     reflink: /^!?\[(inside)\]\s*\[([^\]]*)\]/,
     nolink: /^!?\[((?:\[[^\]]*\]|[^\[\]])*)\]/,
     reffn: /^!?\[\^(inside)\]/,
     strong: /^__([\s\S]+?)__(?!_)|^\*\*([\s\S]+?)\*\*(?!\*)/,
     em: /^\b_((?:__|[\s\S])+?)_\b|^\*((?:\*\*|[\s\S])+?)\*(?!\*)/,
     code: /^(`+)\s*([\s\S]*?[^`])\s*\1(?!`)/,
     br: /^ {2,}\n(?!\s*$)/,
     del: noop,
     text: /^[\s\S]+?(?=[\\<!\[_*`$]| {2,}\n|$)/,
     math: /^\$\$\s*([\s\S]*?[^\$])\s*\$\$(?!\$)/,
   ```

   替换为

   ```shell
     escape: /^\\([`*\[\]()#$+\-.!_>])/,
     autolink: /^<([^ >]+(@|:\/)[^ >]+)>/,
     url: noop,
     html: /^<!--[\s\S]*?-->|^<(\w+(?!:\/|[^\w\s@]*@)\b)*?(?:"[^"]*"|'[^']*'|[^'">])*?>([\s\S]*?)?<\/\1>|^<(\w+(?!:\/|[^\w\s@]*@)\b)(?:"[^"]*"|'[^']*'|[^'">])*?>/,
     link: /^!?\[(inside)\]\(href\)/,
     reflink: /^!?\[(inside)\]\s*\[([^\]]*)\]/,
     nolink: /^!?\[((?:\[[^\]]*\]|[^\[\]])*)\]/,
     reffn: /^!?\[\^(inside)\]/,
     strong: /^__([\s\S]+?)__(?!_)|^\*\*([\s\S]+?)\*\*(?!\*)/,
     em: /^\*((?:\*\*|[\s\S])+?)\*(?!\*)/,
   ```

4. 在markdown开头添加语句

   ```shell
   mathjax: true
   ```

5. 测试

   $$1 = \frac{2}{2}$$

> [在HEXO博客中使用LaTeX公式的简单方法_Loy Fan-CSDN博客](https://blog.csdn.net/weixin_43318626/article/details/89407031)


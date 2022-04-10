---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
slug: {{ substr (md5 (printf "%s%s" .Date (replace .TranslationBaseName "-" " " | title))) 4 8 }}
tags: ["标签1","标签2"]
categories: ["分类1"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ "专栏" ] 
pinned: false
weight: 100
---

描述

<!--more-->

正文

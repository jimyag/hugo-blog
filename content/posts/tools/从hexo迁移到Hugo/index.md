---
title: "从hexo迁移到Hugo"
date: 2022-04-11T11:47:04+08:00
draft: false
slug: /642ecc47
tags: ["Hexo","Hugo","教程"]
categories: ["Hexo","Hugo","教程"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [] 
pinned: false
weight: 100
---



由于之前Hexo的NexT主题加载实在太慢，关闭加载动画之后还是很慢。索性换一个新的博客框架。

<!--more-->

## 安装Hugo

到 [Hugo Releases](https://github.com/spf13/hugo/releases) 下载适合你的操作系统的版本。

把 `hugo` （或者是 Windows 的 `hugo.exe`） 放到你的 环境变量 `PATH` 所在的目录，因为下一步我们将会用到它。

更加完整的安装指南请参考： [Installing Hugo](https://www.gohugo.org/doc/overview/installing/)。

## 配置主题

```shell 
hugo new site hugo-blog
cd hugo-blog
git init
git submodule add https://github.com/razonyang/hugo-theme-bootstrap themes/hugo-theme-bootstrap
cp -a themes/hugo-theme-bootstrap/exampleSite/* .
hugo mod npm pack
npm install
hugo server
```

### 配置作者信息

```toml {title="hugo-blog\config\_default\author.toml"}
name = "jimyag"
avatar = "images/spider-man.jpg" # static/images/spider-man.jpg
bio = "Gopher"
location = "Shanghai"

[params]
  #layout = "compact"

[social]
  email = "jimyag@126.com"
  github = "jimyag"
```

### 配置全站信息

这里也顺便配置`备案信息`

```toml {title="hugo-blog\config\_default\config.toml"}
baseURL = "https://jimyag.cn"
title = "步履不停"
theme = "hugo-theme-bootstrap" # install via git submodule
copyright = "Copyright © 2019-{year} jimyag. All Rights Reserved. 陕ICP备2020018182号-1" # 备案信息

# Multilingual mode
defaultContentLanguage = "zh-cn"
defaultContentLanguageInSubdir = false # If you use only one language comment this option

# Pagination
paginate = 10

enableRobotsTXT = true

enableEmoji = true

pygmentsUseClasses = true

[blackfriday]
  hrefTargetBlank = true

[mediaTypes]
  [mediaTypes."application/manifest+json"]
    suffixes = ["json"]
  
[outputFormats]
  [outputFormats.MANIFEST]
    name = "manifest"
    baseName = "manifest"
    mediaType = "application/manifest+json"

[outputs]
  home = ["HTML", "RSS", "JSON", "MANIFEST"]

[taxonomies]
  category = "categories"
  series = "series"
  tag = "tags"

[build]
  writeStats = true
```

## 配置友情连接

自定义一个`友情链接`的菜单，

| 属性             | 类型    | 描述                       |
| :--------------- | :------ | :------------------------- |
| `name`           | String  | 菜单名称。                 |
| `identifier`     | String  | 菜单 ID。                  |
| `weight`         | Number  | 菜单的权重，用于升序排序。 |
| `parent`         | String  | 上级菜单的 `identifier`。  |
| `url`            | String  | 菜单的 URL。               |
| `pre`            | String  | 菜单名称的前置字符串。     |
| `post`           | String  | 菜单名称的拖尾字符串。     |
| `params`         | Object  | 菜单参数。                 |
| `params.divider` | Boolean | `true` 表示分隔符。        |

```toml {title="hugo-blog\config\_default\menu.toml"}
[[main]]
  name = "友情链接"
  identifier = "friends"
  weight = 40
  pre = '<i class="fas fa-fw fa-chevron-circle-down"></i>'
[[main]]
  name = "xieash"
  identifier = "xieash"
  parent = "friends"
  url = "https://xieash.work/"
  weight = 1
[[main]]
  name = "sunnysab"
  identifier = "sunnysab"
  parent = "friends"
  url = "https://sunnysab.cn/"
  weight = 2
[[main]]
  name = "wanfengcxz"
  identifier = "wanfengcxz"
  parent = "friends"
  url = "https://wanfengcxz.cn/"
  weight = 3
[[main]]
  name = "zhangzqs"
  identifier = "zhangzqs"
  parent = "friends"
  url = "https://zhangzqs.cn/"
  weight = 4
```

## 配置社交连接

```toml {title="hugo-blog\config\_default\social.toml"}
email = "jimyag@126.com"
# facebook = "yourfacebookusername"
github = "jimyag"
```

## 迁移hexo的博客内容

hexo的永久连接的字段是`addlink`,但是hugo是不支持这个字段的。

大佬的永久链接生成方案是**直接对时间 + 文章名生成字符串做一下 md5 然后取任意 4-12 位**。想了一下，这样的 hash 冲撞概率还是挺小的，我觉得可以！

那么接下来说说怎么把这个方案应用到 Hugo 中

Hugo 在永久链接中支持一个参数：`slug`。简单来说，我们可以针对每一篇文章指定一个 `slug`，然后在 `config.toml` 中配置`permalinks`包含`slug`参数，就可以生成唯一的永久链接。我们的目的就是对**每篇文章自动生成一个 slug**。

修改`archetypes/default.md`添加如下一行：

```markdown 
---
#...
slug: {{ substr (md5 (printf "%s%s" .Date (replace .TranslationBaseName "-" " " | title))) 4 8 }}
#...
---
```

这个其实就是`hugo`的博客的模板，可以在里面添加自己预设的内容。

这样在每次使用`hugo new`的时候就会自动填写一个永久链接了。

之后修改`config.toml`添加如下行：

```toml {title="hugo-blog\config\production\config.toml"}
[permalinks]
  posts = "/post/:slug"
```

## 支持letex公式

Hugo原生是不支持数学公式的这时候需要手动引入数学公式的库，

在`/themes/theme-name/layouts/partials`中添加`mathjax.html`文件，

```html
<script type="text/javascript"
        async
        src="https://cdn.bootcss.com/mathjax/2.7.3/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
MathJax.Hub.Config({
  tex2jax: {
    inlineMath: [['$','$'], ['\\(','\\)']],
    displayMath: [['$$','$$'], ['\[\[','\]\]']],
    processEscapes: true,
    processEnvironments: true,
    skipTags: ['script', 'noscript', 'style', 'textarea', 'pre'],
    TeX: { equationNumbers: { autoNumber: "AMS" },
         extensions: ["AMSmath.js", "AMSsymbols.js"] }
  }
});

MathJax.Hub.Queue(function() {
    // Fix <code> tags after MathJax finishes running. This is a
    // hack to overcome a shortcoming of Markdown. Discussion at
    // https://github.com/mojombo/jekyll/issues/199
    var all = MathJax.Hub.getAllJax(), i;
    for(i = 0; i < all.length; i += 1) {
        all[i].SourceElement().parentNode.className += ' has-jax';
    }
});
</script>

<style>
code.has-jax {
    font: inherit;
    font-size: 100%;
    background: inherit;
    border: inherit;
    color: #515151;
}
</style>
```

然后在`head.html`中加入如下语句

```html
{{ partial "mathjax.html" . }}
```

重新安装依赖

```shell
hugo mod npm pack
npm install
hugo server
```

## 部署博客

### Github Actions

起初想通过`GitHub actions`进行部署，使用`rsync`进行同步下面是`action`的配置文件

```yaml
name: deploy

on:
  # push事件
  push:
    # 忽略某些文件和目录，自行定义
    paths-ignore:
      - '.gitignore'
      - '.gitmodules'
      - 'README.md'
    branches: [ master ]

  # pull_request事件
  pull_request:
    # 忽略某些文件和目录，自行定义
    paths-ignore:
      - '.gitignore'
      - '.gitmodules'
      - 'README.md'
    branches: [ master ]

  # 支持手动运行
  workflow_dispatch:

jobs:
  # job名称为deploy
  deploy:
    # 使用GitHub提供的runner
    runs-on: ubuntu-20.04

    steps:
      # 检出代码，包括submodules，保证主题文件正常
      - name: Checkout source
        uses: actions/checkout@v2
        with:
          ref: master
          submodules: true  # Fetch Hugo themes (true OR recursive)
          fetch-depth: 0    # Fetch all history for .GitInfo and .Lastmod

      # 准备 mode
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: 14

      # 准备Hugo环境
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          # extended: true

      # Hugo构建静态站点，默认输出到public目录下
      - name: Build1
        run: hugo mod npm pack



      - name: Build2
        run: npm install

      - name: Build3
        run:
          hugo -D
      # 将public目录下的所有内容同步到远程服务器的nginx站点路径，注意path参数的写法，'public'和'public/'是不同的
      - name: Deploy
        uses: burnett01/rsync-deployments@5.1
        with:
          switches: -avzr --delete
          path: ./public/
          remote_host: ${{ secrets.REMOTE_HOST }}
          remote_port: ${{ secrets.REMOTE_PORT }}
          remote_path: ${{ secrets.REMOTE_PATH }}
          remote_user: ${{ secrets.REMOTE_USER }}
          remote_key: ${{ secrets.REMOTE_KEY }}
```

其中的`secrets.REMOTE_HOST`等五个参数需要在`setting/secrets/actions`中添加，可以自行添加。这有一个好处就是它是增量更新的，只有在第一次同步的时候是全部更新，之后只更新改变的或增加的。坏处就是`腾讯云`一直提醒`服务器在国外被登录`,每一个同步都要发邮件提醒，很烦。

### SCP

`scp`命令使用很简单

```shell
scp -r 本地文件路径 username@ip:/远程文件路径
```

例如

```shell
scp -r public/* username@ip:/public/jimyag.cn/
```

将当前文件中的`public`目录中所有的文件拷到远程主机的`/public/jimyag.cn/`文件夹中。

## 配置https

以下均在服务器中执行。

安装nginx

```shell
yum install nginx -y
```

启动nginx

```shell
systemctl start nginx
```

设置开机自启

```shell
systemctl enable nginx
```

修改默认配置文件，注释掉所有的



```conf {title="/etc/nginx/nginx.conf"
user root; #修改用户
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
    # 删除多余的内容
}
```

在`/etc/nginx/conf.d`中新建文件`jimyag_cn_http2https.conf`,将所有的http请求rewrite到https

```conf
server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  jimyag.cn;
        rewrite ^(.*) https://$server_name$1 permanent;
}
```

在`/etc/nginx/conf.d`中新建文件`jimyag_cn.conf`,监听443端口

```conf
server {
        listen       443 ssl http2;
        listen       [::]:443 ssl http2;
        server_name  jimyag.cn;


        ssl_certificate /etc/ssl/certs/jimyag_cn/jimyag.cn_bundle.crt; # 证书所在文件
        ssl_certificate_key /etc/ssl/certs/jimyag_cn/jimyag.cn.key; # 证书所在文件
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        location /{
                root /public/jimyag.cn/;  #博客文件所在
                index index.html;
        }
}
```

证书需要在云服务器商中申请，申请成功后下载`nginx`版本就可以了，将其中的`.crt`和`.key`文件拷到`证书所在位置即可`。

## 参考

[快速入门 - Hugo Bootstrap (razonyang.com)](https://hbs.razonyang.com/zh-cn/docs/getting-started/)

[Hexo 迁移到 Hugo 记录 - Reborn's Blog (mallotec.com)](https://reb.mallotec.com/post/0e6db571/)

[HUGO迁移 :: shaosy's blog (siyangshao.github.io)](https://siyangshao.github.io/posts/extra/hugo迁移/)

---
layout: home
title: HotelByte Blog
lang: zh
---

<div class="hero">
  <h1>构建酒店分销的未来</h1>
  <p>酒店API聚合、Go微服务、构建可扩展旅游技术平台的技术文章</p>
</div>

<div class="language-notice">
  <p>阅读中文版 | <a href="/en/">切换到英文版</a></p>
</div>

## 最新文章

<div class="posts">
  {% assign zh_posts = site.posts | where: "lang", "zh" %}
  {% for post in zh_posts limit:5 %}
    <div class="post">
      <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
      <p class="meta">{{ post.date | date: "%Y年%-m月%-d日" }} · {{ post.content | strip_html | truncatewords: 30 }}</p>
      <p class="categories">
        {% for category in post.categories %}
          <span class="category">{{ category }}</span>
        {% endfor %}
      </p>
    </div>
  {% endfor %}
</div>

## 分类

<ul class="categories">
  {% for category in site.categories %}
    <li><a href="/categories/{{ category[0] }}">{{ category[0] }}</a> ({{ category[1].size }})</li>
  {% endfor %}
</ul>

## 关于 HotelByte

HotelByte 是新一代酒店分销平台，帮助旅游公司无缝连接供应商。我们构建技术，抽象掉酒店API集成的复杂性，让您专注于构建优秀的产品。

- **官方API**: [openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- **GitHub**: [github.com/hotelbyte-com](https://github.com/hotelbyte-com)
- **加入候补名单**: [waitlist.hotelbyte.com](https://waitlist.hotelbyte.com)

<script>
// 自动检测浏览器语言并跳转（仅当用户未手动选择时）
document.addEventListener('DOMContentLoaded', function() {
  // 优先级：用户手动选择 > 浏览器语言 > 默认语言
  const userSelectedLang = sessionStorage.getItem('user-lang-preference');
  
  // 如果用户已经手动选择过语言，不再自动跳转
  if (userSelectedLang) {
    return; // 用户主动选择的优先级最高
  }
  
  // 获取浏览器语言
  const browserLang = navigator.language || navigator.userLanguage;
  const currentPath = window.location.pathname;
  
  // 如果浏览器语言是英文，并且当前在中文首页
  if (browserLang.startsWith('en') && currentPath === '/') {
    // 延迟跳转，避免闪烁
    setTimeout(function() {
      // 在跳转前存储浏览器语言（作为首次访问的默认值）
      sessionStorage.setItem('user-lang-preference', 'en');
      window.location.href = '/en/';
    }, 100);
  }
});
</script>

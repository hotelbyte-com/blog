---
layout: home
title: HotelByte Blog
---

<div class="hero">
  <h1>Building the Future of Hotel Distribution</h1>
  <p>Technical articles about hotel API aggregation, Go microservices, and building scalable traveltech platforms</p>
</div>

## Latest Posts (English)

<div class="posts">
  {% assign en_posts = site.posts | where: "lang", "en" %}
  {% for post in en_posts limit:5 %}
    <div class="post">
      <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
      <p class="meta">{{ post.date | date: "%B %d, %Y" }} · {{ post.content | strip_html | truncatewords: 30 }}</p>
      <p class="categories">
        {% for category in post.categories %}
          <span class="category">{{ category }}</span>
        {% endfor %}
      </p>
    </div>
  {% endfor %}
</div>

---

<div class="hero-zh">
  <h1>构建酒店分销的未来</h1>
  <p>酒店API聚合、Go微服务、构建可扩展旅游技术平台的技术文章</p>
</div>

## 最新文章 (中文)

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

## Categories

<ul class="categories">
  {% for category in site.categories %}
    <li><a href="/categories/{{ category[0] }}">{{ category[0] }}</a> ({{ category[1].size }})</li>
  {% endfor %}
</ul>

## About HotelByte

HotelByte is a next-generation hotel distribution platform that helps travel companies connect with suppliers seamlessly. We build technology that abstracts away the complexity of hotel API integration, allowing you to focus on building great products.

- **Official API**: [openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- **GitHub**: [github.com/hotelbyte-com](https://github.com/hotelbyte-com)
- **Join Waitlist**: [waitlist.hotelbyte.com](https://waitlist.hotelbyte.com)

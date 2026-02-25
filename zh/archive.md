---
layout: post
title: 文章归档
lang: zh
permalink: /zh/archive/
---

<div class="archive">
  <h1>所有文章</h1>
  <p>这里是 HotelByte 博客的所有文章，按时间倒序排列。</p>

  {% assign zh_posts = site.posts | where: "lang", "zh" | sort: "date" | reverse %}
  {% assign current_year = "" %}

  {% for post in zh_posts %}
    {% assign post_year = post.date | date: "%Y" %}
    {% if post_year != current_year %}
      {% if current_year != "" %}</div>{% endif %}
      <h2 class="year">{{ post_year }}</h2>
      <div class="year-posts">
      {% assign current_year = post_year %}
    {% endif %}

    <div class="archive-post">
      <div class="date">{{ post.date | date: "%Y年%-m月%-d日" }}</div>
      <div class="post-title">
        <a href="{{ post.url }}">{{ post.title }}</a>
      </div>
      <div class="meta">
        <span class="author">{{ post.author }}</span>
        {% for category in post.categories %}
          <span class="category">{{ category }}</span>
        {% endfor %}
      </div>
    </div>
  {% endfor %}

  {% if current_year != "" %}</div>{% endif %}
</div>

<style>
.archive {
  max-width: 800px;
  margin: 0 auto;
}

.archive h1 {
  margin-bottom: 10px;
}

.archive p {
  margin-bottom: 30px;
  color: #666;
}

.year {
  margin: 40px 0 20px 0;
  padding-bottom: 10px;
  border-bottom: 2px solid #eee;
}

.archive-post {
  padding: 15px 0;
  border-bottom: 1px solid #eee;
}

.archive-post:hover {
  background-color: #f9f9f9;
  padding-left: 10px;
  transition: all 0.2s ease;
}

.date {
  color: #999;
  font-size: 0.9em;
  margin-bottom: 5px;
}

.post-title {
  margin-bottom: 5px;
}

.post-title a {
  font-size: 1.1em;
  font-weight: 500;
  color: #2c3e50;
  text-decoration: none;
}

.post-title a:hover {
  color: #3498db;
  text-decoration: underline;
}

.meta {
  font-size: 0.85em;
  color: #777;
}

.meta .author {
  margin-right: 15px;
}

.meta .category {
  display: inline-block;
  background-color: #f0f0f0;
  padding: 2px 8px;
  border-radius: 3px;
  margin-right: 5px;
  margin-top: 5px;
  font-size: 0.9em;
}
</style>

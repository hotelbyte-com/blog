---
layout: home
title: HotelByte 技术白皮书系列
lang: zh
permalink: /zh/en/whitepapers/
---

<section class="whitepaper-hub">
  <div class="whitepaper-hero">
    <div>
      <h1>HotelByte 技术白皮书系列</h1>
      <p>面向酒店分销团队、集成伙伴和技术评审者的系统化技术资产。每个主题都提供可快速判断价值的导读，以及可直接引用的白皮书原文。</p>
    </div>
    <div class="whitepaper-hero-panel">
      <span>阅读顺序</span>
      <strong>先读导读，再看原文</strong>
      <p>导读负责把问题讲清楚；原文负责保留架构、控制点和证据锚点。</p>
    </div>
  </div>

  <div class="whitepaper-toolbar">
    <a href="/en/whitepapers/">English version</a>
    <a href="/docs/whitepaper-content-matrix.html">内容矩阵</a>
  </div>

  <div class="whitepaper-grid">
    {% assign zh_posts = site.posts | where: "lang", "zh" %}
    {% for post in zh_posts reversed %}
      {% if post.whitepaper_kind == "guide" %}
        <article class="whitepaper-card">
          <div class="whitepaper-card-meta">Guide · Original</div>
          <h2><a href="{{ post.url }}">{{ post.title | remove: "白皮书导读：" }}</a></h2>
          <p>{{ post.description | default: post.excerpt | strip_html | truncate: 120 }}</p>
          <div class="whitepaper-card-actions">
            <a href="{{ post.url }}">读导读</a>
            {% if post.original_url %}
              <a href="{{ post.original_url }}">看原文</a>
            {% else %}
              <a href="{{ post.url }}original/">看原文</a>
            {% endif %}
          </div>
        </article>
      {% endif %}
    {% endfor %}
  </div>
</section>

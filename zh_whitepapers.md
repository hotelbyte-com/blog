---
layout: home
title: HotelByte 技术白皮书索引
lang: zh
permalink: /zh/whitepapers/
---

<section class="whitepaper-hub">
  <div class="whitepaper-hero">
    <div>
      <h1>HotelByte 技术白皮书索引</h1>
      <p>面向酒店分销团队、集成伙伴和技术评审者的技术资产。每个主题提供读者导读和可引用的白皮书原文。</p>
    </div>
    <div class="whitepaper-hero-panel">
      <span>路径</span>
      <strong>导读 / 原文</strong>
      <p>先判断价值，再进入架构、控制点和证据细节。</p>
    </div>
  </div>

  <div class="whitepaper-toolbar">
    <a href="/en/whitepapers/">English version</a>
    <a href="/docs/whitepaper-content-matrix.html">内容矩阵</a>
  </div>

  <section class="whitepaper-feature">
    <p class="featured-kicker">重点推荐 · WP27</p>
    <h2>AI 原生工程操作系统</h2>
    <p>这篇重量级白皮书不讨论“让 AI 多写一点代码”，而是讨论工程组织如何把 AI 工作纳入意图、证据、执行、验证、评审和记忆的治理系统。</p>
    <div class="featured-actions">
      <a href="/zh/whitepapers/wp27-ai-native-engineering-operating-system/">读导读</a>
      <a href="/zh/whitepapers/wp27-ai-native-engineering-operating-system/original/">看原文</a>
    </div>
  </section>

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

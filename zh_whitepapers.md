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
    <p class="featured-kicker">重点推荐</p>
    <h2>AI 原生工程操作系统</h2>
    <p>模型是租来的，编码智能体和它自带的 harness 也是租来的；工作 harness 要自己训。每一次智能体落地都跑在两套 harness 上：编码智能体内部的智能体 harness，和智能体在其中干活的工作 harness。这篇白皮书讲不到 5 名工程师如何建一个 B2B 酒店分销平台，以一份外部报价上亿元人民币的需求清单为标尺、又不止于它：关于长程任务和长程记忆的十条判断、每条背后的证据、一次针对指令层的预先登记消融实验，以及哪些经验能迁移给造智能体 harness 的人。</p>
    <div class="featured-actions">
      <a href="/zh/whitepapers/ai-native-engineering-operating-system/">读导读</a>
      <a href="/zh/whitepapers/ai-native-engineering-operating-system/original/">看原文</a>
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

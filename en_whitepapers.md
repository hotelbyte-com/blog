---
layout: home
title: HotelByte Technical Whitepaper Index
lang: en
permalink: /en/whitepapers/
---

<section class="whitepaper-hub">
  <div class="whitepaper-hero">
    <div>
      <h1>HotelByte Technical Whitepaper Index</h1>
      <p>Technical assets for hotel distribution teams, integration partners, and technical reviewers. Each topic has a reader guide and a citable whitepaper source.</p>
    </div>
    <div class="whitepaper-hero-panel">
      <span>Path</span>
      <strong>Guide / Source</strong>
      <p>Start with value and context, then move into architecture, controls, and evidence.</p>
    </div>
  </div>

  <div class="whitepaper-toolbar">
    <a href="/zh/whitepapers/">中文版</a>
    <a href="/docs/whitepaper-content-matrix.html">Content matrix</a>
  </div>

  <section class="whitepaper-feature">
    <p class="featured-kicker">Featured</p>
    <h2>AI-Native Engineering Operating System</h2>
    <p>Rent the model. Rent the coding agent and its harness. Train the work harness. Every agent deployment runs on two harnesses: the agent harness inside each coding agent, and the work harness, the environment the agents work in. How fewer than five engineers build a B2B hotel-distribution platform, measured against a requirement catalog that an outside quote priced at more than ¥100 million and built for more than it: ten judgments about long-horizon tasks and long-horizon memory, the evidence behind each, a pre-registered ablation of the instruction layer, and what transfers to anyone who builds an agent harness.</p>
    <div class="featured-actions">
      <a href="/en/whitepapers/ai-native-engineering-operating-system/">Read guide</a>
      <a href="/en/whitepapers/ai-native-engineering-operating-system/original/">Read source</a>
    </div>
  </section>

  <div class="whitepaper-grid">
    {% assign en_posts = site.posts | where: "lang", "en" %}
    {% for post in en_posts reversed %}
      {% if post.whitepaper_kind == "guide" %}
        <article class="whitepaper-card">
          <div class="whitepaper-card-meta">Guide · Original</div>
          <h2><a href="{{ post.url }}">{{ post.title | remove: "Whitepaper Guide: " }}</a></h2>
          <p>{{ post.description | default: post.excerpt | strip_html | truncate: 120 }}</p>
          <div class="whitepaper-card-actions">
            <a href="{{ post.url }}">Read guide</a>
            {% if post.original_url %}
              <a href="{{ post.original_url }}">Read original</a>
            {% else %}
              <a href="{{ post.url }}original/">Read original</a>
            {% endif %}
          </div>
        </article>
      {% endif %}
    {% endfor %}
  </div>
</section>

---
layout: home
title: HotelByte Technical Whitepapers
lang: en
permalink: /en/whitepapers/
---

<section class="whitepaper-hub">
  <div class="whitepaper-hero">
    <div>
      <h1>HotelByte Technical Whitepapers</h1>
      <p>A structured public reading path for hotel distribution teams, integration partners, and technical reviewers. Each topic has a reader-facing guide and a full whitepaper published directly on the blog.</p>
    </div>
    <div class="whitepaper-hero-panel">
      <span>Reading path</span>
      <strong>Start with the guide, then read the original</strong>
      <p>The guide explains why the topic matters; the original keeps the architecture, controls, and evidence in one place.</p>
    </div>
  </div>

  <div class="whitepaper-toolbar">
    <a href="/zh/whitepapers/">中文版</a>
    <a href="/docs/whitepaper-content-matrix.html">Content matrix</a>
  </div>

  <section class="whitepaper-feature">
    <p class="featured-kicker">Featured · WP27</p>
    <h2>AI-Native Engineering Operating System</h2>
    <p>This heavyweight whitepaper is not about making AI write more code. It explains how an engineering organization turns AI work into a governed system of intent, evidence, execution, verification, review, and memory.</p>
    <div class="featured-actions">
      <a href="/en/whitepapers/wp27-ai-native-engineering-operating-system/">Read guide</a>
      <a href="/en/whitepapers/wp27-ai-native-engineering-operating-system/original/">Read source</a>
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

---
layout: home
title: HotelByte Blog
lang: zh
---

<script>
// Eliminate language-selection flicker on the very first byte.
// If the visitor previously chose English, we redirect synchronously inside
// the head — before the body paints — so the user never sees a Chinese flash.
// We never redirect on the English homepage (`/en/`) because that page is
// already English; the symmetric redirect lives in `en/index.md`.
(function () {
  try {
    var pref = localStorage.getItem('hb-lang');
    if (pref === 'en') {
      window.location.replace('/en/');
    }
  } catch (e) {
    // localStorage may be blocked; stay on /.
  }
})();
</script>

<div class="hero">
  <h1>构建酒店分销的未来</h1>
  <p>酒店API聚合、Go微服务、构建可扩展旅游技术平台的技术文章</p>
</div>

<div class="lang-suggest" id="lang-suggest-zh" hidden>
  <p>需要查看英文版？</p>
  <div class="lang-suggest__actions">
    <button type="button" class="lang-suggest__btn lang-suggest__btn--primary" data-lang-action="en">查看英文版</button>
    <button type="button" class="lang-suggest__btn lang-suggest__btn--ghost" data-lang-action="dismiss">继续中文</button>
  </div>
</div>

<section class="featured-whitepaper">
  <div>
    <p class="featured-kicker">重点推荐 · WP27</p>
    <h2>AI 原生工程操作系统</h2>
    <p>AI 不再只是写代码助手。真正的问题是工程组织如何安全吸收 AI 工作，并把人类意图、运行时证据、评审、发布控制和组织记忆接成一条已验证反馈闭环。</p>
  </div>
  <div class="featured-actions">
    <a href="/zh/whitepapers/wp27-ai-native-engineering-operating-system/">读导读</a>
    <a href="/zh/whitepapers/wp27-ai-native-engineering-operating-system/original/">看原文</a>
  </div>
</section>

<div class="quick-links">
  <a href="/zh/whitepapers/" class="link-card">
    <h3>技术白皮书</h3>
    <p>导读与原文</p>
  </a>
  <a href="/zh/series/" class="link-card">
    <h3>专题</h3>
    <p>按主题阅读文章</p>
  </a>
  <a href="/zh/archive/" class="link-card">
    <h3>文章归档</h3>
    <p>浏览所有文章</p>
  </a>
  <a href="/zh/topics/hotel-api-integration/" class="link-card">
    <h3>酒店 API 集成</h3>
    <p>供应商直连、聚合、房型映射</p>
  </a>
  <a href="/zh/topics/openapi-hotel-distribution/" class="link-card">
    <h3>OpenAPI 接入</h3>
    <p>客户认证、预订链路、错误处理</p>
  </a>
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
// Reveal the language suggestion only after the head-level redirect ran (so a
// user with hb-lang=en never sees the banner flicker into existence), and only
// when the visitor has not already expressed a preference. We listen for the
// language switcher click as well, so flipping through the top-bar toggle also
// updates the same preference.
(function () {
  var suggest = document.getElementById('lang-suggest-zh');
  if (!suggest) return;

  try {
    var pref = localStorage.getItem('hb-lang');
    if (pref) return; // user already chose — keep the page silent
  } catch (e) { /* ignore */ }

  suggest.hidden = false;

  suggest.addEventListener('click', function (event) {
    var target = event.target.closest('[data-lang-action]');
    if (!target) return;
    var action = target.getAttribute('data-lang-action');
    try {
      if (action === 'en') {
        localStorage.setItem('hb-lang', 'en');
        window.location.href = '/en/';
      } else {
        localStorage.setItem('hb-lang', 'zh');
        suggest.hidden = true;
      }
    } catch (e) {
      // localStorage unavailable — fall back to plain navigation.
      if (action === 'en') window.location.href = '/en/';
    }
  });

  // If the user clicks the top-bar language switcher before this banner ever
  // shows, treat it as an implicit preference so we don't bounce them back.
  var topToggle = document.querySelector('.language-toggle');
  if (topToggle) {
    topToggle.addEventListener('click', function () {
      try { localStorage.setItem('hb-lang', 'en'); } catch (e) { /* ignore */ }
    }, { capture: true });
  }
})();
</script>
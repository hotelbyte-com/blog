---
layout: home
title: HotelByte Blog
lang: en
---

<div class="hero">
  <h1>Building the Future of Hotel Distribution</h1>
  <p>Technical articles about hotel API aggregation, Go microservices, and building scalable traveltech platforms</p>
</div>

<div class="language-notice">
  <p><a href="/">Switch to 中文</a> | Reading English</p>
</div>

## Latest Posts

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

<script>
// Auto-detect browser language and redirect (only when user hasn't manually selected)
document.addEventListener('DOMContentLoaded', function() {
  // Priority: User manual selection > Browser language > Default language
  const userSelectedLang = sessionStorage.getItem('user-lang-preference');
  
  // If user has manually selected a language, no auto-redirect
  if (userSelectedLang) {
    return; // User's manual selection has highest priority
  }
  
  // Get browser language
  const browserLang = navigator.language || navigator.userLanguage;
  const currentPath = window.location.pathname;
  
  // If browser language is Chinese, and currently on English homepage
  if (browserLang.startsWith('zh') && currentPath === '/en/') {
    // Delay redirect to avoid flicker
    setTimeout(function() {
      // Store browser language as default before redirecting (for first-time visitors)
      sessionStorage.setItem('user-lang-preference', 'zh');
      window.location.href = '/';
    }, 100);
  }
});
</script>


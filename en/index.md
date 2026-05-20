---
layout: home
title: HotelByte Blog
lang: en
permalink: /en/
---

<div class="hero">
  <h1>Building the Future of Hotel Distribution</h1>
  <p>Technical articles about hotel API aggregation, Go microservices, and building scalable traveltech platforms</p>
</div>

<div class="language-notice">
  <p><a href="/">Switch to 中文</a> | Reading English</p>
</div>

<section class="featured-whitepaper">
  <div>
    <p class="featured-kicker">Featured · WP27</p>
    <h2>AI-Native Engineering Operating System</h2>
    <p>AI is no longer just a coding assistant. The hard problem is how an engineering organization safely absorbs AI work into one verified feedback loop across intent, runtime evidence, review, release control, and memory.</p>
  </div>
  <div class="featured-actions">
    <a href="/en/whitepapers/wp27-ai-native-engineering-operating-system/">Read guide</a>
    <a href="/en/whitepapers/wp27-ai-native-engineering-operating-system/original/">Read source</a>
  </div>
</section>

<div class="quick-links">
  <a href="/en/whitepapers/" class="link-card">
    <h3>Whitepapers</h3>
    <p>Read guides and originals as a series</p>
  </a>
  <a href="/en/series/" class="link-card">
    <h3>Series</h3>
    <p>View all article series</p>
  </a>
  <a href="/en/archive/" class="link-card">
    <h3>Archive</h3>
    <p>Browse all posts</p>
  </a>
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

<style>
.quick-links {
  display: flex;
  gap: 20px;
  margin-bottom: 40px;
}

.link-card {
  flex: 1;
  padding: 20px;
  background-color: #f9f9f9;
  border-radius: 8px;
  text-decoration: none;
  border: 2px solid #e0e0e0;
  transition: all 0.3s ease;
}

.link-card:hover {
  border-color: #3498db;
  background-color: #f0f0f0;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.link-card h3 {
  margin: 0 0 10px 0;
  color: #2c3e50;
  font-size: 1.2em;
}

.link-card p {
  margin: 0;
  color: #666;
  font-size: 0.9em;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .quick-links {
    flex-direction: column;
  }
}
</style>

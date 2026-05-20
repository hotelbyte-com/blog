---
layout: post
title: Topic Guides
lang: en
permalink: /en/series/
---

<div class="series">
  <h1>Topic Guides</h1>
  <p>Related articles grouped by topic, without treating every post as one generic series.</p>

  <div class="series-section">
    <h2>Hotel API Integration Field Notes</h2>
    <p class="series-desc">Real integration lessons across authentication, data normalization, rate limits, error handling, timezones, and room mapping.</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <span class="part">Part 1</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/">Why Hotel API Integration Is So Hard (1): Authentication Hell - 10 Weeks Planned, 24 Weeks Still Not Done</a>
        </div>
        <p class="summary">5 suppliers, 5 different authentication methods—Basic Auth, HMAC-SHA256, OAuth1, JWT...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">Part 2</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/">Why Hotel API Integration Is So Hard (2): Data Chaos - Same Hotel, 5 Different Data Formats</a>
        </div>
        <p class="summary">The same hotel can arrive with different schemas, field meanings, and room structures from each supplier.</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">Part 3</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/">Why Hotel API Integration Is So Hard (3): Rate Limiting Nightmare - Blocked 3 Times on Day 1</a>
        </div>
        <p class="summary">Supplier rate limits, hotspot detection, and blocking behavior can break search on launch day.</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">Part 4</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/">Why Hotel API Integration Is So Hard (4): Error Handling - Same Error, 5 Different Status Codes</a>
        </div>
        <p class="summary">Supplier error codes are inconsistent, and HTTP status codes are often misused...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">Part 5</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-5/">Why Hotel API Integration Is So Hard (5): Timezone Issues - User Booked Yesterday's Hotel</a>
        </div>
        <p class="summary">UTC, hotel-local time, user-local time, and daylight saving rules can shift stay dates.</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">Part 6</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-6/">Why Hotel API Integration Is So Hard (6): Room Mapping - Same Room, 5 Different Names</a>
        </div>
        <p class="summary">The same physical room can have different names, photos, and attributes across suppliers.</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">Part 7</span>
          <a href="/en/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-7/">Why Hotel API Integration Is So Hard (Final): Why Can We Solve These Problems?</a>
        </div>
        <p class="summary">Reviewing entire API integration process and summarizing best practices...</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>AI Coding Practice</h2>
    <p class="series-desc">From DeepSeek to Claude Code, exploring practice and experience of AI-assisted programming.</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/en/AI%20Coding/Hospitality%20Industry/Development%20Practice/ai-coding-hotelbyte-journey-from-deepseek-to-claude-code/">AI Coding Practice: Journey from DeepSeek to Claude Code</a>
        </div>
        <p class="summary">We experimented with various AI coding tools in HotelByte project...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/engineering/aicoding/ai-coding-practice-1-deepseek-to-claude-code/">AI Coding Practice (1): Migration from DeepSeek to Claude Code</a>
        </div>
        <p class="summary">How to switch from DeepSeek to Claude Code while maintaining code quality...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/AI%20Coding/Hospitality%20Industry/Development%20Practice/ai-coding-claude-code-integration/">AI Coding Practice (2): Deep Claude Code Integration</a>
        </div>
        <p class="summary">Integrating Claude Code into our development workflow...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/AI%20Coding/Hospitality%20Industry/Development%20Practice/ai-coding-multi-model-integration/">AI Coding Practice (3): Multi-Model and Toolchain Integration</a>
        </div>
        <p class="summary">Using multiple AI models simultaneously to leverage their strengths...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/AI%20Coding/Hospitality%20Industry/Development%20Practice/ai-coding-openspec-driven-development/">AI Coding Practice (4): OpenSpec-Driven Development</a>
        </div>
        <p class="summary">Using OpenSpec specifications to drive AI-assisted development...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/AI%20Coding/Hospitality%20Industry/Development%20Practice/ai-coding-best-practices/">AI Coding Practice (5): AI Coding Best Practices</a>
        </div>
        <p class="summary">Summarizing best practices and considerations for AI coding...</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>HTTP Dispatcher</h2>
    <p class="series-desc">Deep dive into design and implementation of HTTP Dispatcher.</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/en/developer-experience/api-integration/architecture/http-dispatcher-1-what-is-http-dispatcher/">HTTP Dispatcher (1): What Is HTTP Dispatcher and Why It's Needed for Hotel API Integration</a>
        </div>
        <p class="summary">Introducing concept and role of HTTP Dispatcher...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/developer-experience/api-integration/performance/http-dispatcher-2-rate-limiting-connection-pooling/">HTTP Dispatcher (2): How HTTP Dispatcher Solves Rate Limiting and Connection Pooling</a>
        </div>
        <p class="summary">How to implement efficient rate limiting and connection pool management...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/developer-experience/go/api-integration/http-dispatcher-3-implementation-go/">HTTP Dispatcher (3): Implementing HTTP Dispatcher in Go</a>
        </div>
        <p class="summary">Implementing HTTP Dispatcher using Go language...</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>Supplier Proxy</h2>
    <p class="series-desc">Design and implementation of supplier proxy.</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/en/developer-experience/api-integration/architecture/supplier-proxy-1-what-is-supplier-proxy/">Supplier Proxy (1): What Is Supplier Proxy and Its Role in Hotel API Aggregation</a>
        </div>
        <p class="summary">Introducing concept and role of Supplier Proxy...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/en/developer-experience/api-integration/security/supplier-proxy-2-authentication-error-handling/">Supplier Proxy (2): How Supplier Proxy Handles Authentication and Error Handling</a>
        </div>
        <p class="summary">How to handle authentication and errors in Supplier Proxy...</p>
      </li>
    </ul>
  </div>
</div>

<style>
.series {
  max-width: 900px;
  margin: 0 auto;
}

.series h1 {
  margin-bottom: 10px;
}

.series > p {
  margin-bottom: 30px;
  color: #666;
}

.series-section {
  margin-bottom: 50px;
  padding-bottom: 30px;
  border-bottom: 1px solid #eee;
}

.series-section h2 {
  margin-bottom: 10px;
  color: #2c3e50;
}

.series-desc {
  margin-bottom: 20px;
  color: #666;
  font-style: italic;
}

.series-posts {
  list-style: none;
  padding: 0;
  margin: 0;
}

.series-posts li {
  margin-bottom: 25px;
  padding: 20px;
  background-color: #f9f9f9;
  border-radius: 5px;
  border-left: 4px solid #3498db;
}

.series-posts li:hover {
  background-color: #f0f0f0;
  transition: all 0.2s ease;
}

.post-info {
  margin-bottom: 10px;
}

.part {
  display: inline-block;
  background-color: #3498db;
  color: white;
  padding: 2px 8px;
  border-radius: 3px;
  font-size: 0.85em;
  margin-right: 10px;
  font-weight: bold;
}

.post-info a {
  font-size: 1.1em;
  font-weight: 500;
  color: #2c3e50;
  text-decoration: none;
}

.post-info a:hover {
  color: #3498db;
  text-decoration: underline;
}

.summary {
  margin: 0;
  color: #666;
  font-size: 0.95em;
  line-height: 1.6;
}
</style>

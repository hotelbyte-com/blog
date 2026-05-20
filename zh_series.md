---
layout: post
title: 专题目录
lang: zh
permalink: /zh/series/
---

<div class="series">
  <h1>专题目录</h1>
  <p>按主题组织可连续阅读的文章。</p>

  <div class="series-section">
    <h2>行业搜索入口</h2>
    <p class="series-desc">面向酒旅技术团队的短入口页，用于解释酒店 API 集成和 HotelByte OpenAPI 接入。</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/zh/topics/hotel-api-integration/">酒店 API 集成指南</a>
        </div>
        <p class="summary">供应商直连、酒店 API 聚合、房型映射、价格标准化、限流和预订链路可靠性。</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/topics/openapi-hotel-distribution/">HotelByte OpenAPI 酒店分销接入指南</a>
        </div>
        <p class="summary">认证、客户认证、预订链路、错误处理、内容 API 和健康检查，源内容来自 docs/api。</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>酒店 API 集成避坑指南</h2>
    <p class="series-desc">用真实踩坑故事拆解酒店 API 集成的认证、数据、限流、错误处理、时区和房型映射问题。</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <span class="part">第 1 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/">为什么酒店API集成这么难？（1）认证地狱：10周计划，24周还没完成</a>
        </div>
        <p class="summary">5家供应商，5种不同的认证方式——Basic Auth、HMAC-SHA256、OAuth1、JWT...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 2 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/">为什么酒店API集成这么难？（2）数据混乱：同一家酒店，5种不同的数据格式</a>
        </div>
        <p class="summary">同一家酒店在不同供应商里可能有完全不同的数据结构和字段含义。</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 3 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/">为什么酒店API集成这么难？（3）限流噩梦：上线第1天被拉黑3次</a>
        </div>
        <p class="summary">供应商限流策略、热点检测和封禁规则不一致，搜索上线第一天就可能出事故。</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 4 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/">为什么酒店API集成这么难？（4）错误处理：同一个错误，5种不同的状态码</a>
        </div>
        <p class="summary">供应商的错误码不统一，HTTP状态码也经常用错...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 5 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-5/">为什么酒店API集成这么难？（5）时区问题：用户订了昨天的酒店</a>
        </div>
        <p class="summary">UTC、酒店本地时间、用户本地时间和夏令时一起出现时，入住日期很容易错位。</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 6 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-6/">为什么酒店API集成这么难？（6）房间映射：同一个房间，5种不同的名字</a>
        </div>
        <p class="summary">同一个真实房间在不同供应商里有不同名称、图片和属性，直接影响用户体验。</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 7 部分</span>
          <a href="/zh/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-7/">为什么酒店API集成这么难？（终）我们为什么能解决这些问题？</a>
        </div>
        <p class="summary">回顾整个API集成过程，总结最佳实践...</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>AI 编程实践</h2>
    <p class="series-desc">从 DeepSeek 到 Claude Code，探索 AI 辅助编程的实践与经验。</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/zh/AI%20Coding/%E9%85%92%E5%BA%97%E8%A1%8C%E4%B8%9A/%E5%BC%80%E5%8F%91%E5%AE%9E%E8%B7%B5/ai-coding-hotelbyte-journey-from-deepseek-to-claude-code/">AI 编程实践：从 DeepSeek 到 Claude Code 的演进之旅</a>
        </div>
        <p class="summary">我们在 HotelByte 项目中尝试了多种 AI 编程工具...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/engineering/aicoding/ai-coding-practice-1-deepseek-to-claude-code/">AI 编程实践（1）：DeepSeek 到 Claude Code 的迁移</a>
        </div>
        <p class="summary">如何从 DeepSeek 切换到 Claude Code，保持代码质量...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/AI%20Coding/%E9%85%92%E5%BA%97%E8%A1%8C%E4%B8%9A/%E5%BC%80%E5%8F%91%E5%AE%9E%E8%B7%B5/ai-coding-claude-code-integration/">AI 编程实践（2）：Claude Code 深度集成</a>
        </div>
        <p class="summary">将 Claude Code 集成到我们的开发工作流中...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/engineering/aicoding/ai-coding-practice-2-claude-code-deep-integration/">AI 编程实践（2）：Cla Code 深度集成 - AI Coding 实践（二）</a>
        </div>
        <p class="summary">将 Claude Code 深度集成到开发工作流中...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/AI%20Coding/%E9%85%92%E5%BA%97%E8%A1%8C%E4%B8%9A/%E5%BC%80%E5%8F%91%E5%AE%9E%E8%B7%B5/ai-coding-multi-model-integration/">AI 编程实践（3）：多模型与工具链集成</a>
        </div>
        <p class="summary">同时使用多个 AI 模型，发挥各自优势...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/AI%20Coding/%E9%85%92%E5%BA%97%E8%A1%8C%E4%B8%9A/%E5%BC%80%E5%8F%91%E5%AE%9E%E8%B7%B5/ai-coding-openspec-driven-development/">AI 编程实践（4）：OpenSpec 规格驱动开发</a>
        </div>
        <p class="summary">使用 OpenSpec 规范来驱动 AI 辅助开发...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/AI%20Coding/%E9%85%92%E5%BA%97%E8%A1%8C%E4%B8%9A/%E5%BC%80%E5%8F%91%E5%AE%9E%E8%B7%B5/ai-coding-best-practices/">AI 编程实践（5）：AI Coding 最佳实践</a>
        </div>
        <p class="summary">总结 AI 编程的最佳实践和注意事项...</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>HTTP Dispatcher</h2>
    <p class="series-desc">深入理解 HTTP Dispatcher 的设计与实现。</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/zh/developer-experience/api-integration/architecture/http-dispatcher-1-what-is-http-dispatcher/">HTTP Dispatcher（1）：什么是HTTP Dispatcher？为什么酒店API集成必须要有它</a>
        </div>
        <p class="summary">介绍 HTTP Dispatcher 的概念和作用...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/developer-experience/api-integration/performance/http-dispatcher-2-rate-limiting-connection-pooling/">HTTP Dispatcher（2）：HTTP Dispatcher如何解决限流和连接池问题</a>
        </div>
        <p class="summary">如何实现高效的限流和连接池管理...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/developer-experience/go/api-integration/http-dispatcher-3-implementation-go/">HTTP Dispatcher（3）：在Go中实现HTTP Dispatcher</a>
        </div>
        <p class="summary">使用 Go 语言实现 HTTP Dispatcher...</p>
      </li>
    </ul>
  </div>

  <div class="series-section">
    <h2>Supplier Proxy</h2>
    <p class="series-desc">供应商代理的设计与实现。</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <a href="/zh/developer-experience/api-integration/architecture/supplier-proxy-1-what-is-supplier-proxy/">Supplier Proxy（1）：什么是Supplier Proxy？它是酒店API聚合的骨干</a>
        </div>
        <p class="summary">介绍 Supplier Proxy 的概念和作用...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/developer-experience/api-integration/security/supplier-proxy-2-authentication-error-handling/">Supplier Proxy（2）：Supplier Proxy如何处理认证和错误处理</a>
        </div>
        <p class="summary">如何在 Supplier Proxy 中处理认证和错误...</p>
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

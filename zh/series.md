---
layout: post
title: 系列文章
lang: zh
---

<div class="series">
  <h1>系列文章</h1>
  <p>这里按主题整理了相关的系列文章，方便您系统性地阅读。</p>

  <div class="series-section">
    <h2>为什么酒店API集成这么难</h2>
    <p class="series-desc">深入探讨酒店API集成的各种挑战，从认证到协议差异，从错误处理到性能优化。</p>
    <ul class="series-posts">
      <li>
        <div class="post-info">
          <span class="part">第 1 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard/">为什么酒店API集成这么难？（1）认证地狱：10周计划，24周还没完成</a>
        </div>
        <p class="summary">5家供应商，5种不同的认证方式——Basic Auth、HMAC-SHA256、OAuth1、JWT...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 2 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard-2/">为什么酒店API集成这么难？（2）协议丛林：REST、SOAP、JSON-RPC、XML-RPC</a>
        </div>
        <p class="summary">除了认证方式不同，API协议也五花八门...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 3 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard-3/">为什么酒店API集成这么难？（3）数据模型噩梦：100个字段，10个供应商，1000种组合</a>
        </div>
        <p class="summary">同一个字段在不同供应商的API中可能有完全不同的含义...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 4 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard-4/">为什么酒店API集成这么难？（4）错误处理：500种错误码，你该相信谁？</a>
        </div>
        <p class="summary">供应商的错误码不统一，HTTP状态码也经常用错...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 5 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard-5/">为什么酒店API集成这么难？（5）限流熔断：别让你的API被供应商封禁</a>
        </div>
        <p class="summary">每个供应商都有不同的限流策略，需要精心设计...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 6 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard-6/">为什么酒店API集成这么难？（6）缓存策略：别让重复查询拖垮性能</a>
        </div>
        <p class="summary">酒店数据变化频率不同，需要智能的缓存策略...</p>
      </li>
      <li>
        <div class="post-info">
          <span class="part">第 7 部分</span>
          <a href="/zh/developer-experience/why-hotel-api-integration-is-so-hard-7/">为什么酒店API集成这么难？（7）总结与最佳实践</a>
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
          <a href="/zh/ai-coding/ai-coding-hotelbyte-journey-from-deepseek-to-claude-code/">AI 编程实践：从 DeepSeek 到 Claude Code 的演进之旅</a>
        </div>
        <p class="summary">我们在 HotelByte 项目中尝试了多种 AI 编程工具...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/aicoding/ai-coding-practice-1-deepseek-to-claude-code/">AI 编程实践（1）：DeepSeek 到 Claude Code 的迁移</a>
        </div>
        <p class="summary">如何从 DeepSeek 切换到 Claude Code，保持代码质量...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/ai-coding/ai-coding-claude-code-integration/">AI 编程实践（2）：Claude Code 深度集成</a>
        </div>
        <p class="summary">将 Claude Code 集成到我们的开发工作流中...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/ai-coding/ai-coding-multi-model-integration/">AI 编程实践（3）：多模型集成</a>
        </div>
        <p class="summary">同时使用多个 AI 模型，发挥各自优势...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/ai-coding/ai-coding-openspec-driven-development/">AI 编程实践（4）：OpenSpec 驱动开发</a>
        </div>
        <p class="summary">使用 OpenSpec 规范来驱动 AI 辅助开发...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/ai-coding/ai-coding-best-practices/">AI 编程实践（5）：最佳实践</a>
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
          <a href="/zh/architecture/http-dispatcher-1-what-is-http-dispatcher/">HTTP Dispatcher（1）：什么是 HTTP Dispatcher</a>
        </div>
        <p class="summary">介绍 HTTP Dispatcher 的概念和作用...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/performance/http-dispatcher-2-rate-limiting-connection-pooling/">HTTP Dispatcher（2）：限流与连接池</a>
        </div>
        <p class="summary">如何实现高效的限流和连接池管理...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/api-integration/http-dispatcher-3-implementation-go/">HTTP Dispatcher（3）：Go 语言实现</a>
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
          <a href="/zh/architecture/supplier-proxy-1-what-is-supplier-proxy/">Supplier Proxy（1）：什么是 Supplier Proxy</a>
        </div>
        <p class="summary">介绍 Supplier Proxy 的概念和作用...</p>
      </li>
      <li>
        <div class="post-info">
          <a href="/zh/security/supplier-proxy-2-authentication-error-handling/">Supplier Proxy（2）：认证与错误处理</a>
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

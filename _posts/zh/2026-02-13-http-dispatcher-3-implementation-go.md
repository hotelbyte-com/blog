---
layout: post
title: "HTTP Dispatcher系列（3）：在Go中实现HTTP Dispatcher"
date: 2026-02-13 10:00:00 +0000
categories: [developer-experience, go, api-integration]
tags: [http-dispatcher, go, implementation, tutorial]
author: "HotelByte Team"
description: "在Go中实现HTTP Dispatcher的逐步指南。完整的代码示例，展示限流、连接池、优先级队列和用于酒店API集成的生产就绪模式。"
reading_time: "15 minutes"
lang: zh
---

既然我们了解了HTTP Dispatcher的作用以及它如何解决限流和连接池问题，让我们在Go中实现一个。

## 项目结构

```
http-dispatcher/
├── cmd/
│   └── example/
│       └── main.go
├── pkg/
│   ├── dispatcher.go         # 主调度器
│   ├── ratelimiter.go        # 限流
│   ├── pool.go               # 连接池
│   ├── priority.go           # 优先级队列
│   ├── retry.go              # 重试逻辑
│   └── metrics.go            # 指标收集
├── go.mod
└── README.md
```

## 步骤1：核心类型和配置

```go
// pkg/dispatcher.go
package dispatcher

import (
    "context"
    "sync"
    "time"
)

// 优先级级别
const (
    PriorityHighest = iota + 1
    PriorityHigh
    PriorityNormal
    PriorityLow
    PriorityLowest
)

// Request 表示供应商API请求
type Request struct {
    ID       string
    Supplier string
    Method   string
    URL      string
    Headers  map[string]string
    Body     []byte
    Priority int
    Timeout  time.Duration
}

// Response 表示API响应
type Response struct {
    StatusCode int
    Body       []byte
    Headers    http.Header
    Duration   time.Duration
    FromCache  bool
}

// SupplierConfig 保存供应商特定设置
type SupplierConfig struct {
    BaseURL             string
    RateLimit          float64          // 每秒请求数
    MaxIdleConns       int
    MaxConnsPerHost    int
    ConnectionTimeout  time.Duration
    IdleTimeout        time.Duration
    RetryAttempts      int
    RetryBaseDelay     time.Duration
}

// Config 是调度器配置
type Config struct {
    Suppliers       map[string]SupplierConfig
    MaxQueueSize    int
    WorkerCount     int
    MetricsEnabled  bool
}

// HTTPDispatcher 是主调度器
type HTTPDispatcher struct {
    config          Config
    rateLimiter     *RateLimiter
    poolManager     *PoolManager
    priorityQueue   *PriorityQueue
    retryHandler    *RetryHandler
    metrics         *MetricsCollector
    workers         []*Worker
    shutdownChan    chan struct{}
    mu              sync.RWMutex
}
```

## 步骤2：限流器实现

```go
// pkg/ratelimiter.go
package dispatcher

import (
    "sync"
    "time"
)

// TokenBucketRateLimiter 实现令牌桶算法
type TokenBucketRateLimiter struct {
    capacity  float64
    rate      float64          // 每秒添加的令牌
    tokens    float64
    lastRefill time.Time
    mu        sync.Mutex
}

// NewTokenBucketRateLimiter 创建新的限流器
func NewTokenBucketRateLimiter(capacity int, rate float64) *TokenBucketRateLimiter {
    return &TokenBucketRateLimiter{
        capacity:  float64(capacity),
        rate:      rate,
        tokens:    float64(capacity),
        lastRefill: time.Now(),
    }
}

// Allow 检查请求是否被允许
func (tb *TokenBucketRateLimiter) Allow() bool {
    tb.mu.Lock()
    defer tb.mu.Unlock()

    now := time.Now()
    elapsed := now.Sub(tb.lastRefill).Seconds()
    tb.lastRefill = now

    // 填充令牌
    tb.tokens += elapsed * tb.rate
    if tb.tokens > tb.capacity {
        tb.tokens = tb.capacity
    }

    // 检查是否有令牌
    if tb.tokens >= 1.0 {
        tb.tokens -= 1.0
        return true
    }

    return false
}

// RateLimiter 管理多个供应商限流
type RateLimiter struct {
    limiters map[string]*TokenBucketRateLimiter
    config   map[string]SupplierConfig
    mu       sync.RWMutex
}

// NewRateLimiter 创建新的限流器
func NewRateLimiter(config map[string]SupplierConfig) *RateLimiter {
    rl := &RateLimiter{
        limiters: make(map[string]*TokenBucketRateLimiter),
        config:   config,
    }

    for supplier, cfg := range config {
        rl.limiters[supplier] = NewTokenBucketRateLimiter(
            int(cfg.RateLimit)*10, // 允许突发达速率的10倍
            cfg.RateLimit,
        )
    }

    return rl
}

// Allow 检查供应商的请求是否被允许
func (rl *RateLimiter) Allow(supplier string) bool {
    rl.mu.RLock()
    limiter, exists := rl.limiters[supplier]
    rl.mu.RUnlock()

    if !exists {
        return true // 如果未配置则无限流
    }

    return limiter.Allow()
}

// GetWaitTime 返回下一个请求的预计等待时间
func (rl *RateLimiter) GetWaitTime(supplier string) time.Duration {
    rl.mu.RLock()
    limiter, exists := rl.limiters[supplier]
    rl.mu.RUnlock()

    if !exists {
        return 0
    }

    if limiter.Allow() {
        return 0
    }

    // 基于速率估算等待时间
    rl.mu.RLock()
    rate := rl.config[supplier].RateLimit
    rl.mu.RUnlock()

    return time.Duration(float64(time.Second) / rate)
}
```

## 步骤3：连接池管理器

```go
// pkg/pool.go
package dispatcher

import (
    "crypto/tls"
    "net"
    "net/http"
    "sync"
    "time"
)

// PoolManager 管理每个供应商的HTTP连接池
type PoolManager struct {
    clients map[string]*http.Client
    configs map[string]SupplierConfig
    mu      sync.RWMutex
}

// NewPoolManager 创建新的池管理器
func NewPoolManager(configs map[string]SupplierConfig) *PoolManager {
    pm := &PoolManager{
        clients: make(map[string]*http.Client),
        configs: configs,
    }

    // 为所有供应商初始化池
    for supplier, cfg := range configs {
        pm.createPool(supplier, cfg)
    }

    return pm
}

// createPool 为供应商创建新的HTTP客户端
func (pm *PoolManager) createPool(supplier string, cfg SupplierConfig) {
    transport := &http.Transport{
        // 带超时的拨号上下文
        DialContext: (&net.Dialer{
            Timeout:   cfg.ConnectionTimeout,
            KeepAlive: 30 * time.Second,
        }).DialContext,

        // TLS配置
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: false,
            MinVersion:         tls.VersionTLS12,
            NextProtos:         []string{"h2", "http/1.1"},
        },

        // 连接池
        MaxIdleConns:        200,                     // 总空闲连接
        MaxIdleConnsPerHost: cfg.MaxIdleConns,       // 每个供应商
        MaxConnsPerHost:     cfg.MaxConnsPerHost,    // 最大活动连接
        IdleConnTimeout:     cfg.IdleTimeout,
        DisableKeepAlives:   false,
        DisableCompression:  false,

        // 响应头超时
        ResponseHeaderTimeout: cfg.ConnectionTimeout,

        // 如果支持则强制HTTP/2
        ForceAttemptHTTP2: true,
    }

    client := &http.Client{
        Transport: transport,
        Timeout:   cfg.ConnectionTimeout,
        CheckRedirect: func(req *http.Request, via []*http.Request) error {
            // 跟随最多10次重定向
            if len(via) >= 10 {
                return http.ErrUseLastResponse
            }
            return nil
        },
    }

    pm.mu.Lock()
    pm.clients[supplier] = client
    pm.mu.Unlock()
}

// GetClient 返回供应商的HTTP客户端
func (pm *PoolManager) GetClient(supplier string) *http.Client {
    pm.mu.RLock()
    client, exists := pm.clients[supplier]
    pm.mu.RUnlock()

    if !exists {
        pm.mu.Lock()
        cfg, exists := pm.configs[supplier]
        if exists {
            pm.createPool(supplier, cfg)
            client = pm.clients[supplier]
        }
        pm.mu.Unlock()
    }

    return client
}

// GetStats 返回供应商的池统计
func (pm *PoolManager) GetStats(supplier string) *PoolStats {
    pm.mu.RLock()
    client := pm.clients[supplier]
    cfg := pm.configs[supplier]
    pm.mu.RUnlock()

    if client == nil {
        return nil
    }

    transport, ok := client.Transport.(*http.Transport)
    if !ok {
        return nil
    }

    return &PoolStats{
        MaxIdleConns:        cfg.MaxIdleConns,
        MaxConnsPerHost:     cfg.MaxConnsPerHost,
        IdleConnTimeout:     cfg.IdleTimeout,
        ResponseHeaderTimeout: cfg.ConnectionTimeout,
    }
}

// PoolStats 保存池统计
type PoolStats struct {
    MaxIdleConns          int
    MaxConnsPerHost       int
    IdleConnTimeout       time.Duration
    ResponseHeaderTimeout time.Duration
}
```

## 步骤4：优先级队列

```go
// pkg/priority.go
package dispatcher

import (
    "container/heap"
    "sync"
    "time"
)

// RequestItem 表示优先级队列中的请求
type RequestItem struct {
    Request    *Request
    Priority   int
    SubmitTime time.Time
    Index      int
}

// PriorityQueue 实现 heap.Interface
type PriorityQueue struct {
    items []*RequestItem
    mu    sync.RWMutex
    cond  *sync.Cond
}

// NewPriorityQueue 创建新的优先级队列
func NewPriorityQueue(maxSize int) *PriorityQueue {
    pq := &PriorityQueue{
        items: make([]*RequestItem, 0, maxSize),
    }
    pq.cond = sync.NewCond(&pq.mu)
    return pq
}

// Len 返回队列长度
func (pq *PriorityQueue) Len() int {
    pq.mu.RLock()
    defer pq.mu.RUnlock()
    return len(pq.items)
}

// Less 比较两个项
func (pq *PriorityQueue) Less(i, j int) bool {
    // 更高优先级（更小数字）先到
    if pq.items[i].Priority != pq.items[j].Priority {
        return pq.items[i].Priority < pq.items[j].Priority
    }
    // 相同优先级的FIFO
    return pq.items[i].SubmitTime.Before(pq.items[j].SubmitTime)
}

// Swap 交换两个项
func (pq *PriorityQueue) Swap(i, j int) {
    pq.items[i], pq.items[j] = pq.items[j], pq.items[i]
    pq.items[i].Index = i
    pq.items[j].Index = j
}

// Push 向队列添加项
func (pq *PriorityQueue) Push(x interface{}) {
    n := len(pq.items)
    item := x.(*RequestItem)
    item.Index = n
    pq.items = append(pq.items, item)
}

// Pop 从队列移除项
func (pq *PriorityQueue) Pop() interface{} {
    n := len(pq.items)
    item := pq.items[n-1]
    pq.items[n-1] = nil
    item.Index = -1
    pq.items = pq.items[:n-1]
    return item
}

// Enqueue 向队列添加请求
func (pq *PriorityQueue) Enqueue(req *Request, priority int) error {
    pq.mu.Lock()
    defer pq.mu.Unlock()

    // 检查队列大小（如需要实现最大大小逻辑）
    item := &RequestItem{
        Request:    req,
        Priority:   priority,
        SubmitTime: time.Now(),
    }

    heap.Push(pq, item)
    pq.cond.Signal()

    return nil
}

// Dequeue 从队列移除请求
func (pq *PriorityQueue) Dequeue() *Request {
    pq.mu.Lock()
    defer pq.mu.Unlock()

    for len(pq.items) == 0 {
        pq.cond.Wait()
    }

    item := heap.Pop(pq).(*RequestItem)
    return item.Request
}

// Peek 返回下一个请求而不移除它
func (pq *PriorityQueue) Peek() *Request {
    pq.mu.RLock()
    defer pq.mu.RUnlock()

    if len(pq.items) == 0 {
        return nil
    }

    return pq.items[0].Request
}

// Clear 从队列移除所有项
func (pq *PriorityQueue) Clear() {
    pq.mu.Lock()
    defer pq.mu.Unlock()

    pq.items = make([]*RequestItem, 0)
}
```

## 步骤5：重试处理器

```go
// pkg/retry.go
package dispatcher

import (
    "context"
    "fmt"
    "math"
    "net/http"
    "time"
)

// RetryHandler 实现指数退避重试逻辑
type RetryHandler struct {
    maxAttempts  int
    baseDelay    time.Duration
    maxDelay     time.Duration
    jitterFactor float64
}

// NewRetryHandler 创建新的重试处理器
func NewRetryHandler(maxAttempts int, baseDelay, maxDelay time.Duration) *RetryHandler {
    return &RetryHandler{
        maxAttempts:  maxAttempts,
        baseDelay:    baseDelay,
        maxDelay:     maxDelay,
        jitterFactor: 0.1, // 10%抖动
    }
}

// ShouldRetry 确定是否应该重试请求
func (rh *RetryHandler) ShouldRetry(attempt int, statusCode int, err error) bool {
    if attempt >= rh.maxAttempts {
        return false
    }

    // 在服务器错误（5xx）上重试
    if statusCode >= 500 && statusCode < 600 {
        return true
    }

    // 在限流（429）上重试
    if statusCode == 429 {
        return true
    }

    // 在超时错误上重试
    if err != nil {
        if netErr, ok := err.(net.Error); ok {
            if netErr.Timeout() {
                return true
            }
        }
    }

    return false
}

// GetBackoffDelay 计算带有指数退避和抖动的延迟
func (rh *RetryHandler) GetBackoffDelay(attempt int) time.Duration {
    // 指数退避: base * 2^attempt
    delay := float64(rh.baseDelay) * math.Pow(2, float64(attempt))

    // 上限为最大延迟
    if delay > float64(rh.maxDelay) {
        delay = float64(rh.maxDelay)
    }

    // 添加抖动以避免雪崩
    jitter := delay * rh.jitterFactor * (2*rand.Float64() - 1)
    delay += jitter

    if delay < 0 {
        delay = float64(rh.baseDelay)
    }

    return time.Duration(delay)
}

// Execute 使用重试逻辑执行请求
func (rh *RetryHandler) Execute(ctx context.Context, client *http.Client, req *http.Request) (*http.Response, error) {
    var lastErr error
    var lastResp *http.Response

    for attempt := 0; attempt < rh.maxAttempts; attempt++ {
        // 使用上下文创建请求
        reqCopy := req.Clone(ctx)

        // 执行请求
        resp, err := client.Do(reqCopy)
        lastResp = resp
        lastErr = err

        // 检查是否应该重试
        statusCode := 0
        if resp != nil {
            statusCode = resp.StatusCode
        }

        if !rh.ShouldRetry(attempt, statusCode, err) {
            break
        }

        // 记录重试
        if attempt < rh.maxAttempts-1 {
            delay := rh.GetBackoffDelay(attempt)
            logRetry(req.URL.String(), attempt, statusCode, delay)

            // 重试前关闭响应体
            if resp != nil {
                resp.Body.Close()
            }

            // 等待上下文取消
            select {
            case <-time.After(delay):
                continue
            case <-ctx.Done():
                return nil, ctx.Err()
            }
        }
    }

    return lastResp, lastErr
}

func logRetry(url string, attempt, statusCode int, delay time.Duration) {
    // 实现日志记录
    fmt.Printf("重试 %d for %s (status: %d, delay: %v)\n",
        attempt+1, url, statusCode, delay)
}
```

## 步骤6：主调度器

```go
// pkg/dispatcher.go (续)

// NewHTTPDispatcher 创建新的HTTP调度器
func NewHTTPDispatcher(config Config) (*HTTPDispatcher, error) {
    d := &HTTPDispatcher{
        config:        config,
        rateLimiter:   NewRateLimiter(config.Suppliers),
        poolManager:   NewPoolManager(config.Suppliers),
        priorityQueue: NewPriorityQueue(config.MaxQueueSize),
        retryHandler:  NewRetryHandler(3, 100*time.Millisecond, 5*time.Second),
        metrics:       NewMetricsCollector(),
        shutdownChan:  make(chan struct{}),
    }

    // 启动工作池
    d.startWorkers()

    return d, nil
}

// startWorkers 启动工作池
func (d *HTTPDispatcher) startWorkers() {
    d.workers = make([]*Worker, d.config.WorkerCount)

    for i := 0; i < d.config.WorkerCount; i++ {
        worker := &Worker{
            ID:         i,
            Dispatcher: d,
        }
        d.workers[i] = worker
        go worker.Run()
    }
}

// Submit 提交请求到调度器
func (d *HTTPDispatcher) Submit(ctx context.Context, req *Request) (*Response, error) {
    start := time.Now()

    // 将请求入队
    err := d.priorityQueue.Enqueue(req, req.Priority)
    if err != nil {
        return nil, fmt.Errorf("入队失败: %w", err)
    }

    // 创建结果通道
    resultChan := make(chan *Result, 1)

    // 处理请求（在实际实现中，这将由工作程序完成）
    go func() {
        response, err := d.processRequest(ctx, req)
        resultChan <- &Result{
            Response: response,
            Error:    err,
        }
    }()

    // 等待结果或上下文取消
    select {
    case result := <-resultChan:
        duration := time.Since(start)

        // 记录指标
        d.metrics.Record(req.Supplier, duration, result.Response.StatusCode)

        return result.Response, result.Error
    case <-ctx.Done():
        return nil, ctx.Err()
    }
}

// processRequest 处理单个请求
func (d *HTTPDispatcher) processRequest(ctx context.Context, req *Request) (*Response, error) {
    // 等待限流
    for {
        if d.rateLimiter.Allow(req.Supplier) {
            break
        }
        time.Sleep(10 * time.Millisecond)
    }

    // 从池获取HTTP客户端
    client := d.poolManager.GetClient(req.Supplier)

    // 创建HTTP请求
    httpReq, err := http.NewRequestWithContext(ctx, req.Method, req.URL, bytes.NewReader(req.Body))
    if err != nil {
        return nil, fmt.Errorf("创建请求失败: %w", err)
    }

    // 设置头
    for k, v := range req.Headers {
        httpReq.Header.Set(k, v)
    }

    // 带重试执行
    httpResp, err := d.retryHandler.Execute(ctx, client, httpReq)
    if err != nil {
        return nil, fmt.Errorf("请求失败: %w", err)
    }
    defer httpResp.Body.Close()

    // 读取响应体
    body, err := io.ReadAll(httpResp.Body)
    if err != nil {
        return nil, fmt.Errorf("读取响应失败: %w", err)
    }

    return &Response{
        StatusCode: httpResp.StatusCode,
        Body:       body,
        Headers:    httpResp.Header,
        Duration:   time.Since(time.Now()),
        FromCache:  false,
    }, nil
}

// Shutdown 优雅关闭调度器
func (d *HTTPDispatcher) Shutdown(ctx context.Context) error {
    close(d.shutdownChan)

    // 等待工作程序完成（带超时）
    done := make(chan struct{})
    go func() {
        for _, worker := range d.workers {
            worker.Stop()
        }
        close(done)
    }()

    select {
    case <-done:
        return nil
    case <-ctx.Done():
        return ctx.Err()
    }
}

// GetMetrics 返回当前指标
func (d *HTTPDispatcher) GetMetrics() *Metrics {
    return d.metrics.Snapshot()
}

// Result 表示请求的结果
type Result struct {
    Response *Response
    Error    error
}

// Worker 处理队列中的请求
type Worker struct {
    ID         int
    Dispatcher *HTTPDispatcher
    stopChan   chan struct{}
}

// Run 启动工作程序
func (w *Worker) Run() {
    w.stopChan = make(chan struct{})

    for {
        select {
        case <-w.stopChan:
            return
        default:
            // 出队下一个请求
            req := w.Dispatcher.priorityQueue.Dequeue()
            if req == nil {
                continue
            }

            // 处理请求
            ctx, cancel := context.WithTimeout(context.Background(), req.Timeout)
            w.Dispatcher.processRequest(ctx, req)
            cancel()
        }
    }
}

// Stop 停止工作程序
func (w *Worker) Stop() {
    close(w.stopChan)
}
```

## 步骤7：指标收集器

```go
// pkg/metrics.go
package dispatcher

import (
    "sync"
    "time"
)

// MetricsCollector 收集和聚合指标
type MetricsCollector struct {
    requests map[string]*SupplierMetrics
    mu       sync.RWMutex
}

// SupplierMetrics 保存供应商的指标
type SupplierMetrics struct {
    TotalRequests      int64
    SuccessRequests    int64
    FailedRequests     int64
    RateLimitedRequests int64
    TotalDuration      time.Duration
    MinDuration        time.Duration
    MaxDuration        time.Duration
}

// Metrics 表示所有指标的快照
type Metrics struct {
    Suppliers map[string]*SupplierMetrics
}

// NewMetricsCollector 创建新的指标收集器
func NewMetricsCollector() *MetricsCollector {
    return &MetricsCollector{
        requests: make(map[string]*SupplierMetrics),
    }
}

// Record 记录请求
func (mc *MetricsCollector) Record(supplier string, duration time.Duration, statusCode int) {
    mc.mu.Lock()
    defer mc.mu.Unlock()

    metrics, exists := mc.requests[supplier]
    if !exists {
        metrics = &SupplierMetrics{
            MinDuration: duration,
            MaxDuration: duration,
        }
        mc.requests[supplier] = metrics
    }

    metrics.TotalRequests++
    metrics.TotalDuration += duration

    if duration < metrics.MinDuration {
        metrics.MinDuration = duration
    }
    if duration > metrics.MaxDuration {
        metrics.MaxDuration = duration
    }

    switch {
    case statusCode >= 200 && statusCode < 300:
        metrics.SuccessRequests++
    case statusCode == 429:
        metrics.RateLimitedRequests++
        metrics.FailedRequests++
    default:
        metrics.FailedRequests++
    }
}

// Snapshot 返回当前指标的快照
func (mc *MetricsCollector) Snapshot() *Metrics {
    mc.mu.RLock()
    defer mc.mu.RUnlock()

    snapshot := &Metrics{
        Suppliers: make(map[string]*SupplierMetrics),
    }

    for supplier, metrics := range mc.requests {
        // 深度复制指标
        copy := *metrics
        snapshot.Suppliers[supplier] = &copy
    }

    return snapshot
}

// Reset 清除所有指标
func (mc *MetricsCollector) Reset() {
    mc.mu.Lock()
    defer mc.mu.Unlock()

    mc.requests = make(map[string]*SupplierMetrics)
}
```

## 步骤8：示例用法

```go
// cmd/example/main.go
package main

import (
    "context"
    "fmt"
    "time"
    "your-project/pkg/dispatcher"
)

func main() {
    // 配置供应商
    config := dispatcher.Config{
        Suppliers: map[string]dispatcher.SupplierConfig{
            "hotelbeds": {
                BaseURL:            "https://api.hotelbeds.com",
                RateLimit:         10.0,  // 10 req/s
                MaxIdleConns:       20,
                MaxConnsPerHost:    30,
                ConnectionTimeout:  5 * time.Second,
                IdleTimeout:        90 * time.Second,
                RetryAttempts:      3,
                RetryBaseDelay:     100 * time.Millisecond,
            },
            "dida": {
                BaseURL:            "https://api.dida.travel",
                RateLimit:         20.0,  // 20 req/s
                MaxIdleConns:       30,
                MaxConnsPerHost:    40,
                ConnectionTimeout:  3 * time.Second,
                IdleTimeout:        60 * time.Second,
                RetryAttempts:      3,
                RetryBaseDelay:     100 * time.Millisecond,
            },
        },
        MaxQueueSize:   1000,
        WorkerCount:    10,
        MetricsEnabled: true,
    }

    // 创建调度器
    d, err := dispatcher.NewHTTPDispatcher(config)
    if err != nil {
        panic(err)
    }
    defer d.Shutdown(context.Background())

    // 提交请求
    for i := 0; i < 100; i++ {
        req := &dispatcher.Request{
            ID:       fmt.Sprintf("req-%d", i),
            Supplier: "hotelbeds",
            Method:   "GET",
            URL:      "https://api.hotelbeds.com/v1/hotels",
            Headers: map[string]string{
                "Accept": "application/json",
            },
            Priority: dispatcher.PriorityNormal,
            Timeout:  10 * time.Second,
        }

        go func(r *dispatcher.Request) {
            resp, err := d.Submit(context.Background(), r)
            if err != nil {
                fmt.Printf("请求 %s 失败: %v\n", r.ID, err)
                return
            }

            fmt.Printf("请求 %s: status=%d, duration=%v\n",
                r.ID, resp.StatusCode, resp.Duration)
        }(req)
    }

    // 等待完成
    time.Sleep(30 * time.Second)

    // 打印指标
    metrics := d.GetMetrics()
    for supplier, m := range metrics.Suppliers {
        fmt.Printf("\n供应商: %s\n", supplier)
        fmt.Printf("  总计: %d\n", m.TotalRequests)
        fmt.Printf("  成功: %d\n", m.SuccessRequests)
        fmt.Printf("  失败: %d\n", m.FailedRequests)
        fmt.Printf("  限流: %d\n", m.RateLimitedRequests)
        avgDuration := float64(m.TotalDuration) / float64(m.TotalRequests) / float64(time.Millisecond)
        fmt.Printf("  平均延迟: %.2fms\n", avgDuration)
    }
}
```

## 测试

```go
// pkg/dispatcher_test.go
package dispatcher

import (
    "context"
    "testing"
    "time"
)

func TestRateLimiter(t *testing.T) {
    limiter := NewTokenBucketRateLimiter(10, 5.0) // 5 req/s

    // 前10个都应该被允许
    for i := 0; i < 10; i++ {
        if !limiter.Allow() {
            t.Errorf("请求 %d 应该被允许", i)
        }
    }

    // 下一个应该被限流
    if limiter.Allow() {
        t.Error("请求应该被限流")
    }

    // 等待填充
    time.Sleep(250 * time.Millisecond)

    // 应该再次被允许
    if !limiter.Allow() {
        t.Error("填充后请求应该被允许")
    }
}

func TestPriorityQueue(t *testing.T) {
    pq := NewPriorityQueue(100)

    req1 := &Request{ID: "1", Priority: PriorityNormal}
    req2 := &Request{ID: "2", Priority: PriorityHigh}
    req3 := &Request{ID: "3", Priority: PriorityLow}

    pq.Enqueue(req1, req1.Priority)
    pq.Enqueue(req2, req2.Priority)
    pq.Enqueue(req3, req3.Priority)

    // 应该先得到高优先级
    got := pq.Dequeue()
    if got.ID != "2" {
        t.Errorf("预期请求2, 得到 %s", got.ID)
    }

    // 然后普通
    got = pq.Dequeue()
    if got.ID != "1" {
        t.Errorf("预期请求1, 得到 %s", got.ID)
    }

    // 然后低
    got = pq.Dequeue()
    if got.ID != "3" {
        t.Errorf("预期请求3, 得到 %s", got.ID)
    }
}

func TestRetryHandler(t *testing.T) {
    handler := NewRetryHandler(3, 100*time.Millisecond, 1*time.Second)

    // 测试退避计算
    delays := []time.Duration{
        handler.GetBackoffDelay(0),
        handler.GetBackoffDelay(1),
        handler.GetBackoffDelay(2),
    }

    // 延迟应该增加
    if delays[1] < delays[0] {
        t.Error("退避延迟应该增加")
    }
    if delays[2] < delays[1] {
        t.Error("退避延迟应该增加")
    }

    // 测试应该重试
    if !handler.ShouldRetry(0, 429, nil) {
        t.Error("应该在429上重试")
    }
    if !handler.ShouldRetry(0, 500, nil) {
        t.Error("应该在500上重试")
    }
    if handler.ShouldRetry(0, 404, nil) {
        t.Error("不应该在404上重试")
    }
}
```

## 生产考虑

### 1. 优雅关闭
```go
// 处理SIGTERM和SIGINT
signalChan := make(chan os.Signal, 1)
signal.Notify(signalChan, syscall.SIGTERM, syscall.SIGINT)

<-signalChan

ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

if err := d.Shutdown(ctx); err != nil {
    log.Fatal("关闭失败:", err)
}
```

### 2. 监控
```go
// 通过Prometheus暴露指标
import "github.com/prometheus/client_golang/prometheus"

var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_dispatcher_requests_total",
            Help: "请求总数",
        },
        []string{"supplier"},
    )
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_dispatcher_request_duration_seconds",
            Help:    "请求持续时间（秒）",
            Buckets: prometheus.DefBuckets,
        },
        []string{"supplier"},
    )
)
```

### 3. 日志记录
```go
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

// 使用结构化日志
logger.Info("请求已提交",
    zap.String("request_id", req.ID),
    zap.String("supplier", req.Supplier),
    zap.Int("priority", req.Priority),
)
```

## 总结

我们已经实现了一个生产就绪的HTTP Dispatcher，具有：

✅ **限流** - 每供应商令牌桶算法
✅ **连接池** - 每供应商池配置
✅ **优先级队列** - 请求优先级
✅ **重试逻辑** - 带抖动的指数退避
✅ **指标** - 全面的指标收集
✅ **优雅关闭** - 干净关闭支持

**下一篇**：[真实案例研究和性能改进](/blog/zh/2026/02/15/http-dispatcher-4-case-studies.html)

---

## 推荐资源

- [Go net/http文档](https://pkg.go.dev/net/http)
- [生产就绪的Go服务](https://github.com/ardanlabs/service)
- [在Go中构建连接池](https://www.ardanlabs.com/blog/2019/05/connection-pooling-in-go.html)

---

## 系列导航

**HTTP Dispatcher系列**：
1. [什么是HTTP Dispatcher及为什么需要](/blog/zh/2026/02/09/http-dispatcher-1-what-is-http-dispatcher.html)
2. [HTTP Dispatcher如何解决限流和连接池](/blog/zh/2026/02/11/http-dispatcher-2-rate-limiting-connection-pooling.html)
3. 在Go中实现HTTP Dispatcher ← 你在这里
4. [真实案例研究和性能改进](/blog/zh/2026/02/15/http-dispatcher-4-case-studies.html)

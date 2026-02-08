---
layout: post
title: "HTTP Dispatcher Series (3): Implementing HTTP Dispatcher in Go"
date: 2026-02-13 10:00:00 +0000
categories: [developer-experience, go, api-integration]
tags: [http-dispatcher, go, implementation, tutorial]
author: "HotelByte Team"
description: "Step-by-step guide to implementing HTTP Dispatcher in Go. Complete code examples showing rate limiting, connection pooling, priority queues, and production-ready patterns for hotel API integration."
reading_time: "15 minutes"
lang: en
---

Now that we understand what HTTP Dispatcher does and how it solves rate limiting and connection pooling, let's implement one in Go.

## Project Structure

```
http-dispatcher/
├── cmd/
│   └── example/
│       └── main.go
├── pkg/
│   ├── dispatcher.go         # Main dispatcher
│   ├── ratelimiter.go        # Rate limiting
│   ├── pool.go               # Connection pooling
│   ├── priority.go           # Priority queue
│   ├── retry.go              # Retry logic
│   └── metrics.go            # Metrics collection
├── go.mod
└── README.md
```

## Step 1: Core Types and Configuration

```go
// pkg/dispatcher.go
package dispatcher

import (
    "context"
    "sync"
    "time"
)

// Priority levels
const (
    PriorityHighest = iota + 1
    PriorityHigh
    PriorityNormal
    PriorityLow
    PriorityLowest
)

// Request represents a supplier API request
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

// Response represents the API response
type Response struct {
    StatusCode int
    Body       []byte
    Headers    http.Header
    Duration   time.Duration
    FromCache  bool
}

// SupplierConfig holds supplier-specific settings
type SupplierConfig struct {
    BaseURL             string
    RateLimit          float64          // Requests per second
    MaxIdleConns       int
    MaxConnsPerHost    int
    ConnectionTimeout  time.Duration
    IdleTimeout        time.Duration
    RetryAttempts      int
    RetryBaseDelay     time.Duration
}

// Config is the dispatcher configuration
type Config struct {
    Suppliers       map[string]SupplierConfig
    MaxQueueSize    int
    WorkerCount     int
    MetricsEnabled  bool
}

// HTTPDispatcher is the main dispatcher
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

## Step 2: Rate Limiter Implementation

```go
// pkg/ratelimiter.go
package dispatcher

import (
    "sync"
    "time"
)

// TokenBucketRateLimiter implements token bucket algorithm
type TokenBucketRateLimiter struct {
    capacity  float64
    rate      float64          // Tokens added per second
    tokens    float64
    lastRefill time.Time
    mu        sync.Mutex
}

// NewTokenBucketRateLimiter creates a new rate limiter
func NewTokenBucketRateLimiter(capacity int, rate float64) *TokenBucketRateLimiter {
    return &TokenBucketRateLimiter{
        capacity:  float64(capacity),
        rate:      rate,
        tokens:    float64(capacity),
        lastRefill: time.Now(),
    }
}

// Allow checks if a request is allowed
func (tb *TokenBucketRateLimiter) Allow() bool {
    tb.mu.Lock()
    defer tb.mu.Unlock()

    now := time.Now()
    elapsed := now.Sub(tb.lastRefill).Seconds()
    tb.lastRefill = now

    // Refill tokens
    tb.tokens += elapsed * tb.rate
    if tb.tokens > tb.capacity {
        tb.tokens = tb.capacity
    }

    // Check if we have tokens
    if tb.tokens >= 1.0 {
        tb.tokens -= 1.0
        return true
    }

    return false
}

// RateLimiter manages multiple supplier rate limits
type RateLimiter struct {
    limiters map[string]*TokenBucketRateLimiter
    config   map[string]SupplierConfig
    mu       sync.RWMutex
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(config map[string]SupplierConfig) *RateLimiter {
    rl := &RateLimiter{
        limiters: make(map[string]*TokenBucketRateLimiter),
        config:   config,
    }

    for supplier, cfg := range config {
        rl.limiters[supplier] = NewTokenBucketRateLimiter(
            int(cfg.RateLimit)*10, // Allow burst up to 10x rate
            cfg.RateLimit,
        )
    }

    return rl
}

// Allow checks if request is allowed for supplier
func (rl *RateLimiter) Allow(supplier string) bool {
    rl.mu.RLock()
    limiter, exists := rl.limiters[supplier]
    rl.mu.RUnlock()

    if !exists {
        return true // No rate limiting if not configured
    }

    return limiter.Allow()
}

// GetWaitTime returns estimated wait time for next request
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

    // Estimate wait time based on rate
    rl.mu.RLock()
    rate := rl.config[supplier].RateLimit
    rl.mu.RUnlock()

    return time.Duration(float64(time.Second) / rate)
}
```

## Step 3: Connection Pool Manager

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

// PoolManager manages HTTP connection pools per supplier
type PoolManager struct {
    clients map[string]*http.Client
    configs map[string]SupplierConfig
    mu      sync.RWMutex
}

// NewPoolManager creates a new pool manager
func NewPoolManager(configs map[string]SupplierConfig) *PoolManager {
    pm := &PoolManager{
        clients: make(map[string]*http.Client),
        configs: configs,
    }

    // Initialize pools for all suppliers
    for supplier, cfg := range configs {
        pm.createPool(supplier, cfg)
    }

    return pm
}

// createPool creates a new HTTP client for supplier
func (pm *PoolManager) createPool(supplier string, cfg SupplierConfig) {
    transport := &http.Transport{
        // Dial context with timeout
        DialContext: (&net.Dialer{
            Timeout:   cfg.ConnectionTimeout,
            KeepAlive: 30 * time.Second,
        }).DialContext,

        // TLS configuration
        TLSClientConfig: &tls.Config{
            InsecureSkipVerify: false,
            MinVersion:         tls.VersionTLS12,
            NextProtos:         []string{"h2", "http/1.1"},
        },

        // Connection pooling
        MaxIdleConns:        200,                     // Total idle connections
        MaxIdleConnsPerHost: cfg.MaxIdleConns,       // Per supplier
        MaxConnsPerHost:     cfg.MaxConnsPerHost,    // Max active connections
        IdleConnTimeout:     cfg.IdleTimeout,
        DisableKeepAlives:   false,
        DisableCompression:  false,

        // Response header timeout
        ResponseHeaderTimeout: cfg.ConnectionTimeout,

        // Force HTTP/2 if supported
        ForceAttemptHTTP2: true,
    }

    client := &http.Client{
        Transport: transport,
        Timeout:   cfg.ConnectionTimeout,
        CheckRedirect: func(req *http.Request, via []*http.Request) error {
            // Follow up to 10 redirects
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

// GetClient returns the HTTP client for a supplier
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

// GetStats returns pool statistics for a supplier
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

// PoolStats holds pool statistics
type PoolStats struct {
    MaxIdleConns          int
    MaxConnsPerHost       int
    IdleConnTimeout       time.Duration
    ResponseHeaderTimeout time.Duration
}
```

## Step 4: Priority Queue

```go
// pkg/priority.go
package dispatcher

import (
    "container/heap"
    "sync"
    "time"
)

// RequestItem represents a request in the priority queue
type RequestItem struct {
    Request    *Request
    Priority   int
    SubmitTime time.Time
    Index      int
}

// PriorityQueue implements heap.Interface
type PriorityQueue struct {
    items []*RequestItem
    mu    sync.RWMutex
    cond  *sync.Cond
}

// NewPriorityQueue creates a new priority queue
func NewPriorityQueue(maxSize int) *PriorityQueue {
    pq := &PriorityQueue{
        items: make([]*RequestItem, 0, maxSize),
    }
    pq.cond = sync.NewCond(&pq.mu)
    return pq
}

// Len returns the length of the queue
func (pq *PriorityQueue) Len() int {
    pq.mu.RLock()
    defer pq.mu.RUnlock()
    return len(pq.items)
}

// Less compares two items
func (pq *PriorityQueue) Less(i, j int) bool {
    // Higher priority (lower number) comes first
    if pq.items[i].Priority != pq.items[j].Priority {
        return pq.items[i].Priority < pq.items[j].Priority
    }
    // FIFO for same priority
    return pq.items[i].SubmitTime.Before(pq.items[j].SubmitTime)
}

// Swap swaps two items
func (pq *PriorityQueue) Swap(i, j int) {
    pq.items[i], pq.items[j] = pq.items[j], pq.items[i]
    pq.items[i].Index = i
    pq.items[j].Index = j
}

// Push adds an item to the queue
func (pq *PriorityQueue) Push(x interface{}) {
    n := len(pq.items)
    item := x.(*RequestItem)
    item.Index = n
    pq.items = append(pq.items, item)
}

// Pop removes an item from the queue
func (pq *PriorityQueue) Pop() interface{} {
    n := len(pq.items)
    item := pq.items[n-1]
    pq.items[n-1] = nil
    item.Index = -1
    pq.items = pq.items[:n-1]
    return item
}

// Enqueue adds a request to the queue
func (pq *PriorityQueue) Enqueue(req *Request, priority int) error {
    pq.mu.Lock()
    defer pq.mu.Unlock()

    // Check queue size (implement max size logic if needed)
    item := &RequestItem{
        Request:    req,
        Priority:   priority,
        SubmitTime: time.Now(),
    }

    heap.Push(pq, item)
    pq.cond.Signal()

    return nil
}

// Dequeue removes a request from the queue
func (pq *PriorityQueue) Dequeue() *Request {
    pq.mu.Lock()
    defer pq.mu.Unlock()

    for len(pq.items) == 0 {
        pq.cond.Wait()
    }

    item := heap.Pop(pq).(*RequestItem)
    return item.Request
}

// Peek returns the next request without removing it
func (pq *PriorityQueue) Peek() *Request {
    pq.mu.RLock()
    defer pq.mu.RUnlock()

    if len(pq.items) == 0 {
        return nil
    }

    return pq.items[0].Request
}

// Clear removes all items from the queue
func (pq *PriorityQueue) Clear() {
    pq.mu.Lock()
    defer pq.mu.Unlock()

    pq.items = make([]*RequestItem, 0)
}
```

## Step 5: Retry Handler

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

// RetryHandler implements exponential backoff retry logic
type RetryHandler struct {
    maxAttempts  int
    baseDelay    time.Duration
    maxDelay     time.Duration
    jitterFactor float64
}

// NewRetryHandler creates a new retry handler
func NewRetryHandler(maxAttempts int, baseDelay, maxDelay time.Duration) *RetryHandler {
    return &RetryHandler{
        maxAttempts:  maxAttempts,
        baseDelay:    baseDelay,
        maxDelay:     maxDelay,
        jitterFactor: 0.1, // 10% jitter
    }
}

// ShouldRetry determines if request should be retried
func (rh *RetryHandler) ShouldRetry(attempt int, statusCode int, err error) bool {
    if attempt >= rh.maxAttempts {
        return false
    }

    // Retry on server errors (5xx)
    if statusCode >= 500 && statusCode < 600 {
        return true
    }

    // Retry on rate limit (429)
    if statusCode == 429 {
        return true
    }

    // Retry on timeout errors
    if err != nil {
        if netErr, ok := err.(net.Error); ok {
            if netErr.Timeout() {
                return true
            }
        }
    }

    return false
}

// GetBackoffDelay calculates delay with exponential backoff and jitter
func (rh *RetryHandler) GetBackoffDelay(attempt int) time.Duration {
    // Exponential backoff: base * 2^attempt
    delay := float64(rh.baseDelay) * math.Pow(2, float64(attempt))

    // Cap at max delay
    if delay > float64(rh.maxDelay) {
        delay = float64(rh.maxDelay)
    }

    // Add jitter to avoid thundering herd
    jitter := delay * rh.jitterFactor * (2*rand.Float64() - 1)
    delay += jitter

    if delay < 0 {
        delay = float64(rh.baseDelay)
    }

    return time.Duration(delay)
}

// Execute performs request with retry logic
func (rh *RetryHandler) Execute(ctx context.Context, client *http.Client, req *http.Request) (*http.Response, error) {
    var lastErr error
    var lastResp *http.Response

    for attempt := 0; attempt < rh.maxAttempts; attempt++ {
        // Create request with context
        reqCopy := req.Clone(ctx)

        // Execute request
        resp, err := client.Do(reqCopy)
        lastResp = resp
        lastErr = err

        // Check if we should retry
        statusCode := 0
        if resp != nil {
            statusCode = resp.StatusCode
        }

        if !rh.ShouldRetry(attempt, statusCode, err) {
            break
        }

        // Log retry
        if attempt < rh.maxAttempts-1 {
            delay := rh.GetBackoffDelay(attempt)
            logRetry(req.URL.String(), attempt, statusCode, delay)

            // Close response body before retry
            if resp != nil {
                resp.Body.Close()
            }

            // Wait with context cancellation
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
    // Implement logging
    fmt.Printf("Retry %d for %s (status: %d, delay: %v)\n",
        attempt+1, url, statusCode, delay)
}
```

## Step 6: Main Dispatcher

```go
// pkg/dispatcher.go (continued)

// NewHTTPDispatcher creates a new HTTP dispatcher
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

    // Start worker pool
    d.startWorkers()

    return d, nil
}

// startWorkers starts the worker pool
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

// Submit submits a request to the dispatcher
func (d *HTTPDispatcher) Submit(ctx context.Context, req *Request) (*Response, error) {
    start := time.Now()

    // Enqueue request
    err := d.priorityQueue.Enqueue(req, req.Priority)
    if err != nil {
        return nil, fmt.Errorf("enqueue failed: %w", err)
    }

    // Create result channel
    resultChan := make(chan *Result, 1)

    // Process request (in a real implementation, this would be done by workers)
    go func() {
        response, err := d.processRequest(ctx, req)
        resultChan <- &Result{
            Response: response,
            Error:    err,
        }
    }()

    // Wait for result or context cancellation
    select {
    case result := <-resultChan:
        duration := time.Since(start)

        // Record metrics
        d.metrics.Record(req.Supplier, duration, result.Response.StatusCode)

        return result.Response, result.Error
    case <-ctx.Done():
        return nil, ctx.Err()
    }
}

// processRequest processes a single request
func (d *HTTPDispatcher) processRequest(ctx context.Context, req *Request) (*Response, error) {
    // Wait for rate limit
    for {
        if d.rateLimiter.Allow(req.Supplier) {
            break
        }
        time.Sleep(10 * time.Millisecond)
    }

    // Get HTTP client from pool
    client := d.poolManager.GetClient(req.Supplier)

    // Create HTTP request
    httpReq, err := http.NewRequestWithContext(ctx, req.Method, req.URL, bytes.NewReader(req.Body))
    if err != nil {
        return nil, fmt.Errorf("create request failed: %w", err)
    }

    // Set headers
    for k, v := range req.Headers {
        httpReq.Header.Set(k, v)
    }

    // Execute with retry
    httpResp, err := d.retryHandler.Execute(ctx, client, httpReq)
    if err != nil {
        return nil, fmt.Errorf("request failed: %w", err)
    }
    defer httpResp.Body.Close()

    // Read response body
    body, err := io.ReadAll(httpResp.Body)
    if err != nil {
        return nil, fmt.Errorf("read response failed: %w", err)
    }

    return &Response{
        StatusCode: httpResp.StatusCode,
        Body:       body,
        Headers:    httpResp.Header,
        Duration:   time.Since(time.Now()),
        FromCache:  false,
    }, nil
}

// Shutdown gracefully shuts down the dispatcher
func (d *HTTPDispatcher) Shutdown(ctx context.Context) error {
    close(d.shutdownChan)

    // Wait for workers to finish (with timeout)
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

// GetMetrics returns current metrics
func (d *HTTPDispatcher) GetMetrics() *Metrics {
    return d.metrics.Snapshot()
}

// Result represents the result of a request
type Result struct {
    Response *Response
    Error    error
}

// Worker processes requests from the queue
type Worker struct {
    ID         int
    Dispatcher *HTTPDispatcher
    stopChan   chan struct{}
}

// Run starts the worker
func (w *Worker) Run() {
    w.stopChan = make(chan struct{})

    for {
        select {
        case <-w.stopChan:
            return
        default:
            // Dequeue next request
            req := w.Dispatcher.priorityQueue.Dequeue()
            if req == nil {
                continue
            }

            // Process request
            ctx, cancel := context.WithTimeout(context.Background(), req.Timeout)
            w.Dispatcher.processRequest(ctx, req)
            cancel()
        }
    }
}

// Stop stops the worker
func (w *Worker) Stop() {
    close(w.stopChan)
}
```

## Step 7: Metrics Collector

```go
// pkg/metrics.go
package dispatcher

import (
    "sync"
    "time"
)

// MetricsCollector collects and aggregates metrics
type MetricsCollector struct {
    requests map[string]*SupplierMetrics
    mu       sync.RWMutex
}

// SupplierMetrics holds metrics for a supplier
type SupplierMetrics struct {
    TotalRequests      int64
    SuccessRequests    int64
    FailedRequests     int64
    RateLimitedRequests int64
    TotalDuration      time.Duration
    MinDuration        time.Duration
    MaxDuration        time.Duration
}

// Metrics represents a snapshot of all metrics
type Metrics struct {
    Suppliers map[string]*SupplierMetrics
}

// NewMetricsCollector creates a new metrics collector
func NewMetricsCollector() *MetricsCollector {
    return &MetricsCollector{
        requests: make(map[string]*SupplierMetrics),
    }
}

// Record records a request
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

// Snapshot returns a snapshot of current metrics
func (mc *MetricsCollector) Snapshot() *Metrics {
    mc.mu.RLock()
    defer mc.mu.RUnlock()

    snapshot := &Metrics{
        Suppliers: make(map[string]*SupplierMetrics),
    }

    for supplier, metrics := range mc.requests {
        // Deep copy metrics
        copy := *metrics
        snapshot.Suppliers[supplier] = &copy
    }

    return snapshot
}

// Reset clears all metrics
func (mc *MetricsCollector) Reset() {
    mc.mu.Lock()
    defer mc.mu.Unlock()

    mc.requests = make(map[string]*SupplierMetrics)
}
```

## Step 8: Example Usage

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
    // Configure suppliers
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

    // Create dispatcher
    d, err := dispatcher.NewHTTPDispatcher(config)
    if err != nil {
        panic(err)
    }
    defer d.Shutdown(context.Background())

    // Submit requests
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
                fmt.Printf("Request %s failed: %v\n", r.ID, err)
                return
            }

            fmt.Printf("Request %s: status=%d, duration=%v\n",
                r.ID, resp.StatusCode, resp.Duration)
        }(req)
    }

    // Wait for completion
    time.Sleep(30 * time.Second)

    // Print metrics
    metrics := d.GetMetrics()
    for supplier, m := range metrics.Suppliers {
        fmt.Printf("\nSupplier: %s\n", supplier)
        fmt.Printf("  Total: %d\n", m.TotalRequests)
        fmt.Printf("  Success: %d\n", m.SuccessRequests)
        fmt.Printf("  Failed: %d\n", m.FailedRequests)
        fmt.Printf("  Rate Limited: %d\n", m.RateLimitedRequests)
        avgDuration := float64(m.TotalDuration) / float64(m.TotalRequests) / float64(time.Millisecond)
        fmt.Printf("  Avg Duration: %.2fms\n", avgDuration)
    }
}
```

## Testing

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

    // First 10 should all be allowed
    for i := 0; i < 10; i++ {
        if !limiter.Allow() {
            t.Errorf("Request %d should be allowed", i)
        }
    }

    // Next one should be rate limited
    if limiter.Allow() {
        t.Error("Request should be rate limited")
    }

    // Wait for refill
    time.Sleep(250 * time.Millisecond)

    // Should be allowed again
    if !limiter.Allow() {
        t.Error("Request should be allowed after refill")
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

    // Should get high priority first
    got := pq.Dequeue()
    if got.ID != "2" {
        t.Errorf("Expected request 2, got %s", got.ID)
    }

    // Then normal
    got = pq.Dequeue()
    if got.ID != "1" {
        t.Errorf("Expected request 1, got %s", got.ID)
    }

    // Then low
    got = pq.Dequeue()
    if got.ID != "3" {
        t.Errorf("Expected request 3, got %s", got.ID)
    }
}

func TestRetryHandler(t *testing.T) {
    handler := NewRetryHandler(3, 100*time.Millisecond, 1*time.Second)

    // Test backoff calculation
    delays := []time.Duration{
        handler.GetBackoffDelay(0),
        handler.GetBackoffDelay(1),
        handler.GetBackoffDelay(2),
    }

    // Delays should increase
    if delays[1] < delays[0] {
        t.Error("Backoff delay should increase")
    }
    if delays[2] < delays[1] {
        t.Error("Backoff delay should increase")
    }

    // Test should retry
    if !handler.ShouldRetry(0, 429, nil) {
        t.Error("Should retry on 429")
    }
    if !handler.ShouldRetry(0, 500, nil) {
        t.Error("Should retry on 500")
    }
    if handler.ShouldRetry(0, 404, nil) {
        t.Error("Should not retry on 404")
    }
}
```

## Production Considerations

### 1. Graceful Shutdown
```go
// Handle SIGTERM and SIGINT
signalChan := make(chan os.Signal, 1)
signal.Notify(signalChan, syscall.SIGTERM, syscall.SIGINT)

<-signalChan

ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

if err := d.Shutdown(ctx); err != nil {
    log.Fatal("Shutdown failed:", err)
}
```

### 2. Monitoring
```go
// Expose metrics via Prometheus
import "github.com/prometheus/client_golang/prometheus"

var (
    requestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_dispatcher_requests_total",
            Help: "Total number of requests",
        },
        []string{"supplier"},
    )
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_dispatcher_request_duration_seconds",
            Help:    "Request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"supplier"},
    )
)
```

### 3. Logging
```go
import "go.uber.org/zap"

logger, _ := zap.NewProduction()
defer logger.Sync()

// Use structured logging
logger.Info("Request submitted",
    zap.String("request_id", req.ID),
    zap.String("supplier", req.Supplier),
    zap.Int("priority", req.Priority),
)
```

## Summary

We've implemented a production-ready HTTP Dispatcher with:

✅ **Rate Limiting** - Token bucket algorithm per supplier
✅ **Connection Pooling** - Per-supplier pool configuration
✅ **Priority Queue** - Request prioritization
✅ **Retry Logic** - Exponential backoff with jitter
✅ **Metrics** - Comprehensive metrics collection
✅ **Graceful Shutdown** - Clean shutdown support

**Next**: [Real-World Case Studies and Performance Improvements](/blog/2026/02/15/http-dispatcher-4-case-studies.html)

---

## Recommended Resources

- [Go net/http Documentation](https://pkg.go.dev/net/http)
- [Production-Ready Go Services](https://github.com/ardanlabs/service)
- [Building a Connection Pool in Go](https://www.ardanlabs.com/blog/2019/05/connection-pooling-in-go.html)

---

## Series Navigation

**HTTP Dispatcher Series**:
1. [What is HTTP Dispatcher and Why It's Needed](/blog/2026/02/09/http-dispatcher-1-what-is-http-dispatcher.html)
2. [How HTTP Dispatcher Solves Rate Limiting and Connection Pooling](/blog/2026/02/11/http-dispatcher-2-rate-limiting-connection-pooling.html)
3. Implementing HTTP Dispatcher in Go ← You are here
4. [Real-World Case Studies and Performance Improvements](/blog/2026/02/15/http-dispatcher-4-case-studies.html)

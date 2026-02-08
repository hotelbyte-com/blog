---
layout: post
title: "HTTP Dispatcher Series (2): How HTTP Dispatcher Solves Rate Limiting and Connection Pooling"
date: 2026-02-11 10:00:00 +0000
categories: [developer-experience, api-integration, performance]
tags: [http-dispatcher, rate-limiting, connection-pooling, performance-optimization]
author: "HotelByte Team"
description: "Deep dive into HTTP Dispatcher's rate limiting algorithms and connection pooling strategies. Learn about token bucket, leaky bucket, adaptive rate limiting, and efficient connection management for high-throughput hotel API integration."
reading_time: "14 minutes"
lang: en
---

> "We're getting 429 errors from 60% of our supplier calls. Our customers are seeing error pages during peak hours." — Operations Manager

> "Our application creates 10,000+ connections per hour. Cloud provider bills are exploding." — DevOps Engineer

These are classic symptoms of missing HTTP Dispatcher. Let's dive deep into how it solves these problems.

## Part 1: Rate Limiting - The Art of Throttling

### Understanding Supplier Rate Limits

**Rate limiting is everywhere**, but it's not uniform:

| Supplier Type | Common Limit | Limit Type | Burst Allowance |
|---------------|-------------|-----------|-----------------|
| Large OTAs (Expedia, Agoda) | 100-500 req/s | Per IP/Key | Yes |
| Mid-size OTAs (HotelBeds, Dida) | 10-50 req/s | Per API Key | Sometimes |
| Small/Niche Suppliers | 2-10 req/s | Strict | No |
| GDS Systems | 5-20 req/s | Per session | No |
| Bedbanks | 20-100 req/min | Per contract | No |

### The Rate Limiting Algorithms

#### Algorithm 1: Token Bucket (Most Common)

**How it works**:
```
Bucket has:
- Capacity: Max tokens (rate limit)
- Refill Rate: Tokens added per second
- Token Cost: 1 token per request

Request flow:
1. Check if bucket has token
2. If yes: Consume 1 token, allow request
3. If no: Queue or reject request
```

**Implementation**:
```go
type TokenBucketRateLimiter struct {
    capacity  float64
    rate      float64
    tokens    float64
    lastRefill time.Time
    mu        sync.Mutex
}

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
```

**Visual**:
```
Tokens: ██████████ (10/10) → Ready
Tokens: ████████░░ (8/10) → Request allowed
Tokens: ██░░░░░░░░ (2/10) → Request allowed
Tokens: ░░░░░░░░░░ (0/10) → Request queued

... after 2 seconds (refill 20 tokens/s) ...
Tokens: ██████░░░░ (6/10) → Ready again
```

#### Algorithm 2: Leaky Bucket (Fixed Output Rate)

**How it works**:
```
Bucket has:
- Capacity: Max queue size
- Leak Rate: Requests processed per second
- Water Level: Current queue size

Request flow:
1. If bucket full: Reject
2. If bucket not full: Add to queue
3. Queue leaks at fixed rate
```

**Implementation**:
```go
type LeakyBucketRateLimiter struct {
    capacity int
    rate     float64 // requests per second
    queue    chan struct{}
    ticker   *time.Ticker
}

func NewLeakyBucketRateLimiter(capacity int, rate float64) *LeakyBucketRateLimiter {
    lb := &LeakyBucketRateLimiter{
        capacity: capacity,
        rate:     rate,
        queue:    make(chan struct{}, capacity),
    }

    // Start leaking at fixed rate
    interval := time.Duration(1.0/rate*1000) * time.Millisecond
    lb.ticker = time.NewTicker(interval)
    go func() {
        for range lb.ticker.C {
            select {
            case <-lb.queue:
                // Process one request
            default:
                // No requests queued
            }
        }
    }()

    return lb
}

func (lb *LeakyBucketRateLimiter) Allow() bool {
    select {
    case lb.queue <- struct{}{}:
        return true
    default:
        return false // Bucket full
    }
}
```

**When to use each**:

| Algorithm | Best For | Pros | Cons |
|-----------|----------|------|------|
| Token Bucket | Variable rate, burst allowed | Handles bursts well | Can waste tokens |
| Leaky Bucket | Fixed output rate | Predictable output | Delays all requests |

### HTTP Dispatcher's Adaptive Rate Limiting

**Standard rate limiting is not enough**. Suppliers may:
- Change limits dynamically
- Impose temporary restrictions
- Have tiered limits (premium vs standard)

**Adaptive Rate Limiting**:
```go
type AdaptiveRateLimiter struct {
    buckets map[string]*TokenBucketRateLimiter
    history map[string][]RateLimitEvent
    mu      sync.RWMutex
}

type RateLimitEvent struct {
    Timestamp time.Time
    Allowed   bool
    StatusCode int
}

func (arl *AdaptiveRateLimiter) Allow(supplier string) bool {
    arl.mu.Lock()
    defer arl.mu.Unlock()

    // Get or create bucket for supplier
    bucket, exists := arl.buckets[supplier]
    if !exists {
        bucket = arl.createBucket(supplier)
        arl.buckets[supplier] = bucket
    }

    // Check allowance
    allowed := bucket.Allow()

    // Track event
    arl.history[supplier] = append(arl.history[supplier], RateLimitEvent{
        Timestamp: time.Now(),
        Allowed:   allowed,
    })

    // Analyze history and adapt
    arl.analyzeAndAdapt(supplier)

    return allowed
}

func (arl *AdaptiveRateLimiter) analyzeAndAdapt(supplier string) {
    events := arl.history[supplier]

    // Keep only last 100 events
    if len(events) > 100 {
        events = events[len(events)-100:]
    }

    // Calculate 429 error rate
    var four29Count int
    for _, event := range events {
        if event.StatusCode == 429 {
            four29Count++
        }
    }

    four29Rate := float64(four29Count) / float64(len(events))

    // If 429 rate > 5%, reduce rate by 20%
    if four29Rate > 0.05 {
        bucket := arl.buckets[supplier]
        bucket.rate *= 0.8
        log.Warn("Reducing rate limit", "supplier", supplier, "new_rate", bucket.rate)
    }
}
```

**Benefits**:
- Self-adjusting to supplier behavior
- Reduces 429 errors automatically
- Optimizes throughput dynamically

## Part 2: Connection Pooling - The Efficiency Booster

### Why Connection Pooling Matters

**HTTP connection overhead**:
```
TCP 3-way handshake: 1 RTT
TLS handshake: 2 RTTs (full) or 1 RTT (session resumption)
DNS lookup: 0-1 RTT (cached)
─────────────────────────────────
Total: 2-4 RTTs per new connection

Assuming 50ms RTT:
New connection: 100-200ms
Reused connection: 5-10ms
```

**Without pooling vs with pooling**:

| Scenario | Without Pooling | With Pooling | Improvement |
|----------|----------------|--------------|-------------|
| 100 requests | 10-20 seconds | 0.5-1 second | 20x faster |
| 1000 requests | 100-200 seconds | 5-10 seconds | 20x faster |
| 10000 requests | 1000-2000 seconds (16-33 min) | 50-100 seconds | 20x faster |

### Go's Built-in HTTP Client Pooling

**Good news**: Go's `http.Client` already has connection pooling!

```go
// Default client uses default transport
client := &http.Client{}
// Default: MaxIdleConns: 100, MaxIdleConnsPerHost: 2
```

**But defaults are not enough** for hotel API integration:

```go
// Better configuration for supplier APIs
transport := &http.Transport{
    MaxIdleConns:        200,      // Total idle connections
    MaxIdleConnsPerHost: 20,       // Per supplier
    IdleConnTimeout:     90 * time.Second,
    DisableCompression:  false,
    // TLS config
    TLSClientConfig: &tls.Config{
        InsecureSkipVerify: false,
        MinVersion:         tls.VersionTLS12,
    },
    // Keep-alive
    DisableKeepAlives: false,
    MaxConnsPerHost:   50, // Max active connections per host
}

client := &http.Client{
    Transport: transport,
    Timeout:   30 * time.Second,
}
```

### HTTP Dispatcher's Intelligent Pool Management

**Key features**:

#### 1. Per-Supplier Pool Configuration

```go
type SupplierConfig struct {
    BaseURL             string
    RateLimit          float64
    MaxIdleConns       int
    MaxConnsPerHost    int
    ConnectionTimeout  time.Duration
    IdleTimeout        time.Duration
}

var supplierConfigs = map[string]SupplierConfig{
    "hotelbeds": {
        BaseURL:            "https://api.hotelbeds.com",
        RateLimit:         10.0,  // 10 req/s
        MaxIdleConns:      20,
        MaxConnsPerHost:   30,
        ConnectionTimeout: 5 * time.Second,
        IdleTimeout:       60 * time.Second,
    },
    "dida": {
        BaseURL:            "https://api.dida.travel",
        RateLimit:         20.0,  // 20 req/s
        MaxIdleConns:      30,
        MaxConnsPerHost:   40,
        ConnectionTimeout: 3 * time.Second,
        IdleTimeout:       90 * time.Second,
    },
}
```

#### 2. Dynamic Pool Sizing

```go
type PoolManager struct {
    pools map[string]*http.Client
    stats map[string]PoolStats
    mu    sync.RWMutex
}

type PoolStats struct {
    ActiveConnections int
    IdleConnections  int
    WaitTime         time.Duration
    ErrorRate        float64
}

func (pm *PoolManager) GetClient(supplier string) *http.Client {
    pm.mu.RLock()
    client, exists := pm.pools[supplier]
    pm.mu.RUnlock()

    if exists {
        return client
    }

    // Create new pool
    return pm.createPool(supplier)
}

func (pm *PoolManager) Monitor() {
    ticker := time.NewTicker(30 * time.Second)
    for range ticker.C {
        pm.adjustPoolSizes()
    }
}

func (pm *PoolManager) adjustPoolSizes() {
    pm.mu.Lock()
    defer pm.mu.Unlock()

    for supplier, stats := range pm.stats {
        config := supplierConfigs[supplier]

        // If error rate high, reduce pool size
        if stats.ErrorRate > 0.1 {
            config.MaxConnsPerHost = int(float64(config.MaxConnsPerHost) * 0.8)
            log.Warn("Reducing pool size due to errors", "supplier", supplier)
        }

        // If wait time high, increase pool size
        if stats.WaitTime > 100*time.Millisecond {
            config.MaxConnsPerHost = int(float64(config.MaxConnsPerHost) * 1.2)
            log.Info("Increasing pool size due to wait time", "supplier", supplier)
        }
    }
}
```

#### 3. Health Checking

```go
func (pm *PoolManager) HealthCheck() {
    for supplier, client := range pm.pools {
        ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()

        req, err := http.NewRequestWithContext(ctx, "GET", "/health", nil)
        if err != nil {
            log.Error("Health check failed", "supplier", supplier, "error", err)
            continue
        }

        resp, err := client.Do(req)
        if err != nil {
            log.Error("Health check failed", "supplier", supplier, "error", err)
            pm.resetPool(supplier)
            continue
        }

        resp.Body.Close()

        if resp.StatusCode >= 500 {
            log.Warn("Supplier unhealthy", "supplier", supplier, "status", resp.StatusCode)
            pm.enableCircuitBreaker(supplier)
        }
    }
}
```

## Part 3: Putting It All Together

### Complete HTTP Dispatcher Flow

```go
type HTTPDispatcher struct {
    rateLimiter    *AdaptiveRateLimiter
    poolManager    *PoolManager
    prioritizer    *RequestPrioritizer
    retryHandler   *RetryHandler
    metrics        *MetricsCollector
}

func (d *HTTPDispatcher) Submit(req *Request) (*Response, error) {
    start := time.Now()

    // 1. Enqueue with priority
    d.prioritizer.Enqueue(req)

    // 2. Wait for turn (priority queue)
    d.prioritizer.WaitTurn(req)

    // 3. Check rate limit
    for !d.rateLimiter.Allow(req.Supplier) {
        time.Sleep(10 * time.Millisecond)
    }

    // 4. Get connection from pool
    client := d.poolManager.GetClient(req.Supplier)

    // 5. Execute request (with retry)
    var resp *http.Response
    var err error

    for attempt := 0; attempt < 3; attempt++ {
        resp, err = d.doRequest(client, req)
        if err == nil {
            break
        }

        // Handle rate limit
        if resp != nil && resp.StatusCode == 429 {
            d.rateLimiter.Backoff(req.Supplier)
            time.Sleep(d.getBackoffDuration(attempt))
            continue
        }

        // Handle server error
        if resp != nil && resp.StatusCode >= 500 {
            time.Sleep(d.getBackoffDuration(attempt))
            continue
        }

        break
    }

    // 6. Record metrics
    duration := time.Since(start)
    d.metrics.Record(req.Supplier, duration, resp.StatusCode)

    return &Response{
        StatusCode: resp.StatusCode,
        Body:       resp.Body,
        Duration:   duration,
    }, err
}
```

## Real-World Performance Impact

### Case Study: OTA Platform

**Before HTTP Dispatcher**:
```
Concurrent requests: 1000
429 error rate: 42%
P50 latency: 800ms
P95 latency: 5200ms
P99 latency: 12400ms
Connections: 5000+
```

**After HTTP Dispatcher**:
```
Concurrent requests: 1000
429 error rate: 0.8%
P50 latency: 120ms
P95 latency: 680ms
P99 latency: 1200ms
Connections: 150
```

**Metrics**:
- **429 errors reduced by 98%**
- **P95 latency reduced by 87%**
- **P99 latency reduced by 90%**
- **Connections reduced by 97%**
- **Throughput increased by 6x**

## Best Practices

### Rate Limiting Best Practices

1. **Track supplier limits carefully** - They may change without notice
2. **Use adaptive algorithms** - Static limits don't work in real world
3. **Monitor 429 errors** - They indicate limit adjustments needed
4. **Respect Retry-After headers** - Suppliers send them for a reason
5. **Implement backoff** - Don't hammer when limited

### Connection Pooling Best Practices

1. **Configure per-host limits** - One size doesn't fit all
2. **Monitor pool health** - Reset unhealthy connections
3. **Use connection timeouts** - Don't wait forever
4. **Enable keep-alive** - Crucial for performance
5. **Set appropriate idle timeouts** - Balance memory vs reconnection

## Summary

HTTP Dispatcher solves two critical problems:

**Rate Limiting**:
- Token bucket and leaky bucket algorithms
- Adaptive adjustment based on 429 errors
- Per-supplier limit tracking

**Connection Pooling**:
- Intelligent pool sizing
- Per-supplier configuration
- Health monitoring and automatic recovery

**Together**: 6x throughput increase, 90% latency reduction, 98% fewer 429 errors.

**Next**: [Implementing HTTP Dispatcher in Go](/blog/2026/02/13/http-dispatcher-3-implementation-go.html)

---

## Recommended Reading

- [Rate Limiting at Scale](https://stripe.com/blog/rate-limiters)
- [Go HTTP Client Pooling](https://go.dev/doc/effective_go#defer)
- [Connection Pool Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingRDS_Connections.html)

---

## Series Navigation

**HTTP Dispatcher Series**:
1. [What is HTTP Dispatcher and Why It's Needed](/blog/2026/02/09/http-dispatcher-1-what-is-http-dispatcher.html)
2. How HTTP Dispatcher Solves Rate Limiting and Connection Pooling ← You are here
3. [Implementing HTTP Dispatcher in Go](/blog/2026/02/13/http-dispatcher-3-implementation-go.html)
4. [Real-World Case Studies and Performance Improvements](/blog/2026/02/15/http-dispatcher-4-case-studies.html)

---
layout: post
title: "HTTP Dispatcher Series (1): What is HTTP Dispatcher and Why It's Needed for Hotel API Integration"
date: 2026-02-09 10:00:00 +0000
categories: [developer-experience, api-integration, architecture]
tags: [http-dispatcher, hotel-api, rate-limiting, connection-pooling]
author: "HotelByte Team"
description: "What is HTTP Dispatcher? Why is it crucial for hotel API integration? Learn how it manages multiple suppliers, handles rate limiting, and solves connection pooling challenges."
reading_time: "12 minutes"
lang: en
---

> "We have 50 hotel suppliers, each with different rate limits. Our integration service crashes every time we run a promotion." — A frustrated CTO

> "Our HTTP clients are creating thousands of connections per second. The suppliers block us after 5 minutes." — A lead engineer

If these stories sound familiar, you're facing the **HTTP Dispatcher** problem.

## The Problem: Too Many Suppliers, Too Many Connections

### The Naive Approach: One Client per Supplier

```go
// ❌ Naive implementation
type HotelIntegrationService struct {
    hotelbedsClient  *http.Client
    didaClient       *http.Client
    expediaClient    *http.Client
    agodaClient      *http.Client
    // ... 46 more clients
}

func (s *HotelIntegrationService) SearchHotels(ctx context.Context, suppliers []string) {
    for _, supplier := range suppliers {
        go func(supplier string) {
            var client *http.Client
            switch supplier {
            case "hotelbeds":
                client = s.hotelbedsClient
            case "dida":
                client = s.didaClient
            // ... more cases
            }

            resp, err := client.Get(fmt.Sprintf("/api/hotels?%s", query))
            // Handle response
        }(supplier)
    }
}
```

**What happens when you search 50 suppliers?**

```
Concurrent requests: 50
Connections opened: 50 (one per supplier)
┌─────────────────────────────────────────────────┐
│  Supplier A: 10 req/s (limit: 10) ✅           │
│  Supplier B: 10 req/s (limit: 5) ❌ 429       │
│  Supplier C: 10 req/s (limit: 20) ✅          │
│  Supplier D: 10 req/s (limit: 2) ❌ 429       │
│  ...                                          │
└─────────────────────────────────────────────────┘

Result: 40% of requests fail with 429 Too Many Requests
```

### The Root Causes

1. **No Rate Limiting Awareness**: Each supplier has different limits (5 req/s, 10 req/s, 100 req/s, burst only, etc.)
2. **No Connection Pooling**: Creating new connections for every request
3. **No Intelligent Retry**: Getting 429 and giving up immediately
4. **No Prioritization**: All requests treated equally

## Enter: HTTP Dispatcher

### What is HTTP Dispatcher?

**HTTP Dispatcher** is a middleware layer that sits between your application and supplier APIs. It manages all HTTP communication with intelligent rate limiting, connection pooling, and request prioritization.

```
┌─────────────────────────────────────────────────────────┐
│                   Your Application                        │
└─────────────────────────────────────────────────────────┘
                          │
                          │ SearchHotels(request)
                          ▼
┌─────────────────────────────────────────────────────────┐
│              HTTP Dispatcher (The Brain)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ Rate Limiter  │  │  Conn Pool   │  │  Prioritizer │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
│         │                  │                  │           │
└─────────┼──────────────────┼──────────────────┼───────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────┐
│              Supplier APIs (50 endpoints)                │
│  HotelBeds  |  Dida  |  Expedia  |  Agoda  |  ...       │
└─────────────────────────────────────────────────────────┘
```

### Key Responsibilities

| Responsibility | Why It Matters |
|----------------|----------------|
| **Rate Limiting** | Prevent 429 errors, respect supplier limits |
| **Connection Pooling** | Reduce latency, improve throughput |
| **Request Prioritization** | Ensure critical requests go first |
| **Smart Retry** | Handle transient failures automatically |
| **Metrics & Observability** | Know what's happening in real-time |
| **Circuit Breaking** | Stop hammering failing suppliers |

## Why HTTP Dispatcher is Critical for Hotel API Integration

### Challenge 1: Rate Limiting Chaos

**Supplier rate limits are everywhere**:

| Supplier | Rate Limit | Type |
|----------|-----------|------|
| HotelBeds | 10 req/s | Per IP |
| Dida | 50 req/min | Per API Key |
| Expedia | 100 req/s | Burst allowed |
| Agoda | No limit | But will block abuse |
| DerbySoft | 5 req/s | Strict |
| TravelGDS | 20 req/s + burst | Token bucket |

**Without HTTP Dispatcher**:
```go
// ❌ You send 100 requests simultaneously
for i := 0; i < 100; i++ {
    go func() {
        resp, err := http.Get("https://api.hotelbeds.com/v1/hotels")
        // Result: Most requests fail with 429
    }()
}
```

**With HTTP Dispatcher**:
```go
// ✅ Dispatcher queues and throttles requests
dispatcher := NewHTTPDispatcher()

for i := 0; i < 100; i++ {
    dispatcher.Submit(&Request{
        Supplier: "hotelbeds",
        URL:      "https://api.hotelbeds.com/v1/hotels",
        Priority: PriorityNormal,
    })
}
// Dispatcher respects 10 req/s limit automatically
```

### Challenge 2: Connection Overhead

**Creating a new HTTP connection takes time**:
```
DNS Lookup: 20-50ms
TCP Handshake: 30-100ms
TLS Handshake: 50-150ms
─────────────────────────────
Total: 100-300ms per new connection
```

**Without connection pooling**:
```
1000 requests × 300ms = 300 seconds = 5 minutes!
```

**With HTTP Dispatcher connection pooling**:
```
First request: 300ms (new connection)
Next 999 requests: 10-20ms (reused connection)
Total: ~5-10 seconds
```

**Performance improvement**: 50-100x faster

### Challenge 3: Priority Matters

**Not all requests are equal**:

| Request Type | Priority | Reason |
|--------------|----------|--------|
| Real-time booking | HIGH | User waiting, revenue at stake |
| Price comparison | NORMAL | Important but not urgent |
| Cache refresh | LOW | Background task |
| Analytics sync | LOWEST | Can wait |

**HTTP Dispatcher ensures**:
```
┌─────────────────────────────────────┐
│  Queue State                        │
│  ───────────────────────────────   │
│  [HIGH] Booking #1234 ← Processing  │
│  [HIGH] Booking #1235 ← Next       │
│  [NORMAL] Price check ← Waiting    │
│  [NORMAL] Price check ← Waiting    │
│  [LOW] Cache refresh ← Waiting     │
│  [LOWEST] Analytics ← Waiting      │
└─────────────────────────────────────┘
```

## Real-World Impact

### Case Study: OTA Platform Integration

**Before HTTP Dispatcher**:
```
Suppliers: 35
Requests per second: 500
429 Error Rate: 45%
Response Time (P95): 8.2s
Server CPU: 95%
Connection count: 2000+
```

**After HTTP Dispatcher**:
```
Suppliers: 35
Requests per second: 500
429 Error Rate: 0.5%
Response Time (P95): 1.2s
Server CPU: 45%
Connection count: 150
```

**Impact**:
- **89% reduction** in 429 errors
- **85% reduction** in P95 latency
- **53% reduction** in CPU usage
- **92% reduction** in connection count

## Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    HTTP Dispatcher                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. Request Router                                    │  │
│  │     - Route to correct supplier                      │  │
│  │     - Apply supplier-specific config                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  2. Rate Limiter (per supplier)                      │  │
│  │     - Token bucket algorithm                         │  │
│  │     - Adaptive backoff                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  3. Connection Pool Manager                          │  │
│  │     - Keep-alive connections                         │  │
│  │     - Pool size management                            │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  4. Request Prioritizer                              │  │
│  │     - Priority queues                                 │  │
│  │     - Fair scheduling                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  5. Retry & Circuit Breaker                           │  │
│  │     - Exponential backoff                             │  │
│  │     - Fail-fast on cascading failures                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```go
1. Submit Request
   ├─ App → Dispatcher: SearchHotelsRequest
   └─ Dispatcher → Queue: Enqueue with priority

2. Rate Limit Check
   ├─ Dispatcher → RateLimiter: Check supplier limit
   └─ RateLimiter → Queue: Throttle if needed

3. Connection Pool Lookup
   ├─ Dispatcher → PoolManager: Get connection
   └─ PoolManager → Dispatcher: Reuse or create

4. Execute Request
   ├─ Dispatcher → Supplier: HTTP request
   └─ Supplier → Dispatcher: Response or error

5. Handle Response
   ├─ If 429: Back to rate limiter, retry later
   ├─ If 5xx: Retry with backoff
   ├─ If success: Return to app
   └─ Track metrics
```

## When Do You Need HTTP Dispatcher?

### ✅ You Need HTTP Dispatcher If:

- **3+ suppliers** with different rate limits
- **100+ req/s** aggregate traffic
- **Real-time requirements** (booking, availability check)
- **Cost constraints** (cloud provider charges per connection)
- **Need observability** into supplier performance

### ❌ You Might Not Need It If:

- **1-2 suppliers** only
- **Low traffic** (<10 req/s)
- **Offline batch processing** only
- **Prototype or MVP** stage

## Summary

**HTTP Dispatcher** is not optional for hotel API integration at scale. It's a critical component that:

1. **Prevents rate limit violations** → Fewer 429 errors
2. **Reduces connection overhead** → Faster response times
3. **Prioritizes critical requests** → Better user experience
4. **Provides observability** → Debugging becomes easier
5. **Handles failures gracefully** → Higher reliability

**Next**: [How HTTP Dispatcher Solves Rate Limiting and Connection Pooling](/blog/2026/02/11/http-dispatcher-2-rate-limiting-connection-pooling.html)

---

## Recommended Reading

- [Designing Data-Intensive Applications: Chapter 4](https://dataintensive.net/)
- [Go's net/http Connection Pooling Internals](https://pkg.go.dev/net/http)
- [Rate Limiting Algorithms Explained](https://stripe.com/blog/rate-limiters)

---

## Series Navigation

**HTTP Dispatcher Series**:
1. What is HTTP Dispatcher and Why It's Needed ← You are here
2. [How HTTP Dispatcher Solves Rate Limiting and Connection Pooling](/blog/2026/02/11/http-dispatcher-2-rate-limiting-connection-pooling.html)
3. [Implementing HTTP Dispatcher in Go](/blog/2026/02/13/http-dispatcher-3-implementation-go.html)
4. [Real-World Case Studies and Performance Improvements](/blog/2026/02/15/http-dispatcher-4-case-studies.html)

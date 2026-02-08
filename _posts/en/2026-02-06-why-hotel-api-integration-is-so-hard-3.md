---
layout: post
title: "Why Hotel API Integration is So Hard? (3) Rate Limiting Nightmare: Blocked 3 Times on Day 1"
date: 2026-02-06 05:30:00 +0000
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, rate-limiting, hot-spot-detection]
author: "HotelByte Team"
description: "The third nightmare of hotel API integration: rate limiting. 5 suppliers, 5 different rate limiting rules - QPS limits, time windows, hot spot detection... Blocked 3 times on day 1, search feature completely unavailable."
reading_time: "15 minutes"
---

> This is part 3 of the "Why Hotel API Integration is So Hard?" series.
> 
> [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/) | 
> [Part 2: Data Chaos](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/) | 
> [Part 4: Error Handling](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/) (Coming Soon)

---

## Has Your Search Feature Been Blocked by Supplier on Day 1?

### Real Scenario

Your hotel search feature is live!

**Day 1**:
- 9:00 AM: Everything works fine, search response 300ms
- 10:00 AM: User traffic increases, search QPS reaches 100
- 10:05 AM: Supplier A starts returning 429 Too Many Requests
- 10:10 AM: Supplier B returns 403 Forbidden
- 10:15 AM: Supplier C returns 429 Too Many Requests

**User complaints**:
- "Why can't I find XX hotel?"
- "Why is the search always spinning?"
- "Why does it show error?"

**You open the supplier backend and see this**:
```
Rate Limit Status: EXCEEDED
Next Reset Time: 2026-02-06 16:00:00 UTC (3 hours later)
Your API Key has been temporarily suspended.
```

### The Problem

**You only integrated 5 suppliers, got blocked 3 times on day 1.**

- Why?
- What are the supplier's rate limiting rules?
- Why are some hotels never searchable?

---

## Pain Point 1: Different Rate Limiting Rules per Supplier

### 5 Suppliers, 5 Different Rate Limiting Rules

| Supplier | QPS Limit | Time Window | Rate Limiting Strategy | What happens when exceeded |
|-------|---------|-------------|------------------------|----------------------------|
| A | 10 | Per second | Fixed window | 429 error |
| B | 100 | Per minute | Sliding window | 403 error |
| C | 1000 | Per hour | Token bucket | 429 error |
| D | 500 | Per minute | Sliding window | Suspend API Key |
| E | No limit | N/A | N/A | No limit |

### Differences in Rate Limiting Strategies

#### Fixed Window (Supplier A)

```
Time window: Per second
Limit: 10 QPS
```

**Problem**:
- ❌ Second 1 0.99s: Send 10 requests → OK
- ❌ Second 2 0.01s: Send 10 requests → OK
- ❌ Send 20 requests within 0.02s → Sudden burst traffic

**Supplier's perspective**: You followed the QPS limit, but...

**User's perspective**: Why is the search sometimes fast, sometimes slow?

#### Sliding Window (Supplier B)

```
Time window: Per minute
Limit: 100 QPS
```

**More precise, but more complex**:
- Record timestamp for each request
- Count requests within the past 60 seconds
- If exceed 100, reject

**Problem**:
- ⚠️ Need to maintain request timestamp list
- ⚠️ High memory usage (if QPS is high)
- ⚠️ Complex to implement

#### Token Bucket (Supplier C)

```
Time window: Per hour
Limit: 1000 QPS
Token refill rate: ~16.7 tokens/second
Bucket capacity: 1000 tokens
```

**Working principle**:
- Add 16.7 tokens to bucket every second
- Each request consumes 1 token
- If bucket has no tokens, reject request

**Problem**:
- ⚠️ Burst traffic: If bucket is full, can send 1000 requests instantly
- ⚠️ Cold start: Bucket may be empty initially

#### API Key Suspension (Supplier D)

```
After exceeding: Suspend API Key for 1 hour
Second time exceeding: Suspend API Key for 24 hours
Third time exceeding: Permanently disable API Key
```

**Problem**:
- ❌ Suspend for 1 hour on first exceed
- ❌ Cannot recover quickly
- ❌ Your search feature becomes completely unavailable

---

## Pain Point 2: Hot Hotels Have Stricter Rate Limits

### Real Scenario

**Your users are searching for London's hot hotel**:
- London Central Hotel (hot, 100x search traffic of ordinary hotels)
- London Budget Hotel (cold, very low search traffic)

**Supplier's rate limiting rules**:
- Global QPS limit: 100/minute
- Single hotel QPS limit: 10/minute

### The Problem

**First user searches**:
- London Central Hotel → Search successful
- London Budget Hotel → Search successful

**100th user searches**:
- London Central Hotel → 429 Too Many Requests
- London Budget Hotel → Search successful

**User complaints**:
- "Why can't I find London Central Hotel?"
- "Why can I find it sometimes but not others?"

### The Importance of Hot Spot Detection

**Supplier's perspective**:
- Hot hotels: Too much search traffic, protect supplier's backend
- Single hotel rate limiting: Prevent certain hot hotel from dragging down the entire system

**Your problem**:
- You don't know which are hot hotels
- You don't know each supplier's single hotel rate limiting rules
- You don't know how to avoid hot spots

---

## Pain Point 3: Burst Traffic Causes Exceeds

### Real Scenario

**Your search feature is stable under normal conditions**:
- Average QPS: 50
- Response time: 300ms
- Not rate limited

**One morning at 10 AM**:
- An influencer posted a recommendation for your website
- Suddenly 10000 users flood in
- Instant QPS reaches 500

**Result**:
- Supplier A: 429 Too Many Requests
- Supplier B: 403 Forbidden
- Supplier C: 429 Too Many Requests
- Supplier D: API Key suspended
- Supplier E: Timeout (backend overloaded)

**User complaints**:
- "Why is the website so slow?"
- "Why does it keep showing errors?"
- "I can't use it!"

### The Problem

**Your system design assumes average QPS is 50, but burst traffic is 500.**

- What should you do?
- Estimate traffic in advance?
- Implement caching?
- Queue management?

---

## Pain Point 4: Cache Invalidation Causes Duplicate Calls

### Real Scenario

**You implemented caching**:
- Search results cached for 5 minutes
- User searches the same query, return directly from cache

**Effect**:
- Response time: 300ms → 50ms
- QPS: 500 → 50
- Supplier API calls reduced by 90%

**But...**

**Suddenly the price of a certain hot hotel changes**:
- User A searches: $150 (cached)
- User B searches: $150 (cached)
- User C searches: $150 (cached)
- Supplier price changes: $180

**User D searches**:
- Cache invalidates
- Call supplier API
- Price: $180

**User complaints**:
- "Why did the price change?"
- "My friend saw $150, why do I see $180?"

### The Problem

**If you don't cache**:
- Slow response time (300ms)
- High QPS (500)
- Easily rate limited

**If you cache**:
- Fast response time (50ms)
- Low QPS (50)
- But inaccurate prices

**How to balance?**

---

## Pain Point 5: Multi-Supplier Concurrent Calls Cause Exceeds

### Real Scenario

**Your search feature calls 5 suppliers concurrently**:

```python
async def search_hotel(hotel_id):
    tasks = []
    for supplier in suppliers:
        task = asyncio.create_task(supplier.search(hotel_id))
        tasks.append(task)
    
    results = await asyncio.gather(*tasks)
    return results
```

**Single user search**:
- Concurrently call 5 suppliers
- Each supplier receives 1 request
- QPS: 5

**100 users search simultaneously**:
- Concurrently call 500 suppliers (5 suppliers × 100 users)
- Each supplier receives 100 requests
- QPS: 100

**500 users search simultaneously**:
- Concurrently call 2500 suppliers (5 suppliers × 500 users)
- Each supplier receives 500 requests
- QPS: 500

**Supplier A's rate limiting rule**:
- 10 QPS (per second)

**Result**:
- 100 users search simultaneously: Exceeded (100 > 10)
- 500 users search simultaneously: Exceeded (500 > 10)

### The Problem

**Your user traffic grows fast, but you're rate limited.**

- Should you limit user concurrency?
- Should you implement queuing?
- Should you cache?

---

## Our Solution

### Core Idea: Intelligent Rate Limiting Management

**Problem**: 5 suppliers, 5 different rate limiting rules, easy to exceed.

**Solution**: Intelligent rate limiting management + hot spot detection + multi-level caching + queue management

```
User Request → Queue Management → Intelligent Rate Limiting → Hot Spot Detection → Multi-level Cache → Supplier API
```

---

### 1. Intelligent Rate Limiting Management

#### Automatically Identify Rate Limiting Rules

```python
class RateLimiter:
    def __init__(self, supplier):
        self.supplier = supplier
        self.rules = self._detect_rate_limit_rules()
    
    def _detect_rate_limit_rules(self):
        # 1. Read rate limiting rules from supplier documentation
        docs_rules = self.supplier.rate_limit_docs
        
        # 2. Test rate limiting rules (progressive testing)
        test_rules = self._test_rate_limits()
        
        # 3. Choose the strictest rule
        return self._merge_rules(docs_rules, test_rules)
    
    def _test_rate_limits(self):
        # Progressive testing: start from low QPS, gradually increase
        qps = 1
        max_qps = 1000
        
        while qps <= max_qps:
            success = self._test_qps(qps)
            if not success:
                break
            qps *= 2
        
        return {
            "qps_limit": qps // 2,
            "time_window": self._detect_time_window(),
            "strategy": self._detect_strategy()
        }
```

#### Dynamically Adjust Request Rate

```python
async def request_with_rate_limit(supplier, request):
    rate_limiter = RateLimiter(supplier)
    
    # 1. Check current request rate
    current_qps = rate_limiter.get_current_qps()
    max_qps = rate_limiter.get_max_qps()
    
    # 2. If approaching rate limit, reduce rate
    if current_qps > max_qps * 0.8:
        # Reduce to 80% rate
        await asyncio.sleep(1.0 / (max_qps * 0.2))
    
    # 3. Send request
    response = await supplier.request(request)
    
    # 4. Check if rate limited
    if response.status_code == 429:
        # Rate limited, wait and retry
        retry_after = response.headers.get('Retry-After', 60)
        await asyncio.sleep(retry_after)
        return await request_with_rate_limit(supplier, request)
    
    return response
```

---

### 2. Hot Spot Detection

#### Real-time Identify Hot Hotels

```python
class HotSpotDetector:
    def __init__(self):
        self.request_counts = {}  # hotel_id -> (count, timestamp)
        self.hotspots = set()
    
    def record_request(self, hotel_id):
        now = time.time()
        
        # 1. Record request
        self.request_counts[hotel_id] = (
            self.request_counts.get(hotel_id, (0, 0))[0] + 1,
            now
        )
        
        # 2. Clean expired data (> 1 minute)
        self._cleanup_expired_data(now - 60)
        
        # 3. Detect hot spots
        self._detect_hotspots()
    
    def _detect_hotspots(self):
        # 1. Calculate each hotel's QPS
        hotel_qps = {}
        for hotel_id, (count, timestamp) in self.request_counts.items():
            hotel_qps[hotel_id] = count / 60.0  # per minute
        
        # 2. Identify hot spots (QPS > average * 10)
        avg_qps = sum(hotel_qps.values()) / len(hotel_qps)
        self.hotspots = {
            hotel_id for hotel_id, qps in hotel_qps.items()
            if qps > avg_qps * 10
        }
    
    def is_hotspot(self, hotel_id):
        return hotel_id in self.hotspots
```

#### Rate Limiting Strategy for Hot Hotels

```python
async def search_hotel_with_hotspot_protection(hotel_id):
    hotspot_detector = HotSpotDetector()
    
    # 1. Record request
    hotspot_detector.record_request(hotel_id)
    
    # 2. Detect if it's a hot spot
    if hotspot_detector.is_hotspot(hotel_id):
        # Hot hotel: Reduce request frequency
        await asyncio.sleep(1.0)  # Max 1 request per second
    else:
        # Ordinary hotel: Normal request
        pass
    
    # 3. Search hotel
    return await search_hotel(hotel_id)
```

---

### 3. Multi-level Caching

#### Cache Hierarchy

```
L1: Local memory cache (hot data, second-level TTL)
  ↓ miss
L2: Redis cache (warm data, minute-level TTL)
  ↓ miss
L3: Supplier API (real-time data)
```

#### Adaptive TTL

```python
def adaptive_ttl(hotel_id, check_in_date):
    # 1. Base TTL: 1 minute
    base_ttl = 60  # seconds
    
    # 2. Days until check-in
    days_until = (check_in_date - datetime.now()).days
    time_factor = min(1.0, days_until / 30.0)
    
    # 3. Hot hotel: Shorten TTL
    hotspot_detector = HotSpotDetector()
    if hotspot_detector.is_hotspot(hotel_id):
        hotspot_factor = 0.5  # Hot hotel TTL halved
    else:
        hotspot_factor = 1.0
    
    # 4. Calculate final TTL
    final_ttl = int(base_ttl * time_factor * hotspot_factor)
    
    return final_ttl
```

#### Cache Implementation

```python
async def search_hotel_with_cache(hotel_id, check_in_date):
    cache_key = f"hotel:{hotel_id}:{check_in_date}"
    
    # 1. L1: Local cache
    if cache_key in local_cache:
        return local_cache[cache_key]
    
    # 2. L2: Redis cache
    cached = await redis.get(cache_key)
    if cached:
        data = json.loads(cached)
        local_cache[cache_key] = data
        return data
    
    # 3. L3: Supplier API
    result = await search_hotel_from_supplier(hotel_id)
    
    # 4. Write to cache
    ttl = adaptive_ttl(hotel_id, check_in_date)
    await redis.setex(cache_key, ttl, json.dumps(result))
    local_cache[cache_key] = result
    
    return result
```

---

### 4. Queue Management

#### Request Queue

```python
class RequestQueue:
    def __init__(self, max_concurrent=10):
        self.queue = asyncio.Queue()
        self.max_concurrent = max_concurrent
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.workers = []
    
    async def enqueue(self, request):
        await self.queue.put(request)
    
    async def start_workers(self):
        for i in range(self.max_concurrent):
            worker = asyncio.create_task(self._worker(i))
            self.workers.append(worker)
    
    async def _worker(self, worker_id):
        while True:
            request = await self.queue.get()
            
            async with self.semaphore:
                try:
                    result = await process_request(request)
                    request.complete(result)
                except Exception as e:
                    request.fail(e)
                finally:
                    self.queue.task_done()
    
    async def stop(self):
        for worker in self.workers:
            worker.cancel()
```

#### Burst Traffic Protection

```python
async def search_hotel_with_queue_protection(hotel_id):
    # 1. Check queue length
    queue_length = request_queue.qsize()
    
    if queue_length > 1000:
        # Queue too long, reject new requests
        raise TooManyRequests("Please try again later")
    
    # 2. Add to queue
    future = asyncio.Future()
    await request_queue.enqueue(SearchRequest(
        hotel_id=hotel_id,
        future=future
    ))
    
    # 3. Wait for result
    result = await future
    return result
```

---

### 5. Graceful Degradation

```python
async def search_hotel_with_fallback(hotel_id):
    # 1. Try primary supplier
    try:
        result = await search_hotel_from_supplier(supplier_a, hotel_id)
        return result
    except RateLimitError:
        # Rate limited, try backup supplier
        pass
    
    # 2. Try backup supplier
    try:
        result = await search_hotel_from_supplier(supplier_b, hotel_id)
        return result
    except RateLimitError:
        # Backup supplier also rate limited, return cache
        pass
    
    # 3. Return cache (may be expired)
    cached = await redis.get(f"hotel:{hotel_id}")
    if cached:
        return json.loads(cached)
    
    # 4. Really no choice, return error
    raise ServiceUnavailable("All suppliers are rate limited")
```

---

## Our Advantages

### 1. Intelligent Rate Limiting Management

- Automatically identify each supplier's rate limiting rules
- Dynamically adjust request rate
- Avoid being rate limited
- Automatically retry rate limited requests

### 2. Hot Spot Detection

- Real-time identify hot hotels
- Automatically reduce hot hotel request frequency
- Avoid single hotel rate limiting

### 3. Multi-level Caching

- L1 local cache + L2 Redis cache
- Adaptive TTL (hot hotels shorten TTL)
- Reduce 90% of supplier API calls

### 4. Queue Management

- Request queue avoids burst traffic
- Limit concurrent number to protect suppliers
- Graceful degradation (cache → backup supplier)

### 5. Comprehensive Monitoring

- Real-time monitor each supplier's QPS
- Real-time monitor rate limit times
- Real-time monitor cache hit rate
- Real-time monitor queue length

---

## Call to Action

### Has Your Search Feature Been Blocked on Day 1?

**Problems**:
- 5 suppliers, 5 different rate limiting rules
- Hot hotels have stricter rate limiting
- Burst traffic causes exceeds
- Multi-supplier concurrent calls cause exceeds
- Cache invalidation causes duplicate calls

**Our Solution**:
- Intelligent rate limiting management (automatically identify rate limiting rules, dynamically adjust rate)
- Hot spot detection (real-time identify hot hotels, reduce request frequency)
- Multi-level caching (L1+L2, reduce 90% API calls)
- Queue management (avoid burst traffic, graceful degradation)

**You Only Need**:
```go
import "github.com/hotelbyte-com/sdk-go/hotelbyte"

client := hotelbyte.NewClient("YOUR_API_KEY")

// Search hotels (automatically handle rate limiting, hot spots, caching)
result, err := client.SearchHotels(&hotelbyte.SearchRequest{
    Destination: "London",
    CheckIn:     time.Date(2026, 2, 10, 0, 0, 0, 0, time.Local),
    CheckOut:    time.Date(2026, 2, 12, 0, 0, 0, 0, time.Local),
    Guests:      2,
})

// We automatically handle:
// - Rate limiting management
// - Hot spot detection
// - Multi-level caching
// - Queue management
// - Graceful degradation

for _, hotel := range result.Hotels {
    fmt.Printf("%s: $%.2f\n", hotel.Name, hotel.TotalPrice)
}
```

**No rate limiting nightmare. No 429 errors. Only stable search.**

---

## Next Steps

### Free Trial

- 30 days free trial
- No credit card required
- Start testing immediately

**[Free Trial for 30 Days](https://waitlist.hotelbyte.com)**

### View Documentation

- API docs: [openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- SDK docs: [docs.hotelbyte.com](https://docs.hotelbyte.com)
- Best practices: [blog.hotelbyte.com](https://blog.hotelbyte.com)

### Contact Us

Have questions? Contact our engineers directly.

**[Contact Us](mailto:support@hotelbyte.com)**

---

## Series Navigation

- [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/)
- [Part 2: Data Chaos](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/)
- [Part 3: Rate Limiting Nightmare (This Article)](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/)
- [Part 4: Error Handling (Coming Soon)](#)

---

**Next article preview: Error Handling - Same error, 5 different HTTP status codes and error messages**

---

*Reading time: ~15 minutes*
*Difficulty: Medium (requires understanding API rate limiting, caching, queue management)*

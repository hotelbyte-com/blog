---
layout: post
title: "Why Hotel API Integration is So Hard? (1) Authentication Nightmare: 10-Week Plan, 24 Weeks and Still Not Done"
date: 2026-02-04 18:30:00 +0000
lang: en
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, authentication]
author: "HotelByte Team"
description: "The first nightmare of hotel API integration: authentication. 5 suppliers, 5 different authentication methods - Basic Auth, HMAC-SHA256, OAuth1, JWT... A 10-week plan, 24 weeks and still not done with the first supplier."
series: "Hotel API Integration Field Notes"
series_order: 1
reading_time: "10 minutes"
lang: en
---

> 3 years ago, I received a task: integrate 5 hotel supplier APIs to allow users to search global hotel inventory.
>
> I thought: 5 REST APIs, 2 weeks each, total 10 weeks, done.
>
> 10 weeks later, I was still debugging authentication issues with the first supplier.
>
> 2 years later, I quit, and the project still wasn't fully launched.

## The Initial Misunderstanding

### My Plan (Week 1)

```
Week 1-2:  HotelBeds API Integration
Week 3-4:  Dida API Integration
Week 5-6:  DerbySoft API Integration
Week 7-8:  Expedia API Integration
Week 9-10: Agoda API Integration
Week 11-12: Testing & Launch
```

### Reality (Week 24)

```
Week 1-4:  HotelBeds - Authentication Failed
Week 5-8:  HotelBeds - Data Format Inconsistency
Week 9-12: HotelBeds - Rate Limiting Issues
Week 13-16: Dida - Signature Algorithm Error
Week 17-20: Dida - Timezone Issues
Week 21-24: DerbySoft - Not Started Yet
```

I underestimated the complexity of hotel APIs.

<!-- Read more content from the full article -->

## First Challenge: Authentication Hell

### Supplier A: Basic Auth (Simple)

```http
GET /api/hotels?destination=London
Authorization: Basic YXBpX2tleTphcGlfc2VjcmV0
```

**Problem**: No problem, 5 minutes done.

---

### Supplier B: HMAC-SHA256 (Starting to Get Headaches)

**Documentation says**:
```
Signature = HMAC-SHA256(
    API_SECRET,
    HTTP_METHOD + "\n" +
    REQUEST_PATH + "\n" +
    TIMESTAMP + "\n" +
    NONCE + "\n" +
    REQUEST_BODY
)
```

**My Implementation**:
```go
func GenerateSignature(apiKey, apiSecret, method, path, body string) string {
    timestamp := fmt.Sprintf("%d", time.Now().Unix())
    nonce := generateNonce()

    payload := fmt.Sprintf("%s\n%s\n%s\n%s\n%s",
        method, path, timestamp, nonce, body)

    h := hmac.New(sha256.New, []byte(apiSecret))
    h.Write([]byte(payload))
    return hex.EncodeToString(h.Sum(nil))
}
```

**Result**: 401 Unauthorized.

**Debug Process**:
1. ❌ Check API Secret - Correct
2. ❌ Check HMAC algorithm - Correct
3. ❌ Check payload format - Correct
4. ❌ Check timestamp - Correct
5. ❌ Check nonce - Correct
6. ✅ **Discovery**: Documentation didn't say to URL encode the payload!

**Fix**:
```go
payload := url.QueryEscape(fmt.Sprintf("%s\n%s\n%s\n%s\n%s",
    method, path, timestamp, nonce, body))
```

**Time taken**: 3 days

**Lesson**: Never trust API documentation completely.

---

### Supplier C: OAuth1 (Nightmare Begins)

**Documentation**: 200 pages, mostly废话, key information hidden on page 147.

**OAuth1 Flow**:
1. Get temporary Token
2. Exchange temporary Token for Access Token
3. Use Access Token to call API
4. Access Token expires after 1 hour

**My Implementation**:
```go
func GetAccessToken() (string, error) {
    // Step 1: Get temporary Token
    reqToken, err := oauth1.GetRequestToken()
    if err != nil {
        return "", err
    }

    // Step 2: Authorize (requires user browser operation, backend can't automate)
    // ❌ Stuck here

    // Step 3: Exchange for Access Token
    accessToken, err := oauth1.GetAccessToken(reqToken, verifier)
    if err != nil {
        return "", err
    }

    return accessToken, nil
}
```

**Problem**: OAuth1 is designed for user authorization, not machine-to-machine. But this supplier insists on using OAuth1.

**Solution**: Communicated with supplier technical support, they gave a "backend authentication" API, but it's not in the documentation.

**Time taken**: 2 weeks (most time waiting for supplier response)

---

## Final Results

24 weeks later, I finally integrated 5 suppliers:

| Supplier | Estimated Time | Actual Time | Delay Reason |
|---------|----------------|--------------|---------------|
| HotelBeds | 2 weeks | 16 weeks | Authentication, rate limiting, error handling |
| Dida | 2 weeks | 6 weeks | Signature, timezone |
| DerbySoft | 2 weeks | 2 weeks | Relatively simple |
| Expedia | 2 weeks | Not completed | Incomplete documentation, gave up |
| Agoda | 2 weeks | Not completed | Can't reach technical support |

**Total**:
- Estimated: 10 weeks
- Actual: 24 weeks (and not completed)
- Delay: 140%

---

## If I Could Do It Again

### Option 1: Use Existing Aggregation Platform

- Pros: Quick integration (1-2 weeks)
- Cons: Need to pay commission, high cost
- Cost: $500,000+ / year

### Option 2: Build It Yourself, But Use SDK

- Pros: Control cost, quick integration (4-8 weeks)
- Cons: Need technical team
- Cost: $50,000 - $100,000 (development) + $5,000 / month (subscription)

**Our Solution**:
- Provide multi-language SDKs (Go, Java, Python, JavaScript)
- Unified authentication (one API Key)
- Unified data format (Hotel/Room/RatePlan)
- Smart retry (automatically handle rate limiting, timeouts)
- Detailed documentation and example code

**Quick Start (5 minutes)**:
```go
// Install
go get github.com/hotelbyte-com/sdk-go

// Initialize
client := hotelbyte.NewClient(
    hotelbyte.WithCredentials("your-api-key", "your-api-secret"),
    hotelbyte.WithBaseURL("https://api.hotelbyte.com"),
)

// Search
resp, err := client.SearchHotels(ctx, &hotelbyte.SearchHotelsRequest{
    DestinationID: "LHR",
    CheckIn:       time.Now().AddDate(0, 0, 7),
    CheckOut:      time.Now().AddDate(0, 0, 9),
    AdultCount:    2,
    RoomCount:     1,
})

// Done!
fmt.Printf("Found %d hotels\n", len(resp.Hotels))
```

---

## Summary

**3 Reasons Why Hotel API Integration is Hard**:
1. **Authentication Hell**: Basic Auth → HMAC → OAuth1 → Custom signature
2. **Data Chaos**: Field naming, time formats, price formats all different
3. **Unpredictability**: Rate limiting, error handling, timezone issues

**If you only have 1-2 suppliers**:
- Building it yourself is acceptable (but watch your time budget)

**If you have 5+ suppliers**:
- Use SDK or aggregation platform (save time + reduce cost)

**If you have 50+ suppliers**:
- Must use aggregation platform (otherwise your technical team will explode)

---

## Recommended Resources

**Open Source SDKs**:
- Go SDK: [github.com/hotelbyte-com/sdk-go](https://github.com/hotelbyte-com/sdk-go)
- Java SDK: [github.com/hotelbyte-com/sdk-java](https://github.com/hotelbyte-com/sdk-java)

**Technical Documentation**:
- [How to Design API Rate Limiters](https://stripe.com/blog/rate-limiters)
- [Designing Data-Intensive Applications](https://dataintensive.net/)
- [Building Microservices](https://samnewman.io/books/building_microservices_2nd_edition/)

**Join Us**:
- GitHub: [github.com/hotelbyte-com](https://github.com/hotelbyte-com)
- Product: [waitlist.hotelbyte.com](https://waitlist.hotelbyte.com)

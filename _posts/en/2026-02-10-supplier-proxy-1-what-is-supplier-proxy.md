---
layout: post
title: "Supplier Proxy Series (1): What is Supplier Proxy and Its Role in Hotel API Aggregation"
date: 2026-02-10 10:00:00 +0000
categories: [developer-experience, api-integration, architecture]
tags: [supplier-proxy, hotel-api, api-aggregation, authentication]
author: "HotelByte Team"
description: "What is Supplier Proxy? Why is it the backbone of hotel API aggregation? Learn how it centralizes authentication, normalizes data formats, and provides a unified interface for multiple hotel suppliers."
reading_time: "13 minutes"
lang: en
---

> "We integrated 20 suppliers. Now we have 20 different authentication methods, 20 different data formats, and 20 different error codes. Our team is drowning in complexity." — A Senior Engineer

> "Every time a supplier changes their API, we have to update our entire codebase. It's like playing Whac-A-Mole." — A Tech Lead

If this sounds familiar, you're facing the **Supplier Proxy** problem.

## The Problem: Supplier Proliferation = Complexity Explosion

### The Direct Integration Nightmare

When you integrate hotel suppliers directly, each one brings its own ecosystem of quirks:

```
┌─────────────────────────────────────────────────────────────┐
│                   Your Application                         │
└─────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Supplier A │   │  Supplier B │   │  Supplier C │
│  ┌─────────┐ │   │  ┌─────────┐ │   │  ┌─────────┐ │
│  │  Auth:  │ │   │  │  Auth:  │ │   │  │  Auth:  │ │
│  │ Basic   │ │   │  │ HMAC    │ │   │  │ OAuth2  │ │
│  └─────────┘ │   │  └─────────┘ │   │  └─────────┘ │
│  ┌─────────┐ │   │  ┌─────────┐ │   │  ┌─────────┐ │
│  │ Format: │ │   │  │ Format: │ │   │  │ Format: │ │
│  │ JSON    │ │   │  │ XML     │ │   │  │ JSON    │ │
│  └─────────┘ │   │  └─────────┘ │   │  └─────────┘ │
│  ┌─────────┐ │   │  ┌─────────┐ │   │  ┌─────────┐ │
│  │ Errors: │ │   │  │ Errors: │ │   │  │ Errors: │ │
│  │ 401,429 │ │   │  │ 500,503 │ │   │  │ 200+err │ │
│  └─────────┘ │   │  └─────────┘ │   │  └─────────┘ │
└─────────────┘   └─────────────┘   └─────────────┘
     ... × 50 suppliers
```

### The Complexity Multiplies

| Aspect | 5 Suppliers | 10 Suppliers | 20 Suppliers | 50 Suppliers |
|--------|------------|-------------|-------------|-------------|
| Authentication Methods | 5 | 10 | 20 | 50 |
| Data Formats | 3-4 | 6-8 | 10-15 | 20-30 |
| Error Codes | 20-30 | 50-80 | 100-150 | 250-400 |
| Rate Limits | 5 | 10 | 20 | 50 |
| Timezone Handling | 5 | 10 | 20 | 50 |
| **Total Complexity** | **High** | **Very High** | **Nightmare** | **Impossible** |

## Enter: Supplier Proxy

### What is Supplier Proxy?

**Supplier Proxy** is a middleware layer that sits between your application and hotel supplier APIs. It provides a **unified interface** while handling all supplier-specific complexities behind the scenes.

```
┌─────────────────────────────────────────────────────────────┐
│                   Your Application                           │
│                                                             │
│  hotelbyte.SearchHotels({                                   │
│    destination: "LHR",                                       │
│    checkIn: "2026-02-16",                                    │
│    checkOut: "2026-02-18",                                   │
│  })                                                          │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Unified Request
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Supplier Proxy (The Translator)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Auth       │  │    Data      │  │   Error      │     │
│  │  Manager     │  │  Normalizer  │  │  Translator  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Normalized Requests
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │HotelBeds│    │  Dida   │    │ Expedia │
    └─────────┘    └─────────┘    └─────────┘
          ... × 50 suppliers
```

### Key Responsibilities

| Responsibility | Why It Matters |
|----------------|----------------|
| **Unified Authentication** | One API key for all suppliers |
| **Data Normalization** | Consistent data format regardless of supplier |
| **Error Translation** | Supplier errors → Standardized errors |
| **Schema Mapping** | Different fields → Unified schema |
| **Request/Response Transformation** | XML ↔ JSON, different structures |
| **Caching & Performance** | Reduce redundant supplier calls |
| **Logging & Observability** | Single point of visibility |

## Why Supplier Proxy is the Backbone of Hotel API Aggregation

### Challenge 1: Authentication Fragmentation

**Suppliers use many different authentication methods**:

| Supplier | Auth Method | Complexity |
|----------|-------------|------------|
| HotelBeds | API Key + Signature | Medium |
| Dida | HMAC-SHA256 | High |
| Expedia | OAuth2 (3-legged) | Very High |
| Agoda | API Key (Header) | Low |
| DerbySoft | JWT + Certificate | Very High |
| TravelGDS | WSSecurity | Extreme |

**Without Supplier Proxy**:
```go
// ❌ Different auth for each supplier
func SearchHotelBeds(req *SearchRequest) (*Response, error) {
    signature := generateHMACSignature(req)
    client := &http.Client{}
    req.Header.Set("X-Signature", signature)
    req.Header.Set("Api-Key", hotelbedsKey)
    // ...
}

func SearchDida(req *SearchRequest) (*Response, error) {
    timestamp := time.Now().Unix()
    signature := hmacSHA256(didaSecret, req.Body)
    req.Header.Set("X-Timestamp", strconv.Itoa(timestamp))
    req.Header.Set("X-Signature", signature)
    // ...
}

func SearchExpedia(req *SearchRequest) (*Response, error) {
    accessToken, err := getOAuth2Token()
    req.Header.Set("Authorization", "Bearer "+accessToken)
    // ...
}
// ... and so on for 50 suppliers
```

**With Supplier Proxy**:
```go
// ✅ One unified authentication
func SearchHotels(req *SearchRequest) (*Response, error) {
    // Single API key for all suppliers
    client := hotelbyte.NewClient(
        hotelbyte.WithAPIKey("your-api-key"),
        hotelbyte.WithAPISecret("your-api-secret"),
    )
    return client.SearchHotels(ctx, req)
}
```

### Challenge 2: Data Format Chaos

**Different suppliers return different structures**:

**Supplier A (JSON)**:
```json
{
  "hotels": [
    {
      "hotel_id": "H123",
      "hotel_name": "Grand Hotel",
      "rooms": [
        {
          "room_type": "DELUXE",
          "rates": [
            {
              "amount": 150.00,
              "currency": "USD"
            }
          ]
        }
      ]
    }
  ]
}
```

**Supplier B (XML)**:
```xml
<Hotels>
  <Hotel id="H456">
    <Name>Grand Hotel</Name>
    <RoomTypes>
      <Room type="DLX">
        <Pricing>
          <Price currency="USD">150.00</Price>
        </Pricing>
      </Room>
    </RoomTypes>
  </Hotel>
</Hotels>
```

**Supplier C (JSON, different structure)**:
```json
{
  "results": [
    {
      "property": {
        "code": "H789",
        "title": "Grand Hotel",
        "accommodation": [
          {
            "category": "DELUXE",
            "price": {
              "total": 150,
              "currency": "USD"
            }
          }
        ]
      }
    }
  ]
}
```

**Without Supplier Proxy**:
```go
// ❌ Different structs for each supplier
type HotelBedsHotel struct {
    HotelID   string `json:"hotel_id"`
    HotelName string `json:"hotel_name"`
    Rooms     []HotelBedsRoom `json:"rooms"`
}

type DidaHotel struct {
    Property struct {
        ID    string `xml:"id,attr"`
        Title string `xml:"Name"`
    } `xml:"Hotel"`
}

type ExpediaProperty struct {
    Code string `json:"code"`
    Title string `json:"title"`
}

// ... 50 different structs
```

**With Supplier Proxy**:
```go
// ✅ One unified structure
type Hotel struct {
    ID      string  `json:"id"`
    Name    string  `json:"name"`
    Rating  float64 `json:"rating"`
    Rooms   []Room  `json:"rooms"`
    Address Address `json:"address"`
}

type Room struct {
    Type      string    `json:"type"`
    Available bool      `json:"available"`
    Rates     []Rate    `json:"rates"`
}

type Rate struct {
    Amount   float64 `json:"amount"`
    Currency string  `json:"currency"`
    Taxes    float64 `json:"taxes"`
    Fees     float64 `json:"fees"`
}
```

### Challenge 3: Error Code Mismatch

**Suppliers use different error codes and messages**:

| Supplier | Error Code | Meaning |
|----------|-----------|---------|
| HotelBeds | 401 | Invalid API key |
| Dida | AUTH_001 | Authentication failed |
| Expedia | E_AUTH_ERROR | Token expired |
| Agoda | 403 | Permission denied |
| DerbySoft | ERR-1001 | Signature invalid |

**Without Supplier Proxy**:
```go
// ❌ Different error handling for each supplier
func HandleHotelBedsError(resp *http.Response) error {
    if resp.StatusCode == 401 {
        return errors.New("invalid API key")
    }
    if resp.StatusCode == 429 {
        return errors.New("rate limited")
    }
    // ...
}

func HandleDidaError(resp *http.Response) error {
    if resp.StatusCode == 200 {
        var errResp struct {
            ErrorCode string `json:"error_code"`
            Message   string `json:"message"`
        }
        if errResp.ErrorCode == "AUTH_001" {
            return errors.New("authentication failed")
        }
    }
    // ...
}
// ... 50 different handlers
```

**With Supplier Proxy**:
```go
// ✅ Unified error handling
var err *hotelbyte.Error

switch err.Code {
case hotelbyte.ErrAuthentication:
    // Handle authentication errors
    log.Error("Authentication failed", "supplier", err.Supplier)
case hotelbyte.ErrRateLimit:
    // Handle rate limiting
    time.Sleep(time.Second)
case hotelbyte.ErrInvalidRequest:
    // Handle invalid requests
}
```

## Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                   Supplier Proxy                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. API Gateway                                       │  │
│  │     - Request validation                              │  │
│  │     - Routing                                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  2. Authentication Manager                           │  │
│  │     - Multi-protocol support                          │  │
│  │     - Token management                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  3. Request Transformer                              │  │
│  │     - Format conversion (JSON/XML)                    │  │
│  │     - Schema mapping                                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  4. Response Normalizer                               │  │
│  │     - Data unification                                │  │
│  │     - Error translation                               │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  5. Caching Layer                                     │  │
│  │     - Response caching                                │  │
│  │     - Cache invalidation                              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. Application Request
   ├─ Unified API call (e.g., SearchHotels)
   └─ API Gateway validates request

2. Authentication
   ├─ Auth Manager generates supplier-specific auth
   └─ Tokens cached for reuse

3. Request Transformation
   ├─ Transform unified request to supplier format
   ├─ Apply supplier-specific mappings
   └─ Convert to JSON/XML as needed

4. Supplier API Call
   ├─ Make HTTP request to supplier
   └─ Handle rate limiting, retries

5. Response Normalization
   ├─ Parse supplier response (JSON/XML)
   ├─ Map to unified schema
   ├─ Translate error codes
   └─ Cache if appropriate

6. Return to Application
   └─ Unified response format
```

## Real-World Impact

### Case Study: Hotel Booking Platform

**Before Supplier Proxy**:
```
Suppliers integrated: 15
Development time: 6 months
Maintenance overhead: 80% of team time
New supplier integration: 3-4 weeks
Bugs from supplier changes: 2-3 per month
```

**After Supplier Proxy**:
```
Suppliers integrated: 45
Development time: 2 months (initial)
Maintenance overhead: 20% of team time
New supplier integration: 3-5 days
Bugs from supplier changes: 0 (handled in proxy)
```

**Impact**:
- **67% reduction** in initial development time
- **75% reduction** in maintenance overhead
- **85% reduction** in new supplier integration time
- **100% reduction** in bugs from supplier changes

## When Do You Need Supplier Proxy?

### ✅ You Need Supplier Proxy If:

- **3+ suppliers** to integrate
- **Different authentication methods** across suppliers
- **Different data formats** (JSON, XML, Protobuf)
- **Long-term maintenance** requirement
- **Multiple applications** consuming hotel data
- **Need for scalability** (adding more suppliers)

### ❌ You Might Not Need It If:

- **1-2 suppliers** only
- **Same authentication method** across all
- **Consistent data formats**
- **Short-term project** or prototype

## Summary

**Supplier Proxy** is not optional for hotel API aggregation. It's the backbone that:

1. **Unifies authentication** → One API key, not 50
2. **Normalizes data** → One schema, not 50
3. **Standardizes errors** → Consistent error handling
4. **Reduces maintenance** → Changes in one place, not 50
5. **Enables scalability** → Add suppliers without complexity explosion

**Next**: [How Supplier Proxy Handles Authentication and Error Handling](/blog/2026/02/12/supplier-proxy-2-authentication-error-handling.html)

---

## Recommended Reading

- [API Gateway Patterns](https://microservices.io/patterns/apigateway.html)
- [API Design Patterns](https://www.oreilly.com/library/view/api-design-patterns/9781484269423/)
- [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/)

---

## Series Navigation

**Supplier Proxy Series**:
1. What is Supplier Proxy and Its Role in Hotel API Aggregation ← You are here
2. [How Supplier Proxy Handles Authentication and Error Handling](/blog/2026/02/12/supplier-proxy-2-authentication-error-handling.html)
3. [Supplier Proxy Architecture and Scalability](/blog/2026/02/14/supplier-proxy-3-architecture-scalability.html)
4. [Cost Benefits and ROI Analysis](/blog/2026/02/16/supplier-proxy-4-cost-benefits-roi.html)

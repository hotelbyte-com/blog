---
layout: post
title: "Supplier Proxy系列（1）：什么是Supplier Proxy？它是酒店API聚合的骨干"
date: 2026-02-10 10:00:00 +0000
categories: [developer-experience, api-integration, architecture]
tags: [supplier-proxy, hotel-api, api-aggregation, authentication]
author: "HotelByte Team"
description: "什么是Supplier Proxy？为什么它是酒店API聚合的骨干？了解它如何集中认证、标准化数据格式，并为多个酒店供应商提供统一接口。"
reading_time: "13 minutes"
lang: zh
---

> "我们集成了20家供应商。现在我们有20种不同的认证方法、20种不同的数据格式、20种不同的错误代码。我们的团队正淹没在复杂性中。" — 一位高级工程师

> "每次供应商更改他们的API，我们都要更新整个代码库。这就像玩打地鼠游戏。" — 一位技术负责人

如果这听起来很熟悉，那你面临的就是**Supplier Proxy**问题。

## 问题：供应商激增 = 复杂性爆炸

### 直接集成的噩梦

当你直接集成酒店供应商时，每个都带来自己的生态系统怪癖：

```
┌─────────────────────────────────────────────────────────────┐
│                   你的应用程序                               │
└─────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  供应商A     │   │  供应商B     │   │  供应商C     │
│  ┌─────────┐ │   │  ┌─────────┐ │   │  ┌─────────┐ │
│  │  认证:   │ │   │  │  认证:   │ │   │  │  认证:   │ │
│  │ Basic   │ │   │  │ HMAC    │ │   │  │ OAuth2  │ │
│  └─────────┘ │   │  └─────────┘ │   │  └─────────┘ │
│  ┌─────────┐ │   │  ┌─────────┐ │   │  ┌─────────┐ │
│  │ 格式:   │ │   │  │ 格式:   │ │   │  │ 格式:   │ │
│  │ JSON    │ │   │  │ XML     │ │   │  │ JSON    │ │
│  └─────────┘ │   │  └─────────┘ │   │  └─────────┘ │
│  ┌─────────┐ │   │  ┌─────────┐ │   │  ┌─────────┐ │
│  │ 错误:   │ │   │  │ 错误:   │ │   │  │ 错误:   │ │
│  │ 401,429 │ │   │  │ 500,503 │ │   │  │ 200+err │ │
│  └─────────┘ │   │  └─────────┘ │   │  └─────────┘ │
└─────────────┘   └─────────────┘   └─────────────┘
     ... × 50家供应商
```

### 复杂性成倍增长

| 方面 | 5家供应商 | 10家供应商 | 20家供应商 | 50家供应商 |
|------|-----------|-----------|-----------|-----------|
| 认证方法 | 5 | 10 | 20 | 50 |
| 数据格式 | 3-4 | 6-8 | 10-15 | 20-30 |
| 错误代码 | 20-30 | 50-80 | 100-150 | 250-400 |
| 限流策略 | 5 | 10 | 20 | 50 |
| 时区处理 | 5 | 10 | 20 | 50 |
| **总复杂度** | **高** | **很高** | **噩梦** | **不可能** |

## 登场：Supplier Proxy

### 什么是Supplier Proxy？

**Supplier Proxy**是一个中间件层，位于你的应用程序和酒店供应商API之间。它在后台处理所有供应商特定的复杂性，同时提供**统一接口**。

```
┌─────────────────────────────────────────────────────────────┐
│                   你的应用程序                               │
│                                                             │
│  hotelbyte.SearchHotels({                                   │
│    destination: "LHR",                                       │
│    checkIn: "2026-02-16",                                    │
│    checkOut: "2026-02-18",                                   │
│  })                                                          │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ 统一请求
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Supplier Proxy (翻译官)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   认证        │  │   数据标准化  │  │   错误翻译   │     │
│  │  管理器       │  │   器         │  │   器         │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ 标准化请求
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │HotelBeds│    │  Dida   │    │ Expedia │
    └─────────┘    └─────────┘    └─────────┘
          ... × 50家供应商
```

### 核心职责

| 职责 | 为什么重要 |
|------|-----------|
| **统一认证** | 一个API密钥适用于所有供应商 |
| **数据标准化** | 无论供应商如何，数据格式一致 |
| **错误翻译** | 供应商错误 → 标准化错误 |
| **模式映射** | 不同字段 → 统一模式 |
| **请求/响应转换** | XML ↔ JSON，不同结构 |
| **缓存和性能** | 减少冗余的供应商调用 |
| **日志和可观测性** | 单一可见性点 |

## 为什么Supplier Proxy是酒店API聚合的骨干

### 挑战1：认证碎片化

**供应商使用许多不同的认证方法**：

| 供应商 | 认证方法 | 复杂度 |
|--------|---------|--------|
| HotelBeds | API Key + 签名 | 中等 |
| Dida | HMAC-SHA256 | 高 |
| Expedia | OAuth2 (3-legged) | 很高 |
| Agoda | API Key (Header) | 低 |
| DerbySoft | JWT + 证书 | 很高 |
| TravelGDS | WSSecurity | 极高 |

**没有Supplier Proxy**：
```go
// ❌ 每个供应商不同的认证
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
// ... 还有50家供应商的类似代码
```

**有Supplier Proxy**：
```go
// ✅ 一个统一的认证
func SearchHotels(req *SearchRequest) (*Response, error) {
    // 所有供应商一个API密钥
    client := hotelbyte.NewClient(
        hotelbyte.WithAPIKey("your-api-key"),
        hotelbyte.WithAPISecret("your-api-secret"),
    )
    return client.SearchHotels(ctx, req)
}
```

### 挑战2：数据格式混乱

**不同供应商返回不同的结构**：

**供应商A (JSON)**:
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

**供应商B (XML)**:
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

**供应商C (JSON, 不同结构)**:
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

**没有Supplier Proxy**：
```go
// ❌ 每个供应商不同的结构体
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

// ... 50个不同的结构体
```

**有Supplier Proxy**：
```go
// ✅ 一个统一的结构体
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

### 挑战3：错误代码不匹配

**供应商使用不同的错误代码和消息**：

| 供应商 | 错误代码 | 含义 |
|--------|---------|------|
| HotelBeds | 401 | 无效的API密钥 |
| Dida | AUTH_001 | 认证失败 |
| Expedia | E_AUTH_ERROR | 令牌过期 |
| Agoda | 403 | 权限被拒绝 |
| DerbySoft | ERR-1001 | 签名无效 |

**没有Supplier Proxy**：
```go
// ❌ 每个供应商不同的错误处理
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
// ... 50个不同的处理器
```

**有Supplier Proxy**：
```go
// ✅ 统一的错误处理
var err *hotelbyte.Error

switch err.Code {
case hotelbyte.ErrAuthentication:
    // 处理认证错误
    log.Error("认证失败", "supplier", err.Supplier)
case hotelbyte.ErrRateLimit:
    // 处理限流
    time.Sleep(time.Second)
case hotelbyte.ErrInvalidRequest:
    // 处理无效请求
}
```

## 架构概览

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                   Supplier Proxy                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  1. API网关                                           │  │
│  │     - 请求验证                                          │  │
│  │     - 路由                                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  2. 认证管理器                                         │  │
│  │     - 多协议支持                                        │  │
│  │     - 令牌管理                                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  3. 请求转换器                                         │  │
│  │     - 格式转换（JSON/XML）                              │  │
│  │     - 模式映射                                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  4. 响应标准化器                                        │  │
│  │     - 数据统一                                          │  │
│  │     - 错误翻译                                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                              │                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  5. 缓存层                                            │  │
│  │     - 响应缓存                                          │  │
│  │     - 缓存失效                                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 数据流

```
1. 应用程序请求
   ├─ 统一API调用（例如 SearchHotels）
   └─ API网关验证请求

2. 认证
   ├─ 认证管理器生成供应商特定认证
   └─ 令牌缓存以供重用

3. 请求转换
   ├─ 将统一请求转换为供应商格式
   ├─ 应用供应商特定映射
   └─ 根据需要转换为JSON/XML

4. 供应商API调用
   ├─ 向供应商发出HTTP请求
   └─ 处理限流、重试

5. 响应标准化
   ├─ 解析供应商响应（JSON/XML）
   ├─ 映射到统一模式
   ├─ 翻译错误代码
   └─ 适当缓存

6. 返回应用程序
   └─ 统一响应格式
```

## 实际影响

### 案例研究：酒店预订平台

**使用Supplier Proxy之前**：
```
已集成供应商：15家
开发时间：6个月
维护开销：团队时间的80%
新供应商集成：3-4周
供应商变更导致的错误：每月2-3个
```

**使用Supplier Proxy之后**：
```
已集成供应商：45家
开发时间：2个月（初始）
维护开销：团队时间的20%
新供应商集成：3-5天
供应商变更导致的错误：0（在代理中处理）
```

**影响**：
- 初始开发时间**减少67%**
- 维护开销**减少75%**
- 新供应商集成时间**减少85%**
- 供应商变更导致的错误**减少100%**

## 什么时候你需要Supplier Proxy？

### ✅ 你需要Supplier Proxy如果：

- **3家以上供应商**需要集成
- **不同的认证方法**跨供应商
- **不同的数据格式**（JSON、XML、Protobuf）
- **长期维护**要求
- **多个应用程序**消费酒店数据
- **需要可扩展性**（添加更多供应商）

### ❌ 你可能不需要如果：

- **1-2家供应商**仅
- **相同的认证方法**跨所有
- **一致的数据格式**
- **短期项目**或原型

## 总结

**Supplier Proxy**不是可选项，而是酒店API聚合的骨干。它：

1. **统一认证** → 一个API密钥，而不是50个
2. **标准化数据** → 一个模式，而不是50个
3. **标准化错误** → 一致的错误处理
4. **减少维护** → 在一个地方更改，而不是50个
5. **实现可扩展性** → 添加供应商而不会复杂性爆炸

**下一篇**：[Supplier Proxy如何处理认证和错误处理](/blog/zh/2026/02/12/supplier-proxy-2-authentication-error-handling.html)

---

## 推荐阅读

- [API Gateway Patterns](https://microservices.io/patterns/apigateway.html)
- [API Design Patterns](https://www.oreilly.com/library/view/api-design-patterns/9781484269423/)
- [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/)

---

## 系列导航

**Supplier Proxy系列**：
1. 什么是Supplier Proxy及它在酒店API聚合中的作用 ← 你在这里
2. [Supplier Proxy如何处理认证和错误处理](/blog/zh/2026/02/12/supplier-proxy-2-authentication-error-handling.html)
3. [Supplier Proxy架构和可扩展性](/blog/zh/2026/02/14/supplier-proxy-3-architecture-scalability.html)
4. [成本效益和ROI分析](/blog/zh/2026/02/16/supplier-proxy-4-cost-benefits-roi.html)

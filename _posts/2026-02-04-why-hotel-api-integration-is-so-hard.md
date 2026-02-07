---
layout: post
title: "为什么酒店API集成这么难？（1）认证地狱：10周计划，24周还没完成"
date: 2026-02-04 18:30:00 +0000
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, authentication]
author: "HotelByte Team"
description: "酒店API集成的第一个噩梦：认证。5家供应商，5种不同的认证方式——Basic Auth、HMAC-SHA256、OAuth1、JWT...10周的计划，24周还没完成第一个供应商。"
---

> 3年前，我接到了一个任务：接入5家酒店供应商的API，让用户可以搜索全球酒店库存。
>
> 我想：5个REST API，每个花2周，总共10周，搞定。
>
> 10周后，我还在调试第一个供应商的认证问题。
>
> 2年后，我离职了，项目还没有完全上线。

## 最初的误解

### 我的计划（第1周）

```
Week 1-2:  HotelBeds API 集成
Week 3-4:  Dida API 集成
Week 5-6:  DerbySoft API 集成
Week 7-8:  Expedia API 集成
Week 9-10: Agoda API 集成
Week 11-12: 测试 & 上线
```

### 现实（第24周）

```
Week 1-4:  HotelBeds - 认证失败
Week 5-8:  HotelBeds - 数据格式不一致
Week 9-12: HotelBeds - 限流问题
Week 13-16: Dida - 签名算法错误
Week 17-20: Dida - 时区问题
Week 21-24: DerbySoft - 还没开始
```

我低估了酒店API的复杂度。

<!-- Read more content from the full article -->

## 第一关：认证地狱

### 供应商A：Basic Auth（简单）

```http
GET /api/hotels?destination=London
Authorization: Basic YXBpX2tleTphcGlfc2VjcmV0
```

**问题**：没有问题，5分钟搞定。

---

### 供应商B：HMAC签名（开始头疼）

**文档说**：
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

**我的实现**：
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

**结果**：401 Unauthorized。

**Debug过程**：
1. ❌ 检查API Secret - 正确
2. ❌ 检查HMAC算法 - 正确
3. ❌ 检查payload格式 - 正确
4. ❌ 检查时间戳 - 正确
5. ❌ 检查nonce - 正确
6. ✅ **发现**：文档没有说要URL encode payload！

**修复**：
```go
payload := url.QueryEscape(fmt.Sprintf("%s\n%s\n%s\n%s\n%s",
    method, path, timestamp, nonce, body))
```

**耗时**：3天

**教训**：永远不要相信API文档完全正确。

---

### 供应商C：OAuth1（噩梦开始）

**文档**：200页，全是废话，关键信息藏在第147页。

**OAuth1流程**：
1. 获取临时Token
2. 用临时Token换取Access Token
3. 用Access Token调用API
4. Access Token 1小时后过期

**我的实现**：
```go
func GetAccessToken() (string, error) {
    // Step 1: 获取临时Token
    reqToken, err := oauth1.GetRequestToken()
    if err != nil {
        return "", err
    }

    // Step 2: 授权（需要用户浏览器操作，后台无法自动化）
    // ❌ 卡在这里

    // Step 3: 换取Access Token
    accessToken, err := oauth1.GetAccessToken(reqToken, verifier)
    if err != nil {
        return "", err
    }

    return accessToken, nil
}
```

**问题**：OAuth1设计用于用户授权，不是机器对机器。但这个供应商坚持用OAuth1。

**解决**：和供应商技术支持沟通，他们给了一个"后台认证"的API，但文档里没写。

**耗时**：2周（大部分时间在等供应商回复）

---

## 最终成果

24周后，我终于接入了5个供应商：

| 供应商 | 预计时间 | 实际时间 | 延期原因 |
|-------|---------|---------|---------|
| HotelBeds | 2周 | 16周 | 认证、限流、错误处理 |
| Dida | 2周 | 6周 | 签名、时区 |
| DerbySoft | 2周 | 2周 | 相对简单 |
| Expedia | 2周 | 未完成 | 文档不完整，放弃 |
| Agoda | 2周 | 未完成 | 联系不上技术支持 |

**总计**：
- 预计：10周
- 实际：24周（且未完成）
- 延期：140%

---

## 如果重来一次

### 方法1：使用现成的聚合平台

- 优点：快速接入（1-2周）
- 缺点：要交佣金，成本高
- 成本：$500,000+ / 年

### 方法2：自己写，但用SDK

- 优点：控制成本，快速接入（4-8周）
- 缺点：需要技术团队
- 成本：$50,000 - $100,000（开发） + $5,000 / 月（订阅）

**我们的方案**：
- 提供多语言SDK（Go, Java, Python, JavaScript）
- 统一认证（一个API Key）
- 统一数据格式（Hotel/Room/RatePlan）
- 智能重试（自动处理限流、超时）
- 详细文档和示例代码

**Quick Start（5分钟）**：
```go
// 安装
go get github.com/hotelbyte-com/sdk-go

// 初始化
client := hotelbyte.NewClient(
    hotelbyte.WithCredentials("your-api-key", "your-api-secret"),
    hotelbyte.WithBaseURL("https://api.hotelbyte.com"),
)

// 搜索
resp, err := client.SearchHotels(ctx, &hotelbyte.SearchHotelsRequest{
    DestinationID: "LHR",
    CheckIn:       time.Now().AddDate(0, 0, 7),
    CheckOut:      time.Now().AddDate(0, 0, 9),
    AdultCount:    2,
    RoomCount:     1,
})

// 完成！
fmt.Printf("找到 %d 家酒店\n", len(resp.Hotels))
```

---

## 总结

**酒店API集成难的3个原因**：
1. **认证地狱**：Basic Auth → HMAC → OAuth1 → 自定义签名
2. **数据混乱**：字段命名、时间格式、价格格式各不相同
3. **不可预测**：限流、错误处理、时区问题

**如果只有1-2个供应商**：
- 自己写可以接受（但要注意时间预算）

**如果有5+个供应商**：
- 使用SDK或聚合平台（节省时间 + 降低成本）

**如果有50+个供应商**：
- 必须用聚合平台（否则技术团队会爆炸）

---

## 推荐资源

**开源SDK**：
- Go SDK：[github.com/hotelbyte-com/sdk-go](https://github.com/hotelbyte-com/sdk-go)
- Java SDK：[github.com/hotelbyte-com/sdk-java](https://github.com/hotelbyte-com/sdk-java)

**技术文档**：
- [How to Design API Rate Limiters](https://stripe.com/blog/rate-limiters)
- [Designing Data-Intensive Applications](https://dataintensive.net/)
- [Building Microservices](https://samnewman.io/books/building_microservices_2nd_edition/)

**加入我们**：
- GitHub：[github.com/hotelbyte-com](https://github.com/hotelbyte-com)
- 产品：[waitlist.hotelbyte.com](https://waitlist.hotelbyte.com)

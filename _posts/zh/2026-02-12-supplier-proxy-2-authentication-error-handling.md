---
layout: post
title: "Supplier Proxy系列（2）：Supplier Proxy如何处理认证和错误处理"
date: 2026-02-12 10:00:00 +0000
categories: [developer-experience, api-integration, security]
tags: [supplier-proxy, authentication, error-handling, hotel-api]
author: "HotelByte Team"
description: "深入探讨Supplier Proxy的认证管理和错误处理策略。了解它如何处理多种认证协议（Basic Auth、HMAC、OAuth2、JWT）并标准化50+酒店供应商的错误处理。"
reading_time: "13 minutes"
lang: zh
---

> "我们的认证模块有5,000行代码并且还在增长。每个新供应商都要增加200-300行认证逻辑。" — 高级开发人员

> "我们有15种不同的错误类型需要处理。开发人员花在解析错误上的时间比写业务逻辑还多。" — 技术负责人

如果这听起来很熟悉，你需要Supplier Proxy的认证和错误处理能力。

## 第一部分：认证管理

### 认证爆炸

酒店供应商使用**许多不同的认证方法**：

| 认证类型 | 使用的供应商 | 复杂度 |
|---------|-------------|--------|
| Basic Auth | 15% | 低 |
| API Key (Header) | 25% | 低 |
| HMAC-SHA256 | 20% | 中等 |
| HMAC-SHA512 | 10% | 中高 |
| OAuth 1.0 | 5% | 很高 |
| OAuth 2.0 | 15% | 高 |
| JWT | 5% | 高 |
| WSSecurity (XML) | 3% | 极高 |
| 自定义 | 2% | 极高 |

**总计**：50家供应商，9种不同认证类型

### Supplier Proxy的认证架构

```
┌────────────────────────────────────────────────────────────┐
│              你的应用程序                                    │
│                                                              │
│  hotelbyte.SearchHotels({                                    │
│    apiKey: "HB-123456",                                      │
│  })                                                          │
└────────────────────────────────────────────────────────────┘
                          │
                          │ 单一API密钥
                          ▼
┌────────────────────────────────────────────────────────────┐
│           Supplier Proxy - 认证管理器                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  认证路由器   │  │   令牌管理器  │  │    缓存     │    │
│  │              │  │              │  │              │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└────────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │Basic Auth │   │   HMAC    │   │  OAuth2   │
    └───────────┘   └───────────┘   └───────────┘
```

### 认证协议实现

#### 1. Basic Auth + API Key（简单）

```go
type BasicAuthConfig struct {
    Username string
    Password string
    APIKey   string
}

func (a *BasicAuthConfig) Apply(req *http.Request) {
    // 设置API密钥
    if a.APIKey != "" {
        req.Header.Set("X-API-Key", a.APIKey)
        req.Header.Set("X-API-Secret", a.Password)
        return
    }

    // 设置Basic Auth
    req.SetBasicAuth(a.Username, a.Password)
}
```

**配置**：
```go
authConfigs := map[string]AuthConfig{
    "hotelbeds": {
        Type:     AuthTypeBasic,
        Username: "hotelbyte_api",
        Password: "secret_from_vault",
    },
    "agoda": {
        Type:   AuthTypeAPIKey,
        APIKey: "agoda_key_123",
    },
}
```

#### 2. HMAC-SHA256（复杂）

```go
type HMACAuthConfig struct {
    APIKey    string
    APISecret string
    Algorithm string
    Headers   []string
}

func (h *HMACAuthConfig) Apply(req *http.Request) error {
    timestamp := time.Now().Unix()
    nonce := generateNonce()

    // 构建签名字符串
    parts := []string{
        req.Method,
        req.URL.Path,
        strconv.FormatInt(timestamp, 10),
        nonce,
    }

    // 添加指定的头
    for _, header := range h.Headers {
        parts = append(parts, req.Header.Get(header))
    }

    signatureString := strings.Join(parts, "\n")

    // 生成HMAC
    var hash hash.Hash
    switch h.Algorithm {
    case "SHA256":
        hash = hmac.New(sha256.New, []byte(h.APISecret))
    case "SHA512":
        hash = hmac.New(sha512.New, []byte(h.APISecret))
    default:
        return fmt.Errorf("不支持的算法: %s", h.Algorithm)
    }

    hash.Write([]byte(signatureString))
    signature := hex.EncodeToString(hash.Sum(nil))

    // 设置头
    req.Header.Set("X-API-Key", h.APIKey)
    req.Header.Set("X-Timestamp", strconv.FormatInt(timestamp, 10))
    req.Header.Set("X-Nonce", nonce)
    req.Header.Set("X-Signature", signature)

    return nil
}
```

**配置**：
```go
authConfigs := map[string]AuthConfig{
    "dida": {
        Type:      AuthTypeHMAC,
        APIKey:    "dida_key",
        APISecret: "dida_secret",
        Algorithm: "SHA256",
        Headers:   []string{"Content-Type", "Accept"},
    },
    "derbysoft": {
        Type:      AuthTypeHMAC,
        APIKey:    "derby_key",
        APISecret: "derby_secret",
        Algorithm: "SHA512",
        Headers:   []string{"Content-Type"},
    },
}
```

#### 3. OAuth 2.0（复杂）

```go
type OAuth2Config struct {
    ClientID     string
    ClientSecret string
    TokenURL     string
    Scopes       []string
}

type OAuth2TokenManager struct {
    configs map[string]*OAuth2Config
    tokens  map[string]*oauth2.Token
    mu      sync.RWMutex
    client  *http.Client
}

func (tm *OAuth2TokenManager) GetToken(supplier string) (string, error) {
    tm.mu.RLock()
    token, exists := tm.tokens[supplier]
    tm.mu.RUnlock()

    if exists && token.Valid() {
        return token.AccessToken, nil
    }

    tm.mu.Lock()
    defer tm.mu.Unlock()

    config := tm.configs[supplier]
    oauthConfig := &oauth2.Config{
        ClientID:     config.ClientID,
        ClientSecret: config.ClientSecret,
        Endpoint: oauth2.Endpoint{
            TokenURL: config.TokenURL,
        },
        Scopes: config.Scopes,
    }

    ctx := context.Background()
    newToken, err := oauthConfig.TokenSource(ctx, &oauth2.Token{}).Token()
    if err != nil {
        return "", fmt.Errorf("获取令牌失败: %w", err)
    }

    tm.tokens[supplier] = newToken
    return newToken.AccessToken, nil
}

func (tm *OAuth2TokenManager) Apply(req *http.Request, supplier string) error {
    token, err := tm.GetToken(supplier)
    if err != nil {
        return err
    }

    req.Header.Set("Authorization", "Bearer "+token)
    return nil
}
```

**配置**：
```go
authConfigs := map[string]AuthConfig{
    "expedia": {
        Type:         AuthTypeOAuth2,
        ClientID:     "expedia_client_id",
        ClientSecret: "expedia_client_secret",
        TokenURL:     "https://api.expedia.com/v2/oauth/token",
        Scopes:       []string{"hotel.read", "hotel.write"},
    },
    "travelgds": {
        Type:         AuthTypeOAuth2,
        ClientID:     "gds_client_id",
        ClientSecret: "gds_client_secret",
        TokenURL:     "https://api.travelgds.com/oauth2/token",
        Scopes:       []string{"read:hotels"},
    },
}
```

#### 4. JWT（复杂）

```go
type JWTConfig struct {
    Issuer     string
    Subject    string
    PrivateKey []byte
    Algorithm  string
    Expiry     time.Duration
}

type JWTTokenManager struct {
    configs map[string]*JWTConfig
    tokens  map[string]*jwt.Token
    mu      sync.RWMutex
}

func (jtm *JWTTokenManager) GenerateToken(supplier string) (string, error) {
    jtm.mu.Lock()
    defer jtm.mu.Unlock()

    config := jtm.configs[supplier]

    claims := &jwt.StandardClaims{
        Issuer:    config.Issuer,
        Subject:   config.Subject,
        ExpiresAt: time.Now().Add(config.Expiry).Unix(),
        IssuedAt:  time.Now().Unix(),
    }

    var token *jwt.Token

    switch config.Algorithm {
    case "RS256":
        privateKey, err := jwt.ParseRSAPrivateKeyFromPEM(config.PrivateKey)
        if err != nil {
            return "", err
        }
        token = jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
        return token.SignedString(privateKey)
    case "HS256":
        token = jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
        return token.SignedString(config.PrivateKey)
    default:
        return "", fmt.Errorf("不支持的算法: %s", config.Algorithm)
    }
}

func (jtm *JWTTokenManager) Apply(req *http.Request, supplier string) error {
    token, err := jtm.GenerateToken(supplier)
    if err != nil {
        return err
    }

    req.Header.Set("Authorization", "Bearer "+token)
    return nil
}
```

**配置**：
```go
authConfigs := map[string]AuthConfig{
    "bedbank": {
        Type:       AuthTypeJWT,
        Issuer:     "hotelbyte",
        Subject:    "api-client",
        PrivateKey: []byte(privateKeyPEM),
        Algorithm:  "RS256",
        Expiry:     time.Hour,
    },
}
```

### 认证路由器

```go
type AuthRouter struct {
    managers map[string]AuthManager
    config   map[string]AuthConfig
    mu       sync.RWMutex
}

func (ar *AuthRouter) Apply(req *http.Request, supplier string) error {
    ar.mu.RLock()
    config, exists := ar.config[supplier]
    ar.mu.RUnlock()

    if !exists {
        return fmt.Errorf("没有供应商的认证配置: %s", supplier)
    }

    switch config.Type {
    case AuthTypeBasic, AuthTypeAPIKey:
        manager := &BasicAuthManager{Config: config}
        return manager.Apply(req)
    case AuthTypeHMAC:
        manager := &HMACAuthManager{Config: config}
        return manager.Apply(req)
    case AuthTypeOAuth2:
        manager := &OAuth2TokenManager{Config: config}
        return manager.Apply(req, supplier)
    case AuthTypeJWT:
        manager := &JWTTokenManager{Config: config}
        return manager.Apply(req, supplier)
    default:
        return fmt.Errorf("不支持的认证类型: %s", config.Type)
    }
}
```

## 第二部分：错误处理

### 错误碎片化问题

**供应商使用不同的错误格式**：

**供应商A（HTTP状态+JSON）**:
```json
{
  "error": {
    "code": "AUTH_001",
    "message": "Invalid API credentials",
    "details": "The provided API key is expired"
  }
}
```

**供应商B（HTTP状态+XML）**:
```xml
<Error>
  <Code>AUTHENTICATION_FAILED</Code>
  <Message>Invalid signature</Message>
</Error>
```

**供应商C（仅HTTP状态）**:
```http
HTTP/1.1 401 Unauthorized
X-Error-Code: ERR_AUTH_1001
```

**供应商D（200 OK + 主体中的错误）**:
```json
{
  "status": "error",
  "error": {
    "type": "authentication_error",
    "code": "invalid_credentials"
  }
}
```

### Supplier Proxy的统一错误模型

```go
// 标准化错误结构
type StandardError struct {
    Code        string            `json:"code"`
    Message     string            `json:"message"`
    Category    ErrorCategory     `json:"category"`
    Supplier    string            `json:"supplier"`
    Details     map[string]string `json:"details,omitempty"`
    Timestamp   time.Time         `json:"timestamp"`
    RequestID   string            `json:"request_id"`
    Retryable   bool              `json:"retryable"`
}

type ErrorCategory string

const (
    ErrCategoryAuthentication ErrorCategory = "authentication"
    ErrCategoryAuthorization  ErrorCategory = "authorization"
    ErrCategoryRateLimit      ErrorCategory = "rate_limit"
    ErrCategoryValidation     ErrorCategory = "validation"
    ErrCategoryBusiness       ErrorCategory = "business"
    ErrCategorySystem         ErrorCategory = "system"
)
```

### 错误翻译层

```go
type ErrorTranslator struct {
    translators map[string]ErrorMap
}

type ErrorMap struct {
    CodeMap       map[string]string          // 供应商代码 → 标准代码
    CategoryMap   map[string]ErrorCategory   // 供应商代码 → 类别
    RetryableMap  map[string]bool            // 供应商代码 → 可重试
}

var globalErrorMap = map[string]ErrorMap{
    "hotelbeds": {
        CodeMap: map[string]string{
            "AUTH_001":        "ERR_AUTH_INVALID_CREDENTIALS",
            "AUTH_002":        "ERR_AUTH_EXPIRED_TOKEN",
            "RATE_LIMIT_001":  "ERR_RATE_LIMIT_EXCEEDED",
            "VALIDATION_001":  "ERR_VALIDATION_INVALID_PARAMETER",
        },
        CategoryMap: map[string]ErrorCategory{
            "AUTH_001":       ErrCategoryAuthentication,
            "AUTH_002":       ErrCategoryAuthentication,
            "RATE_LIMIT_001": ErrCategoryRateLimit,
            "VALIDATION_001": ErrCategoryValidation,
        },
        RetryableMap: map[string]bool{
            "AUTH_001":        false,
            "AUTH_002":        true,
            "RATE_LIMIT_001":  true,
            "VALIDATION_001":  false,
        },
    },
    "dida": {
        CodeMap: map[string]string{
            "ERR_AUTH_1001":   "ERR_AUTH_INVALID_CREDENTIALS",
            "ERR_RATE_2001":   "ERR_RATE_LIMIT_EXCEEDED",
        },
        CategoryMap: map[string]ErrorCategory{
            "ERR_AUTH_1001":  ErrCategoryAuthentication,
            "ERR_RATE_2001":  ErrCategoryRateLimit,
        },
        RetryableMap: map[string]bool{
            "ERR_AUTH_1001":  false,
            "ERR_RATE_2001":  true,
        },
    },
    // ... 50家供应商
}

func (et *ErrorTranslator) Translate(supplier string, statusCode int, body []byte) *StandardError {
    errorMap, exists := et.translators[supplier]
    if !exists {
        return et.fallbackError(supplier, statusCode)
    }

    // 解析供应商特定错误
    supplierError := et.parseSupplierError(supplier, body)

    // 翻译为标准格式
    standardCode := errorMap.CodeMap[supplierError.Code]
    if standardCode == "" {
        standardCode = "ERR_UNKNOWN"
    }

    category := errorMap.CategoryMap[supplierError.Code]
    if category == "" {
        category = ErrCategorySystem
    }

    retryable := errorMap.RetryableMap[supplierError.Code]

    return &StandardError{
        Code:       standardCode,
        Message:    supplierError.Message,
        Category:   category,
        Supplier:   supplier,
        Details:    supplierError.Details,
        Timestamp:  time.Now(),
        RequestID:  generateRequestID(),
        Retryable:  retryable,
    }
}
```

### 按供应商解析错误

```go
func (et *ErrorTranslator) parseSupplierError(supplier string, body []byte) *SupplierError {
    var err error
    var supplierError SupplierError

    switch supplier {
    case "hotelbeds", "dida", "expedia", "agoda":
        // JSON错误
        var jsonErr struct {
            Error struct {
                Code    string `json:"code"`
                Message string `json:"message"`
                Details string `json:"details"`
            } `json:"error"`
        }
        err = json.Unmarshal(body, &jsonErr)
        if err == nil {
            supplierError.Code = jsonErr.Error.Code
            supplierError.Message = jsonErr.Error.Message
            supplierError.Details = map[string]string{"details": jsonErr.Error.Details}
        }

    case "travelgds":
        // XML错误
        var xmlErr struct {
            Code    string `xml:"Code"`
            Message string `xml:"Message"`
        }
        err = xml.Unmarshal(body, &xmlErr)
        if err == nil {
            supplierError.Code = xmlErr.Code
            supplierError.Message = xmlErr.Message
        }

    case "bedbank":
        // 200 OK且主体中有错误
        var jsonErr struct {
            Status string `json:"status"`
            Error  struct {
                Type  string `json:"type"`
                Code  string `json:"code"`
                Message string `json:"message"`
            } `json:"error"`
        }
        err = json.Unmarshal(body, &jsonErr)
        if err == nil && jsonErr.Status == "error" {
            supplierError.Code = jsonErr.Error.Code
            supplierError.Message = jsonErr.Error.Message
        }
    }

    if err != nil {
        return et.fallbackSupplierError(supplier, body)
    }

    return &supplierError
}
```

### 错误处理策略

```go
type ErrorHandler struct {
    translator *ErrorTranslator
    logger     *zap.Logger
}

func (eh *ErrorHandler) Handle(supplier string, resp *http.Response, body []byte) error {
    // 翻译错误
    stdErr := eh.translator.Translate(supplier, resp.StatusCode, body)

    // 记录错误
    eh.logger.Error("供应商API错误",
        zap.String("supplier", supplier),
        zap.String("code", stdErr.Code),
        zap.String("message", stdErr.Message),
        zap.String("category", string(stdErr.Category)),
        zap.Bool("retryable", stdErr.Retryable),
    )

    // 按类别处理
    switch stdErr.Category {
    case ErrCategoryAuthentication:
        return &AuthenticationError{StandardError: stdErr}
    case ErrCategoryRateLimit:
        return &RateLimitError{StandardError: stdErr}
    case ErrCategoryValidation:
        return &ValidationError{StandardError: stdErr}
    case ErrCategoryBusiness:
        return &BusinessError{StandardError: stdErr}
    default:
        return &SystemError{StandardError: stdErr}
    }
}

// 在应用程序中使用
func SearchHotels(req *SearchRequest) (*Response, error) {
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }

    if resp.StatusCode >= 400 {
        body, _ := io.ReadAll(resp.Body)
        resp.Body.Close()

        // 使用错误处理器
        err := errorHandler.Handle("hotelbeds", resp, body)

        // 检查错误类型
        if rateLimitErr, ok := err.(*RateLimitError); ok {
            // 带退避重试
            return RetryWithBackoff(req, rateLimitErr)
        }

        if authErr, ok := err.(*AuthenticationError); ok {
            // 刷新认证并重试
            return RetryWithAuthRefresh(req, authErr)
        }

        return nil, err
    }

    // 处理成功响应
    return processResponse(resp)
}
```

## 实际影响

### 案例研究：认证简化

**使用Supplier Proxy之前**：
```
认证代码：5,200行
代码复杂度：高
维护负担：很高
新供应商认证时间：2-3天
认证相关错误：每月8-12个
```

**使用Supplier Proxy之后**：
```
认证代码：1,800行（集中化）
代码复杂度：低
维护负担：低
新供应商认证时间：1-2小时
认证相关错误：0（在代理中处理）
```

**影响**：
- 认证代码**减少65%**
- 新供应商认证时间**减少90%**
- 认证相关错误**减少100%**
- 集中管理50家供应商的认证

### 案例研究：错误处理简化

**使用Supplier Proxy之前**：
```
错误处理代码：3,400行
错误类型：15-20
开发人员花在错误上的时间：总计30%
面向用户的错误消息：不一致
```

**使用Supplier Proxy之后**：
```
错误处理代码：800行（统一）
错误类型：6个标准类别
开发人员花在错误上的时间：总计5%
面向用户的错误消息：一致
```

**影响**：
- 错误处理代码**减少76%**
- 开发人员花在错误上的时间**减少83%**
- **一致的错误体验**跨所有供应商

## 最佳实践

### 认证最佳实践

1. **安全凭证存储** - 使用保险库、环境变量
2. **令牌缓存** - 不要每次请求都获取令牌
3. **主动刷新** - 不要等待401错误
4. **轮换凭证** - 定期凭证轮换
5. **监控认证失败** - 对高认证错误率发出警报

### 错误处理最佳实践

1. **标准化错误代码** - 所有供应商一套代码
2. **分类错误** - 认证、限流、验证、业务
3. **标记可重试错误** - 不要在客户端错误上重试
4. **记录所有内容** - 用于调试的完整错误上下文
5. **翻译消息** - 用户友好的错误消息

## 总结

Supplier Proxy的认证和错误处理：

**认证**：
- 支持9种不同认证协议
- 自动令牌管理
- 集中化配置
- 安全凭证处理

**错误处理**：
- 统一错误模型
- 为50+供应商翻译
- 分类错误类型
- 内置重试逻辑

**结果**：代码减少65%，供应商上线速度提升90%，一致的错误体验。

**下一篇**：[Supplier Proxy架构和可扩展性](/blog/zh/2026/02/14/supplier-proxy-3-architecture-scalability.html)

---

## 推荐阅读

- [OAuth 2.0最佳实践](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [JWT最佳实践](https://datatracker.ietf.org/doc/html/rfc8725)
- [API错误处理最佳实践](https://restfulapi.net/http-status-codes/)

---

## 系列导航

**Supplier Proxy系列**：
1. [什么是Supplier Proxy及它在酒店API聚合中的作用](/blog/zh/2026/02/10/supplier-proxy-1-what-is-supplier-proxy.html)
2. Supplier Proxy如何处理认证和错误处理 ← 你在这里
3. [Supplier Proxy架构和可扩展性](/blog/zh/2026/02/14/supplier-proxy-3-architecture-scalability.html)
4. [成本效益和ROI分析](/blog/zh/2026/02/16/supplier-proxy-4-cost-benefits-roi.html)

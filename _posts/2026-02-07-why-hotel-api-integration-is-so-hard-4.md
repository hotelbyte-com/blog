---
layout: post
title: "为什么酒店API集成这么难？（4）错误处理：同一个错误，5种不同的状态码"
date: 2026-02-07 05:30:00 +0000
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, error-handling, retry-strategy]
author: "HotelByte Team"
description: "酒店API集成的第四个噩梦：错误处理。5家供应商，5种不同的HTTP状态码和错误消息——400、401、403、404、429...你写过100+行的错误码映射表吗？"
reading_time: "16分钟"
---

> 这是"为什么酒店API集成这么难？"系列的第4篇。
> 
> [第1篇：认证地狱](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/) | 
> [第2篇：数据混乱](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/) | 
> [第3篇：限流噩梦](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/) | 
> [第5篇：时区问题](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-5/)（即将发布）

---

## 你写过错误码映射表吗？100+行代码？

### 真实场景

你的搜索功能接入了5家供应商。

**用户搜索伦敦的酒店**：
- 调用供应商A → 400 Bad Request
- 调用供应商B → 401 Unauthorized
- 调用供应商C → 403 Forbidden
- 调用供应商D → 404 Not Found
- 调用供应商E → 500 Internal Server Error

**问题来了**：
- 为什么是400？不是200？
- 400和401有什么区别？
- 403和404有什么区别？
- 500意味着什么？

### 你怎么处理这些错误？

**方法1：直接返回给用户**
```python
if response.status_code == 400:
    return {"error": "400 Bad Request"}
elif response.status_code == 401:
    return {"error": "401 Unauthorized"}
elif response.status_code == 403:
    return {"error": "403 Forbidden"}
elif response.status_code == 404:
    return {"error": "404 Not Found"}
elif response.status_code == 500:
    return {"error": "500 Internal Server Error"}
```

**用户投诉**：
- "什么是400 Bad Request？"
- "为什么401 Unauthorized？我的密码是对的！"
- "为什么403 Forbidden？我有权限啊！"
- "为什么404 Not Found？酒店明明存在！"
- "为什么500 Internal Server Error？你们系统坏了吗？"

**方法2：错误码映射**
```python
error_mapping = {
    "supplier_a": {
        400: "INVALID_REQUEST",
        401: "AUTH_FAILED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        500: "SERVER_ERROR",
    },
    "supplier_b": {
        400: "BAD_REQUEST",
        401: "UNAUTHORIZED",
        403: "PERMISSION_DENIED",
        404: "HOTEL_NOT_FOUND",
        500: "INTERNAL_ERROR",
    },
    "supplier_c": {
        400: "ERROR_INVALID_INPUT",
        401: "ERROR_AUTHENTICATION",
        403: "ERROR_AUTHORIZATION",
        404: "ERROR_HOTEL_NOT_FOUND",
        500: "ERROR_SERVER",
    },
    "supplier_d": {
        400: "E001",
        401: "E002",
        403: "E003",
        404: "E004",
        500: "E005",
    },
    "supplier_e": {
        400: "INVALID_REQUEST",
        401: "AUTH_ERROR",
        403: "FORBIDDEN_ERROR",
        404: "NOT_FOUND_ERROR",
        500: "SERVER_ERROR",
    },
}

def handle_error(supplier, status_code):
    unified_error = error_mapping[supplier][status_code]
    return {"error": unified_error}
```

**问题**：
- ⚠️ 5家供应商，25个错误码
- ⚠️ 每家供应商的错误码含义不同
- ⚠️ 错误消息语言不同（英文/中文/西班牙文）
- ⚠️ 有些错误码没有说明

---

## 痛点1：HTTP状态码不一致

### 5家供应商，5种不同的HTTP状态码

| 场景 | 供应商A | 供应商B | 供应商C | 供应商D | 供应商E |
|------|---------|---------|---------|---------|---------|
| 认证失败 | 401 | 401 | 401 | 403 | 401 |
| 权限不足 | 403 | 401 | 403 | 403 | 401 |
| 资源不存在 | 404 | 404 | 404 | 404 | 400 |
| 参数错误 | 400 | 400 | 400 | 400 | 400 |
| 限流 | 429 | 403 | 429 | 429 | 429 |
| 服务器错误 | 500 | 500 | 500 | 502 | 500 |

### 问题：同样的错误，不同的状态码

#### 场景1：权限不足

- **供应商A**：403 Forbidden（正确）
- **供应商B**：401 Unauthorized（不正确，应该是403）
- **供应商C**：403 Forbidden（正确）
- **供应商D**：403 Forbidden（正确）
- **供应商E**：401 Unauthorized（不正确，应该是403）

#### 场景2：酒店不存在

- **供应商A**：404 Not Found（正确）
- **供应商B**：404 Not Found（正确）
- **供应商C**：404 Not Found（正确）
- **供应商D**：404 Not Found（正确）
- **供应商E**：400 Bad Request（不正确，应该是404）

#### 场景3：限流

- **供应商A**：429 Too Many Requests（正确）
- **供应商B**：403 Forbidden（不正确，应该是429）
- **供应商C**：429 Too Many Requests（正确）
- **供应商D**：429 Too Many Requests（正确）
- **供应商E**：429 Too Many Requests（正确）

---

## 痛点2：错误码混乱

### 5家供应商，5种不同的错误码

| 场景 | 供应商A | 供应商B | 供应商C | 供应商D | 供应商E |
|------|---------|---------|---------|---------|---------|
| 认证失败 | AUTH_001 | UNAUTHORIZED | ERROR_AUTHENTICATION | E002 | AUTH_ERROR |
| 权限不足 | AUTH_002 | PERMISSION_DENIED | ERROR_AUTHORIZATION | E003 | AUTH_ERROR |
| 酒店不存在 | HOTEL_NOT_FOUND | NOT_FOUND | ERROR_HOTEL_NOT_FOUND | E004 | NOT_FOUND_ERROR |
| 参数错误 | INVALID_REQUEST | BAD_REQUEST | ERROR_INVALID_INPUT | E001 | INVALID_REQUEST |
| 限流 | RATE_LIMIT_EXCEEDED | TOO_MANY_REQUESTS | ERROR_RATE_LIMIT | E006 | RATE_LIMIT_ERROR |

### 问题：错误码命名不统一

#### 前缀混乱

- `AUTH_`（供应商A）
- `ERROR_`（供应商C）
- `E00X`（供应商D）
- 无前缀（供应商B、E）

#### 命名风格混乱

- `UPPER_CASE_WITH_UNDERSCORE`（供应商A、B）
- `ERROR_UPPER_CASE_WITH_UNDERSCORE`（供应商C）
- `E00X`（供应商D）
- `UPPER_CASE_WITH_SUFFIX_ERROR`（供应商E）

---

## 痛点3：错误消息语言不同

### 5家供应商，5种不同的错误消息语言

| 场景 | 供应商A | 供应商B | 供应商C | 供应商D | 供应商E |
|------|---------|---------|---------|---------|---------|
| 认证失败 | Authentication failed | Invalid credentials | 认证失败 | Error: Auth failed | Autenticación fallida |
| 酒店不存在 | Hotel not found | Hotel does not exist | 酒店不存在 | Error: Hotel not found | Hôtel introuvable |
| 参数错误 | Invalid request parameters | Bad request | 参数错误 | Error: Invalid params | Paramètres invalides |
| 限流 | Rate limit exceeded | Too many requests | 限流 | Error: Rate limit | Límite de tasa |

### 问题：错误消息语言不统一

- **供应商A、B**：英文
- **供应商C**：中文
- **供应商D**：英文 + Error: 前缀
- **供应商E**：西班牙文

**用户投诉**：
- "为什么有些错误是英文，有些是中文？"
- "为什么我看不懂错误消息？"

---

## 痛点4：什么时候该重试？

### 真实场景

**你的搜索功能调用供应商API失败**：
- 供应商A：400 Bad Request（参数错误）
- 供应商B：401 Unauthorized（认证失败）
- 供应商C：403 Forbidden（权限不足）
- 供应商D：404 Not Found（酒店不存在）
- 供应商E：500 Internal Server Error（服务器错误）

### 问题来了：哪些错误应该重试？

#### 应该重试的错误（临时性错误）

- 429 Too Many Requests（限流，等待后重试）
- 500 Internal Server Error（服务器错误，重试）
- 502 Bad Gateway（网关错误，重试）
- 503 Service Unavailable（服务不可用，重试）
- 504 Gateway Timeout（网关超时，重试）

#### 不应该重试的错误（永久性错误）

- 400 Bad Request（参数错误，重试没用）
- 401 Unauthorized（认证失败，修复认证后重试）
- 403 Forbidden（权限不足，重试没用）
- 404 Not Found（资源不存在，重试没用）

#### 可能重试也可能不重试的错误

- 408 Request Timeout（可能是网络问题，可能是服务器超时）

### 你怎么判断？

**方法1：硬编码**
```python
def should_retry(status_code):
    return status_code in [429, 500, 502, 503, 504]
```

**问题**：
- ⚠️ 每个供应商的错误码不同
- ⚠️ 需要维护5个不同的重试规则
- ⚠️ 有些错误码没有说明

---

## 痛点5：重试策略复杂

### 真实场景

**你的搜索功能需要处理重试**：

#### 场景1：限流（429 Too Many Requests）

- 第一次调用：429 Too Many Requests，Retry-After: 60
- 等待60秒
- 第二次调用：429 Too Many Requests，Retry-After: 60
- 等待60秒
- 第三次调用：200 OK

**总等待时间**：120秒

**用户投诉**："为什么这么慢？"

#### 场景2：服务器错误（500 Internal Server Error）

- 第一次调用：500 Internal Server Error
- 立即重试：500 Internal Server Error
- 等待1秒后重试：500 Internal Server Error
- 等待2秒后重试：500 Internal Server Error
- 等待4秒后重试：500 Internal Server Error
- 等待8秒后重试：200 OK

**总等待时间**：15秒

**用户投诉**："为什么搜索这么慢？"

#### 场景3：网络错误

- 第一次调用：Connection timeout
- 立即重试：Connection timeout
- 等待1秒后重试：Connection timeout
- 等待2秒后重试：Connection timeout
- 等待4秒后重试：Connection timeout
- 等待8秒后重试：Connection timeout

**总等待时间**：15秒，还是失败

**用户投诉**："为什么一直显示错误？"

---

## 痛点6：错误聚合困难

### 真实场景

**你的搜索功能调用5家供应商**：
- 供应商A：200 OK（成功）
- 供应商B：200 OK（成功）
- 供应商C：404 Not Found（失败）
- 供应商D：429 Too Many Requests（失败）
- 供应商E：500 Internal Server Error（失败）

### 问题来了：怎么返回错误给用户？

**方法1：返回第一个错误**
```python
result = search_all_suppliers(hotel_id)
if result.errors:
    return {"error": result.errors[0]}  # 只返回第一个错误
```

**用户投诉**：
- "为什么只显示一个错误？"
- "我有3家供应商失败了，为什么只告诉我1家？"

**方法2：返回所有错误**
```python
result = search_all_suppliers(hotel_id)
return {
    "errors": result.errors,  # 返回所有错误
    "hotels": result.hotels
}
```

**用户投诉**：
- "为什么有这么多错误？"
- "我该怎么办？"

**方法3：统一错误**
```python
result = search_all_suppliers(hotel_id)
if len(result.errors) >= 3:
    # 3家或以上失败，返回统一错误
    return {"error": "部分供应商暂时不可用，请稍后重试"}
else:
    # 1-2家失败，返回详细错误
    return {
        "errors": result.errors,
        "hotels": result.hotels
    }
```

**用户投诉**：
- "为什么有时候详细错误，有时候统一错误？"
- " inconsistent behavior！"

---

## 我们如何解决

### 核心思路：统一错误模型

**问题**：5家供应商，5种不同的HTTP状态码、错误码、错误消息。

**解决方案**：统一错误模型 + 智能重试 + 错误聚合

```
供应商A → 标准化层 → 统一错误模型
供应商B → 标准化层 → 统一错误模型
供应商C → 标准化层 → 统一错误模型
供应商D → 标准化层 → 统一错误模型
供应商E → 标准化层 → 统一错误模型
```

---

### 1. 统一错误模型

#### 错误分类

```yaml
# 认证错误
AuthenticationError:
  INVALID_CREDENTIALS: "Invalid API key or secret"
  EXPIRED_CREDENTIALS: "API key has expired"
  MISSING_CREDENTIALS: "API key or secret is missing"

# 授权错误
AuthorizationError:
  INSUFFICIENT_PERMISSIONS: "Insufficient permissions"
  FORBIDDEN: "Access forbidden"

# 请求错误
RequestError:
  INVALID_PARAMETERS: "Invalid request parameters"
  MISSING_REQUIRED_PARAMETER: "Missing required parameter: {param}"
  INVALID_PARAMETER_VALUE: "Invalid value for parameter: {param}"
  INVALID_PARAMETER_TYPE: "Invalid type for parameter: {param}"

# 资源错误
ResourceError:
  HOTEL_NOT_FOUND: "Hotel not found: {hotel_id}"
  ROOM_NOT_FOUND: "Room not found: {room_id}"
  RATE_PLAN_NOT_FOUND: "Rate plan not found: {rate_plan_id}"

# 业务错误
BusinessError:
  AVAILABILITY_NOT_FOUND: "No availability found"
  CHECK_IN_DATE_INVALID: "Check-in date is invalid"
  CHECK_OUT_DATE_INVALID: "Check-out date is invalid"
  MIN_NIGHTS_NOT_MET: "Minimum {min_nights} nights required"

# 限流错误
RateLimitError:
  RATE_LIMIT_EXCEEDED: "Rate limit exceeded, please try again later"
  SINGLE_HOTEL_RATE_LIMIT: "Rate limit exceeded for hotel: {hotel_id}"

# 服务器错误
ServerError:
  INTERNAL_ERROR: "Internal server error"
  BAD_GATEWAY: "Bad gateway"
  SERVICE_UNAVAILABLE: "Service unavailable"
  GATEWAY_TIMEOUT: "Gateway timeout"

# 网络错误
NetworkError:
  CONNECTION_TIMEOUT: "Connection timeout"
  READ_TIMEOUT: "Read timeout"
  CONNECTION_ERROR: "Connection error"
```

#### 统一错误响应

```json
{
  "error": {
    "code": "HOTEL_NOT_FOUND",
    "message": "Hotel not found: LON123",
    "type": "ResourceError",
    "retryable": false,
    "supplier": "supplier_a",
    "original_error": {
      "status_code": 404,
      "code": "HOTEL_NOT_FOUND",
      "message": "Hotel not found"
    }
  }
}
```

---

### 2. 错误码映射

#### 自动映射

```python
class ErrorMapper:
    def __init__(self):
        self.mappings = self._load_mappings()
    
    def _load_mappings(self):
        # 1. 从文档加载映射规则
        docs_mappings = self._load_from_docs()
        
        # 2. 从历史错误加载映射规则
        history_mappings = self._load_from_history()
        
        # 3. 合并映射规则
        return self._merge_mappings(docs_mappings, history_mappings)
    
    def map_error(self, supplier, original_error):
        # 1. 查找映射规则
        mapping = self.mappings.get(supplier, {}).get(
            original_error.code
        )
        
        if not mapping:
            # 2. 没有映射规则，使用规则引擎推断
            mapping = self._infer_error(original_error)
        
        # 3. 返回统一错误
        return UnifiedError(
            code=mapping.code,
            message=mapping.message,
            type=mapping.type,
            retryable=mapping.retryable,
            supplier=supplier,
            original_error=original_error
        )
    
    def _infer_error(self, original_error):
        # 1. 根据HTTP状态码推断
        if original_error.status_code in [400, 422]:
            return ErrorMapping(
                code="INVALID_PARAMETERS",
                message="Invalid request parameters",
                type="RequestError",
                retryable=False
            )
        elif original_error.status_code == 401:
            return ErrorMapping(
                code="INVALID_CREDENTIALS",
                message="Invalid API key or secret",
                type="AuthenticationError",
                retryable=False
            )
        elif original_error.status_code == 403:
            return ErrorMapping(
                code="INSUFFICIENT_PERMISSIONS",
                message="Insufficient permissions",
                type="AuthorizationError",
                retryable=False
            )
        elif original_error.status_code == 404:
            return ErrorMapping(
                code="HOTEL_NOT_FOUND",
                message="Hotel not found",
                type="ResourceError",
                retryable=False
            )
        elif original_error.status_code == 429:
            return ErrorMapping(
                code="RATE_LIMIT_EXCEEDED",
                message="Rate limit exceeded",
                type="RateLimitError",
                retryable=True
            )
        elif original_error.status_code >= 500:
            return ErrorMapping(
                code="INTERNAL_ERROR",
                message="Internal server error",
                type="ServerError",
                retryable=True
            )
```

---

### 3. 智能重试

#### 重试策略

```python
class RetryStrategy:
    def __init__(self):
        self.retryable_errors = {
            "RATE_LIMIT_EXCEEDED": self._retry_with_backoff,
            "INTERNAL_ERROR": self._retry_with_exponential_backoff,
            "BAD_GATEWAY": self._retry_with_exponential_backoff,
            "SERVICE_UNAVAILABLE": self._retry_with_exponential_backoff,
            "GATEWAY_TIMEOUT": self._retry_with_exponential_backoff,
            "CONNECTION_TIMEOUT": self._retry_with_exponential_backoff,
            "READ_TIMEOUT": self._retry_with_exponential_backoff,
            "CONNECTION_ERROR": self._retry_with_exponential_backoff,
        }
    
    async def should_retry(self, error):
        retry_func = self.retryable_errors.get(error.code)
        return retry_func is not None
    
    async def retry(self, supplier, request, error):
        retry_func = self.retryable_errors.get(error.code)
        return await retry_func(supplier, request, error)
    
    async def _retry_with_backoff(self, supplier, request, error):
        # 限流错误：使用Retry-After头
        retry_after = error.original_error.headers.get('Retry-After', 60)
        await asyncio.sleep(int(retry_after))
        return await supplier.request(request)
    
    async def _retry_with_exponential_backoff(self, supplier, request, error):
        # 其他错误：使用指数退避
        max_retries = 5
        base_delay = 1.0  # 秒
        
        for attempt in range(max_retries):
            try:
                return await supplier.request(request)
            except Exception as e:
                if attempt == max_retries - 1:
                    raise  # 最后一次尝试失败
                
                delay = base_delay * (2 ** attempt)
                await asyncio.sleep(delay)
```

---

### 4. 错误聚合

#### 多供应商错误聚合

```python
async def search_all_suppliers_with_error_aggregation(hotel_id):
    # 1. 并发调用所有供应商
    tasks = []
    for supplier in suppliers:
        task = asyncio.create_task(
            search_supplier_with_retry(supplier, hotel_id)
        )
        tasks.append(task)
    
    # 2. 收集结果和错误
    results = []
    errors = []
    for task in tasks:
        try:
            result = await task
            results.append(result)
        except UnifiedError as error:
            errors.append(error)
    
    # 3. 错误聚合
    aggregated_error = self._aggregate_errors(errors)
    
    # 4. 返回结果
    return {
        "hotels": results,
        "error": aggregated_error,
        "partial_success": len(results) > 0
    }
    
def _aggregate_errors(self, errors):
    # 1. 按错误类型分类
    error_types = {}
    for error in errors:
        if error.type not in error_types:
            error_types[error.type] = []
        error_types[error.type].append(error)
    
    # 2. 如果所有供应商都失败，返回统一错误
    if len(errors) == len(suppliers):
        return UnifiedError(
            code="ALL_SUPPLIERS_FAILED",
            message="All suppliers are temporarily unavailable, please try again later",
            type="ServerError",
            retryable=True,
            details=error_types
        )
    
    # 3. 如果部分供应商失败，返回详细错误
    if len(errors) >= 3:
        # 3家或以上失败，返回简化错误
        return UnifiedError(
            code="SOME_SUPPLIERS_FAILED",
            message=f"{len(errors)} suppliers failed, showing results from available suppliers",
            type="ServerError",
            retryable=True,
            details=error_types
        )
    else:
        # 1-2家失败，返回详细错误
        return UnifiedError(
            code="SOME_SUPPLIERS_FAILED",
            message=f"{len(errors)} suppliers failed",
            type="ServerError",
            retryable=True,
            details=error_types
        )
```

---

## 我们的优势

### 1. 统一错误模型

- 标准化的错误码和错误消息
- 清晰的错误分类
- 所有错误都遵循相同的格式

### 2. 智能错误映射

- 自动映射供应商错误码到统一错误码
- 规则引擎推断未知错误
- 持续学习历史错误

### 3. 智能重试策略

- 自动识别可重试错误
- 指数退避策略
- 限流错误使用Retry-After头

### 4. 错误聚合

- 多供应商错误统一返回
- 智能判断错误级别
- 用户友好的错误消息

### 5. 实时监控

- 实时监控错误率
- 实时监控重试成功率
- 实时监控供应商可用性

---

## 行动号召

### 你写过100+行的错误码映射表吗？

**问题**：
- 5家供应商，5种不同的HTTP状态码
- 5家供应商，5种不同的错误码
- 5家供应商，5种不同的错误消息（不同语言）
- 什么时候该重试？
- 重试策略怎么实现？
- 多供应商错误怎么聚合？

**我们的解决方案**：
- 统一错误模型（标准化错误码和错误消息）
- 智能错误映射（自动映射供应商错误）
- 智能重试策略（自动识别可重试错误，指数退避）
- 错误聚合（多供应商错误统一返回）

**你只需要**：
```go
import "github.com/hotelbyte-com/sdk-go/hotelbyte"

client := hotelbyte.NewClient("YOUR_API_KEY")

// 搜索酒店（自动处理错误、重试、聚合）
result, err := client.SearchHotels(&hotelbyte.SearchRequest{
    Destination: "London",
    CheckIn:     time.Date(2026, 2, 10, 0, 0, 0, 0, time.UTC),
    CheckOut:    time.Date(2026, 2, 12, 0, 0, 0, 0, time.UTC),
    Guests:      2,
})

if err != nil {
    // 统一错误格式
    switch e := err.(type) {
    case *hotelbyte.RateLimitError:
        fmt.Println("Rate limited, please try again later")
    case *hotelbyte.HotelNotFoundError:
        fmt.Printf("Hotel not found: %s\n", e.HotelID)
    case *hotelbyte.AuthenticationError:
        fmt.Println("Invalid API key")
    default:
        fmt.Printf("Error: %s\n", err.Error())
    }
    return
}

// 返回标准化结果
for _, hotel := range result.Hotels {
    fmt.Printf("%s: $%.2f\n", hotel.Name, hotel.TotalPrice)
}
```

**没有100+行的错误码映射表。没有复杂的重试策略。只有统一的错误模型。**

---

## 下一步

### 免费试用

- 30天免费试用
- 无需信用卡
- 立即开始测试

**[免费试用30天](https://waitlist.hotelbyte.com)**

### 查看文档

- API文档：[openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- SDK文档：[docs.hotelbyte.com](https://docs.hotelbyte.com)
- 最佳实践：[blog.hotelbyte.com](https://blog.hotelbyte.com)

### 联系我们

有问题？直接联系我们的工程师。

**[联系我们](mailto:support@hotelbyte.com)**

---

## 系列导航

- [第1篇：认证地狱](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/)
- [第2篇：数据混乱](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/)
- [第3篇：限流噩梦](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/)
- [第4篇：错误处理（本文）](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/)
- [第5篇：时区问题（即将发布）](#)

---

**下一篇预告：时区问题 - 用户选了明天入住，供应商以为是昨天**

---

*阅读时间：约16分钟*
*难度：中等（需要了解HTTP状态码、错误处理、重试策略）*

---
layout: post
title: "Why Hotel API Integration Is So Hard? (4) Error Handling: Same Error, 5 Different Status Codes"
date: 2026-02-07 05:30:00 +0000
lang: en
categories: [developer-experience, api-integration]
tags: [hotel-api, api-integration, error-handling, retry-strategy]
author: "HotelByte Team"
description: "The fourth nightmare of hotel API integration: error handling. 5 suppliers, 5 different HTTP status codes and error messages—400, 401, 403, 404, 429... Have you written a 100+ line error code mapping table?"
reading_time: "16 minutes"
---

> This is Part 4 of the "Why Hotel API Integration Is So Hard?" series.
> 
> [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/) | 
> [Part 2: Data Chaos](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/) | 
> [Part 3: Rate Limiting Nightmare](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/) | 
> [Part 5: Timezone Issues](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-5/) (Coming Soon)

---

## Have You Written an Error Code Mapping Table? 100+ Lines of Code?

### Real-World Scenario

Your search function integrates with 5 suppliers.

**User searches for hotels in London**:
- Call Supplier A → 400 Bad Request
- Call Supplier B → 401 Unauthorized
- Call Supplier C → 403 Forbidden
- Call Supplier D → 404 Not Found
- Call Supplier E → 500 Internal Server Error

**Here's the problem**:
- Why is it 400? Not 200?
- What's the difference between 400 and 401?
- What's the difference between 403 and 404?
- What does 500 mean?

### How Do You Handle These Errors?

**Method 1: Return directly to users**
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

**User complaints**:
- "What is 400 Bad Request?"
- "Why 401 Unauthorized? My password is correct!"
- "Why 403 Forbidden? I have permission!"
- "Why 404 Not Found? The hotel clearly exists!"
- "Why 500 Internal Server Error? Is your system down?"

**Method 2: Error code mapping**
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

**Problems**:
- ⚠️ 5 suppliers, 25 error codes
- ⚠️ Each supplier's error codes mean different things
- ⚠️ Error message languages differ (English/Chinese/Spanish)
- ⚠️ Some error codes have no documentation

---

## Pain Point 1: Inconsistent HTTP Status Codes

### 5 Suppliers, 5 Different HTTP Status Codes

| Scenario | Supplier A | Supplier B | Supplier C | Supplier D | Supplier E |
|----------|------------|------------|------------|------------|------------|
| Auth failed | 401 | 401 | 401 | 403 | 401 |
| Insufficient permissions | 403 | 401 | 403 | 403 | 401 |
| Resource not found | 404 | 404 | 404 | 404 | 400 |
| Parameter error | 400 | 400 | 400 | 400 | 400 |
| Rate limited | 429 | 403 | 429 | 429 | 429 |
| Server error | 500 | 500 | 500 | 502 | 500 |

### Problem: Same Error, Different Status Codes

#### Scenario 1: Insufficient Permissions

- **Supplier A**: 403 Forbidden (correct)
- **Supplier B**: 401 Unauthorized (incorrect, should be 403)
- **Supplier C**: 403 Forbidden (correct)
- **Supplier D**: 403 Forbidden (correct)
- **Supplier E**: 401 Unauthorized (incorrect, should be 403)

#### Scenario 2: Hotel Not Found

- **Supplier A**: 404 Not Found (correct)
- **Supplier B**: 404 Not Found (correct)
- **Supplier C**: 404 Not Found (correct)
- **Supplier D**: 404 Not Found (correct)
- **Supplier E**: 400 Bad Request (incorrect, should be 404)

#### Scenario 3: Rate Limiting

- **Supplier A**: 429 Too Many Requests (correct)
- **Supplier B**: 403 Forbidden (incorrect, should be 429)
- **Supplier C**: 429 Too Many Requests (correct)
- **Supplier D**: 429 Too Many Requests (correct)
- **Supplier E**: 429 Too Many Requests (correct)

---

## Pain Point 2: Error Code Chaos

### 5 Suppliers, 5 Different Error Codes

| Scenario | Supplier A | Supplier B | Supplier C | Supplier D | Supplier E |
|----------|------------|------------|------------|------------|------------|
| Auth failed | AUTH_001 | UNAUTHORIZED | ERROR_AUTHENTICATION | E002 | AUTH_ERROR |
| Insufficient permissions | AUTH_002 | PERMISSION_DENIED | ERROR_AUTHORIZATION | E003 | AUTH_ERROR |
| Hotel not found | HOTEL_NOT_FOUND | NOT_FOUND | ERROR_HOTEL_NOT_FOUND | E004 | NOT_FOUND_ERROR |
| Parameter error | INVALID_REQUEST | BAD_REQUEST | ERROR_INVALID_INPUT | E001 | INVALID_REQUEST |
| Rate limited | RATE_LIMIT_EXCEEDED | TOO_MANY_REQUESTS | ERROR_RATE_LIMIT | E006 | RATE_LIMIT_ERROR |

### Problem: Inconsistent Error Code Naming

#### Prefix Chaos

- `AUTH_` (Supplier A)
- `ERROR_` (Supplier C)
- `E00X` (Supplier D)
- No prefix (Suppliers B, E)

#### Naming Style Chaos

- `UPPER_CASE_WITH_UNDERSCORE` (Suppliers A, B)
- `ERROR_UPPER_CASE_WITH_UNDERSCORE` (Supplier C)
- `E00X` (Supplier D)
- `UPPER_CASE_WITH_SUFFIX_ERROR` (Supplier E)

---

## Pain Point 3: Different Error Message Languages

### 5 Suppliers, 5 Different Error Message Languages

| Scenario | Supplier A | Supplier B | Supplier C | Supplier D | Supplier E |
|----------|------------|------------|------------|------------|------------|
| Auth failed | Authentication failed | Invalid credentials | 认证失败 | Error: Auth failed | Autenticación fallida |
| Hotel not found | Hotel not found | Hotel does not exist | 酒店不存在 | Error: Hotel not found | Hôtel introuvable |
| Parameter error | Invalid request parameters | Bad request | 参数错误 | Error: Invalid params | Paramètres invalides |
| Rate limited | Rate limit exceeded | Too many requests | 限流 | Error: Rate limit | Límite de tasa |

### Problem: Inconsistent Error Message Languages

- **Suppliers A, B**: English
- **Supplier C**: Chinese
- **Supplier D**: English + "Error:" prefix
- **Supplier E**: Spanish

**User complaints**:
- "Why are some errors in English and some in Chinese?"
- "Why can't I understand the error messages?"

---

## Pain Point 4: When Should You Retry?

### Real-World Scenario

**Your search function calls supplier API and fails**:
- Supplier A: 400 Bad Request (parameter error)
- Supplier B: 401 Unauthorized (authentication failed)
- Supplier C: 403 Forbidden (insufficient permissions)
- Supplier D: 404 Not Found (hotel not found)
- Supplier E: 500 Internal Server Error (server error)

### Problem: Which Errors Should Be Retried?

#### Errors That Should Be Retried (Temporary Errors)

- 429 Too Many Requests (rate limited, wait then retry)
- 500 Internal Server Error (server error, retry)
- 502 Bad Gateway (gateway error, retry)
- 503 Service Unavailable (service unavailable, retry)
- 504 Gateway Timeout (gateway timeout, retry)

#### Errors That Should NOT Be Retried (Permanent Errors)

- 400 Bad Request (parameter error, retrying won't help)
- 401 Unauthorized (authentication failed, fix auth then retry)
- 403 Forbidden (insufficient permissions, retrying won't help)
- 404 Not Found (resource doesn't exist, retrying won't help)

#### Errors That May or May Not Be Retried

- 408 Request Timeout (could be network issue, could be server timeout)

### How Do You Decide?

**Method 1: Hardcoding**
```python
def should_retry(status_code):
    return status_code in [429, 500, 502, 503, 504]
```

**Problems**:
- ⚠️ Each supplier has different error codes
- ⚠️ Need to maintain 5 different retry rules
- ⚠️ Some error codes have no documentation

---

## Pain Point 5: Complex Retry Strategies

### Real-World Scenario

**Your search function needs to handle retries**:

#### Scenario 1: Rate Limiting (429 Too Many Requests)

- First call: 429 Too Many Requests, Retry-After: 60
- Wait 60 seconds
- Second call: 429 Too Many Requests, Retry-After: 60
- Wait 60 seconds
- Third call: 200 OK

**Total wait time**: 120 seconds

**User complaint**: "Why is it so slow?"

#### Scenario 2: Server Error (500 Internal Server Error)

- First call: 500 Internal Server Error
- Immediate retry: 500 Internal Server Error
- Wait 1 second then retry: 500 Internal Server Error
- Wait 2 seconds then retry: 500 Internal Server Error
- Wait 4 seconds then retry: 500 Internal Server Error
- Wait 8 seconds then retry: 200 OK

**Total wait time**: 15 seconds

**User complaint**: "Why is the search so slow?"

#### Scenario 3: Network Error

- First call: Connection timeout
- Immediate retry: Connection timeout
- Wait 1 second then retry: Connection timeout
- Wait 2 seconds then retry: Connection timeout
- Wait 4 seconds then retry: Connection timeout
- Wait 8 seconds then retry: Connection timeout

**Total wait time**: 15 seconds, still failed

**User complaint**: "Why does it keep showing errors?"

---

## Pain Point 6: Difficulty Aggregating Errors

### Real-World Scenario

**Your search function calls 5 suppliers**:
- Supplier A: 200 OK (success)
- Supplier B: 200 OK (success)
- Supplier C: 404 Not Found (failure)
- Supplier D: 429 Too Many Requests (failure)
- Supplier E: 500 Internal Server Error (failure)

### Problem: How to Return Errors to Users?

**Method 1: Return first error**
```python
result = search_all_suppliers(hotel_id)
if result.errors:
    return {"error": result.errors[0]}  # Only return first error
```

**User complaints**:
- "Why only show one error?"
- "I have 3 suppliers that failed, why tell me only 1?"

**Method 2: Return all errors**
```python
result = search_all_suppliers(hotel_id)
return {
    "errors": result.errors,  # Return all errors
    "hotels": result.hotels
}
```

**User complaints**:
- "Why so many errors?"
- "What should I do?"

**Method 3: Unified error**
```python
result = search_all_suppliers(hotel_id)
if len(result.errors) >= 3:
    # 3 or more failed, return unified error
    return {"error": "Some suppliers are temporarily unavailable, please try again later"}
else:
    # 1-2 failed, return detailed errors
    return {
        "errors": result.errors,
        "hotels": result.hotels
    }
```

**User complaints**:
- "Why sometimes detailed errors, sometimes unified error?"
- "Inconsistent behavior!"

---

## How We Solve It

### Core Approach: Unified Error Model

**Problem**: 5 suppliers, 5 different HTTP status codes, error codes, error messages.

**Solution**: Unified error model + intelligent retry + error aggregation

```
Supplier A → Standardization Layer → Unified Error Model
Supplier B → Standardization Layer → Unified Error Model
Supplier C → Standardization Layer → Unified Error Model
Supplier D → Standardization Layer → Unified Error Model
Supplier E → Standardization Layer → Unified Error Model
```

---

### 1. Unified Error Model

#### Error Classification

```yaml
# Authentication Errors
AuthenticationError:
  INVALID_CREDENTIALS: "Invalid API key or secret"
  EXPIRED_CREDENTIALS: "API key has expired"
  MISSING_CREDENTIALS: "API key or secret is missing"

# Authorization Errors
AuthorizationError:
  INSUFFICIENT_PERMISSIONS: "Insufficient permissions"
  FORBIDDEN: "Access forbidden"

# Request Errors
RequestError:
  INVALID_PARAMETERS: "Invalid request parameters"
  MISSING_REQUIRED_PARAMETER: "Missing required parameter: {param}"
  INVALID_PARAMETER_VALUE: "Invalid value for parameter: {param}"
  INVALID_PARAMETER_TYPE: "Invalid type for parameter: {param}"

# Resource Errors
ResourceError:
  HOTEL_NOT_FOUND: "Hotel not found: {hotel_id}"
  ROOM_NOT_FOUND: "Room not found: {room_id}"
  RATE_PLAN_NOT_FOUND: "Rate plan not found: {rate_plan_id}"

# Business Errors
BusinessError:
  AVAILABILITY_NOT_FOUND: "No availability found"
  CHECK_IN_DATE_INVALID: "Check-in date is invalid"
  CHECK_OUT_DATE_INVALID: "Check-out date is invalid"
  MIN_NIGHTS_NOT_MET: "Minimum {min_nights} nights required"

# Rate Limit Errors
RateLimitError:
  RATE_LIMIT_EXCEEDED: "Rate limit exceeded, please try again later"
  SINGLE_HOTEL_RATE_LIMIT: "Rate limit exceeded for hotel: {hotel_id}"

# Server Errors
ServerError:
  INTERNAL_ERROR: "Internal server error"
  BAD_GATEWAY: "Bad gateway"
  SERVICE_UNAVAILABLE: "Service unavailable"
  GATEWAY_TIMEOUT: "Gateway timeout"

# Network Errors
NetworkError:
  CONNECTION_TIMEOUT: "Connection timeout"
  READ_TIMEOUT: "Read timeout"
  CONNECTION_ERROR: "Connection error"
```

#### Unified Error Response

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

### 2. Error Code Mapping

#### Automatic Mapping

```python
class ErrorMapper:
    def __init__(self):
        self.mappings = self._load_mappings()
    
    def _load_mappings(self):
        # 1. Load mapping rules from documentation
        docs_mappings = self._load_from_docs()
        
        # 2. Load mapping rules from historical errors
        history_mappings = self._load_from_history()
        
        # 3. Merge mapping rules
        return self._merge_mappings(docs_mappings, history_mappings)
    
    def map_error(self, supplier, original_error):
        # 1. Find mapping rule
        mapping = self.mappings.get(supplier, {}).get(
            original_error.code
        )
        
        if not mapping:
            # 2. No mapping rule, use rule engine to infer
            mapping = self._infer_error(original_error)
        
        # 3. Return unified error
        return UnifiedError(
            code=mapping.code,
            message=mapping.message,
            type=mapping.type,
            retryable=mapping.retryable,
            supplier=supplier,
            original_error=original_error
        )
    
    def _infer_error(self, original_error):
        # 1. Infer from HTTP status code
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

### 3. Intelligent Retry

#### Retry Strategy

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
        # Rate limit error: Use Retry-After header
        retry_after = error.original_error.headers.get('Retry-After', 60)
        await asyncio.sleep(int(retry_after))
        return await supplier.request(request)
    
    async def _retry_with_exponential_backoff(self, supplier, request, error):
        # Other errors: Use exponential backoff
        max_retries = 5
        base_delay = 1.0  # seconds
        
        for attempt in range(max_retries):
            try:
                return await supplier.request(request)
            except Exception as e:
                if attempt == max_retries - 1:
                    raise  # Last attempt failed
                
                delay = base_delay * (2 ** attempt)
                await asyncio.sleep(delay)
```

---

### 4. Error Aggregation

#### Multi-Supplier Error Aggregation

```python
async def search_all_suppliers_with_error_aggregation(hotel_id):
    # 1. Concurrently call all suppliers
    tasks = []
    for supplier in suppliers:
        task = asyncio.create_task(
            search_supplier_with_retry(supplier, hotel_id)
        )
        tasks.append(task)
    
    # 2. Collect results and errors
    results = []
    errors = []
    for task in tasks:
        try:
            result = await task
            results.append(result)
        except UnifiedError as error:
            errors.append(error)
    
    # 3. Error aggregation
    aggregated_error = self._aggregate_errors(errors)
    
    # 4. Return results
    return {
        "hotels": results,
        "error": aggregated_error,
        "partial_success": len(results) > 0
    }
    
def _aggregate_errors(self, errors):
    # 1. Classify by error type
    error_types = {}
    for error in errors:
        if error.type not in error_types:
            error_types[error.type] = []
        error_types[error.type].append(error)
    
    # 2. If all suppliers failed, return unified error
    if len(errors) == len(suppliers):
        return UnifiedError(
            code="ALL_SUPPLIERS_FAILED",
            message="All suppliers are temporarily unavailable, please try again later",
            type="ServerError",
            retryable=True,
            details=error_types
        )
    
    # 3. If some suppliers failed, return detailed error
    if len(errors) >= 3:
        # 3 or more failed, return simplified error
        return UnifiedError(
            code="SOME_SUPPLIERS_FAILED",
            message=f"{len(errors)} suppliers failed, showing results from available suppliers",
            type="ServerError",
            retryable=True,
            details=error_types
        )
    else:
        # 1-2 failed, return detailed error
        return UnifiedError(
            code="SOME_SUPPLIERS_FAILED",
            message=f"{len(errors)} suppliers failed",
            type="ServerError",
            retryable=True,
            details=error_types
        )
```

---

## Our Advantages

### 1. Unified Error Model

- Standardized error codes and error messages
- Clear error classification
- All errors follow the same format

### 2. Intelligent Error Mapping

- Automatically maps supplier error codes to unified error codes
- Rule engine infers unknown errors
- Continuously learns from historical errors

### 3. Intelligent Retry Strategy

- Automatically identifies retryable errors
- Exponential backoff strategy
- Rate limit errors use Retry-After header

### 4. Error Aggregation

- Unified return of multi-supplier errors
- Intelligently determines error severity
- User-friendly error messages

### 5. Real-time Monitoring

- Real-time error rate monitoring
- Real-time retry success rate monitoring
- Real-time supplier availability monitoring

---

## Call to Action

### Have You Written a 100+ Line Error Code Mapping Table?

**Problems**:
- 5 suppliers, 5 different HTTP status codes
- 5 suppliers, 5 different error codes
- 5 suppliers, 5 different error messages (different languages)
- When should you retry?
- How to implement retry strategy?
- How to aggregate multi-supplier errors?

**Our Solution**:
- Unified error model (standardized error codes and error messages)
- Intelligent error mapping (automatically maps supplier errors)
- Intelligent retry strategy (automatically identifies retryable errors, exponential backoff)
- Error aggregation (unified return of multi-supplier errors)

**You only need**:
```go
import "github.com/hotelbyte-com/sdk-go/hotelbyte"

client := hotelbyte.NewClient("YOUR_API_KEY")

// Search hotels (automatically handles errors, retries, aggregation)
result, err := client.SearchHotels(&hotelbyte.SearchRequest{
    Destination: "London",
    CheckIn:     time.Date(2026, 2, 10, 0, 0, 0, 0, time.UTC),
    CheckOut:    time.Date(2026, 2, 12, 0, 0, 0, 0, time.UTC),
    Guests:      2,
})

if err != nil {
    // Unified error format
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

// Return standardized results
for _, hotel := range result.Hotels {
    fmt.Printf("%s: $%.2f\n", hotel.Name, hotel.TotalPrice)
}
```

**No 100+ line error code mapping table. No complex retry strategy. Only a unified error model.**

---

## Next Steps

### Free Trial

- 30-day free trial
- No credit card required
- Start testing immediately

**[Start Your 30-Day Free Trial](https://waitlist.hotelbyte.com)**

### View Documentation

- API documentation: [openapi.hotelbyte.com](https://openapi.hotelbyte.com)
- SDK documentation: [docs.hotelbyte.com](https://docs.hotelbyte.com)
- Best practices: [blog.hotelbyte.com](https://blog.hotelbyte.com)

### Contact Us

Have questions? Contact our engineers directly.

**[Contact Us](mailto:support@hotelbyte.com)**

---

## Series Navigation

- [Part 1: Authentication Hell](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard/)
- [Part 2: Data Chaos](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-2/)
- [Part 3: Rate Limiting Nightmare](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-3/)
- [Part 4: Error Handling (This Article)](/developer-experience/api-integration/why-hotel-api-integration-is-so-hard-4/)
- [Part 5: Timezone Issues (Coming Soon)](#)

---

**Next up: Timezone Issues - User chose to check in tomorrow, supplier thinks it was yesterday**

---

*Reading time: ~16 minutes*
*Difficulty: Medium (requires understanding of HTTP status codes, error handling, retry strategies)*

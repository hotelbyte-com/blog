---
layout: post
title: "Whitepaper: HTTP Gateway & In-Process API Routing"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Infrastructure]
tags: ["Infrastructure", "Platform Engineering", "Whitepaper", "HotelByte"]
author: "HotelByte Team"
description: "WP01 technical whitepaper: A hotel API gateway is not just ingress plumbing. It is the first governed control plane for authentication, authorization, caching, streaming, field shaping, and request evidence."
lang: en
permalink: /en/whitepapers/wp01-http-gateway-routing/original/
whitepaper_kind: original
guide_url: /en/whitepapers/wp01-http-gateway-routing/
source_asset: hotel-be/docs/whitepapers/01-http-gateway-and-in-process-routing.md
---
<div class="whitepaper-reader-note">
  <strong>Reading path:</strong> this is the full WP01 whitepaper. For a shorter reader-facing guide, start with <a href="/en/whitepapers/wp01-http-gateway-routing/">the blog guide</a>. Browse the series at <a href="/en/whitepapers/">HotelByte Whitepapers</a>.
</div>

# HTTP Gateway & In-Process API Routing

**HotelByte Technical Whitepaper | Version 2.0**

---

## Executive Summary

**Assumed audience:** platform engineers, enterprise architects, integration owners, and technical reviewers evaluating governed infrastructure capabilities in hotel distribution.

**TL;DR:** A hotel API gateway is not ingress plumbing; it is the first governed control plane for authentication, authorization, caching, streaming, field shaping, and request evidence.

> **Central claim:** A hotel API gateway is not ingress plumbing; it is the first governed control plane for authentication, authorization, caching, streaming, field shaping, and request evidence.

HotelByte is a global hotel API distribution platform. Rather than relying on external API gateways or service mesh sidecars, HotelByte developed an in-process HTTP dispatcher that embeds gateway functionality directly into every service process. This architectural trade-off eliminates network hop overhead, reduces P99 latency, and enables a unified, defense-in-depth security model.

This whitepaper describes the design principles, layered middleware architecture, and production-validated controls that govern how every API request is received, authenticated, authorized, rate-limited, cached, and responded to. It is intended for security auditors, integration partners, and enterprise customers who require transparency into the platform's ingress handling and access control posture.

---

## Scope

This document covers the HotelByte HTTP gateway layer only:

- In-process HTTP service dispatch logic
- Ten-layer onion middleware chain
- Authentication (JWT and Short Token Mode)
- Authorization (RBAC and OpenAPI whitelist)
- Rate limiting and flow control (IP-level, API-level, tenant-level)
- Response caching, field filtering, and streaming
- Error normalization and observability

It does not cover supplier-facing outbound adapters, search engine internals, or data intelligence pipelines, which are addressed in separate whitepapers.

---

## Objectives

1. **Zero Network Hop Ingress** — Remove sidecar/proxy latency by compiling gateway logic into the service binary.
2. **Defense in Depth** — Apply security and resiliency controls at multiple layers, from IP to tenant.
3. **Observable and Auditable** — Record per-middleware timing, emit structured access logs, and alert on anomalies.
4. **Consistent API Contract** — Enforce unified request/response envelopes, field-level access control, and deterministic cache behavior.
5. **Graceful Degradation** — Normalize transient dependency failures into predictable error categories without leaking internal state.

---

## Design Principles

### Embed Over Proxy

Traditional API gateways or service mesh sidecars introduce at least one additional network hop per request. In a hotel distribution platform where a single search may fan out to dozens of internal calls, these hops compound into measurable latency inflation. To address this, HotelByte compiles the gateway directly into each service process. Startup-time service introspection maps business interfaces to HTTP routes, eliminating runtime route resolution cost. While this tight language coupling limits polyglot microservice adoption and requires full-service redeployments for gateway policy updates, the latency savings are critical for a high fan-out aggregation engine where P99 tail latency dictates business success. The resource contention between gateway logic and core business logic within the same process is mitigated through strict capacity planning.

### Query-Parameter-Only Routing

HotelByte intentionally avoids REST-style path parameters (`/hotels/{id}`), expressing all request arguments as query parameters instead. While this approach deviates from RESTful purism and can hinder the out-of-the-box utility of standard OpenAPI client generators, it fundamentally simplifies cache key generation by ensuring deterministic ordering and no path ambiguity. It also strengthens log parsing through uniform access patterns and reduces the attack surface for path traversal or parameter smuggling. For highly complex queries that might hit edge infrastructure URL length limits (typically 2KB-8KB), the system gracefully falls back to POST payloads.

### Short Token Security Model

Standard JWT embeds claims directly in the token string. This causes the token size to grow with permission scope and makes server-side revocation impractical until natural expiration. In a B2B hotel distribution context where compromised enterprise API keys must be revoked in milliseconds, stateless validation becomes a liability rather than a feature. HotelByte addresses this by storing JWT claims in Redis and transmitting only a short Token ID to the client. Although this introduces a hard dependency on distributed cache availability and a microsecond-level network latency penalty for validation lookups, it drastically reduces header overhead and enables instantaneous revocation. The availability risk is strictly mitigated through highly available Redis clusters and in-memory local caching fallbacks.

### Structured Concurrency for Cache Invalidation

Write operations asynchronously trigger cache invalidation via a bounded worker pool rather than blocking the response path. This decouples mutation latency from cache consistency, restricted by a worker pool with backpressure-aware semantics. Field collection caches are similarly invalidated to ensure downstream consumers never observe stale partial data.

### Normalize, Don't Leak

Unclassified network, timeout, or connection errors are automatically mapped to a standard `DependencyErr` category. This guarantees that clients receive predictable error envelopes without exposure of internal topology, hostnames, or stack traces.

---

## Layered Architecture

The in-process dispatcher processes every request through a strict, ordered ten-layer onion middleware chain. Each layer has a single responsibility and can short-circuit the pipeline when a control violation is detected.

```
Recovery
  → IPRateLimit
    → SentinelAPIGateway
      → RouteHandler
        → Authenticate
          → MockGuard
            → Authorize
              → SentinelWeb
                → CoreHandler
                  → Response
```

### Layer 1 — Recovery

The outermost layer catches panics from any downstream layer, converts them into sanitized internal errors, and reports the full stack trace to Sentry with request context (path, user, tenant, user agent). A single malformed request can never crash the service process.

### Layer 2 — IP Rate Limiting

Before any routing or authentication occurs, the caller's IP address is evaluated against a configurable rate limit. The layer supports sliding-window counters backed by Redis with an in-memory fallback when Redis is unavailable. IP whitelists (individual addresses and CIDR blocks) are honored, and proxy headers (`X-Forwarded-For`, `X-Real-IP`) are parsed only when explicitly trusted.

### Layer 3 — Sentinel API Gateway

The third layer applies Sentinel-based API gateway rate limiting. This control enforces global and per-API throughput limits. A dedicated load-test header allows authorized performance testing to bypass this layer, ensuring synthetic traffic does not consume production quota.

### Layer 4 — Route Handler

Route resolution maps the HTTP path to a registered service method using the startup-time reflection index. Because path parameters are prohibited, every route is an exact match. Query parameters are extracted and validated before being passed downstream.

### Layer 5 — Authentication

The authentication layer supports dual token modes: traditional JWT and Short Token Mode. For Short Tokens, the layer retrieves claims from Redis, validates impersonation guards (administrative mock-login scenarios), refreshes user information via `singleflight` (guaranteeing one concurrent refresh per user), and enforces sliding expiration based on Redis access records. Tokens that have been idle beyond the configured timeout are rejected with a standard expiration response.

### Layer 6 — Mock Guard

Mock operations — where an administrative user impersonates another account for testing or support — are intercepted and validated. This layer ensures impersonation is authorized, logged, and cannot be used to bypass production controls.

### Layer 7 — Authorization

Role-Based Access Control (RBAC) is enforced via an injected Authorizer. Each API method declares required permissions in source annotations; the layer rejects requests that lack them. OpenAPI demo accounts are restricted to a whitelist of methods tagged with the `openapi` permission, preventing exploration beyond documented surfaces.

### Layer 8 — Sentinel Web

Tenant- and customer-level flow control is applied here. Sentinel rules can throttle or block traffic at the granularity of individual tenants or customers, ensuring noisy-neighbor isolation without affecting platform-wide availability.

### Layer 9 — Core Handler

The business execution layer parses request parameters, performs cache lookups (read path), invokes the target business method via reflection, and initiates asynchronous cache invalidation for write operations. Cache keys are derived deterministically from service name, method name, and sorted query parameters. Field-level access control metadata is resolved and attached for the response layer.

### Layer 10 — Response

The innermost layer constructs the unified response envelope, writes cache entries for read operations (with optional compression), applies field filtering based on the caller's access profile, and supports streaming output (SSE) when the service returns a `StreamingOutput` implementation. All responses conform to a single JSON envelope schema.

---

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| In-Process HTTP Dispatcher | Eliminates sidecar/proxy latency; every request is handled within the service process, reducing P99 response times. |
| Panic Recovery with Sentry Reporting | A single bad request cannot crash a service instance; incidents are captured and routed to engineering with full context. |
| IP-Level Rate Limiting | Abusive or misconfigured clients are throttled at the network edge before consuming compute or downstream resources. |
| Sentinel API Gateway Rate Limiting | Global and per-API throughput limits protect platform stability during traffic spikes and promotional events. |
| Exact-Path Routing (No Path Parameters) | Predictable cache keys and uniform access logs eliminate ambiguity in caching, monitoring, and log analysis. |
| Short Token Mode | Smaller headers, instant server-side revocation, and reduced token surface area improve security and transfer efficiency. |
| Sliding Expiration | API tokens expire based on inactivity, not fixed calendar time, balancing security with uninterrupted legitimate usage. |
| Singleflight User Refresh | Concurrent requests for the same user trigger only one refresh operation, eliminating cache stampede on user data. |
| Mock Operation Guard | Administrative impersonation is controlled, audited, and cannot be exploited to access unauthorized data. |
| RBAC with OpenAPI Whitelist | Fine-grained permission enforcement ensures customers and demo accounts access only explicitly authorized endpoints. |
| Tenant/Customer Sentinel Flow Control | Multi-tenant isolation prevents one customer's traffic from degrading service quality for others. |
| Deterministic Response Caching | Read-heavy APIs benefit from Redis-backed caching with automatic invalidation on writes, reducing latency and load. |
| Async Write-Triggered Cache Invalidation | Cache consistency is maintained without blocking the response path, preserving low-latency mutations. |
| Field Collection Caching & Filtering | Responses are automatically scoped to fields the caller is permitted to see, preventing overexposure of sensitive attributes. |
| Streaming Response Support | Real-time endpoints (e.g., progress streams) bypass default JSON marshaling while retaining observability. |
| Error Normalization | Network and dependency failures are mapped to stable error categories, preventing internal topology leakage. |
| Per-Middleware Timing with Alerting | Every layer's latency is measured; layers exceeding 10ms trigger operational alerts for rapid diagnosis. |

---

## Auditability

External reviewers and enterprise customers can verify HotelByte gateway controls through the following mechanisms:

1. **Structured Access Logs** — Every request emits a structured log record containing path, service, method, tenant, customer, API key, cache hit/miss status, cost time, and error classification. These logs are retained and available for audit export.

2. **Metrics Export** — `APICallTiming` and `APICallCount` metrics are tagged by service, method, tenant, customer, API key, and cache status. Reviewers with metric access can independently validate rate-limit effectiveness, cache hit ratios, and latency distributions.

3. **Sentry Integration** — Panic events include full stack traces, request context, user identity, and tenant information. Security teams can correlate Sentry incidents with access logs.

4. **Sentinel Dashboards** — Sentinel flow-control rules and real-time QPS/block metrics are observable through standard Sentinel consoles, enabling independent confirmation that rate limits and tenant throttles are active.

5. **Token Store Audit** — Short Token access records (last access time, IP, user agent, access count) are stored in Redis and can be queried to verify token usage patterns and sliding expiration behavior.

6. **Source-Level Declarative Policies** — API methods declare authentication requirements, permissions, and cache behavior in source code annotations. These annotations are parsed at build time and can be statically audited to verify that controls match published API documentation.

7. **Integration Tests** — The gateway core module includes comprehensive tests covering cache invalidation, rate limiting, JWT short-token flows, field filtering, authorization, and error normalization. Reviewers can execute these tests to reproduce control behavior in a local environment.

---

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **OWASP API Security Top 10 (2023)** — API1:2023 Broken Object Level Authorization | "Implement a proper authorization mechanism that relies on the user policies and hierarchy." | RBAC permission checks (`authorizeMiddleware`) enforce method-level authorization against declared permissions. OpenAPI whitelist further restricts demo account access. |
| **OWASP API Security Top 10 (2023)** — API6:2023 Unrestricted Access to Sensitive Business Flows | "Implement rate limiting and flow control mechanisms to prevent abuse of business flows." | Three-tier rate limiting (IP, API gateway, tenant/customer Sentinel) prevents automated abuse and protects sensitive booking/search flows. |
| **NIST SP 800-207 Zero Trust Architecture** | "The enterprise monitors and measures the integrity and security posture of all owned and associated assets." | In-process gateway eliminates trust in external proxies; every request is authenticated, authorized, and metered within the service boundary. |
| **RFC 8725 JSON Web Token Best Current Practices** | "Keep tokens short-lived and use refresh tokens where necessary." | Short Token Mode stores claims server-side; sliding expiration based on activity ensures tokens are short-lived in practice without forcing frequent reauthentication. |
| **RFC 6585 HTTP Status Code 429 (Too Many Requests)** | "The 429 status code indicates that the user has sent too many requests in a given amount of time." | Sentinel and IP rate limiters return standard 429 responses with clear rate-limit headers, enabling client-side back-off strategies. |
| **NIST SP 800-53 Rev. 5 AC-3 Access Enforcement** | "The information system enforces approved authorizations for logical access to information and system resources." | `authorizeMiddleware` enforces RBAC permissions annotated at the method level, with fallback no-auth lists for public endpoints; impersonation is guarded by `mockGuardMiddleware`. |

---

*For questions or audit requests regarding this whitepaper, contact HotelByte Engineering via your assigned partner channel.*

## WP27 Governance Reading

Read HTTP Gateway & In-Process API Routing through the same loop used by WP27: intent, evidence, bounded execution, verification, and durable governance.

| Plane | What to inspect in this paper |
|---|---|
| Intent | Which operational or integration risk the design removes. |
| Evidence | Which logs, metrics, records, traces, tests, or replay artifacts prove the behavior. |
| Execution boundary | Which layer owns the decision and which layer only adapts or transports data. |
| Verification | Which failure modes are tested beyond the happy path. |
| Governance memory | Which rules, dashboards, audit trails, or test cases make the lesson reusable. |

## Conclusion

HTTP Gateway & In-Process API Routing matters because it turns a fragile implementation concern into a governed platform capability. The durable value is not that the component exists, but that its boundaries, evidence, failure semantics, and verification path can be reviewed after the fact.

A hotel API gateway is not ingress plumbing; it is the first governed control plane for authentication, authorization, caching, streaming, field shaping, and request evidence.

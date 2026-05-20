---
layout: post
title: "Whitepaper: Supplier Adapter Framework & Standardization Whitepaper"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [Hotel API, Whitepaper, Architecture]
author: "HotelByte Team"
description: "Full HotelByte technical whitepaper published on the blog for readable public access."
lang: en
permalink: /en/whitepapers/wp06-supplier-adapter-framework/original/
whitepaper_kind: original
guide_url: /en/whitepapers/wp06-supplier-adapter-framework/
---

<div class="whitepaper-reader-note">
  <strong>Reading path:</strong> this is the full whitepaper. For a shorter reader-facing guide, start with <a href="/en/whitepapers/wp06-supplier-adapter-framework/">the blog guide</a>. Browse the whitepaper index at <a href="/en/whitepapers/">HotelByte Whitepapers</a>.
</div>

# Supplier Adapter Framework & Standardization Whitepaper

**HotelByte Technical Whitepaper | Version 2.0**

---

## Executive Summary

HotelByte is a global hotel API distribution platform that aggregates inventory from 27+ hotel suppliers—ranging from direct-connect bed banks and OTA platforms to wholesale aggregators and niche regional operators. Each supplier exposes a distinct API surface with its own authentication scheme, data model, error vocabulary, and rate-limiting behavior. Without architectural discipline, this heterogeneity would produce duplicated business logic, inconsistent error semantics, and unpredictable caching behavior.

This whitepaper describes HotelByte's Supplier Adapter Framework, a three-layer isolation architecture that unifies every supplier behind a single, strongly typed interface contract. The framework enforces standardized data types, canonical error mappings, mandatory session persistence, and unified HTTP execution—while preserving supplier-specific optimizations where they add value. It is intended for security auditors, integration partners, and enterprise customers who require transparency into how HotelByte normalizes third-party supplier interactions without compromising correctness or observability.

---

## Scope

This document covers the architectural design, interface contracts, and assurance properties of HotelByte's supplier integration layer. Specifically:

- **Proxy Layer** (`supplier/proxy/`): Unified entry point, session persistence, price conversion, cache management, and temporary offline controls.
- **Middleware Layer** (`supplier/middleware/`): Unified HTTP execution, error normalization, rate limiting, circuit breaking, proxy keepalive, and response decoding.
- **Supplier Layer** (`supplier/integration/{supplier}/`): Standard interface implementation, supplier-specific data models, response conversion, metadata storage, and geographic mapping.
- **Supplier Classification Model**: Core, edge, and special supplier storage strategies and their performance characteristics.

This whitepaper does not cover HotelByte's search ranking engine, pricing intelligence systems, or customer-facing booking API, which are addressed in companion documents.

---

## Objectives

The Supplier Adapter Framework is designed to achieve the following objectives:

1. **Interface Contract Uniformity** — Every supplier implements the same `Supplier` interface, ensuring that search, booking, and content operations behave identically regardless of the underlying provider.

2. **Type Safety at Scale** — Enforce unified integer (`int64`), float (`float64`), and time representations across all supplier boundaries, eliminating serialization drift and platform-specific width hazards.

3. **Error Semantic Normalization** — Map opaque supplier error codes into canonical business error categories (e.g., `PriceChangedError`, `SupplierRateLimitErr`) via configuration, preventing error vocabulary leakage into customer-facing responses.

4. **Operational Isolation** — Separate supplier-specific logic from cross-cutting concerns such as caching, rate limiting, circuit breaking, and logging. Supplier engineers own adapter correctness; the platform owns resilience.

5. **Query Performance Tiering** — Distinguish between high-frequency core suppliers (stored inline) and lower-frequency edge suppliers (stored via reference tables), optimizing the data access path for each supplier's observed traffic pattern.

---

## Design Principles

### Interface Contract First

HotelByte's `Supplier` interface is the single source of truth for all supplier interactions. It comprises three capability groups:

- `SupplierContent`: `HotelStaticDetail`, `HotelsMetadata`
- `SupplierResource`: `HotelList`, `HotelRates`, `CheckAvail`
- `SupplierBooking`: `Book`, `QueryOrderByIDs`, `SearchOrders`, `Cancel`

No supplier may expose ad-hoc operations outside this contract. This constraint guarantees that upstream services—search, booking, content management—can treat every supplier as a substitutable dependency, enabling A/B testing, failover routing, and capacity scaling without interface rework.

### Layered Responsibility Isolation

The framework strictly partitions concerns across three layers:

- The **Proxy Layer** owns session lifecycle, cache key generation, price conversion, and supplier selection. It is forbidden from duplicating request parameters or performing supplier-specific parsing.
- The **Middleware Layer** owns HTTP transport, retry policies, error decoding, rate limiting, and circuit breaking. All outbound HTTP calls MUST use `middleware.Execute`; raw `http.Client` usage is prohibited.
- The **Supplier Layer** owns request construction, response parsing, domain model conversion, and supplier-specific metadata extraction (e.g., `rateKey` tokens). It may not implement its own caching or retry logic.

This separation ensures that a resilience improvement in the middleware (e.g., adding adaptive backoff) immediately benefits all 27+ suppliers without per-adapter changes.

### Type Safety Enforcement

Supplier APIs are notorious for inconsistent numeric types: `int` on 32-bit systems, `float32` for prices, and integer timestamps masquerading as strings. HotelByte mandates:

- **Integers**: unified `int64`; `int`, `int32`, and `uint` are prohibited.
- **Floats**: unified `float64`; `float32` is prohibited.
- **Time**: `string` at supplier boundaries, `time.Time` internally.
- **No weak types**: `map[string]interface{}` is forbidden in adapter models.

These rules are enforced at compile time and verified in code review, eliminating an entire class of cross-platform serialization defects.

### Config-Driven Error Mapping

Each supplier defines its own error ontology. One supplier's `"2018"` may mean "currency not supported," while another's `"RATE_CHANGED"` signals a price revision. Rather than hard-coding these mappings in Go source, HotelByte externalizes them into per-supplier `config.yaml` files:

```yaml
errorMappings:
  - supplierErrorCode: "2005"
    bizErrorName: ARIChangedErr
    bizErrorMessage: "No available room"
```

This approach allows operations teams to adjust error semantics without redeploying code, and ensures that new suppliers can be onboarded by authoring configuration rather than modifying shared libraries.

### Supplier Classification

Not all suppliers carry equal query volume. HotelByte classifies suppliers into three tiers:

- **Core suppliers** (IDs 1–30): Hotel-to-supplier mappings are stored inline in the `hotel` table (`supplier_N_id`). Queries execute against a single table with no JOIN overhead.
- **Edge suppliers** (IDs 31+): Mappings are stored in the `hotel_edge_supplier_ref` table. A JOIN is required, trading modest latency for schema extensibility.
- **Special suppliers** (IDs 10,000,000+): In-memory or transient mappings for simulation, testing, and provisional integrations.

This tiering prevents the hotel content table from growing unbounded while keeping the hottest query paths maximally efficient.

---

## Layered Architecture

HotelByte's supplier integration is organized into three vertically isolated layers, each abstracting a distinct operational concern:

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                          │
│   Search, booking, content, and analytics services            │
├─────────────────────────────────────────────────────────────┤
│                    Proxy Layer                                │
│   Session persistence, cache management, price conversion,    │
│   temporary offline controls, supplier selection              │
├─────────────────────────────────────────────────────────────┤
│                    Middleware Layer                           │
│   Unified HTTP execution, retry, rate limit, circuit break,   │
│   error decoding, proxy keepalive, structured logging         │
├─────────────────────────────────────────────────────────────┤
│                    Supplier Layer                             │
│   Per-supplier interface implementation, model structs,       │
│   request builders, response converters, metadata storage     │
└─────────────────────────────────────────────────────────────┘
```

### Proxy Layer

The Proxy Layer is the single entry point for all supplier calls. Its responsibilities include:

- **Session Persistence**: Multi-step booking flows (e.g., `HotelRates` → `CheckAvail` → `Book`) require state continuity. The proxy persists session parameters across API calls so that downstream suppliers receive correlated context without upstream services managing state.
- **Cache Management**: The proxy generates deterministic cache keys from supplier, credential, session, API name, and request hash. It consults a tiered cache (L1 session-scoped, L2 global) before permitting an outbound call, and writes back non-empty, successful responses automatically.
- **Price Conversion**: Supplier currencies and pricing models are normalized into the platform's canonical price representation before returning to the application layer.
- **Temporary Offline Control**: Operational incidents (supplier outage, credential rotation, contract suspension) can be gated at the proxy level without modifying supplier code or application logic.

### Middleware Layer

The Middleware Layer encapsulates all HTTP transport semantics. Every supplier call flows through `middleware.Execute`, which provides:

- **Unified HTTP Client**: A preconfigured `req.Client` with standardized timeouts, retry policies (3 retries, 300ms–2s backoff), and proxy resolution. System proxy fallback is explicitly disabled to prevent environmental leakage.
- **Response Error Handling**: HTTP error states are decoded into structured error responses using the supplier's configured error mappings. HTTP 429 responses trigger adaptive rate-limit backoff.
- **Rate Limiting**: Per-credential rate limiting is enforced before every outbound call, with queueing and wait-time metrics exposed for observability.
- **Circuit Breaking**: Supplier-level circuit breakers skip requests after consecutive failures, preventing goroutine accumulation during downstream outages.
- **Proxy Keepalive**: For suppliers requiring SOCKS5 tunneling, the middleware performs lightweight proxy health checks and automatic reconnection on cache misses.
- **Structured Logging**: Every request and response is captured in the HBLog format, including input body, output body, headers, cost time, and credential metadata—without supplier code touching logging directly.

### Supplier Layer

The Supplier Layer contains the per-supplier adapter implementations. Each supplier directory follows a standardized file organization (using Dida as the reference paradigm):

```
supplier/integration/{supplier}/
  ├── hotel_list.go
  ├── hotel_rates.go
  ├── check_avail.go
  ├── book.go
  ├── query_order.go
  ├── cancel.go
  ├── content.go
  ├── geo.go
  ├── init.go
  ├── model/session.go
  ├── model/converter_*.go
  ├── config.yaml
  └── full_flow_test.go
```

This convention enables engineers to locate any capability for any supplier within seconds. The layer's responsibilities are:

- **Request Construction**: Map domain requests into supplier-specific payloads (JSON, XML, form-data, or query parameters).
- **Response Conversion**: Parse supplier responses and convert them into canonical domain models using strongly typed converters.
- **Metadata Storage**: Persist supplier-specific identifiers (e.g., `rateKey`, `bookingId`) in domain models so that subsequent calls in a session can reference them.
- **Interface Compliance**: Every supplier struct must satisfy `SupplierResponse` (`ErrorCode()`, `ErrorMsg()`) and `EmptySupplierResponse` (`IsEmpty()`), enabling the middleware to perform uniform error and cache-eligibility checks.

---

## Supplier Lifecycle / Onboarding Flow

Adding a new supplier to HotelByte follows a standardized lifecycle that preserves architectural integrity:

1. **Interface Compliance**: Implement the `Supplier` interface for all content, resource, and booking operations.
2. **File Structure Conformance**: Create the canonical file set per the Dida reference paradigm.
3. **Type Safety Audit**: Verify that all models use `int64`, `float64`, and `string` (boundary) / `time.Time` (internal); no weak types.
4. **Error Mapping Configuration**: Populate `config.yaml` with per-API error mappings translating supplier codes to canonical business errors.
5. **Middleware Integration**: Ensure all HTTP calls route through `middleware.Execute`; no raw HTTP clients.
6. **Full Flow Testing**: Author `full_flow_test.go` covering HotelList → HotelRates → CheckAvail → Book → QueryOrder → Cancel.
7. **Classification Assignment**: Register the supplier as core (1–30), edge (31+), or special (10,000,000+) based on projected traffic and operational priority.
8. **Certification Gate**: Pass integration certification against live supplier sandboxes before production promotion.

---

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| **Unified Supplier Interface Contract** | All 27+ suppliers present identical content, resource, and booking capabilities. Customers experience consistent behavior regardless of which supplier fulfills a search or booking request. |
| **Three-Layer Responsibility Isolation** | Resilience improvements (retries, caching, rate limiting) in the proxy and middleware layers propagate to every supplier automatically, without per-adapter reimplementation. |
| **Config-Driven Error Normalization** | Opaque supplier error codes are mapped to canonical business errors at runtime via configuration. Customers receive meaningful, actionable error messages instead of raw supplier codes. |
| **Strong Type Safety Enforcement** | Unified `int64`, `float64`, and `time.Time` types prevent serialization drift, integer overflow, and floating-point precision loss across heterogeneous supplier APIs. |
| **Mandatory Session Persistence** | Multi-step booking flows maintain state continuity across `HotelRates`, `CheckAvail`, and `Book` calls, eliminating race conditions and parameter mismatches. |
| **Tiered Supplier Classification** | Core suppliers serve from inline table columns for sub-millisecond lookups; edge suppliers use reference tables for flexible expansion. Query performance is matched to traffic frequency. |
| **Supplier-Level Circuit Breaking** | Consecutive failures trigger automatic request skipping, preventing cascading overload and preserving platform capacity for healthy suppliers. |
| **Adaptive Rate Limiting** | Per-credential QPM enforcement with queueing and backoff protects supplier relationships and ensures fair resource allocation across tenants. |
| **Empty-Response Cache Exclusion** | Responses implementing `EmptySupplierResponse` are automatically excluded from caching, preventing the storage and serving of invalid or incomplete inventory snapshots. |
| **Standardized File Organization** | Every supplier follows the same directory and file naming convention, reducing cognitive load and enabling automated audits, scaffolding, and cross-supplier diff analysis. |

---

## Auditability

HotelByte's supplier adapter framework exposes multiple verification surfaces that allow operators and auditors to confirm correct behavior:

**Structured Request-Response Logging.** Every supplier call emits an HBLog record containing the full request body, response body, HTTP status, headers, cost time, internal cost time, and credential metadata. These logs are trace-correlated, enabling end-to-end tracking from a customer search to the final supplier HTTP exchange.

**Metrics Exposure.** Prometheus-compatible counters and histograms are exported for cache hit rates, supplier call latency, rate-limit wait times, circuit-breaker state transitions, and per-supplier error rates. Metrics support real-time alerting and historical SLA reporting.

**Config Auditing.** Error mappings, timeout values, base URLs, and proxy settings are declared in version-controlled YAML configuration rather than embedded in source code. Configuration changes are diffable, reviewable, and reversible without deployment.

**Full Flow Test Coverage.** Every supplier includes `full_flow_test.go` exercising the complete booking lifecycle. These tests validate request construction, response conversion, error mapping, and session continuity against recorded or sandboxed supplier responses.

**Supplier Classification Verification.** Core/edge/special classification is encoded in the `protocol.Supplier` enumeration with explicit `IsCoreSupplier()` and `IsEdgeSupplier()` predicates. Storage-layer queries can be audited to confirm that classification aligns with observed query patterns.

**Type Safety Verification.** The build pipeline enforces the absence of `int`, `int32`, `uint`, `float32`, and `map[string]interface{}` in supplier model files through static analysis and lint gates.

---

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **Robert C. Martin, "Clean Architecture" (Prentice Hall, 2017)** | "The dependency rule states that source code dependencies can only point inwards. Nothing in an inner circle can know anything at all about something in an outer circle." | HotelByte's three-layer architecture enforces inward-pointing dependencies: the Supplier Layer depends on the Middleware Layer, which depends on the Proxy Layer. Supplier-specific code never imports caching, logging, or HTTP retry logic directly. |
| **Robert C. Martin, "The Interface Segregation Principle" (1996)** | "Clients should not be forced to depend on methods that they do not use." | The `Supplier` interface is decomposed into `SupplierContent`, `SupplierResource`, and `SupplierBooking` capability groups. A read-only content importer need not implement booking methods, and a booking-only connector need not implement search. |
| **Google API Design Guide, "Standard Methods"** | "Use a small set of standard methods... to keep your API consistent and simple." | HotelByte mandates exactly eight standard operations across all suppliers (`HotelStaticDetail`, `HotelsMetadata`, `HotelList`, `HotelRates`, `CheckAvail`, `Book`, `QueryOrderByIDs`, `SearchOrders`, `Cancel`), preventing API surface fragmentation. |
| **OWASP API Security Top 10 (2023), API6:2023 — Unrestricted Access to Sensitive Business Flows** | "Implement mechanisms to prevent automated abuse... such as rate limiting, device fingerprinting, and bot detection." | The middleware layer enforces per-credential rate limiting, circuit breaking, and adaptive backoff before every supplier call, protecting both HotelByte infrastructure and supplier endpoints from abusive traffic patterns. |
| **ISO/IEC 25010:2011, "Compatibility — Interoperability"** | "The degree to which two or more systems, products or components can exchange information and use the information that has been exchanged." | The Supplier Adapter Framework maximizes interoperability by normalizing heterogeneous supplier protocols (REST, SOAP, XML, JSON) into a single domain model and interface contract, enabling substitutability without upstream code changes. |
| **NIST SP 800-53 Rev. 5 — SC-5 (Denial of Service Protection)** | "The information system protects against or limits the effects of denial of service attacks." | Circuit breaking, request coalescing, rate limiting, and proxy keepalive collectively limit the blast radius of supplier outages and traffic spikes, preserving platform availability for non-impacted suppliers and tenants. |

---

*This whitepaper is published by HotelByte Engineering. For questions regarding the technical controls described herein, please contact HotelByte Technical Support or your assigned Customer Success Engineer.*


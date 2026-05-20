---

layout: post
title: "英文 canonical 原文：SSE 流式搜索架构白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp12-sse-streaming-search/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp12-sse-streaming-search/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是英文 canonical 原文页。中文导读在 <a href="/zh/whitepapers/wp12-sse-streaming-search/">读者视角导读</a>；完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。下方发布英文 canonical whitepaper 全文，避免再跳转到仓库相对目录。
</div>

# 英文 canonical 原文：SSE 流式搜索架构白皮书

> 本页为公开博客版白皮书原文。当前 canonical 全文以英文维护，中文导读负责解释读者视角和业务价值；英文 canonical URL 为 [/en/whitepapers/wp12-sse-streaming-search/original/](/en/whitepapers/wp12-sse-streaming-search/original/)。

# SSE Streaming Search Architecture Whitepaper

**HotelByte Technical Whitepaper | Version 2.0**

---

## Executive Summary

HotelByte is a global hotel API distribution platform that serves aggregated inventory from dozens of supplier integrations to travel agencies, online travel agencies (OTAs), and corporate booking tools. Traditional hotel search APIs return results only after all supplier queries have completed, forcing end users to wait several seconds before seeing any hotels. HotelByte replaces this blocking model with a progressive streaming architecture built on Server-Sent Events (SSE).

The SSE streaming search endpoint (`/hotelListStream`) delivers an `initial` event containing the complete hotel catalog within milliseconds, followed by zero or more `update` events as live rates arrive from supplier systems, and finally a `complete` event with aggregated statistics. This architecture decouples catalog presentation from supplier latency, achieving a Time-To-First-Byte (TTFB) target of under 200 milliseconds and a First Contentful Paint (FCP) target of under 500 milliseconds.

This whitepaper describes the protocol design, concurrent batch processing engine, frontend state synchronization model, and the observability framework that makes the stream fully auditable. It is intended for integration partners, enterprise customers, and security auditors who require transparency into how HotelByte delivers progressive search results without compromising data consistency or error visibility.

---

## Scope

This document covers the HotelByte streaming search layer only:

- SSE protocol implementation and event lifecycle
- Concurrent supplier batch processing and chunk scheduling
- Frontend state machine for real-time price merging and hotel visibility
- Structured observability, per-event logging, and stream statistics
- Framework integration via the `StreamingOutput` interface

It does not cover the underlying supplier adapter framework, the static hotel content pipeline, or the booking/trade engine, which are addressed in separate whitepapers.

---

## Objectives

1. **Progressive Discovery** — Users see the full hotel catalog immediately, while live rates stream in asynchronously as suppliers respond.
2. **Latency Budget Enforcement** — TTFB < 200ms for the initial event; FCP < 500ms for the first meaningful price update.
3. **Supplier Fault Isolation** — A slow or failing supplier does not block results from other suppliers; per-supplier errors are emitted as discrete events.
4. **Real-Time Price Convergence** — The frontend merges incoming rates incrementally, always displaying the best available price observed across all supplier responses.
5. **Full Observability** — Every event is traceable via a unified trace ID, and stream completion produces structured statistics suitable for operational dashboards and customer reports.
6. **Graceful Degradation** — Hotels without live offers remain visible when no alternative pricing exists, preventing empty-result states.

---

## Design Principles

### Progressive Enhancement

The user experience is intentionally layered. The initial event contains hotel static content (names, stars, locations, amenities) and any cached or pre-computed pricing already available in the platform. Live supplier responses then progressively enhance this baseline. This guarantees that a user with a slow connection or a supplier experiencing an outage still receives a usable hotel list.

### Latency Budgeting

Each phase of the stream carries a strict latency budget. Initial catalog preparation is optimized to complete within the TTFB window. Supplier queries are executed concurrently with aggressive batching and timeout management. The frontend applies a 150-millisecond debounce window for update rendering to balance perceived responsiveness with rendering efficiency.

### Observable by Design

Streaming responses bypass the default JSON marshaling path, which would ordinarily produce a single structured log entry. To preserve observability, the streaming response object maintains an internal event journal that records every emitted event—its type, supplier, credential, batch index, hotel count, and duration. Upon stream completion, `GetLogData()` returns this journal as a structured JSON object, ensuring that streamed responses are no less auditable than standard API calls.

### Fault Isolation at the Credential Boundary

Supplier queries are decomposed into batches, and each batch is further decomposed into independent goroutines per credential. A timeout, network error, or business-rule block in one credential does not delay or contaminate another. Error events carry full supplier and credential context, enabling downstream systems to attribute failures precisely.

### Session Consistency

The platform maintains a transactional search session that survives across API calls. During streaming, incremental session state is persisted before each update event is written to the client. This ensures that if a user clicks into a hotel immediately after its price appears, the subsequent `hotelRates` call operates against a fully synchronized session.

---

## Streaming Architecture

The streaming architecture consists of three coordinated layers: the SSE Protocol Layer, the Batch Processing Layer, and the Frontend State Layer.

### SSE Protocol Layer

The endpoint returns `Content-Type: text/event-stream` with `Cache-Control: no-cache`, `Connection: keep-alive`, and `X-Accel-Buffering: no` to prevent intermediate proxies from buffering events. Every SSE event conforms to the standard `event: {type}\ndata: {payload}\n\n` format.

Four event types form the contract:

| Event Type | Purpose |
|---|---|
| `initial` | Delivers the complete hotel catalog, session ID, pagination metadata, and any cached pricing. This event always arrives first. |
| `update` | Carries live supplier results for a specific batch. Contains supplier ID, credential ID, batch index, supplier cost time, and the hotel rate payload. |
| `error` | Signals a supplier-level or global failure. Includes the same identity metadata as `update` events so failures can be correlated to specific supplier queries. |
| `complete` | Terminates the stream with aggregated statistics: total suppliers, success/failure counts, total credentials, total batches, and their respective success/failure breakdowns. |

Every event carries a monotonically increasing `eventSeq`, an `eventTs` (millisecond timestamp), and a `traceId` that is aligned across the HTTP response header and every SSE event. This allows distributed tracing tools to correlate the streaming HTTP request with each incremental payload.

### Batch Processing Layer

When a streaming search is initiated, the platform first resolves the buyer entity and all active seller entities for the requested hotels. For each seller, the system determines the optimal batch size (configurable per supplier entity) and splits the supplier hotel ID list into chunks.

The processing pipeline follows this pattern:

1. **Seller Parallelization** — Each seller is processed in its own concurrent goroutine. Sellers do not block one another.
2. **Batch Chunking** — Hotel IDs are partitioned into chunks based on the supplier's configured batch size. This prevents oversized supplier requests that can trigger timeouts or rate limits.
3. **Credential Concurrency** — Within each chunk, every available credential is queried concurrently. This maximizes throughput for accounts with multiple active credentials.
4. **Rule Application** — Responses flow through a deterministic pipeline: seller-out rules filter rooms, room mapping normalizes supplier room types, buyer-out rules enforce customer-specific pricing policies, and rate normalization flattens and deduplicates results.
5. **Room Aggregation** — Normalized rooms are grouped by hotel ID, and the minimum price per hotel is computed. The resulting `StreamUpdatePayload` contains one entry per hotel with its aggregated rooms and computed minimum price.
6. **Visibility Resolution** — A final visibility update is computed after all supplier responses have been processed. Hotels that received no live offers are hidden only when at least one other hotel in the same search has a confirmed live offer. If no hotel has offers, all hotels remain visible with a "no offers" indicator, preventing empty-result states.

### Frontend State Layer

The client maintains an in-memory `HotelStateMap` keyed by hotel ID. As `update` events arrive, the frontend performs an incremental merge:

- Existing hotel state is preserved for fields not present in the update.
- Incoming rooms are merged into the hotel's room list.
- Minimum price is updated when the new supplier price is lower than the current best price.
- The `hideFromSearchResults` flag is applied to suppress hotels that receive confirmed no-offer states.

To prevent excessive React re-renders during high-frequency updates, the frontend applies a 150-millisecond debounce window. Updates arriving within this window are batched into a single state transition. The debounce is flushed immediately when the `complete` event arrives, ensuring the final state is rendered without delay.

---

## Stream Lifecycle

A typical stream progresses through the following lifecycle:

1. **Request Ingestion** — The HTTP dispatcher recognizes that the service method returns a `StreamingOutput` implementation and delegates response writing to the stream object.
2. **Catalog Preparation** — The platform resolves the destination, builds the hotel list, applies pagination, and enriches with cached pricing. This phase is measured and reported in the `initial` event's `ServerCostMilliseconds` header.
3. **Initial Event Emission** — The full hotel list is serialized and flushed to the client. The connection remains open.
4. **Concurrent Supplier Execution** — Seller goroutines begin executing. As each credential query completes, the result is normalized, aggregated, and pushed to the stream channel.
5. **Incremental Persistence** — Before each `update` event is written, the current session state is cached. This guarantees session readiness for any immediate downstream `hotelRates` call.
6. **Update Event Emission** — Each supplier result is written as an `update` event with full trace context. Slow suppliers do not block fast ones because the channel is buffered and each supplier operates independently.
7. **Error Event Emission** — If a supplier query fails (timeout, authentication failure, business error), an `error` event is emitted with the same supplier/credential/batch metadata. The stream continues.
8. **Final Visibility Update** — After all sellers complete, a computed visibility patch is emitted to hide hotels with no offers (only when other hotels have valid offers).
9. **Complete Event Emission** — The `complete` event delivers final statistics and closes the stream.
10. **Structured Logging** — `GetLogData()` returns the full event journal, byte count, and success/failure statistics for the platform's structured log pipeline.

---

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| Server-Sent Events (SSE) Protocol | Progressive result delivery over a single long-lived HTTP connection; no WebSocket handshake overhead and full compatibility with standard HTTP infrastructure. |
| Initial Event with Full Catalog | Users see hotels within 200ms regardless of supplier latency, eliminating the blank-screen problem of traditional blocking search APIs. |
| Configurable Batch Chunking | Supplier requests are sized to match each supplier's capacity, reducing timeout rates and improving supplier relationship stability. |
| Credential-Level Concurrency | Multi-credential accounts achieve maximum parallel throughput; one credential's slowness does not delay another. |
| Seller-Level Fault Isolation | A failing supplier is contained to its own error event; all other suppliers continue streaming unaffected. |
| Real-Time Price Merging | The frontend always displays the lowest price observed across all suppliers, updated live as each batch returns. |
| Debounced Frontend Rendering | A 150ms batching window prevents UI thrashing during high-frequency updates while preserving perceived real-time behavior. |
| Incremental Session Persistence | Session state is cached before every update event, ensuring that subsequent `hotelRates` calls are immediately valid. |
| Conditional Hotel Visibility | Hotels without offers are hidden only when alternatives exist; otherwise, the catalog remains intact to prevent empty-result UX degradation. |
| Per-Event Structured Logging | Every event type, supplier, credential, batch, and hotel count is recorded in a structured log object for audit and debugging. |
| Unified Trace ID Propagation | The same `traceId` flows from the HTTP response header through every SSE event, enabling end-to-end distributed tracing. |
| Stream Completion Statistics | The `complete` event reports total, success, and failure counts at supplier, credential, and batch granularity for operational transparency. |
| `StreamingOutput` Framework Extension | Streaming endpoints are first-class citizens in the HTTP dispatcher, with automatic bypass of default JSON marshaling and retained observability. |

---

## Auditability

External reviewers and enterprise customers can verify HotelByte streaming search controls through the following mechanisms:

1. **Structured Stream Logs (HBLog)** — Every stream emits a structured log object via `GetLogData()` containing event count, byte count, total suppliers, success/failure breakdowns by supplier, credential, and batch, and a chronological event journal. These logs are retained and available for audit export.

2. **Trace ID Correlation** — The `traceId` returned in the HTTP `Trace-Id` header is identical to the `traceId` field in every SSE event. Reviewers can correlate the parent HTTP request with each incremental event in log aggregation tools.

3. **Per-Event Timing** — The `ServerCostMilliseconds` field in each event header reports the backend cost for that specific phase: initial preparation cost for the `initial` event, supplier round-trip cost for each `update` event, and total stream duration for the `complete` event.

4. **Stream Statistics Payload** — The `complete` event's `stats` object reports `totalSuppliers`, `success`, `failed`, `totalCredentials`, `successCredentials`, `failedCredentials`, `totalBatches`, `successBatches`, and `failedBatches`. These counters can be validated against supplier configuration and expected concurrency levels.

5. **E2E Test Coverage** — The streaming endpoint is covered by end-to-end tests that validate progressive loading, real-time price updates, error handling, hotel visibility logic, and performance thresholds. Reviewers can execute these tests in a local environment to reproduce control behavior.

6. **Source Annotations** — The streaming service method declares OpenAPI tags, authentication requirements, and permission annotations in source code. These annotations are parsed at build time and can be statically audited to verify that the endpoint matches published API documentation.

---

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **HTML Standard — Server-Sent Events (WHATWG)** | "The event stream is a simple stream of text data which must be encoded using UTF-8. Each message is separated by a double newline." | The streaming endpoint emits strictly formatted SSE events (`event: {type}\ndata: {payload}\n\n`) with `Content-Type: text/event-stream`, ensuring universal browser and proxy compatibility. |
| **RFC 6202 — Known Issues and Best Practices for the Use of Long Polling and Streaming in Bidirectional HTTP** | "Use the 'Cache-Control: no-cache' header to prevent intermediaries from buffering responses." | The platform sets `Cache-Control: no-cache`, `Connection: keep-alive`, and `X-Accel-Buffering: no` to prevent intermediate proxies from buffering SSE events. |
| **Google Web Vitals — First Contentful Paint (FCP)** | "FCP measures how long it takes the browser to render the first piece of DOM content after a user navigates to your page." | The streaming architecture targets FCP < 500ms by delivering the full hotel catalog in the `initial` event, followed by progressive price enhancement via `update` events. |
| **Martin Fowler — Circuit Breaker Pattern** | "The basic idea behind the circuit breaker is very simple. You wrap a protected function call in a circuit breaker object, which monitors for failures." | Supplier failures are isolated to discrete `error` events; the stream continues for healthy suppliers. This containment acts as a per-supplier circuit breaker at the event-stream level. |
| **AWS Well-Architected Framework — Performance Efficiency Pillar** | "Use a multi-threaded or asynchronous architecture to reduce blocking and increase throughput." | The batch processing layer executes sellers, batches, and credentials in concurrent goroutines with bounded error groups, maximizing throughput while preventing unbounded goroutine growth. |
| **NIST SP 800-53 Rev. 5 AU-12 Audit Generation** | "The information system provides audit record generation capability for the events defined in AU-2 at all information system components where audit capability is deployed." | `StreamHotelListResp` maintains an internal event journal (`logEvents`) and exposes `GetLogData()` to return a structured audit object containing every event, supplier, batch, and outcome, ensuring no audit gap for streamed responses. |

---

*For questions or audit requests regarding this whitepaper, contact HotelByte Engineering via your assigned partner channel.*

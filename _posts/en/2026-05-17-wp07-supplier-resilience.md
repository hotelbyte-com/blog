---
layout: post
title: "Supplier Resilience Starts With Failure Classification, Not Retry Policy"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Supplier Integration]
tags: ["Supplier Integration", "Hotel API", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP07 guide: Supplier resilience starts with failure classification before retry policy—otherwise retries amplify rather than mitigate failure."
lang: en
permalink: /en/whitepapers/wp07-supplier-resilience/
source_asset: hotel-be/docs/whitepapers/07-supplier-resilience-engineering.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp07-supplier-resilience/original/
---

> Picture a small hiccup on a cancellation API: the search API stays perfectly healthy, yet both endpoints are blocked by the same circuit breaker. A business 4xx—"no rooms for that date"—inflates the failure budget designed for 5xx. An HTTP 429 rate-limit signal gets drowned under automatic retries and pushes the supplier's capacity past the edge. None of this happens because there are not enough retries. It happens because retries run before classification.

Supplier resilience starts with failure classification before retry policy.

## Why More Retries Make It Worse

> "Retries are not a strategy. They are a downstream consumer of a classification system."

The first reaction to a failing supplier is almost always the same: increase retries. Add exponential backoff. Maybe a circuit breaker if the team has read the right blog posts. What rarely happens first is asking what kind of failure the supplier is actually signaling—and whether retrying makes it better or worse.

This distinction matters because not all failures are equal, yet most platforms treat them as a single bucket.

- **Transient infrastructure errors** — network timeouts, connection failures, HTTP 5xx. Recoverable jitter at the network or process layer; retrying is reasonable.
- **Rate-limit signals (HTTP 429)** — the supplier explicitly asking for less traffic. Retrying immediately is an attack on its capacity: it overwhelms the supplier and breaks connections that were just recovering.
- **Business-level 4xx outcomes** — invalid destination code, room unavailable, price changed. Expected application results; retrying them wastes resources and corrupts monitoring signals.
- **Credential or configuration failures** — expired keys, revoked tokens, suspended tenants. Security or configuration problems; repeated retries risk account lockout and audit exposure.

Without classification, the retry policy becomes a blunt instrument that amplifies load during the exact moments the platform should be shedding it. The "failure rate is climbing" alert then reflects a broken taxonomy, not a supplier that is truly down.

## What HotelByte Chose — Classify, Then Decide

> "A circuit breaker is not a fail-counter. It is an executor the classification system exposes outward."

HotelByte's Supplier Resilience Engineering layer is built on the opposite assumption: failure classification must precede every resilience decision. The platform distinguishes the four categories above and routes each through a different control path:

- Business errors do not count toward circuit breaker thresholds, and they do not consume rate-limit failure budgets.
- Rate-limit responses trigger the adaptive learning engine (next section), not blind retries.
- Credential failures are surfaced immediately to operators, not hidden in retry loops.
- Only transient infrastructure errors enter the standard retry-plus-circuit-breaker path.

The circuit breaker implementation is scoped to `supplier:apiName` pairs, not to suppliers as a whole. This is a subtle but critical boundary: a single misbehaving endpoint—say, a supplier's cancellation API—should not consume the failure budget of that supplier's search API, which may be perfectly healthy. Dimension isolation prevents cross-contamination and keeps controls precise under partial degradation.

## Rate-Limit Twin Engines + Recording Replay

> "The default failure mode of resilience controls is faith-based: you believe they work because the code looks right, not because you have evidence."

Rate limiting operates through a dual-engine architecture. The **config-driven engine** enforces static per-credential limits, scoped globally or by individual API name via the `byApi` option—letting you throttle high-cost operations (cancellation, booking) more aggressively than lightweight queries. The **adaptive learning engine** responds to live HTTP 429 signals by computing a safe threshold from the recent request window (`learnedLimit = count × 0.8`) and persisting it to a distributed cache. A **strict QPM scheduler** smooths request admission rather than allowing burst-and-starve patterns at interval boundaries. The result: quota changes on the supplier side are absorbed automatically, without manual tuning or emergency deploys.

The recording and replay layer provides the forensic capability that makes all of this verifiable. A **boundary detector** classifies requests into boundary-triggered (HTTP 400+, timeouts, rate-limit headers) or normal traffic. Boundary events are recorded at 100% fidelity; normal traffic is sampled. A **sanitizer** strips PII and credentials before storage. A **replay player** re-executes historical requests against current implementations, enabling regression validation after supplier-side changes or platform updates. Without this layer, resilience controls are faith-based, not engineered.

## The Middleware Chain — Unbypassable Ordering

> "The order is not a suggestion. It is enforced by the unified executor, and raw HTTP clients are architecturally prohibited."

The middleware chain ordering is deliberate:

```
cache → rate limit → circuit breaker → proxy → HTTP transport → error mapping → cache write
```

Each stage has its reason; skipping any one amplifies a different risk:

- Cache lookup must precede rate limiting—repeated queries should not consume the rate budget.
- Rate limiting must precede circuit breaker evaluation—so queued requests are not prematurely rejected by the breaker.
- Circuit breaker must precede the HTTP transport—so it protects network and thread resources from an already-open supplier.
- Error mapping must follow the response—so supplier-specific status codes are translated into platform-standard outcomes.
- Cache write must come last—so only successful, non-empty responses populate the result cache.

This ordering is not documentation folklore. It is enforced by the unified executor, and raw HTTP clients are architecturally prohibited: any adapter that tries to bypass the middleware chain fails at compile time.

## When This Pattern Does Not Fit

The WP07 tradeoff has a real cost. It is justified only when **all four** of the following conditions hold:

1. **Multi-supplier heterogeneity** — you aggregate multiple independent supplier interfaces, and single-point retry/breaker logic cannot handle their variance.
2. **Dimension-isolation payoff** — individual suppliers expose several APIs whose failure budgets need to be separated.
3. **Runtime homogeneity** — your team can maintain one middleware library, in one language, on one build pipeline.
4. **Observability investment** — your team is willing to pay the storage and query cost of structured logs, metrics, and replay samples.

If your supplier footprint is small, your call graph shallow, or your stack polyglot, the WP07 middleware framework becomes a tax rather than a benefit. The value of this whitepaper is precisely that it records the boundary conditions under which this otherwise-counterintuitive choice becomes rational.

## What to Read in the Whitepaper

- **Design Principles** — for the reasoning behind Fail Fast and Recover Gracefully, Learning from Feedback, Defense in Depth, Interface-First, and Dimension Isolation.
- **Layered Architecture** — for the exact responsibilities of the rate-limit, circuit-breaker, recording, and middleware-integration layers, and the counterfactual of what goes wrong if any layer is omitted.
- **Implemented Control Summary** — a nine-row table; cross-check which controls you already have and which are missing.
- **Auditability** — how metrics, structured logging, recording, replay, and feature-flag governance let operators review every resilience decision after the fact.
- **Authoritative Source References** — eight external standards (Netflix Hystrix, Google SRE, OWASP, Martin Fowler, AWS Well-Architected, etc.) and their specific mappings into WP07 controls.

## Read the Full Whitepaper

- [English whitepaper](/en/whitepapers/wp07-supplier-resilience/original/)
- [中文白皮书原文](/zh/whitepapers/wp07-supplier-resilience/original/)
- [Whitepaper Index](/en/whitepapers/)

---

The durable lesson is that resilience is not a collection of mechanisms. It is a classification discipline. Retry, circuit breaking, and rate limiting are only as good as the failure taxonomy that feeds them. Without that taxonomy, every resilience policy is a gamble.
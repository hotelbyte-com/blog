---
layout: post
title: "Retry Without Classification Is Just Load Amplification"
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

The first reaction to a failing supplier is almost always the same: increase retries. Add exponential backoff. Maybe a circuit breaker if the team has read the right blog posts. What rarely happens first is asking what kind of failure the supplier is actually signaling—and whether retrying makes it better or worse.

This distinction matters because not all failures are equal, yet most platforms treat them as a single bucket. A network timeout from an overloaded bed bank is a transient infrastructure problem; retrying it is reasonable. An HTTP 429 rate-limit response is the supplier explicitly asking for less traffic; retrying it immediately is an attack on their capacity. An HTTP 4xx business error—invalid destination code, room unavailable, price changed—is an expected application outcome; retrying it wastes resources and can mislead monitoring. A credential failure is a security or configuration issue; retrying it repeatedly risks account lockout and audit exposure. Without classification, the retry policy becomes a blunt instrument that amplifies load during the exact moments the platform should be shedding it.

HotelByte's Supplier Resilience Engineering layer is built on the opposite assumption: failure classification must precede every resilience decision. The platform distinguishes four categories of outbound failure—transient infrastructure errors, rate-limit signals, business-level 4xx outcomes, and credential or configuration failures—and routes each through a different control path. Business errors do not count toward circuit breaker thresholds. Rate-limit responses trigger adaptive learning rather than blind retry. Credential failures are surfaced immediately to operators rather than hidden in retry loops.

The circuit breaker implementation is scoped to `supplier:apiName` pairs, not to suppliers as a whole. This is a subtle but critical boundary. A single misbehaving endpoint—say, a supplier's cancellation API—should not consume the failure budget of that supplier's search API, which may be perfectly healthy. Dimension isolation prevents cross-contamination and ensures that controls remain precise under partial degradation.

Rate limiting operates through a dual-engine architecture. A config-driven engine enforces static per-credential limits, scoped globally or by individual API name. An adaptive learning engine responds to live HTTP 429 signals by computing a safe threshold from the recent request window and persisting it to distributed cache. The strict QPM scheduler smooths request admission rather than allowing burst-and-starve patterns at interval boundaries. The result is that quota changes on the supplier side are absorbed automatically, without manual tuning or emergency deploys.

The recording and replay layer provides the forensic capability that makes all of this verifiable. A boundary detector classifies requests into boundary-triggered or normal traffic. Boundary events are recorded at 100% fidelity; normal traffic is sampled. A sanitizer strips PII and credentials before storage. The replay player can re-execute historical requests against current implementations, enabling regression validation after supplier-side changes or platform updates. Without this, resilience controls would be faith-based: you would believe the circuit breaker works because the code looks right, not because you have evidence.

The middleware chain ordering is deliberate and unbypassable: cache lookup, rate limit, circuit breaker, proxy, HTTP transport, error mapping, cache write. Every supplier request flows through this exact sequence. Cache lookups skip downstream controls for efficiency; rate limiting precedes circuit breaker evaluation so queued requests are not prematurely rejected; the circuit breaker protects the actual HTTP transport; error mapping runs after the response returns. This ordering is not a suggestion—it is enforced by the unified executor, and raw HTTP client usage is architecturally prohibited.

If you are evaluating this system, the whitepaper chapters that deserve close attention are:

- **Design Principles** — for the reasoning behind Fail Fast and Recover Gracefully, Learning from Feedback, and Dimension Isolation.
- **Rate Limiting Layer** — for the mechanics of the adaptive learning engine and the strict QPM scheduler.
- **Circuit Breaker Layer** — for the 4xx versus 5xx classification logic and the per-endpoint scoping rules.
- **Recording Layer** — for the boundary detection, sampling strategy, sanitization, and replay validation paths.
- **Middleware Integration Layer** — for the exact control ordering and the architectural prohibition on raw HTTP clients.

The full English whitepaper is available at [WP07 — Supplier Resilience Engineering](/en/whitepapers/wp07-supplier-resilience/original/), and the Chinese version is at [WP07 中文原文](/zh/whitepapers/wp07-supplier-resilience/original/). For the complete set of whitepapers, see the [HotelByte Whitepaper Index](/en/whitepapers/).

The durable lesson is that resilience is not a collection of mechanisms. It is a classification discipline. Retry, circuit breaking, and rate limiting are only as good as the failure taxonomy that feeds them. Without that taxonomy, every resilience policy is a gamble.

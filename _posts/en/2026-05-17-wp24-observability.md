---
layout: post
title: "Five Dashboards, Five Stories, One Incident"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Engineering Excellence]
tags: ["Engineering Excellence", "Quality", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP24 guide: Observability only works when errors, traces, profiles, metrics, and audit logs can explain the same incident."
lang: en
permalink: /en/whitepapers/wp24-observability/
source_asset: hotel-be/docs/whitepapers/24-five-dimensional-observability.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp24-observability/original/
---

The hotel distribution industry has no shortage of telemetry. Every platform collects logs, metrics, and traces. The problem is not collection—it is correlation. When an incident occurs, error tracking says one thing, distributed tracing says another, metrics suggest a third explanation, and the audit trail implies a fourth. The result is not clarity; it is a Rorschach test where every team sees what they expect to see.

HotelByte's five-dimensional observability framework is built on a single principle: correlation over collection. A unified `logid` identifier propagates across error events, distributed traces, profiling snapshots, Prometheus metrics, and structured business logs. The goal is not more dashboards. It is the ability to retrieve the complete context of a single request—from edge ingress through every downstream supplier interaction—with one identifier.

## The Evidence Gap in Production Incidents

Consider a typical failure mode: a customer reports an unexpected rate for a hotel. The metrics dashboard shows a spike in `SupplierRateLimitWaitTiming`. The error tracker shows a cluster of timeout exceptions. The trace visualization reveals that one supplier span took 8 seconds. The business log shows that a fallback rate was returned. The profiling data indicates elevated goroutine contention in the normalization layer.

Without correlation, these five signals are five separate investigations. With correlation, they are five views of the same request. HotelByte's `logid` makes this possible: the same identifier appears in the Sentry error event, the OpenTelemetry trace, the Prometheus metric labels, the Pyroscope profiling snapshot, and the VictoriaLogs business log entry. An on-call engineer can move from alert to root cause without manual log correlation.

## What HotelByte Chose—and What It Costs

The framework prioritizes correlation infrastructure over raw volume. This means predefined cardinality boundaries on metrics, standardized naming conventions enforced at build time, and automatic sensitive-data sanitization before telemetry leaves the application boundary. Authorization headers, cookies, and tokens are stripped from error reports and traces by default.

The trade-off is that ad-hoc exploration is constrained. You cannot add an arbitrary high-cardinality label to a metric without considering the storage cost and query performance. You cannot emit a raw stack trace without verifying that it contains no PII. The platform auto-instruments services at construction time, which means new features enter production with full visibility—but also means that instrumentation changes require the same review discipline as business logic changes.

## The Five Dimensions in Practice

**Error tracking** is not just exception capture. Business-critical panics are auto-promoted to fatal-level events with storm control and deduplication, ensuring that cascading failures produce one actionable notification per distinct issue rather than hundreds of redundant alerts.

**Distributed tracing** follows a booking request from edge API through rate-limiting, cache evaluation, supplier availability checks, response normalization, and final assembly. Each span carries timing data, error status, and custom attributes that reveal exactly where latency accumulates or failures originate.

**Continuous profiling** captures CPU and memory flame graphs from production workloads without perceptible overhead. Historical profiling data enables before-and-after deployment comparison, catching performance regressions that escape traditional load testing.

**Metrics** are organized into five functional domains—API, Business, Supplier, Cache, and Agent—feeding Prometheus with consistent labels for dimensional analysis. Dashboard deployment is automated to prevent configuration drift across environments.

**Business-context logging** records not just events but decision processes: intermediate states, supplier responses, normalization decisions, and anomalies encountered. This transforms debugging from reactive log-grepping into structured narrative reconstruction.

## Reading Path

Read **"Correlation Over Collection"** in the Design Principles section first. It is the conceptual foundation that makes the other four dimensions meaningful.

For the operational mechanics, the **"Observability Architecture"** section details each of the five layers: error tracking with sensitive-data filtering and trace association; distributed tracing with OpenTelemetry auto-instrumentation and multi-protocol export; continuous profiling for production flame graphs; the five functional metric domains; and business-context logging with readiness probing.

For incident response, **"Observability Lifecycle / Alert Flow"** describes the seven-stage pipeline from instrumentation through learning, with explicit correlation points at each stage.

## Cross-References

- [Read the full WP24 whitepaper (English)](/en/whitepapers/wp24-observability/original/)
- [Read the Chinese version of WP24](/zh/whitepapers/wp24-observability/original/)
- [Browse the whitepaper index](/en/whitepapers/)

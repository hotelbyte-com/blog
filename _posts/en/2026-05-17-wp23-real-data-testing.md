---
layout: post
title: "Your Mocks Are Lying to You"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Engineering Excellence]
tags: ["Engineering Excellence", "Quality", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP23 guide: Real-data testing is not about rejecting mocks—it is about exposing supplier truth before UAT or production."
lang: en
permalink: /en/whitepapers/wp23-real-data-testing/
source_asset: hotel-be/docs/whitepapers/23-real-data-testing-culture.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp23-real-data-testing/original/
---

The most expensive bug is the one that passes every test and still fails in production. In hotel distribution, this is not a theoretical risk—it is the default outcome when your test suite simulates ideal supplier behavior while real suppliers return partial responses, rate-limit errors, and payload shapes that diverge from their own documentation.

Most teams know this. Their response is to add more mocks, more synthetic data, and more local test fixtures. The result is a test suite that grows in volume while shrinking in predictive power. HotelByte's response is different: an independent E2E application that calls live APIs with real credentials, creates real bookings, and voids them. The goal is not to eliminate mocks—it is to ensure that mocks are not the last line of defense.

## Three Failure Modes Mocks Hide

**Shape drift.** A supplier changes a field name, adds a nested object, or moves a critical value into a comment field. Mocks frozen at the time of integration continue to pass while production encounters deserialization errors or silent data loss.

**State blindness.** A booking test that mocks the supplier response cannot verify whether the reservation actually exists in the supplier's system, whether the cancellation policy was correctly transmitted, or whether the confirmation code maps to a real record.

**Latency fiction.** Mocks return in milliseconds. Real supplier APIs vary by continent, time of day, and rate-limit window. A timeout configured against a mock will be wrong in production, either failing healthy requests or waiting too long on degraded ones.

HotelByte's E2E framework (`api/tests/`) is designed to expose these failures before they reach UAT. It uses the same `sdk/go` client available to external integrators, authenticates with real credentials, and exercises 40+ scenarios across search, rate, availability, booking, cancellation, and order query chains. A booking test creates a real reservation; a cancellation test voids it. There is no stubbing, no in-process short-circuiting, and no synthetic inventory.

## The Boundary: Intra-Layer Real, Cross-Layer Mocked

HotelByte does not reject all mocking. The rule is precise: calls within the same architectural layer use real implementations; calls that cross a layer boundary are mocked. A domain test invokes real domain methods. A service test mocks the DAO it depends on, but executes real service logic. This prevents the test suite from validating the mock framework instead of the production code, while keeping unit tests fast enough to run on every commit.

The trade-off is test execution time and cost. Real-data E2E tests are slower than mocked suites, and real bookings consume supplier quota. HotelByte manages this with a 500-assertion threshold per run—flagging incomplete validation surfaces—and incremental report comparison that surfaces silent test shrinkage even when all scenarios pass. Coverage floors are enforced in CI: 100% for domain logic, 80%+ for data access layers, 70%+ for service layers. Pull requests that reduce coverage below tier thresholds are blocked.

## What This Costs

The zero-tolerance policy for hardcoded test data means engineers cannot drop a JSON fixture into a test file and call it done. Every test input must derive from real sources or explicitly managed test accounts. This is slower than synthetic data, and it requires a unified test account matrix (platform admin, tenant user, OpenAPI customer) that is maintained across all scenarios.

The payoff is that when a test fails, the failure is informative. It reflects a real supplier behavior change, a real data shape anomaly, or a real regression—not a mock that was never updated.

## Reading Path

Start with **"Test Against Reality"** in the Design Principles section. It is the clearest statement of why real-data testing is an architectural constraint, not a testing preference.

For the operational mechanics, read **"End-to-End Layer"** in the Testing Architecture section. It details the 40+ scenarios, multi-environment execution, assertion buckets, 500-assertion threshold, and incremental comparison logic.

For the governance angle, **"Auditability"** lists the seven verification mechanisms—published E2E reports, coverage artifacts, static assertion manifests, code review rules, test account provenance, CI enforcement logs, and LLM test artifacts—that make the testing culture inspectable.

## Cross-References

- [Read the full WP23 whitepaper (English)](/en/whitepapers/wp23-real-data-testing/original/)
- [Read the Chinese version of WP23](/zh/whitepapers/wp23-real-data-testing/original/)
- [Browse the whitepaper index](/en/whitepapers/)

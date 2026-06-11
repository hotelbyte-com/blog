---
layout: post
title: "A Price Without Provenance Is a Liability"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Commercial Controls]
tags: [Pricing, "Business Rules", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP15 guide: Dynamic pricing becomes governable when every price can explain which rules shaped it."
lang: en
permalink: /en/whitepapers/wp15-pricing-rules/
source_asset: hotel-be/docs/whitepapers/15-dynamic-pricing-and-business-rules-engine.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp15-pricing-rules/original/
---

The most expensive bug in a pricing system is not a miscalculation. It is a price that looks correct but cannot be explained. When a buyer disputes a rate, when a supplier claims underpayment, when a revenue team audits quarterly commissions, the platform must answer a simple question: why was this number returned? Most rules engines fail this test. They compute fast, mutate silently, and leave behind a final price with no ancestry. The result is operational paralysis: teams know something changed, but they cannot reconstruct what, when, or by whose authority.

HotelByte's Dynamic Pricing & Business Rules Engine treats provenance as a first-class output. Every room rate that passes through the system carries a `MarkupProcess` trace that records the original supplier net rate, the final buyer-facing rate, the absolute and percentage delta, and a chronological list of every rule that fired—including the rule ID, the strategy type, the scene label, and a human-readable description. This is not a logging afterthought. It is a structural guarantee: if a price exists, its explanation exists.

## The Industry Pattern: Black-Box Markup

Commercial teams in hotel distribution typically manage pricing through one of three paths: hard-coded logic in supplier adapters, spreadsheet-driven bulk updates, or external rule engines integrated via opaque APIs. All three share the same failure mode: the rule that modified the price is decoupled from the price itself. A post-request markup of 12% applied by a "seasonal adjustment" rule in a third-party system leaves no trace in the platform's response payload. The buyer sees a number. The platform sees a number. No one sees the chain.

This opacity creates three predictable problems. First, dispute resolution becomes a forensic exercise requiring cross-system log correlation that may span multiple vendors and time zones. Second, regression testing is impossible: a rule change in January may alter prices in June, and the platform has no mechanism to detect the drift until a buyer complains. Third, multi-party governance collapses. When platform operators, suppliers, and buyers each maintain independent rule sets, the absence of a unified trace means no single party can verify that its policies were applied correctly.

## HotelByte's Trade-Off: Configuration Over Code, Trace Over Speed

The engine is built on a three-layer architecture—factors, conditions, and actions—that separates "what is being evaluated" from "when it should trigger" and "what should happen next." Rules are expressed as declarative JSON configurations rather than imperative code. This choice sacrifices the expressive power of Turing-complete scripts in exchange for deterministic evaluation, versionable definitions, and non-engineering authorship.

The trade-off is real. A configuration-driven engine cannot express arbitrary business logic. It cannot call external services during evaluation, cannot maintain hidden state between requests, and cannot introduce temporal side effects. These restrictions are deliberate boundaries. They ensure that identical inputs always yield identical outputs—a property that caching layers, reconciliation pipelines, and dispute resolution all depend on.

The evaluation lifecycle is split into two phases. Pre-request actions govern supplier selection and request shaping before any external call is made. Post-request actions apply markups or filtering after supplier responses are received. This separation prevents wasteful supplier calls and ensures that buyer-facing prices are computed from fully materialized rates rather than estimates.

## Semantic Guards in the Markup Layer

The engine implements four markup models—percentage, fixed amount, multiplier, and tiered—each with bounded parameters validated at rule creation, simulation, and execution time. Percentage markups are constrained between -99% and +1000%; multipliers between 0× and 10×; tier intervals must be well-formed and monotonic. These bounds are not performance optimizations. They are semantic guards that prevent malformed or malicious rules from distorting prices.

Floating-point boundary precision handling ensures that integer-valued thresholds behave correctly when the underlying rate is represented as a decimal currency type. A condition such as `netRate > 100` must not misclassify a value of `99.999999999` due to IEEE 754 representation errors. The engine applies precision-safe comparison semantics to eliminate this class of subtle markup failures.

The factor registry organizes contextual dimensions into five scopes—Request, User, Item, Tenant, and Environment—each with explicitly defined data sources and operator support. This scoping prevents rule authors from inadvertently creating cross-tenant conditions and enables the engine to pre-filter the factor set for each evaluation context.

## What to Read in the Whitepaper

If you are evaluating HotelByte's commercial controls, focus on these chapters:

- **Factor Layer** — understand the five evaluation scopes and the hybrid data source resolution strategy.
- **Condition Layer** — examine the operator semantics and floating-point precision handling.
- **Action Layer** — review the pre-request and post-request action types, the four markup models, and their parameter bounds.
- **Rule Evaluation Lifecycle** — trace how Seller-In, Seller-Out, and Buyer-Out rules execute in sequence.
- **MarkupProcess Trace** — study the response-level provenance structure and its role in dispute resolution.
- **Implemented Control Summary** — review the full list of controls, including simulation capabilities and multi-tenant rule isolation.

The full technical specification is available in the [Dynamic Pricing & Business Rules Engine whitepaper](/en/whitepapers/wp15-pricing-rules/original/). A Chinese version is also available: [动态定价与业务规则引擎白皮书](/zh/whitepapers/wp15-pricing-rules/original/).

For the complete whitepaper index, see [HotelByte Whitepapers](/en/whitepapers/).

---
layout: post
title: "Field Names Don't Make Prices Right"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Supplier Integration]
tags: ["Supplier Integration", "Hotel API", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP10 guide: money semantics preservation vs field renaming"
lang: en
permalink: /en/whitepapers/wp10-price-normalization/
source_asset: hotel-be/docs/whitepapers/10-multi-supplier-price-normalization.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp10-price-normalization/original/
---

The most expensive bug in price normalization looks correct on the surface. A supplier returns `NetRate: 120.00` and `Currency: USD`; the platform renames it to `customerNetPrice` and passes it downstream. The field names are aligned. The data type is a decimal. The pipeline is green. But the 120 dollars might be per-room per-night, total-stay inclusive, net-exclusive before commission, or gross with taxes folded in—and the downstream booking engine has no way to know.

Most integration teams discover this only after a customer books a five-night stay expecting a 120-dollar total and receives an invoice for 600. By then the damage is split between finance, customer support, and the supplier relationship manager.

## The Semantic Erosion Problem

Hotel distribution is uniquely hostile to implicit assumptions. One supplier quotes per-room nightly rates; another quotes total-stay prices. One includes resort fees in the headline number; another buries them in `rateComment`. One uses the customer's requested currency; another responds in its own default and expects the platform to convert. When normalization is treated as a schema-mapping exercise—renaming fields and coercing types—these semantic differences survive as silent errors.

The industry default is to trust the supplier's documentation and hope the integration test suite catches discrepancies. It rarely does, because test environments typically use single-room, single-night queries that mask per-room versus total-stay ambiguity. Production traffic, with multi-room multi-night bookings, is where the mismatch surfaces.

## HotelByte's Guard: Preserve Semantics, Not Just Fields

HotelByte's pipeline treats semantic completeness as a validation gate, not a documentation concern. The four-stage contract—validation, derivation, conversion, buffer application—does not merely transform data; it verifies that every monetary amount carries enough context to be interpreted safely.

At the validation stage, any non-zero amount without an explicit ISO 4217 currency code is rejected outright. No inference from context, no fallback to a previously seen currency, no silent defaulting. This eliminates the class of bugs where a supplier's omission becomes a misdenomination.

At the derivation stage, the pipeline reconciles per-room and total-stay representations through mutual derivation. If a supplier provides only a total, the per-room rate is computed with precise decimal arithmetic and treated as a first-class input. If only per-room rates are present, the total is derived. Either way, the downstream system receives both representations, cross-validated.

At the conversion stage, foreign-exchange transformation uses a snapshot rate captured at search time and applies a configurable buffer exactly once. The snapshot is carried forward through booking and cancellation, so the customer does not see a different rate at checkout than at search. If conversion fails, the original currency and amount are preserved with a warning—never dropped silently.

At the buffer stage, cancellation deadlines are shifted earlier by a configurable safety buffer (default 36 hours) and realigned to the tenant's business timezone. A policy originally marked "fully refundable" is re-evaluated against the buffered deadline, so the customer sees an actionable refundability status rather than a stale supplier assertion.

## What This Approach Gives Up

The pipeline is not free. Strict currency validation means some supplier responses are rejected that a more permissive system would accept, reducing apparent catalog breadth. Precise decimal arithmetic is slower than floating-point. FX buffer application makes HotelByte's displayed prices slightly higher than the raw supplier quote during volatile rate periods. And the 36-hour cancellation buffer narrows the effective refund window for the customer.

These are intentional trade-offs. The platform chooses correctness over coverage, stable semantics over raw performance, and customer safety over headline price competitiveness. In a market where a single mispriced booking can cost more than the margin on a hundred correct ones, the math is straightforward.

## What to Read in the Whitepaper

If you want to understand the mechanics of semantic preservation, focus on the **Price Normalization Pipeline** section, which walks through each of the four stages with exact formulas and failure modes. The **Booking Safety Lifecycle** section is worth reading for the environment-isolation controls: automatic test-order marking, live-credential refundable-only gates, and the two-phase timeout recovery protocol that resolves ambiguous booking states without manual intervention. The **Auditability** section lists the specific metrics and trace fields that reviewers can query to verify that normalization is behaving as described.

The full whitepaper is available in [English](/en/whitepapers/wp10-price-normalization/original/) and [Chinese](/zh/whitepapers/wp10-price-normalization/original/). For the complete set of whitepapers, see the [Whitepaper Index](/en/whitepapers/).

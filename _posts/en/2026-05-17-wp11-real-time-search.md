---
layout: post
title: "Concurrent Fan-Out Is the Easy Part"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Search & Trade]
tags: ["Search", "Booking", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP11 guide: controlled competition vs simple fan-out"
lang: en
permalink: /en/whitepapers/wp11-real-time-search/
source_asset: hotel-be/docs/whitepapers/11-real-time-search-aggregation.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp11-real-time-search/original/
---

The first thing most engineers build for multi-supplier search is a `Promise.all` over an array of supplier clients. It works in the demo. It looks elegant in the architecture diagram. And it collapses in production when supplier number seven takes eight seconds, supplier twelve returns a duplicate hotel under a different ID, and the merged catalog contains three versions of the same room at three different prices with no indication of which one the customer should trust.

Concurrent fan-out is not the architecture. It is the prerequisite. The real problem is what happens after the responses start arriving.

## Why Simple Fan-Out Fails

The hotel distribution industry runs on heterogeneous data models. The same physical property is `HTL-48291` in one supplier's system, `PROPERTY_7723` in another, and a SHA256 hash in a third. The same room type is "Deluxe King with City View" in one feed and "DLX-K-CV" in another. A rate that includes breakfast in one response excludes it in another, and the difference is buried in a free-text policy field.

When a platform treats search as "query everyone, concatenate results," the customer receives a catalog that looks comprehensive but is actually unusable. Duplicate listings erode trust. Inconsistent room descriptions create support tickets. And price sorting across incompatible rate structures produces rankings that are technically correct and commercially meaningless.

The industry has learned to live with this by pushing the problem downstream. OTAs display multiple supplier offers for the same hotel as separate options. Metasearch engines show "prices from" ranges that hide the structural differences. The customer is expected to compare apples and oranges and make a decision. This is not a user experience; it is a user burden.

## HotelByte's Controlled Competition

HotelByte treats real-time search as a controlled competition among suppliers, not a simple fan-out. The dispatch layer does issue concurrent requests—this is table stakes—but the merge, processing, and caching layers impose a deterministic normalization pipeline that turns heterogeneous responses into a single canonical catalog.

The merge layer resolves supplier-specific hotel identifiers to master hotel IDs through the mapping layer. Room descriptions are aligned into a standardized taxonomy through automatic and manual mapping integration. Compatible rates are coalesced under unified entries, so the customer sees one hotel, one room type, one set of comparable prices.

The processing layer then applies redundancy detection, price-based sorting, per-hotel rate limiting, and business-rule transformations. Redundant packages—identical or near-identical room and rate combinations—are flagged rather than removed, preserving transparency. Seller-out and buyer-out rules operate on the normalized canonical model, not on raw supplier responses, ensuring consistency across all buyers.

The caching layer protects latency through dual-dimension minimum-price caching and session fallback. When content services are unavailable, the search engine falls back to session snapshots captured within the preceding 30 seconds, preserving functionality during transient outages.

## What Controlled Competition Costs

The normalization pipeline adds latency. Mapping resolution, room type consolidation, and rule-engine execution are not free. The platform accepts this because the alternative—returning raw, unmerged supplier data—produces a worse outcome for the customer and higher operational cost for the platform in support tickets and booking errors.

There is also a coverage trade-off. If a supplier's response cannot be mapped to the master catalog—because the property is unknown or the room type is unrecognizable—it may be excluded from the result set. A simple fan-out system would include it. HotelByte chooses catalog correctness over catalog breadth.

## What to Read in the Whitepaper

The **Search Aggregation Architecture** section details the four layers—dispatch, merge, processing, and caching—with exact controls and failure domains. The **Search Request Lifecycle** section walks through a complete query from admission to response assembly. For operators, the **Auditability** section describes the distributed trace correlation, structured quality metrics, and rule-engine execution logs that make the aggregation behavior verifiable.

The full whitepaper is available in [English](/en/whitepapers/wp11-real-time-search/original/) and [Chinese](/zh/whitepapers/wp11-real-time-search/original/). For the complete set of whitepapers, see the [Whitepaper Index](/en/whitepapers/).

---
layout: post
title: "Streaming Results Are a State Consistency Problem"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Search & Trade]
tags: ["Search", "Booking", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP12 guide: incremental state consistency over time"
lang: en
permalink: /en/whitepapers/wp12-sse-streaming-search/
source_asset: hotel-be/docs/whitepapers/12-sse-streaming-search-architecture.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp12-sse-streaming-search/original/
---

The first user experience improvement most teams attempt for slow hotel search is "show something while we wait." They split the API into an initial response and a background poll. The user sees a hotel list immediately, prices update a few seconds later, and everyone congratulates themselves on shaving perceived latency. Then a user clicks a hotel at the 3-second mark, sees a price of 120 dollars, and by the time the booking page loads at the 8-second mark, the price has dropped to 98. Or risen to 145. The user does not know whether to refresh, wait, or trust what they see.

Streaming search is not a latency optimization. It is a state consistency problem distributed across time.

## The Incremental State Trap

Traditional blocking APIs have one advantage: the response is a snapshot. Every field is consistent with every other field at a single point in time. When you replace that with incremental updates, you trade snapshot consistency for responsiveness—and the trade is not always in the user's favor.

In a multi-supplier search, supplier A returns at 200ms, supplier B at 1.2s, supplier C at 4s, and supplier D times out at 8s. The frontend receives four separate payloads that must be merged into a coherent view. If the merge logic is naive—overwrite on arrival—the user sees prices flip-flop as cheaper offers replace more expensive ones. If the merge logic is too aggressive—hide hotels without offers too early—the user sees the catalog shrink before their eyes. If session state is not synchronized between the streaming endpoint and the downstream `hotelRates` call, the user clicks into a hotel whose price the backend no longer recognizes.

The industry default is to treat streaming as a presentation-layer concern. The backend streams raw supplier events; the frontend sorts out the UX. This pushes the hardest problem—incremental state consistency—to the least equipped layer.

## HotelByte's Time-Bounded Consistency Model

HotelByte's SSE streaming architecture treats incremental state as a first-class engineering problem, not a frontend afterthought. The protocol defines four event types—`initial`, `update`, `error`, and `complete`—each with monotonically increasing sequence numbers, millisecond timestamps, and a unified trace ID that flows from the HTTP header through every event.

The `initial` event delivers the complete hotel catalog within 200ms, including cached pricing and static content. This is not a placeholder; it is a fully usable catalog. Hotels without live offers remain visible with a "no offers" indicator, preventing the empty-result degradation that plagues naive streaming implementations.

As supplier responses arrive, `update` events carry live rates for specific batches. The frontend merges these incrementally into an in-memory `HotelStateMap`, preserving existing state for fields not present in the update and updating minimum prices only when a cheaper offer arrives. A 150-millisecond debounce window batches rapid updates into single state transitions, preventing React re-render thrashing without delaying the final `complete` event.

The critical consistency guarantee is session persistence. Before each `update` event is written to the client, the current session state is cached. If a user clicks into a hotel immediately after its price appears, the subsequent `hotelRates` call operates against a fully synchronized session. The price the user saw is the price the backend honors.

## What Streaming Costs

The architecture sacrifices strict snapshot consistency for responsiveness. At any moment between the `initial` event and the `complete` event, the displayed catalog is a partial view. A hotel's price may change between the user's glance and their click. The platform mitigates this through session synchronization and buffered cancellation policies, but the fundamental trade-off remains: the user sees a moving target.

There is also operational complexity. SSE bypasses default JSON marshaling, which would ordinarily produce a single structured log entry. HotelByte solves this with an internal event journal that records every emitted event—type, supplier, credential, batch index, hotel count, duration—and exposes it via `GetLogData()` upon stream completion. Without this, streamed responses would be audit black holes.

## What to Read in the Whitepaper

The **Streaming Architecture** section details the three coordinated layers—SSE protocol, batch processing, and frontend state—with exact event schemas and merge semantics. The **Stream Lifecycle** section walks through the ten-phase lifecycle from request ingestion to structured logging. For operators, the **Auditability** section explains how `GetLogData()`, trace ID correlation, and per-event timing make streamed responses as auditable as standard API calls.

The full whitepaper is available in [English](/en/whitepapers/wp12-sse-streaming-search/original/) and [Chinese](/zh/whitepapers/wp12-sse-streaming-search/original/). For the complete set of whitepapers, see the [Whitepaper Index](/en/whitepapers/).

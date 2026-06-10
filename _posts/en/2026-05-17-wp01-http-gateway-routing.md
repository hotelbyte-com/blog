---
layout: post
title: "Why We Put the Gateway Inside the Process"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Infrastructure]
tags: ["Infrastructure", "Platform Engineering", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP01 guide: Most platforms buy an API gateway or deploy a service mesh. HotelByte compiled gateway logic into every service process. The trade-off is real."
lang: en
permalink: /en/whitepapers/wp01-http-gateway-routing/
source_asset: hotel-be/docs/whitepapers/01-http-gateway-and-in-process-routing.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp01-http-gateway-routing/original/
---

# Why We Put the Gateway Inside the Process

Most hotel distribution platforms handle ingress the same way: buy an off-the-shelf API gateway, or layer a service mesh between microservices. HotelByte did neither. It compiled gateway logic—authentication, authorization, caching, streaming, field shaping, and request evidence—into every service process.

This is not a performance hack. In a system where a single search can fan out to thirty-plus internal calls, every network hop adds tail latency. Hotel search P99 latency directly affects conversion. Removing one hop by collapsing the gateway into the process boundary is a measurable win.

But the cost is real. You lose the freedom of polyglot microservices—every service must speak the same gateway language. Policy updates require recompilation and redeployment. CPU and memory contention inside the process demand stricter capacity planning. And the ten-layer onion middleware chain that replaces the external gateway is not something you can swap out with a vendor upgrade.

## What the Industry Usually Does

The default playbook is well understood: terminate TLS at the edge, run a gateway for rate limiting and routing, then let services communicate through a mesh or direct HTTP. This works until the internal call graph becomes dense. At HotelByte's scale—27+ supplier integrations, multi-tenant credential isolation, per-request field filtering—the gateway becomes a bottleneck and a single point of failure. Worse, every request crosses the gateway twice: once on ingress, once for every internal service call that needs authentication or caching.

## The In-Process Trade-Off

HotelByte's approach inverts the model. The gateway is not a separate process; it is a library linked into every service. The ten-layer middleware chain—Short Token authentication, RBAC, request normalization, caching, streaming, field shaping, evidence logging, and more—runs inside the same OS process as the business logic. This eliminates the network hop entirely for internal calls.

The whitepaper details three specific mechanisms that make this viable:

- **Short Token Mode**: A lightweight credential format that can be validated in-process without remote token introspection. Revocation happens in milliseconds because the token carries enough context to be rejected locally.
- **Query-Parameter-Only Routing**: REST path parameters are replaced with query parameters. This seems like a minor API style choice, but it makes cache keys deterministic across services—critical when the same request may be served by different process instances.
- **In-Process Dispatcher**: Internal service calls are dispatched through the same middleware chain as external requests, ensuring that security and observability policies apply uniformly. There is no "internal bypass" that quietly drops authentication or logging.

## What You Give Up

The whitepaper does not pretend this is free. The most significant constraint is language uniformity: the gateway library is written in Go, and every service that uses it must be a Go binary. Teams cannot drop in a Python or Node.js microservice and expect it to participate in the same security model. Policy changes—new middleware, updated authentication rules, revised field-shaping logic—require a full rebuild and redeploy of every service.

There is also a debugging cost. When the gateway was a separate process, you could tcpdump the boundary. Now the boundary is a function call inside the process. The whitepaper addresses this with structured evidence logging: every middleware layer emits a structured record that can be replayed and inspected after the fact.

## When This Choice Makes Sense

The in-process gateway is not a universal architecture. It pays off when three conditions hold:

1. **High internal call density**: The cost of network hops dominates the cost of in-process computation.
2. **Homogeneous runtime**: The organization can standardize on a single language and build system.
3. **Frequent policy changes are acceptable**: The team can tolerate redeployment cycles for security and routing updates.

If your internal call graph is shallow, or your services are polyglot, an external gateway or mesh is likely the better choice. HotelByte's whitepaper is useful precisely because it documents the boundary conditions where the反常 choice becomes rational.

## What to Read in the Full Whitepaper

- **Layered Architecture**: The ten-layer middleware chain and what each layer owns.
- **Short Token Mode**: How credential validation works without remote calls, and how revocation is handled.
- **Query-Parameter Routing**: Why cache-key determinism matters more than REST aesthetics in this context.
- **Evidence and Auditability**: What structured logs are emitted at each layer, and how they support post-incident review.

## Read the Full Whitepaper

- [Full English whitepaper](/en/whitepapers/wp01-http-gateway-routing/original/)
- [Chinese version](/zh/whitepapers/wp01-http-gateway-routing/original/)
- [Whitepaper index](/en/whitepapers/)

---
layout: post
title: "A Spec Is Not a Document—It Is a Gate"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Engineering Excellence]
tags: ["Engineering Excellence", "Quality", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP22 guide: Spec-driven development only works when it sits between intent and code, not after the fact."
lang: en
permalink: /en/whitepapers/wp22-spec-driven-development/
source_asset: hotel-be/docs/whitepapers/22-spec-driven-development.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp22-spec-driven-development/original/
---

Most teams claim to write specs. What they actually produce are after-the-fact write-ups—documents that describe what was already built, not what should be built. The result is predictable: ambiguity surfaces in production, regression tests are written to match existing behavior rather than intended behavior, and the "spec" drifts into irrelevance the moment code is merged.

HotelByte treats spec-driven development as a governance gate, not a documentation chore. The gate sits between business intent and implementation, and it has four positions: proposal, specification, implementation, and archive. Nothing passes through without a verifiable scenario, an approved design, and a permanent record. This sounds slow. In practice, it is faster than the rework it prevents.

## The Tool vs. The System

The industry mistake is to install a spec tool and assume governance will follow. A Confluence page, a Jira ticket, or a Gherkin file is just an artifact. What matters is the workflow that surrounds it: who can advance a change, what "complete" means, and what happens when implementation reveals that the spec was wrong.

HotelByte's workflow answers these questions explicitly. A proposal must answer Why, What, and Impact before it earns a number. A specification must include Gherkin-style WHEN/THEN scenarios for every requirement; vague aspirations like "improve performance" are sent back for translation into measurable claims. Implementation cannot deviate from the approved spec without a formal amendment—preventing the common anti-pattern where code becomes the de facto specification. After deployment, the complete record is snapshotted to an immutable archive, creating a tamper-evident trail from business intent to verified behavior.

The boundary conditions matter. Trivial changes—documentation typos, configuration value updates within existing bounds—can follow a lightweight path. But any change that affects externally observable behavior still requires explicit scenario coverage. There is no "spec-free" lane for "small" changes, because small changes are where assumptions leak.

## What HotelByte Gave Up

The trade-off is velocity in the early phase of a project. A team accustomed to starting coding on day one will find the proposal-and-specification layer frustrating. HotelByte accepts this friction because the alternative—discovering a misunderstood requirement after deployment—is more expensive in a platform where a single search request traverses dozens of supplier integrations and a booking state machine error can result in financial loss.

The MECE documentation architecture, with its 7±2 rule at every directory level, also imposes a cognitive tax. Engineers must think about where a spec belongs before they write it. The payoff is that any engineer can locate the authoritative specification for a given capability within three navigational steps, even in a system with thousands of integrations.

## Reading Path

If you read one chapter, read **"Spec-Driven Workflow Architecture"** (Proposal → Specification → Implementation → Archive). It is the clearest description of how the gate operates in practice.

For the governance angle, **"Auditability"** explains the three verification methods—scenario traceability, three-independent-approval review, and immutable archive snapshots—that make the gate inspectable by external reviewers.

For the human cost, **"Design Principles"** lists the rules that reviewers enforce: "every 'should,' 'may,' and 'appropriate' is flagged for clarification." This is where you can judge whether the discipline is real or performative.

## Cross-References

- [Read the full WP22 whitepaper (English)](/en/whitepapers/wp22-spec-driven-development/original/)
- [Read the Chinese version of WP22](/zh/whitepapers/wp22-spec-driven-development/original/)
- [Browse the whitepaper index](/en/whitepapers/)

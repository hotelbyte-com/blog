---

layout: post
title: "白皮书原文：动态定价与业务规则引擎白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp15-pricing-rules/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp15-pricing-rules/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文页。中文导读在 <a href="/zh/whitepapers/wp15-pricing-rules/">读者视角导读</a>；完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。下方发布 canonical whitepaper 全文，避免再跳转到仓库相对目录。
</div>

# 动态定价与业务规则引擎白皮书

> 本页为公开博客版白皮书原文。当前 canonical 全文以英文维护，中文导读负责解释读者视角和业务价值；英文 canonical URL 为 [/en/whitepapers/wp15-pricing-rules/original/](/en/whitepapers/wp15-pricing-rules/original/)。

# Dynamic Pricing & Business Rules Engine Whitepaper

## Executive Summary

HotelByte's Dynamic Pricing & Business Rules Engine is a configurable, multi-tenant policy layer that enables real-time price transformation and request-level business control across the entire hotel distribution pipeline. The engine decouples commercial policy from application code, allowing platform operators, suppliers, and buyers to define, simulate, and enforce pricing rules through a declarative configuration interface rather than software releases.

Built on a three-layer architecture—factors, conditions, and actions—the engine evaluates rules against more than 30 contextual dimensions drawn from five distinct scopes. Rules execute in two phases: pre-request actions govern supplier selection and request shaping, while post-request actions apply dynamic markups or block results before they reach the buyer. Every price change is traced and auditable through a comprehensive markup telemetry stream.

This whitepaper describes the design principles, architectural layers, evaluation lifecycle, and operational controls that make the HotelByte rules engine suitable for high-volume, multi-party hotel distribution at global scale.

## Scope

This document covers:

- The factor registry and its five evaluation scopes
- The condition layer and supported operator semantics
- The action registry, including pre-request and post-request action types
- The rule evaluation lifecycle within search and trade flows
- Dynamic pricing models: percentage, fixed-amount, multiplier, and tiered markups
- Auditability, traceability, and simulation capabilities
- Security boundaries and multi-tenant rule isolation

This document does not cover supplier adapter internals, booking engine transaction semantics, or general platform caching strategy, which are addressed in separate whitepapers.

## Objectives

The rules engine was designed to achieve five objectives:

1. **Policy Agility** — Enable commercial teams to change pricing and availability policies within minutes, without engineering intervention.
2. **Multi-Party Governance** — Support independent rule sets for platform operators, suppliers, and buyers, each with distinct evaluation timing and authority boundaries.
3. **Deterministic Pricing** — Guarantee that identical requests, under identical rule configurations, produce identical price outcomes.
4. **Full Traceability** — Record every price transformation with original value, final value, applied strategy, and responsible rule identity.
5. **Safe Simulation** — Allow rules to be tested against synthetic request profiles before production activation.

## Design Principles

### Configuration Over Code

Business rules are expressed as structured configuration rather than imperative code. This eliminates logic drift between policy definition and execution, reduces time-to-market for new commercial strategies, and enables non-engineering stakeholders to author and review rules through a governed self-service interface.

### Deterministic Evaluation

Rule outcomes depend solely on the factor map derived from the request and the rule configuration itself. The engine contains no hidden state, randomness, or temporal side effects. Identical inputs always yield identical outputs, ensuring price consistency across redundant search calls, caching layers, and downstream reconciliation.

### Audit Every Price Change

Every room rate that passes through the engine carries a `MarkupProcess` trace containing the original price, final price, total markup amount, markup percentage, and a chronological list of applied strategies. This trace is returned in API responses and is available for downstream reporting, dispute resolution, and revenue assurance.

### Defense in Depth for Pricing

Markup parameters are validated at rule creation time, at rule simulation time, and at execution time. Percentage markups are bounded, multiplier ranges are capped, and tier definitions are validated for monotonicity and interval consistency. This layered validation prevents malformed or excessive rules from affecting production prices.

### Scope Isolation

Factors are organized into five scopes—Request, User, Item, Tenant, and Environment—each with explicitly defined data sources and operator support. This scoping prevents rule authors from inadvertently creating cross-tenant or cross-user conditions, and it enables the engine to pre-filter the factor set for each evaluation context.

## Rules Engine Architecture

The engine is structured into three orthogonal layers that separate "what is being evaluated" from "when it should trigger" and "what should happen next."

### Factor Layer

The factor layer defines the vocabulary of rule conditions. Each factor has a strongly typed key, a data type (Date, Number, String, Enum, Boolean), a scope, a list of supported operators, and an optional data source reference.

Factors are drawn from five scopes:

| Scope | Examples | Data Types |
|---|---|---|
| Request | checkInDate, stayLength, nationality, currency | Date, Number, Enum |
| User | userId, customerEntityId, appKey | Number, String |
| Item | hotelId, supplierId, netRate, breakfastIncluded | Number, Enum, Boolean |
| Tenant | tenantId, tenantType | Number, Enum |
| Environment | requestHour, dayOfWeek, isWeekend | Number, Enum, Boolean |

Dynamic factor values are resolved through three data source types: API-backed lookups (e.g., country or city lists), static enumerations (e.g., currency codes or tenant types), and asynchronous search-backed resolution (e.g., hotel metadata). This hybrid approach ensures that rapidly changing reference data is always current, while stable enumerations are cached locally for performance.

The `FactorBuilder` component assembles factor maps from request context, user identity, occupancy details, and inventory items. It uses a pooled object pattern to minimize allocation overhead during high-throughput search evaluation.

### Condition Layer

The condition layer evaluates Boolean expressions over the factor map. Conditions are expressed as composite predicates with an outer logical operator (`AND`/`OR`) and a list of atomic comparisons. Each comparison specifies a left-hand side factor, an operator, and a right-hand side constant or factor reference.

Supported operators include:

| Operator | Semantics | Applicable Types |
|---|---|---|
| Eq / Neq | Equality / inequality | All |
| Gt / Gte | Greater than / greater-or-equal | Number, Date |
| Lt / Lte | Less than / less-or-equal | Number, Date |
| In / NotIn | Membership / exclusion | Enum, String |
| Contains | Substring match | String |

The condition layer applies floating-point boundary precision handling for numeric comparisons involving integer-valued thresholds, ensuring that comparisons such as `netRate > 100` behave correctly when the underlying value is represented as a decimal currency type.

### Action Layer

The action layer defines the consequences of a matched rule. Actions are registered in a global registry and are categorized by execution phase:

**Pre-request actions** (`ActionPhasePreRequest`) execute before supplier calls are dispatched:
- `block_request` — prevents the request from reaching a specific supplier
- `select_supplier` — overrides the supplier routing decision
- `select_credential` — selects an alternative supplier credential
- `override_country_option` — modifies nationality, residency, or country code parameters

**Post-request actions** (`ActionPhasePostRequest`) execute after supplier responses are received:
- `block` — removes an item from the result set
- `markup` — applies a dynamic price transformation

The markup action supports four pricing models:

| Model | Parameter | Description |
|---|---|---|
| Percentage | `percentage` | Adds a percentage of the net rate (range: -99% to +1000%) |
| Fixed Amount | `fixedMarkupAmount` | Adds a flat monetary amount, distributed per room |
| Multiplier | `multiplier` | Multiplies the net rate by a scalar (range: 0× to 10×) |
| Tiered | `tiers` | Applies a multiplier based on price band intervals |

Markup actors apply transformations to net rate, commissionable rate, and final rate, while preserving gross rate ceilings where contractually required. Cancellation fee structures are proportionally adjusted when the underlying room total changes.

## Rule Evaluation Lifecycle

The rules engine is integrated into the HotelByte search pipeline at four distinct touchpoints, forming a complete evaluation lifecycle:

### 1. Request Ingestion & Factor Extraction

When a search request arrives, the `FactorBuilder` extracts contextual dimensions from:
- The HTTP request itself (check-in/out dates, room count, occupancy, nationality, currency)
- The authenticated user (user ID, customer entity, API key)
- The runtime environment (current hour, day of week, weekend flag)
- The tenant context (tenant ID, tenant type)

These dimensions are assembled into a canonical factor map that serves as the input for all downstream rule evaluations.

### 2. Seller-In Rule Evaluation (Pre-Request)

Before dispatching requests to supplier adapters, the engine evaluates **Seller-In Rules** attached to each seller participant. These rules can block requests, override country options (nationality, residency, country code), or redirect the request to an alternative supplier or credential. This phase ensures that supplier-side business constraints—such as market restrictions or credential-specific routing—are enforced before any external call is made.

### 3. Supplier Response & Seller-Out Rule Evaluation (Post-Request)

After supplier responses are received and normalized, **Seller-Out Rules** are evaluated per room. These rules apply supplier-side markup or filtering policies. For each room, the engine builds an item-enriched factor map (including hotel ID, supplier ID, net rate, star rating, breakfast inclusion) and evaluates the seller's outgoing rule set. Matched markup actions transform the room's rate structure, while block actions remove the room from the result stream.

### 4. Buyer-Out Rule Evaluation & Final Price Transformation

Before results are returned to the API client, **Buyer-Out Rules** are evaluated. These rules represent the buyer's final pricing layer—often a commission markup, volume discount, or promotional adjustment. Because buyer-out rules execute after all supplier-side processing, they operate on fully materialized prices and can perform cross-supplier comparisons if needed.

### 5. Trace Population

Throughout post-request evaluation, the engine populates the `MarkupProcess` trace on every rate package:
- `OriginalPrice` is captured before any rule actions execute
- `FinalPrice` is recorded after all actions complete
- `TotalMarkup` and `MarkupPercentage` summarize the net change
- `MarkupStrategies` records each intermediate transformation with type, value, scene label, localized description, and the responsible rule ID

This trace is emitted in API responses and is retained for operational analytics.

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| **Factor Registry with 5 Scopes** | Rules can target any combination of request context, user identity, inventory attributes, tenant classification, and runtime environment, enabling granular commercial policies. |
| **Dynamic Data Source Resolution** | Factor values backed by API, static, or async sources ensure that reference data (countries, cities, hotels, currencies) is always accurate without manual enumeration maintenance. |
| **Two-Phase Action Execution** | Pre-request actions control supplier selection and request shaping; post-request actions control pricing and filtering. This separation prevents wasteful supplier calls and enables precise output control. |
| **Four Markup Models** | Percentage, fixed-amount, multiplier, and tiered pricing models cover the full spectrum of distribution contracts, from simple commissions to complex volume-based rate cards. |
| **Gross Rate Ceiling Preservation** | Markup actors respect contractual gross rate ceilings where applicable, ensuring that recommended selling prices are never exceeded. |
| **Floating-Point Boundary Precision** | Numeric condition evaluation applies precision-safe boundary handling, preventing misclassification due to decimal representation in currency values. |
| **Markup Parameter Validation** | Percentage, multiplier, and tier parameters are bounded and validated at rule creation, simulation, and execution time, preventing accidental or malicious price distortion. |
| **Real-Time Price Preview** | The simulation endpoint computes exact price outcomes before a rule is activated, enabling safe policy testing against synthetic or historical requests. |
| **Multi-Tenant Rule Isolation** | Platform users can manage global rules; non-platform users are restricted to rules within their own entity boundary, enforced at persistence and retrieval layers. |
| **Markup Traceability** | Every rate carries an immutable audit trail of original price, applied strategies, intermediate prices, final price, and responsible rule IDs. |

## Auditability

The rules engine provides multiple independent mechanisms for verifying that pricing policies are applied correctly and consistently.

### Response-Level Tracing

Every `RoomRatePkg` returned by the search API includes a `MarkupProcess` object. This object contains:
- The original supplier net rate (`OriginalPrice`)
- The final buyer-facing net rate (`FinalPrice`)
- The absolute difference (`TotalMarkup`)
- The percentage change (`MarkupPercentage`)
- A detailed list of `MarkupStrategies`, each annotated with the rule ID, scene (e.g., `seller-out-rule`, `buyer-out-rule`), strategy type, and a human-readable description in multiple languages

API consumers and internal operations teams can inspect this trace to reconcile any price discrepancy without accessing internal execution logs.

### Rule Simulation

The `/simulateRule` endpoint allows authorized users to evaluate a rule against arbitrary factor parameters and a base price. The response includes:
- Whether the rule passed or failed
- The list of actions that would have fired
- A `PricePreview` showing the exact adjusted price, price difference, and percentage change

This capability supports pre-deployment validation, regression testing during rule updates, and training scenarios for commercial teams.

### Execution Metrics

The engine emits business-level metrics for rule hit/miss rates per scene (`applySellerOutRuleOnRooms`, `applyBuyerOutRule`, etc.), enabling operational dashboards that track policy effectiveness and supplier participation rates.

### Change Logging

All rule mutations—creation, update, deletion, and toggle—are attributed to the authenticated operator and persisted with full rule content. The normalization layer logs any condition transformations (e.g., precision adjustments) for diagnostic review.

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **OMG Decision Model and Notation (DMN) v1.5** | "A decision is the act of determining an output value from a number of input values, using logic defining how the output is determined from the inputs." | The HotelByte condition layer maps directly to DMN decision logic: factors are inputs, conditions are decision tables, and actions are outputs. The explicit separation of inputs (factors), logic (conditions), and outputs (actions) mirrors DMN's separation of data, decision logic, and knowledge sources. |
| **Business Rules Group, "The Business Rules Manifesto"** | "Rules should be expressed declaratively in natural-language sentences for the business audience… Rules should be managed and controlled outside the code." | HotelByte rules are authored as declarative JSON configurations (conditions and aims) rather than code. The rules engine enforces this separation by compiling configurations into an executable rule graph at runtime, enabling business stakeholders to read and validate policy without engineering involvement. |
| **Gartner, "Market Guide for Business Rules Management Systems"** | "BRMS platforms must support versioning, testing, simulation, and governance of business rules across multiple channels and user groups." | The HotelByte engine implements simulation via `/simulateRule`, governance via entity-scoped access control (platform vs. tenant users), and multi-channel consistency by evaluating the same rule configuration across hotel list, hotel rates, check availability, and streaming search paths. |
| **IEEE Software, "Rule-Based Systems: A Taxonomy"** | "A rule engine should provide traceability of rule firing, explainability of conclusions, and support for forward and backward chaining." | The engine provides traceability through `MarkupProcess` and `MarkupStrategies`. Explainability is supported via simulation responses that show exactly which conditions passed and which actions fired. Forward chaining is implemented through sequential action execution within a matched rule. |
| **ISO 4217 (Currency Codes)** | "ISO 4217 provides standard three-letter alphabetic codes for currencies." | The currency factor in the Request scope uses ISO 4217 standard codes (USD, EUR, CNY, AED, etc.) as static enumerated values, ensuring that currency-based rules are expressed in an internationally recognized vocabulary. |
| **OWASP, "Input Validation Cheat Sheet"** | "All input should be validated against a strict specification… Numeric inputs should have defined minimum and maximum bounds." | The markup validation layer enforces strict bounds: percentage markups are constrained between -99% and +1000%, multipliers between 0× and 10×, fixed amounts must be non-negative, and tier intervals must be well-formed. All parameters are validated at rule persistence time, simulation time, and execution time. |

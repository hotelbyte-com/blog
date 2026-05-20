---

layout: post
title: "白皮书原文：订单生命周期状态机白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp13-order-lifecycle/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp13-order-lifecycle/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文页。中文导读在 <a href="/zh/whitepapers/wp13-order-lifecycle/">读者视角导读</a>；完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。下方发布 canonical whitepaper 全文，避免再跳转到仓库相对目录。
</div>

# 订单生命周期状态机白皮书

> 本页为公开博客版白皮书原文。当前 canonical 全文以英文维护，中文导读负责解释读者视角和业务价值；英文 canonical URL 为 [/en/whitepapers/wp13-order-lifecycle/original/](/en/whitepapers/wp13-order-lifecycle/original/)。

# Order Lifecycle State Machine Whitepaper

**HotelByte Technical Whitepaper | Version 2.0**

---

## Executive Summary

HotelByte processes thousands of hotel booking transactions daily across a global supplier network. Each reservation traverses a complex lifecycle—from initial creation through payment, supplier confirmation, and eventual completion or cancellation—often spanning multiple external systems with independent failure modes. To manage this complexity with financial-grade reliability, HotelByte implements a deterministic order state machine that governs every legal transition, enforces terminal-state immutability, and produces a complete, timestamped audit trail for every order.

This whitepaper describes the architecture, design principles, and operational controls of the HotelByte order lifecycle state machine. It is intended for enterprise customers, integration partners, security auditors, and compliance reviewers who require transparency into how booking states are managed, how refunds are gated, and how the platform converges to known-good outcomes even when upstream suppliers exhibit ambiguous or delayed behavior.

---

## Scope

This document covers the HotelByte order state management layer:

- Internal order state definitions and transition rules (`trade/domain/`)
- State machine mechanics: validation, atomic transition, and history recording
- Customer-facing status projection and alert semantics
- Booking flow state progression (`trade/service/book.go`)
- Cancellation flow state progression, including multi-actor support and refund gating (`trade/service/cancel.go`)
- Background order scanner reconciliation (`trade/service/order_scanner.go`)
- Audit trail structure and verification methods

It does not cover supplier adapter internals, payment processor integrations, or search engine mechanics, which are addressed in separate whitepapers.

---

## Objectives

1. **Deterministic Lifecycle Progression** — Every order follows an explicit, verifiable path through legally defined states; illegal transitions are rejected at the domain layer before any side effects occur.
2. **Terminal-State Immutability** — Once an order reaches Completed, Cancelled, or Failed, no further state mutation is possible, guaranteeing stable financial reconciliation endpoints.
3. **Complete Auditability** — Every transition records From/To states, timestamps, and business reasons, producing an immutable history suitable for financial audit and dispute resolution.
4. **Customer-Transparent Projection** — Internal states are mapped to customer-visible statuses through a controlled projection layer that abstracts supplier-specific ambiguities.
5. **Automated Reconciliation** — Background scanning tasks detect and resolve stuck or divergent orders by synchronizing against supplier-side terminal states without manual intervention.

---

## Design Principles

### Atomic State Transitions

State transitions are atomic, validated, and logged as a single indivisible operation. The state machine validates the target state against a statically defined transition matrix before any mutation occurs. If validation fails, the operation returns a detailed error enumerating the allowed target states from the current state, and no partial update is persisted. This prevents orders from entering ambiguous or inconsistent intermediate conditions.

### Terminal State Immutability

Completed, Cancelled, and Failed are designated terminal states. The state machine rejects any transition attempt originating from a terminal state. This invariant is the foundation of financial reconciliation: once an order is terminal, its associated ledger entries, refund eligibility, and commission calculations are fixed and will not be altered by subsequent background processes or retry logic.

### Audit Every Change

Every state transition produces a `StateTransitionRecord` containing the previous state, the new state, an RFC-3339 timestamp, and a human-readable business reason. These records are persisted to the order's business metadata and emitted as structured logs. The audit trail is append-only and travels with the order through its entire lifecycle, enabling post-hoc analysis of booking failures, cancellation disputes, and SLA investigations.

### Project, Don't Expose

Internal states reflect supplier-specific nuances that would confuse downstream consumers. HotelByte maps internal states to a normalized customer-visible status through a projection layer. Additionally, a `StatusAlert` mechanism handles edge cases—such as a supplier aborting a booking after partial processing—by projecting the internal state to a customer-meaningful outcome (e.g., `Failed` or `Confirmed`) without mutating the underlying state machine record.

### Fail Safe, Converge Eventually

When supplier responses are delayed, ambiguous, or indicate transient errors, the platform does not guess. Instead, it places the order into an explicit intermediate state (e.g., `NeedSupplierConfirm`, `NeedCancel`) and delegates resolution to background scanner tasks with bounded retry limits and timeouts. This ensures that human operators or automated reconcilers always have a clear, actionable target state to evaluate.

---

## State Machine Architecture

### State Definitions

The HotelByte order state machine defines ten discrete internal states organized into three categories:

**Active States** — `Created`, `Paid`, `NeedSupplierConfirm`, `Confirmed`, `NeedCancel`, `NeedRefund`, `CancelFailed`

**Terminal States** — `Completed`, `Cancelled`, `Failed`

Active states permit forward or backward movement according to business events. Terminal states are absorbing: once entered, no exit is permitted.

### Transition Rules

Legal transitions are encoded in a static transition matrix validated at runtime. Key rules include:

- `Created` may transition to `Paid`, `Cancelled`, or `NeedCancel`
- `Paid` may transition to `Confirmed`, `NeedSupplierConfirm`, `NeedRefund`, `NeedCancel`, or `Failed`
- `NeedSupplierConfirm` may transition to `Confirmed`, `NeedRefund`, `NeedCancel`, `Cancelled`, or `Failed`
- `Confirmed` may transition to `NeedCancel`, `NeedRefund`, `Cancelled`, or `Failed`
- `NeedCancel` may transition to `Cancelled`, `NeedRefund`, `CancelFailed`, or `Failed`
- `CancelFailed` may transition back to `NeedCancel`, to `Cancelled`, or to `Failed`
- `NeedRefund` converges to `Cancelled`

This matrix encodes business policy directly into the domain layer. Any transition not explicitly listed is rejected with an error that enumerates the permitted targets.

### State Projection Layer

The `ProjectCustomerOrderStatus` function maps internal states to a normalized external status understood by customer systems. In addition, a `StatusAlert` overlay handles supplier-specific edge cases:

- `BookingAborted` → projects internal state to `Failed`
- `CancellationAborted` → projects internal state to `Confirmed`

Projection occurs after state transitions complete, ensuring that the internal state machine remains the single source of truth while customers receive semantically appropriate status values.

---

## Order Lifecycle

### Booking Flow

The standard booking flow progresses through four major phases:

**1. Order Creation**

The booking request is preprocessed: session context is validated, availability data is parsed, and a `BookCtx` is assembled. An idempotency check keyed by `customerReferenceNo` prevents duplicate reservations. If an unconfirmed order with the same reference already exists, it is returned instead of creating a new record. A final concurrency guard after order insertion detects and cancels any duplicate orders created by race conditions.

**2. Safety and Compliance Checks**

Before financial commitment, the platform enforces a sequence of safety checks: environment mixing detection prevents test traffic from reaching production suppliers; booking prohibition checks respect tenant-level administrative blocks; non-refundable booking interception applies policy-based gates; and subscription quota checks enforce tenant booking entitlement limits.

**3. Payment and Supplier Booking**

After transactional order creation (main order plus sub-orders split by room and night), a credit check verifies wallet balance or credit limit. Upon successful debit, the order state transitions atomically to `Paid`. The platform then dispatches the booking to the supplier. If the supplier reports a failure, Smart Booking resale logic attempts to fulfill the reservation through alternate inventory. When no `HotelConfirmNo` is returned, a background `TaskTypeFetchHCN` scan task is scheduled to poll for the confirmation number.

**4. Confirmation or Failure**

On supplier success, the order transitions to `Confirmed` (or `NeedSupplierConfirm` when asynchronous confirmation is required). On terminal failure, it transitions to `Failed`. Each transition is recorded with the supplier response context as the business reason.

### Cancellation Flow

Cancellation is a multi-actor, state-gated process:

**1. Actor Identification and Order Resolution**

Cancellation requests may originate from the System, API clients, or the Portal. The actor type is determined from request context and recorded in the audit trail. Orders are located through multiple identifier types—`CustomerReferenceNo`, `PlatformReferenceNo`, or `SupplierReferenceNo`—supporting flexible integration patterns.

**2. State Validation and Refund Order Preparation**

The current order state is loaded into a state machine instance. If the order is not already in `NeedCancel` or `Cancelled`, it transitions to `NeedCancel` with an audit reason capturing the actor and justification. A refund order record is initialized (or an existing pending refund order is reused) to track financial reversal.

**3. Supplier Cancellation and Terminal Convergence**

The platform calls the supplier cancel API. On success, the order transitions to `Cancelled`; on definitive supplier rejection, it may transition to `CancelFailed` or `Failed` depending on the response semantics. A critical business rule governs refund eligibility: wallet credit is refunded **only** when the order reaches `Cancelled`. The `CancelFailed` state explicitly does **not** trigger refund, preserving financial integrity when cancellation is incomplete.

**4. Background Reconciliation**

Orders in `NeedCancel` or `CancelFailed` that do not converge promptly are picked up by the order scanner. The scanner queries supplier-side order status directly. If all supplier orders report a terminal state, the local order is synchronized to match without re-invoking the supplier cancel API, resolving stuck cancellations automatically.

---

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| Atomic State Transitions | Every state change is validated against a static rules matrix before persistence; illegal transitions are rejected with no side effects, preventing orders from entering invalid or inconsistent states. |
| Terminal State Immutability | Orders reaching Completed, Cancelled, or Failed are permanently locked; financial reconciliation, commission calculations, and refund eligibility remain stable and auditable. |
| Transition Audit Records | Each state change appends a timestamped record (From/To/Reason) to the order history, producing an immutable chain suitable for dispute resolution and compliance review. |
| Idempotent Booking by Reference | Duplicate `customerReferenceNo` values on unconfirmed orders return the existing record instead of creating a new booking, eliminating accidental double reservations. |
| Concurrency-Guard Deduplication | A post-creation race-condition check detects duplicate orders and cancels the younger instance, ensuring exactly one active booking per customer reference. |
| Multi-Actor Cancellation Audit | System, API, and Portal cancellations are tagged with actor identity and reason, creating a complete accountability trail for every cancellation event. |
| Refund Gating by Terminal State | Wallet credit is refunded only upon reaching `Cancelled`; `CancelFailed` explicitly blocks refund, protecting against partial or failed cancellation financial leakage. |
| Smart Booking Resale | On supplier book failure, the platform automatically attempts alternate inventory fulfillment, increasing booking success rates without customer intervention. |
| Background HCN Fetch Task | When suppliers do not immediately return a hotel confirmation number, a scheduled retry task polls for up to three months post-checkout, ensuring confirmation data is eventually captured. |
| Supplier Terminal State Sync | The order scanner independently queries supplier status and converges local state when the supplier side is terminal, resolving stuck or timeout-affected orders without manual operations. |
| Status Projection Layer | Internal supplier-specific states are mapped to normalized customer-visible statuses with alert overlays, presenting clear semantics while preserving internal state integrity. |
| Safety Check Pipeline | Environment mixing, booking prohibition, non-refundable interception, and quota checks execute before financial commitment, preventing policy violations and administrative errors. |

---

## Auditability

External reviewers and enterprise customers can verify HotelByte order state controls through the following mechanisms:

1. **State Transition Logs** — Every transition emits a structured log record containing order identifier, previous state, new state, timestamp, business reason, and actor information. These logs are retained and available for audit export.

2. **Order History Records** — The `StateTransitionRecord` array stored within each order's business metadata provides an append-only, per-order audit trail that can be retrieved through standard order query APIs.

3. **Callback Events** — Customers subscribing to webhook callbacks receive deterministic events (`OrderCreated`, `OrderPaid`, `OrderCancelled`, `OrderFailed`) that correspond to validated state machine transitions, enabling independent reconciliation against the customer's own ledger.

4. **CQRS Event Publishing** — State transition events are published to an internal event bus with at-least-once delivery semantics, supporting downstream audit pipelines, BI analytics, and anomaly detection.

5. **Background Scanner Metrics** — Order scanner execution produces metrics for task queue depth, retry success rates, timeout resolutions, and supplier-not-found finalizations. Reviewers with metric access can independently verify reconciliation effectiveness.

6. **Integration Tests** — The trade domain includes comprehensive tests covering state transition validation, terminal-state rejection, projection semantics, and cancellation refund gating. Reviewers can execute these tests to reproduce control behavior in a local environment.

---

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **AWS Builder's Library — State Machine Pattern** | "Use a state machine to ensure that an entity can only be in one of a finite number of states and that transitions between states are well-defined and atomic." | The `OrderStateMachine` enforces a finite set of internal states with a statically defined transition matrix; every transition is validated atomically before persistence. |
| **NIST SP 800-53 Rev. 5 AU-3 Content of Audit Records** | "The information system generates audit records containing information that establishes what type of event occurred, when it occurred, where it was directed, and the outcome of the event." | Every state transition appends a `StateTransitionRecord` with From/To states, timestamp, and reason, establishing a complete event history for each order. |
| **ISO 20022 — Transaction State Management** | "A transaction shall have a clearly defined lifecycle with explicit states, and once a transaction reaches a final state it shall not be possible to alter that state." | Terminal states (`Completed`, `Cancelled`, `Failed`) are immutable; the state machine rejects any transition originating from a terminal state. |
| **Martin Fowler — Accounting Patterns (Audit Log)** | "An audit log keeps a chronological record of changes to an object, providing a history that can be inspected to determine what happened and why." | The order business metadata persists an append-only list of state transitions, enabling post-hoc inspection of booking and cancellation history. |
| **OWASP Cheat Sheet — Financial Grade APIs** | "Financial operations must ensure that compensating transactions are only executed when the primary transaction has reached a confirmed terminal state." | Wallet refunds are gated exclusively on the `Cancelled` terminal state; `CancelFailed` does not trigger refund, ensuring compensating transactions align with confirmed outcomes. |
| **Gregor Hohpe — Enterprise Integration Patterns (Idempotent Receiver)** | "An idempotent receiver ensures that duplicate messages do not cause unintended side effects, typically by correlating incoming messages with existing state." | Booking requests keyed by `customerReferenceNo` deduplicate against unconfirmed orders, and a post-creation concurrency guard cancels duplicate race-condition orders. |

---

*For questions or audit requests regarding this whitepaper, contact HotelByte Engineering via your assigned partner channel.*

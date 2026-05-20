---
layout: post
title: "Whitepaper: Financial-Grade Wallet & Credit System Whitepaper"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [Hotel API, Whitepaper, Architecture]
author: "HotelByte Team"
description: "Full HotelByte technical whitepaper published on the blog for readable public access."
lang: en
permalink: /en/whitepapers/wp14-wallet-credit/original/
whitepaper_kind: original
guide_url: /en/whitepapers/wp14-wallet-credit/
---

<div class="whitepaper-reader-note">
  <strong>Reading path:</strong> this is the full whitepaper. For a shorter reader-facing guide, start with <a href="/en/whitepapers/wp14-wallet-credit/">the blog guide</a>. Browse the whitepaper index at <a href="/en/whitepapers/">HotelByte Whitepapers</a>.
</div>

# Financial-Grade Wallet & Credit System Whitepaper

**HotelByte Technical Whitepaper | Version 2.0**

---

## Executive Summary

HotelByte operates a multi-tenant hotel distribution platform where thousands of booking transactions flow between customers, tenants, and suppliers across dozens of currencies every hour. To govern financial exposure at each of these boundaries, HotelByte implements a financial-grade wallet and credit system that enforces strict balance integrity, immutable audit trails, and automatic reconciliation-driven compensation.

This whitepaper describes the architecture, controls, and operational guarantees of the wallet and credit subsystem. It is intended for enterprise customers, security auditors, and integration partners who require transparency into how HotelByte manages credit limits, pre-authorization holds, deductions, refunds, and cross-currency settlements without ever permitting a balance to drift into an inconsistent state.

---

## Scope

This document covers the HotelByte wallet and credit layer only:

- Wallet domain model and triplet addressing (`user/domain/wallet.go`)
- Wallet persistence and atomic balance operations (`user/mysql/wallet_dao.go`)
- Credit lifecycle management: holds, deductions, releases, and refunds (`user/service/credit_management.go`)
- Immutable ledger recording and query semantics
- Order reconciliation and automatic wallet compensation (`trade/service/order_reconciliation.go`)
- Cross-currency conversion and settlement tracking

It does not cover payment processor integrations, charge-back handling, or regulatory tax reporting, which are addressed in separate whitepapers.

---

## Objectives

1. **Financial-Grade Consistency** — Every credit operation is atomic, bounded, and leaves an immutable ledger record. No balance update is ever applied without a corresponding audit entry.
2. **Defense in Depth for Balance Integrity** — Balance mutations are enforced at both the domain layer (invariant checks) and the storage layer (atomic conditional UPDATE), with self-healing clamp semantics for anomalous states.
3. **Transparent Multi-Tenant Isolation** — Each wallet is scoped to a unique `(BuyerEntityID, SellerEntityID, Currency)` triplet, ensuring that credit exposure between any two parties is independently tracked and settled.
4. **Automatic Reconciliation Compensation** — When supplier-reported order states diverge from the platform's internal state, the system automatically determines whether to refund or re-deduct wallet credit, keeping financial exposure aligned with ground truth.
5. **Cross-Currency Transparency** — All currency conversions are recorded with original amount, settlement currency, and applied exchange rate, enabling full traceability for multi-currency accounts.

---

## Design Principles

### Atomic Financial Operations

Every mutation to a wallet's `UsedLimit` or `CreditLimit` is executed inside a transaction that also produces at least one immutable ledger record. There is no code path that updates a wallet balance without a corresponding `CreditLedger` entry. This ensures that the ledger is not a secondary log—it is the authoritative source of financial truth, and the wallet table serves as a denormalized, performance-optimized current-state view.

### Immutable Ledger Records

Ledger entries are append-only. Once created, a `CreditLedger` row is never updated or deleted. The five operation types—`HOLD`, `RELEASE`, `DEBIT`, `CREDIT`, and `LIMIT_CHANGE`—form a complete vocabulary for every financial event. Each entry carries a `RunningBalance` (`CreditLimit - UsedLimit` at the moment of recording), enabling auditors to reconstruct the wallet state at any point in time by replaying entries in sequence.

### Defense in Depth for Balance Integrity

Balance mutations pass through three independent enforcement layers:

1. **Domain-layer invariants** — `CheckBalanceSufficient`, `CalculateNewUsedLimitForDeduction`, and `CalculateNewUsedLimitForRefund` enforce semantic correctness before any storage call.
2. **Atomic conditional UPDATE** — MySQL `UPDATE` statements apply delta changes only when the resulting `UsedLimit` remains within `[0, CreditLimit]`. Unlimited-mode wallets (`CreditLimit == 0`) bypass the upper bound.
3. **Self-healing clamp semantics** — Refund operations apply `GREATEST(0, used_limit + delta)` at the database level, automatically correcting any anomalous negative state that could theoretically arise from extreme edge cases.

### Idempotent Safety

All refund paths are designed to be safely retryable. When a refund request duplicates a previously processed operation, the system detects the no-op condition (zero rows affected from MySQL aligned with the domain expression) and returns success without double-crediting the wallet.

### Unlimited-Mode Credit

HotelByte supports both limited and unlimited credit modes. In unlimited mode (`CreditLimit == 0`), balance sufficiency checks are skipped, enabling trusted enterprise customers to operate without artificial booking caps while still recording every hold and deduction in the ledger for full visibility.

---

## Wallet Architecture

### Triplet Identity Model

Every wallet is uniquely identified by a triplet:

```
(BuyerEntityID, SellerEntityID, Currency)
```

This design explicitly models the two-sided nature of hotel distribution: a buyer (the customer or sub-account) holds credit with a seller (the tenant or supplier). Because a single customer may book in EUR with one tenant and in USD with another, the currency is a first-class dimension of wallet identity, not merely an attribute.

The query strategy implements a deterministic fallback chain:

1. **Exact currency match** — Return the wallet whose `Currency` exactly matches the transaction currency.
2. **`ALL` currency wallet** — If no exact match exists, return the universal-currency wallet (`Currency == "ALL"`), which stores balances normalized to USD minimum units.
3. **Explicit failure** — If neither exists, the operation returns a not-found error rather than silently defaulting to an incorrect wallet.

### Wallet State Model

Each wallet maintains the following core fields:

| Field | Semantics |
|---|---|
| `CreditLimit` | Maximum credit extended. `0` denotes unlimited mode. Negative values are sanitized to `0` available balance. |
| `UsedLimit` | Cumulative amount currently held or deducted. Always non-negative in consistent state. |
| `Status` | Enable/disable gate. Inactive wallets block new holds and deductions. |
| `Currency` | Settlement currency. `ALL` wallets settle in USD minimum units. |

The available balance is always computed as:

```
RunningBalance = CreditLimit - UsedLimit   (for limited wallets)
RunningBalance = MAX_INT64                 (for unlimited wallets)
```

This computed value is never persisted independently; it is derived on read to guarantee that `CreditLimit`, `UsedLimit`, and the ledger remain the single sources of truth.

### Ledger Layer

The `CreditLedger` is an append-only record of every financial event affecting a wallet. Each entry captures:

- `OperationType`: `HOLD`, `RELEASE`, `DEBIT`, `CREDIT`, or `LIMIT_CHANGE`
- `Amount` and `AmountSign`: the magnitude and direction of the change
- `RunningBalance`: the computed available balance at the time of the entry
- `Reference`: an external correlation key (e.g., booking ID)
- `OriginalAmount`, `OriginalCurrency`, `ExchangeRate`: cross-currency audit trail
- `PerformedBy`: user ID for human-initiated actions, nil for system operations

Because the ledger is append-only, it serves as a complete, tamper-evident history. Any discrepancy between the wallet's current state and the sum of ledger entries is detectable and correctable.

### Reconciliation Layer

The reconciliation engine (`trade/service/order_reconciliation.go`) continuously aligns internal order states with supplier-reported snapshots. When a state transition indicates that an order has moved from an active financial state (e.g., paid, confirmed) to an inactive terminal state (e.g., cancelled, failed), the system automatically triggers wallet compensation:

- **Active → Inactive**: The platform refunds held or deducted credit back to the buyer's wallet.
- **Inactive → Active**: The platform re-deducts or re-holds credit to restore the correct financial exposure.

These compensations are themselves recorded as ledger entries, ensuring that reconciliation actions are as auditable as user-initiated transactions.

---

## Credit Lifecycle / Transaction Flow

### 1. Hold (Pre-Authorization)

When a booking is initiated, `HoldCredit` pre-occupies the required amount in the customer's wallet:

- The system resolves the wallet via the triplet query (exact currency → `ALL` fallback).
- For limited wallets, `CheckBalanceSufficient` verifies that `UsedLimit + amount ≤ CreditLimit`.
- Unlimited wallets skip the balance check.
- `UsedLimit` is increased by the hold amount.
- An immutable `HOLD` ledger entry is created, correlated to the booking ID via `Reference`.

Hold records are queryable by booking ID, enabling deterministic release even if the booking spans multiple wallets due to currency conversion.

### 2. Deduction (Settlement)

Upon successful confirmation, the actual deduction moves credit from the customer to the tenant (and subsequently from tenant to supplier). This is modeled as:

- Customer → Tenant: The held amount is consumed, or an additional `DEBIT` is applied if the final supplier amount differs from the original hold.
- Tenant → Supplier: A parallel deduction may occur on the tenant's supplier-facing wallet.

Deductions use the atomic `IncrementUsedLimit` path with a positive delta. The database-level `UPDATE` enforces:

```sql
UPDATE wallet
SET used_limit = GREATEST(0, used_limit) + ?
WHERE id = ?
  AND (credit_limit = 0 OR GREATEST(0, used_limit) + ? <= credit_limit)
```

If the boundary check fails, zero rows are affected and the operation returns an explicit insufficient-balance error. This prevents over-commitment even under concurrent load.

### 3. Release (Cancellation)

When a booking is cancelled, `ReleaseCredit` reverses the hold:

- All `HOLD` and `RELEASE` ledger entries for the booking ID are enumerated.
- The remaining unreleased amount is computed (`totalHeld - alreadyReleased`).
- `UsedLimit` is decreased by the release amount, with domain-level clamping to prevent negative states.
- An immutable `RELEASE` ledger entry is created for each wallet touched.

Release is idempotent: if the full hold has already been released, the operation returns success without mutation.

### 4. Refund (Post-Deduction Reversal)

For orders that were already deducted (not merely held), refund operations decrease `UsedLimit` using a negative delta. The database applies:

```sql
UPDATE wallet
SET used_limit = GREATEST(0, used_limit + ?)
WHERE id = ?
```

The `GREATEST(0, ...)` clamp provides self-healing: if an anomalous state produced a negative `UsedLimit`, the refund operation corrects it to zero rather than compounding the error.

Idempotency is preserved by detecting when the domain-calculated new value equals the current value (zero rows affected from MySQL, but semantically a no-op success).

### 5. Reconciliation Loop

Supplier snapshots may report order state changes that the platform has not yet observed (e.g., a supplier-initiated cancellation). The reconciliation engine evaluates the transition:

```
shouldRefundWalletForReconciliation:  active -> inactive  => refund
shouldRechargeWalletForReconciliation: inactive -> active  => re-deduct/re-hold
```

Compensation amounts are derived from the original order's buyer and seller currency amounts, converted through the same wallet-deduction path used at booking time. This closes the loop: every state change that affects financial exposure produces a corresponding, auditable wallet mutation.

---

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| **Triplet Wallet Identity** | Credit exposure is independently tracked per buyer-seller-currency combination, preventing commingling of funds or accidental cross-tenant over-commitment. |
| **Exact → `ALL` Currency Fallback** | Multi-currency customers can operate with either currency-specific wallets or a single universal (`ALL`) wallet, with deterministic resolution semantics. |
| **Atomic Conditional UPDATE** | Balance mutations are protected by database-level boundary checks; concurrent bookings cannot overdraw a limited wallet. |
| **Self-Healing Refund Clamp** | Refund operations clamp `UsedLimit` to a minimum of zero, automatically recovering from any anomalous state without manual intervention. |
| **Idempotent Release & Refund** | Retry-safe operations ensure that duplicate cancellation or reconciliation events never double-credit a wallet. |
| **Unlimited Credit Mode** | Trusted enterprise accounts can operate without hard booking caps while retaining full ledger visibility. Mode transitions generate explicit `LIMIT_CHANGE` entries. |
| **Immutable Ledger Append-Only** | Every financial event is permanently recorded with `RunningBalance`, enabling point-in-time audit reconstruction and tamper detection. |
| **Cross-Currency Audit Trail** | `OriginalAmount`, `OriginalCurrency`, and `ExchangeRate` are captured on every converted transaction, ensuring full transparency for multi-currency settlements. |
| **Reconciliation-Driven Compensation** | Automatic wallet refund or re-deduction aligns financial exposure with supplier ground truth, closing the loop on state divergence. |
| **Reference-Indexed Hold Tracking** | Holds are correlated to booking IDs, enabling precise partial or full release even when bookings span multiple currencies or wallets. |
| **Two-Level Cache Invalidation** | Wallet reads leverage a two-level cache (local + Redis) with explicit invalidation on every mutation, balancing read performance with strong consistency. |

---

## Auditability

### Ledger Replay

Because the `CreditLedger` is append-only and every entry includes a `RunningBalance`, auditors can reconstruct the wallet state at any historical moment by replaying entries in `CreateTime` order. The sum of signed effective amounts (`Amount × AmountSign`) must equal `CreditLimit - RunningBalance` at every step.

### Reference Tracing

Every `HOLD` and `RELEASE` entry carries a `Reference` field populated with the booking ID. This allows auditors to trace a single booking through its entire financial lifecycle:

1. Initial `HOLD` at booking creation.
2. Potential `DEBIT` at confirmation (if the final amount differs from the hold).
3. `RELEASE` or `REFUND` at cancellation.
4. Reconciliation-compensation entries if supplier state divergence is detected.

### Cross-Currency Verification

For transactions involving currency conversion, the ledger stores the original request amount, the settlement currency amount, and the applied exchange rate. Auditors can independently verify conversion accuracy by dividing `OriginalAmount` by the settlement amount and comparing it to the recorded `ExchangeRate`.

### Operational Query Interface

The `GetCreditLedger` API supports paginated retrieval with time-range and operation-type filters. Customers and administrators can export ledger entries for arbitrary periods, filtered by `HOLD`, `DEBIT`, `CREDIT`, `RELEASE`, or `LIMIT_CHANGE`, enabling both routine reconciliation and forensic investigation.

---

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **Double-Entry Bookkeeping Principles** | "Every financial transaction has equal and opposite effects in at least two different accounts." (Pacioli, *Summa de Arithmetica*, 1494) | Every wallet mutation produces a corresponding `CreditLedger` entry with signed `Amount` and `RunningBalance`, ensuring that the ledger and wallet remain mathematically consistent. |
| **PCI DSS v4.0 Requirement 10** | "Implement audit trails linking all access to system components to each individual user." (PCI Security Standards Council, 2022) | `CreditLedger` records `PerformedBy` (user ID) for human-initiated actions and marks system operations explicitly, creating an immutable, user-attributed audit trail for every credit event. |
| **ISO 27001:2022 Control A.8.11** | "Information shall be protected from unauthorized changes to ensure its integrity." (ISO/IEC 27001:2022) | Wallet mutations use atomic conditional `UPDATE` statements with strict boundary checks, preventing race-condition overdrafts and ensuring balance integrity under concurrent access. |
| **ACID Transaction Semantics** | "A transaction is a single logical unit of work that takes the database from one consistent state to another." (Silberschatz, Korth, & Sudarshan, *Database System Concepts*) | `SetCreditLimit` and reconciliation compensation wrap entity updates, wallet updates, and ledger insertions in database transactions, guaranteeing atomicity and consistency. |
| **Payment Card Industry — Data Integrity Best Practices** | "Systems should employ defense-in-depth strategies including input validation, boundary checks, and self-healing recovery mechanisms." (PCI SSC Guidance) | The `execRefundUsedLimitClamp` applies `GREATEST(0, used_limit + delta)` at the database level, providing a self-healing boundary that clamps anomalous states to zero rather than propagating corruption. |
| **IEEE 830-1998 (Software Requirements Specifications)** | "Traceability ensures that each requirement can be traced forward to design, code, and test cases." (IEEE) | `Reference`-indexed holds and reconciliation-compensation entries enable forward and backward traceability from any booking ID to every wallet mutation and ledger record that affected it. |


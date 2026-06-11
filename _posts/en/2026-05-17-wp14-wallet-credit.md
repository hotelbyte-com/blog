---
layout: post
title: "B2B Wallets Fail When They Treat Currency as Metadata"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Finance]
tags: [Finance, Wallet, "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP14 guide: A B2B wallet should model responsibility across buyer, seller, and currency."
lang: en
permalink: /en/whitepapers/wp14-wallet-credit/
source_asset: hotel-be/docs/whitepapers/14-financial-grade-wallet-and-credit-system.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp14-wallet-credit/original/
---

Most platform wallets start with a simple assumption: one user, one balance. That model works for consumer apps because the buyer and the payer are the same person, and the currency is whatever the user selected at checkout. In B2B hotel distribution, that assumption collapses. A single corporate buyer may hold credit with three different tenants, settle in EUR for one contract and USD for another, and expect the platform to prevent over-commitment across all of them simultaneously. When currency is treated as a metadata field rather than a first-class identity dimension, the result is silent commingling: a EUR hold reduces a USD balance, or a tenant's credit exposure leaks into a supplier's ledger.

HotelByte's wallet system rejects that simplification. It models every wallet as a triplet—`(BuyerEntityID, SellerEntityID, Currency)`—which means credit responsibility is scoped to a specific bilateral relationship in a specific denomination. This is not a normalization trick. It is a semantic guard that prevents the most common class of B2B financial errors: treating a cross-boundary balance as if it were a single account.

## The Industry Blind Spot: Balance as a Scalar

The typical approach to multi-tenant wallets is to add columns. A `user_id`, a `tenant_id`, a `currency_code`. The query becomes `SELECT balance FROM wallets WHERE user_id = ? AND tenant_id = ? AND currency = ?`. This looks correct until concurrency enters the picture. Two bookings in different currencies hit the same row via different index paths, or a reconciliation job refunds into a wallet whose currency has shifted since the original hold. The database may be ACID, but the semantic model is not.

The deeper problem is that currency is often treated as a display concern. The platform stores everything in USD, converts at the edge, and assumes the ledger will sort itself out. In practice, this means auditors cannot reconstruct the original obligation. A supplier reports a cancellation in AED; the platform refunds in USD; the exchange rate moved; the buyer disputes the amount. Without an immutable record of the original amount, settlement currency, and applied rate, the platform has no evidence.

## HotelByte's Trade-Off: Triplets Everywhere

The triplet model is expensive. It multiplies the number of wallet rows by the Cartesian product of buyers, sellers, and currencies. It complicates the query path—exact match first, then `ALL` fallback, then explicit failure. It forces the reconciliation engine to track original and settlement amounts separately for every transaction. The team accepted these costs because the alternative—silent cross-currency over-commitment or unrecoverable audit gaps—is more expensive.

The design also imposes a boundary condition: if no exact-currency wallet exists and no `ALL` universal wallet is configured, the operation fails explicitly rather than defaulting to an incorrect balance. This is a deliberate rejection of the "helpful fallback" pattern common in consumer finance, where the system guesses the nearest match. In B2B distribution, a guess is a liability.

## How the Ledger Guards Semantics

Every mutation to `UsedLimit` or `CreditLimit` is paired with an append-only `CreditLedger` entry. The ledger is not a secondary log; it is the authoritative source of truth, and the wallet table is a denormalized current-state view. Each entry carries a `RunningBalance`, enabling auditors to replay the wallet state at any historical moment. For cross-currency transactions, the ledger stores `OriginalAmount`, `OriginalCurrency`, and `ExchangeRate`, creating a complete audit trail that survives rate fluctuations.

The defense-in-depth strategy operates at three layers: domain-layer invariants check semantic correctness before storage; atomic conditional `UPDATE` statements enforce boundary checks at the database level; and self-healing clamp semantics (`GREATEST(0, used_limit + delta)`) recover from anomalous states without manual intervention. Refund paths are idempotent—duplicate reconciliation events detect the no-op condition and return success without double-crediting.

## What to Read in the Whitepaper

If you are evaluating HotelByte's financial architecture, start with these chapters:

- **Triplet Identity Model** — understand why currency is a first-class dimension and how the fallback chain works.
- **Ledger Layer** — examine the append-only record structure and the `RunningBalance` replay semantics.
- **Credit Lifecycle** — trace the `HOLD` → `DEBIT` → `RELEASE` / `REFUND` flow and the idempotency guarantees.
- **Reconciliation Layer** — see how supplier-reported state transitions trigger automatic wallet compensation.
- **Implemented Control Summary** — review the full list of controls, including unlimited-mode credit and two-level cache invalidation.

The full technical specification is available in the [Financial-Grade Wallet & Credit System whitepaper](/en/whitepapers/wp14-wallet-credit/original/). A Chinese version is also available: [财务级钱包与信用系统白皮书](/zh/whitepapers/wp14-wallet-credit/original/).

For the complete whitepaper index, see [HotelByte Whitepapers](/en/whitepapers/).

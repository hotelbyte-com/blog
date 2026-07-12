---
layout: post
title: "staicli Early Beta: Search Hotels, Book, and Run Your Travel Business from the Terminal"
date: 2026-07-12
lang: en
categories: [HotelByte, Releases, CLI]
tags: ["staicli", "hbcli", "CLI", "Early Beta"]
author: "HotelByte Team"
description: "staicli enters early beta. Install in one line, search global hotels, check live rates, book, manage your team and subscriptions — all from the terminal."
permalink: /en/releases/staicli-early-beta/
---

Using the HotelByte API used to mean reading docs, hand-writing JSON, managing tokens. Now: search hotels, check rates, and book — right from the terminal.

## Install

```bash
curl -fsSL https://github.com/hotelbyte-com/docs/releases/latest/download/install.sh | bash
```

Verify:

```bash
$ hbcli version
hbcli (staicli) 0.0.1
```

Nothing else to install.

Updating and uninstalling are also one line:

```bash
hbcli update                    # Update to latest
# Uninstall:
curl -fsSL https://github.com/hotelbyte-com/docs/releases/latest/download/uninstall.sh | bash
```

## What You Can Do

### Search Hotels

```bash
# Set your API credentials (one-time)
hbcli auth set-credentials --app-key YOUR_KEY --app-secret YOUR_SECRET

# Search hotels
hbcli search hotel-list \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --country-code US --nationality-code US --residency-code US \
  --destination-id "city:123" \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# Check live rates for a specific hotel
hbcli search hotel-rates --hotel-id "900000001" \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# Hotel details (description, facilities, images)
hbcli search hotel-detail --hotel-id "900000001"
```

### Book

```bash
# Book a hotel
hbcli trade book \
  --rate-pkg-id "rate-456" \
  --holder '{"name":"John","email":"john@example.com"}' \
  --guests '[{"firstName":"John","lastName":"Doe","type":"adult"}]'

# Query orders
hbcli trade query-orders --customer-reference-nos "REF001,REF002"

# Cancel
hbcli trade cancel \
  --customer-reference-no "REF001" \
  --supplier-reference-no "SUP001"
```

### Run Your Business

If you're a tenant admin, log in with your portal account to manage everything:

```bash
# Login (one-time)
hbcli auth login --username admin@example.com

# Orders
hbcli orders list --status-list confirmed
hbcli orders detail --order-id "order-123"

# Team management
hbcli team list
hbcli team invite --email newuser@example.com --role-id role-1

# Subscriptions and billing
hbcli account subscriptions get
hbcli account subscriptions catalog
hbcli account subscriptions invoices

# Supplier connections
hbcli account suppliers accessible
```

### For Scripts and AI Agents

Every command supports `--json` for structured output:

```bash
hbcli --json search destinations --country-code US | jq '.[] | .name'
```

Large request bodies can be loaded from files:

```bash
hbcli trade book --guests @guests.json --holder @holder.json --rate-pkg-id "rate-456"
```

## Command Overview

```
hbcli search       Search hotels, rates, destinations, details
hbcli trade        Book, cancel, query orders
hbcli orders       Tenant order management
hbcli team         Team and role management
hbcli account      Entity, subscriptions, suppliers
hbcli auth         Set credentials / login
hbcli update       Update to latest version
```

Auth is automatic — store an API key and it uses the integrator flow. Log in and it uses the admin flow. No manual switching.

## What Doesn't Work Yet

This is early beta. Known issues:

| Issue | Status |
|-------|--------|
| **Windows** | Not supported, on the roadmap |
| **Linux x64 / Intel Mac** | Build scripts ready, not end-to-end tested yet |
| **Some searches slow** | Hotel list aggregation on UAT is occasionally slow, we're optimizing |

## Feedback

Found a bug, missing a feature, or hate a command name? Tell us:

- Open an issue: [hotelbyte-com/docs](https://github.com/hotelbyte-com/docs/issues) (add the `cli` label)
- Email: support@hotelbyte.com

---

**staicli v0.0.1 · Early Beta · 2026-07-12**
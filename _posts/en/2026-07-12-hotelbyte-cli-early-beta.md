---
layout: post
title: "staicli Early Beta: One Command to Put HotelByte in Your Pocket"
date: 2026-07-12
lang: en
categories: [HotelByte, Releases, CLI]
tags: ["staicli", "hbcli", "Bun", "TypeScript", "CLI", "Early Beta"]
author: "HotelByte Team"
description: "staicli (hbcli) enters early beta. A self-contained native binary compiled with Bun, installed via a single curl command with zero runtime dependencies. Flat command tree with auto-detected auth — no profile switching for integrators and admins."
permalink: /en/releases/staicli-early-beta/
---

> We shipped a CLI tool the way Claude Code ships: a single `curl | bash` that downloads a 56MB native binary. No Python, no Node, no Bun runtime required on the target machine — install and go.

## The Problem We're Solving

The HotelByte platform serves two types of users:

- **Integrators**: search hotels, check availability, book — authenticated via API key
- **Admins**: manage orders, team, subscriptions, suppliers — authenticated via portal login

Until now, consuming these APIs meant reading docs, hand-writing HTTP requests, managing tokens — starting from scratch for each scenario. We wanted this to be a single command.

## One-Line Install

```bash
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/install.sh | bash
```

**No Python, Node.js, or Bun runtime required** — the binary embeds the entire Bun runtime.

```bash
$ hbcli version
hbcli (staicli) 0.3.0
  binary: ~/.staicli/versions/0.3.0/hbcli
  home:   ~/.staicli
```

## Flat Command Tree, Auto-Detected Auth

We deliberately avoided grouping commands by internal terminology like "OpenAPI profile" or "Portal BFF." Customers don't care about that — they want to search hotels, book rooms, manage their team.

The command tree is **flat, organized by business domain**:

```
hbcli
├── search      Search hotels, rates, destinations
├── trade       Book, cancel, query orders
├── orders      Tenant order management (list, detail, dashboard)
├── team        Team members and roles
├── account     Entity, subscriptions, suppliers
├── view        Portal navigation and menus
├── auth        Credentials and login
├── version     Show version
└── update      Self-update
```

Auth is **auto-detected**:
- API key stored → ticket flow (integrator)
- Portal login stored → session flow (admin)

No profile switching, no mode toggles — the credential type determines the auth path.

## 30-Second Quick Start

### As an integrator (API key mode)

```bash
# Store your API credentials
hbcli auth set-credentials --app-key YOUR_KEY --app-secret YOUR_SECRET

# Search hotels
hbcli search hotel-list \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --country-code US --nationality-code US --residency-code US \
  --hotel-ids "461850557" \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# Check rates
hbcli search hotel-rates --hotel-id "900000001" \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# Book
hbcli trade book \
  --rate-pkg-id "rate-456" \
  --holder '{"name":"John","email":"john@example.com"}' \
  --guests '[{"firstName":"John","lastName":"Doe","type":"adult"}]'
```

### As an admin (portal mode)

```bash
# Login
hbcli auth login --username admin@example.com

# List orders
hbcli orders list --status-list confirmed

# Manage team
hbcli team list
hbcli team invite --email newuser@example.com --role-id role-1

# Subscriptions
hbcli account subscriptions get
hbcli account subscriptions catalog
```

### Agent-friendly

```bash
hbcli --json search destinations --country-code US | jq '.[] | .name'
hbcli trade book --guests @guests.json --holder @holder.json --rate-pkg-id "rate-456"
```

## Why Bun

We initially built this in Python + Click. But the closed-source distribution requirement changed the equation:

| Dimension | Python + wheel | Bun-compiled binary |
|-----------|----------------|---------------------|
| Distribution artifact | wheel (zip) + venv | **Single native binary** |
| Source visibility | wheel unpacks to readable Python | **Binary is not decompilable** |
| Runtime dependencies | Requires Python 3.9+ | **Zero dependencies** |
| Install size | venv + deps ~30MB | 56MB (includes Bun runtime) |
| Self-update | Rebuild venv or pip upgrade | **Download new binary, swap** |

```bash
bun build --compile --target=bun-darwin-arm64 --outfile=hbcli src/cli.ts
```

One command. TypeScript source embedded into the Bun runtime, compiled into a 56MB native executable. Not decompilable — true closed-source distribution.

## Early Beta: Known Limitations

This is **v0.3.0 early beta**:

| Limitation | Details |
|-----------|---------|
| **Only verified on macOS arm64** | Cross-platform build scripts ready, linux/darwin-x64 untested |
| **UAT search partially slow** | hotelList aggregation times out on UAT; hotelRates verified working |
| **No GitHub Release yet** | `install.sh` works once first Release is published |
| **No Windows support** | Roadmap item |

## Roadmap

- [x] v0.3.0 — Flat command tree, auto-auth, native binary, curl install
- [ ] v0.4.0 — E2E test coverage, verify all 4 platform binaries
- [ ] v0.5.0 — Streaming search support
- [ ] v1.0.0 — GA release

## Feedback

- GitHub Issues: [hotelbyte-com/hotelbyte-cli](https://github.com/hotelbyte-com/hotelbyte-cli/issues)
- Email: support@hotelbyte.com

---

**staicli (hbcli) v0.3.0 · Early Beta · 2026-07-12**
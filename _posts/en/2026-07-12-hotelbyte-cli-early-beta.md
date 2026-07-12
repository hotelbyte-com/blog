---
layout: post
title: "hotelbyte-cli Early Beta: One Command to Put the HotelByte Platform in Your Pocket"
date: 2026-07-12
lang: en
categories: [HotelByte, Releases, CLI]
tags: ["hotelbyte-cli", "Bun", "TypeScript", "CLI", "OpenAPI", "Tenant Portal", "Early Beta"]
author: "HotelByte Team"
description: "HotelByte CLI enters early beta. A self-contained native binary compiled with Bun, installed via a single curl command with zero runtime dependencies. Two profiles (openapi + portal) cover the full hotel search, booking management, and tenant administration workflow."
permalink: /en/releases/hotelbyte-cli-early-beta/
---

> We shipped a CLI tool the way Claude Code ships: a single `curl | bash` that downloads a 56MB native binary. No Python, no Node, no Bun runtime required on the target machine — install and go.

## The Problem We're Solving

The HotelByte platform has two API surfaces serving different audiences:

- **OpenAPI** (for integrators): search hotels, check availability, book, cancel — authenticated via appKey/appSecret.
- **Tenant Portal BFF** (for tenant admins): user management, order management, entity config, subscriptions, suppliers, retail onboarding — authenticated via username/password.

Until now, consuming these APIs meant reading OpenAPI docs, hand-writing HTTP requests, managing JWT tokens — starting from scratch for each scenario. We wanted this to be a single command.

## One-Line Install

```bash
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/install.sh | bash
```

The installer:

1. Detects your OS and CPU architecture (macOS/Linux × arm64/x64)
2. Downloads the matching native binary (56MB) from GitHub Releases
3. Writes it to `~/.hotelbyte-cli/versions/0.2.0/` (Claude Code-style versioned directory)
4. Creates a `~/.local/bin/hotelbyte-cli` symlink

**No Python, Node.js, or Bun runtime required** — the binary embeds the entire Bun runtime.

```bash
$ hotelbyte-cli version
hotelbyte-cli 0.2.0
  binary: ~/.hotelbyte-cli/versions/0.2.0/hotelbyte-cli
  home:   ~/.hotelbyte-cli
```

## Two Profiles, One Binary

```
hotelbyte-cli (single native binary)
├── openapi profile  ← public search + trade API
│   ├── auth      → /api/auth/ticket
│   ├── search    → /api/search/* (checkAvail, hotelList, hotelRates, destinations, ...)
│   └── trade     → /api/trade/* (book, cancel, queryOrders, updateOrder)
│
└── portal profile   ← tenant-portal BFF
    ├── auth          → /api/auth/login
    ├── search        → /api/search/* (same search backend, portal JWT)
    ├── orders        → /api/trade/tenant/* (listOrder, detailOrder, orderHomeFunction, ...)
    ├── users         → /api/user/tenant/* (listUser, inviteUser, listRole, listTeamMembers, ...)
    ├── entity        → /api/user/tenant/*Entity (listEntity, getEntity, updateEntity, distributionConfig, ...)
    ├── customers     → /api/user/tenant/*Customer (activate, inactivate, delete)
    ├── subscriptions → /api/user/tenant/*Subscription (get, catalog, start, changePlan, cancel, invoices, ...)
    ├── suppliers     → /api/user/tenant/connectSupplier, getAccessibleCredentials
    ├── retail        → /api/user/tenant/getRetailOnboardingStatus
    └── view          → /api/view/paasHomepage, retailHomepage
```

Why one binary instead of two? Both profiles share the same backend, JWT auth mechanism, and HTTP client infrastructure. Splitting them just duplicates the foundation for no architectural gain. Routing via `hotelbyte-cli openapi …` and `hotelbyte-cli portal …` keeps it DRY while presenting distinct command surfaces to each audience.

## 30-Second Quick Start

### OpenAPI (Integrator)

```bash
# 1. Set credentials
hotelbyte-cli openapi auth set-credentials --app-key YOUR_KEY --app-secret YOUR_SECRET

# 2. Search destinations
hotelbyte-cli openapi search destinations --country-code US

# 3. Search hotels + rates
hotelbyte-cli openapi search hotel-list \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --country-code US --nationality-code US --residency-code US \
  --destination-id "city:123" \
  --room-occupancies '[{"adults":2}]'

# 4. Book
hotelbyte-cli openapi trade book \
  --rate-pkg-id "rate-456" \
  --holder '{"name":"John","email":"john@example.com"}' \
  --guests '[{"firstName":"John","lastName":"Doe","type":"adult"}]'

# 5. Query orders
hotelbyte-cli openapi trade query-orders --customer-reference-nos "REF001,REF002"
```

### Tenant Portal (Admin)

```bash
# 1. Login
hotelbyte-cli portal auth login --username admin@example.com

# 2. Fetch portal navigation
hotelbyte-cli portal view paas-homepage

# 3. List orders
hotelbyte-cli portal orders list --status-list confirmed

# 4. Manage users
hotelbyte-cli portal users list
hotelbyte-cli portal users invite --email newuser@example.com --role-id role-1

# 5. Subscriptions
hotelbyte-cli portal subscriptions get
hotelbyte-cli portal subscriptions catalog
hotelbyte-cli portal subscriptions invoices
```

### Agent-Friendly

Every command supports `--json` for structured output, ready for scripting pipelines and AI agents:

```bash
hotelbyte-cli --json openapi search destinations --country-code US | jq '.[] | .name'
```

Large request bodies can be loaded from files with the `@file.json` prefix:

```bash
hotelbyte-cli openapi trade book --guests @guests.json --holder @holder.json --rate-pkg-id "rate-456"
```

## Self-Update and Uninstall

```bash
# Check for and install the latest version (same mechanism as Claude Code)
hotelbyte-cli update

# Uninstall
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/uninstall.sh | bash

# Full uninstall (including credentials)
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/uninstall.sh | bash -s -- --purge
```

## Why Bun

We initially built this in Python + Click (following the [CLI-Anything](https://github.com/HKUDS/CLI-Anything) framework's Python convention). But the closed-source distribution requirement changed the equation:

| Dimension | Python + wheel | Bun-compiled binary |
|-----------|----------------|---------------------|
| Distribution artifact | wheel (zip) + venv | **Single native binary** |
| Source visibility | wheel unpacks to readable Python | **Binary is not decompilable** |
| Runtime dependencies | Requires Python 3.9+ | **Zero dependencies** |
| Install size | venv + deps ~30MB | 56MB (includes Bun runtime) |
| Self-update | Rebuild venv or pip upgrade | **Download new binary, swap** |

Claude Code achieves "download one file and run" because Bun compiles JS into a native Mach-O / ELF binary. We chose the same path:

```bash
bun build --compile --target=bun-darwin-arm64 --outfile=hotelbyte-cli src/cli.ts
```

One command. TypeScript source embedded into the Bun runtime, compiled into a 56MB native executable. Not decompilable back to source — true closed-source distribution.

## Tech Stack

- **Language**: TypeScript (strict mode)
- **Runtime/Compiler**: Bun (`bun build --compile` → native Mach-O / ELF)
- **CLI Framework**: Commander.js
- **HTTP**: Native `fetch` (built into Bun runtime)
- **Testing**: `bun test` (23 tests, all passing)
- **CI/CD**: GitHub Actions — tag-triggered, cross-platform build of 4 binaries, uploaded to Release (no source tarball)

## Early Beta: Known Limitations

This is **v0.2.0 early beta**. We want to be explicit about limitations:

| Limitation | Details |
|-----------|---------|
| **Only verified on macOS arm64** | Cross-platform build scripts are ready, but darwin-x64 / linux-arm64 / linux-x64 haven't been end-to-end tested yet |
| **No live API testing** | Unit tests use mocks; E2E tests require UAT credentials |
| **No GitHub Release yet** | `install.sh` will work once the first Release is published |
| **REPL mode is basic** | Interactive REPL is implemented (help/state/undo/exit) but minimal |
| **No Windows support** | macOS and Linux only for now; Windows is on the roadmap |

## Roadmap

- [x] v0.2.0 — OpenAPI + Portal profiles, native binary, curl install
- [ ] v0.3.0 — E2E test coverage, verify all 4 platform binaries
- [ ] v0.4.0 — Streaming search (hotelListStream) support
- [ ] v0.5.0 — Windows binary + PowerShell install script
- [ ] v1.0.0 — GA release, full E2E test matrix, stable API contract

## Feedback

- GitHub Issues: [hotelbyte-com/hotelbyte-cli](https://github.com/hotelbyte-com/hotelbyte-cli/issues)
- Email: support@hotelbyte.com

During early beta, we specifically need:
1. Linux x64/arm64 users to verify `install.sh` works correctly
2. Real UAT environment API call testing feedback
3. Suggestions on command naming and parameter design

---

**hotelbyte-cli v0.2.0 · Early Beta · 2026-07-12**
---
layout: post
title: "hotelbyte-cli 早期公测发布：一行命令，把 HotelByte 平台装进口袋"
date: 2026-07-12
lang: zh
categories: [HotelByte, Releases, CLI]
tags: ["hotelbyte-cli", "Bun", "TypeScript", "CLI", "OpenAPI", "Tenant Portal", "早期公测"]
author: "HotelByte Team"
description: "HotelByte CLI 进入早期公测。基于 Bun 编译的自包含原生二进制，一行 curl 命令安装，零运行时依赖。两个 profile（openapi + portal）覆盖酒店搜索、预订管理、租户管理全流程。"
permalink: /zh/releases/hotelbyte-cli-early-beta/
---

> 我们用 Claude Code 的方式发布了一个 CLI 工具。
> 一行 `curl | bash`，下载一个 56MB 的原生二进制文件，不需要 Python、Node、Bun 或任何运行时——装完即用。

## 我们在解决什么问题

HotelByte 平台的 API 有两个面向不同用户群的入口：

- **OpenAPI**（面向集成商）：搜索酒店、查房态、下订单、取消订单——通过 appKey/appSecret 认证。
- **Tenant Portal BFF**（面向租户管理员）：用户管理、订单管理、实体管理、订阅、供应商、零售入驻——通过用户名/密码认证。

过去，接入这些 API 意味着读 OpenAPI 文档、手写 HTTP 请求、管理 JWT token——每换一个场景就要从头开始。我们想让这件事变成一行命令。

## 一行安装

```bash
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/install.sh | bash
```

安装脚本会：

1. 检测你的操作系统和 CPU 架构（macOS/Linux × arm64/x64）
2. 从 GitHub Releases 下载匹配的原生二进制（56MB）
3. 写入 `~/.hotelbyte-cli/versions/0.2.0/`（类 Claude Code 的版本目录结构）
4. 创建 `~/.local/bin/hotelbyte-cli` symlink

**不需要安装 Python、Node.js 或 Bun**——二进制文件内嵌了完整的 Bun 运行时。

```bash
$ hotelbyte-cli version
hotelbyte-cli 0.2.0
  binary: ~/.hotelbyte-cli/versions/0.2.0/hotelbyte-cli
  home:   ~/.hotelbyte-cli
```

## 两个 Profile，一个 Binary

```
hotelbyte-cli (单个原生二进制)
├── openapi profile  ← 公开搜索 + 交易 API
│   ├── auth      → /api/auth/ticket
│   ├── search    → /api/search/* (checkAvail, hotelList, hotelRates, destinations, ...)
│   └── trade     → /api/trade/* (book, cancel, queryOrders, updateOrder)
│
└── portal profile   ← 租户门户 BFF
    ├── auth          → /api/auth/login
    ├── search        → /api/search/* (同一搜索后端，portal JWT)
    ├── orders        → /api/trade/tenant/* (listOrder, detailOrder, orderHomeFunction, ...)
    ├── users         → /api/user/tenant/* (listUser, inviteUser, listRole, listTeamMembers, ...)
    ├── entity        → /api/user/tenant/*Entity (listEntity, getEntity, updateEntity, distributionConfig, ...)
    ├── customers     → /api/user/tenant/*Customer (activate, inactivate, delete)
    ├── subscriptions → /api/user/tenant/*Subscription (get, catalog, start, changePlan, cancel, invoices, ...)
    ├── suppliers     → /api/user/tenant/connectSupplier, getAccessibleCredentials
    ├── retail        → /api/user/tenant/getRetailOnboardingStatus
    └── view          → /api/view/paasHomepage, retailHomepage
```

为什么是一个 binary 而不是两个？两个 profile 共享同一个后端、同一套 JWT 认证机制、同一个 HTTP client。分开做只是重复基础设施，没有架构收益。用 `hotelbyte-cli openapi …` 和 `hotelbyte-cli portal …` 路由，既保持 DRY 又让不同用户群看到各自的命令面。

## 30 秒上手

### OpenAPI（集成商场景）

```bash
# 1. 设置凭据
hotelbyte-cli openapi auth set-credentials --app-key YOUR_KEY --app-secret YOUR_SECRET

# 2. 搜索目的地
hotelbyte-cli openapi search destinations --country-code US

# 3. 搜索酒店 + 房价
hotelbyte-cli openapi search hotel-list \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --country-code US --nationality-code US --residency-code US \
  --destination-id "city:123" \
  --room-occupancies '[{"adults":2}]'

# 4. 下单
hotelbyte-cli openapi trade book \
  --rate-pkg-id "rate-456" \
  --holder '{"name":"John","email":"john@example.com"}' \
  --guests '[{"firstName":"John","lastName":"Doe","type":"adult"}]'

# 5. 查订单
hotelbyte-cli openapi trade query-orders --customer-reference-nos "REF001,REF002"
```

### Tenant Portal（租户管理员场景）

```bash
# 1. 登录
hotelbyte-cli portal auth login --username admin@example.com

# 2. 获取门户导航
hotelbyte-cli portal view paas-homepage

# 3. 列出订单
hotelbyte-cli portal orders list --status-list confirmed

# 4. 管理用户
hotelbyte-cli portal users list
hotelbyte-cli portal users invite --email newuser@example.com --role-id role-1

# 5. 查看订阅
hotelbyte-cli portal subscriptions get
hotelbyte-cli portal subscriptions catalog
hotelbyte-cli portal subscriptions invoices
```

### Agent 友好

每个命令都支持 `--json`，输出结构化 JSON，方便脚本管道和 AI agent 消费：

```bash
hotelbyte-cli --json openapi search destinations --country-code US | jq '.[] | .name'
```

大体积请求体可以用 `@file.json` 前缀从文件读取：

```bash
hotelbyte-cli openapi trade book --guests @guests.json --holder @holder.json --rate-pkg-id "rate-456"
```

## 自更新与卸载

```bash
# 检查并安装最新版本（和 Claude Code 一样的自更新机制）
hotelbyte-cli update

# 卸载
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/uninstall.sh | bash

# 彻底卸载（包括凭据）
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/uninstall.sh | bash -s -- --purge
```

## 技术选型：为什么是 Bun

我们最初用 Python + Click 实现（基于 [CLI-Anything](https://github.com/HKUDS/CLI-Anything) 框架的 Python 约定）。但闭源分发的需求改变了等式：

| 维度 | Python + wheel | Bun 编译二进制 |
|------|---------------|----------------|
| 分发产物 | wheel (zip) + venv | **单个原生二进制** |
| 闭源程度 | wheel 解包即见源码 | **二进制不可读** |
| 运行时依赖 | 需要 Python 3.9+ | **零依赖** |
| 安装体量 | venv + 依赖 ~30MB | 56MB（含 Bun runtime） |
| 自更新 | 重建 venv 或 pip upgrade | **下载新二进制替换** |

Claude Code 之所以能"下载一个文件就能跑"，是因为 Bun 把 JS 编译成了原生 Mach-O / ELF 二进制。我们选择了同样的路径：

```bash
bun build --compile --target=bun-darwin-arm64 --outfile=hotelbyte-cli src/cli.ts
```

一行命令，TypeScript 源码嵌入 Bun runtime，编译成 56MB 的原生可执行文件。不支持反编译回源码——真正的闭源分发。

## 技术栈

- **语言**：TypeScript（严格模式）
- **运行时/编译器**：Bun（`bun build --compile` → 原生 Mach-O / ELF）
- **CLI 框架**：Commander.js
- **HTTP**：原生 `fetch`（Bun runtime 内置）
- **测试**：`bun test`（23 个测试，全部通过）
- **CI/CD**：GitHub Actions — tag 触发，跨平台构建 4 个二进制，上传到 Release（不含源码 tarball）

## 早期公测：已知限制

这是 **v0.2.0 早期公测版**。我们明确以下限制：

| 限制 | 说明 |
|------|------|
| **仅验证 macOS arm64** | 跨平台构建脚本已就绪，但 darwin-x64 / linux-arm64 / linux-x64 尚未端到端验证 |
| **未测试真实 API 调用** | 单元测试使用 mock，E2E 测试需要 UAT 环境凭据 |
| **GitHub Release 尚未发布** | `install.sh` 在第一个 Release 发布后才能实际工作 |
| **REPL 模式基础** | 交互式 REPL 已实现，但功能较简（help/state/undo/exit） |
| **无 Windows 支持** | 当前仅支持 macOS 和 Linux，Windows 支持在路线图中 |

## 路线图

- [x] v0.2.0 — OpenAPI + Portal 两 profile，原生二进制，curl 安装
- [ ] v0.3.0 — 补充 E2E 测试，验证全部 4 个平台二进制
- [ ] v0.4.0 — streaming search（hotelListStream）支持
- [ ] v0.5.0 — Windows 二进制 + PowerShell 安装脚本
- [ ] v1.0.0 — 正式发布，完整 E2E 测试矩阵，稳定 API 约定

## 反馈

- GitHub Issues：[hotelbyte-com/hotelbyte-cli](https://github.com/hotelbyte-com/hotelbyte-cli/issues)
- 邮件：support@hotelbyte.com

我们在这个早期公测阶段特别需要：
1. Linux x64/arm64 用户验证 `install.sh` 能否正常工作
2. 真实 UAT 环境的 API 调用测试反馈
3. 对命令命名/参数设计的建议

---

**hotelbyte-cli v0.2.0 · 早期公测 · 2026-07-12**
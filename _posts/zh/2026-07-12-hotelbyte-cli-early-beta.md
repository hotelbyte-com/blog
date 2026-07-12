---
layout: post
title: "staicli 早期公测：一行命令，把 HotelByte 装进口袋"
date: 2026-07-12
lang: zh
categories: [HotelByte, Releases, CLI]
tags: ["staicli", "hbcli", "Bun", "TypeScript", "CLI", "早期公测"]
author: "HotelByte Team"
description: "staicli (hbcli) 进入早期公测。基于 Bun 编译的自包含原生二进制，一行 curl 命令安装，零运行时依赖。扁平化命令树，认证自动检测——集成商和管理员无需切换模式。"
permalink: /zh/releases/staicli-early-beta/
---

> 我们用 Claude Code 的方式发布了一个 CLI 工具。
> 一行 `curl | bash`，下载一个 56MB 的原生二进制文件，不需要 Python、Node、Bun 或任何运行时——装完即用。

## 我们在解决什么问题

HotelByte 平台的 API 面向两类用户：

- **集成商**：搜索酒店、查房态、下订单——通过 appKey/appSecret 认证
- **管理员**：管理订单、团队、订阅、供应商——通过用户名/密码登录

过去，接入这些 API 意味着读文档、手写 HTTP 请求、管理 token——每换一个场景就要从头开始。我们想让这件事变成一行命令。

## 一行安装

```bash
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/install.sh | bash
```

**不需要安装 Python、Node.js 或 Bun**——二进制文件内嵌了完整的 Bun 运行时。

```bash
$ hbcli version
hbcli (staicli) 0.3.0
  binary: ~/.staicli/versions/0.3.0/hbcli
  home:   ~/.staicli
```

## 扁平化命令树，认证自动检测

我们没有做 `hbcli openapi ...` 和 `hbcli portal ...` 这种按技术术语分组的设计。客户不在乎什么叫 "OpenAPI profile" 或 "Portal BFF"——他们只想搜酒店、下订单、管团队。

所以命令树是**按业务域平铺**的：

```
hbcli
├── search      搜酒店、查房价、查目的地
├── trade       下单、取消、查订单
├── orders      租户订单管理（列表、详情、仪表盘）
├── team        团队成员和角色管理
├── account     实体、订阅、供应商
├── view        门户导航和菜单
├── auth        认证设置
├── version     查看版本
└── update      自更新
```

认证是**自动检测**的：
- 存了 API key → 走 ticket 流程（集成商）
- 存了门户登录 → 走 session 流程（管理员）

用户不需要切换 "profile" 或 "mode"——凭据类型决定了认证方式。

## 30 秒上手

### 集成商

```bash
# 存 API 凭据
hbcli auth set-credentials --app-key YOUR_KEY --app-secret YOUR_SECRET

# 搜酒店
hbcli search hotel-list \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --country-code US --nationality-code US --residency-code US \
  --hotel-ids "461850557" \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# 查房价
hbcli search hotel-rates --hotel-id "900000001" \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# 下单
hbcli trade book \
  --rate-pkg-id "rate-456" \
  --holder '{"name":"John","email":"john@example.com"}' \
  --guests '[{"firstName":"John","lastName":"Doe","type":"adult"}]'
```

### 管理员

```bash
# 登录
hbcli auth login --username admin@example.com

# 查订单
hbcli orders list --status-list confirmed

# 管理团队
hbcli team list
hbcli team invite --email newuser@example.com --role-id role-1

# 查订阅
hbcli account subscriptions get
hbcli account subscriptions catalog
```

### Agent 友好

```bash
hbcli --json search destinations --country-code US | jq '.[] | .name'
hbcli trade book --guests @guests.json --holder @holder.json --rate-pkg-id "rate-456"
```

## 自更新与卸载

```bash
# 自更新（和 Claude Code 一样的机制）
hbcli update

# 卸载
curl -fsSL https://github.com/hotelbyte-com/hotelbyte-cli/releases/latest/download/uninstall.sh | bash
```

## 技术选型：为什么是 Bun

我们最初用 Python + Click 实现。但闭源分发的需求改变了等式：

| 维度 | Python + wheel | Bun 编译二进制 |
|------|---------------|----------------|
| 分发产物 | wheel (zip) + venv | **单个原生二进制** |
| 闭源程度 | wheel 解包即见源码 | **二进制不可读** |
| 运行时依赖 | 需要 Python 3.9+ | **零依赖** |
| 安装体量 | venv + 依赖 ~30MB | 56MB（含 Bun runtime） |
| 自更新 | 重建 venv 或 pip upgrade | **下载新二进制替换** |

```bash
bun build --compile --target=bun-darwin-arm64 --outfile=hbcli src/cli.ts
```

一行命令，TypeScript 源码嵌入 Bun runtime，编译成 56MB 的原生可执行文件。不支持反编译回源码——真正的闭源分发。

## 早期公测：已知限制

这是 **v0.3.0 早期公测版**：

| 限制 | 说明 |
|------|------|
| **仅验证 macOS arm64** | 跨平台构建脚本已就绪，linux/darwin-x64 尚未端到端验证 |
| **UAT 搜索部分超时** | hotelList 聚合搜索在 UAT 上较慢，hotelRates 已验证正常 |
| **GitHub Release 尚未发布** | `install.sh` 在第一个 Release 发布后才能实际工作 |
| **无 Windows 支持** | 路线图中 |

## 路线图

- [x] v0.3.0 — 扁平化命令树，自动认证，原生二进制，curl 安装
- [ ] v0.4.0 — 补充 E2E 测试，验证全部 4 个平台二进制
- [ ] v0.5.0 — streaming search 支持
- [ ] v1.0.0 — 正式发布

## 反馈

- GitHub Issues：[hotelbyte-com/hotelbyte-cli](https://github.com/hotelbyte-com/hotelbyte-cli/issues)
- 邮件：support@hotelbyte.com

---

**staicli (hbcli) v0.3.0 · 早期公测 · 2026-07-12**
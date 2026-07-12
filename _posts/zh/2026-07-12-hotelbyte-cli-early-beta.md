---
layout: post
title: "staicli 早期公测：在终端里搜索全球酒店、下单、管业务"
date: 2026-07-12
lang: zh
categories: [HotelByte, Releases, CLI]
tags: ["staicli", "hbcli", "CLI", "早期公测"]
author: "HotelByte Team"
description: "staicli 进入早期公测。一行命令安装，在终端里搜索全球酒店、查看实时房价、下单预订、管理团队和订阅。"
permalink: /zh/releases/staicli-early-beta/
---

过去用 HotelByte 的 API，你得读文档、拼 JSON、管 token。现在，终端里直接搜酒店、查房价、下单。

## 获取

staicli 目前处于早期公测阶段，正在准备第一个公开发布的安装包。在此期间，如果你的账户经理已经给你发了安装包，直接按说明装即可。

装完验证一下：

```bash
$ hbcli version
hbcli (staicli) 0.3.0
```

不需要装别的任何东西。

更新到最新版：

```bash
hbcli update
```

## 能干什么

### 搜酒店

```bash
# 设置 API 凭据（一次性）
hbcli auth set-credentials --app-key YOUR_KEY --app-secret YOUR_SECRET

# 搜酒店
hbcli search hotel-list \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --country-code US --nationality-code US --residency-code US \
  --destination-id "city:123" \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# 查某个酒店的实时房价
hbcli search hotel-rates --hotel-id "900000001" \
  --check-in 2026-08-01 --check-out 2026-08-03 \
  --room-occupancies '[{"adultCount":2,"childrenAges":[]}]'

# 查酒店详情（描述、设施、图片）
hbcli search hotel-detail --hotel-id "900000001"
```

### 下单

```bash
# 预订
hbcli trade book \
  --rate-pkg-id "rate-456" \
  --holder '{"name":"John","email":"john@example.com"}' \
  --guests '[{"firstName":"John","lastName":"Doe","type":"adult"}]'

# 查订单
hbcli trade query-orders --customer-reference-nos "REF001,REF002"

# 取消
hbcli trade cancel \
  --customer-reference-no "REF001" \
  --supplier-reference-no "SUP001"
```

### 管业务

如果你是租户管理员，用门户账号登录后可以管理整个业务：

```bash
# 登录（一次性）
hbcli auth login --username admin@example.com

# 查订单
hbcli orders list --status-list confirmed
hbcli orders detail --order-id "order-123"

# 管理团队
hbcli team list
hbcli team invite --email newuser@example.com --role-id role-1

# 查订阅和账单
hbcli account subscriptions get
hbcli account subscriptions catalog
hbcli account subscriptions invoices

# 查供应商连接
hbcli account suppliers accessible
```

### 给程序和 AI agent 用

每个命令都支持 `--json`，输出结构化数据：

```bash
hbcli --json search destinations --country-code US | jq '.[] | .name'
```

大的请求体可以读文件：

```bash
hbcli trade book --guests @guests.json --holder @holder.json --rate-pkg-id "rate-456"
```

## 命令一览

```
hbcli search       搜酒店、查房价、查目的地、查详情
hbcli trade        下单、取消、查订单
hbcli orders       租户订单管理
hbcli team         团队和角色管理
hbcli account      实体、订阅、供应商
hbcli auth         设置凭据 / 登录
hbcli update       更新到最新版
```

认证是自动的——存了 API key 就走集成商通道，存了门户登录就走管理员通道。不需要手动切换。

## 还有什么不能用

这是早期公测版，以下问题我们已知：

| 问题 | 状态 |
|------|------|
| **公开安装包** | 正在准备中，目前通过账户经理获取 |
| **Windows** | 不支持，路线图中 |
| **Linux x64 / Intel Mac** | 构建脚本已就绪，还没端到端验证 |
| **部分搜索超时** | UAT 环境的酒店列表搜索偶尔较慢，我们正在优化 |

## 反馈

发现了 bug、缺了功能、或者命令名起得不好？直接说：

- 提 Issue：[hotelbyte-com/docs](https://github.com/hotelbyte-com/docs/issues)（加 `cli` 标签）
- 邮件：support@hotelbyte.com

---

**staicli v0.3.0 · 早期公测 · 2026-07-12**
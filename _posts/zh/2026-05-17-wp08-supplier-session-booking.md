---
layout: post
title: "白皮书导读：供应商会话与有状态预订"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [供应商集成, 技术白皮书, HotelByte]
author: "HotelByte Team"
description: "HotelByte 供应商会话与有状态预订导读：有状态预订的核心不是把更多内容塞进 session，而是明确哪一层拥有状态、哪些 key 可以写、如何按凭证隔离、以及如何在每个阶段留下可复查快照。"
lang: zh
permalink: /zh/whitepapers/wp08-supplier-session-booking/
source_asset: hotel-be/docs/whitepapers/zh/08-supplier-session-and-stateful-booking.md
whitepaper_kind: guide
original_url: /zh/whitepapers/wp08-supplier-session-booking/original/
---
# 白皮书导读：供应商会话与有状态预订

**TL;DR：** 有状态预订的核心不是把更多内容塞进 session，而是明确哪一层拥有状态、哪些 key 可以写、如何按凭证隔离、以及如何在每个阶段留下可复查快照。

酒店预订不是一次无状态请求。搜索、报价、验价和下单之间需要携带供应商 token、rate key、入住人、房型、价格和取消政策等状态。任何一步丢失、串租户或被供应商实现随意改写，都可能造成下单失败、价格错配或数据泄露。

## 谁应该读

预订链路负责人、供应商集成工程师、安全审核方、企业架构师 应该优先阅读这篇白皮书。它不是功能介绍，而是帮助技术评审者理解 HotelByte 如何把 供应商集成 能力放进可验证的工程控制面。

## 阅读重点

- 看执行摘要，确认问题背景和中心判断。
- 看架构机制，理解系统如何把复杂度拆成可治理的控制点。
- 看验证路径，判断能力是否能被测试、回放、日志或审计证据证明。

## 完整白皮书

- [中文白皮书原文](/zh/whitepapers/wp08-supplier-session-booking/original/)
- [English whitepaper](/en/whitepapers/wp08-supplier-session-booking/original/)

Twitter/X 角度：有状态预订的安全边界，藏在 session key 的所有权里。

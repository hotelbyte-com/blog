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
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp13-order-lifecycle/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 订单生命周期状态机白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何建模订单创建、确认、待供应商确认、取消、退款和异常扫描，保证交易状态可追踪、可恢复、可归因。

## 公开证据锚点

- order scanner
- booking/cancel/query order proxy
- supplier and platform reference mapping

## Twitter 宣发角度

主张：酒店订单状态机需要区分供应商确认、平台状态和客户可见状态。


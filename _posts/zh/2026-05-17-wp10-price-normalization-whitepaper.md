---
layout: post
title: "白皮书原文：多供应商价格标准化白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp10-price-normalization/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp10-price-normalization/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp10-price-normalization/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 多供应商价格标准化白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何处理供应商价格、币种、税费、房型、ratePkgId 和报价口径，避免把单房价、总价、卖家金额和买家金额混用。

## 公开证据锚点

- price normalization pipeline
- taxes and fees handling
- rate and totalRate boundary

## Twitter 宣发角度

主张：价格标准化的关键是金额语义和币种来源一致，不能靠 fallback 拼出看似完整的总价。


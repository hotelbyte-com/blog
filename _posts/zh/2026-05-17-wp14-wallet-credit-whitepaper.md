---
layout: post
title: "白皮书原文：金融级钱包与授信系统白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp14-wallet-credit/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp14-wallet-credit/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp14-wallet-credit/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 金融级钱包与授信系统白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何处理客户钱包、授信、扣减、冻结、退款和财务展示边界，避免金额、币种、供应商成本和客户金额互相兜底。

## 公开证据锚点

- wallet debit and refund path
- buyer/seller/supplier amount separation
- currency-safe financial display

## Twitter 宣发角度

主张：酒店分销的资金系统必须 fail closed，不能展示不完整或来源不一致的财务金额。


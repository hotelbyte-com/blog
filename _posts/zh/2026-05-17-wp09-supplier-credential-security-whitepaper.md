---
layout: post
title: "白皮书原文：供应商凭证安全白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp09-supplier-credential-security/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp09-supplier-credential-security/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp09-supplier-credential-security/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 供应商凭证安全白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何管理供应商 API 和 portal 凭证，包括遮蔽、最小暴露、日志脱敏、平台权限和供应商特定凭证结构。

## 公开证据锚点

- `user/domain/credential_security.go`
- supplier credential schema
- portal credential separation

## Twitter 宣发角度

主张：供应商凭证安全必须覆盖 API、portal、日志和前端展示，不只是数据库字段加密。


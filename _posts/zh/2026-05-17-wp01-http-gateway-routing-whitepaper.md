---
layout: post
title: "白皮书原文：HTTP 网关与进程内 API 路由白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp01-http-gateway-routing/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp01-http-gateway-routing/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp01-http-gateway-routing/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# HTTP 网关与进程内 API 路由白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何把 API 网关能力内嵌到 Go 服务进程中，通过 `common/httpdispatcher/` 统一处理认证、授权、限流、缓存、字段过滤和可观测性。面向企业架构师、安全审核方和集成伙伴，重点强调可审计入口控制、低延迟路径和一致的 API 合约。

## 公开证据锚点

- `common/httpdispatcher/`
- JWT 与 Short Token Mode
- RBAC、OpenAPI whitelist、rate limit、response cache

## Twitter 宣发角度

主张：HotelByte 的入口层不是黑盒代理，而是可审计、可测试、可内嵌的进程内网关。


---
layout: post
title: "白皮书原文：零停机运行时与部署白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp25-zero-downtime/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp25-zero-downtime/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp25-zero-downtime/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 零停机运行时与部署白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何处理服务启动、worker/master 进程、健康检查、配置、部署和回滚，降低发布对交易流量的影响。

## 公开证据锚点

- master/worker runtime
- readiness and health checks
- deployment config and rollback path

## Twitter 宣发角度

主张：酒店交易平台的发布机制必须保护正在进行的搜索和订单链路。


---
layout: post
title: "白皮书原文：数据库与存储韧性层白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp04-database-storage-resilience/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp04-database-storage-resilience/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是白皮书原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp04-database-storage-resilience/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 数据库与存储韧性层白皮书

**HotelByte 技术白皮书 | Version 2.0 | 中文同级公开安全版**

英文 canonical 版本已发布在英文白皮书系列中，可从站内白皮书入口继续阅读。

## 摘要

本文说明 HotelByte 如何围绕订单、钱包、映射、日志和运营数据建立持久化边界，包括事务语义、读写隔离、索引策略和故障恢复路径。

## 公开证据锚点

- MySQL DAO 边界
- Redis / TDengine 使用边界
- schema 与迁移源文件

## Twitter 宣发角度

主张：酒店交易系统的存储层必须区分订单事实、运营指标和缓存候选数据，不能互相兜底。


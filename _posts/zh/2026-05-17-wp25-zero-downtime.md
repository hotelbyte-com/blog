---

layout: post
title: "白皮书导读：零停机运行时与部署"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [部署, 运行时, SRE]
author: "HotelByte Team"
description: "HotelByte 运行时与部署安全模型导读。"
lang: zh
permalink: /zh/whitepapers/wp25-zero-downtime/
source_asset: hotel-be/docs/whitepapers/25-zero-downtime-runtime-and-deployment.md
---

酒店分销发布需要在服务重启、配置变化和 worker 轮换时，保护正在进行的搜索和预订流量。

这份白皮书解释 HotelByte 的运行时与部署模型，包括 master/worker 行为、readiness、health check 和支持回滚的运营方式。

如果你的 SRE 或企业审核需要证明发布机制考虑了在线交易，这份资产值得阅读。

源资产：`hotel-be/docs/whitepapers/25-zero-downtime-runtime-and-deployment.md`

Twitter/X 角度：部署安全也是预订产品的一部分。

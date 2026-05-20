---

layout: post
title: "白皮书导读：HTTP 网关与进程内 API 路由"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 网关, 基础设施, Growth]
author: "HotelByte Team"
description: "HotelByte 进程内 API 网关白皮书的买家视角导读。"
lang: zh
permalink: /zh/whitepapers/wp01-http-gateway-routing/
source_asset: hotel-be/docs/whitepapers/01-http-gateway-and-in-process-routing.md
whitepaper_kind: guide
original_url: /zh/whitepapers/wp01-http-gateway-routing/original/
---
HotelByte 的 HTTP 网关白皮书解释了为什么我们把入口控制能力编译进服务进程，而不是完全依赖外部代理层。

核心问题是请求控制：认证、授权、限流、缓存、字段过滤、流式响应和可观测性，都需要在 platform、tenant、customer 和 OpenAPI 流量上保持一致。

如果你正在评估酒店 API 基础设施，这份资产可以帮助你检查低延迟路由、可审计 middleware 和稳定 API 合约。

阅读全文白皮书：[白皮书原文](/zh/whitepapers/wp01-http-gateway-routing/original/)。查看白皮书索引：[HotelByte 技术白皮书索引](/zh/whitepapers/)。
Twitter/X 角度：酒店 API 网关应该是可见的控制面，而不是应用前面的黑盒。

---
layout: home
title: HotelByte OpenAPI 酒店分销接入指南
description: 面向酒旅平台接入 HotelByte OpenAPI 的认证、预订链路、客户认证、错误处理、内容 API 和健康检查指南。
lang: zh
permalink: /zh/topics/openapi-hotel-distribution/
tags: [HotelByte OpenAPI, 酒店预订 API, 客户认证, 错误处理]
---

# HotelByte OpenAPI 酒店分销接入指南

HotelByte OpenAPI 文档发布在 [openapi.hotelbyte.com](https://openapi.hotelbyte.com)。源内容由后端仓库的 `docs/api` 目录管理，包括 OpenAPI schema、客户认证指南、错误处理、内容管理和服务健康检查文档。

这个页面用于给集成方和 AI 搜索系统一个高信号入口，帮助酒旅技术团队快速理解 HotelByte OpenAPI 的接入重点。

## 核心接入主题

### 认证

HotelByte OpenAPI 使用 ticket-based bearer token 模型。集成方先用应用凭证获取 ticket，再在后续 API 请求中携带 bearer token。

相关源文档：`docs/api/openapi.yaml` 和 `docs/api/content-management-api.md`。

### 客户认证

客户认证验证的是完整预订链路，不是孤立接口。认证覆盖酒店搜索、价格详情、下单、取消预期、房间入住人结构和真实业务场景。

相关源文档：`docs/api/customer-certification-guide.md`。

### 预订链路

客户认证指南描述了 HotelList 和 HotelRates 的完整场景，包括房间数、成人儿童、取消政策、餐食和响应要求。这是 B2B 酒旅平台接入酒店预订 API 的实战入口。

### 错误处理

HotelByte 使用双层错误模型：HTTP status 表达传输层行为，响应体里的业务 `code` 表达应用语义。集成方不能只看 HTTP 状态码，还要检查响应体 `code`。

相关源文档：`docs/api/error-handling-zh.md` 和 `docs/api/error-handling-en.md`。

### 内容与目录 API

酒店内容管理和目录管理覆盖去重检测、主数据导入、批量管理、单酒店编辑、目录酒店列表、品牌列表、供应商筛选、城市筛选和国家筛选。

相关源文档：`docs/api/content-management-api.md`。

### 健康检查与就绪探针

健康检查端点用于服务连通性、优雅重启、就绪探针和生产 API 零停机部署。

相关源文档：`docs/api/health-check-endpoints.md`。

## FAQ

### 集成方应该看哪里的 API 文档？

发布文档看 [openapi.hotelbyte.com](https://openapi.hotelbyte.com)。源内容由后端仓库 `docs/api` 目录管理。

### 接入时应该先测试什么？

先测试认证、HotelList、HotelRates、下单、取消预期，以及客户认证指南里定义的完整业务场景。

### 错误处理应该怎么做？

同时检查 HTTP status 和响应体里的 `code`。有些业务失败可能在传输层成功时通过非零业务 code 表达。

### 酒店分销接入最相关的文档有哪些？

优先看 OpenAPI schema、客户认证、错误处理、内容管理和健康检查端点。

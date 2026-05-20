---
layout: post
title: "英文 canonical 原文：实时搜索与分布式交易引擎白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp03-async-structured-concurrency/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp03-async-structured-concurrency/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是英文 canonical 原文。想先快速判断和业务有什么关系，可以先读 <a href="/zh/whitepapers/wp03-async-structured-concurrency/">读者视角导读</a>。完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。
</div>

# 英文 canonical 原文：实时搜索与分布式交易引擎白皮书

**HotelByte Platform Technical Whitepaper — Search & Trade Engine**

---

## 1. 概述（Executive Summary）

HotelByte 是一个面向全球酒店分销场景的 API 平台，核心能力覆盖实时搜索聚合（Real-time Search Aggregation）与完整订单生命周期管理（Order Lifecycle Management）。本白皮书聚焦平台两大技术资产——**实时搜索引擎**与**分布式交易引擎**——阐述其架构设计、核心创新及工程实践。

在搜索侧，平台通过 SSE（Server-Sent Events）流式协议实现亚秒级首字节时间（TTFB < 200ms），支持多供应商并发 Fanout 与增量结果推送，将传统轮询模式下的"等待-刷新"体验升级为"渐进式呈现"。在交易侧，平台构建了金融级订单状态机（Financial-grade Order State Machine）与三元组信用钱包体系（BuyerEntityID × SellerEntityID × Currency），确保高并发场景下的状态一致性、资金安全性与跨币种结算准确性。

本白皮书面向企业技术决策者与架构师，旨在展示 HotelByte 在实时性、可靠性及可扩展性方面的技术资产价值。

---

## 2. 业务场景与挑战

### 2.1 实时搜索延迟挑战

酒店分销场景具有典型的"长尾供应商"特征：一次搜索请求可能触发数十家供应商的并发调用，而各供应商的响应时间（Response Time）差异极大——头部供应商可在 100ms 内返回，尾部供应商可能需要 3-5 秒。传统轮询模式下，用户必须等待最慢供应商返回后才能看到完整结果，首屏时间（FCP）往往超过 3 秒，导致极高的搜索放弃率。

此外，酒店价格具有强时效性：同一房型在不同供应商处的净价（Net Price）可能在数秒内发生变化。搜索系统必须在聚合过程中实时处理价格波动，并向用户呈现当前可预订的最优价格。

### 2.2 订单一致性挑战

酒店订单生命周期跨越多个异构系统：买方（Buyer）、平台（Platform）、供应商（Seller）。一个预订请求可能涉及：
- 信用额度预占（Credit Hold）
- 供应商库存确认（Supplier Confirmation）
- 多币种汇率转换（Cross-currency Exchange）
- 异步确认号获取（HotelConfirmNo / HCN）
- 取消与退款（Cancellation & Refund）

在分布式环境下，任何节点的故障或超时都可能导致状态不一致：已扣款但未确认、已取消但未退款、重复预订等。这对状态机设计的原子性（Atomicity）与可观测性（Observability）提出了极高要求。

### 2.3 多币种与信用管理挑战

平台支持全球多币种交易。买方与供应商可能使用不同币种结算，汇率波动直接影响利润核算。同时，企业级买家通常采用信用额度（Credit Limit）而非预充值模式，系统需要精确追踪每笔交易的额度占用（Used Limit）、释放（Release）与扣减（Debit），并保证账本级的一致性。

---

## 3. 架构设计

### 3.1 搜索聚合引擎

搜索聚合引擎采用**分层并发架构**：

```
Search Request
    ├── Fanout Layer: errgroup.WithContext() 并发调用所有 Sellers
    │       └── Per-Seller: 按 Credential 二次并发
    ├── Aggregation Layer: supplierHotelId → masterHotelId 映射合并
    │       ├── integrateRoomMapping (自动映射)
    │       └── integrateManualRoomMapping (人工映射)
    ├── Deduplication Layer: detectRedundantRatePackages
    ├── Pricing Layer: Seller Out Rule / Buyer Out Rule 动态加价
    └── Sorting & Limiting: sortRoomRatePackagesByPrice + limitRoomRatesPerHotel
```

**结果合并策略**：搜索返回的房型（Room）首先通过供应商酒店 ID 映射至主酒店 ID，再按房型代码（Room Type Code）合并。系统支持自动映射与人工映射双轨机制，确保新供应商接入时映射准确率可快速达到生产标准。合并后的 Rate Packages 经过冗余检测（Redundant Detection）与价格排序，最终按配置的每酒店上限（Limit per Hotel）截断返回。

**缓存体系**：平台采用双维度缓存策略。酒店最低价按 `buyerKey × sellerKey` 缓存，加速重复查询；Session 快照在 30 秒内可作为回退（Fallback）数据源，保障供应商瞬时不可达时的搜索可用性。

### 3.2 SSE 流式搜索（HotelListStream）

为突破传统轮询的延迟瓶颈，平台设计了基于 SSE 的流式搜索协议：

```
Event Sequence: initial → update × N → complete
```

- **initial**：首包立即返回，携带已就绪的缓存数据与搜索上下文，确保 TTFB < 200ms
- **update**：每批次（按 `SupplierConfig.BatchSize` 切分酒店 ID 列表）供应商返回后，推送增量更新
- **complete**：所有供应商响应完成或超时后，发送终止事件

前端维护 `HotelStateMap` 状态机，基于 `update` 事件实时合并价格：对新到达的价格执行 `Min(Existing, New)` 比较，确保用户始终看到当前最优价。FCP（First Contentful Paint 等效指标）目标控制在 500ms 以内。

可观测性方面，`StreamHotelListResp` 内部维护结构化 `LogBuilder`，对每个 event 的生成时间、批次大小、合并结果进行结构化记录，支持全链路追踪。

### 3.3 规则引擎（Rule Engine）

规则引擎基于 **FactorBuilder** 构建规则因子，覆盖用户身份（User）、入住人数（Occupancies）、入住离店日期（CheckInOut）及客户实体（CustomerEntityId）等维度。规则分为两类：

- **Seller Out Rule**：供应商侧加价（Markup）或拦截（Block），用于渠道成本管控
- **Buyer Out Rule**：买家侧加价或拦截，用于客户级定价策略

Action 处理器支持两种行为：
- `block`：拦截匹配规则的结果，不返回给买家
- `markup`：动态定价，支持百分比（Percentage）与固定金额（Fixed Amount）两种模式

每一次 Markup 操作均通过 `Trace.MarkupProcess` 记录原始价（Original Price）、最终价（Final Price）、总加价（Total Markup）及加价百分比（Markup Percentage），实现定价全链路可追溯。

### 3.4 订单状态机

平台采用**显式状态机（Explicit State Machine）**替代简单的状态字段，定义完整的状态空间与转换规则：

```
Created → Paid → NeedSupplierConfirm → Confirmed
                ↓
        Cancelled / Failed（终态）
```

核心设计：
- **TransitionToWithReason()**：原子状态转换，每次转换记录 `StateTransitionRecord`（From / To / Timestamp / Reason）
- **ValidateTransition()**：非法转换返回详细错误，杜绝脏状态
- **IsTerminalState()**：`Completed` / `Cancelled` / `Failed` 为终态，终态订单拒绝任何后续转换
- **StatusAlert 机制**：`BookingAborted` 自动投影为 `Failed`，`CancellationAborted` 自动投影为 `Confirmed`，确保外部视图与内部状态一致
- **ProjectCustomerOrderStatus()**：将内部细粒度状态投影为客户可见状态，隔离内部复杂度

### 3.5 分布式交易流程

**幂等性设计**：预订入口以 `customerReferenceNo` 进行查重。若存在未确认状态的历史订单，直接复用旧订单并返回，从根本上杜绝重复预订。

**安全检查链**：预订前依次执行环境混淆检查、禁止预订检查、不可取消拦截检查及订阅额度检查，确保不符合业务规则的请求在最早阶段被拒绝。

**事务创建**：采用主订单 + 子订单的拆分模型。子订单按"房间 × 晚数"拆分，每晚上的下浮金额均摊至子订单层级。事务失败时自动回滚，保证订单数据的完整性。

**信用检查**：通过 `checkCredit` 检查钱包余额与信用额度，确保资金充足后才向供应商下单。

**供应商下单与 Smart Booking**：调用 `callSupplierBookAPI()` 向供应商下单。若供应商下单失败，系统触发 **Smart Booking** 机制，自动将订单转售至备用供应商，降低单供应商依赖风险。

**HCN 任务**：对于无 `HotelConfirmNo` 的订单，创建 `TaskTypeFetchHCN` 扫描任务，异步轮询获取供应商确认号，确保订单最终可达 Confirmed 状态。

**并发安全**：幂等性最后防线通过保留最大的 `PlatformReferenceNo`、取消其余冲突订单实现，确保极端并发场景下的数据一致性。

### 3.6 取消、对账与 Wallet 信用系统

**取消身份识别**：支持 `System` / `API` / `Portal` 三种 `CancelActor`，满足不同渠道的取消审计需求。

**多 ID 查询**：取消接口支持 `CustomerReferenceNo` / `PlatformReferenceNo` / `SupplierReferenceNo` 任意一种 ID 定位订单，提升操作灵活性。

**退款单管理**：通过 `selectLatestPendingCancelRefundOrder` 与 `initRefundOrder` 管理退款单生命周期，确保每笔取消对应唯一的退款记录。

**供应商取消与钱包退款**：仅在订单进入 `Cancelled` 状态后执行钱包退款；`CancelFailed` 状态不触发退款，防止资金误退。

**Order Scanner**：后台任务覆盖 `TaskTypeFetchHCN`（确认号获取）、`TaskTypeCancelRetry`（取消重试）、`TaskTypeBatchCancel`（批量取消），保障异步流程的最终一致性。

**对账机制**：通过 `reconcileOrderFromSupplierSnapshot` 与供应商快照对账，差异部分由钱包自动补偿（`recharge` / `refund`），实现资金闭环。

**Wallet 模型**：钱包以 `(BuyerEntityID, SellerEntityID, Currency)` 三元组为唯一键，天然隔离不同买家、供应商与币种的资金池。

**核心操作**：
- `SetCreditLimit`：设置信用额度，支持 `Limited` / `Unlimited` 两种模式
- `HoldCredit`：预订时预占额度
- `ReleaseCredit`：取消或失败时释放额度
- `AddCreditTransaction`：扣减（Debit）或充值（Credit）

**账本模型**：每笔操作记录为 `OperationTypeHold` / `Release` / `Debit` / `Credit` / `LimitChange`，维护 `RunningBalance = CreditLimit - UsedLimit`。MySQL 原子 UPDATE 确保并发安全，`IncrementUsedLimit` 执行严格边界检查，`execRefundUsedLimitClamp` 对负数 delta 执行 Clamp 到 0，杜绝超额释放。

**跨币种交易**：记录 `OriginalAmount` / `OriginalCurrency` / `ExchangeRate`，支持多币种审计与利润核算。

**查询策略**：优先精确匹配币种；无精确匹配时 Fallback 至 `ALL` 币种钱包，兼顾灵活性与准确性。

---

## 4. 技术亮点

### 4.1 SSE 流式搜索：从"等待"到"渐进呈现"

传统酒店搜索采用轮询或阻塞式 API，用户需要等待所有供应商返回后才能看到结果。HotelByte 的 SSE 流式搜索将 TTFB 压缩至 **200ms 以内**，FCP 控制在 **500ms 以内**，相比传统轮询模式提升一个数量级。增量更新机制让用户在首包后即可开始浏览，后续价格持续优化，实现"越搜越准"的体验。

### 4.2 金融级订单状态机

区别于简单的状态字段（Status Field），HotelByte 采用显式状态机管理订单全生命周期。每一次状态转换都是原子操作，附带原因记录与合法性校验。终态判定、状态投影、异常自动修复（StatusAlert）三层机制确保：
- 用户看到的订单状态始终准确
- 非法转换在代码层面不可达
- 内部异常不会外泄为脏状态

这一设计使订单系统具备金融级系统的严谨性，满足企业客户对交易可靠性的高要求。

### 4.3 三元组信用钱包：精细化资金管控

传统余额扣减模型难以应对多供应商、多币种的复杂场景。HotelByte 的 Wallet 以 `(Buyer, Seller, Currency)` 三元组为维度，实现资金池的物理隔离。预占-释放-扣减的三阶段模型配合原子化 MySQL 更新与边界 Clamp，确保：
- 高并发预订场景下额度不超卖
- 取消场景下额度精确回退
- 跨币种交易具备完整审计追踪

### 4.4 Smart Booking：供应商容错与自动转售

单供应商依赖是酒店分销的核心风险。HotelByte 的 Smart Booking 机制在供应商下单失败时，自动将订单转售至备用供应商，无需人工干预。这一能力显著提升了预订成功率，降低了因单一供应商故障导致的业务损失。

### 4.5 全链路定价可追溯

从供应商原始价到买家最终价，每一次加价（Markup）与拦截（Block）均通过 `Trace.MarkupProcess` 记录原始价、最终价、加价金额与加价百分比。全链路可追溯的定价体系不仅满足审计合规要求，也为客户提供了透明的成本结构。

---

## 5. 工程实践

### 5.1 一致性保障

- **数据库层**：订单创建、子订单拆分、钱包额度更新均在一个事务边界内完成，失败自动回滚
- **状态机层**：`ValidateTransition()` 在编译期与运行期双重保障状态转换合法性
- **并发层**：`PlatformReferenceNo` 最大保留策略作为幂等性最后防线，确保重复提交的极端并发场景下数据不冲突
- **对账层**：供应商快照对账 + 钱包自动补偿，实现资金最终一致性

### 5.2 可靠性保障

- **超时与降级**：供应商调用设置分级超时，超时时使用 Session 快照或缓存数据降级
- **异步任务**：HCN 获取、取消重试、批量取消均以后台扫描任务（Order Scanner）执行，确保异步流程不遗漏
- **结构化日志**：SSE 流式搜索的每个 event、状态机的每次转换、钱包的每笔操作均有结构化日志记录，支持 TraceID 维度的全链路追踪
- **可观测性**：LogBuilder 内置于核心响应对象，无需外部侵入即可收集关键指标

### 5.3 可扩展性保障

- **供应商接入**：自动映射 + 人工映射双轨机制降低新供应商接入成本
- **规则配置**：FactorBuilder 支持多维度规则因子，客户级定价策略可动态调整
- **币种扩展**：Wallet 三元组模型天然支持新币种接入，仅需配置汇率与资金池

---

## 6. 价值总结

HotelByte 的实时搜索与分布式交易引擎，通过 SSE 流式协议、显式状态机、三元组信用钱包与 Smart Booking 等核心创新，为企业客户提供了以下差异化价值：

| 维度 | 传统方案 | HotelByte |
|---|---|---|
| 搜索首屏时间 | 3-5 秒轮询等待 | **< 500ms 渐进呈现** |
| 订单状态管理 | 简单状态字段，易脏数据 | **金融级状态机，原子转换** |
| 资金管理 | 单余额扣减，无审计追踪 | **三元组信用钱包，全链路账本** |
| 供应商容错 | 单供应商依赖，失败即丢单 | **Smart Booking 自动转售** |
| 定价透明度 | 黑盒加价，无法审计 | **MarkupTrace 全链路可追溯** |

在金融级一致性的核心要求下，平台将实时性、可靠性与可扩展性统一于同一架构，支持企业客户在全球酒店分销场景下的高并发、高可用、高透明交易需求。

---

*本白皮书由 HotelByte 技术团队撰写，内容反映当前生产环境的技术能力。如需进一步了解 API 接入与集成细节，请联系 HotelByte 技术支持团队。*


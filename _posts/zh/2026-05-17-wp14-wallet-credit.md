---
layout: post
title: "B2B 钱包的基本问题不是余额"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Finance]
tags: ["财务", "钱包", "白皮书导读", "HotelByte"]
author: "HotelByte Team"
description: "WP14 导读：B2B 钱包应该把买方、卖方和货币作为责任的三重维度来建模。"
lang: zh
permalink: /zh/whitepapers/wp14-wallet-credit/
source_asset: hotel-be/docs/whitepapers/zh/14-financial-grade-wallet-and-credit-system.md
whitepaper_kind: guide
original_url: /zh/whitepapers/wp14-wallet-credit/original/
---

大多数平台钱包的设计起点是一个简单假设：一个用户对应一个余额。这个模型在 C 端应用里跑得通，因为付款人和使用人是同一个人，货币也只是结账时选中的币种。但在 B2B 酒店分销场景里，这个假设会全面崩塌。同一个企业买家可能和三家不同的租户签有信用协议，一份合同用 EUR 结算，另一份用 USD，平台必须同时保证所有通道都不超支。当货币被当作附属字段而不是身份的第一维度时，结果就是静默的资金混同：EUR 的预授权扣掉了 USD 的余额，或者租户的信用敞口渗入了供应商的账本。

HotelByte 的钱包系统拒绝这种简化。它将每个钱包建模为三元组——`(BuyerEntityID, SellerEntityID, Currency)`——这意味着信用责任被限定在特定的双边关系和特定币种之内。这不是数据库范式化的技巧，而是一个语义守卫，用来阻止 B2B 金融系统中最常见的一类错误：把跨边界的余额当成单一账户来管理。

## 行业盲区：余额是一个标量

多租户钱包的典型做法是加列。`user_id`、`tenant_id`、`currency_code`，查询写成 `SELECT balance FROM wallets WHERE user_id = ? AND tenant_id = ? AND currency = ?`。看起来没问题，直到并发场景出现。两笔不同币种的预订通过不同索引路径命中同一行，或者对账任务向一个币种已经变更的钱包发起退款。数据库也许是 ACID 的，但语义模型不是。

更深层的问题在于，货币常常被当作展示层的问题。平台把所有金额统一存成 USD，在边缘做换算，然后假设账本自己会理清。实际上，这意味着审计人员无法还原原始债务。供应商用 AED 报告一笔取消，平台用 USD 退款，汇率变了，买家对金额提出异议。如果没有原始金额、结算币种和适用汇率的不可变记录，平台就没有证据。

## HotelByte 的取舍：三元组无处不在

三元组模型是有代价的。它把钱包行数乘以买家、卖家和币种的笛卡尔积。它让查询路径更复杂——先精确匹配，再 `ALL` 回退，最后显式失败。它迫使对账引擎对每笔交易分别追踪原始金额和结算金额。团队接受这些成本，因为另一种选择——静默的跨币种超额承诺或无法恢复的审计缺口——代价更高。

这个设计还施加了一个边界条件：如果没有精确币种钱包，也没有配置 `ALL` 通用钱包，操作会显式失败，而不是默认 fallback 到一个错误的余额。这是对 C 端金融常见模式的有意拒绝——那种"智能猜测最近匹配"的做法。在 B2B 分销里，猜测就是负债。

## 账本如何守护语义

每次对 `UsedLimit` 或 `CreditLimit` 的变更都伴随一条追加-only 的 `CreditLedger` 记录。账本不是辅助日志，它是权威的事实来源，而钱包表只是一个反规范化的当前状态视图。每条记录携带 `RunningBalance`，使审计人员可以按时间顺序回放任意历史时刻的钱包状态。对于跨币种交易，账本存储 `OriginalAmount`、`OriginalCurrency` 和 `ExchangeRate`，形成完整的审计轨迹，不受汇率波动影响。

纵深防御策略分三层：领域层不变式在落库前检查语义正确性；原子条件 `UPDATE` 在数据库层强制执行边界检查；自愈钳位语义（`GREATEST(0, used_limit + delta)`）在异常状态下自动恢复，无需人工干预。退款路径是幂等的——重复的对账事件会检测到无操作条件并返回成功，不会重复入账。

## 白皮书重点阅读路径

如果你在评估 HotelByte 的金融架构，建议从以下章节入手：

- **三元组身份模型** —— 理解为什么货币是第一维度，以及回退链如何工作。
- **账本层** —— 查看追加-only 记录结构和 `RunningBalance` 回放语义。
- **信用生命周期** —— 追踪 `HOLD` → `DEBIT` → `RELEASE` / `REFUND` 流程及其幂等性保证。
- **对账层** —— 了解供应商报告的状态变更如何触发自动钱包补偿。
- **已实现控制摘要** —— 审阅完整控制列表，包括无限制信用模式和两级缓存失效。

完整技术规范见 [Financial-Grade Wallet & Credit System 白皮书](/en/whitepapers/wp14-wallet-credit/original/)。中文版：[财务级钱包与信用系统白皮书](/zh/whitepapers/wp14-wallet-credit/original/)。

全部白皮书索引见 [HotelByte Whitepapers](/en/whitepapers/)。

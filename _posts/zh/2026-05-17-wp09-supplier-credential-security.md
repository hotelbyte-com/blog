---
layout: post
title: "凭证安全不能靠提醒，要靠平台默认路径"
date: 2026-05-17
categories: [HotelByte, Whitepapers, 安全]
tags: ["安全", "供应商集成", "白皮书导读", "HotelByte"]
author: "HotelByte Team"
description: "WP09 导读：凭证安全必须是平台默认路径——字段识别、脱敏、环境隔离和审计轨迹由代码强制执行，而不是靠 review 提醒。"
lang: zh
permalink: /zh/whitepapers/wp09-supplier-credential-security/
source_asset: hotel-be/docs/whitepapers/zh/09-supplier-credential-security.md
whitepaper_kind: guide
original_url: /zh/whitepapers/wp09-supplier-credential-security/original/
---

最常见的凭证安全做法是一份 checklist：不要硬编码 secret、日志里要脱敏、定期轮换、在 code review 时提醒开发者。问题在于 checklist 的扩展性很差。面对 27 家以上供应商，每家都有自己的认证方案——密码、API key、token、license key、安全证书——人为失误的暴露面增长速度远超任何 review 流程能覆盖的范围。一个新供应商适配器里漏掉一条脱敏规则、一行日志不小心打印了 bearer token、一张客服截图里带出了测试凭证，都可能动摇整个信任模型。

HotelByte 把凭证安全当成平台路径，而不是文化规范。系统不要求工程师"记得"脱敏，而是把脱敏作为所有可能暴露凭证的表面的默认行为：管理 API、后台界面、审计记录、日志查询、session 视图、支持导出工作流。查看凭证时，敏感字段默认显示为掩码占位符；编辑凭证时，掩码占位符的含义是"保留现有 secret"，从而防止最常见的失败模式：管理员只改了某个非敏感字段，却不小心用掩码字符串覆盖了真实凭证。

这种默认脱敏的理念由 schema 驱动，而不是靠约定。HotelByte 使用各供应商的凭证 schema 来描述认证结构，并按语义识别敏感字段——password、secret、apiKey、token、licenseKey、securityKey、authorization。这些 schema 驱动管理界面的输入类型、标记脱敏字段、为每家新供应商接入提供一致的安全基线。没有显式声明哪些字段敏感的供应商，无法完成接入。安全是 onboarding 契约的一部分，不是事后补丁。

管理平面和运行时被当作两个独立的安全边界。运行时执行路径需要完整凭证来向供应商 API 认证；管理展示、日志查询、审计和实体配置流程只需要标识信息或掩码信息。完整凭证被限制在真正需要它们的供应商执行路径中，不会扩散到管理界面、实体配置或支持工具里。这种分离在减少不必要暴露的同时，保证了业务连续性。

审计轨迹的设计目标是可追溯，但不能变成 secret 仓库。凭证审计记录保留操作人、目标对象、动作类型、时间戳和上下文信息，但审计 payload 使用掩码副本或安全元数据。同样的原则适用于日志查询结果、session 视图和支持排查输出：敏感信息在展示前被清理。目标不是让 secret 对所有人都不可见，而是确保没有任何表面意外变成明文 secret 的存储库。

基于引用的配置进一步降低了暴露面。在不需要完整 secret 的场景下，HotelByte 存储凭证引用信息，而不是复制完整的凭证内容。这让凭证所有权边界保持清晰，减少了系统内部 floating 的 secret 副本数量。当业务实体需要关联到某条凭证时，它持有的是引用，不是 secret 本身。

五层安全架构——输入与 schema 控制、管理表面默认脱敏、运行时隔离、审计与可观测性安全、基于引用的配置——构成了纵深防御。没有任何一层被单独依赖。某一层的 bug 会被另一层捕获；开发者忘记标记字段敏感，会被 schema 要求拦住；日志格式化器漏掉一条脱敏规则，会被平台级默认脱敏兜底。

如果你正在评估这套系统，白皮书中最值得细读的章节是：

- **安全目标** —— 理解六个明确目标如何塑造每一项控制决策，从最小权限到业务连续性。
- **设计原则** —— 理解最小暴露、管理/运行时分离和可追溯性背后的 reasoning。
- **分层安全架构** —— 掌握五层控制模型，以及 schema 驱动的字段识别如何创建一致基线。
- **凭证生命周期保护** —— 了解创建、查看、更新、使用、删除各阶段的控制如何防止意外暴露。
- **治理控制摘要** —— 从安全编辑语义到日志查询脱敏，理解系统如何保持可验证性。

完整中文白皮书请见 [WP09 — 供应商凭证安全](/zh/whitepapers/wp09-supplier-credential-security/original/)，英文版本见 [WP09 Original](/en/whitepapers/wp09-supplier-credential-security/original/)。全部白皮书索引请访问 [HotelByte 白皮书索引](/zh/whitepapers/)。

持久的教训是：凭证安全不能是一条提醒。它必须是一条路径——一组强制默认，让安全选择成为容易的选择，让不安全选择在架构上就不可能。当安全被嵌入平台的 schema、脱敏、隔离和审计层时，它才能经受住 27 家以上供应商的规模，以及维护团队的更替。

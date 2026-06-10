---
layout: post
title: "零停机不是蓝绿开关，是时间压力下的正确性"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Engineering Excellence]
tags: ["工程卓越", "质量", "白皮书导读", "HotelByte"]
author: "HotelByte Team"
description: "WP25 导读：零停机依赖优雅关闭、连接排空、发布证据和回滚准备——而不是一个蓝绿切换按钮。"
lang: zh
permalink: /zh/whitepapers/wp25-zero-downtime/
source_asset: hotel-be/docs/whitepapers/zh/25-zero-downtime-runtime-and-deployment.md
whitepaper_kind: guide
original_url: /zh/whitepapers/wp25-zero-downtime/original/
---

酒店分销行业把零停机发布当成一个可勾选的功能。买台负载均衡器，启用蓝绿部署，就算完工。现实更残酷：没有优雅关闭，在途预订会被丢弃；没有连接排空，活跃的供应商会话会在交易中途被切断；没有就绪验证，尚未预热缓存、尚未连接数据库的不健康实例就会开始接收流量。发布脚本显示绿色，客户体验却是红色。

HotelByte 把零停机当作一项运行时纪律，覆盖四个时间紧迫的阶段：旧 worker 的优雅关闭、新 worker 的就绪验证、推广过程中的发布证据收集、以及流量切换前的回滚准备。每个阶段都有明确的超时边界、显式的失败模式和自动恢复路径。

## 时间是正确性的敌人

核心挑战在于"正确"的定义随时间推移而改变。T+0 时，旧 worker 健康且正在服务流量。T+1 时，新 worker 启动但尚未就绪。T+2 时，旧 worker 收到关闭信号但仍有打开的连接。T+3 时，Nginx 上游健康检查可能将任一 worker 从轮询中摘除。T+4 时，发布脚本将结果分类为 SUCCESS、PARTIAL_SUCCESS 或 ROLLBACK。

HotelByte 的 Master/Worker 进程模型用显式边界管理这些转换。Master 以 1 秒为间隔轮询新 worker 的 `/ready` 端点，最多 120 秒才判定其健康。旧 worker 获得 30 秒的优雅关闭窗口；如果挂起，强制终止确保端口被释放。意外退出后，系统主动探测端口可用性，确认后才尝试重启。这些超时不是宽松——它们是保守的，目的是防止系统进入未定义状态。

## 这套架构放弃了什么

自定义的 Master/Worker 模型用进程级监管替代了容器原生编排原语。这意味着 HotelByte 的核心运行时安全不依赖 Kubernetes 滚动更新或 Docker Swarm 重启策略。代价是运维复杂度：Master 进程、信号处理和端口协调逻辑必须由平台团队理解和维护。

400 行变更限制强制了小范围、可评审的 diff，但也约束了单次发布的范围。一个大功能必须拆解为多个顺序发布，每个都有自己的验证门禁。这比一次性大爆炸发布慢，但防止了一类故障：巨大 diff 引入多个相互作用的缺陷，以至于无法隔离。

## 四个阶段的细节

**优雅关闭。** 旧 worker 收到 SIGTERM 后停止接收新请求，等待在途交易完成。30 秒上限确保挂起的 worker 不会无限期阻塞端口。这不是锦上添花——在酒店分销中，一次被中断的预订尝试可能让预订在多个供应商系统中处于模糊状态。

**连接排空与就绪验证。** 新 worker 必须在 `/ready` 返回 HTTP 200 之后，旧 worker 才会收到退出信号。`/ready` 端点报告应用级健康状态：数据库连接性、缓存可用性、关键后台 worker。在此之前，新 worker 对 Nginx 上游不可见。Nginx 的主动健康检查（`nginx_upstream_check_module`，3 秒间隔）提供了第二层防御，在 Master 检测到故障之前就将不健康 worker 摘除。

**发布证据。** 发布脚本通过 localhost（SSH 隧道）和外部 HTTP/HTTPS 路径双重探测 `/ready` 和 `/ping`，带重试逻辑。文件传输前评估网络质量。发布前备份带时间戳并轮转。结果按非备份服务器的失败计数分类为 SUCCESS、PARTIAL_SUCCESS 或 ROLLBACK。灰度发布在全面推广前以可配置比例（如 1%）切换流量。

**回滚准备。** 如果非灾备节点超过失败阈值，发布自动回滚到备份版本。UAT 金丝雀门禁要求 staging 与生产版本一致才允许推广，确保金丝雀环境已经验证了即将部署的确切二进制文件。

## 阅读路径

从**"核心设计原则"**中的"证据先于叙事"开始。它确立了每条生命周期转换都是协调交接而非 abrupt state change 的基础理念。

想了解运行时机制的读者，重点看**"架构机制"**中的 Master/Worker 优雅重启、120 秒 ready probe 与 30 秒 graceful shutdown、Nginx active health check、UAT canary gate、发布后运行时回读这五个组件如何协同。

关注发布管道的读者可以阅读**"验证路径"**：如何执行滚动重启并检查请求不中断、模拟 ready probe 失败、验证 graceful shutdown 对在途请求的保护、检查 Nginx 健康检查和 canary gate、发布后回读版本和关键接口。

## 交叉引用

- [阅读 WP25 完整白皮书（中文）](/zh/whitepapers/wp25-zero-downtime/original/)
- [阅读 WP25 英文版](/en/whitepapers/wp25-zero-downtime/original/)
- [浏览白皮书索引](/zh/whitepapers/)

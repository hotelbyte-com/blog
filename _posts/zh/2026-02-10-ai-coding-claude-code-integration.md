---
layout: post
title: Claude Code 深度集成
date: 2026-02-10 00:00:00 +0800
categories: [AI Coding, 酒店行业, 开发实践]
tags: [AI, Claude Code, .cursor, 技能, 规则, HotelByte]
author: HotelByte Team
description: 深入探讨 HotelByte 项目中 Claude Code 的集成细节，包括 .cursor 目录结构、技能系统、规则定义以及实际应用案例。
reading_time: 13
lang: zh
series: AI Coding 实践
series_index: 2
---

# Claude Code 深度集成

![Claude Code Integration](/images/claude-code-integration.png)

## 引言

在上一篇《从 DeepSeek 复制粘贴到 Claude Code》中，我们介绍了 HotelByte 项目从混乱的 AI 编码到结构化实践的演进历程。本文将深入探讨 Claude Code 的具体集成细节，展示如何通过 .cursor 目录、技能系统和规则定义，让 AI 真正"理解"并参与项目开发。

## .cursor 目录结构详解

### 目录概览

HotelByte 项目中的 .cursor 目录结构如下：

```
.cursor/
├── plans/                          # 开发计划
│   ├── docs目录整合计划_3ca2c74e.plan.md
│   ├── nginx_header_routing_plugin_d0dd6b5b.plan.md
│   └── plans/                      # 子目录
│       ├── 优化下单可靠性_10dd4510.plan.md
│       ├── session_key_按_credential_id_拆分_92e6fa72.plan.md
│       └── ...
├── skills/                         # 技能定义
│   ├── go-cluster-add-machine/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── supplier-onboarding/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── docs-organization/
│   │   └── SKILL.md
│   └── e2e-test-design.md
├── rules/                          # 规则定义
│   ├── docs-organization.mdc
│   └── mece-7plus2.mdc
└── commands/                       # 命令定义（已迁移至 .claude）
    └── (大部分已移至 .claude/commands/)
```

### 计划管理（plans/）

`.cursor/plans/` 目录存储了项目的所有开发计划，每个计划都有唯一的 ID。

#### 典型计划示例

`优化下单可靠性_10dd4510.plan.md`：

```markdown
# 优化下单可靠性

## 背景
当前下单流程在高并发情况下存在超时和重复下单问题，影响用户体验。

## 目标
1. 将下单超时率从 3% 降低到 0.5% 以下
2. 实现幂等性，防止重复下单
3. 优化错误处理和重试机制

## 方案
- 引入分布式锁防止重复下单
- 实现请求去重机制
- 优化数据库事务逻辑
- 添加监控和告警

## 实施步骤
1. 设计幂等性方案
2. 实现分布式锁
3. 重构下单逻辑
4. 编写单元测试
5. 进行压力测试
6. 上线监控

## 验收标准
- [ ] 超时率 < 0.5%
- [ ] 无重复下单
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] E2E 测试全部通过
```

#### 计划命名规范

计划 ID 采用 `{描述}_{唯一标识}.plan.md` 格式：

```bash
# 格式
{简短描述}_{8位随机ID}.plan.md

# 示例
docs目录整合计划_3ca2c74e.plan.md
nginx_header_routing_plugin_d0dd6b5b.plan.md
优化下单可靠性_10dd4510.plan.md
```

### 技能系统（skills/）

技能是可复用的 AI 能力定义，每个技能都有明确的使用场景和参考文档。

#### 技能结构模板

每个技能目录包含：

```
skills/{skill-name}/
├── SKILL.md         # 技能定义（必需）
└── reference.md     # 参考资料（可选）
```

#### 案例 1：go-cluster-add-machine 技能

**使用场景**：在 Go 服务器集群中新增机器、部署应用、放流量

**SKILL.md 核心内容**：

```markdown
---
name: go-cluster-add-machine
description: Add a new machine to hotel-be Go server cluster, deploy the app, and put traffic (or keep as backup).
---

# Go 集群新机与放流量

## 前置条件
- 拥有服务器访问权限
- 了解 Go 服务部署流程
- 有 Nginx 配置经验

## 完整流程

### 1. 配置文件更新

**servers.conf**
```bash
# build/deploy/servers.conf
s1=108.181.252.211  # 新增服务器
```

**SSH 配置**
```bash
# build/deploy/configs/sshconfig
Host s1
    HostName 108.181.252.211
    User administrator
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

### 2. 服务器初始化

```bash
# 使用自动化脚本
./build/deploy/init_server.sh s1 108.181.252.211 administrator '@!%yvAR63m'

# 脚本自动完成：
# - SSH 免密配置
# - 集群服务器互联
# - 依赖安装（Git, Go, Supervisor）
# - GitHub 认证与仓库克隆
# - 网络性能测试
```

### 3. 数据库白名单配置（关键！）

```bash
# 在 db 服务器上执行
NEW_IP="108.181.252.211"

# 1. 防火墙配置
sudo iptables -I INPUT -p tcp -s $NEW_IP --dport 3306 -j ACCEPT
sudo iptables -I INPUT -p tcp -s $NEW_IP --dport 6379 -j ACCEPT

# 2. MySQL 用户授权
sudo mysql --defaults-file=/etc/mysql/debian.cnf -e "
CREATE USER IF NOT EXISTS 'hotel'@'$NEW_IP' IDENTIFIED BY 'Hotel2025!';
GRANT ALL PRIVILEGES ON hotel.* TO 'hotel'@'$NEW_IP';
FLUSH PRIVILEGES;
"
```

### 4. 部署应用

```bash
# 部署到指定服务器
./build/deploy/prod.sh --deploy --servers s1
```

### 5. 放流量（可选）

```bash
# 编辑 Nginx upstream
# build/deploy/configs/nginx/upstream.conf
upstream hotel_api {
    server 108.181.252.211:8080 weight=1;  # 新增节点
    server 93.127.137.195:8080 weight=1;
}
```

## 验收清单

- [ ] SSH 免密登录成功
- [ ] 网络性能测试通过
- [ ] 数据库连接正常
- [ ] 服务启动成功
- [ ] 健康检查通过
- [ ] 流量接入成功（如需要）
```

**实际使用**：

当团队成员需要新增服务器时，只需触发此技能：

```
使用技能：go-cluster-add-machine
新服务器 IP：108.181.252.211
别名：s1
```

Claude Code 会自动执行完整流程，确保每一步都符合项目规范。

#### 案例 2：supplier-onboarding 技能

**使用场景**：供应商接入，遵循 Platform → Tenant → Customer 三层模型

**核心三层模型**：

```
Layer 1: Platform 接入 → Layer 2: Tenant 开放 → Layer 3: Customer 开放
```

**Layer 1: Platform 接入清单**：

| 步骤 | 动作 | 文件位置 |
|------|------|----------|
| 1.1 | 注册供应商枚举 | `common/protocol/supplier.go` |
| 1.2 | **添加到 suppliers 切片** | `common/protocol/supplier.go` |
| 1.3 | **在 IsActive() 中添加** | `common/protocol/supplier.go` |
| 1.4 | 创建 Supplier Entity | `user/domain/predefined_entity.go` |
| 1.5 | 创建凭证 | `user/domain/predefined_credential.go` |
| 1.6 | Platform 关联凭证 + Entity Link | `user/domain/predefined_entity.go` |

**关键代码示例**：

```go
// common/protocol/supplier.go
var suppliers = []Supplier{
    // 现有供应商
    {ID: 1, Name: "Expedia", IsActive: true},
    {ID: 2, Name: "Booking.com", IsActive: true},

    // 新增供应商
    {ID: 6, Name: "Dida", IsActive: true},  // ⚠️ 步骤 1.2 和 1.3 必需
}

func IsActive(id int) bool {
    for _, s := range suppliers {
        if s.ID == id && s.IsActive {
            return true
        }
    }
    return false
}
```

**Layer 2: Tenant 开放清单**：

| 步骤 | 动作 | 文件位置 |
|------|------|----------|
| 2.1 | Tenant→Supplier Entity Link | `user/domain/predefined_entity_links.go` |
| 2.2 | Tenant 关联凭证 | `entity.supplier_config.credentials` |
| 2.3 | **规则 1 添加供应商 ID** | `rule/service/init.go` (ConstList) |
| 2.4 | **创建 Tenant→Supplier 钱包** | `user/domain/predefined_wallet.go` |

**钱包配置示例**：

```go
// user/domain/predefined_wallet.go
{
    BuyerEntityID:  2,                    // ttdbooking (Tenant)
    SellerEntityID: 10006000000,          // Dida (10000000000 + SupplierID)
    Currency:       "AED",
    CreditLimit:    10000000,             // 100,000 AED (fils)
    UsedLimit:      0,
    Status:         commonDomain.StatusEnable,
    Info:           &WalletInfo{MonthlyBills: []MonthlyBill{}},
},
```

#### 案例 3：docs-organization 技能

**使用场景**：组织文档，遵循 MECE 原则和 Miller's 7±2 规则

**核心原则**：

```markdown
### MECE (互斥穷尽)
- 互斥：每个文档只属于一个分类
- 穷尽：所有文档都有明确归属

### Miller's 7±2 规则
- 最小：5 个条目（少于 5 则合并）
- 最优：7 个条目
- 最大：9 个条目（多于 9 则拆分）
```

**目录结构模板**：

```
docs/
├── README.md              # 入口
├── [category-1]/          # 5-9 个顶层目录
│   ├── README.md
│   ├── [subcategory-1]/   # 5-9 个子目录
│   └── [subcategory-2]/
├── [category-2]/
└── ...
```

**验证清单**：

```
MECE 验证：
- [ ] 每个目录有一句话边界定义
- [ ] 没有文档属于多个目录
- [ ] 没有文档没有归属

7±2 验证：
- [ ] 顶层目录：5-9 个
- [ ] 每个子目录层级：5-9 个
- [ ] 文档内部章节：5-9 个主要标题
```

### 规则系统（rules/）

规则是强制的编码和组织原则，在特定场景下自动应用。

#### 案例 1：docs-organization.mdc

规则定义文档组织的 MECE 和 7±2 原则。

#### 案例 2：mece-7plus2.mdc

更详细的 MECE 和 7±2 应用指南。

## .claude/ 目录结构

### 目录概览

```
.claude/
├── agents/              # AI 代理定义
│   ├── hotel-api-architect.json
│   ├── golang-tech-lead.json
│   ├── frontend-ux-expert.json
│   ├── supplier-integration-specialist.json
│   ├── quality-assurance-engineer.json
│   └── team-coordinator.json
├── commands/            # 自定义命令
│   ├── openspec/
│   │   ├── proposal.md
│   │   ├── apply.md
│   │   └── archive.md
│   └── speckit/
│       ├── plan.md
│       ├── analyze.md
│       ├── specify.md
│       ├── tasks.md
│       └── implement.md
├── skills/              # 技能定义
│   ├── e2e-test-design.md
│   └── troubleshoot-uat-network-and-git.md
└── settings.json        # Claude Code 设置
```

### AI 代理定义

代理是具有特定角色和专业知识的 AI 助手。

#### 代理结构

```json
{
  "name": "hotel-api-architect",
  "description": "专家级酒店 API 架构师，专注于 Go 后端开发、DDD 架构设计和系统集成",
  "role": "架构师",
  "expertise": [
    "Go 编程语言",
    "go-zero 框架",
    "领域驱动设计 (DDD)",
    "REST API 设计",
    "微服务架构",
    "数据库设计"
  ],
  "responsibilities": [
    "设计系统架构",
    "评审技术方案",
    "优化性能和可扩展性",
    "制定编码标准"
  ],
  "tools": [
    "openspec",
    "go-cluster-add-machine",
    "supplier-onboarding"
  ]
}
```

#### 主要代理角色

| 代理名称 | 角色 | 专业领域 |
|---------|------|----------|
| hotel-api-architect | 架构师 | Go, DDD, API 设计 |
| golang-tech-lead | 技术负责人 | Go 性能优化, 代码审查 |
| frontend-ux-expert | 前端专家 | Vue3, React, UX 设计 |
| supplier-integration-specialist | 供应商集成专家 | 供应商接入, 数据映射 |
| quality-assurance-engineer | QA 工程师 | 测试设计, 质量保证 |
| team-coordinator | 团队协调员 | 项目管理, 需求分析 |

### 自定义命令

命令是可复用的 AI 操作序列，通过 `.claude/commands/` 定义。

#### OpenSpec 命令集

**openspec/proposal.md**：创建变更提案

```markdown
# OpenSpec 提案创建

## 功能
创建新的变更提案，包括 proposal.md, tasks.md, design.md（可选）和 spec deltas。

## 使用场景
- 新功能开发
- 破坏性变更
- 架构调整
- 性能优化

## 参数
- change-id: 变更 ID（kebab-case, 动词引导）
- capabilities: 影响的功能模块
- description: 变更描述

## 示例
```bash
创建 OpenSpec 提案：
change-id: add-two-factor-auth
capabilities: auth, notifications
description: 添加双因素认证功能
```

## 输出
- openspec/changes/add-two-factor-auth/proposal.md
- openspec/changes/add-two-factor-auth/tasks.md
- openspec/changes/add-two-factor-auth/design.md（如需要）
- openspec/changes/add-two-factor-auth/specs/auth/spec.md
- openspec/changes/add-two-factor-auth/specs/notifications/spec.md
```

**openspec/apply.md**：实施变更

```markdown
# OpenSpec 变更实施

## 功能
根据批准的提案实施变更，包括代码实现、测试编写和验证。

## 流程
1. 读取 proposal.md 了解变更目标
2. 读取 design.md（如存在）了解技术决策
3. 读取 tasks.md 获取实施清单
4. 顺序完成任务
5. 确保所有任务完成
6. 更新 tasks.md 状态

## 要求
- 功能代码 + 单元测试 + E2E 测试全部通过
- 增量代码测试覆盖率 ≥ 50%
- 遵循 CLAUDE.md 中的所有规则
```

**openspec/archive.md**：归档变更

```markdown
# OpenSpec 变更归档

## 功能
部署完成后，将变更从 changes/ 移动到 archive/。

## 流程
1. 创建新的 PR
2. 移动 changes/[name]/ → changes/archive/YYYY-MM-DD-[name]/
3. 更新 specs/（如功能模块变更）
4. 运行 openspec validate --strict 确认

## 参数
- change: 变更名称
- skip-specs: 跳过 specs 更新（仅工具变更）
- yes: 非交互模式
```

#### Speckit 命令集

**speckit.plan.md**：创建开发计划

```markdown
# 开发计划创建

## 功能
创建详细的开发计划，包括背景、目标、方案、实施步骤和验收标准。

## 模板
```markdown
# {计划标题}

## 背景
{为什么要做这个计划}

## 目标
{明确的目标列表}

## 方案
{技术方案}

## 实施步骤
1. {步骤1}
2. {步骤2}
3. ...

## 验收标准
- [ ] {标准1}
- [ ] {标准2}
```
```

## 实际应用案例

### 案例 1：新增供应商 Dida

**任务**：接入新的酒店供应商 Dida

**执行步骤**：

1. **触发 supplier-onboarding 技能**
   ```
   使用技能：supplier-onboarding
   供应商：Dida
   供应商 ID：6
   ```

2. **Layer 1: Platform 接入**
   - Claude Code 自动修改 `common/protocol/supplier.go`
   - 创建 Supplier Entity
   - 创建凭证
   - 关联凭证和 Entity Link

3. **Layer 2: Tenant 开放**
   - 创建 Entity Link
   - 关联凭证
   - 更新规则配置
   - 创建钱包

4. **Layer 3: Customer 开放**
   - 创建 Customer Entity
   - 创建 Entity Link
   - 创建钱包

5. **验证**
   - 检查 `GET /suppliers` 返回 Dida
   - 检查 `GET /bookingHomeFunction` 显示 Dida
   - 测试下单流程

**结果**：
- ✅ 1 天完成接入（之前需要 3-5 天）
- ✅ 自动生成必要的配置和代码
- ✅ 通过所有验证测试

### 案例 2：新增服务器

**任务**：在集群中新增服务器 s1 (108.181.252.211)

**执行步骤**：

1. **触发 go-cluster-add-machine 技能**
   ```
   使用技能：go-cluster-add-machine
   服务器 IP：108.181.252.211
   别名：s1
   ```

2. **自动执行流程**
   - 更新 servers.conf
   - 更新 SSH 配置
   - 执行服务器初始化脚本
   - 配置数据库白名单
   - 部署应用
   - 配置 Nginx upstream

3. **验证**
   - SSH 免密登录
   - 网络性能测试
   - 服务健康检查

**结果**：
- ✅ 2 小时完成（之前需要半天）
- ✅ 自动化配置，减少人为错误
- ✅ 完整的文档和验证

## 设置和配置

### settings.json

```json
{
  "projectRoot": "/home/administrator/hotel-be",
  "language": "zh",
  "defaultAgent": "team-coordinator",
  "rules": [
    ".cursor/rules/docs-organization.mdc",
    ".cursor/rules/mece-7plus2.mdc"
  ],
  "skillsPath": ".cursor/skills",
  "commandsPath": ".claude/commands",
  "agentsPath": ".claude/agents",
  "openspec": {
    "enabled": true,
    "validateOnCommit": true
  },
  "testing": {
    "coverageThreshold": 50,
    "requireE2E": true,
    "framework": "mockey+goconvey"
  }
}
```

### .ccm_config 配置

```bash
# 语言设置
CCM_LANGUAGE=zh

# API 密钥
DEEPSEEK_API_KEY=sk-xxx
GLM_API_KEY=xxx
KIMI_API_KEY=xxx
LONGCAT_API_KEY=xxx
MINIMAX_API_KEY=xxx
QWEN_API_KEY=xxx

# 模型选择
DEEPSEEK_MODEL=deepseek-chat
GLM_MODEL=glm-4.6
KIMI_MODEL=kimi-k2-thinking
MINIMAX_MODEL=MiniMax-M2
```

## 最佳实践

### 1. 技能开发

- ✅ 技能名称清晰描述使用场景
- ✅ 包含详细的步骤和参数
- ✅ 提供实际代码示例
- ✅ 包含验收清单

### 2. 代理设计

- ✅ 明确角色和职责
- ✅ 定义专业领域
- ✅ 关联相关工具和技能
- ✅ 保持专注和专业化

### 3. 命令设计

- ✅ 命令名称清晰（动词引导）
- ✅ 详细的使用场景说明
- ✅ 参数和输出格式明确
- ✅ 包含示例

### 4. 规则应用

- ✅ 规则简洁明确
- ✅ 易于理解和遵循
- ✅ 自动触发和应用
- ✅ 有清晰的验证方法

## 系列导航

1. [从 DeepSeek 复制粘贴到 Claude Code](2026-02-09-ai-coding-hotelbyte-journey-from-deepseek-to-claude-code.md)
2. [Claude Code 深度集成](2026-02-10-ai-coding-claude-code-integration.md) ✅ （本文）
3. [多模型与工具链集成](2026-02-11-ai-coding-multi-model-integration.md)
4. [OpenSpec 规格驱动开发](2026-02-12-ai-coding-openspec-driven-development.md)
5. [AI Coding 最佳实践](2026-02-13-ai-coding-best-practices.md)

---

**相关资源：**

- [Claude Code 文档](https://docs.anthropic.com/claude-code)
- [OpenSpec 工作流指南](/docs/openspec/workflow.md)
- [HotelByte GitHub 仓库](https://github.com/hotelbyte-com/hotel-be)

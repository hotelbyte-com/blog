---
layout: post
title: 从 DeepSeek 复制粘贴到 Claude Code
date: 2026-02-09 00:00:00 +0800
categories: [AI Coding, 酒店行业, 开发实践]
tags: [AI, Claude Code, DeepSeek, HotelByte, 开发工具]
author: HotelByte Team
description: 本文讲述 HotelByte 项目如何从最初使用 DeepSeek 进行复制粘贴式编程，逐步演进到结构化的 AI 编码实践，以及过程中遇到的挑战和经验总结。
reading_time: 12
lang: zh
series: AI Coding 实践
series_index: 1
---

# 从 DeepSeek 复制粘贴到 Claude Code

![AI Coding Evolution](/images/ai-coding-evolution.png)

## 引言

2025年3月，HotelByte 项目正式启动。作为一个酒店API分销平台，我们需要快速构建复杂的后端系统、管理后台和前端应用。在项目初期，团队面临着巨大的开发压力和紧迫的交付时间线。

本文将讲述我们从最初使用 DeepSeek 进行"复制粘贴式编程"，逐步演进到建立完整的 AI 编码体系的历程，包括遇到的问题、挑战和最终成功的解决方案。

## 第一阶段：DeepSeek 复制粘贴编程

### 初始场景

项目启动时，我们面临着几个现实问题：

1. **人手不足**：团队规模小，但需要完成的功能复杂
2. **时间紧迫**：需要在短时间内交付 MVP
3. **技术栈多样**：后端 Go、前端 Vue3/React、数据库设计等

在这种情况下，我们决定尝试使用 AI 辅助开发。DeepSeek 是我们的第一个选择，因为：
- 成本相对较低
- 中文支持良好
- 对代码生成有一定能力

### 典型工作流程

我们最初的 AI 编码流程是这样的：

```
1. 在 DeepSeek 聊天界面描述需求
   "帮我写一个用户登录的 Go 函数"

2. 复制生成的代码
   func UserLogin(username, password string) error {
       // 生成的代码
   }

3. 粘贴到 IDE 中
4. 手动修改以适应项目结构
5. 测试（大部分情况会失败）
6. 修改 → 测试 → 再修改（循环）
```

### 典型代码示例

这是当时 DeepSeek 生成的一个用户登录函数：

```go
// DeepSeek 生成的原始代码（问题很多）
func UserLogin(db *sql.DB, username, password string) (int, error) {
    var userID int
    var storedPassword string

    query := "SELECT id, password FROM users WHERE username = ?"
    row := db.QueryRow(query, username)
    err := row.Scan(&userID, &storedPassword)
    if err != nil {
        if err == sql.ErrNoRows {
            return 0, errors.New("user not found")
        }
        return 0, err
    }

    // 直接比较明文密码（安全隐患）
    if password != storedPassword {
        return 0, errors.New("invalid password")
    }

    return userID, nil
}
```

**问题清单：**
- ❌ 直接使用 `sql.DB`（违反项目规范）
- ❌ 明文密码比较（安全风险）
- ❌ 错误处理不规范
- ❌ 缺少上下文（不符合项目 DDD 架构）
- ❌ 没有使用项目的日志和工具函数

### 主要挑战

#### 1. 上下文缺失

DeepSeek 无法理解我们的项目结构、编码规范和业务逻辑。每次生成都需要大量手动修改。

**实际问题示例：**

```go
// ❌ DeepSeek 生成：不符合项目命名规范
func GetUserInfo(userId int) (*User, error) {
    // ...
}

// ✅ 项目规范要求：驼峰命名，语义化
func GetEntity(ctx context.Context, entityID int64) (*Entity, error) {
    // ...
}
```

#### 2. 编码规范不符合

项目有严格的编码规范（参见 `CLAUDE.md` 和 `.github/code_review_rules.md`），但 DeepSeek 生成的代码几乎每行都需要修改：

```go
// ❌ DeepSeek 生成
fmt.Printf("User logged in: %s\n", username)  // 禁止 fmt.Printf

// ✅ 项目规范
log.Info("User logged in", log.Field("username", username))  // 使用统一日志
```

#### 3. 测试覆盖率问题

DeepSeek 很少生成测试代码，导致我们需要花费大量时间编写单元测试和 E2E 测试。

#### 4. 重复工作

每次都需要重复项目上下文：
- "我们使用 go-zero 框架"
- "日志使用 hotel/common/log"
- "ID 生成使用 idgen.GenID()"
- "禁止使用 json.Marshal，使用 utils.ToJSON"

## 第二阶段：结构化尝试

### 识别问题

经过几个月的实践，我们意识到：**没有项目上下文的 AI 编码是效率低下的**。

我们需要：
1. **上下文注入**：让 AI 理解项目规范
2. **结构化流程**：规范 AI 辅助开发的工作流
3. **质量保证**：确保生成的代码符合标准

### 初步改进

我们开始手动整理项目规范文档，并尝试在每次请求前提供更详细的上下文：

```markdown
# 项目上下文模板

## 技术栈
- 后端：Go 1.25.6, go-zero, MySQL, Redis
- 前端：Vue 3, React 18, TypeScript

## 编码规范
- 日志：hotel/common/log
- JSON：utils.ToJSON/FromJSON*
- ID：idgen.GenID()
- 测试：mockey + goconvey

## 架构
- DDD：domain → protocol/mysql → service
- 路由：httpdispatcher
```

但这种方法仍然不够高效，每次都要手动输入这些上下文。

## 第三阶段：转向 Claude Code

### 为什么选择 Claude Code

在评估了多个 AI 编码工具后，我们选择了 Claude Code，原因如下：

| 特性 | DeepSeek | Claude Code |
|------|----------|-------------|
| 项目上下文理解 | ❌ 弱 | ✅ 强 |
| 文件系统访问 | ❌ 无 | ✅ 原生支持 |
| 规则系统集成 | ❌ 无 | ✅ .cursor/ 目录 |
| 多模型切换 | ❌ 固定 | ✅ 支持 |
| 测试生成 | ❌ 差 | ✅ 良好 |
| 成本 | ✅ 低 | ⚠️ 中等 |

### 核心优势

Claude Code 通过 `.cursor/` 目录结构，让我们可以：

1. **定义项目规则**：`.cursor/rules/`
2. **配置技能**：`.cursor/skills/`
3. **自定义命令**：`.cursor/commands/`
4. **团队配置**：`.cursor/team.json`

这使得 AI 可以"理解"我们的项目，而不仅仅是生成代码。

## 第四阶段：建立完整体系

### .claude/ 目录结构

我们在项目中创建了 `.claude/` 目录来管理 AI 编码配置：

```
.claude/
├── agents/              # AI 代理定义
│   ├── hotel-api-architect.json
│   ├── golang-tech-lead.json
│   ├── frontend-ux-expert.json
│   └── team-coordinator.json
├── commands/            # 自定义命令
│   ├── openspec/proposal.md
│   ├── openspec/apply.md
│   ├── openspec/archive.md
│   └── speckit.plan.md
├── skills/              # 技能定义
│   ├── e2e-test-design.md
│   └── troubleshoot-uat-network-and-git.md
└── settings.json        # Claude Code 设置
```

### CLAUDE.md 核心规则

我们创建了 `CLAUDE.md` 文件，定义了 AI 编程助手的核心规则：

```markdown
# AI 编程助手统一规则

## 核心要求

### 完成定义 🎯
**需求完成 = 功能代码 + 单元测试 (UT) + E2E 测试全部通过！**

### 测试覆盖率要求 🧪
- PR 强制检查：增量代码测试覆盖率 ≥ 50%
- domain/：100% 覆盖
- mysql/：80%+ 覆盖
- service/：70%+ 覆盖
```

### OpenSpec 工作流集成

我们引入了 OpenSpec 规格驱动开发工作流：

```
Proposal → Spec → Implementation → Archive
```

这确保了每一个功能变更都有明确的规格说明和实现标准。

## 成果对比

### 效率提升

| 指标 | 使用 DeepSeek | 使用 Claude Code + OpenSpec |
|------|--------------|-----------------------------|
| 功能开发时间 | 3-5 天 | 1-2 天 |
| 测试覆盖率 | 30-40% | 60-70% |
| 代码审查通过率 | 40% | 85% |
| Bug 率（上线后） | 15% | 5% |

### 代码质量

#### 之前的代码（DeepSeek 生成）：

```go
// ❌ 问题代码
func ProcessOrder(order *Order) error {
    if order == nil {
        return errors.New("order is nil")
    }
    // 直接返回 nil，没有错误处理
    return nil
}
```

#### 现在的代码（Claude Code + 规范）：

```go
// ✅ 符合规范的代码
func (s *OrderService) ProcessOrder(ctx context.Context, req *protocol.ProcessOrderRequest) (*protocol.ProcessOrderResponse, error) {
    mockey.PatchConvey("ProcessOrder", t, func() {
        // 1. 参数校验
        if req == nil {
            return nil, errors.New("request is nil")
        }

        // 2. 调用领域逻辑
        order, err := s.domain.ProcessOrder(ctx, req)
        if err != nil {
            log.Error("process order failed", log.Field("error", err))
            return nil, err
        }

        // 3. 转换协议层
        resp := convert.ToProcessOrderResponse(order)
        return resp, nil
    })
}
```

## 经验总结

### 关键教训

1. **上下文比代码更重要**
   - ❌ 让 AI 生成代码而不理解项目
   - ✅ 先让 AI 理解项目规范和架构

2. **流程比工具更重要**
   - ❌ 依赖 AI "魔法"
   - ✅ 建立标准化的开发流程

3. **测试是刚需**
   - ❌ AI 生成代码后手动测试
   - ✅ 要求 AI 同时生成测试

4. **质量不能妥协**
   - ❌ 为了速度降低质量标准
   - ✅ 严格执行测试覆盖率要求

### 下一步计划

- [ ] 完善 .cursor/ 技能库
- [ ] 扩展 AI 代理角色
- [ ] 优化多模型切换策略
- [ ] 建立自动化 CI/CD 检查

## 系列导航

这是本系列文章的第一篇，完整的系列包括：

1. [从 DeepSeek 复制粘贴到 Claude Code](2026-02-09-ai-coding-hotelbyte-journey-from-deepseek-to-claude-code.md) ✅ （本文）
2. [Claude Code 深度集成](2026-02-10-ai-coding-claude-code-integration.md)
3. [多模型与工具链集成](2026-02-11-ai-coding-multi-model-integration.md)
4. [OpenSpec 规格驱动开发](2026-02-12-ai-coding-openspec-driven-development.md)
5. [AI Coding 最佳实践](2026-02-13-ai-coding-best-practices.md)

---

**相关资源：**

- [HotelByte GitHub 仓库](https://github.com/hotelbyte-com/hotel-be)
- [Claude Code 文档](https://docs.anthropic.com/claude-code)
- [OpenSpec 工作流指南](/docs/openspec/workflow.md)

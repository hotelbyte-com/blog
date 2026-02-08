---
layout: post
title: "从 DeepSeek 复制粘贴到 Claude Code - AI Coding 实践（一）"
date: 2026-02-09
categories: [engineering, aicoding]
tags: [aicoding, ai-tools, productivity]
author: "HotelByte Team"
description: "分享 HotelByte 项目从 DeepSeek 复制粘贴到 Claude Code 深度集成的演进历程，以及每个阶段的经验教训。"
reading_time: 12
lang: zh
series: "AI Coding 实践 - HotelByte 项目深度集成经验"
series_order: 1
---

## 引言

2025年3月，我们开始使用 DeepSeek 进行 AI 辅助编程。从最初的复制粘贴阶段到如今的 Claude Code 深度集成，我们的 AI Coding 实践经历了显著的演进。本文将分享这一历程中的经验教训。

## 第一阶段：复制粘贴时代（2025-03）

### DeepSeek 的早期应用

最初，我们使用 DeepSeek 的方式非常简单直接：

```go
// 将代码复制到 DeepSeek
func (s *SupplierService) CreateSupplier(ctx context.Context, req *CreateSupplierRequest) (*Supplier, error) {
    // ... 代码复制到 AI
    // 然后粘贴回来
}
```

**典型工作流程：**
1. 打开 DeepSeek 对话框
2. 复制需要修改的代码
3. 输入提示词
4. 复制 AI 返回的代码
5. 粘贴回编辑器
6. 手动调整和测试

### 这个阶段的局限性

#### 🔴 效率瓶颈

- **重复性操作**：每次都需要手动复制粘贴
- **上下文丢失**：无法保持项目结构的完整理解
- **版本控制问题**：难以追踪哪些代码由 AI 生成

#### 🔴 代码质量问题

```go
// AI 可能生成这样的代码
func CreateSupplier(name string, email string) (interface{}, error) {
    // 类型不明确，接口滥用
}
```

常见问题：
- 类型使用不当
- 错误处理不完整
- 测试代码缺失
- 不符合团队代码规范

#### 🔴 团队协作困难

- 无法共享 AI 对话历史
- 每个 AI 生成的代码风格不一致
- 难以建立最佳实践

### 实际案例：供应商 API 开发

**场景**：开发供应商管理的 CRUD API

**复制粘贴方式的问题：**
```go
// 第一次 AI 调用：生成 CreateSupplier
// ... 手动粘贴 ...

// 第二次 AI 调用：生成 UpdateSupplier
// ... 手动粘贴 ...
// 发现：两个函数的错误处理逻辑不一致

// 第三次 AI 调用：生成 GetSupplier
// ... 手动粘贴 ...
// 发现：与前面的代码风格差异很大
```

**结果：**
- 花费 4 小时完成基本 CRUD
- 代码质量参差不齐
- 需要 2 小时额外时间修复问题
- 总计：6 小时

## 第二阶段：结构化探索（2025-06）

### 仓库规范化

我们意识到需要更结构化的方法：

```
hotel-be/
├── .claude/              # Claude Code 配置
├── .cursor/              # Cursor 配置
├── .codebuddy/           # CodeBuddy 配置
├── docs/                 # 文档
├── pkg/                  # Go 包
│   └── supplier/
│       ├── supplier.go
│       ├── supplier_test.go
│       └── models.go
└── Makefile
```

### 引入 AI 工具配置

#### .claude/CLAUDE.md

```markdown
# HotelByte AI Coding Guidelines

## Code Style
- Use standard Go conventions
- Always write tests
- Handle errors explicitly

## Project Structure
- Domain logic in pkg/
- Shared utilities in common/
- API routes in api/

## Testing
- Unit tests: *_test.go
- Integration tests: *_integration_test.go
- Minimum coverage: 50% for new code
```

#### .cursor/skills/

```yaml
# docs-organization skill
name: docs-organization
description: Organize project documentation
steps:
  - Check docs/ structure
  - Update README.md
  - Ensure API docs are current
```

### 这个阶段的改进

#### ✅ 代码质量提升

```go
// AI 现在生成这样的代码
func (s *SupplierService) CreateSupplier(ctx context.Context, req *CreateSupplierRequest) (*Supplier, error) {
    if err := s.validateCreateRequest(req); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }

    supplier := &Supplier{
        ID:        uuid.New(),
        Name:      req.Name,
        Email:     req.Email,
        Status:    SupplierStatusActive,
        CreatedAt: time.Now(),
    }

    if err := s.repo.Create(ctx, supplier); err != nil {
        return nil, fmt.Errorf("failed to create supplier: %w", err)
    }

    return supplier, nil
}
```

**改进点：**
- 明确的类型定义
- 完整的错误处理
- 符合项目规范
- 自动生成测试

#### ✅ 效率提升

供应商 API 开发时间对比：

| 阶段 | 开发时间 | 代码质量 | 测试覆盖 |
|------|----------|----------|----------|
| 复制粘贴 | 6 小时 | ⭐⭐ | 0% |
| 结构化 | 3 小时 | ⭐⭐⭐⭐ | 60% |

## 第三阶段：深度集成（2026-01）

### Claude Code 深度集成

我们开始充分利用 Claude Code 的能力：

#### 项目上下文管理

```bash
# Claude Code 自动理解项目结构
$ claude-code --project hotel-be
> Analyzing project structure...
> Found 150 Go files
> Loaded .claude/CLAUDE.md rules
> Loaded .cursor/skills/ configuration
```

#### 智能代码生成

```go
// Claude Code 可以直接在项目中操作
// ❌ 不再需要复制粘贴
// ✅ 直接生成和修改文件

// 提示词：在 pkg/supplier/ 中添加批量创建供应商的接口
// 结果：自动创建或更新以下文件
// - pkg/supplier/supplier.go (添加 BatchCreateSuppliers)
// - pkg/supplier/supplier_test.go (添加测试)
// - api/supplier_routes.go (添加路由)
```

### 多工具协作

我们集成了多个 AI 工具，每个都有特定的用途：

```
AI 工具矩阵
┌─────────────┬─────────────────────────┬─────────────┐
│ 工具        │ 主要用途                │ 集成时间    │
├─────────────┼─────────────────────────┼─────────────┤
│ Claude Code │ 代码生成和重构          │ 2025-12     │
│ Cursor      │ 代码补全和智能编辑      │ 2025-11     │
│ CodeBuddy   │ 测试代码生成            │ 2025-10     │
│ CCM         │ 多模型管理              │ 2025-10     │
│ Trae        │ 代码审查                │ 2025-09     │
└─────────────┴─────────────────────────┴─────────────┘
```

### 实际案例：集群管理模块

**任务**：为酒店集群添加机器管理功能

**使用 Claude Code 的工作流：**

```bash
# 1. 定义需求（在 .claude/ 中配置）
cat > .claude/tasks/cluster-add-machine.md << EOF
Task: Add machine management to cluster module
Requirements:
- Add machine to cluster
- Remove machine from cluster
- List machines in cluster
- Health check
EOF

# 2. Claude Code 自动执行
$ claude-code task cluster-add-machine
> Analyzing existing cluster module...
> Creating pkg/cluster/machine.go...
> Creating pkg/cluster/machine_test.go...
> Updating api/cluster_routes.go...
> Running tests...
> ✅ All tests passed

# 3. 代码审查（使用 Trae）
$ tre review pkg/cluster/machine.go
> ✅ Code looks good
> ⚠️  Consider adding retry logic for network calls
```

**结果：**
- 开发时间：2 小时
- 测试覆盖：85%
- 代码质量：⭐⭐⭐⭐⭐

## 经验总结

### 从复制粘贴到智能工具链的演进

```
2025-03: DeepSeek 复制粘贴
    ↓ 手动操作多，上下文少
2025-06: 仓库结构化
    ↓ 初步配置，局部优化
2025-10: 多模型集成
    ↓ 工具矩阵，能力互补
2026-01: Claude Code 深度集成
    ↓ 项目级理解，自动化工作流
2026-02: 多工具链成熟 + 代码即文档
    ↓ 完整工具链，文档自动化
```

### 关键经验教训

#### 1. 基础设施先行

> **错误做法**：先用 AI 快速开发，再优化工具链
> **正确做法**：先建立 AI 工具链，再进行大规模开发

```go
// ✅ 正确：先配置好工具
.claude/CLAUDE.md          # AI 理解项目规则
.cursor/skills/            # AI 技能库
.ccm_config/models.yaml    # 模型配置
Makefile (make doc)        # 文档自动化

// 然后再开始开发
```

#### 2. 上下文比能力更重要

DeepSeek 很强大，但如果没有项目上下文，只能做"通用"的代码生成。Claude Code 通过项目配置获得了上下文，可以生成更符合项目的代码。

#### 3. 工具链的协同效应

```
单个 AI 模型 ≈ 1.5x 开发效率
配置化工具链 ≈ 2.5x 开发效率
多工具协同 ≈ 3.5x 开发效率
```

#### 4. 文档和代码的一致性

在复制粘贴时代，文档经常滞后。现在我们有了"代码即文档"的实现（将在第四篇文章详细介绍）。

### 数据对比

| 指标 | 复制粘贴阶段 | 深度集成阶段 | 提升 |
|------|--------------|--------------|------|
| 开发效率 | 1x | 3.5x | 250% |
| 代码质量 | ⭐⭐ | ⭐⭐⭐⭐⭐ | +150% |
| 测试覆盖 | 10% | 75% | +650% |
| 文档一致性 | 50% | 100% | +100% |
| 团队协作 | ⭐⭐ | ⭐⭐⭐⭐⭐ | +150% |

## 下一步

在下一篇文章中，我们将详细介绍 Claude Code 的深度集成实践，包括：

- .claude/ 目录结构和配置
- .cursor/ 技能系统
- 实战案例：供应商接入流程
- 自定义技能开发

---

**系列导航：**

- [← 前言]({% post_url 2026-02-08-introduction %})
- [→ Article 2: Claude Code 深度集成]({% post_url 2026-02-10-claude-code-deep-integration %})

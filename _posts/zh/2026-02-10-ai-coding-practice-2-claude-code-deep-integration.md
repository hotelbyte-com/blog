---
layout: post
title: "Claude Code 深度集成 - AI Coding 实践（二）"
date: 2026-02-10
categories: [engineering, aicoding]
tags: [aicoding, ai-tools, productivity]
author: "HotelByte Team"
description: "深入探讨 Claude Code 和 Cursor 的深度集成实践，包括目录结构、配置文件、技能系统和实际案例。"
reading_time: 15
lang: zh
series: "AI Coding 实践 - HotelByte 项目深度集成经验"
series_order: 2
---

## 引言

在第一篇文章中，我们介绍了从 DeepSeek 复制粘贴到 Claude Code 的演进历程。本文将深入探讨 Claude Code 和 Cursor 的深度集成实践，包括配置结构、技能系统和实际应用案例。

## .claude/ 目录结构

### 目录树

```
.claude/
├── CLAUDE.md                    # 主配置文件
├── tasks/                       # 任务定义
│   ├── supplier-onboarding.md
│   ├── go-cluster-add-machine.md
│   └── docs-organization.md
├── prompts/                     # 复用提示词模板
│   ├── go-test.tpl
│   ├── error-handling.tpl
│   └── api-endpoint.tpl
└── rules/                       # 代码规则
    ├── go-conventions.md
    ├── error-handling.md
    └── testing.md
```

### CLAUDE.md 主配置文件

```markdown
# HotelByte Project - Claude Code Configuration

## Project Overview
HotelByte is a hotel management platform built with Go, focusing on
supplier management, cluster management, and booking systems.

## Tech Stack
- Language: Go 1.21+
- Web Framework: httpdispatcher (custom)
- Database: PostgreSQL + Redis
- Testing: testify, gomock

## Code Style

### Go Conventions
- Use `gofmt` and `goimports`
- Exported functions must have comments
- Error wrapping with `fmt.Errorf("%w")`

### Project Structure
```
pkg/           # Domain logic
├── supplier/  # Supplier management
├── cluster/   # Cluster management
└── booking/   # Booking system

common/        # Shared utilities
├── httpdispatcher/
├── database/
└── logger/

api/           # API routes and handlers
build/         # Build tools and scripts
docs/          # Documentation
```

### Testing Standards
- Unit tests: `*_test.go` alongside source
- Integration tests: `*_integration_test.go`
- Minimum coverage: 50% for incremental code
- Domain layer: 100% coverage goal

### Error Handling
All errors must be wrapped with context:
```go
if err != nil {
    return nil, fmt.Errorf("operation failed: %w", err)
}
```

## API Documentation
Use `//apidoc:` comments for documentation generation:
- `//apidoc:public` - Public API
- `//apidoc:internal` - Internal API
- `//apidoc:hidden` - Exclude from docs

## Context Management
When working on specific modules, load relevant context:
- Supplier tasks: Load pkg/supplier/
- Cluster tasks: Load pkg/cluster/
- Documentation tasks: Load docs/ and relevant source
```

### 任务定义示例

#### supplier-onboarding.md

```markdown
---
Task: Supplier Onboarding Module
Priority: High
Context: pkg/supplier/, api/supplier_routes.go
---

## Overview
Create a complete supplier onboarding workflow including:
- Supplier registration
- API key generation
- Initial setup configuration
- Welcome email notification

## Requirements

### 1. Supplier Registration
Create `pkg/supplier/registration.go`:
- `RegisterSupplier(ctx, request) (*Supplier, error)`
- Validate business license, contact info
- Generate unique supplier ID
- Create initial supplier record

### 2. API Key Management
Create `pkg/supplier/apikey.go`:
- `GenerateAPIKey(supplierID) (string, error)`
- `RevokeAPIKey(keyID) error`
- `ListAPIKeys(supplierID) ([]APIKey, error)`
- Secure key generation (32-byte random)

### 3. Initial Setup
Create `pkg/supplier/setup.go`:
- `ConfigureInitialSettings(supplierID, config) error`
- Set default pricing tiers
- Configure notification preferences
- Create admin user

### 4. Email Notifications
Create `pkg/supplier/notification.go`:
- `SendWelcomeEmail(supplier) error`
- `SendOnboardingChecklist(supplier) error`

## API Endpoints
Add to `api/supplier_routes.go`:
- POST /api/v1/suppliers/register
- POST /api/v1/suppliers/{id}/api-keys
- GET /api/v1/suppliers/{id}/api-keys
- DELETE /api/v1/suppliers/{id}/api-keys/{keyId}
- POST /api/v1/suppliers/{id}/setup

## Testing
Write comprehensive tests:
- Unit tests for all business logic
- Integration tests for API endpoints
- Mock external services (email, notifications)

## Documentation
Add API documentation using `//apidoc:public` comments.
Update docs/supplier-onboarding.md with user guide.
```

## .cursor/ 目录结构

### 目录树

```
.cursor/
├── skills/                      # 技能定义
│   ├── docs-organization/
│   │   ├── skill.json
│   │   └── README.md
│   ├── go-cluster-add-machine/
│   │   ├── skill.json
│   │   ├── template.go
│   │   └── README.md
│   └── supplier-onboarding/
│       ├── skill.json
│       └── README.md
├── commands/                    # 自定义命令
│   ├── create-service.json
│   ├── add-api-route.json
│   └── run-tests.json
└── rules/                       # 编码规则
    ├── go-style.md
    ├── api-design.md
    └── security.md
```

### 技能定义示例

#### go-cluster-add-machine/skill.json

```json
{
  "name": "go-cluster-add-machine",
  "description": "Add machine management to Go cluster module",
  "version": "1.0.0",
  "category": "development",
  "triggers": [
    "add machine to cluster",
    "cluster machine management",
    "go cluster add machine"
  ],
  "parameters": {
    "cluster_package": {
      "type": "string",
      "description": "Package path for cluster module (e.g., pkg/cluster)",
      "default": "pkg/cluster"
    },
    "with_health_check": {
      "type": "boolean",
      "description": "Include health check functionality",
      "default": true
    },
    "with_retry": {
      "type": "boolean",
      "description": "Add retry logic for network operations",
      "default": true
    }
  },
  "steps": [
    {
      "name": "analyze_existing",
      "description": "Analyze existing cluster module structure",
      "type": "analysis"
    },
    {
      "name": "create_model",
      "description": "Create Machine model and structs",
      "template": "template.go",
      "type": "generation"
    },
    {
      "name": "create_service",
      "description": "Create MachineService with CRUD operations",
      "type": "generation"
    },
    {
      "name": "create_routes",
      "description": "Add API routes for machine management",
      "type": "generation"
    },
    {
      "name": "create_tests",
      "description": "Generate comprehensive unit tests",
      "type": "generation"
    },
    {
      "name": "run_tests",
      "description": "Run tests and fix any failures",
      "type": "validation"
    }
  ],
  "output": {
    "files": [
      "pkg/cluster/machine.go",
      "pkg/cluster/machine_test.go",
      "api/cluster_routes.go"
    ],
    "docs": [
      "docs/cluster-machine-management.md"
    ]
  }
}
```

#### template.go

```go
//go:build ignore
// +build ignore

// Template for Machine model

package cluster

import (
    "context"
    "time"
    "github.com/google/uuid"
)

// Machine represents a machine in a cluster
type Machine struct {
    ID          uuid.UUID    `json:"id" db:"id" apidoc:"public"`
    ClusterID   uuid.UUID    `json:"cluster_id" db:"cluster_id" apidoc:"public"`
    Name        string       `json:"name" db:"name" apidoc:"public"`
    IPAddress   string       `json:"ip_address" db:"ip_address" apidoc:"public"`
    Port        int          `json:"port" db:"port" apidoc:"public"`
    Status      MachineStatus `json:"status" db:"status" apidoc:"public"`
    HealthStatus HealthStatus `json:"health_status" db:"health_status" apidoc:"public"`
    CreatedAt   time.Time    `json:"created_at" db:"created_at" apidoc:"public"`
    UpdatedAt   time.Time    `json:"updated_at" db:"updated_at" apidoc:"public"`
}

// MachineStatus represents the machine status
type MachineStatus string

const (
    MachineStatusActive   MachineStatus = "active"
    MachineStatusInactive MachineStatus = "inactive"
    MachineStatusDraining MachineStatus = "draining"
)

// HealthStatus represents the health status
type HealthStatus string

const (
    HealthStatusHealthy   HealthStatus = "healthy"
    HealthStatusUnhealthy HealthStatus = "unhealthy"
    HealthStatusUnknown   HealthStatus = "unknown"
)

// MachineService provides machine management operations
type MachineService struct {
    repo MachineRepository
}

// AddMachine adds a machine to the cluster
//apidoc:public
func (s *MachineService) AddMachine(ctx context.Context, req *AddMachineRequest) (*Machine, error) {
    // TODO: Implement
    return nil, nil
}

// RemoveMachine removes a machine from the cluster
//apidoc:public
func (s *MachineService) RemoveMachine(ctx context.Context, machineID uuid.UUID) error {
    // TODO: Implement
    return nil
}

// ListMachines lists all machines in a cluster
//apidoc:public
func (s *MachineService) ListMachines(ctx context.Context, clusterID uuid.UUID) ([]Machine, error) {
    // TODO: Implement
    return nil, nil
}

// CheckHealth checks the health of a machine
//apidoc:internal
func (s *MachineService) CheckHealth(ctx context.Context, machineID uuid.UUID) (HealthStatus, error) {
    // TODO: Implement
    return HealthStatusUnknown, nil
}

// AddMachineRequest represents the request to add a machine
type AddMachineRequest struct {
    ClusterID uuid.UUID `json:"cluster_id" apidoc:"public"`
    Name      string    `json:"name" apidoc:"public"`
    IPAddress string    `json:"ip_address" apidoc:"public"`
    Port      int       `json:"port" apidoc:"public"`
}
```

### 自定义命令示例

#### create-service.json

```json
{
  "name": "create-service",
  "description": "Create a new Go service with standard structure",
  "parameters": {
    "name": {
      "type": "string",
      "description": "Service name (e.g., supplier, booking)",
      "required": true
    },
    "path": {
      "type": "string",
      "description": "Package path (e.g., pkg/supplier)",
      "required": false
    }
  },
  "template": "service-template.go",
  "files": [
    "{{path}}/{{name}}.go",
    "{{path}}/{{name}}_test.go",
    "{{path}}/models.go",
    "api/{{name}}_routes.go"
  ]
}
```

## 实战案例 1：文档组织技能

### 场景

项目文档随着功能增加变得杂乱，需要定期整理。

### 使用 docs-organization 技能

```bash
# 使用 Cursor 技能
$ cursor skill run docs-organization

> 📋 Analyzing documentation structure...
>   Found 45 documentation files
>
> 🗂️  Organizing by category...
>   API docs: 15 files
>   Architecture docs: 8 files
>   User guides: 12 files
>   Development docs: 10 files
>
> ✅ Updated README.md with navigation
> ✅ Created docs/api/ directory structure
> ✅ Added cross-references between docs
> ✅ Generated API documentation index
>
> 📊 Statistics:
>   - Total docs: 45
>   - Orphaned docs found: 3
>   - Duplicate content: 2
>   - Outdated docs: 5
>
> 📝 Recommendations:
>   - Merge duplicate: docs/api/endpoints.md and docs/api/routes.md
>   - Update outdated: docs/deployment.md (last updated 2025-08)
>   - Review orphaned: docs/old-integration.md
```

### 技能实现

```yaml
# docs-organization/skill.json
{
  "name": "docs-organization",
  "description": "Organize and clean up project documentation",
  "steps": [
    {
      "name": "scan",
      "action": "find docs/ -type f -name '*.md'",
      "output": "file_list"
    },
    {
      "name": "categorize",
      "action": "analyze_categories",
      "input": "file_list",
      "output": "categories"
    },
    {
      "name": "restructure",
      "action": "move_files",
      "input": "categories"
    },
    {
      "name": "update_index",
      "action": "generate_index",
      "output": "README.md"
    },
    {
      "name": "report",
      "action": "generate_report",
      "output": "docs/org-report.md"
    }
  ]
}
```

## 实战案例 2：集群机器管理

### 场景

为酒店集群系统添加机器管理功能。

### 使用 go-cluster-add-machine 技能

```bash
$ cursor skill run go-cluster-add-machine \
  --cluster-package pkg/cluster \
  --with-health-check \
  --with-retry

> 🔧 Setting up machine management module...
>
> 📂 Analyzing existing cluster module...
>   Found: pkg/cluster/cluster.go
>   Found: pkg/cluster/repository.go
>   Found: api/cluster_routes.go
>
> ✨ Creating Machine model...
>   Created: pkg/cluster/machine.go
>   Added structs: Machine, MachineStatus, HealthStatus
>
> 🚀 Implementing MachineService...
>   Added: AddMachine
>   Added: RemoveMachine
>   Added: ListMachines
>   Added: CheckHealth
>
> 🛣️  Adding API routes...
>   POST   /api/v1/clusters/{id}/machines
>   GET    /api/v1/clusters/{id}/machines
>   GET    /api/v1/clusters/{id}/machines/{machineId}
>   DELETE /api/v1/clusters/{id}/machines/{machineId}
>   POST   /api/v1/clusters/{id}/machines/{machineId}/health-check
>
> 🧪 Generating tests...
>   Created: pkg/cluster/machine_test.go
>   Test coverage: 85%
>
> ✅ Running tests...
>   TestAddMachine: PASS
>   TestRemoveMachine: PASS
>   TestListMachines: PASS
>   TestCheckHealth: PASS
>   TestAddMachineValidation: PASS
>   TestAddMachineRetry: PASS
>
> 📚 Generating documentation...
>   Created: docs/cluster-machine-management.md
>   Generated API docs with `make doc`
>
> ✨ Done! Machine management module ready.
```

### 生成的代码示例

```go
// pkg/cluster/machine.go

// AddMachine adds a machine to the cluster
//apidoc:public
func (s *MachineService) AddMachine(ctx context.Context, req *AddMachineRequest) (*Machine, error) {
    // Validate request
    if err := validateAddMachineRequest(req); err != nil {
        return nil, fmt.Errorf("validation failed: %w", err)
    }

    // Check if cluster exists
    _, err := s.clusterService.GetCluster(ctx, req.ClusterID)
    if err != nil {
        return nil, fmt.Errorf("cluster not found: %w", err)
    }

    // Create machine
    machine := &Machine{
        ID:          uuid.New(),
        ClusterID:   req.ClusterID,
        Name:        req.Name,
        IPAddress:   req.IPAddress,
        Port:        req.Port,
        Status:      MachineStatusActive,
        HealthStatus: HealthStatusUnknown,
        CreatedAt:   time.Now(),
        UpdatedAt:   time.Now(),
    }

    // Save to repository with retry
    err = s.repo.Create(ctx, machine)
    if err != nil {
        return nil, fmt.Errorf("failed to create machine: %w", err)
    }

    // Initial health check
    if s.withHealthCheck {
        go s.performHealthCheck(ctx, machine.ID)
    }

    return machine, nil
}

// CheckHealth checks the health of a machine with retry logic
//apidoc:internal
func (s *MachineService) CheckHealth(ctx context.Context, machineID uuid.UUID) (HealthStatus, error) {
    var lastErr error

    // Retry up to 3 times
    for i := 0; i < s.maxRetries; i++ {
        status, err := s.checkHealthOnce(ctx, machineID)
        if err == nil {
            // Update machine health status
            s.repo.UpdateHealthStatus(ctx, machineID, status)
            return status, nil
        }

        lastErr = err
        if i < s.maxRetries-1 {
            time.Sleep(s.retryDelay)
        }
    }

    // All retries failed
    return HealthStatusUnhealthy, fmt.Errorf("health check failed after %d retries: %w", s.maxRetries, lastErr)
}

func (s *MachineService) checkHealthOnce(ctx context.Context, machineID uuid.UUID) (HealthStatus, error) {
    machine, err := s.repo.Get(ctx, machineID)
    if err != nil {
        return HealthStatusUnknown, err
    }

    // Perform actual health check
    healthy, err := s.healthChecker.Check(ctx, machine.IPAddress, machine.Port)
    if err != nil {
        return HealthStatusUnhealthy, err
    }

    if healthy {
        return HealthStatusHealthy, nil
    }
    return HealthStatusUnhealthy, nil
}
```

## 实战案例 3：供应商接入流程

### 场景

创建完整的供应商接入工作流。

### 完整流程

```bash
# Step 1: 使用 supplier-onboarding 技能
$ cursor skill run supplier-onboarding

> 🏢 Starting supplier onboarding setup...
>
> ✨ Creating registration module...
>   Created: pkg/supplier/registration.go
>   Added: RegisterSupplier, ValidateBusinessLicense
>
> 🔑 Creating API key management...
>   Created: pkg/supplier/apikey.go
>   Added: GenerateAPIKey, RevokeAPIKey, ListAPIKeys
>
> ⚙️  Creating initial setup...
>   Created: pkg/supplier/setup.go
>   Added: ConfigureInitialSettings
>
> 📧 Creating notification module...
>   Created: pkg/supplier/notification.go
>   Added: SendWelcomeEmail, SendOnboardingChecklist
>
> 🛣️  Adding API routes...
>   POST /api/v1/suppliers/register
>   POST /api/v1/suppliers/{id}/api-keys
>   GET  /api/v1/suppliers/{id}/api-keys
>
> 🧪 Generating tests...
>   Test coverage: 78%
>
> ✅ All tests passed!

# Step 2: 生成文档
$ make doc

> 📚 Generating API documentation...
>   Scanning source files...
>   Extracting API metadata...
>   Generating OpenAPI spec...
>   Generating markdown docs...
>
>   ✅ Generated 25 API endpoints
>   ✅ Created docs/api/supplier.md
>   ✅ Updated docs/api/index.md

# Step 3: 运行集成测试
$ make test-integration

> 🧪 Running integration tests...
>   TestSupplierRegistration: PASS
>   TestAPIKeyGeneration: PASS
>   TestWelcomeEmail: PASS
>   TestFullOnboardingFlow: PASS
>
>   ✅ All integration tests passed
```

### 生成的完整示例

```go
// pkg/supplier/registration.go

// RegisterSupplier registers a new supplier
//apidoc:public
//apidoc:zh 注册新供应商
func (s *SupplierService) RegisterSupplier(ctx context.Context, req *RegisterSupplierRequest) (*Supplier, error) {
    // Validate business license
    if err := s.ValidateBusinessLicense(ctx, req.BusinessLicense); err != nil {
        return nil, fmt.Errorf("invalid business license: %w", err)
    }

    // Check for duplicate
    exists, err := s.repo.ExistsByEmail(ctx, req.Email)
    if err != nil {
        return nil, fmt.Errorf("failed to check supplier existence: %w", err)
    }
    if exists {
        return nil, ErrSupplierAlreadyExists
    }

    // Create supplier
    supplier := &Supplier{
        ID:            uuid.New(),
        Name:          req.Name,
        Email:         req.Email,
        BusinessLicense: req.BusinessLicense,
        Status:        SupplierStatusPendingApproval,
        CreatedAt:     time.Now(),
    }

    if err := s.repo.Create(ctx, supplier); err != nil {
        return nil, fmt.Errorf("failed to create supplier: %w", err)
    }

    // Generate API key
    apiKey, err := s.apiKeyService.GenerateAPIKey(ctx, supplier.ID)
    if err != nil {
        return nil, fmt.Errorf("failed to generate API key: %w", err)
    }

    // Configure initial settings
    if err := s.ConfigureInitialSettings(ctx, supplier.ID, DefaultSupplierConfig); err != nil {
        return nil, fmt.Errorf("failed to configure initial settings: %w", err)
    }

    // Send welcome email (async)
    go s.SendWelcomeEmail(supplier)

    return supplier, nil
}
```

## 配置最佳实践

### 1. 层次化配置

```
CLAUDE.md (项目级)
    ↓
rules/go-conventions.md (语言级)
    ↓
prompts/*.tpl (模板级)
    ↓
tasks/*.md (任务级)
```

### 2. 版本控制

```bash
# 配置文件也应该版本控制
.claude/
.cursor/
.ccm_config/

# 但不要提交敏感信息
.claude/secrets/  # .gitignore
.cursor/local/    # .gitignore
```

### 3. 持续优化

```markdown
# 在 .claude/MAINTENANCE.md 中记录
## Configuration Updates
- 2026-01-15: Added API doc standards
- 2026-01-20: Updated error handling rules
- 2026-02-01: Added DDD guidelines
```

## 效率提升

### 开发时间对比

| 任务 | 传统方式 | 使用技能 | 提升 |
|------|----------|----------|------|
| 创建服务 | 2h | 10min | 92% ↓ |
| 添加 API 路由 | 30min | 2min | 93% ↓ |
| 生成测试 | 1h | 5min | 92% ↓ |
| 文档更新 | 45min | 3min | 93% ↓ |

### 代码质量指标

| 指标 | 传统方式 | 使用技能 | 改进 |
|------|----------|----------|------|
| 代码规范符合度 | 70% | 98% | +40% |
| 测试覆盖率 | 45% | 85% | +89% |
| 文档完整性 | 60% | 95% | +58% |

## 总结

Claude Code 和 Cursor 的深度集成通过以下方式提升了我们的开发效率：

1. **结构化配置**：.claude/ 和 .cursor/ 提供了清晰的配置层次
2. **可复用技能**：技能系统允许封装常见工作流
3. **自动化工作流**：减少重复性手动操作
4. **代码一致性**：统一的规则和模板保证代码质量

下一篇文章将深入探讨多模型与工具链集成。

---

**系列导航：**

- [← Article 1: 从 DeepSeek 复制粘贴到 Claude Code]({% post_url 2026-02-09-ai-coding-practice-1-deepseek-to-claude-code %})
- [→ Article 3: 多模型与工具链集成]({% post_url 2026-02-11-ai-coding-practice-3-multi-model-toolchain %})

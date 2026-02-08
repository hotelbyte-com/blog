---
layout: post
title: OpenSpec-Driven Development
date: 2026-02-12 00:00:00 +0800
categories: [AI Coding, Hospitality Industry, Development Practice]
tags: [OpenSpec, Spec-Driven Development, DDD, Testing, Proposal Workflow, HotelByte]
author: HotelByte Team
description: In-depth exploration of OpenSpec spec-driven development practices in HotelByte project, including proposal workflow, spec definition, implementation standards, DDD alignment, and testing standards.
reading_time: 15
lang: en
series: AI Coding Practices
series_index: 4
---

# OpenSpec-Driven Development

![OpenSpec Workflow](/images/openspec-workflow.png)

## Introduction

In early stages of HotelByte project, we faced a typical problem: **requirements and implementation often misaligned**. Product managers proposed requirements, developers understood them, but final delivery didn't match expectations. Additionally, code review often became arguments about "why" rather than "how to do better."

To solve this problem, we introduced OpenSpec — a spec-driven development framework. This article will dive deep into how OpenSpec works, its application in the HotelByte project, and how it helped us establish a more standardized development process.

## Code-as-Documentation: httpdispatcher + make doc

### Core Innovation of Forward-Thinking Design

In the OpenSpec workflow, we identified an important bottleneck: **high documentation writing and maintenance costs, and easy detachment from code**.

To solve this problem, we built a unique "code-as-documentation" system, achieving full automatic synchronization of code, documentation, routing, and testing through **httpdispatcher + make doc**.

### Core Philosophy

> **"Code-as-Documentation" isn't just "code includes comments", but metadata-driven automatic synchronization of code, documentation, testing, and routing.**

### Workflow

```
Developer writes code with metadata comments
         ↓
AST parsing (build/api/asthelper/)
         ↓
httpdispatcher + make doc
         ↓
Runtime routing table + OpenAPI documentation
```

### Metadata Comment System

The system uses lightweight comment tags to control documentation visibility and routing configuration:

- **Type Visibility**: Control which types/enum values appear in public vs internal docs
- **Method Metadata**: Extract routing, auth, permission, cache settings from comments
- **Multi-Language Support**: Generate docs for multiple languages from single source

**Examples of Metadata Usage:**

Type visibility tags control documentation scope:
- Public docs show only customer-facing APIs
- Internal docs show all implementation details

Method metadata allows httpdispatcher to automatically:
- Configure JWT authentication
- Set permission checks
- Apply caching policies
- Generate OpenAPI specifications
- Bind routes to handlers

### Document Generation

#### Commands

```bash
# Generate all documentation
make doc

# Generate only public documentation
make doc-public

# Generate only internal documentation
make doc-internal
```

### Actual Effect Data

| Metric | Manual Maintenance | Code-as-Documentation | Improvement |
|--------|-------------------|----------------------|-------------|
| Documentation maintenance time | 4-6 hours/week | 0 hours/week | **100%** |
| Documentation accuracy | 60-70% | 100% | **+40%** |
| API change sync delay | 2-3 days | Real-time | **Instant** |
| Multi-language doc maintenance | 8-10 hours/week | 0 hours/week | **100%** |
| SDK generation time | Manual 2-3 days | Auto 5 minutes | **99%** |

### make doc vs Swagger Comparison

| Dimension | Swagger | make doc |
|-----------|---------|----------|
| **Code location** | Separate files (swagger.yaml/swagger.json) | Within code comments |
| **Maintenance cost** | Manual sync between code and docs | Auto-sync, no extra maintenance |
| **Boilerplate code** | Manual API definitions for all endpoints | Auto-extracted from code |
| **Type safety** | Manual definitions, error-prone | Directly uses Go types |
| **Visibility control** | By file separation | By comment tags |
| **Multi-language support** | Multiple manual versions | Auto-generated from single source |
| **Best use case** | External API documentation | Internal APIs + Documentation |
| **Learning curve** | Requires learning Swagger spec | Minimal (just code comments) |

**Key Advantages of make doc:**

1. **Code-First**: Documentation stays in sync because it's derived from code
2. **Type Safety**: No mismatch between docs and actual types
3. **Developer Experience**: Just write code, docs are generated automatically
4. **Governance Integration**: httpdispatcher uses same metadata for routing
5. **Multi-Output**: Single source generates OpenAPI, Markdown, routing configs

**Note:**

`make doc` is an internal tool for the HotelByte project and is still under active development. We plan to consider open-sourcing it once the implementation reaches maturity. Follow our GitHub repository for updates.

## Three-Stage Workflow

OpenSpec defines a clear three-stage workflow:

```
Stage 1: Creating Changes (Creating Proposals)
    ↓
Stage 2: Implementing Changes (Implementing)
    ↓
Stage 3: Archiving Changes (Archiving)
```

### Stage 1: Creating Changes

#### Triggers

Scenarios requiring change proposals:

- ✅ Adding new features or capabilities
- ✅ Breaking changes (API, data structures)
- ✅ Architecture or pattern changes
- ✅ Performance optimizations (affecting behavior)
- ✅ Security pattern updates

Scenarios NOT requiring proposals:

- ❌ Bug fixes (restoring intended behavior)
- ❌ Typos, formatting, comments
- ❌ Non-breaking dependency updates
- ❌ Configuration changes
- ❌ Tests for existing behavior

### Stage 2: Implementing Changes

#### Implementation Process

1. **Read proposal** - Understand change goals and scope
2. **Read design** (if exists) - Understand technical decisions
3. **Read task list** - Get implementation checklist
4. **Implement sequentially** - Complete tasks in order
5. **Confirm completion** - Ensure all tasks finished
6. **Update checklist** - Set all tasks to completed
7. **Approval gate** - Don't start implementation until proposal approved

#### Completion Definition

**Key Principle:**

> **Requirement Completion = Functional Code + Unit Tests (UT) + E2E Tests All Passing!**

### Stage 3: Archiving Changes

After deployment, create separate PR to archive changes.

## DDD Alignment

### DDD Directory Structure

OpenSpec perfectly aligns with DDD architecture:

```
hotel/
├── domain/           # Domain layer (core business logic)
├── protocol/         # Protocol layer (API definitions)
├── mysql/            # Data access layer
└── service/          # Service layer
```

### Development Order

OpenSpec forces development in DDD order:

```
1. domain/      ← First write domain logic
   ↓
2. protocol/   ← Then define protocols
   ↓
3. mysql/      ← Then write DAO
   ↓
4. service/    ← Finally write services
```

## Testing Standards

### Coverage Requirements

| Layer | Coverage Goal | Description |
|-------|--------------|-------------|
| **domain/** | 100% | All domain logic must have tests |
| **mysql/** (DAO) | 80%+ | All CRUD must have tests |
| **service/** | 70%+ | Core business logic must have tests |
| **convert/** | 90%+ | All conversion functions must have tests |
| **protocol/** | Not required | Data structures only, no tests needed |

**PR mandatory check:** Incremental code test coverage must ≥ 50%

### Unit Test Framework

**Framework:** `github.com/bytedance/mockey` + `github.com/smartystreets/goconvey`

**Test Template:**

```go
func TestService_Method_Success(t *testing.T) {
    mockey.PatchConvey("Description", t, func() {
        // 1. Setup - Prepare test data
        ctx := context.Background()

        // 2. Mock - Mock external dependencies
        mockey.Mock((*DAO).Method).Return(expected, nil).Build()

        // 3. Execute - Execute function being tested
        result, err := service.Method(ctx, input)

        // 4. Assert - Verify results
        convey.So(err, convey.ShouldBeNil)
        convey.So(result, convey.ShouldEqual, expected)
    })
}
```

### E2E Testing

**Test location:** `api/tests/`

**Test tool:** Use `sdk/go` to call real API

**Test scenarios:** Must cover core business flows

## Best Practices

### 1. Proposal Writing

- ✅ Clearly describe "why"
- ✅ Explicitly list "what"
- ✅ Identify all impacts
- ✅ Assess risks

### 2. Spec Definition

- ✅ Use ADDED/MODIFIED/REMOVED
- ✅ Each requirement has at least one Scenario
- ✅ Scenarios use GWT format (Given-When-Then)
- ✅ Clear success and failure scenarios

### 3. Task Management

- ✅ Tasks are quantifiable
- ✅ Reasonable order
- ✅ Include tests
- ✅ Update status

### 4. Implementation Quality

- ✅ Follow DDD order
- ✅ Write complete tests
- ✅ Ensure coverage meets standards
- ✅ Run all checks

### 5. Archiving Workflow

- ✅ Archive immediately after deployment
- ✅ Update spec files
- ✅ Run validation
- ✅ Clean up temporary files

## Series Navigation

1. [From DeepSeek Copy-Paste to Claude Code](2026-02-09-ai-coding-hotelbyte-journey-from-deepseek-to-claude-code.md)
2. [Deep Claude Code Integration](2026-02-10-ai-coding-claude-code-integration.md)
3. [Multi-Model and Toolchain Integration](2026-02-11-ai-coding-multi-model-integration.md)
4. [OpenSpec-Driven Development](2026-02-12-ai-coding-openspec-driven-development.md) ✅ (This article)
5. [AI Coding Best Practices](2026-02-13-ai-coding-best-practices.md)

---

**Related Resources:**

- [OpenSpec GitHub](https://github.com/openspec/openspec)
- [OpenSpec Workflow Guide](/docs/openspec/workflow.md)
- [DDD Architecture Guide](/docs/architecture/ddd.md)

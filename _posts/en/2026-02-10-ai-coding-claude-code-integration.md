---
layout: post
title: Deep Claude Code Integration
date: 2026-02-10 00:00:00 +0800
categories: [AI Coding, Hospitality Industry, Development Practice]
tags: [AI, Claude Code, .cursor, Skills, Rules, HotelByte]
author: HotelByte Team
description: In-depth exploration of Claude Code integration in the HotelByte project, including .cursor directory structure, skills system, rules definition, and real-world application cases.
reading_time: 13
lang: en
series: AI Coding Practices
series_index: 2
---

# Deep Claude Code Integration

![Claude Code Integration](/images/claude-code-integration.png)

## Introduction

In the previous article "From DeepSeek Copy-Paste to Claude Code", we described HotelByte's evolution from chaotic AI coding to structured practices. This article will dive deep into the specifics of Claude Code integration, showing how to make AI truly "understand" and participate in project development through the .cursor directory, skills system, and rules definition.

## .cursor Directory Structure Deep Dive

### Directory Overview

The .cursor directory structure in the HotelByte project is as follows:

```
.cursor/
├── plans/                          # Development plans
│   ├── docs目录整合计划_3ca2c74e.plan.md
│   ├── nginx_header_routing_plugin_d0dd6b5b.plan.md
│   └── plans/                      # Subdirectory
│       ├── 优化下单可靠性_10dd4510.plan.md
│       ├── session_key_按_credential_id_拆分_92e6fa72.plan.md
│       └── ...
├── skills/                         # Skill definitions
│   ├── go-cluster-add-machine/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── supplier-onboarding/
│   │   ├── SKILL.md
│   │   └── reference.md
│   ├── docs-organization/
│   │   └── SKILL.md
│   └── e2e-test-design.md
├── rules/                          # Rules definition
│   ├── docs-organization.mdc
│   └── mece-7plus2.mdc
└── commands/                       # Commands definition (moved to .claude)
    └── (大部分已移至 .claude/commands/)
```

### Plan Management (plans/)

The `.cursor/plans/` directory stores all project development plans, each with a unique ID.

#### Typical Plan Example

`优化下单可靠性_10dd4510.plan.md`:

```markdown
# 优化下单可靠性

## Background
The current booking process has timeout and duplicate booking issues under high concurrency, affecting user experience.

## Goals
1. Reduce booking timeout rate from 3% to below 0.5%
2. Implement idempotency to prevent duplicate bookings
3. Optimize error handling and retry mechanisms

## Solution
- Introduce distributed locks to prevent duplicate bookings
- Implement request deduplication
- Optimize database transaction logic
- Add monitoring and alerting

## Implementation Steps
1. Design idempotency solution
2. Implement distributed locks
3. Refactor booking logic
4. Write unit tests
5. Perform stress testing
6. Deploy monitoring

## Acceptance Criteria
- [ ] Timeout rate < 0.5%
- [ ] No duplicate bookings
- [ ] Unit test coverage ≥ 80%
- [ ] E2E tests all pass
```

### Skills System (skills/)

Skills are reusable AI capability definitions, each with clear usage scenarios and reference documents.

#### Skill Structure Template

Each skill directory contains:

```
skills/{skill-name}/
├── SKILL.md         # Skill definition (required)
└── reference.md     # Reference material (optional)
```

#### Case 1: go-cluster-add-machine Skill

**Usage Scenario**: Add new machine to Go server cluster, deploy application, and route traffic

**SKILL.md Core Content**:

```markdown
---
name: go-cluster-add-machine
description: Add a new machine to hotel-be Go server cluster, deploy the app, and put traffic (or keep as backup).
---

# Go Cluster New Machine and Traffic Routing

## Prerequisites
- Server access privileges
- Understanding of Go service deployment
- Nginx configuration experience

## Complete Workflow

### 1. Configuration File Update

**servers.conf**
```bash
# build/deploy/servers.conf
s1=108.181.252.211  # New server
```

**SSH Configuration**
```bash
# build/deploy/configs/sshconfig
Host s1
    HostName 108.181.252.211
    User administrator
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

### 2. Server Initialization

```bash
# Use automated script
./build/deploy/init_server.sh s1 108.181.252.211 administrator '@!%yvAR63m'

# Script automatically completes:
# - SSH passwordless configuration
# - Cluster server interconnection
# - Dependency installation (Git, Go, Supervisor)
# - GitHub authentication and repository cloning
# - Network performance testing
```

### 3. Database Whitelist Configuration (Critical!)

```bash
# Execute on db server
NEW_IP="108.181.252.211"

# 1. Firewall configuration
sudo iptables -I INPUT -p tcp -s $NEW_IP --dport 3306 -j ACCEPT
sudo iptables -I INPUT -p tcp -s $NEW_IP --dport 6379 -j ACCEPT

# 2. MySQL user authorization
sudo mysql --defaults-file=/etc/mysql/debian.cnf -e "
CREATE USER IF NOT EXISTS 'hotel'@'$NEW_IP' IDENTIFIED BY 'Hotel2025!';
GRANT ALL PRIVILEGES ON hotel.* TO 'hotel'@'$NEW_IP';
FLUSH PRIVILEGES;
"
```

### 4. Deploy Application

```bash
# Deploy to specified server
./build/deploy/prod.sh --deploy --servers s1
```

### 5. Route Traffic (Optional)

```bash
# Edit Nginx upstream
# build/deploy/configs/nginx/upstream.conf
upstream hotel_api {
    server 108.181.252.211:8080 weight=1;  # New node
    server 93.127.137.195:8080 weight=1;
}
```

## Acceptance Checklist

- [ ] SSH passwordless login successful
- [ ] Network performance test passed
- [ ] Database connection normal
- [ ] Service startup successful
- [ ] Health check passed
- [ ] Traffic routing successful (if required)
```

### Case 2: supplier-onboarding Skill

**Usage Scenario**: Supplier onboarding, following Platform → Tenant → Customer three-layer model

**Core Three-Layer Model**:

```
Layer 1: Platform Access → Layer 2: Tenant Open → Layer 3: Customer Open
```

## Settings and Configuration

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

## Best Practices

### 1. Skill Development

- ✅ Skill name clearly describes usage scenario
- ✅ Includes detailed steps and parameters
- ✅ Provides actual code examples
- ✅ Includes acceptance checklist

### 2. Agent Design

- ✅ Clear role and responsibilities
- ✅ Define expertise areas
- ✅ Associate related tools and skills
- ✅ Keep focused and specialized

### 3. Command Design

- ✅ Command name clear (verb-led)
- ✅ Detailed usage scenario description
- ✅ Clear parameter and output format
- ✅ Includes examples

## Series Navigation

1. [From DeepSeek Copy-Paste to Claude Code](2026-02-09-ai-coding-hotelbyte-journey-from-deepseek-to-claude-code.md)
2. [Deep Claude Code Integration](2026-02-10-ai-coding-claude-code-integration.md) ✅ (This article)
3. [Multi-Model and Toolchain Integration](2026-02-11-ai-coding-multi-model-integration.md)
4. [OpenSpec-Driven Development](2026-02-12-ai-coding-openspec-driven-development.md)
5. [AI Coding Best Practices](2026-02-13-ai-coding-best-practices.md)

---

**Related Resources:**

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [OpenSpec Workflow Guide](/docs/openspec/workflow.md)
- [HotelByte GitHub Repository](https://github.com/hotelbyte-com/hotel-be)

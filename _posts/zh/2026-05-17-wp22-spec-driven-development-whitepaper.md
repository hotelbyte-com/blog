---

layout: post
title: "英文 canonical 原文：规格驱动开发白皮书"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [酒店 API, 白皮书, 架构]
author: "HotelByte Team"
description: "HotelByte 技术白皮书原文已发布到博客，便于公开阅读、引用和分享。"
lang: zh
permalink: /zh/whitepapers/wp22-spec-driven-development/original/
whitepaper_kind: original
guide_url: /zh/whitepapers/wp22-spec-driven-development/
---

<div class="whitepaper-reader-note">
  <strong>阅读路径：</strong>这是英文 canonical 原文页。中文导读在 <a href="/zh/whitepapers/wp22-spec-driven-development/">读者视角导读</a>；完整系列在 <a href="/zh/whitepapers/">HotelByte 技术白皮书系列</a>。下方发布英文 canonical whitepaper 全文，避免再跳转到仓库相对目录。
</div>

# 英文 canonical 原文：规格驱动开发白皮书

> 本页为公开博客版白皮书原文。当前 canonical 全文以英文维护，中文导读负责解释读者视角和业务价值；英文 canonical URL 为 [/whitepapers/wp22-spec-driven-development/original/](/whitepapers/wp22-spec-driven-development/original/)。

# Spec-Driven Development Whitepaper

## Executive Summary

HotelByte operates a global hotel API distribution platform connecting thousands of suppliers and buyers across diverse markets, each with distinct business rules, regulatory requirements, and service-level expectations. In this environment, undocumented assumptions and implicit requirements are the primary sources of production defects, integration mismatches, and costly rework.

To address this, HotelByte has adopted **Spec-Driven Development (SDD)**—a disciplined workflow where every change originates from a written specification, every requirement is expressed as a verifiable scenario, and no implementation proceeds without an approved, versioned spec. This approach transforms requirements from tribal knowledge into durable, testable contracts.

The result is measurable: requirements ambiguity is caught during the proposal phase rather than in production; regression tests are generated directly from specifications; and every deployed change carries a complete, auditable chain from business intent to verified behavior.

## Scope

This whitepaper describes HotelByte's spec-driven development methodology as applied to platform changes—encompassing API contract modifications, supplier integration updates, booking workflow enhancements, and operational control changes. It covers the full lifecycle from proposal through implementation to archival, with emphasis on how specifications drive verification and auditability.

The practices described here govern all material changes to the HotelByte platform. Trivial changes—such as documentation typo fixes or configuration value updates within existing boundaries—may follow a lightweight path, but still require explicit scenario coverage when they affect externally observable behavior.

## Objectives

The SDD program at HotelByte pursues four objectives:

1. **Eliminate Ambiguity Before Coding.** Every requirement is expressed in structured prose with executable scenarios before engineering effort is expended. This prevents the most expensive class of defect: the one built on a misunderstood requirement.

2. **Guarantee Verifiability.** No requirement is considered complete unless it includes at least one scenario describing an observable outcome. This bridges the gap between "the code was written" and "the behavior is correct."

3. **Minimize Change Surface.** Each change is scoped to the smallest verifiable unit that delivers customer value. Large, speculative changes are decomposed into smaller, independently specified proposals.

4. **Maintain Permanent Auditability.** Every change leaves a durable, time-ordered record linking business justification, technical design, specification, implementation, and verification results. This supports regulatory review, security audits, and post-incident analysis.

## Design Principles

HotelByte's spec-driven workflow is built on five design principles derived from requirements engineering, behavior-driven development, and systems safety disciplines:

**Specification Before Implementation.** A proposal and its associated specifications must exist and be approved before implementation begins. This is a hard gate: the spec is the contract, and code is the fulfillment of that contract—not the other way around.

**Verifiable Requirements.** Every requirement statement must be coupled to at least one Gherkin-style scenario describing a concrete WHEN/THEN condition. Vague aspirations such as "improve performance" or "make it more robust" are rejected until they are translated into measurable, testable claims.

**Minimal Change Surface.** Changes are decomposed until the default implementation fits within a single, focused artifact. This reduces review burden, limits blast radius, and makes rollback decisions straightforward. Prohibited patterns include open-ended refactoring without specification, version suffixes that obscure intent (V2, Enhanced), and safety-qualified names that substitute for actual safety analysis.

**MECE Documentation Architecture.** All documentation is organized according to the MECE principle—Mutually Exclusive, Collectively Exhaustive. At each directory level, the number of entries is bounded by the 7±2 rule (five to nine items). This prevents information overload and ensures that any engineer can locate the authoritative spec for a given capability within three navigational steps.

**Definition of Done as a Proof.** Completion is not declared when code is merged. It is declared when functional code, unit tests, and end-to-end tests all pass against the scenarios defined in the specification. The spec is the oracle; the tests are the evidence.

## Spec-Driven Workflow Architecture

HotelByte's SDD workflow is organized as a four-layer architecture, each layer with distinct responsibilities, entry criteria, and exit criteria.

### Proposal Layer

Every change begins with a proposal document that answers three questions: Why, What, and Impact. The proposal identifies the business or technical problem, defines the scope of the proposed solution, and enumerates the stakeholders affected. Proposals are numbered and stored in a changes directory, ensuring that every initiative has a stable identifier before engineering resources are allocated.

The proposal layer serves as the intake gate. An incomplete proposal—one lacking clear impact statements or stakeholder identification—is returned for revision rather than advanced to specification. This lightweight filter prevents the pipeline from filling with poorly understood work.

### Specification Layer

Once a proposal is accepted, it is elaborated into three coordinated artifacts: a task breakdown, a technical design document, and capability-specific specifications.

The task breakdown decomposes the proposal into actionable, independently verifiable units of work. The technical design document describes the architectural approach, interface changes, data model updates, and operational considerations. The capability specifications contain the authoritative behavior definitions: for each affected capability, a spec document captures the requirements and their associated Gherkin scenarios.

The specification layer enforces the verifiability principle. A requirement that cannot be scenario-tested is treated as incomplete. Reviewers at this layer are explicitly tasked with challenging ambiguity: every "should," "may," and "appropriate" is flagged for clarification.

### Implementation Layer

Implementation proceeds only after the specification layer is approved. Engineers implement against the spec, not against the proposal or informal discussion. Unit tests are written to exercise the scenarios at the component level. End-to-end tests validate the complete user-visible behavior. Both test suites reference the spec scenarios by identifier, creating a traceable link from requirement to test result.

The implementation layer does not permit deviation from the approved spec without a specification amendment. If implementation reveals that the spec is incorrect, the spec is revised and re-approved before code is updated. This prevents the common anti-pattern where code becomes the de facto specification and the written spec drifts into irrelevance.

### Archive Layer

After deployment, the complete change record—proposal, tasks, design, specifications, test results, and deployment confirmation—is archived in a date-stamped directory. This creates a permanent, immutable snapshot of what was approved, what was built, and what was verified.

The archive layer is not a casual filing system. It is the authoritative historical record used for post-incident investigation, compliance auditing, and cross-functional review. The archival structure mirrors the active changes layout, ensuring that any engineer can navigate from a current capability spec to its historical antecedents using identical paths.

## Change Lifecycle

A typical change progresses through the following lifecycle, with explicit gates at each transition:

1. **Proposal Drafting.** Author writes the proposal addressing Why, What, and Impact.
2. **Proposal Review.** Peers and stakeholders review for clarity, scope, and alignment.
3. **Specification Development.** Author creates tasks, design, and capability specs with scenarios.
4. **Specification Review.** Technical reviewers verify completeness, testability, and MECE compliance.
5. **Implementation.** Engineers write code and tests against the approved spec.
6. **Verification.** Automated and manual tests confirm all scenarios pass.
7. **Deployment.** Change is promoted through environments with automated checks.
8. **Archival.** Complete record is moved to the archive layer with deployment timestamp.

Rejection at any review gate returns the change to the preceding layer for revision. There are no bypass paths.

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| **Three-Stage Gate** (Proposal → Spec → Archive) | Ensures every production change has traceable justification, design, and verification—reducing unexpected breaking changes and enabling rapid impact assessment. |
| **Scenario Enforcement** (Gherkin WHEN/THEN per requirement) | Guarantees that every business rule has an observable, testable outcome—preventing silent failures and ensuring that what was promised is what was delivered. |
| **MECE Documentation with 7±2 Rule** | Enables customers and partners to locate authoritative interface specifications quickly, reducing integration friction and support inquiries. |
| **Minimal Change Surface** | Limits the blast radius of each deployment, improving platform stability and reducing the window of exposure during rollouts. |
| **Definition of Done** (Code + Unit Tests + E2E Tests Passing) | Provides confidence that declared capabilities are actually working in production, not merely present in source control. |
| **Permanent Archive Layer** | Supports compliance inquiries, security audits, and incident investigations with complete, immutable change history. |

## Auditability

Auditability in the HotelByte SDD workflow rests on three verification methods:

**Scenario Traceability.** Every requirement scenario is assigned a stable identifier that appears in both the specification document and the automated test suite. Test execution reports include these identifiers, enabling auditors to confirm that every specified behavior is exercised on every build.

**Three-Independent-Approval Review.** Proposals, specifications, and designs each require independent review before advancement. The review history—including reviewer identity, timestamp, and resolution—is preserved in version control, creating a non-repudiable record of scrutiny.

**Immutable Archive Snapshots.** Post-deployment, the entire change record is snapshotted to the archive layer with a date prefix. These archives are write-once: no subsequent modification is permitted. In the event of an incident or audit, the exact specification and verification evidence that governed a deployment can be retrieved without ambiguity.

Together, these methods ensure that any change can be traced from business intent through specification, implementation, verification, and deployment—and that this trace is durable, inspectable, and tamper-evident.

## Authoritative Source References

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **ISO/IEC/IEEE 29148:2018** — *Systems and software engineering — Life cycle processes — Requirements engineering* | "Requirements shall be expressed in a manner that avoids ambiguity and is verifiable." | The Scenario Enforcement control requires every requirement to include a Gherkin-style WHEN/THEN scenario, directly satisfying the verifiability and ambiguity-avoidance mandates. |
| **Gherkin Language Specification** — *Cucumber.io* | "Gherkin uses a set of special keywords to give structure and meaning to executable specifications. The primary keywords are Feature, Rule, Example (or Scenario), Given, When, Then, And, But." | HotelByte capability specifications adopt Gherkin syntax for scenario expression, ensuring that requirements are structured for both human review and automated test generation. |
| **Behavior-Driven Development: BDD with Cucumber and SpecFlow** — *Gáspár Nagy and Seb Rose* | "BDD is a way for software teams to work that closes the gap between business people and technical people by encouraging collaboration across roles to build a shared understanding of the problem to be solved." | The Three-Stage Gate creates explicit collaboration points between business stakeholders (proposal), technical designers (specification), and engineers (implementation), closing the business-technical gap. |
| **ITIL 4: Change Control Practice** | "The purpose of the change control practice is to maximize the number of successful service and product changes by ensuring that risks have been properly assessed, authorizing changes to proceed, and managing the change schedule." | HotelByte's proposal review gate performs risk assessment and stakeholder alignment; the archive layer maintains the change schedule and historical record; together they implement ITIL-aligned change control. |
| **MECE Principle** — *Barbara Minto, The Pyramid Principle* | "The grouping must be Mutually Exclusive and Collectively Exhaustive... the ideas must not overlap, and they must cover all the relevant possibilities." | Documentation Architecture control applies MECE to capability organization, ensuring that every spec has a single, exhaustive home without overlap or omission. |
| **ISO 9001:2015** — *Quality management systems* | "The organization shall retain documented information to the extent necessary to have confidence that the processes have been carried out as planned." | The Archive Layer and immutable snapshot policy retain complete documented information for every change, providing the evidentiary basis for quality system confidence. |

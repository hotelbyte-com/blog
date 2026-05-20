---
layout: post
title: "Whitepaper: Room Mapping with Shadow Mode Whitepaper"
date: 2026-05-17
categories: [HotelByte, Whitepapers]
tags: [Hotel API, Whitepaper, Architecture]
author: "HotelByte Team"
description: "Full HotelByte technical whitepaper published on the blog for readable public access."
lang: en
permalink: /en/whitepapers/wp16-room-mapping-shadow/original/
whitepaper_kind: original
guide_url: /en/whitepapers/wp16-room-mapping-shadow/
---

<div class="whitepaper-reader-note">
  <strong>Reading path:</strong> this is the full whitepaper. For a shorter reader-facing guide, start with <a href="/en/whitepapers/wp16-room-mapping-shadow/">the blog guide</a>. Browse the full series at <a href="/en/whitepapers/">HotelByte Whitepapers</a>.
</div>

# Room Mapping with Shadow Mode Whitepaper

**Version:** 2.0  
**Classification:** External — Customer-Facing  
**Scope:** HotelByte Room Mapping System  
**Date:** May 2026

---

## Executive Summary

Hotel distribution relies on the accurate alignment of room types between supplier systems and customer-facing search results. A "Double Room with Sea View" from one supplier must correspond to the same physical room category offered by another, even when naming conventions, languages, and attribute schemas differ. Room mapping — the automated reconciliation of heterogeneous room inventories — is therefore a critical competency for any hotel API distribution platform.

This whitepaper describes HotelByte's Room Mapping system, which operates under a **Shadow Mode** safety architecture. In Shadow Mode, candidate mapping algorithms run in parallel with the production system without mutating customer-visible outputs. Algorithms are promoted to production only after they demonstrate statistically significant improvement across precision, recall, F1 score, and latency percentiles against a curated ground-truth corpus. This approach ensures that every mapping decision reaching a customer search result has been validated through layered evaluation gates, human review workflows, and continuous A/B measurement.

The system supports a **Multi-Version Algorithm Matrix** — a portfolio of complementary mapping approaches spanning rule-based feature extraction, multidimensional semantic scoring, and performance-optimized inference pipelines. Each algorithm version is held to the same Shadow Mode contract: observe, evaluate, and only then act.

---

## Scope

This whitepaper covers the following aspects of HotelByte's Room Mapping system:

- **Shadow Mode Architecture** — the safety layer that isolates candidate algorithms from production search responses.
- **Algorithm Portfolio** — the Multi-Version Algorithm Matrix and the distinct technical approaches employed.
- **Offline Evaluation Loop** — pair-based benchmarking, confusion matrix analysis, and automatic winner determination.
- **Annotation & Test Set Management** — human review workflows and auto-corpus construction.
- **Embedding Service** — semantic vector computation for text similarity scoring.
- **Auditability & Controls** — traceability, metrics persistence, and compliance mappings.

This document does not cover supplier onboarding, hotel-level geographic mapping, or real-time pricing logic, which are addressed in separate whitepapers.

---

## Objectives

The Room Mapping system is designed to achieve the following objectives:

1. **Preserve Search Integrity** — No mapping algorithm may modify a `RoomTypeId` or any main-chain search response field until it has met validated confidence thresholds through Shadow Mode evaluation.
2. **Enable Safe Experimentation** — Engineering teams must be able to deploy new algorithms, feature engineering pipelines, and similarity models without risk to customer-facing search accuracy.
3. **Ensure Continuous Measurable Improvement** — Every candidate algorithm is evaluated against a held-out ground-truth test set using standard information-retrieval metrics (Precision, Recall, F1, Rand Index) and latency percentiles (P95).
4. **Maintain Human Oversight** — A structured review workflow (annotated → approved → rejected) governs the construction of the ground-truth corpus, and approved samples automatically enrich the auto-corpus test set.
5. **Guarantee Traceability** — Original supplier room identifiers (via `roomKey`: supplierHotelId + roomCode) are persisted alongside all mapping outputs to prevent evaluation distortion and to enable full retrospective audit.

---

## Design Principles

The following design principles govern the architecture and operation of the Room Mapping system:

### Safety Before Accuracy

No algorithm — regardless of theoretical accuracy — is permitted to influence production search results until it has completed Shadow Mode validation. Safety is enforced by architectural separation, not by convention. The shadow layer is physically incapable of writing to customer-visible response fields.

### Continuous Evaluation

Evaluation is not a one-time certification event. Every algorithm in the matrix is subject to recurring evaluation against an expanding auto-corpus. As new approved annotations enter the test set, previously validated algorithms are re-benchmarked to detect regression.

### Human-in-the-Loop

Automated mapping decisions are probabilistic. The ground-truth corpus is built through a structured human review workflow. Only samples that pass expert review (annotated → approved) enter the auto-corpus. Rejected samples are preserved for error-case analysis and model refinement.

### Multi-Strategy Redundancy

The Multi-Version Algorithm Matrix deliberately employs heterogeneous approaches — lexical, structural, semantic, and price-aware — so that no single failure mode can compromise the entire mapping pipeline. Disagreement between algorithms is itself a signal for downstream confidence scoring.

### Observability by Default

All mapping decisions, algorithm outputs, confidence scores, and latency measurements are written to both real-time monitoring (Prometheus) and persistent relational storage (MySQL `room_mapping_metric`). Dual-metrics writing ensures that transient runtime issues do not result in permanent observability gaps.

---

## Shadow Mode Architecture

The Shadow Mode architecture comprises three logically separated layers: the **Shadow Layer**, the **Algorithm Layer**, and the **Evaluation Layer**.

### Shadow Layer

The Shadow Layer is the safety-critical boundary of the system. It receives the same inputs as the production mapping path — supplier room metadata, search context, and pricing signals — but its outputs are routed exclusively to isolated storage and metrics pipelines. The Shadow Layer cannot write to search response structs, cache entries that affect customer results, or any main-chain persistence.

Key safety guarantees enforced by the Shadow Layer:

- **Immutability Contract:** Candidate algorithms are bound by the `MapperInterface` abstraction, which explicitly disallows mutation of the production `RoomTypeId` field.
- **Sampling Control:** A/B test configuration via `hb_compare_sample_rate` governs the fraction of traffic shadowed for each algorithm. Sampling rates vary by environment to ensure that production shadowing is conservative while staging shadowing is comprehensive.
- **Original Traceability Preservation:** The `roomKey` (composite of `supplierHotelId` and `roomCode`) is persisted alongside every shadow mapping decision. This prevents the substitution of evaluated room identifiers with inferred ones, a common source of evaluation distortion in mapping systems.

### Algorithm Layer

The Algorithm Layer hosts the **Multi-Version Algorithm Matrix** — a portfolio of complementary mapping strategies that operate independently within the Shadow Layer. The matrix is organized by capability rather than by version lineage, reflecting that each approach addresses distinct aspects of the mapping problem.

| Algorithm Dimension | Core Technique | Key Capabilities |
|---|---|---|
| **Lexical-Rule Mapping** | Multilingual keyword feature extraction (en/pt/es/fr) for Capacity, BedType, ViewType, and RoomClass; weighted similarity composition (text 60% + price 20% + feature 20%); hierarchical threshold clustering. | High interpretability; deterministic behavior; strong performance on structured room metadata. |
| **Semantic-Structural Mapping** | Multidimensional semantic feature engineering (ViewScore, ClassScore, AmenityScore, LuxuryScore); multidimensional price normalization (RelativePosition, ZScore, PriceRatio, Segment); three-layer similarity blending (lexical 50% + structural 30% + semantic 20%). | Captures nuanced room descriptions; robust to supplier naming variation; price-aware disambiguation. |
| **Performance-Optimized Inference** | Feature caching with 24-hour Redis TTL; sparse similarity matrix representation reducing complexity from quadratic to near-linear; goroutine pool parallel processing. | Sub-second P95 latency at scale; supports high-throughput shadow evaluation without impacting production QPS. |

Each dimension of the matrix can be evaluated, promoted, or rolled back independently. The matrix design ensures that a regression in one dimension does not invalidate gains in another.

### Evaluation Layer

The Evaluation Layer executes the offline benchmarking pipeline that determines algorithm promotion.

**Pair-Based Evaluation:**  
The `buildPairs()` construct generates exhaustive room pair sets from the ground-truth corpus. For each pair, the algorithm under evaluation predicts a match or non-match decision. These predictions are compared against human-approved labels.

**Metrics Computed:**

| Metric | Purpose |
|---|---|
| **Precision** | Fraction of predicted matches that are true matches. |
| **Recall** | Fraction of true matches that are correctly predicted. |
| **F1 Score** | Harmonic mean of Precision and Recall; primary promotion criterion. |
| **Rand Index** | Agreement between predicted clusters and ground-truth clusters. |
| **P95 Latency** | 95th-percentile inference time; must remain within SLO bounds. |

**Automatic Winner Determination:**  
The `CompareAlgorithms()` function applies a thresholded F1 Score comparison (difference > 0.001) to declare a statistically meaningful winner. Algorithms failing to surpass the incumbent by this margin remain in shadow.

**Confusion Matrix & Error Analysis:**  
Every evaluation produces a full confusion matrix (True Positives, False Positives, True Negatives, False Negatives). Error cases are automatically surfaced for human review and may trigger targeted corpus augmentation.

---

## Mapping Lifecycle

The lifecycle of a room mapping decision at HotelByte follows a gated pipeline:

1. **Ingestion** — Supplier room metadata is normalized and enriched with pricing context.
2. **Shadow Execution** — All algorithms in the active matrix process the room independently within the Shadow Layer.
3. **Metrics Emission** — Shadow outputs, confidence scores, and latency measurements are dual-written to Prometheus and MySQL `room_mapping_metric`.
4. **Ground-Truth Construction** — Annotators review samples through the annotated → approved → rejected workflow. Approved samples enter the auto-corpus.
5. **Offline Evaluation** — The evaluation layer runs `buildPairs()`, computes Precision/Recall/F1/Rand Index/P95, and executes `CompareAlgorithms()`.
6. **Promotion Gate** — An algorithm is promoted to production eligibility only if it exceeds the incumbent F1 Score by > 0.001 and satisfies latency SLOs.
7. **Production Activation** — Promoted algorithms are gradually ramped via controlled sampling before full deployment.
8. **Continuous Monitoring** — Post-promotion, algorithms remain subject to ongoing auto-corpus re-evaluation to detect drift or regression.

---

## Implemented Control Summary

| Control | Customer Value |
|---|---|
| **Shadow Mode Safety Boundary** | Customer search results are insulated from unvalidated algorithm outputs. Mapping decisions cannot reach production without completing independent offline evaluation. |
| **Multi-Version Algorithm Matrix** | No single algorithm failure mode can compromise mapping quality. Heterogeneous approaches provide redundancy and enable selective promotion of best-performing strategies. |
| **Dual Metrics Writing (Prometheus + MySQL)** | Complete observability of mapping behavior is preserved even in the event of transient monitoring system failure. Customers benefit from consistent, auditable decision trails. |
| **Original Room Key Traceability (`roomKey`)** | Every mapping decision is linked to its original supplier identifier, preventing silent substitution and enabling accurate retrospective audit and dispute resolution. |
| **Automatic Winner Determination (F1 Δ > 0.001)** | Algorithm promotion is governed by an objective, reproducible statistical threshold rather than subjective judgment, ensuring only measurably superior algorithms influence customer results. |
| **Structured Annotation Workflow (annotated → approved → rejected)** | The ground-truth corpus is built through expert-reviewed samples, ensuring that evaluation benchmarks reflect human-validated reality rather than algorithmic self-reference. |
| **Auto-Corpus Enrichment** | The test set continuously expands as approved annotations accumulate, preventing evaluation stagnation and ensuring that algorithms are tested against representative, current inventory patterns. |
| **Embedding Service with LRU Cache & Hit Rate Statistics** | Semantic similarity computation is performed efficiently with bounded latency and observable cache performance, supporting scalable room description comparison without external service degradation. |
| **A/B Sampling Rate Control (`hb_compare_sample_rate`)** | Shadow evaluation load is tuned per environment, ensuring that production traffic is never materially impacted by shadow computation overhead. |
| **Confusion Matrix & Error Case Analysis** | Systematic identification of false positive and false negative patterns drives targeted algorithm improvement and maintains transparency into failure modes. |

---

## Auditability

Auditability is a first-class requirement of the Room Mapping system. HotelByte provides the following verification methods:

- **Decision Traceability:** Every shadow and production mapping output is associated with a unique trace identifier, the originating `roomKey`, the algorithm version that produced it, the confidence score, and the Unix timestamp of the decision.
- **Metrics Persistence:** MySQL `room_mapping_metric` tables retain historical evaluation results, confusion matrices, and latency distributions for the lifetime of the data retention policy. This supports longitudinal trend analysis and regulatory audit.
- **Corpus Provenance:** Each entry in the auto-corpus test set carries metadata including review status, annotator identifier, supplier, and country distribution. Test set statistics are reported by review status, case type, supplier, and geography.
- **Embedding Audit Log:** The embedding service tracks batch processing identifiers, cache hit rates, and similarity computation outputs. LRU cache statistics (hit rate, eviction count) are emitted to monitoring for capacity planning and quality assurance.
- **Promotion Log:** Every algorithm promotion or rollback event is logged with the incumbent F1 Score, the challenger F1 Score, the computed delta, and the evaluation timestamp. This creates an immutable record of why a given algorithm version was activated.

Customers and auditors may request structured exports of mapping metrics, corpus statistics, and promotion logs through HotelByte's standard compliance channels.

---

## Authoritative Source References

The following authoritative sources inform the design, evaluation, and governance of HotelByte's Room Mapping system. Each source is mapped to the corresponding HotelByte control.

| Source | Original Excerpt | HotelByte Control Mapping |
|---|---|---|
| **Google. "Shadow Mode: A Safe Environment for Experimentation."** *Google AI Blog*, 2019. | "Shadow mode allows teams to run new models in parallel with production systems, capturing predictions without affecting user-facing outcomes. This enables safe measurement of model performance before launch." | **Shadow Mode Safety Boundary** — The production system remains unaffected by candidate algorithm outputs until offline evaluation is complete. |
| **Microsoft. "Responsible AI: Fairness and Transparency in Machine Learning."** *Microsoft AI Principles*, 2022. | "AI systems should be evaluated against fairness metrics and transparent about their decision-making processes, including the ability to explain outcomes and audit model behavior over time." | **Structured Annotation Workflow** and **Auto-Corpus Enrichment** — Human-validated ground truth and continuous re-evaluation ensure fairness and transparency in mapping decisions. |
| **Powers, David M.W. "Evaluation: From Precision, Recall and F-Measure to ROC, Informedness, Markedness & Correlation."** *Journal of Machine Learning Technologies*, 2011. | "F1 score is the harmonic mean of precision and recall and provides a balanced measure of a test's accuracy, particularly useful when class distributions are uneven." | **Automatic Winner Determination (F1 Δ > 0.001)** — F1 score is the primary promotion criterion, balancing precision and recall in the presence of imbalanced match/non-match pair distributions. |
| **Hubert, Lawrence, and Phipps Arabie. "Comparing Partitions."** *Journal of Classification*, 1985. | "The Rand Index measures the similarity between two data clusterings, providing a scalar value between 0 and 1 that reflects the proportion of agreed-upon pairwise decisions." | **Offline Evaluation Loop** — Rand Index is computed alongside Precision and Recall to validate cluster-level agreement, not just pairwise accuracy. |
| **Breck, Eric, et al. "What's Your ML Test Score? A Rubric for ML Production Systems."** *Google Research*, 2017. | "ML systems in production require tests for feature expectations, model specifications, and integration contracts, with continuous monitoring for data drift and model staleness." | **Dual Metrics Writing**, **Continuous Monitoring**, and **Embedding Service with LRU Cache & Hit Rate Statistics** — Comprehensive testing and monitoring rubric applied to mapping pipeline components. |
| **OpenAI. "Text Embeddings: Best Practices for Production."** *OpenAI Platform Documentation*, 2024. | "Batching requests, implementing caching layers, and monitoring cache hit rates are essential for achieving cost-effective and low-latency embedding inference at scale." | **Embedding Service with LRU Cache & Hit Rate Statistics** — Batch processing (batch size 100), LRU cache (10k entries, 24h TTL), and hit rate monitoring align with production embedding best practices. |
| **Kohavi, Ron, and Roger Longbotham. "Online Controlled Experiments and A/B Testing."** *Encyclopedia of Machine Learning and Data Mining*, 2017. | "Controlled experiments with randomized assignment and configurable sampling rates are the gold standard for measuring the causal impact of system changes on user outcomes." | **A/B Sampling Rate Control (`hb_compare_sample_rate`)** — Configurable per-environment sampling enables causal measurement of algorithm impact without exposing full traffic to unvalidated changes. |

---

*© 2026 HotelByte. All rights reserved. This whitepaper is provided for informational purposes and does not constitute a binding service-level agreement.*


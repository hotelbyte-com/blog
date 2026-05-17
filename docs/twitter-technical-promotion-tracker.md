# Twitter Technical Promotion Tracker

Source issue: hotelbyte-com/hotel-be#1076
Related outreach issue: hotelbyte-com/hotel-be#1093
Owner: HotelByte Team
Cadence: weekly technical promotion posts

## Scope

This tracker is for short-form technical promotion on Twitter and blog-driven source material. It turns shipped HotelByte engineering work into public, evidence-backed technical stories.

This tracker is not the whitepaper backlog. Whitepaper material should stay longer-lived and thesis-driven: market framing, architectural principles, and reusable industry lessons. Twitter and blog promotion should stay delivery-driven: one concrete capability, one proof point, one linkable artifact, and one clear follow-up for outreach.

## Operating Rules

- Every topic must link to a real shipped feature, scenario test, production metric, architecture diagram, or reviewable source artifact.
- Public copy must avoid customer, supplier, credential, raw log, and tenant-specific data.
- Posts should explain the engineering problem and validation signal, not just announce a feature.
- Weekly updates should be shared with #1093 so audience outreach can reuse the same evidence without changing the technical claim.
- A topic is ready only when the evidence column is filled and the blog/Twitter angle is distinguishable from whitepaper material.

## Evidence Anchors

| Anchor | Public capability claim | Verification signal | Source |
| --- | --- | --- | --- |
| Dashboard reliability | HotelByte exposes a troubleshooting dashboard with coherent request, session, error-rate, latency-quality, and inspection-recall signals. | E2E scenario calls `POST /api/bi/log/troubleshootingHomeFunction`; validates `code == 0`, non-negative counts, ratio bounds, data-quality rates, and inspection-recall SLA semantics. | `hotel-be/api/tests/scenarios/dashboard_reliability_e2e.go` |
| LLM log diagnosis | HotelByte can attach AI-assisted diagnosis to operational session inspection while tolerating disabled or delayed LLM execution. | E2E scenario creates a search session, calls `POST /api/bi/log/getSession`, polls async diagnosis for up to 45 seconds, validates non-empty summary and confidence bounds when a diagnosis is returned. | `hotel-be/api/tests/scenarios/llm_diagnosis_e2e.go` |
| PriceAssist lifecycle | HotelByte can monitor hotel price opportunities through subscription, comparison, alert, read-state, update, and order-linking flows. | E2E scenario covers subscribe, list, detail, compare-now, alert list, mark-read, update, and link-order behavior through `/api/priceassist/*` endpoints. | `hotel-be/api/tests/scenarios/priceassist.go` |

## Weekly Topic Pool

| Week | Topic | Blog/Twitter angle | Evidence to attach | Whitepaper boundary | Publish record |
| --- | --- | --- | --- | --- | --- |
| 2026-W18 | Dashboard Reliability | Show how a hotel API platform turns raw BI logs into bounded operational health signals. | Dashboard reliability E2E scenario, endpoint contract, KPI/rate bounds. | Whitepaper may discuss observability strategy; this post should focus on the concrete dashboard validation contract. | Pending |
| 2026-W19 | LLM Diagnosis for Hotel Sessions | Explain how AI diagnosis is guarded by async status, confidence bounds, and graceful degradation. | LLM diagnosis E2E scenario, async polling behavior, response contract. | Whitepaper may discuss AI-assisted operations; this post should focus on one session-inspection workflow. | Pending |
| 2026-W20 | PriceAssist Alert Lifecycle | Walk through how price monitoring becomes an auditable subscription and alert lifecycle. | PriceAssist scenario, endpoint list, alert read/update behavior. | Whitepaper may discuss revenue optimization; this post should focus on lifecycle mechanics and validation. | Pending |
| 2026-W21 | Evidence-Backed Technical Promotion | Describe the publishing standard: every external technical claim needs a source test, metric, or diagram. | This tracker, #1076, and the three scenario anchors above. | Whitepaper may collect principles; this post should define the lightweight operating loop. | Pending |

## Publish Record Template

Use one row per published item.

| Topic | Channel | Published at | URL | Evidence link | Impressions | Likes | Reposts | Replies | Synced to #1093 |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Dashboard Reliability | Twitter / Blog | TBD | TBD | `dashboard_reliability_e2e.go` | TBD | TBD | TBD | TBD | TBD |

## Next Execution Steps

1. Convert the W18 topic into a bilingual blog post draft.
2. Derive a Twitter thread from the same evidence, keeping the claim narrower than the whitepaper.
3. After publishing, fill the publish record and post the topic/evidence/metrics summary back to #1076 and #1093.

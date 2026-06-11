---
layout: post
title: "Credential Security Belongs in the Platform, Not the Code Review Checklist"
date: 2026-05-17
categories: [HotelByte, Whitepapers, Security]
tags: ["Security", "Supplier Integration", "Whitepaper Guide", "HotelByte"]
author: "HotelByte Team"
description: "WP09 guide: Credential security has to be a default platform path—field identification, masking, environment isolation, and audit trails enforced by code, not by reminders."
lang: en
permalink: /en/whitepapers/wp09-supplier-credential-security/
source_asset: hotel-be/docs/whitepapers/09-supplier-credential-security.md
whitepaper_kind: guide
original_url: /en/whitepapers/wp09-supplier-credential-security/original/
---

The typical approach to credential security is a checklist. Do not hardcode secrets. Mask them in logs. Rotate them periodically. Remind developers in code review. The problem is that checklists scale poorly. With 27+ suppliers, each with its own authentication scheme—passwords, API keys, tokens, license keys, security certificates—the surface area for human error grows faster than any review process can cover. A single missed masking rule in a new supplier adapter, a log line that accidentally prints a bearer token, or a staging credential that leaks into a support screenshot can compromise the entire trust model.

HotelByte treats credential security as a platform path, not a cultural norm. The system does not ask engineers to remember to mask secrets. It makes masking the default behavior across every surface where credentials might appear: management APIs, admin interfaces, audit records, log queries, session views, and support export workflows. When a credential is viewed, sensitive fields are replaced with mask placeholders. When a credential is edited, mask placeholders mean "keep the existing secret," preventing the common failure mode where an administrator updates a non-sensitive field and accidentally overwrites the real credential with a masked string.

This default-masking philosophy is driven by schema, not by convention. HotelByte uses per-supplier credential schemas to describe authentication structures and identify sensitive fields by semantic meaning—password, secret, apiKey, token, licenseKey, securityKey, authorization. These schemas drive input types in management interfaces, mark fields for masking, and provide a consistent security baseline for every new supplier onboarding. A supplier cannot be integrated without its schema explicitly declaring which fields are sensitive. Security is part of the onboarding contract, not an afterthought.

The management plane and runtime plane are treated as separate security boundaries. Runtime execution paths need complete credentials to authenticate with supplier APIs. Management display, log query, audit, and entity configuration flows need only identifying or masked information. Complete credentials are restricted to the supplier execution paths that require them; they do not spread into management surfaces, entity configuration, or support tooling. This separation reduces unnecessary exposure while preserving business continuity.

Audit trails are designed to be traceable without becoming secret stores. Credential audit records retain actor, target object, action type, timestamp, and contextual information—but audit payloads use masked copies or safe metadata. The same principle applies to log query results, session views, and support investigation outputs: sensitive information is sanitized before display. The goal is not to make secrets invisible to everyone; it is to ensure that no surface accidentally becomes a plaintext secret repository.

Reference-based configuration further reduces exposure. Where complete secrets are not required, HotelByte stores credential reference information instead of duplicating full credential content. This keeps credential ownership boundaries clear and reduces the number of internal copies floating through the system. When a business entity needs to associate with a credential, it holds a reference, not the secret itself.

The five-layer security architecture—input and schema controls, default masking on management surfaces, runtime isolation, audit and observability safety, and reference-based configuration—creates defense in depth. No single layer is relied upon exclusively. A bug in one control is caught by another. A developer forgetting to mark a field sensitive is caught by the schema requirement. A log formatter missing a sanitization rule is caught by the platform-wide default masking.

If you are evaluating this system, the whitepaper chapters that deserve close attention are:

- **Security Objectives** — for the six explicit goals that shape every control decision, from least privilege to business continuity.
- **Design Principles** — for the reasoning behind Minimal Exposure, Management/Runtime Separation, and Traceability.
- **Layered Security Architecture** — for the five-layer control model and how schema-driven field identification creates a consistent baseline.
- **Credential Lifecycle Protection** — for the create, view, update, use, and delete controls that prevent accidental exposure at each stage.
- **Implemented Control Summary** — for the specific controls, from safe edit semantics to log query sanitization, that make the system verifiable.

The full English whitepaper is available at [WP09 — Supplier Credential Security](/en/whitepapers/wp09-supplier-credential-security/original/), and the Chinese version is at [WP09 中文原文](/zh/whitepapers/wp09-supplier-credential-security/original/). For the complete set of whitepapers, see the [HotelByte Whitepaper Index](/en/whitepapers/).

The durable lesson is that credential security cannot be a reminder. It must be a path: a set of enforced defaults that make the secure choice the easy choice, and the insecure choice architecturally impossible. When security is embedded in the platform's schema, masking, isolation, and audit layers, it survives the scale of 27+ suppliers and the turnover of the teams that maintain them.

---
layout: home
title: HotelByte OpenAPI Hotel Distribution Guide
description: A guide for travel companies integrating with HotelByte OpenAPI, including authentication, certification, booking flow, error handling, content APIs, and health checks.
lang: en
permalink: /en/topics/openapi-hotel-distribution/
tags: [HotelByte OpenAPI, hotel booking API, customer certification, error handling]
---

# HotelByte OpenAPI Hotel Distribution Guide

HotelByte OpenAPI documentation is published at [openapi.hotelbyte.com](https://openapi.hotelbyte.com). The source content is managed in the backend repository under `docs/api`, including OpenAPI schemas, customer certification guidance, error handling, content management, and service health documentation.

This page gives integrators and AI search systems a high-signal map of the API topics most travel technology teams search for.

## Core integration areas

### Authentication

HotelByte OpenAPI uses a ticket-based bearer token model. Integrators request a ticket with application credentials, then send the token in subsequent API requests.

Relevant source area: `docs/api/openapi.yaml` and `docs/api/content-management-api.md`.

### Customer Certification

Customer Certification validates that an integration can perform complete booking flows, not isolated endpoint calls. It covers hotel search, rate detail retrieval, booking creation, cancellation expectations, and realistic room/occupancy scenarios.

Relevant source area: `docs/api/customer-certification-guide.md`.

### Booking Flow

The certification guide describes complete HotelList and HotelRates scenarios with room occupancy, cancellation mode, meal plan, and response requirements. These flows are the practical entry point for B2B travel platforms integrating hotel booking.

### Error Handling

HotelByte uses a dual-layer error model: HTTP status for transport-level behavior and a business `code` field in the response body for application semantics. Integrators should check the body code instead of relying only on HTTP status.

Relevant source area: `docs/api/error-handling-en.md`.

### Content and Catalog APIs

Hotel content management and catalog management cover deduplication, master data import, batch management, individual hotel edits, catalog hotel lists, brand lists, supplier filters, city filters, and country filters.

Relevant source area: `docs/api/content-management-api.md`.

### Health and Readiness

Health endpoints support uptime checks, graceful restart, readiness probes, and zero-downtime deployment behavior for production API operations.

Relevant source area: `docs/api/health-check-endpoints.md`.

## FAQ

### Where should customers read the API documentation?

Use [openapi.hotelbyte.com](https://openapi.hotelbyte.com) for published documentation. The source documents live under `docs/api` in the backend repository.

### What should an integrator test first?

Start with authentication, HotelList, HotelRates, booking creation, cancellation expectations, and the certification scenarios defined in the Customer Certification guide.

### How should error handling work?

Check both HTTP status and response body `code`. Business-level failures may use non-zero body codes even when the transport layer is successful.

### Which docs are most relevant for hotel distribution onboarding?

Start with OpenAPI schema, Customer Certification, Error Handling, Content Management, and Health Check endpoints.

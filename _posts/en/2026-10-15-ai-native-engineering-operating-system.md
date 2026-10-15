---
layout: post
title: "Rent the Model, Rent the Coding Agent, Train the Harness"
date: 2026-10-15
categories: [HotelByte, Engineering, AI]
tags: [AI-Native Engineering, Harness Engineering, Long-Horizon Agents, Agent Memory, Agent Evaluation, HotelByte]
author: "HotelByte Team"
description: "How fewer than five engineers build against a requirement catalog that an outside quote priced at more than ¥100 million: the judgments behind long-horizon tasks and long-horizon memory in the work harness, and what carries over to anyone who builds agents."
lang: en
permalink: /en/whitepapers/ai-native-engineering-operating-system/
whitepaper_kind: guide
original_url: /en/whitepapers/ai-native-engineering-operating-system/original/
featured: true
---

Writing code is not the hard part of building a large system with agents. Keeping long work correct and long memory useful, when no single session sees the whole, is. This guide summarizes the judgments behind HotelByte's answer, and why they matter to anyone who builds agents.

This is a new edition of our [first AI-Native Engineering Operating System paper (WP27)](/en/whitepapers/wp27-ai-native-engineering-operating-system/), rebuilt around two harnesses and measured like a model.

**TL;DR:** HotelByte builds a B2B hotel-distribution platform and measures it against a wholesaler's catalog of 792 requirements in 14 modules, a scope that an outside quote priced at more than ¥100 million; the catalog is the yardstick, and the platform is built to serve many kinds of travel business beyond it. A team of fewer than five engineers builds it with coding agents from several vendors: 1.61 million lines of first-party code in 8 repositories, 40% of it tests. Every deployment like this runs on two harnesses: the **agent harness** inside each coding agent, which we rent, and the **work harness** the agents work in, which we own and train on our own failures. The whitepaper sets out the judgments we made in the work harness, measures it like a model, with a pre-registered benchmark built from our own bug fixes, and shows which judgments carry over to the agent side.

## Why This Matters in Hotel Distribution

Hotel distribution punishes "looks right" engineering. Supplier APIs drift, prices expire in minutes, and booking, cancellation and payment rules are easy to break. Many questions can only be answered from logs, database state and release state, not from code. A fast agent that gets these wrong is a financial risk.

## Five Judgments, Each Following From the Last

**1. Own the work harness; rent the model and the agent harness.** Both rented layers improve every few weeks without us, so patches for one model's weakness lose value. What we own is the environment our agents work in. *Rejected:* building our own coding agent or review bot.

**2. Grow the oracle faster than the throughput.** At this scale only checks independent of the agent can decide what it may claim, and ours keep accelerating: 47 new test functions a day in the second quarter, 61 in the third and 180 since then, while tests rose from 35% to 55% of new Go lines. *Rejected:* trusting an agent's own "fixed".

**3. A long task is a chain of short, checkable steps, with its state outside the model.** A requirement becomes a design, issues, pull requests, commits with their reasons and receipts with their proof; "done" is allowed only after two machine checks pass at a named commit, and any later commit voids it. Many agents may investigate at once, but only one integrates into each repository. A stuck agent changes strategy before it asks: three rounds without progress send it back to investigation with a demand for two new approaches, and only after four such escalations does it ask a named person, with the evidence attached. *Rejected:* long sessions that carry the plan in their context.

**4. Two memories, both on; the repository's is a budget.** What one agent learns stays in its own memory. What every agent must know lives in the repository, in files any vendor's agent reads, and grows only with a written reason. *Rejected:* making one vendor's memory the organization's record, and switching agent memory off for neutrality.

**5. Grade autonomy by reversibility, not by trust.** Agents act at every risk level; only irreversible steps wait for a named person, and production autonomy has numeric gates checked in code. *Rejected:* approving every step, which turns approval into a reflex.

## The Proof in Brief

| | HotelByte |
|---|---|
| Scope | 792 catalog requirements in 14 modules, priced by an outside quote at more than ¥100 million, as the yardstick; tenants, rate monitoring, an advisor CRM, loyalty and agent channels beyond it |
| System | 1.61 million lines of first-party code in 8 repositories, 40% of it tests, generated code excluded: a Go backend of 579k source and 478k test lines, 395k lines in the web front ends; 23 supplier adapters in production |
| Oracle | 47 → 61 → 180 new test functions a day (second quarter, third quarter, since then) |
| History | 9,545 commits since 2025-05-04; 3,637 merged backend pull requests since July 2025 |
| Pace | 2,069 merged pull requests across 10 company repositories in a 30-day window |
| Ablation of the instruction layer | A pre-registered ablation on 20 private bug fixes, deleting the whole instruction layer and keeping every check, found no detectable difference in how many bugs a strong agent fixed: 9 with the layer, 10 without, 1 of 20 tasks differing |
| Cost | 26–169 million tokens per merged pull request on the measured Mac |

## What Carries Over If You Build Agents

The two harnesses obey the same laws, so five of our judgments apply directly to an agent harness: read the work harness by convention and record which instructions shaped a run; write state where the organization keeps it, and keep your own memory for the person and the session; never grade yourself, and report false completions next to the resolve rate; ask by reversibility, naming the default you will take; and let customers run you with and without their work harness on their own past tasks. [GoTry](https://github.com/Danceiny/gotry), our open-source travel agent, is built on the same laws: the model interviews and code decides, naming the constraint each rejected option fails; every number carries a source tag that code attaches, never the model; a claim whose evidence is unknown or stale is blocked; and booking and payment writes are sealed off the tool surface.

## Two Stories

- **Six months of plans, fifty-eight hours of measurement.** A hotel matcher's nine known gaps had waited in a plan since April. Once a retrospective measured the old scorer instead of planning around it, a 21-feature model replaced it in about 58 hours; replayed over 286,542 labeled lists, the share of hotels mapped without a person rose from 67% to 90%, at higher precision. Automatic mapping still stays off until it passes its written release gate.
- **Measure the LLM before it decides.** The language-model arbiter's first prompt called different properties the same 14.9% of the time, so the gate that kept it in shadow held. A second prompt and a different model made its confident calls reliable, but its overall agreement stayed near 84%, and it still waits for real review data.

## A Five-Question Test for Your Team

1. If you switched model and coding agent tomorrow, which parts of your system would still be yours?
2. Where does a task's state live when the session that started it is gone?
3. Can an agent tell you "done" without naming the commit it verified?
4. Which of your agents' lessons live only in one vendor's memory?
5. Have you measured what your agents' instructions and skills change, on tasks the agents could not have seen?

## How to Read the Full Whitepaper

- **Sections 1–3** for the problem as a rate, the two harnesses (what we rent and what we train), and the scale with the oracle underneath.
- **Sections 4–5** for long-horizon tasks, state and the two memories.
- **Sections 6–8** for retrospection, how we evaluate the work harness (including the pre-registered ablation of the instruction layer), and the laws both harnesses share, with what transfers.
- **Sections 9–12** for authority and data, decision stories, the comparison with the field, and a playbook.

<div class="whitepaper-reader-note">
  <strong>Full source:</strong> <a href="/en/whitepapers/ai-native-engineering-operating-system/original/">AI-Native Engineering Operating System whitepaper</a> · <strong>中文：</strong><a href="/zh/whitepapers/ai-native-engineering-operating-system/">导读</a> / <a href="/zh/whitepapers/ai-native-engineering-operating-system/original/">完整白皮书</a>
</div>

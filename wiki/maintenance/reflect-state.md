---
id: reflect-state
title: Reflect State
type: overview
status: active
summary: "Checkpoint state for periodic reflect workflow (AGENTS.md section 11.4)."
created_at: 2026-04-14
updated_at: 2026-04-14
sources: []
epistemic_status: sourced
tags:
  - meta
  - maintenance
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Reflect State
has_contradictions: false
knowledge_domain: ""
last_reflect_log_entry: ""
last_reflect_commit: ""
last_reflect_at: 2026-04-14
---

# Reflect State

Control-plane checkpoint for the periodic reflect workflow (AGENTS.md section 11.4).
This file tracks where the last reflect pass ended so subsequent passes resume from the correct position.

## Fields

- **last_reflect_log_entry:** The full heading line of the last log.md entry scanned. Empty string means no prior reflect pass has scanned log entries.
- **last_reflect_commit:** The short SHA of the last git commit inspected. Empty string means scan from the beginning of git history.
- **last_reflect_at:** ISO 8601 date of the last reflect pass.

## Usage

Read this file at the start of each periodic reflect pass (Tier 3, Section 11.4). After completing the pass -- whether or not decision records were created -- update all three checkpoint fields and commit. A reflect pass that produces no records still advances the checkpoint to prevent re-scanning.

---
id: log
title: Kahneman Example Log
type: overview
status: active
summary: "Historical ingest log preserved from the Kahneman reference cluster."
created_at: 2026-04-09
updated_at: 2026-04-15
sources: []
epistemic_status: sourced
tags:
  - meta
  - operations
domains: []
privacy: cloud_safe
example: true
---

# Kahneman Example Log

Append-only operations log for the preserved Kahneman reference cluster.
This log captures the ingest entries that produced the pages under `examples/kahneman/`.
It is **reference material** — do not edit.

## [2026-04-09] schema | Create example pages and populate navigation

Created 5 example pages: Daniel Kahneman (entity), Cognitive Biases (concept), Thinking Fast and Slow Part 1 (source summary), System 1 vs System 2 (comparison), Decision Making (overview). Pages form a connected graph cluster demonstrating cross-references, provenance chains, and epistemic markers.

## [2026-04-10] ingest | Prospect Theory and Loss Aversion Article

Ingested synthetic magazine-style article (source_type: article) on Kahneman and Tversky's prospect theory research. Created source summary page src-2026-04-10-kahneman-prospect-theory with 15 atomic claims. Diff pass page changes:

- UPDATED: daniel-kahneman -- biographical key facts (career appointments, Econometrica 1979).
- UPDATED: cognitive-biases -- endowment effect, status quo bias, disposition effect as loss-aversion-origin family.
- UPDATED: system-1-vs-system-2 -- loss-aversion flinches as a System 1 response.
- UPDATED: decision-making -- 90% survival framing, nudge-theory lineage.
- CREATED: prospect-theory -- dedicated concept page (reference dependence, diminishing sensitivity, probability weighting).
- CREATED: loss-aversion -- dedicated concept page (coefficient ~2, anchors downstream biases).

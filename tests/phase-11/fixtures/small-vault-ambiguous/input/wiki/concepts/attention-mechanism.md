---
id: attention-mechanism
title: "Attention Mechanism"
type: ""
status: active
summary: ""
created_at: 2026-04-20
updated_at: 2026-04-20
sources: []
epistemic_status: tentative
tags: []
domains: []
supersedes:
superseded_by:
privacy: local_only
aliases: []
has_contradictions: false
knowledge_domain: ""
bootstrap_stage: bootstrapped
bootstrap_date: 2026-04-20
---

# Attention Mechanism

## TL;DR

- Attention lets models weight input tokens dynamically.
- Transformers rely on attention instead of recurrence.

## Key Facts

- Scaled dot-product attention is the canonical form.
- Multi-head attention runs several attention projections in parallel.

## Detail

Attention mechanisms compute weighted sums of value vectors based on
query-key similarity.  See [[Transformer]] and [[Deep Learning]].

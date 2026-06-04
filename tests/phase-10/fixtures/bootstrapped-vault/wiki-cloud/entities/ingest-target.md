---
id: ingest-target
title: "Ingest Target (Brownfield-Bootstrapped)"
type: entity
status: active
summary: "Fixture page carrying bootstrap_stage + bootstrap_date; used as the source input for bin/ingest.sh strip tests."
created_at: 2026-04-01
updated_at: 2026-04-17
sources: []
epistemic_status: tentative
tags: []
domains: []
supersedes: null
superseded_by: null
privacy: local_only
aliases: []
has_contradictions: false
knowledge_domain: ""
bootstrap_stage: bootstrapped
bootstrap_date: 2026-04-17
---

# Ingest Target

Entity body — must survive the bin/ingest.sh strip pass unchanged.

This paragraph is here specifically so test_ingest_strip_bootstrap_stage.sh
can grep for "Entity body" in the post-ingest DEST_FILE and confirm the
brownfield-strip operation ONLY touches frontmatter lines, not body text.

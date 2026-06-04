---
id: bootstrapped-old
title: "Old Bootstrapped Page"
type: ""
status: active
summary: ""
created_at: 2026-01-01
updated_at: 2026-01-01
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
bootstrap_date: 2026-01-01
---

Body for bootstrapped-old. bootstrap_date is 2026-01-01 which is >30 days before
2026-04-17 (today at fixture author time). Used by test_lint_brownfield_stale_30d.sh
to verify the brownfield-category 30-day staleness warning fires on stale bootstraps.
Also carries `type: ""` which is an invalid enum value → yaml-category error in
base lint, suitable for testing the BRWN-08 --ci downgrade.

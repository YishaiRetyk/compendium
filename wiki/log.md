---
id: log
title: Log
type: overview
status: active
summary: "Append-only operations log."
created_at: 2026-04-15
updated_at: 2026-04-15
sources: []
epistemic_status: sourced
tags:
  - meta
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
---

# Log

Append ingest entries here, newest at bottom, per AGENTS.md §12.

## [2026-04-16] reflect | progressive disclosure extraction

result: extracted §4 worked examples (6 files) to schema/examples/ and §16 appendices A, B to docs/reference/; DR dr-2026-04-16-progressive-disclosure-extraction records the framing shift.
reason: reduce spec context size while preserving "sole authoritative specification" framing via uniform `See:` pointers.

## [2026-04-20] reflect | Phase 11 brownfield apply-vs-advisory architecture + review-feedback hardenings

Structural reasoning captured in Tier-1 decision record [[Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern]] (`dr-2026-04-20-brownfield-apply-vs-advisory`). Documents the apply-class vs advisory-class split (D-01), review-manifest pattern for 01-page-typing (D-02, D-04), bootstrap_stage lifecycle gate via verify --promote (D-13, D-14, D-15), and review-feedback hardenings: root resolution (item 1), paired immutable inputs (item 2), shared walker (item 3), EOF-safe review-typing (item 4), top-level-bullets-only regex (item 5), aggregator per-plan gate split (item 6), widened D-03 auto-approve (item 7), hashlib portability (item 8), operational D-09 enforcement (item 9), per-script applied.log variance (item 10), override-label validation (item 11). Alternatives rejected (chain-runner, per-page prompts, scanner-driven privacy promotion, $(pwd) root default, decisions-only-without-candidates, shell sha256sum, decorative D-09 metadata, unified applied.log schema).

## [2026-05-01] reflect | Phase 12 complementary-systems boundary

Created decision record [[dr-2026-05-01-complementary-systems-boundary]] (`trigger_type: schema-update`, `affected_pages: []`) capturing that compendium owns durable, provenance-backed wiki memory and review support, while complementary systems own task execution, reminders, calendars, and transactional state. Created `docs/reference/three-layer-model.md` with the 3-layer model, capture/clarify/organize/review routing table, and anti-features section. Added README pointer under "What this is", `docs/reference/index.md` bullet, and the Decisions entry above. Supports BOUND-01, BOUND-02, BOUND-03; verification closes them in Plan 12-04 (`bin/requirements-sync.sh --strict --phase 12` exits 0). Unblocks the CLOSE-04 scope-leak gate for v1.1 closure.

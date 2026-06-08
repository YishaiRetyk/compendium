---
id: dr-2026-04-20-brownfield-apply-vs-advisory
title: "Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern"
type: decision
trigger_type: schema-update
affected_pages: []
status: active
summary: "Captures the apply-class vs advisory-class split, review-manifest pattern
  for 01-page-typing, bootstrap_stage lifecycle gate, and cross-AI review-feedback
  hardenings (items 1–11) introduced in Phase 11."
created_at: 2026-04-20
updated_at: 2026-04-20
sources: []
epistemic_status: sourced
tags:
- brownfield
- architecture
- apply-class
- advisory-class
- review-manifest
domains:
- schema-evolution
supersedes: null
superseded_by: null
aliases:
- "Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern"
- "dr-2026-04-20-brownfield-apply-vs-advisory"
has_contradictions: false
knowledge_domain: software
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->

## TL;DR

Phase 11 introduces the brownfield workflow's apply-vs-advisory architectural split, the review-manifest pattern for 01-page-typing, and the bootstrap_stage lifecycle gate via `verify --promote`. Apply-class scripts (01, 02) mutate vault pages deterministically; advisory-class scripts (03, 04) produce reports only. The review-manifest pattern isolates page-typing judgment (AI-guided or TTY) from deterministic apply, preserving BRWN-16's mechanical-tool boundary. Cross-AI review (Gemini + Codex) hardened the initial design with root-resolution safety (item 1), paired-immutable-inputs contract for 01 (item 2), shared `.brownfield-ignore` walker with scan (item 3), EOF-safe prompt loop in review-typing (item 4), top-level-bullets-only regex in 02 (item 5), aggregator per-plan gate split (item 6), widened D-03 auto-approve (item 7), Python hashlib replacing shell sha256sum (item 8), operational D-09 enforcement via stale-artifact WARN in verify (item 9), documented per-script applied.log variance (item 10), and override-label validation (item 11).

## Decision

Adopt the following architecture for Phase 11 brownfield migration:

1. **Apply class:** `01-page-typing.sh`, `02-provenance-bootstrap.sh`. Real `--apply` path; mutate frontmatter / body text deterministically.
2. **Advisory class:** `03-cross-link-inference.sh`, `04-privacy-review.sh`. Report-only; never mutate pages; `--apply` is blocked.
3. **Review-manifest pattern (01-page-typing only):** suggest emits `candidates.yaml` + `decisions.yaml` (pending); review-typing (TTY or AI-handoff) edits decisions; `01 --apply` reads both deterministically as PAIRED IMMUTABLE INPUTS (item 2 contract) — candidates.yaml provides cluster-membership lookup, decisions.yaml provides policy. Apply never re-classifies.
4. **`bootstrap_stage` lifecycle gate:** `verify --promote` flips `bootstrapped → verified` via a 5-gate per-page pass-list (D-14). `verified` is manual-edit-only after that (no automatic downgrade).
5. **Review-feedback hardenings (items 1–11 from 11-REVIEWS.md):** implementation details of the above, documented in Consequences below.

Design principle: **Review may be interactive and AI-guided; apply must always be deterministic.**

## Why

The replaced framing was "generate one `apply` chain-runner that does everything" (v1.0 imagination, captured in v2 backlog as BRWNAPPLY-01). The adopted framing separates mechanical work (deterministic, idempotent, testable via byte-equality fixtures) from judgment work (clustering decisions, cross-link inference, privacy classification) that genuinely requires human or AI-assisted interpretation.

The review-manifest pattern exists because page-typing is the highest-leverage judgment call in the workflow: getting `type:` right affects lint, verify, and all downstream operations. Yet it is also the most cluster-friendly (PascalCase entities tend to cluster; kebab-case concepts tend to cluster). A review manifest captures both the mechanical cluster output AND the human policy decision in one file that the deterministic apply script can then consume without re-interpreting.

Why 02/03/04 do NOT adopt the review-manifest pattern:
- **02-provenance-bootstrap:** surface is narrow (top-level bullets under TL;DR + Key Facts per review item 5); eligibility rules are mechanical (8 skip classes per D-05); no manifest needed.
- **03-cross-link-inference:** advisory-only in v1.1; manifest-backed apply deferred to future phase (see Deferred list). First-mention-only rule per AGENTS.md §8 needs per-user review; judgment-heavy.
- **04-privacy-review:** advisory-only in v1.1; fail-closed `privacy: local_only` is preserved per AGENTS.md §13; no mutation path at all. Future: user-authored `.brownfield-privacy-cloudsafe.txt` allowlist as explicit human policy.

## Alternatives Considered

1. **Auto-apply all migration scripts in a single `brownfield apply` command.** Rejected: judgment errors at scale silently corrupt the wiki; `git reset --hard` is too-blunt recovery for a 500-page vault. Deferred to v1.2 BRWNAPPLY-01 after the per-class dry-run path is battle-tested.

2. **Per-page prompts for typing (no clustering).** Rejected: 500-page vaults produce 500 prompts; cognitive load makes the workflow unusable. Clustering by signal tuple (`cluster_by_signals` per RESEARCH Q1) reduces typical 500-page decisions to 20-50 cluster decisions.

3. **Scanner-driven privacy promotion (04-privacy-review flips `privacy:` frontmatter).** Rejected: violates AGENTS.md §13 fail-closed semantics. Only a human may downgrade `local_only → cloud_safe`; regex-driven classification would produce false positives that silently promote sensitive content.

4. **Embedded vault-specific logic in migration scripts (one-off rendered scripts per vault).** Rejected: violates byte-equality CI + git reviewability; re-running `suggest` on a changed vault would produce different script contents. Hybrid model (canonical scripts byte-copied; vault-specific data in YAML candidate files) keeps logic versioned and state ephemeral.

5. **Interactive TUI with arrow keys + previews.** Rejected per FEATURES.md §Bucket 5 anti-feature list. CLI + manifest hits the same workflow need with less code and better CI scriptability.

6. **Default `BROWNFIELD_ROOT=$(pwd)` for migration scripts.** Rejected (review item 1): cross-tree mutation risk when scripts are invoked via absolute path from unrelated cwd. Adopted: resolve from script's `.brownfield/` parent.

7. **01-page-typing reads only decisions.yaml (candidates.yaml unused at apply time).** Rejected (review item 2): candidates.yaml provides load-bearing cluster-membership lookup. Adopted: paired immutable inputs.

8. **Fork scan's walker for suggest.** Rejected (review item 3): drift risk + simplified-walker bug (would sweep docs/, schema/, etc. into candidates). Adopted: shared `bin/lib/brownfield_walk.py` called by both.

9. **Shell `sha256sum` for input hashing.** Rejected (review item 8): macOS portability gap (not in POSIX; requires coreutils install). Adopted: Python `hashlib` via heredoc.

10. **D-09 metadata decorative.** Rejected (review item 9): audit story is weaker if stale artifacts go undetected. Adopted: verify emits stale-artifact WARN when `source_script_hash` drifts. Non-blocking.

11. **Unified applied.log schema across all four scripts.** Rejected (review item 10): 02's direct-apply has no candidate inputs to hash; forcing a unified schema would require a fake placeholder. Adopted: per-script variance, documented in `schema/brownfield/migrations/README.md` and AGENTS.md §11.5.4.

## Consequences

- `AGENTS.md` §11.5 Brownfield Workflow is the new authoritative contract; §11.5 Release Workflow renumbered to §11.6 (opportunistic fix of Phase 10 WR-03 forward-ref typo).
- `schema/brownfield/migrations/` becomes a new tracked directory of canonical migration scripts; byte-equality CI-enforced via `tests/phase-11/test_canonical_byte_equality.sh`.
- `.brownfield/` gains the candidate/decisions/applied-log artifacts (all gitignored per TMPL-04).
- `bootstrap_stage` gains the `verified` lifecycle state; `verify --promote` is the ONLY v1.1 writer of that state.
- REQUIREMENTS.md BRWN-12 wording amended (04-privacy-classification → 04-privacy-review); new BRWN-22 covers `review-typing` (including items 4 + 11).
- v1.2 roadmap entries: BRWNAPPLY-01 (chain-runner), manifest-backed apply for 03/04, `.brownfield/02-exclude.txt` page-level opt-out.

**Review-feedback hardenings (implementation details of the above architecture):**

- **Item 1 — Root resolution:** all four migration scripts derive `BROWNFIELD_ROOT` from the script's `.brownfield/` parent via `${BASH_SOURCE[0]}` resolution, not from `$(pwd)`. Prevents cross-tree mutation. Locked by `test_01_root_resolution.sh`.
- **Item 2 — Paired immutable inputs:** 01-page-typing.sh requires BOTH candidates.yaml + decisions.yaml at apply time. Neither alone is sufficient. Locked by `test_01_paired_immutable_inputs.sh` + `test_01_apply_reads_decisions_only.sh`.
- **Item 3 — Shared `.brownfield-ignore` walker:** scan + suggest call `bin/lib/brownfield_walk.py walk_vault_respecting_ignore()`; no fork. Locked by `test_suggest_respects_brownfield_ignore.sh` + Phase 10 regression suite staying green.
- **Item 4 — EOF-safe review-typing loop:** `_EOF_SENTINEL` + `_MAX_REPROMPTS_PER_CLUSTER=5` prevent hangs; piped `</dev/null` aborts cleanly. Locked by `test_review_typing_eof_handling.sh` (`timeout 3` guard).
- **Item 5 — Top-level bullets only:** `BULLET_TOP_LEVEL_RE = r'^-(?: |\t)(.+)$'` rejects any leading whitespace. Locked by `test_02_top_level_bullets_only.sh` + `nested-bullets-vault` fixture.
- **Item 6 — Per-plan gate split:** `tests/phase-11/run.sh --expected-by <plan>` filters test subset via `# EXPECTED_BY: <plan-id>` test-file tag. Each downstream plan asserts only its target subset.
- **Item 7 — D-03 auto-approve widened:** `cluster_is_autoapproveable()` returns True for `confidence=high` + (explicit frontmatter type OR 3+ non-frontmatter signals agree). Locked by `test_01_highconf_multisignal_autoapprove.sh`.
- **Item 8 — Python hashlib:** zero shell `sha256sum` in migration scripts or suggest branch. Locked by `test_hashlib_not_sha256sum.sh`.
- **Item 9 — Operational D-09 enforcement:** `verify` WARNs on stale candidate artifacts (`source_script_hash` drift). Non-blocking. Locked by `test_verify_stale_artifact_warn.sh`.
- **Item 10 — Documented per-script applied.log variance:** `schema/brownfield/migrations/README.md` + AGENTS.md §11.5.4 enumerate per-script block shapes. Locked by split `test_applied_log_apply_schema.sh` assertions.
- **Item 11 — Override-label validation:** review-typing validates against `VALID_ENUMS['type']` at entry; invalid labels rejected before write. Locked by `test_review_typing_validates_override_label.sh`.

## Affected Pages

The following artifacts are created or substantially modified by Phase 11 to implement this decision:

- AGENTS.md §11.5 Brownfield Workflow (new authoritative contract, incorporating items 1, 2, 9, 10 anchors)
- AGENTS.md §11.6 Release Workflow (renumbered from §11.5 — Option C per RESEARCH Pitfall 1)
- CLAUDE.md (byte-sync mirror of AGENTS.md via `.githooks/pre-commit`)
- schema/AGENTS.template.md (template mirror of §11.5 + §11.6)
- schema/fixtures/canonical-AGENTS.md (regenerated canonical fixture)
- docs/reference/brownfield.md (operator runbook: suggest + review-typing + verify sections populated; troubleshooting table includes item-4/item-9/item-11 entries)
- schema/brownfield/migrations/01-page-typing.sh (new apply-class canonical script; paired inputs + root resolution)
- schema/brownfield/migrations/02-provenance-bootstrap.sh (new apply-class; top-level-only regex + direct-apply applied.log variance)
- schema/brownfield/migrations/03-cross-link-inference.sh (new advisory-class; root resolution)
- schema/brownfield/migrations/04-privacy-review.sh (new advisory-class; root resolution)
- schema/brownfield/migrations/README.md (per-script applied.log variance schema per item 10)
- bin/brownfield.sh (new subcommands: suggest, review-typing, verify; stale-artifact WARN in verify; EOF-safe prompt loop in review-typing)
- bin/lib/brownfield_classify.py (new `cluster_by_signals()` + `cluster_is_autoapproveable()`)
- bin/lib/brownfield_provenance.py (new module for 02 eligibility heuristics; top-level-only regex)
- bin/lib/brownfield_walk.py (new shared walker per item 3 — consumed by both scan and suggest)
- .planning/REQUIREMENTS.md (BRWN-12 rename; BRWN-22 added with EOF + label-validation wording; traceability updated)

## Sources

- .planning/phases/11-brownfield-suggest-verify/11-CONTEXT.md (21 locked decisions D-01..D-21)
- .planning/phases/11-brownfield-suggest-verify/11-RESEARCH.md (Q1–Q11 research answers; Pitfall 1 renumbering analysis)
- .planning/phases/11-brownfield-suggest-verify/11-PATTERNS.md (analog pattern map)
- .planning/phases/11-brownfield-suggest-verify/11-REVIEWS.md (cross-AI review — Gemini + Codex; items 1–15 — HIGH 1-4, MEDIUM 5-10, LOW 11-15)
- .planning/research/FEATURES.md §Bucket 5 (anti-feature list)
- .planning/research/PITFALLS.md §C-2, §C-3 (frontmatter corruption + idempotency)

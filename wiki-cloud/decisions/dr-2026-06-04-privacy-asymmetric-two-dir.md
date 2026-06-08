---
id: dr-2026-06-04-privacy-asymmetric-two-dir
title: "Asymmetric Two-Directory Privacy: wiki-cloud/ + wiki-local/"
type: decision
status: active
summary: "Converts per-page privacy frontmatter to structural directory-tier enforcement:
  wiki-cloud/ (cloud-safe) + wiki-local/ (local-only), removing the privacy field,
  seven-row decision table, three-level precedence, and page-inheritance machinery."
created_at: 2026-06-04
updated_at: 2026-06-04
sources: []
epistemic_status: sourced
tags:
- meta
- schema
- privacy
domains:
- wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
- dr-2026-06-04-privacy-asymmetric-two-dir
has_contradictions: false
knowledge_domain: software
neutrality_exempt: true  # affected_pages + ## Affected Pages legitimately name the canonical DR id dr-2026-04-15-kahneman-to-examples (and other dr- ids); slugs are structurally fixed and cannot be reworded. Mirrors wiki-cloud/index.md:17 / dr-2026-04-16-progressive-disclosure-extraction.md:27 precedent.
trigger_type: schema-update
affected_pages:
- index
- log
- dr-2026-04-14-phase6-decision-type
- dr-2026-04-15-kahneman-to-examples
- dr-2026-04-16-progressive-disclosure-extraction
- dr-2026-04-20-brownfield-apply-vs-advisory
- dr-2026-05-01-complementary-systems-boundary
- dr-2026-06-02-sc1-examples-isolable-subgraph
- dr-2026-06-02-obsidian-filename-alias-resolution
- dr-2026-06-03-uniform-piped-links
---

## TL;DR

Phase 15 converts privacy from a **per-page agent-remembered rule** (§13 three-level frontmatter precedence + `privacy` field on every page) to a **structural, directory-enforced property**. Two tiers: `wiki-cloud/` (cloud-safe, readable by cloud sessions) and `wiki-local/` (local-only, forbidden to cloud sessions). The per-page `privacy` field is stripped from all pages, templates, lint, and generated maintenance files. The seven-row Privacy Decision Table, Three-Level Precedence narrative, and page-inheritance block are removed from §13 — which reduces to a one-line structural pointer.

## Decision

Adopt the **asymmetric two-directory model**:

- `wiki-cloud/` — cloud-safe tier. All existing wiki pages move here; cloud sessions read freely.
- `wiki-local/` — local-only tier. Subdirectories created on demand (D-06). Audit control-plane (`audit-report.md`, `audit-state.md`) lives here.
- The `privacy` frontmatter field is removed from the base-field set entirely.
- Privacy classification = the directory the page lives in. No per-page override.
- `sources/` remains cloud-safe-only. Local sources live as their source-summary page under `wiki-local/sources/`.
- The FAITH-04 effective-claim privacy predicate collapses to: a claim is local iff its page OR any contributing source-summary is under `wiki-local/`.
- A FAIL-CLOSED CI guard (`bin/check-sources-cloud-safe.sh`) asserts the `sources/` cloud-safe-only invariant.

## Why

The prior framing was the **implicit per-page §13 precedence/inheritance model**: every wiki page carried a `privacy: local_only | cloud_safe` frontmatter field, and a three-level precedence ladder (explicit field > enclosing directory > fail-closed default) resolved effective privacy. The agent was required to remember and honor the field on every operation.

This model had three compounding problems:
1. **Agent-remembered, not structural.** A cloud session could read any page; enforcement depended entirely on the agent following the §13 rule each turn.
2. **Fragile inheritance chain.** The three-level precedence and stricter-wins inheritance created edge cases (e.g., a `cloud_safe` page citing a `local_only` source should inherit `local_only`, but only if the agent checked every source before writing).
3. **Bloated resident core.** The full §13 machinery (table + precedence + inheritance + FAITH-04 predicate) lived in the always-loaded MUST-list, consuming context window on every session.

The asymmetric two-directory model replaces all of this with a **structural invariant**: cloud sessions simply cannot see `wiki-local/` files (enforced by directory boundary + harness permissions). No per-turn agent judgment required. The resident §13 obligation collapses to a one-line pointer (PRIV-07, D-16).

## Alternatives Considered

- **Option 1: Per-page mixed model (status quo before Phase 15).** Keep `privacy: local_only | cloud_safe` on every page. Pro: no directory migration. Con: agent-remembered enforcement is unreliable; any cloud session can read any page if the agent ignores the field. The boundary is as strong as the agent's discipline, not the filesystem. **REJECTED** — fails the honest-contract principle (D-12); ships false assurance.

- **Option 2: Per-vault fully separate repos.** Put all wiki content in a dedicated `wiki-private` git repo gitignored from the parent; the parent contains only `wiki-cloud/` content. Pro: genuine object-level isolation for all content. Con: requires a two-repo workflow for every vault, breaking the unified Obsidian graph for every user, including those with no local content. **REJECTED** — too disruptive for the common case (most users start with zero local content); the separate-repo pattern is documented as the high-sensitivity option (D-13) but not mandated.

- **Option 3: Asymmetric two-directory model (CHOSEN).** `wiki-cloud/` and `wiki-local/` coexist in one vault; `wiki-local/` subdirs are created on demand. One-way permeability: local sessions read both; cloud sessions read only `wiki-cloud/`. Pro: dominates Option 1 on safety (structural, not agent-remembered) and simplicity (no per-page field); keeps the only synthesis direction worth having (local→cloud is the leak, cloud→local is not meaningful). The high-sensitivity separate-repo escalation path (D-13) is available for real secrets. **CHOSEN**.

## Consequences

- All 56 existing wiki pages migrated: 54 to `wiki-cloud/`, 2 audit control-plane files to `wiki-local/maintenance/`.
- The `privacy` frontmatter field is stripped from all pages, templates, examples, lint's BASE_FIELDS + VALID_PRIVACY enum, and generated audit/lint maintenance file templates.
- `bin/lint.sh` no longer raises a yaml error for pages missing the privacy field.
- `bin/audit-claims.sh` FAITH-04 predicate collapses from the three-level ladder to the single path-prefix check: `page or source-summary under wiki-local/ → local_only`.
- `bin/check-neutrality.sh` `source_local_only_wiki()` re-keyed from privacy-frontmatter grep to wiki-local/ directory walk.
- `bin/check-privacy.sh` re-keyed from frontmatter grep to structural PATH guard (wiki-local/ path under PUBLIC_PATHS).
- Raw `sources/` structural rule: cloud-safe-only. A future local raw source fails CI (via `bin/check-sources-cloud-safe.sh`) and forces the deferred `sources-local/` tier (documented in `docs/reference/privacy-model.md`).
- §13 resident obligation reduces to one line; privacy leaves the always-loaded MUST-list (PRIV-07).
- Cloud sessions that navigate to `wiki-local/` via `git show HEAD:wiki-local/…` CAN access content on a shared-history clone — the deny-profile is FAIL-OPEN. The genuinely fail-closed pattern (separate nested repo) is documented as the high-sensitivity escalation path (D-13 in CONTEXT.md).

## Affected Pages

All wiki pages were migrated (54 to `wiki-cloud/`, 2 to `wiki-local/maintenance/`). Key schema pages affected:

- `wiki-cloud/index.md` — renamed from `wiki/index.md`; no longer lists privacy field in example entries
- `wiki-cloud/log.md` — renamed from `wiki/log.md`
- All existing decision record pages (`dr-2026-04-14-phase6-decision-type`, `dr-2026-04-15-kahneman-to-examples`, `dr-2026-04-16-progressive-disclosure-extraction`, `dr-2026-04-20-brownfield-apply-vs-advisory`, `dr-2026-05-01-complementary-systems-boundary`, `dr-2026-06-02-sc1-examples-isolable-subgraph`, `dr-2026-06-02-obsidian-filename-alias-resolution`, `dr-2026-06-03-uniform-piped-links`) — privacy field stripped.

## Sources

- `.planning/phases/15-privacy-architecture/15-CONTEXT.md` — implementation decisions D-01..D-16 (the locked design choices this record implements)
- `.planning/milestones/v1.2-MILESTONE-BRIEF.md` — the accepted asymmetric two-dir decision, three weighed options, enforcement rationale
- `docs/reference/privacy-model.md` — full asymmetric model reference, enforcement options, fail-direction table, `sources-local/` forward reference

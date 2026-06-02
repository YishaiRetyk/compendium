# Requirements: LLM Wiki Compiler — v1.1.1 Graph Integrity

**Defined:** 2026-06-02
**Core Value:** The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Milestone Focus:** Make the Obsidian graph actually connect. Obsidian resolves `[[X]]` by filename + `aliases`, never by `title`; pages are slug-named and linked by spaced `[[Title]]` that isn't aliased, so 31/49 pages render as orphans. Correct the convention, enforce it mechanically, and remediate `wiki/` + `examples/` data. Patch milestone, sequenced before the v1.2 schema refactor (999.4).

Numbering continues from v1.1. New REQ-ID prefix: `LINK`.

---

## v1.1.1 Requirements

### Convention & Schema (Phase 14)

- [ ] **LINK-01**: `CLAUDE.md` §8 states the real Obsidian resolution rule — `[[X]]` resolves by **filename + `aliases`**, never by the `title` frontmatter — replacing the false "wikilinks resolve to this `title` value" claim.
- [ ] **LINK-02**: The self-alias invariant is documented and templated — every page's `aliases` MUST include its `title` and `id` slug; §5 frontmatter validation checklist gains a `title ∈ aliases` item; `schema/templates/*.md` and `schema/obsidian/*.md` ship the self-alias; `AGENTS.md` stays byte-identical to `CLAUDE.md`.
- [ ] **LINK-03**: A decision record (`trigger_type: schema-update`) documents the title-vs-filename resolution reality and the chosen self-alias fix (vs. rejected alternatives: rename files to titles, rewrite links to slugs).

### Lint Enforcement (Phase 15)

- [ ] **LINK-04**: `bin/lint.sh` gains an Obsidian-accurate link-resolution check (category `linkres`) that flags any page whose `title` is not reachable (`title ∉ {filename, aliases}`).
- [ ] **LINK-05**: The check flags intra-wiki `[[link]]`s that do not resolve under Obsidian-accurate matching, **distinguishing** genuine knowledge-gap red links (allowed per §3) from should-resolve-but-mismatched links (bug — plural/parens/casing variants).
- [ ] **LINK-06**: `bin/lint.sh --fix` auto-backfills the self-alias (`title`, `id`) into frontmatter, idempotently; the existing `orphan` check is reconciled so it no longer masks unresolved links; tests cover the new behavior so it cannot regress.

### Data Remediation (Phase 16)

- [ ] **LINK-07**: All `wiki/` pages carry self-aliases; `bin/lint.sh --category linkres` exits 0 over `wiki/`.
- [ ] **LINK-08**: Link-text variants across `wiki/` (plural/parens/casing mismatches such as `[[Bounded Contexts]]`, `[[Hack (Agentive Stack)]]`) are reconciled so every should-resolve intra-wiki link resolves.
- [ ] **LINK-09**: `examples/` pages (kahneman cluster + dataview-fixtures) carry self-aliases and resolve, respecting `example: true` / lint-skip conventions, so the reference cluster forms a clean connected sub-graph.
- [ ] **LINK-10**: Human-verified in Obsidian — opening the vault at the repo root (`hideUnresolved` on) shows a connected graph; `domain-driven-design.md` and the other previously-orphaned pages are no longer orphans.

---

## Future Requirements (deferred)

- Near-duplicate page-title detection (`duplicate` lint category) — pending todo `a1-lexical-dedup-lint-category`; adjacent to LINK-08 variant reconciliation but distinct (detects near-dup *pages*, not link/title mismatches). Promote via `/gsd-quick`.
- v1.2 schema progressive-disclosure refactor (backlog 999.4) — moves §8 et al. to `schema/reference/`; depends on §8 being correct first (this milestone).

## Out of Scope

- Renaming wiki files to spaced titles — breaks `id == filename` (§5), provenance source IDs, and tooling.
- Rewriting body links to slug form (`[[domain-driven-design]]`) — abandons the readable `[[Exact Page Title]]` convention (§8).
- Shipping an `.obsidian/` config in the template (graph filters, excluded files) — the template keeps `.obsidian/` untracked/minimal; graph hygiene stays a per-user setting.
- New wizard/setup features, new page types, or schema expansion beyond the resolution fix.

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| LINK-01 | Phase 14 | Pending |
| LINK-02 | Phase 14 | Pending |
| LINK-03 | Phase 14 | Pending |
| LINK-04 | Phase 15 | Pending |
| LINK-05 | Phase 15 | Pending |
| LINK-06 | Phase 15 | Pending |
| LINK-07 | Phase 16 | Pending |
| LINK-08 | Phase 16 | Pending |
| LINK-09 | Phase 16 | Pending |
| LINK-10 | Phase 16 | Pending |

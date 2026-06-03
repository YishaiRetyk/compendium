# Requirements: LLM Wiki Compiler — v1.1.1 Graph Integrity

**Defined:** 2026-06-02
**Core Value:** The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Milestone Focus:** Make the Obsidian graph actually connect. Obsidian resolves `[[X]]` by **filename/path ONLY** — never via the `title` or `aliases` frontmatter (intentional design, confirmed for v1.12.7). Pages are slug-named but linked by spaced `[[Title]]`, so the multi-word-title pages render as orphans. Fix: adopt **uniform piped links** `[[id|Title]]` (target = page `id` == filename, always resolves; display = readable title) — correct the convention, enforce it mechanically (`linkres` validates link *targets*), and remediate `wiki/` + `examples/` data. Patch milestone, sequenced before the v1.2 schema refactor (999.4).

> ⚠️ **Premise corrected 2026-06-03.** LINK-01..10 below were rewritten after the self-alias
> approach was proven false at the LINK-10 human-verify gate. Aliases do NOT resolve bare `[[X]]`
> links. See `.planning/phases/14-graph-link-resolution/14-FINDINGS-premise-invalidated.md` and
> `14-CONTEXT.md` (D-01..D-09).

Numbering continues from v1.1. New REQ-ID prefix: `LINK`.

---

## v1.1.1 Requirements

### Convention & Schema (Phase 14, Wave 1)

- [ ] **LINK-01**: `CLAUDE.md` §8 (+ §5 `title` field note) states the real Obsidian resolution rule — `[[X]]` resolves by **filename/path ONLY**, never by the `title` frontmatter and never by `aliases` — and **mandates the uniform piped-link form** `[[id|Exact Title]]` (target = page `id`; display = exact canonical title), replacing the old "DO NOT use display aliases" prohibition and the false "filename + aliases" claim.
- [ ] **LINK-02**: The uniform piped-link convention is documented and templated — §8 bad/good examples and the §5 frontmatter validation checklist reflect `[[id|Title]]`; the **self-alias invariant is REMOVED** from §5/§8/`schema/templates/*.md`/`schema/obsidian/*.md` (`aliases` reverts to an OPTIONAL field for genuine alternate names); `schema/AGENTS.template.md` mirrors the §5/§8 edits; `AGENTS.md` stays byte-identical to `CLAUDE.md`.
- [ ] **LINK-03**: A decision record (`trigger_type: schema-update`) documents the real resolution rule (filename/path only) and the uniform-piped-link decision, and **supersedes** the wrong-premise `dr-2026-06-02-obsidian-filename-alias-resolution` (`supersedes`/`superseded_by` set per §9; rejected alternatives recorded: self-aliases [don't resolve], plugin [dependency/fragility/v1.2], bare slug [unreadable], rename files [breaks `id == filename`/provenance]).

### Lint Enforcement (Phase 14, Wave 1)

- [ ] **LINK-04**: `bin/lint.sh`'s `linkres` category is re-pointed to validate intra-wiki link **targets**: a piped `[[id|...]]` whose `id` is a known page is OK; a bare `[[X]]` (no pipe) is a `linkres` **error**; a piped `[[target|...]]` whose `target` is not a known `id` is a `linkres` **error**. The `orphan` check is reconciled to resolve by `id`/filename only (it must not use `title` as a resolver).
- [ ] **LINK-05**: `linkres` distinguishes a deliberate not-yet-existing-`id` target (knowledge-gap red link — stays `gap`/info, allowed per §3) from a bare/broken link (`linkres` error). No title-normalization is needed on the gating path (exact `id` match).
- [ ] **LINK-06**: `bin/lint.sh --fix` is re-pointed to rewrite bare `[[X]]` → `[[id|X]]` for a **unique** match (by `id`/`title`/alias/conservative-normalized match, preserving `X` as display text); a multi-match emits a warning for manual disambiguation (no rewrite); a no-match stays a knowledge-gap red link. Idempotent. Tests cover bare-link error, unknown-target error, unique-match `--fix`, multi-match warning, and knowledge-gap exclusion so it cannot regress.

### Data Remediation (Phase 14, Wave 2)

- [x] **LINK-07**: All `wiki/` body links are rewritten to uniform piped form `[[id|Title]]`; `bin/lint.sh --category linkres` exits 0 over `wiki/`. (The 53 vestigial self-aliases shipped by the prior run stay — harmless residue, per CONTEXT D-07.)
- [x] **LINK-08**: Variant reconciliation is **DISSOLVED** (CONTEXT D-06): under uniform piping, plural/parens/casing live in the cosmetic display text and resolve via the `id` target with zero reconciliation — `[[Bounded Contexts]]` → `[[bounded-context|Bounded Contexts]]` and `[[Hack (Agentive Stack)]]` → `[[hack-agentive-stack|Hack (Agentive Stack)]]` both resolve. Verified: no should-resolve intra-wiki link in `wiki/` remains unresolved after the rewrite.
- [x] **LINK-09**: `examples/` pages (kahneman cluster + dataview-fixtures) body links are rewritten to uniform piped form and resolve, respecting `example: true` / lint-skip conventions, so the reference cluster forms a clean connected sub-graph.
- [x] **LINK-10**: Human-verified in Obsidian — opening the vault at the repo root (`hideUnresolved` on) shows a connected graph; `domain-driven-design.md` (connected via piped inbound links) and the other previously-orphaned pages are no longer orphans.

---

## Future Requirements (deferred)

- Near-duplicate page-title detection (`duplicate` lint category) — **delivered** 2026-06-02 via quick task `260602-d6a` (`LINT_VERSION 1.4.0`); detects near-dup *pages* (distinct from `linkres`, which validates link *targets*). Phase 14's re-pointed `linkres` check slots in alongside this existing `duplicate` category. (Note: the old LINK-08 "variant reconciliation" is dissolved under uniform piped links — see LINK-08.)
- v1.2 schema progressive-disclosure refactor (backlog 999.4) — moves §8 et al. to `schema/reference/`; depends on §8 being correct first (this milestone).

## Out of Scope

- Renaming wiki files to spaced titles — breaks `id == filename` (§5), provenance source IDs, and tooling.
- Bare slug body links `[[domain-driven-design]]` (no display text) — resolves but shows raw slugs in reading view (unreadable); the new convention is the piped form `[[domain-driven-design|Domain-Driven Design]]` which resolves AND reads cleanly (§8).
- Bundling an Obsidian resolver plugin — rejected (CONTEXT D-01): violates §1 "plain markdown regardless of tooling", depends on an undocumented internal API, and "Obsidian plugin distribution" is v1.2-deferred.
- Shipping an `.obsidian/` config in the template (graph filters, excluded files) — the template keeps `.obsidian/` untracked/minimal; graph hygiene stays a per-user setting.
- New wizard/setup features, new page types, or schema expansion beyond the resolution fix.

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| LINK-01 | Phase 14 | Pending |
| LINK-02 | Phase 14 | Pending |
| LINK-03 | Phase 14 | Pending |
| LINK-04 | Phase 14 | Pending |
| LINK-05 | Phase 14 | Pending |
| LINK-06 | Phase 14 | Pending |
| LINK-07 | Phase 14 | Complete |
| LINK-08 | Phase 14 | Complete |
| LINK-09 | Phase 14 | Complete |
| LINK-10 | Phase 14 | Complete |

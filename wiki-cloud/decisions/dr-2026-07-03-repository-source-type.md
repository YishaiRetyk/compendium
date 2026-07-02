---
id: dr-2026-07-03-repository-source-type
title: "Repository as a New Primary Source Type (#path/#commit Locators + Excerpt Registry)"
type: decision
status: active
summary: "Records that repository is a first-class source_type — the extension
  contract's first primary new-type instance (locator, drift, and acquisition
  change unconditionally; epistemics structurally) — with a curated snapshot
  bundle (never a full clone), an Excerpts registry that makes #path: locators
  audit-resolvable offline, a within-source epistemic split, required
  drift-anchor frontmatter, and mechanical-only acquisition glue."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-07-03-repository-source-type
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages:
  - gsd
  - src-2026-07-03-gsd-core-repo
---

# Repository as a New Primary Source Type (#path/#commit Locators + Excerpt Registry)

## TL;DR

Phase 22 adds `source_type: repository` as a **first-class enum value** — the extension contract's first *primary* new-type instance, and the inverse verdict of the Phase 20/21 sub-case evaluations, reached by the same rule. Walking the 5 dimensions: **Locator** changes unconditionally (`#path:<file>[:L<n>[-L<m>]]` and `#commit:<sha>` are new grammar), **Drift** changes unconditionally (the first `live`-upstream type — every other type is static or published-immutable), **Acquisition** changes unconditionally (curated VCS snapshot), and **Epistemic Default** changes structurally (a within-source claim-class split). The raw source is a **curated snapshot bundle, never a full clone**, whose `## Excerpts` registry makes `#path:` locators resolvable offline by the audit — the same registry pattern as research-report's `## References`.

## Decision

1. **New primary type, not a sub-case (D-01).** Four of five contract dimensions change; a convention note on an existing type cannot express new locator grammar or a live-drift stance. Registry row finalized in `schema/reference/source-types.md`; authoritative convention in `schema/reference/repository-ingestion.md`.
2. **Minimal locator grammar (D-02):** `#path:` (with optional `:L<n>[-L<m>]` ranges relative to the snapshot commit) and `#commit:` (≥7-hex prefix of the snapshot's `commit_sha`). `#issue:`/`#pr:` deferred (tracked as IPR) — the snapshot cannot resolve them, so they would be unresolvable-by-construction.
3. **Snapshot bundle + Excerpts registry (D-03/D-04):** metadata section + curated README/docs + `### <path>[:L<a>-L<b>]`-headed code excerpts. Rule of thumb: *if you anchor a claim to code, quote the code.* Missing excerpt → `insufficient-locator` (the honest-degradation precedent of `#p`/`#r`).
4. **`#commit:` resolves only to the snapshot's own commit (D-05)** — the snapshot documents exactly one commit; claims about other commits have no local evidence.
5. **Required drift-anchor frontmatter (D-06):** `repo_url` + `commit_sha` (full 40-hex) + `default_branch`, lint-enforced (LINT_VERSION 1.11.0). Unlike the video sub-case, the type IS the mechanical trigger, so a conditional lint check involves no guessing. `license`/`primary_language`/`stars_at_ingest` recommended, omitted when unknown.
6. **Within-source epistemic split (D-08):** code/benchmark/metadata claims `sourced`; README self-descriptive capability claims MUST carry claim-level `[epistemic:: tentative]` even on `sourced` pages. `support_type` stays `direct` throughout — snapshotting is extraction, not derivation; marketing risk lives on the epistemic axis, never the support axis (the PDF/video principle).
7. **Drift stance: fields now, machinery next phase (D-07).** The snapshot is immutable and claims remain faithful to it; what drifts is the upstream (`HEAD ≠ commit_sha`, or link-rot). Surfaced review-only by the external drift checks; re-snapshot = a NEW ingest, superseding normally.
8. **Mechanical-only glue (D-09):** `bin/repo-snapshot.sh` shallow-clones, harvests metadata, and scaffolds the bundle; curation (docs selection, excerpt choice) stays judgment work — the brownfield mechanical-vs-judgment boundary applied to acquisition.

## Why

The wiki already absorbed repositories informally as entity pages with report-derived claims; formalizing the type turns "claims about code" into verifiable, audit-resolvable provenance and gives the external drift detector its cleanest anchor (a commit SHA gives precise identity AND a diff). The validation ingest proved the value immediately: the documented home of a tracked project turned out to be an archived redirect — a live external-drift case caught by the acquisition runbook one phase before the drift detector ships — and the entity's report-derived point-in-time facts were upgraded/superseded by primary evidence.

## Alternatives Considered

- **Sub-case of `article`/`data` (rejected):** cannot carry the new locator grammar or the live-drift dimension; would erase exactly what makes a repository a different kind of source.
- **Full clone as raw source (rejected):** the wiki compiles *claims about* the repo; a clone bloats `sources/` with unaddressed content and still would not make line-anchored claims verifiable without a registry discipline.
- **`#path:` resolving against a cloned tree (rejected):** requires keeping clones forever and re-fetching at audit time; the Excerpts registry keeps the audit offline and the evidence curated.
- **`#issue:`/`#pr:` locators now (deferred):** no snapshot representation; add when a claim actually needs one.
- **Lint-optional metadata like the video sub-case (rejected):** here the `source_type` value is an unambiguous mechanical trigger, so the PDF-style conditional required-fields check applies cleanly.

## Consequences

- The enum grows to 8; the retro-fit table now contains a worked primary new-type instance alongside the worked secondary one (`research-report`) — future candidates have both poles to compare against.
- `bin/audit-claims.sh` gained `_resolve_path` (fence-aware — quoted markdown headings inside excerpt fences must not truncate the registry; found live on the first real ingest) and `_resolve_commit`, dispatched before `#para`/`#p` (shared-prefix hazard, D-11).
- Phase 23's external drift checks consume `repo_url`/`commit_sha`/`default_branch` as their pilot case.

## Affected Pages

- [[gsd|GSD (Get-Shit-Done)]] — first entity upgraded with repository-direct claims (rename/continuation evidence; superseded-in-part report facts).
- [[src-2026-07-03-gsd-core-repo|open-gsd/gsd-core — GSD Core repository snapshot]] — the validation ingest.

## Sources

- `schema/reference/repository-ingestion.md` (authoritative convention this DR records the rationale for)
- `.planning/phases/22-repository-source-type/22-CONTEXT.md` (D-01..D-12 design decisions)

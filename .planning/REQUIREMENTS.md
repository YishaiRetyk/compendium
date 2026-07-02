# Requirements: LLM Wiki Compiler — Milestone v1.4 Source Lifecycle

**Defined:** 2026-07-03
**Core Value:** The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.

## v1.4 Requirements

Requirements for milestone v1.4 Source Lifecycle. Each maps to roadmap phases.

Design lineage: `.planning/seeds/primary-source-type-extensions.md` Candidate A (repository — the seed's leaning "distinct type" is confirmed here via the Phase-19 extension contract), ROADMAP.md Backlog 999.5 (External Source Drift Detection — explicitly deferred at v1.3 start with "design alongside or after RPT registries exist"; they now exist), and `milestones/v1.3-REQUIREMENTS.md` Future Requirements (DRIFT + REPO — "pairs with 999.5; sequence them together later"). The `drift-external` logical subcategory and its CI default-skip were pre-plumbed in Phase 9 (D-02/D-06) and are the designed landing slot for the network checks.

### Repository Source Type (REPO)

- [ ] **REPO-01**: `source_type: repository` is justified via the extension contract's decision rule (changes ≥1 of the 5 dimensions — here: locator scheme, drift mechanism, acquisition, epistemic handling), recorded in the contract's retro-fit table, and added to the frontmatter enum + ingest Pass-0 classification
- [ ] **REPO-02**: New locators `#path:<file>[:L<n>[-L<m>]]` and `#commit:<sha>` are documented in the provenance locator table; `bin/audit-claims.sh` resolves `#path:` locators against the snapshot's excerpt registry (absent excerpt → `insufficient-locator`, honest degradation)
- [ ] **REPO-03**: A documented repository acquisition runbook exists in `schema/reference/` producing a curated snapshot bundle — README + key docs + an addressable excerpt registry + metadata frontmatter (`repo_url`, `commit_sha`, `default_branch`, `license`, `primary_language`) — explicitly NOT a full clone; thin acquisition glue in `bin/` scaffolds the snapshot
- [ ] **REPO-04**: The convention documents the within-source epistemic split — code/benchmark claims (`#path:`-anchored) at `sourced`, self-descriptive capability claims claim-level `[epistemic:: tentative]` — and assigns `knowledge_domain: software` decay
- [ ] **REPO-05**: Lint enforces the type — D-09 enum extended with `repository`; conditional required-fields check (repository sources must carry `repo_url` + `commit_sha`); LINT_VERSION bumped
- [ ] **REPO-06**: End-to-end validation — one real repository acquired via the runbook, ingested, wiki pages carry `#path`-anchored provenance, and a source-scoped audit run is non-vacuous (locators resolve)

### External Source Drift Detection (DRIFT)

- [ ] **DRIFT-01**: External drift checks land as an opt-in `--network` extension of lint's existing `drift`/`EXTERNAL:` subcategory — without the flag lint behavior is byte-identical to today; `--ci` continues to default-skip `drift-external`; no core workflow gains a mandatory network dependency
- [ ] **DRIFT-02**: Repository sources — upstream default-branch HEAD is compared to the recorded `commit_sha` (`git ls-remote`, no clone): drifted → warning, unreachable → warning, current → no finding
- [ ] **DRIFT-03**: URL-backed sources — recorded `url` frontmatter is reachability-checked (dead/gone → warning, redirect → info); research-report citation registries get a sampled link-rot ratio finding with thresholds
- [ ] **DRIFT-04**: The drift stance is review-only and documented — findings flow through the standard lint report; no page mutation or auto-re-ingest; follow-up guidance (re-snapshot vs annotate via UPDATE op) lives in `schema/workflows/lint.md`; video sources are excluded per the shipped D-06 link-rot stance; a decision record captures the narrowed "surface, don't mark stale" choice vs the 999.5 sketch
- [ ] **DRIFT-05**: Real-run validation — `--network` executed over the live wiki (including the Phase-22 repository source and the URL-backed article/report sources); findings triaged and follow-ups logged

## Future Requirements

Deferred. Tracked but not in the current roadmap.

### Content-Change Detection

- **CCD**: Content-hash / ETag-based change detection for URL-backed sources (beyond reachability) — noisy for dynamic HTML; revisit when a concrete false-freshness incident occurs

### Issue/PR Locators

- **IPR**: `#issue:<n>` / `#pr:<n>` repository locators — deferred until a claim actually needs to cite an issue or PR (snapshot bundles do not capture them)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Full repo cloning / code-as-claims wholesale ingest | The wiki compiles *claims about* the repo via excerpt-backed locators, not the repo itself (seed Candidate A non-goal) |
| Auto-crawling repos or channels | "No broad web-ingestion system" — standing 999.5 non-goal |
| Auto re-ingest on upstream drift | Drift *flags*; the human decides (999.5 non-goal: no automatic re-compilation) |
| Automatic stale-marking from external drift | Claims cite the immutable snapshot and remain faithful to it; upstream movement is surfaced, not auto-propagated into page status (recorded in the Phase-23 DR) |
| Semantic content-diffing of changed upstreams | Requires fetching + diffing full content; reachability + SHA comparison is the honest v1 signal |
| Video drift machinery | Explicitly settled by D-06 (v1.3 Phase 21): committed transcript is the durable archive |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | Phase 22 | Pending |
| REPO-02 | Phase 22 | Pending |
| REPO-03 | Phase 22 | Pending |
| REPO-04 | Phase 22 | Pending |
| REPO-05 | Phase 22 | Pending |
| REPO-06 | Phase 22 | Pending |
| DRIFT-01 | Phase 23 | Pending |
| DRIFT-02 | Phase 23 | Pending |
| DRIFT-03 | Phase 23 | Pending |
| DRIFT-04 | Phase 23 | Pending |
| DRIFT-05 | Phase 23 | Pending |

**Coverage:**
- v1.4 requirements: 11 total
- Mapped to phases: 11 (100%)

---
*Last updated: 2026-07-03 after roadmap creation (traceability filled)*

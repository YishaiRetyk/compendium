# Phase 13: Claim Faithfulness Audit — Discussion Log

**Date:** 2026-05-31
**Mode:** discuss (default)
**Note:** For human reference only (audit/retrospective). Not consumed by downstream agents — see `13-CONTEXT.md` for the canonical decisions.

## Inputs loaded
- `.planning/ROADMAP.md` (Phase 13 entry), `.planning/REQUIREMENTS.md` (FAITH-01..04), `.planning/PROJECT.md`, `.planning/phases/13-claim-faithfulness-audit/13-DESIGN-NOTES.md` (146 lines, primary input), `.planning/seeds/wiki-quality-heuristics.md`, `.planning/phases/12.2-local-wiki-write-gate/12.2-CONTEXT.md` (house style).

## Process note
- A broken `init.sh` path early in the session cancelled a batched tool block; before real file contents were loaded, a CONTEXT draft based on assumptions was begun. That draft was discarded — it never reached disk (working tree confirmed clean). All decisions below are grounded in the actual `13-DESIGN-NOTES.md`. The design notes' own "Open Questions for discuss-phase" framed the gray areas.

## Gray areas presented (all four selected by user)
1. Verifier + privacy contract
2. Page-locator gap
3. Sampling defaults + cadence
4. contradicts → marker handoff

## Area 1 — Verifier + privacy contract
- **1a Verifier deliverable** — options: Contract only (Rec) / Contract + reference scripts / Agent-only no hook. **Chosen: Contract only.**
- **1b local_only egress** — user paused to clarify first (cares that FAITH-04 is mechanically enforced, not just documented). After clarification: options Fail-closed + explicit local opt-in (Rec) / Attest flag / Doc-only. **Chosen: Fail-closed**, and confirmed `skipped-privacy` on `local_only` is acceptable UX.
- → D-01, D-02, D-03.

## Area 2 — Page-locator gap
- **Marker syntax** — HTML comment `<!-- page: N -->` (Rec) / frontmatter offset map / visible delimiter. **Chosen: HTML comment.**
- **Required vs optional** — Optional + insufficient-locator fallback (Rec) / Required. **Chosen: Optional + fallback.**
- **Insertion** — Human at source-add (Rec) / ingest auto-insert / Document now, helper later. **Chosen: Document now, helper later.**
- **Note:** user OVERRODE the design-note recommendation (which deferred the convention to v1.2) — wants it shipped in v1, but accepted the minimal/additive shape. → D-04, D-05, D-06, D-07.

## Area 3 — Sampling defaults + cadence
- **3a Cadence** — On-demand + reflect suggestion (Rec) / On-demand only / Periodic. **Chosen: On-demand + reflect-tier suggestion.**
- **3b Sample default** — 20 priority-ranked union (Rec) / 10 / no cap. **Chosen: 20, priority-ranked union** (stale-source → inferred/tentative → recently-modified → high-fanout; log selected-vs-skipped).
- → D-08, D-09.

## Area 4 — contradicts → marker handoff
- Defined handoff, human-approved (Rec) / report-only no handoff / defer to v1.2. **Chosen: Defined human-approved handoff** (separate explicit op adds `[epistemic:: tentative]`/`[contradiction:]`; never automatic).
- → D-10.

## Carried forward from design notes (not re-asked)
- Raw-source-at-`path:` verification (anti-circularity); 4-way verdict + operational verdicts; zero new claim-level vocabulary; extend lint finding tuple + `audit-report.md`; `audit-state.md` checkpoint; separate script not a lint category; review-only / no-auto-fix / no-default-gate / no-SQLite / no-full-vault / no-ragas-lib (LOCKED non-goals). → D-11..D-16.

## Deferred ideas captured
- Ingest auto-insertion of page markers (v1.2); bundled reference verifiers; required markers; periodic auto-trigger; auto-promotion of contradicts; lint-category/CI-gate form; embeddings/SQLite/full-vault; elevating Audit to a 5th operation (planner's call).

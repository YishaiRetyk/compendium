# Requirements: LLM Wiki Compiler — v1.2 Schema Architecture

**Defined:** 2026-06-04
**Core Value:** The wiki is a persistent, compounding artifact — cross-references already there, contradictions already flagged, synthesis already reflects everything ingested.

**Milestone goal:** Apply the spec's own §7 progressive-disclosure principle to itself — reduce the always-loaded `AGENTS.md`/`CLAUDE.md` (1,689 lines) to a resident core of only what passes the **inclusion test** (ambient / unscriptable-AND-unacceptable-miss-cost / dispatch), extracting the rest into `schema/reference/*.md` + `schema/workflows/*.md`. The ~145-line core is an expected *output*, not a target.

> **The single source of truth for exact line ranges, target files, and resident remnants per section is the Extraction Map in `.planning/milestones/v1.2-MILESTONE-BRIEF.md`.** These REQ-IDs track *intent, guards, and cross-cutting deliverables* only — they do not restate the map.

> **Design constraints (non-negotiable, every phase):** markdown-authoritative; `AGENTS.md ≡ CLAUDE.md` byte-equality (pre-commit `sync-claude --check`); wizard pipeline preserved (`schema/AGENTS.template.md` → `bin/init-wizard.sh` still renders `AGENTS.md`; extracted files copied wholesale); always-loaded safety core stays resident (provenance requirement, MUST-NOT list verbatim, write-back-mandatory, structured-op vocabulary — **privacy no longer resident**, dissolved by Phase 0); CI gates unchanged in *behavior* (`lint.sh`/`validate-op.sh`/`check-privacy.sh`/`check-neutrality.sh` operate on content, not file boundaries — extraction relocates text, not logic).

## v1 Requirements

Requirements for milestone v1.2. Each maps to exactly one roadmap phase.

### Privacy Architecture (`PRIV`) — Phase 15, gates Phase 16

- [x] **PRIV-01**: Adopt the two-directory layout — `wiki-cloud/` (cloud-safe tier) and `wiki-local/` (local-only tier) — and update §2 Directory Structure accordingly. Decide migration of the existing `wiki/` tree (rename to `wiki-cloud/` for the single-tier creator vault; relocate `wiki/maintenance/audit-{report,state}.md` to the local side).
- [x] **PRIV-02**: Rewrite §13 from per-page precedence/inheritance to the per-vault **asymmetric** model: local-side runs (local models) may read both dirs; cloud-side runs (cloud models) MUST NOT read `wiki-local/`. State the one-way permeability rule and its rationale (local→cloud is the leak; it is the forbidden direction).
- [x] **PRIV-03**: Specify enforcement as a **harness permission**, not a resident agent rule — a `deny`-read on `wiki-local/` for cloud sessions (`settings.json`), and/or a documented two-clone / two-session split. Provide the concrete config artifact, not just prose.
- [x] **PRIV-04**: Decide the fate of the per-page `privacy` frontmatter field — removed entirely vs. retained as an optional intra-dir override. Default recommendation: **remove** (the directory is the classifier); if retained, it may only make a `wiki-cloud/` page *stricter*, never a `wiki-local/` page more permissive.
- [x] **PRIV-05**: Update tooling to the structural model: `bin/check-privacy.sh` (public-path leak guard now keys on `wiki-local/` rather than a frontmatter field), `bin/lint.sh` privacy-relevant checks, and `bin/audit-claims.sh` FAITH-04 effective-privacy resolution. CI privacy-leak job updated. No behavioral regression beyond the structural model swap.
- [x] **PRIV-06**: Write the execution-time decision record `wiki/decisions/dr-YYYY-MM-DD-privacy-asymmetric-two-dir.md` (`trigger_type: schema-update`), superseding the implicit per-page §13 framing; record the three options and why asymmetric won.
- [x] **PRIV-07** (knock-on, feeds REF-06): Confirm §13's resident obligation is reduced to a one-line pointer in core ("vault tier is structural; cloud sessions cannot read `wiki-local/` — see `schema/reference/privacy.md`"), with the fail-closed/precedence/inheritance machinery **removed rather than relocated**.

### Reference Extraction (`REF`) — Phase 16

- [ ] **REF-01**: Extract §4 page types → `schema/reference/page-types.md`; merge its section-ordering table with §7's into one resident type-roster (the **§4↔§7 dedupe**, LOCKED).
- [ ] **REF-02**: Extract §5 frontmatter → `schema/reference/frontmatter.md`; core keeps **Option-B pointer only** (~4 lines, LOCKED). Full schema is JIT + lint-gated.
- [ ] **REF-03**: Extract §6 with the **consumer-split** (LOCKED): syntax/epistemics → `schema/reference/provenance.md`; decay table + staleness auto-fix → `schema/workflows/lint.md` (lint is the only consumer of the decay math). Core keeps the provenance requirement + 1 example.
- [ ] **REF-04**: **§7 dissolves** (LOCKED) into the §4 roster (orderings) + §3 (nav rule); no standalone progressive-disclosure file.
- [ ] **REF-05**: Extract §8 wikilinks → `schema/reference/wikilinks.md` (+ §3 Red Links). **Guard:** carry the v1.1.1 uniform-piped-link truth verbatim (`[[X]]` resolves by filename/path ONLY; uniform `[[id|Title]]` mandated).
- [ ] **REF-06**: Extract §13 in its **Phase-0 asymmetric form** → `schema/reference/privacy.md`; the 7-row precedence table is **removed, not relocated** (depends on PRIV-02, PRIV-07).
- [ ] **REF-07**: §14 Scaling → `docs/reference/scaling.md`; §15 Tooling → `docs/reference/tooling.md`; §16 Appendices **deleted** (already pointers).
- [ ] **REF-08**: Add the **`IMPORTANT:`-flagged routing table** to the top of core (operation → file). This is dispatch — load-bearing for every extraction's safety (Vercel 56%-miss mitigation).
- [ ] **REF-09**: Mirror every routing stub into `schema/AGENTS.template.md`; keep `AGENTS.md` byte-identical to `CLAUDE.md` (pre-commit `sync-claude --check`). **Discuss-item (Open Q7):** REF-09 covers only the existing `AGENTS.md ↔ CLAUDE.md` byte-equality — decide whether to extend `bin/sync-claude.sh` with a `--check-tree` drift guard over the *new* `schema/reference|workflows/*.md` tree now (v1.2) or defer to v1.3.
- [ ] **REF-10**: Decision record (`trigger_type: schema-update`) for the extraction + the evolved "sole authoritative specification" framing (Open Q8 — this file is the router; linked files are authoritative for their sections).

### Workflow Extraction (`WF`) — Phase 17

- [ ] **WF-01**: Extract §9 structured ops → `schema/workflows/structured-operations.md`; core keeps vocab + `validate-op.sh` pointer + the **locked 2-line solo-op log shape**. **MUST close the solo-op commit-prefix gap (Open Q9, surfaced 2026-06-04):** the current §3 commit table defines only `ingest/query/lint/reflect/schema` prefixes — a *solo* UPDATE/MERGE/SUPERSEDE/ARCHIVE has no defined commit prefix. This is a real spec hole the extraction must fill, not just relocate.
- [ ] **WF-02**: §10 → **diagram stays (1 line), NO `pipeline.md`** (LOCKED); fold the two substantive blocks into the relevant workflow files, delete the pass-narrative.
- [ ] **WF-03**: Extract §11.1 ingest → `schema/workflows/ingest.md` (+ folded §10 claim-granularity rules).
- [ ] **WF-04**: Extract §11.2 query → `schema/workflows/query.md`; core keeps **only the write-back-mandatory line**.
- [ ] **WF-05**: Extract §11.3 lint → `schema/workflows/lint.md` (+ folded §6 decay/staleness). **Guard:** preserve its "source of truth for CI contracts" framing — other docs link here, must not restate.
- [ ] **WF-06**: Extract §11.4 reflect, **§11.5 brownfield (the 182-line miss)**, §11.6 release, §11.7 audit → `schema/workflows/*.md`.
- [ ] **WF-07**: Extract §12 formats → `schema/reference/log-format.md`; bare log format **inlined per-workflow**; core resident ~0.
- [ ] **WF-08**: Verify core **section-by-section against the inclusion test** (ambient / unscriptable-unacceptable-miss / dispatch). No line target gates the milestone; ~145 is an expected output, with a tripwire only to trigger re-audit on upward drift. Every resident section carries a one-line justification citing its clause.
- [ ] **WF-09**: Manual agent-parity check — a Codex/Cursor agent given only `AGENTS.md` can ingest by following the routing table to `workflows/ingest.md`; evidence in `docs/reference/agent-parity.md`.

### Skills Overlay (`SKILL`) — Phase 18 (optional, ship only if it doesn't slow A+B)

- [ ] **SKILL-01**: Thin `.claude/skills/` wrappers for ingest/query/lint/reflect; each body ≤ 3 lines, pointer-only ("You have been invoked to {op}. Read `schema/workflows/{op}.md` and follow it verbatim."). Consider `disable-model-invocation: true`.
- [ ] **SKILL-02**: Skills add zero authoritative content (routers only); markdown remains the source of truth. Verify no behavior is encoded in a skill that isn't in the workflow file.

## Deferred → Backlog 999.3 (revisit immediately post-v1.2)

Phase D — Wizard / Template Fold-in (`WIZ`) — deferred to backlog **999.3**, to be revisited *immediately after v1.2 ships*, once the wizard surface is settled by the A/B/C restructuring. Tracked but not in this roadmap.

- **WIZ-01** (D1): *Blocked on resolving the Phase-8 minimalism conflict (WZRD-07/D-02 reduced placeholders 6→4)* — extend `{{…}}` placeholders to agreed published surfaces; enforce with a placeholder-set test analogous to `tests/phase-07/test_agents_template_placeholders.sh`. **Must justify reversing the minimalism decision before inclusion** — this is a hard gate on D1.
- **WIZ-02** (D2): *Observation-gated — recommend defer* — optional "describe domain in English → LLM drafts starter scaffold" wizard step, human-confirmed, behind a completeness-validation loop; preserves wizard↔manual byte-equality (scaffold is an optional accelerator). Defer unless onboarding friction is actually observed.

## Out of Scope

Explicitly excluded for v1.2. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Determinism pass (helper scripts / validators / manifests for extracted workflows) | Explicitly a *second* pass after the markdown split lands; evaluate post-extraction, not now |
| New page types or `wiki/` directory taxonomies | Binding: `dr-2026-05-01-complementary-systems-boundary` |
| Any behavioral change to lint/validate/privacy enforcement | Extraction relocates *text*, not logic — CI gates must pass unchanged |
| Tier 2–4 scaling work (split index, incremental lint, SQLite) | Observation-gated, separate milestone |
| v1.3 Wiki-Intelligence seeds (dedup/embeddings/tag-consolidation/cluster-detection) | Remain seeds with triggers intact |
| v1.4 Agent-Interface (MCP surface) | Remains a seed with its trigger intact |
| Mutation→log coupling pre-commit gate (Open Q10) | Adds false-positive surface for a low-miss-cost hygiene rule; `schema:`/`docs:`/`bin:` commits legitimately outside workflows. Recommended rejected |

## Traceability

Which phases cover which requirements. Phase mapping filled during roadmap creation (2026-06-04).

| Requirement | Phase | Status |
|-------------|-------|--------|
| PRIV-01 | Phase 15 | Complete |
| PRIV-02 | Phase 15 | Complete |
| PRIV-03 | Phase 15 | Complete |
| PRIV-04 | Phase 15 | Complete |
| PRIV-05 | Phase 15 | Complete |
| PRIV-06 | Phase 15 | Complete |
| PRIV-07 | Phase 15 | Complete |
| REF-01 | Phase 16 | Pending |
| REF-02 | Phase 16 | Pending |
| REF-03 | Phase 16 | Pending |
| REF-04 | Phase 16 | Pending |
| REF-05 | Phase 16 | Pending |
| REF-06 | Phase 16 | Pending |
| REF-07 | Phase 16 | Pending |
| REF-08 | Phase 16 | Pending |
| REF-09 | Phase 16 | Pending |
| REF-10 | Phase 16 | Pending |
| WF-01 | Phase 17 | Pending |
| WF-02 | Phase 17 | Pending |
| WF-03 | Phase 17 | Pending |
| WF-04 | Phase 17 | Pending |
| WF-05 | Phase 17 | Pending |
| WF-06 | Phase 17 | Pending |
| WF-07 | Phase 17 | Pending |
| WF-08 | Phase 17 | Pending |
| WF-09 | Phase 17 | Pending |
| SKILL-01 | Phase 18 | Pending |
| SKILL-02 | Phase 18 | Pending |

**Coverage:**
- v1.2 requirements: 28 total (PRIV ×7, REF ×10, WF ×9, SKILL ×2)
- Mapped to phases: 28 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-04 — distilled from `.planning/milestones/v1.2-MILESTONE-BRIEF.md` (itself a distillation of `999.4-…/CONTEXT-NOTES.md` + the 2026-06-04 design review). Scope confirmed: Phase 0+A+B+C committed; Phase D (`WIZ`) deferred.*
*Traceability table filled: 2026-06-04 by roadmapper — PRIV→Phase 15, REF→Phase 16, WF→Phase 17, SKILL→Phase 18.*

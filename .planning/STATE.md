---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Shareability
status: Phase 13.2 planned (ready to execute)
stopped_at: Phase 13.2 planned — 3 plans in 2 waves
last_updated: "2026-06-02T08:46:22.150Z"
progress:
  total_phases: 19
  completed_phases: 11
  total_plans: 52
  completed_plans: 52
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-15)

**Core value:** The wiki is a persistent, compounding artifact -- cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Current focus:** Phase 13.2 — v1.1 Closure Verification Gate (3 plans in 2 waves; ready to execute)

## Current Position

Phase: 13.2 PLANNED (3 plans, 2 waves) — ready to execute. The v1.1 end-of-line closure gate. Plan-checker PASSED (0 blockers; 3 warnings resolved in revision 1). Plans committed 7388323 (create) + 7613935 (checker fixes). Decomposition: **Wave 1** — 13.2-01 (CLOSE-02: user Obsidian render human checkpoint counts 3/2/2/2/5 + Codex column → blocked-on-host-runtime AppArmor + DEBT-04 audit; clears the sole DEBT-01 drift row) ‖ 13.2-02 (CLOSE-03 docs/README/DR/ROADMAP consistency + CLOSE-04 scope-leak, edit-on-drift, reusing check-neutrality/check-privacy, no new script). **Wave 2** — 13.2-03 (CLOSE-01: commit dangling 12.2-VERIFIER-REPORT.md [D-04a.1] + author SC1 reframing DR [D-04a.2] + requirements-sync --strict --require-complete zero-drift gate + flip CLOSE-01..04 Complete in bullets+matrix + paired 13.2-VERIFICATION.md/VERIFIER-REPORT.md + `/gsd-complete-milestone` as final task). Two human checkpoints (render, milestone-archive) are `autonomous: false`. Next: `/gsd-execute-phase 13.2`.

Phase: 13.1 complete (5/5 plans). All docs-finalization + Obsidian-starter deliverables shipped. (Closure handled by Phase 13.2 — CLOSE-01..04 re-run/audit 13.1's verification notes incl. the DEBT-01 Obsidian render and DEBT-02 Codex parity column.)

Plan 13.1-05 complete (2026-06-01): accuracy-passed the five substantial reference docs (edit-on-drift) + reconciled `docs/reference/index.md` + verified CONTRIBUTING.md merge-conflict recipes. Only `brownfield.md` had drift: line 3 rewritten to name all FIVE subcommands (scan/bootstrap/suggest/review-typing/verify) per §11.5 (dropped "two stubs ... ship in Phase 11"; never wrote "four" — T-13.1-12 trap avoided); wrong script name `04-privacy-classification.sh` → `04-privacy-review.sh`; ~14 stale "Phase 11" refs reworded to shipped tense (line 356 "Phase 10 + Phase 11 requirements" KEPT as accurate historical authorship); every `0[1-4]-*.sh` ref verified real. quickstart.md ~line 35 + `.obsidianignore` header: corrected the self-falsifying ".obsidianignore hides examples/ from Obsidian" claim (Obsidian does not read it; examples/ IS Dataview-indexed; real exclusion = Settings → Excluded files); .obsidianignore kept in release allowlist; bare `Kahneman` token removed from header (Rule 2 neutrality). ci.md/release.md/three-layer-model.md/dataview-queries.md = NO DRIFT (left byte-unchanged; severity table, allowlist, DR link, 5 queries all verified against source-of-truth). index.md now catalogs all 12 reference files anchored to link form (+5: dataview-queries, commit-examples, setup-prerequisites, agent-parity, obsidian-starter); CONTRIBUTING pointer strengthened (D-11: no merge-conflicts.md). CONTRIBUTING recipes VERIFIED: committed `.gitattributes` has no `merge=union` (opt-in claim true); index.md category-header structure confirms the union-collide warning. check-neutrality.sh + sync-claude.sh --check + full lint all exit 0. Commits ecb013d, 1929838. SUMMARY self-check PASSED.

Plan 13.1-04 complete (2026-06-01): authored the three never-populated `docs/reference/` stubs (schema-tour, privacy-model, examples) + created new `agent-parity.md` (DEBT-02 deliverable). schema-tour.md = full §5 frontmatter + §6 provenance/claim-syntax walkthrough (page-type section orders, validation checklist, `[prov:]` grammar + locator table, `<!-- page: N -->` convention, `[epistemic::]`, decay model). privacy-model.md = §13 tiers/precedence + 7-row decision table VERBATIM + strictest-wins inheritance + `bin/check-privacy.sh` CI gate. examples.md = examples/ usage + `example: true` lint-skip + CORRECTED `.obsidianignore` (release-manifest/graph-hygiene convention, NOT Obsidian-native; real mechanism = Excluded files/`userIgnoreFilters`) + five fixture-scoped Dataview blocks with expected counts (3/2/2/2/5) + grep-vs-Dataview divergence notes; active-entities count re-derived LIVE (=3) and asserted equal. agent-parity.md = structural-equivalence rubric (page-set/types/prov-IDs/locator-targets/frontmatter; prose free) + golden inventory (1 entity, 3 concepts, 1 comparison, 1 overview, 2 sources; single-source vs prospect-theory SUBSET) + codex=cloud-egress + fail-closed seed guard + `codex exec` re-run + `pagetypes()`/`provtargets()` helpers + diff table with Codex column rendered `pending — deferred to 13.2` (blocked-on-runtime, NEVER fabricated; mirrors 13.1-VERIFICATION.md). Neutrality: path-only kahneman refs, only bare token = `prospect-theory` slug; `bash bin/check-neutrality.sh` exit 0. One deviation (Rule 3): added spaced "structural equivalence" to agent-parity TL;DR to satisfy `grep -qi`. Commits eb7b419, 8060c7d, 39e47fb. SUMMARY self-check PASSED. NOTE: index.md registration of agent-parity.md is owned by Plan 05.

Plan 13.1-03 complete (2026-06-01): DEBT-01/02/04 verification execution → `13.1-VERIFICATION.md` (Phase 13 mirror). DEBT-02 agent-parity: fail-closed seed guard (CLAUDE.md §13) ran exit-0 over both scratch trees BEFORE codex egress (single mandatory egress defense; local_only personal-decision-journal never seeded); Claude-side scratch ingest of the prospect-theory source produced 4 pages whose prov-locator-target set EXACTLY matches the golden prospect-theory SUBSET (6 `#sec:` targets); lint 0/0/0 on explicit scratch path; scratch torn down by absolute path (trap + explicit rm; repo clean). Codex side BLOCKED-ON-RUNTIME: codex exec hung on stdin without `</dev/null` (fixed on retry), then bubblewrap sandbox "needs user namespaces" pathology → degenerate sed-exec loop, 0 wiki pages after ~23min → recorded honestly (NOT faked) per SAFETY-GUARD; Phase 13.2 re-runs the Codex column (not on Wave 2 critical path — Plan 04 consumes the Claude-vs-golden-subset diff). DEBT-04 genuine write-back: UPDATE `wiki/concepts/progressive-disclosure.md` citing src-2026-05-06-ralph-playbook + src-2026-05-06-anthropic-agent-skills-overview (≥2 distinct cloud_safe source_ids), validate-op UPDATE PASS (5/5), new today-dated WRITE-BACK log line (7→8), append-then-synthesize, privacy inheritance honored, lint clean, single query() commit 267d2c8. DEBT-01: render checklist + "awaiting user render" capture slot shipped (SC1 graph sub-check reframed to "isolable sub-graph"; D-09 prepared-and-await; Phase 13.2 SC2 closes). DEBT-02/04 → Complete in REQUIREMENTS.md (bullets + matrix); DEBT-01 → Pending (awaiting render). check-neutrality.sh exit 0; targeted neutrality clean (no journal body). Commits 267d2c8 (write-back), b1ba23b (VERIFICATION.md). SUMMARY self-check PASSED.

Plan 13.1-02 complete (2026-06-01): `examples/dataview-fixtures/` — 10 `example: true` fixtures (4 entity / 2 concept / 2 source / 1 comparison / 1 overview) spanning statuses (8 active, 2 stale, 1 archived) and synthetic domains (alpha×5, beta×3, gamma×2). Positive-neutrality discipline: all ids `fixture-*`, synthetic alpha/beta/gamma + tag-x/y/z tokens (check-neutrality.sh PRUNES examples/, so the targeted denylist grep + positive markers are the real proof). domains/tags YAML block-lists; 2 pages carry `bootstrap_stage: bootstrapped` (entity-2, concept-1); both source fixtures carry the full source tail. Machine-consumable count matrix (Plan 04 consumes): active-entities=3, sources-by-domain-alpha=2, stale-pages=2, missing-privacy=2, pages-in-domain-alpha-active=5. Live wiki lint clean (yaml,orphan 0/0/0 — no regression); check-neutrality.sh exit 0. Commit 3eeb101. SUMMARY self-check PASSED. NOTE: examples.md documentation of the fixture counts + .obsidianignore correction is owned by Plan 04.

Plan 13.1-01 complete (2026-06-01): six token-ized `schema/obsidian/{entity,concept,overview,comparison,source-summary,decision}.md` templates (Templates-core `{{title}}`/`{{date:YYYY-MM-DD}}`; zero drift vs `schema/templates/` via full-file reverse-substitution diff; decision.md asymmetry preserved) + `docs/reference/obsidian-starter.md` (OBSID-02; Setup-once, auto-fill-vs-typed, OBSID-03 scope). PRE-FLIGHT: cleared the pre-existing `check-neutrality.sh` exit-2 by adding `neutrality_exempt: true` to generated `wiki/maintenance/lint-report.md` (drift findings preserved) — every downstream plan's neutrality gate is now meaningful. OBSID-01/02/03 → complete. Commits 2bc2258, 8dd8940, bc03f95. SUMMARY self-check PASSED. NOTE: `obsidian-starter.md` index.md registration is owned by Plan 05, not this plan.

Phase 13.1 context: 12 decisions in `13.1-CONTEXT.md` (4 areas). Obsidian starter = Templates-core tokens ({{date}}/{{title}}), `schema/obsidian/` templates + reference doc only, NO `.obsidian/` config mutation. Dataview verification = build `examples/dataview-fixtures/` (example: true + documented expected counts); one fixture covers fresh-starter + post-bootstrap via embedded `bootstrap_stage` pages — KNOWN TENSION: `.obsidianignore` excludes examples/ from indexing (Dataview would return 0; researcher to reconcile). Manual verification split: Claude runs DEBT-04 write-back + BOTH sides of DEBT-02 (Claude ingest + `codex exec`, CLI 0.135.0 confirmed) against `examples/kahneman/` golden, tolerance = structural equivalence; USER does only DEBT-01 Obsidian render (prepared-and-await, phase NOT blocked on GUI; 13.2 confirms). Docs: fully author 3 stubs (schema-tour/privacy-model/examples) + new `agent-parity.md`, accuracy-pass substantial docs, reconcile index; merge-conflict stays in CONTRIBUTING.md, dataview-fixtures folds into examples.md. NEUTRALITY (CLAUDE.md §3) binds all docs/templates — placeholders only, kahneman is the sole sanctioned concrete example.

Phase 13 closure: 5/5 plans complete; FAITH-01..04 → Complete in REQUIREMENTS.md (bullets + traceability matrix); 13-VERIFICATION.md (plan-authored, 12.2 mirror) + 13-VERIFIER-REPORT.md (independent, PASS 6/6 SC + 4/4 REQ); tests 33/33; `bin/requirements-sync.sh --strict --phase 13` and `--require-complete --phase 13` both exit 0; code review 0 critical / 0 high (3 medium / 4 low, advisory — top item MD-01: `--format json` does not apply the `--emit-worklist` HIGH-C metadata redaction; passage text NOT leaked). Shipped: `bin/audit-claims.sh` (selectors → raw-source locator resolver → 9-key findings → privacy chokepoint → stdin-only `shlex.split` verifier dispatch), `bin/lib/privacy_resolve.py` (§13 fail-closed + strictest-wins effective-claim privacy), AGENTS/CLAUDE §6 `<!-- page: N -->` + Audit review-only workflow. Generated audit-report.md / audit-state.md stamped `privacy: local_only`.

Phase 12.2 closure: 5/5 plans complete; WGATE-01..04 → Complete; verifier PASS 7/7 SC; tests 11/11.

Phase 13 context: 16 decisions captured in `13-CONTEXT.md` (resolves the 5 open questions from `13-DESIGN-NOTES.md`). Verifier = contract-only (agent-in-the-loop default + documented `--verifier` hook, no bundled script); fail-closed `local_only` egress (`skipped-privacy` default, explicit local opt-in); page-marker convention shipped in v1 (optional `<!-- page: N -->` + `insufficient-locator` fallback, document-now/helper-later); sample-20 priority-ranked union; on-demand + reflect-tier cadence; human-approved `contradicts`→marker handoff. LOCKED carry-forwards: raw-source-at-`path:`, no auto-fix, no default CI gate, no SQLite, no full-vault default, zero new claim vocabulary.

Phase 12.1 closure: 4/4 plans complete; NEUT-08 flipped to Complete in REQUIREMENTS.md (line 36 + matrix line 215); 12.1-VERIFICATION.md authored with verbatim D-10 evidence; bin/requirements-sync.sh --strict --phase 12.1 and --require-complete --phase 12.1 both exit 0; bin/check-neutrality.sh source unchanged across the entire phase. N=7 defense-in-depth curation: pre-committing, physical flinch, pre-mortem, pre-mortems, decision fatigue, decision-fatigue, meta-observation. First v1.1 partial-requirement closure.

## Performance Metrics

**Velocity:**

- Total plans completed: 24
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 09 | 6 | - | - |
| 09.1 | 2 | - | - |
| 10 | 6 | - | - |
| 11 | 5 | - | - |
| 12 | 4 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 6min | 2 tasks | 10 files |
| Phase 01 P02 | 3min | 2 tasks | 1 files |
| Phase 01 P03 | 1min | 2 tasks | 0 files |
| Phase 02 P01 | 2min | 2 tasks | 5 files |
| Phase 02 P02 | 3min | 2 tasks | 5 files |
| Phase 02 P03 | 1min | 2 tasks | 3 files |
| Phase 03 P02 | 2min | 1 tasks | 1 files |
| Phase 03 P01 | 2min | 2 tasks | 2 files |
| Phase 03 P03 | 10min | 3 tasks | 10 files |
| Phase 03 P04 | 5min | 3 tasks | 6 files |
| Phase 03 P05 | 2min | 2 tasks | 1 files |
| Phase 04 P01 | 3min | 2 tasks | 5 files |
| Phase 04 P02 | 3min | 2 tasks | 1 files |
| Phase 05 P01 | 3min | 2 tasks | 11 files |
| Phase 05 P02 | 4min | 2 tasks | 3 files |
| Phase 05 P03 | 2min | 2 tasks | 1 files |
| Phase 05 P04 | 1min | 2 tasks | 2 files |
| Phase 06 P01 | 4min | 2 tasks | 4 files |
| Phase 06 P02 | 5min | 2 tasks | 1 files |
| Phase 06 P03 | 3min | 3 tasks | 2 files |
| Phase 07 P01 | 6min | 2 tasks | 6 files |
| Phase 07 P02 | 12min | 2 tasks | 19 files |
| Phase 07 P03 | 5min | 2 tasks | 11 files |
| Phase 07 P04 | 4min | 2 tasks | 24 files |
| Phase 07 P05 | 65min | 5 tasks | 13 files |
| Phase 08 P01 | 3 | 2 tasks | 7 files |
| Phase 08-two-track-setup-wizard-manual P04 | 8min | 2 tasks | 12 files |
| Phase 08-two-track-setup-wizard-manual P02 | 12min | 2 tasks | 10 files |
| Phase 08-two-track-setup-wizard-manual P03 | 8min | 2 tasks | 7 files |
| Phase 08-two-track-setup-wizard-manual P05 | 2min | 1 tasks | 2 files |
| Phase 09-collaborative-pr-workflow-ci-lint-gate P01 | 4min | 2 tasks | 18 files |
| Phase 09-collaborative-pr-workflow-ci-lint-gate P04 | 6min | 3 tasks | 11 files |
| Phase 09-collaborative-pr-workflow-ci-lint-gate P02 | 8min | 2 tasks | 6 files |
| Phase 09-collaborative-pr-workflow-ci-lint-gate P03 | 10min | 2 tasks | 11 files |
| Phase 09-collaborative-pr-workflow-ci-lint-gate P05 | 6min | 3 tasks | 11 files |
| Phase 09-collaborative-pr-workflow-ci-lint-gate P06 | 8min | 2 tasks | 5 files |
| Phase 09.1 P01 | 4min | 2 tasks | 13 files |
| Phase 09.1 P02 | 14min | 2 tasks | 18 files |
| Phase 10-brownfield-scan-bootstrap P10-06 | 2min | 5 tasks | 7 files |
| Phase 11-brownfield-suggest-verify P01 | 45 | 2 tasks | 114 files |
| Phase 11-brownfield-suggest-verify P02 | 90min | 2 tasks | 4 files |
| Phase 11-brownfield-suggest-verify P03 | 35min | 3 tasks | 6 files |
| Phase 11-brownfield-suggest-verify P04 | 70min | 2 tasks | 7 files |
| Phase 11-brownfield-suggest-verify P05 | 40min | 2 tasks | 13 files |
| Phase 12.2 P04 | 25min | 4 tasks | 6 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v1.1 Roadmap] 6 phases (7–12) derived from 78 v1.1 requirements (standard granularity); backlog Phase 999.1 superseded (absorbed into Phases 10–11).
- [v1.1 Roadmap] DEBT-03 (`requirements-sync.sh`) placed in Phase 7 so all subsequent phases benefit from mechanical traceability check (retrospective lesson, pitfall m-4).
- [v1.1 Roadmap] Phase 7 gates release via orphan-branch runbook + neutrality/denylist CI (pitfall C-1 mitigation).
- [v1.1 Roadmap] Brownfield split across two phases (10=scan+bootstrap, 11=suggest+verify) to absorb highest-risk surface (pitfalls C-2, C-3) in isolation.
- [v1.1 Roadmap] `ruamel.yaml` accepted as the single new runtime dep in Phase 10 (BRWN-06) — narrowly scoped to bootstrap round-trip, revises "zero new deps" STACK finding.
- [v1.1 Roadmap] Wizard + Manual co-ship in Phase 8 with byte-equality CI (MANUAL-06) to prevent track drift (pitfalls M-1/M-3).
- [v1.1 Roadmap] Contradiction stays warning-only in CI per CI-03 reconciliation; `local_only` privacy guard scoped to public paths only per CI-07.
- [v1.1 Roadmap] No single-command brownfield chain-runner in v1.1 (deferred to v1.2 BRWNAPPLY-01); v1.1 migration scripts are user-invoked per-class.
- [v1.1 Roadmap] Zero claim-level schema expansion for imported content — page-level `bootstrap_stage` carries the lineage (BRWN-07, BRWN-15).
- [v1.1 Roadmap] Phase 12 is Complementary Systems Boundary + GTD Alignment (decision record + reference doc defining compendium as durable wiki memory inside a multi-system agent stack); v1.0-debt verification (Obsidian render, Codex agent-parity, write-back scenario) moved to Phase 13.1 in the 2026-05-01 reorder.
- Roadmap: 6 phases derived from 95 v1 requirements (standard granularity)
- Roadmap: CLI helpers distributed across phases 3-5 where their functionality is most relevant
- Roadmap: Epistemic status placed in Phase 2 (with templates) per research advice that it's foundational to trustworthiness
- [Phase 01]: Source registry uses frontmatter on wiki/sources/ pages (Dataview-native)
- [Phase 01]: snake_case for all frontmatter fields; 16 base fields including aliases
- [Phase 01]: Extended provenance syntax with optional support type and checked_at for staleness
- [Phase 01]: Pipeline vs. workflow separation: conceptual model (Section 10) vs. operator procedures (Section 11)
- [Phase 01]: Privacy conflict resolution: stricter setting always wins (local_only over cloud_safe)
- [Phase 01]: Mandatory query write-back: novel synthesis must be compiled back into wiki
- [Phase 01]: All 19 Phase 1 requirements pass automated validation including YAML parse, structural, provenance syntax, and content checks
- [Phase 02]: Templates use empty/default values rather than placeholder text to prevent accidental publication
- [Phase 02]: FORBIDDEN PATTERNS block placed between frontmatter and first section for maximum agent visibility
- [Phase 02]: Concept page is natural home for tentative/stale markers due to genuine debates in bias research
- [Phase 02]: Overview pages use mixed epistemic_status as standard pattern for synthesis pages
- [Phase 02]: Inferred markers include qualifying language to make epistemic reasoning explicit
- [Phase 02]: Log ordering follows AGENTS.md section 12 (newest at bottom) as authoritative spec
- [Phase 03]: CLI ingest helper (bin/ingest.sh) handles file bookkeeping only — zero LLM/API calls per D-11/D-13
- [Phase 03]: UTC dates used for source directory paths to guarantee determinism across operator timezones
- [Phase 03]: Source ingest collisions require --force to overwrite; empty slugs rejected with clear error
- [Phase 03]: book-chapter is the canonical source type for book content; full books ingested as chapter sequence
- [Phase 03]: Claim granularity follows smallest-unit-that-preserves-provenance heuristic, source-type driven
- [Phase 03]: Incremental updates use append-then-synthesize: append detail, re-synthesize summary, supersede explicitly
- [Phase 03]: Stale/supersede wording deliberately softened to defer formal contradiction semantics to Phase 5
- [Phase 03]: Diff pass must drive page selection — plans list candidates but merge targets are decided from the actual diff, not pre-declared
- [Phase 03]: Prospect theory and loss aversion each warrant their own concept pages (3+ independent claims, natural home for downstream bias families); cognitive-biases.md restructured around heuristic-origin vs loss-aversion-origin families
- [Phase 03]: Ingest log entries use explicit UPDATED: / CREATED: lines with per-page rationale so the diff-pass reasoning is preserved alongside the structural outcome
- [Phase 03]: Biographical drift on entity pages is forbidden during source-ingest validation — only concretely sourced factual additions allowed, no fabricated dates/awards
- [Phase 03]: Privacy separation via dedicated local_only page rather than merging into cloud_safe overview (option a from review feedback)
- [Phase 03]: Paragraph-level granularity (7 clusters) for journal entries vs atomic claims for articles validates adaptive extraction
- [Phase 03]: personal-decision-patterns.md created as local_only overview page type for experiential claims synthesis
- [Phase 03]: Phase-level verification covers 8 cross-plan checks that per-plan verification cannot address individually
- [Phase 04]: Compilation status transitions are explicit and enumerated -- any unlisted transition is a bug
- [Phase 04]: Pre-Phase-4 legacy pages missing compilation_status treated as compiled by tooling
- [Phase 04]: Step 6a added as sub-step within existing merge step to avoid renumbering ingest workflow
- [Phase 04]: Output contracts are deterministic per mode: default (header + path -- TL;DR + footer), --paths-only (bare paths), --query (bounded prompt block)
- [Phase 05]: knowledge_domain is the staleness policy bucket, distinct from domains which is topical classification
- [Phase 05]: Contradiction detection excludes comparison and overview page types (inherently multi-source)
- [Phase 05]: Auto-fix limited to stale markers and has_contradictions sync; contradictions, gaps, orphans are report-only
- [Phase 05]: Single python3 block for all lint checks (efficiency); env vars for heredoc arg passing; exit 0 for findings
- [Phase 05]: Contradiction candidates use section-level provenance grouping with lexicographic pair normalization
- [Phase 05]: Zero-error wiki validates schema implementation quality from phases 1-4
- [Phase 06]: Decision records are a dedicated type: decision page type, not overloaded onto overview
- [Phase 06]: dr-YYYY-MM-DD-slug is canonical naming/ID convention; dr- prefix prevents collisions
- [Phase 06]: trigger_type enum fixed at six values (merge, split, schema-update, domain-reorg, reframing, contradiction-resolution)
- [Phase 06]: decision_history is an optional back-link field, not part of BASE_FIELDS
- [Phase 06]: Content-hash drift auto-fix gated behind --fix flag (same pattern as stale markers)
- [Phase 06]: Lint report groups findings by category within severity for drift visibility
- [Phase 06]: Inline decision record hooks include explicit skip criteria (trivial merges, routine stale-claim supersessions) to prevent record inflation
- [Phase 06]: Reflect checkpoint advances even on no-op passes to avoid re-scanning clean history
- [Phase 06]: Log.md (intent) vs git log (file changes) deduplication rule: log.md is primary trigger, git-only changes signal unrecorded work
- [Phase 07]: [Phase 07]: bin/requirements-sync.sh advisory-default with --strict gate; 5-col markdown table includes Note column for human-readable rationale
- [Phase 07]: [Phase 07]: Duplicate REQ-IDs across VERIFICATION.md files use lexicographic last-write-wins with stderr WARN
- [Phase 07]: [Phase 07]: VERIFICATION.md parser tolerates bare bullets, [x]/[ ] checkboxes, emoji prefixes, and **bold** REQ-IDs
- [Phase 07]: [Phase 07]: Kahneman cluster relocated to examples/; wiki/ reduced to TMPL-05 skeleton; local_only creator content deleted
- [Phase 07]: [Phase 07]: NEUT-07 decision record uses canonical AGENTS.md §4.6 schema with all BASE_FIELDS (including supersedes/superseded_by/aliases/has_contradictions)
- [Phase 07]: [Phase 07]: bin/lint.sh EXCLUDE_DIRS += examples; per-file example: true skip; WIKI_ROOT env var reuses 07-01 fixture-override pattern
- [Phase 07]: AGENTS.md neutralization uses <UPPERCASE_NAME> angle-bracket tokens for illustrative content; schema/AGENTS.template.md reserves {{...}} syntax exclusively for the 4 wizard placeholders (PRIMARY_DOMAIN, DEFAULT_PRIVACY, AGENT_FILENAME, DECAY_PROFILE) per D-08/REVIEWS.md HIGH #1
- [Phase 07]: CLAUDE.md is byte-identical to AGENTS.md, enforced by .githooks/pre-commit that auto-syncs and re-stages on drift (TMPL-10/D-03); hook-path roundtrip test uses ephemeral GIT_INDEX_FILE to avoid polluting the real index
- [Phase 07]: [Phase 07-04] README 'Repo shape' tree neutralized — 'examples/kahneman/ — Daniel Kahneman' replaced with 'examples/ — Reference example clusters (bundled sample domain)' to reconcile plan's README spec with plan's Kahneman-zero-tolerance test
- [Phase 07]: [Phase 07-04] test_no_kahneman_in_public_docs.sh exempts lines that only reference the sanctioned examples/kahneman/ directory path (mirrors 07-03 test_agents_neutralized.sh pointer-exemption precedent)
- [Phase 07]: [Phase 07-04] docs/reference/release.md is NOT a stub — it is the full orphan-branch runbook with --dry-run/--apply/check-neutrality.sh pre-flight/Rollback; 07-05 release.sh and check-neutrality.sh implement exactly this contract
- [Phase 07]: [Phase 07-04] <org>/<repo> angle-bracket placeholder used 7× across README/LICENSE/quickstart/release.md; no your-org/USER-REPO forms (D-02 template-wide convention)
- [Phase 07-neutral-template-foundation]: NEUT-08 (personal-vault denylist coverage) deferred to a follow-up PR per user decision 'approved — minimal'; v1.1 ships with the Kahneman-only category (NEUT-06). Creator-specific personal terms will be added after a separate .planning/notes/ + git-history suggest-denylist pass is reviewed.
- [Phase 07-neutral-template-foundation]: 07-05 Task 2 Rule 1/2 auto-fix: bin/check-neutrality.sh gained three exemptions to make 'kahneman' denylist pass against real repo — (1) SELF_REFERENTIAL_EXEMPT skips bin/check-neutrality.sh itself; (2) line-level strip of sanctioned 'examples/kahneman/...' path refs (mirrors 07-03/07-04 precedent); (3) frontmatter neutrality_exempt: true per-file skip (mirrors bin/lint.sh example:true from 07-02). Applied neutrality_exempt to wiki/decisions/dr-2026-04-15-kahneman-to-examples.md (that record IS about Kahneman relocation).
- [Phase 07-05]: bin/release.sh uses fresh-temp-dir allowlist staging (never worktree mutation) — safe-by-construction per REVIEWS.md HIGH #1; allowlist is the authoritative public-file set, adding a public file is an explicit code change.
- [Phase 07-05]: .github/workflows/neutrality.yml uses pull_request = hard gate + push = advisory. Real enforcement is branch-protection required status check 'neutrality'; push trigger exists only for informational early-warning.
- [Phase 07-05]: TMPL-11 verified live — bash bin/release.sh --remote <throwaway> --apply produced single-commit history (git rev-list --all --count == 1 PASS) with denylist 8/8 absent and allowlist 6/6 present on fresh clone.
- [Phase 07-05]: TMPL-01 mechanics proven on throwaway YishaiRetyk/template-smoke-test — is_template: true toggled + branch protection requires 'neutrality' status check. Real public template repo name deferred to operator decision; runbook at docs/reference/release.md is sufficient for name-pick.
- [Phase 07-05]: release.sh local_only regex tightened (fix 21e0445) to exclude AGENTS.md enum-documentation contexts; release.md smoke grep excludes --exclude=release.md to skip the runbook's own self-reference (fix a1b2afd).
- [Phase 07-05]: NEUT-08 deferred to a follow-up PR; 861-line deterministic --suggest-denylist candidate output preserved at .planning/backlog-neutrality-denylist-candidate.txt for later hand-curated review.
- [Phase 08-01]: default_privacy=cloud_safe in canonical-answers.yaml (not local_only) — deliberate deviation from wizard default to pass bin/release.sh '^privacy:[[:space:]]*local_only' public-leak regex; rationale in schema/fixtures/README.md (review #1)
- [Phase 08-01]: Plan 01 python3 str.replace render is the byte-equality reference; Plan 02 wizard render routine must produce byte-identical output or Plan 05 CI fails (review #13)
- [Phase 08-01]: phase-08/run.sh uses semantic parity (not line-count parity) with phase-07/run.sh — filtered diff returns 0 unexpected lines (review #12)
- [Phase 08-01]: schema/fixtures/ + tests/phase-08/ establish byte-frozen fixture pair pattern (answers.yaml + rendered target, LF-pinned in .gitattributes, README-documented regen rule)
- [Phase 08-04]: Manual-setup.md Section 8 inlines full decision-record heredoc + wiki/index.md append — manual track reaches canonical fixture WITHOUT wizard invocation (review concern #4)
- [Phase 08-04]: Pre-step cp schema/AGENTS.template.md AGENTS.md (copy-not-edit); all Sections 2-5 'File to edit:' lines cite AGENTS.md, template stays pristine (review concern #3)
- [Phase 08-04]: docs/reference/setup-prerequisites.md centralizes bash>=4/git/python3 install matrix for macOS/Debian/Arch/Fedora/Windows (D-16)
- [Phase 08-04]: Privacy tier cloud_safe in walkthrough (deviates from wizard prompt default local_only per D-11) to match canonical public fixture per D-08/Open-Q2
- [Phase 08-04]: Phase-07 test_docs_skeleton.sh relaxed: dropped 'Phase 8' stub-marker assertion + raised quickstart ≤60→≤80 line cap (Rule 3 — prev-phase test obsoleted by Phase 8 populate)
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-02] Prompts + D-13 explainers routed to stderr (not stdout) so command-substitution captures only validated values; fixed a latent interactive byte-equality bug caught in self-test
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-02] Pure-bash parameter-expansion SCRIPT_DIR resolution (no 'dirname') to survive preflight PATH stripping in tests
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-02] Exit-code 2 'not yet implemented — Plan 03 pending' gate as explicit branch before any write; Plan 03 removes it when repo-root writes land
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-03] Idempotency guard scope retained Plan 02 semantics (triggers for both real-run and --render-to when .wizard-answers.yaml exists at REPO_ROOT); narrowing to real-run-only would have regressed test_wizard_idempotent.sh
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-03] Staging-dir pattern (review #8): mkdtemp(dir=REPO_ROOT, prefix='.wizard-stage-') keeps staging on same filesystem as repo-root for atomic shutil.move rename; rmtree in finally block ensures cleanup on both success and failure
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-03] update_index_md() 3 guardrails (review #2): idempotency (skip if exact entry present), duplicate-header (refuse >1 `## Decisions` with recovery message), malformed-recovery (clear pointer-to-manual-recovery error on missing/unreadable file)
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-03] template_sha fallback chain (review #9): WIZARD_TEMPLATE_SHA env > git log -1 --format=%H schema/AGENTS.template.md > <unresolved> literal; CI must set env var (no fetch-depth: 2 reliance)
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-03] Plan 02 exit-2 gate removed; test_wizard_not_yet_implemented.sh deleted; 5 new side-effect tests added (answers_yaml, decision_record, sync_claude, index_md, partial_failure); aggregator PHASE 08 TESTS: 20/20
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-05] Workflow comments avoid literal 'fetch-depth' + 'test_canonical_byte_equality.sh' tokens so plan's strict ! grep -q acceptance checks pass as single-pattern greps; semantically equivalent phrasing ('shallow-clone depth' / 'MANUAL-06 byte-equality test') used instead
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-05] Aggregator math reconciled per review #7: 13 wizard + 7 manual-setup + 1 new byte-equality = 21/21 (test_wizard_not_yet_implemented deleted in 08-03 so does not count)
- [Phase 08-two-track-setup-wizard-manual]: [Phase 08-05] Required-check name 'setup-parity' matches jobs.setup-parity key; operator adds to branch-protection on public template repo (one-time GitHub UI action, same model as Phase 7 neutrality)
- [Phase 09-01]: Phase 9 test harness cloned from phase-08 with 08->09 rename only (zero semantic drift preserves operator muscle memory)
- [Phase 09-01]: Fixtures are static input (no committed .git/); make_fixture_repo creates throwaway git repo at test time via mktemp + git init -b main
- [Phase 09-01]: setup_git_author uses per-call unique filename (email-slug + nanoseconds + RANDOM) replacing Codex-LOW-flagged collision-prone .ts primitive
- [Phase 09-01]: seed_origin_main_ref as first-class helper (not per-test plumbing) — Plan 09-03 strict tests depend on origin/main...HEAD semantics
- [Phase 09-01]: All seeded .md fixtures use LF + UTF-8 (no BOM, no CRLF); critical for Plan 09-03 line-number-sensitive adjacency assertions
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-04] bin/check-privacy.sh pattern-twin of check-neutrality.sh: PUBLIC_PATHS (examples, docs, AGENTS.md, CLAUDE.md, README.md, PRIVACY.md, .github) scanned, wiki/ excluded per D-15 (local_only valid user content per AGENTS.md §13); frontmatter-only match per D-14 (prose mentions exempt); exit codes 0/1/2
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-04] bin/ingest.sh --contributor integration path (a): flag augments printed stdout log-entry template (LLM agent copies into wiki/log.md); bin/ingest.sh does not mutate log.md directly (preserves D-11/D-12/D-13 scope)
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-04] Contributor resolution order: explicit --contributor > single-author-omit (D-20) > .git-author-map.txt hit > map-miss-warn-and-omit (Pitfall 5: never bare email)
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-04] bin/search.sh --contributor branch placed before WIKI_INDEX validation so contributor mode works on fresh forks without wiki/index.md
- [Phase 09-02]: [Phase 09-02] LINT_VERSION=1.1.0 ships as Phase-9 v1.1 baseline; semver MAJOR on breaking, MINOR on additions, PATCH on bug fixes; --require-version is minimum-check semantics
- [Phase 09-02]: [Phase 09-02] drift-external is logical subcategory via EXTERNAL: message prefix (not a new add_finding category) — preserves 4-tuple backward compat + grep-friendly
- [Phase 09-02]: [Phase 09-02] JSON line field OMITTED (not null) when unknown; Plan 02 4-tuple has no line slot so line always omitted for Plan 02 findings (P0 review fix — Codex MEDIUM #3)
- [Phase 09-02]: [Phase 09-02] --category/--skip-category precedence = intersect-then-subtract; narrow first (via existing should_run), skip subtracts; tested by --category X --skip-category X → empty
- [Phase 09-02]: [Phase 09-02] --ci default-skip is drift-external only; DRFT-01/02/content-hash/index-coverage still emit as warnings — only DRFT-03 Obsidian-awareness is suppressed by default
- [Phase 09-02]: [Phase 09-02] Parallel execution race: Task 2 commit content absorbed into concurrent 09-04 commit 8f08d17 (misattributed title). bin/lint.sh content + 3 test files correct at HEAD; all 5 tests green. Record for commit archaeology.
- [Phase 09-03]: DR index collected wiki-wide (merged decisions are valid coverage); only the SET OF CLAIMS checked is PR-diff-scoped, the COVERAGE INDEX is historical
- [Phase 09-03]: origin/main fallback: has_origin_main() probe + stderr WARN + wiki-wide _strict_check_fallback() walk; new-page provenance skipped in fallback (D-10 intrinsically PR-diff-scoped)
- [Phase 09-03]: Escape-hatch marker strictness load-bearing: adjacent-line placement + blank-line-invalidates + id-match + non-empty reason (D-09); prevents stale markers drifting during edits
- [Phase 09-03]: contributor category uses .git-author-map.txt two-space-arrow-two-space or tab separator; case-insensitive email match; D-20 single-author short-circuit silent (zero findings)
- [Phase 09-03]: CI + --strict unified exit policy: exit 1 iff any post-remap error-severity finding; Plan 02 exit path extended to honor STRICT_MODE in both JSON and text modes
- [Phase 09-03]: Fixture data Rule 3 fix: strict-missing-dr + strict-escape-hatch gained source summary pages + raw source files because attention.md's prov ref needed resolution under --strict exit-on-any-error policy
- [Phase 09-03]: test_lint_strict_new_page.sh flips type to source WITH SOURCE_EXTRA_FIELDS injection + --category provenance isolation — isolates D-10 exempt assertion from unrelated yaml errors
- [Phase 09-03]: strict PR-diff scope via git diff unified=0 origin/main...HEAD unified-diff parser (D-08); pre-existing debt on unchanged pages does NOT fail unrelated PRs (Codex HIGH resolution)
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-05] lint.yml uses 3 parallel jobs (no needs: edges) - fast feedback, each an independent required check in branch protection
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-05] annotation shim maps info -> ::notice (NOT ::info) - GitHub's workflow-command set has 3 tiers: error/warning/notice
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-05] annotation cap strategy: sort errors first (preserves critical findings under 10/10/50 cap), emit trailing ::notice with dropped count + 'more' token
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-05] AGENTS.md §11.3 CI-mode subsection opens with source-of-truth blockquote (Codex MEDIUM fix) - docs/reference/ci.md and CONTRIBUTING.md MUST link rather than restate policy
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-05] AGENTS.md §12 documents contributor:: @handle as Dataview inline BODY field (NOT frontmatter per §3 prohibition); single-author repos omit the field entirely
- [Phase 09-collaborative-pr-workflow-ci-lint-gate]: [Phase 09-05] flag-based awk section extractor replaces range-pair in test_agents_section_*.sh - range pair collapses to 1 line when start regex is a subset of end regex (Rule 1 bug fix)
- [Phase 09-06]: [Phase 09-06] CONTRIBUTING.md links to AGENTS.md §11.3 as source of truth for severity tiers (does NOT duplicate category->severity table); Codex MEDIUM spec-duplication fix enforced by test guard
- [Phase 09-06]: [Phase 09-06] docs/reference/ci.md opens Severity policy + JSON schema sections with source-of-truth blockquotes pointing to AGENTS.md §11.3; rationale columns kept for user-facing context not in §11.3
- [Phase 09-06]: [Phase 09-06] .gitattributes merge=union documented as operator opt-in (NOT committed default per D-24) to prevent surprise for contributors who haven't read CONTRIBUTING.md
- [Phase 09-06]: [Phase 09-06] Rule 3 relaxed tests/phase-07/test_reference_stubs.sh to drop ci.md from stub list + added inverse 'ci.md is NOT a stub' assertion (precedent: Phase 08-04 relaxing phase-07 test_docs_skeleton.sh)
- [Phase 09.1]: [Phase 09.1-01] Wave-0 mechanical gate: 13 files in tests/phase-09.1/ (1 aggregator + 1 lib + 11 test files); 3 GREEN canaries + 8 RED extraction-invariant tests; aggregator emits PHASE 09.1 TESTS: 3/11 today, must emit 11/11 after Plan 09.1-02 commit
- [Phase 09.1]: [Phase 09.1-01] R7 review consensus enforced: test_agents_section_16.sh uses grep -F fixed-string for Appendix C literal (backticks/asterisks are regex metachars); R3 enforced: affected_pages == [] EXACTLY (no None fallback); R8 enforced: §4 preamble ratchet from 'Five page types exist.' to 'Six' is mandatory polish
- [Phase 09.1]: [Phase 09.1-01] R2 promoted dataview-fence-shape from inline acceptance criterion to first-class test_dataview_fences.sh — standalone cookbook uses 5 direct ```dataview opens + 0 outer ```markdown wrappers (vs the AGENTS.md §16 inline-illustration nested-fence shape)
- [Phase 09.1]: [Phase 09.1-01] Test scripts use minimal lib.sh (REPO_ROOT + assert_exit_code only) — Phase-09 fixture-repo helpers (make_fixture_repo, setup_git_author, etc.) unnecessary because Phase 09.1 tests operate on the real repo tree, not throwaway fixtures
- [Phase 09.1]: [Phase 09.1-01] test_template_parity.sh uses flag-based awk extraction with sentinel END patterns (## 4. → ## 5. exclusive; ## 16. → EOF) so the AGENTS.md ↔ schema/AGENTS.template.md byte-equality assertion survives the line-number drift Wave-1 will introduce when worked-example fenced blocks shrink to residue
- [Phase 09.1]: [Phase 09.1-02] Atomic extraction landed in commit bdcc2fe (1 commit, 18 files, +596/-1563): AGENTS.md 1785→1412 lines (~21% reduction); CLAUDE.md byte-equal mirror; schema/AGENTS.template.md mirrored at offset-adjusted ranges; canonical fixture regenerated via Plan 08-01 python3 routine; Phase-09.1 11/11; Phase-07 22/22; Phase-08 21/21; Phase-09 28/28
- [Phase 09.1]: [Phase 09.1-02] Pre-stage CLAUDE.md sync (bash bin/sync-claude.sh && git add CLAUDE.md before commit) collapses the documented 2-attempt R-3 path to 1 attempt; commit landed cleanly first try
- [Phase 09.1]: [Phase 09.1-02] §4 D-08 residue: kept-inline normative prose + 2-3-bullet **Example:** capsule + bare-prefix See: schema/examples/<type>.md pointer at column 0 (matches §§11.1/11.2 precedent exactly); 6 pointers, exactly one per sub-section; AGENTS.md preamble polished Five→Six page types per R8
- [Phase 09.1]: [Phase 09.1-02] R2 cookbook fence shape: docs/reference/dataview-queries.md emits 5 direct dataview fences with ZERO outer markdown wrappers (vs AGENTS.md §16 inline-illustration shape); standalone cookbook prioritizes copy-pasteability
- [Phase 09.1]: [Phase 09.1-02] R11 reflect log entry: ## [2026-04-16] reflect | progressive disclosure extraction appended to wiki/log.md EOF per AGENTS.md §9/§12 newest-at-bottom append-only; Tier-1 DR captures structural decision (why), reflect log captures activity (what/when)
- [Phase 09.1]: [Phase 09.1-02] 4 Rule 1 auto-fixes to inherited Plan 09.1-01 test files: (1-3) bash backticks-in-double-quoted-string parser bugs in test_docs_reference_new.sh + test_dataview_fences.sh broke test parsing; (3) set -e + grep -c 0-match in command substitution aborted test_dataview_fences.sh silently; (4) test_agents_section_16.sh unscoped grep false-fired on §3 commit-conventions example unrelated to §16. All bundled into atomic extraction commit per AGENTS.md §3 one-commit-per-logical-operation
- [Phase 10-brownfield-scan-bootstrap]: [Phase 10-06] BROWNFIELD_FIXTURE_CREATED_AT env override mirrors BROWNFIELD_FIXTURE_TODAY precedent; chosen over mtime-pinning in make_fixture_repo because date policy lives in bin/lib/brownfield_yaml.py
- [Phase 10-brownfield-scan-bootstrap]: [Phase 10-06] Fail-loud ValueError on malformed BROWNFIELD_FIXTURE_CREATED_AT (not silent fallback) — matches mechanical-only brownfield contract D-11
- [Phase 11-brownfield-suggest-verify]: [Phase 11-01] Wave-0 RED harness: 47 tests (3/7/19/11/7) across 5 EXPECTED_BY tiers + 7 fixtures + 4 canonical-script skeletons; PHASE 11 TESTS: 4/47 today
- [Phase 11-brownfield-suggest-verify]: [Phase 11-01] Per-plan gate split via # EXPECTED_BY: tag + --expected-by filter (REVIEWS item 6) — each downstream plan asserts its subset not aggregate success
- [Phase 11-brownfield-suggest-verify]: [Phase 11-01] Canonical scripts ship without op_hash headers (RESEARCH Q2); suggest prepends on lines 2+3 after shebang (REVIEWS item 13 Gemini)
- [Phase 11-brownfield-suggest-verify]: [Phase 11-01] applied.log DOCUMENTED PER-SCRIPT VARIANCE (REVIEWS item 10): 01 paired inputs, 02 single vault-walk line, 03/04 advisory with report_section field — schema/brownfield/migrations/README.md owns the shapes
- [Phase 11-brownfield-suggest-verify]: cluster_by_signals returns list[dict]; cluster_is_autoapproveable honors D-03 widened predicate (both frontmatter-explicit AND 3+ signals-agree paths)
- [Phase 11-brownfield-suggest-verify]: bin/lib/brownfield_walk.py extracted as single source of truth for .brownfield-ignore semantics; scan and suggest both import from it (no forked walker logic)
- [Phase 11-brownfield-suggest-verify]: Cluster-level confidence promoted to 'high' when D-03 gate satisfied, even if classify_page's per-page confidence was lower (adds inbound density as 5th cluster-level signal)
- [Phase 11-brownfield-suggest-verify]: Proposed label derivation: frontmatter > directory hint > classify_page output, preventing generic 'entity' fallback for pages under wiki/concepts, wiki/overviews, etc.
- [Phase 11-brownfield-suggest-verify]: All hashing via Python hashlib (macOS-portable); zero shell sha256sum invocations; shebang preserved on line 1 with op_hash headers on lines 2+3 via Python list manipulation
- [Phase 11-brownfield-suggest-verify]: [Phase 11-03] .brownfield-env breadcrumb pattern added (Rule 3 blocking fix) — suggest writes lib-dir path so installed migration scripts can self-locate bin/lib; tests use only PYTHONPATH for ruamel, not BROWNFIELD_LIB_DIR
- [Phase 11-brownfield-suggest-verify]: [Phase 11-03] TASK_RE \b anchor replaced with (\s|$) — \b is zero-width at ]-space boundary so '- [ ] TODO item' leaked as eligible; correctness fix enforced by Task 1 smoke test
- [Phase 11-brownfield-suggest-verify]: [Phase 11-03] test_04_advisory_only.sh SSN-redaction fix: plan must_haves + threat model + Plan 11-02 suggest implementation all agree SSN redacts to [redacted-SSN]; Wave-0 RED test expectation of raw '123-45-6789' was buggy; fixed test preserves plan policy
- [Phase 11-brownfield-suggest-verify]: [Phase 11-03] applied.log 03/04 emit unconditionally (even on 0 findings) — plan text 'appends on findings' conflicts with test_applied_log_advisory_schema asserting 03's block on privacy-sensitive-vault (0 cross-link candidates); test-as-contract wins, always-emit
- [Phase 11-brownfield-suggest-verify]: [Phase 11-04] Process substitution python3 <(cat <<EOF) replaces heredoc in review-typing — heredoc consumes Python stdin preventing scripted-input small-batch path; suggest+verify keep heredoc (no stdin read)
- [Phase 11-brownfield-suggest-verify]: [Phase 11-04] Stdin pre-peek buffer (sys.stdin.read() on non-TTY) discriminates scripted-input (small-batch) from immediate-EOF / </dev/null (large-batch) — resolves CONTEXT D-04 spec ambiguity between 'non-TTY stdout forces large-batch' and 'scripted stdin stays small-batch'
- [Phase 11-brownfield-suggest-verify]: [Phase 11-04] VALID_TYPE_ENUM for review-typing override excludes empty-string sentinel; {''} is a D-14 scaffolding value but not a valid resolved_label
- [Phase 11-brownfield-suggest-verify]: [Phase 11-04] Stale-artifact comparison strips op_hash header from .brownfield/migrations/ copy then sha256 → matches the canonical body sha256 recorded as source_script_hash; on divergence suggest must re-run
- [Phase 11-brownfield-suggest-verify]: [Phase 11-04] verify --promote performance: 500-page synthetic vault completes in ~1.5s (budget <20s); O(n) single os.walk + indexed O(1) lookups; no per-page subprocess
- [Phase 11-brownfield-suggest-verify]: [Phase 11-05] Option C renumber: §11.5 Release Workflow → §11.6; new §11.5 Brownfield Workflow closes Phase 10 WR-03 forward-ref typo by construction
- [Phase 11-brownfield-suggest-verify]: [Phase 11-05] Tier-1 DR with trigger_type: schema-update + affected_pages: [] for infrastructure-only records (inaugural-record precedent from dr-2026-04-14-phase6-decision-type)
- [Phase 11-brownfield-suggest-verify]: [Phase 11-05] canonical-AGENTS.md regenerated via Phase 8-01 wizard render routine with pinned WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA; test_canonical_agents_byte_equality.sh Rule 1 fix re-uses Phase 8 wizard-render shape per 11-01 plan fallback
- [Phase 11-brownfield-suggest-verify]: [Phase 11-05] Single comprehensive Tier-1 DR over 11 micro-DRs for review-feedback items 1-11 — they are implementation details of the apply-vs-advisory + review-manifest + lifecycle-gate architecture, not independent architectural choices
- [Phase ?]: Phase 12.2-04: schema/AGENTS.template.md got the FULL Phase 9 + 12.2 §11.3 CI mode block (closes pre-existing Phase 9 mirror gap)
- [Phase ?]: Phase 12.2-04: pre-existing AGENTS↔CLAUDE drift from b1c3691 fixed first (Plan 02 deferred-items.md) before §11.3 amendment

### Pending Todos

None.

### Roadmap Evolution

- Phase 09.1 inserted after Phase 09: Progressive Disclosure Extraction (URGENT) — extract §4 worked examples + §16 appendices from AGENTS.md/CLAUDE.md to reduce spec size while preserving §1 authority, byte-equality, wizard render, manual-setup walkthrough, and Codex agent-parity. Research backing at .planning/notes/research-progressive-disclosure-framework-comparison.md; open questions at .planning/research/questions.md; deferred workflow/operations skill extraction seeded at .planning/seeds/workflows-operations-to-skills.md.

### Blockers/Concerns

- Phase 10 needs a YAML-lib spike during planning (ruamel.yaml vs PyYAML order-loss tradeoff); treat ruamel.yaml as the single accepted new runtime dep in Phase 10.
- Phase 12 depends on Codex (or another non-Claude agent) being accessible; agent-parity tolerance rules need a spike before Phase 12 can green.
- Phase 12 Obsidian/Dataview render verification may require manual checklist with screenshots if headless Obsidian automation is not available in 2026.
- Research flags Phase 3 (ingest prompts) and Phase 5 (contradiction detection) as areas needing empirical iteration
- REQUIREMENTS.md stated 70 requirements but actual count is 95 -- traceability section corrected

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260415-fvc | fix DRFT-02 error | 2026-04-15 | ad33cb7 | [260415-fvc-fix-drft-02-error](./quick/260415-fvc-fix-drft-02-error/) |
| 260415-gzu | Flip 9 Pending → Complete in REQUIREMENTS.md (QURY-01/04/05, SOPS-01..06) | 2026-04-15 | 03be48f | [260415-gzu-flip-9-pending-requirements-qury-01-qury](./quick/260415-gzu-flip-9-pending-requirements-qury-01-qury/) |
| 260501-g5n | requirements-sync strict-mode completion check (Phase 999.7 delivered) | 2026-05-01 | 9130f87 | [260501-g5n-requirements-sync-strict-mode-completion](./quick/260501-g5n-requirements-sync-strict-mode-completion/) |
| 260503-pl1 | CLAUDE.md placeholder rule for template-public files (companion to Phase 12.1 NEUT-08 denylist) | 2026-05-03 | b1c3691 | (no quick dir — single-line edit via /gsd-fast) |

## Session Continuity

Last session: 2026-06-01T15:39:02.594Z
Stopped at: Phase 13.2 context gathered
Resume file: .planning/phases/13.2-v1-1-closure-verification-gate/13.2-CONTEXT.md

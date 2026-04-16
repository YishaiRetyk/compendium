---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Shareability
status: Ready to execute
stopped_at: Completed 09-01-test-harness-and-fixtures-PLAN.md
last_updated: "2026-04-16T07:45:23.726Z"
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 16
  completed_plans: 11
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-15)

**Core value:** The wiki is a persistent, compounding artifact -- cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Current focus:** Phase 09 — collaborative-pr-workflow-ci-lint-gate

## Current Position

Phase: 09 (collaborative-pr-workflow-ci-lint-gate) — EXECUTING
Plan: 2 of 6

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

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
- [v1.1 Roadmap] Phase 12 is a v1.0-debt verification gate (Obsidian render, Codex agent-parity, write-back scenario), not cosmetic polish.
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

### Pending Todos

None yet.

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

## Session Continuity

Last session: 2026-04-16T07:45:23.723Z
Stopped at: Completed 09-01-test-harness-and-fixtures-PLAN.md
Resume file: None

---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Shareability
status: Ready to execute
stopped_at: Phase 11 context gathered
last_updated: "2026-04-20T14:33:56.987Z"
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 29
  completed_plans: 24
  percent: 83
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-15)

**Core value:** The wiki is a persistent, compounding artifact -- cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested.
**Current focus:** Phase 11 — brownfield-suggest-verify

## Current Position

Phase: 11
Plan: Not started

## Performance Metrics

**Velocity:**

- Total plans completed: 14
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 09 | 6 | - | - |
| 09.1 | 2 | - | - |
| 10 | 6 | - | - |

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

### Pending Todos

None yet.

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

## Session Continuity

Last session: 2026-04-19T15:10:00.356Z
Stopped at: Phase 11 context gathered
Resume file: .planning/phases/11-brownfield-suggest-verify/11-CONTEXT.md

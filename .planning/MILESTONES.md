# Milestones

## v1.5 Python Migration (Shipped: 2026-07-03)

**Phases completed:** 3 phases (24–26), 17 plans
**Requirements:** 18/18 complete (PKG-01..04, TEST-01..06, MIG-01..06, CUT-01..02) — `bin/requirements-sync.sh --strict --require-complete` exits 0 (18/18)
**Timeline:** 2026-07-03 → 2026-07-03 (imported mid-v1.4 as a staged milestone; foundation hardened through 6 cross-AI review cycles on the laptop before import)

**Delivered:** The `bin/` toolchain was re-platformed from Bash to Python behind `.sh` exec-shims — a pure internal refactor with byte-behavior parity as the acceptance bar throughout. All 16 tools now `exec python3 -m compendium.<tool>`; shared logic consolidated into a frozen `compendium.common` core; the black-box bash suite converted onto a single parallel `pytest` entrypoint and the migration-only parity apparatus retired. The system's observable behavior is unchanged; its implementation is now Python.

**Key accomplishments:**

- **Foundation (Phase 24, `PKG-01..04` / `TEST-01..05`):** the installable `src/`-layout package + pinned deps + 6 required CI checks; the frozen `compendium.common` core; and the `WIKI_IMPL=bash|py` parity oracle (git-worktree-backed frozen-bash reference + 4-channel byte capture) — the one hard serialization point built first. 22-finding adversarial review applied; baseline re-pinned via the D-09 flow.
- **Parallel Migration + Cutover (Phase 25, `MIG-01..06` / `CUT-01` / `TEST-06`):** all 16 tools ported cluster-by-cluster behind the frozen surface and fanned back in through a single cutover, each flip gated against the held-fixed bash oracle (238 paired routed calls byte-identical). `migrate-privacy-dirs` retired; the migration decision record authored. 15-finding xhigh review (headline: a greenfield ruamel-import block that failed every commit, fixed via lazy `common` re-export); 5 D-09 rebases.
- **Wholesale CLI→Pytest Conversion (Phase 26, `CUT-02`):** the black-box bash suites became a pytest collector (`test_blackbox_suites.py`) running each `phase-*/test_*.sh` against the real Python `bin/` — a **bridge, not a rewrite** (D-26-01: the bash files ARE the behavioral spec). A single `pytest -n auto` is now the whole net (~4× faster than the retired serial bash runner). With one implementation left, the frozen-bash parity oracle + freeze/staged gates + `parity.yml` were **retired** (22 files deleted), which unblocked the headline behavior fix: `lint --staged`/`--ci` are now **read-only**, ending the per-commit pre-commit wiki-clobber the user hit all through the migration. The characterization goldens were preserved by rewiring to direct-Python capture (Python ≡ the retired oracle). The xhigh review (independent subagent, 60+ probing runs) returned "safe to ship" — 2 low doc/robustness fixes applied (manifest header, hook dep-probe); its one HIGH catch (a phase-08 wizard test that corrupts the live repo) is PRE-EXISTING and off the pytest path, ledgered as a v1.6 test-hygiene landmine.

**Known deferred items at close:** SHIMOUT (shim retirement) + LIBSWAP (native-lib re-platforming) in REQUIREMENTS.md Future Requirements; the optional full file-by-file idiomatic rewrite of the bash suites (beyond the sanctioned bridge — a v1.6 test-hygiene follow-on); the cheap 25-REVIEW faithful-bash items (validate_op/check_privacy `encoding=` guard, release.py SIGTERM cleanup, search byte-vs-char, audit except→None) deferred to that same pass; the phase-08 setup-parity test's non-hermetic live-repo writes (pre-existing nit).

**Archives:**

- `milestones/v1.5-MILESTONE-BRIEF.md`
- `milestones/v1.5-MILESTONE-AUDIT.md`
- `REQUIREMENTS.md` / `ROADMAP.md` remain the live v1.5 artifacts (snapshotted to `milestones/v1.5-*` at the next milestone's start, per the established pattern)

---

## v1.4 Source Lifecycle (Shipped: 2026-07-03)

**Phases completed:** 2 phases (22–23), 5 plans
**Requirements:** 11/11 complete (REPO-01..06, DRIFT-01..05) — `bin/requirements-sync.sh --strict --require-complete` exits 0
**Timeline:** 2026-07-03 → 2026-07-03 (single overnight autonomous session, 19 commits + pre-milestone housekeeping)

**Delivered:** The source lifecycle loop closed — the wiki now knows not just how sources arrive but whether their upstreams have moved or died. `repository` shipped as the extension contract's first *primary* new-type instance, and external source drift detection (backlog 999.5, deferred twice) landed as opt-in, review-only `lint --network` checks in the `drift-external` slot Phase 9 pre-plumbed.

**Key accomplishments:**

- **Repository Source Type (Phase 22, `REPO-01..06`):** `schema/reference/repository-ingestion.md` — curated snapshot bundle (never a full clone) with an `## Excerpts` registry that makes the new `#path:<file>[:L<n>[-L<m>]]`/`#commit:<sha>` locators audit-resolvable offline; within-source epistemic split (code `sourced`, README self-descriptions hedged `tentative`, `support_type` stays `direct`); lint-enforced drift-anchor frontmatter (`repo_url`/`commit_sha`/`default_branch`, LINT_VERSION 1.11.0); `bin/repo-snapshot.sh` mechanical glue. Validated on a real ingest of `open-gsd/gsd-core` — which itself caught **live external drift** (the wiki's documented GSD home was an archived redirect; the project renamed to `@opengsd/gsd-core`), upgrading the `gsd` entity from report-derived to repository-direct claims (the Model C promotion story in anger).
- **The review that mattered:** a 10-angle adversarial code review (subagent fan-out) found 15 confirmed findings — headline: the phase's own "10/10 locators resolve" verification was partially hollow (non-None ≠ usable passage), and the fence-awareness fix had been applied one resolver too shallow. All 15 fixed: a shared `_fence_mask_lines` layer now protects ALL four audit resolvers from quoted-markdown hijacking; locator grammar closed (whole-file/single-line/inverted-range); the live snapshot repaired via a logged same-phase curation amendment.
- **External Source Drift Detection (Phase 23, `DRIFT-01..05`):** three check families behind `--network` (LINT_VERSION 1.12.0) — repository HEAD-vs-`commit_sha` via `git ls-remote` (no clone), URL reachability (videos excluded per their settled link-rot stance), citation-registry link-rot ratios. **Surface, don't mark** (DR `dr-2026-07-03-external-source-drift`): the 999.5 sketch's auto-stale-marking consciously narrowed — upstream drift changes currency, not claim faithfulness against the immutable snapshot. Zero network I/O without the flag; `--ci` skip contract intact; network-free test harness (file:// upstreams + curl stub). Live run: the repository source verified current (true negative), 2 benign moved-infos, 0 dead links.

**Also this session (pre/mid-milestone):** v1.3 closed + archived + tagged; the thrice-carried `phase-14-lint-mask-fence-edge-cases` todo delivered (quick task 260703-m4f, LINT_VERSION 1.10.1); **laptop↔desktop consolidation** — the laptop's ICM paper ingest cherry-picked, and its independently-planned "v1.4 Python Migration" (6-cycle cross-AI-reviewed foundation phase) imported as **staged milestone v1.5** (phases renumbered 24–26, mandatory re-baseline brief).

**Known deferred items at close:** CCD (content-change detection beyond reachability) + IPR (`#issue:`/`#pr:` locators) in v1.4 Future Requirements; doi.org-style permanent-redirector skip-list (noise refinement, noted in the DR); cross-phase test-aggregator dedup (naturally superseded by v1.5's pytest conversion); backlog 999.3/999.6 carried.

**Archives:**

- `milestones/v1.4-ROADMAP.md`
- `milestones/v1.4-REQUIREMENTS.md`

---

## v1.3 Source Ingestion (Shipped: 2026-06-14)

**Phases completed:** 3 phases (19–21), 11 plans
**Requirements:** 17/17 complete (EXT-01..03, RPT-01..06, PDF-01..04, VID-01..04) — `bin/requirements-sync.sh --strict --require-complete` exits 0
**Timeline:** 2026-06-10 → 2026-06-14 (~5 days, 104 commits)

**Delivered:** Three new source ingestion paths — AI deep-research reports, PDFs, and YouTube videos — formalized as schema conventions plus documented acquisition pipelines, designed once via a shared 5-dimension source-type extension contract so each new source type is an instance of the contract rather than a one-off.

**Key accomplishments:**

- **Extension Contract + Research-Report Type (Phase 19, `EXT-01..03`/`RPT-01..06`):** The 5-dimension source-type extension contract (acquisition / locator / extraction / drift / epistemics + the primary-vs-secondary axis) in `schema/reference/source-types.md`, extracted from real cases with a retro-fit table. `source_type: research-report` shipped as the worked secondary instance: second-order provenance (`support_type: derived`, never `direct`), `mixed`/`tentative` epistemic defaults, `#r<n>` citation-registry locators with an audit resolver, D-08 (derived-never-direct, self-citation-only exemption) + D-09 (enum) lint gates (LINT_VERSION 1.9.0). Three report-shaped sources retro-classified with citation registries; 160 downstream `|direct|`→`|derived|` markers swept. One verification-driven gap-closure wave (19-05: table-cell `\|direct\|` blind spot) plus a 14-finding review-fix pass (incl. the WR-01 hollow-audit fix: 78/110 unresolvable tier-5 locators → 0, with a resolvable-ratio tripwire added).
- **PDF Ingestion (Phase 20, `PDF-01..04`):** `bin/pdf-extract.sh` acquisition glue (pdftoppm → Ollama olmOCR 2 → `<!-- page: N -->` markers) + authoritative `schema/reference/pdf-ingestion.md`. PDF confirmed via the contract's decision rule as an article/paper *sub-case*, not a new type: `#p<N>` page locators, extraction tool/model recorded in frontmatter (conditional lint check, LINT_VERSION 1.10.0), tiered VLM-hallucination epistemic guidance for degraded scans, `bin/ingest.sh --asset` bundle support. Validated end-to-end on a real PDF with page-anchored provenance.
- **Video/YouTube Ingestion (Phase 21, `VID-01..04`):** Authoritative `schema/reference/video-ingestion.md` defining video as a *sub-case* of `transcript` (per the same decision rule): tool-generic yt-dlp + timestamped-STT runbook, five frontmatter fields (`url`/`title`/`channel`/`publish_date`/`duration`), `#t<start>-<end>` locators with `support_type: direct`, tiered epistemic policy, and an explicit link-rot drift stance (committed transcript is the durable archive; no drift machinery). Validated end-to-end on a real 3-speaker YouTube interview; post-ingest source-scoped audit: 37 claims, 0 `insufficient-locator`.

**Known deferred items at close:** the `phase-14-lint-mask-fence-edge-cases` todo (carried from v1.1.1); backlog 999.3 (template placeholders / Phase D `WIZ`), 999.5 (external source drift — explicitly deferred 2026-06-10, citation registries are its named trigger), 999.6 (observed GTD review patterns); `repository` source type (seed Candidate A — pairs with 999.5); multimodal frame capture for slide-heavy videos; Model B auto-promotion (Model C hybrid shipped instead).

**Archives:**

- `milestones/v1.3-ROADMAP.md`
- `milestones/v1.3-REQUIREMENTS.md`

---

## v1.2 Schema Architecture (Shipped: 2026-06-08)

**Phases completed:** 4 phases (15–18), 15 plans
**Requirements:** 28/28 complete (PRIV-01..07, REF-01..10, WF-01..09, SKILL-01..02)
**Timeline:** 2026-06-04 → 2026-06-08 (~4 days)

**Delivered:** The project's own §7 progressive-disclosure principle applied to its own spec — the always-loaded `AGENTS.md`/`CLAUDE.md` monolith (1,689 lines) reduced to a ~287-line resident core, the rest extracted into a markdown-authoritative `schema/reference/*.md` + `schema/workflows/*.md` tree, with privacy re-architected as a structural harness permission and a thin drift-gated skills overlay added.

**Key accomplishments:**

- **Privacy Architecture (Phase 15, `PRIV-01..07`):** Replaced per-page §13 `privacy` frontmatter with the asymmetric two-directory model — `wiki-cloud/` (cloud-safe) and `wiki-local/` (local-only), one-way permeability enforced as a harness `deny`-read permission rather than a resident agent rule. One security-atomic migration commit re-keyed every privacy predicate so no intermediate had a dead guard; a TDD harness armed the Nyquist gate before any structural change. Privacy thereby dropped out of the always-loaded safety core.
- **Reference Extraction (Phase 16, `REF-01..10`):** §4/5/6/7/8/13 → `schema/reference/*.md`; §14/15 → `docs/reference/*.md`; §16 deleted; the `IMPORTANT:`-flagged routing table added to the core; stubs mirrored into `schema/AGENTS.template.md`; byte-equality and neutrality gates held.
- **Workflow Extraction (Phase 17, `WF-01..09`):** §9/10/11.1–11.7/12 → `schema/workflows/*.md` (including the previously-missed 182-line brownfield workflow); resident core shrank 1,689→287 lines with per-section inclusion justifications; a new `routing` lint category (LINT_VERSION 1.8.0) gates forward dangling-ref and inverse orphan-file integrity over the live tree.
- **Skills Overlay (Phase 18, `SKILL-01..02`):** Four thin pointer-only `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` routers generated and drift-gated by `bin/gen-skills.sh --check` (regenerate-diff + 6 structural assertions), wired into the pre-commit hook and a hard-fail CI `skills-check` job; zero authoritative content (markdown stays the SOT). TDD harness `tests/phase-18/` 10/10 green; advisory code-review warnings on generator cwd-resolution fixed in `18-REVIEW-FIX.md`.

**Known deferred items at close:** 5 (see STATE.md Deferred Items) — all pre-existing acknowledged deferrals carried from prior closes: the `phase-14-lint-mask-fence-edge-cases` todo, and 4 audit-flagged quick tasks (`260415-fvc`, `260415-gzu`, `260501-g5n`, `260602-d6a`) that are actually complete (false-positive from an unparseable status field). Plus Phase D Wizard fold-in (`WIZ`) deferred from v1.2 scope.

---

## v1.1.1 Graph Integrity (Shipped: 2026-06-04)

**Phases completed:** 1 phase (Phase 14: Graph Link Resolution), 3 plans
**Requirements:** 10/10 LINK requirements complete (`bin/requirements-sync.sh --require-complete` exits 0)
**Timeline:** 2026-06-02 → 2026-06-03 (~2 days, 75 commits since v1.1)

**Delivered:** A connected Obsidian graph — the schema now tells the truth about link resolution and the data is remediated to match.

**Key accomplishments:**

- **Premise correction (the headline):** The original Phase 14 self-alias approach was executed, then proven false at the LINK-10 human-verify gate — Obsidian resolves `[[X]]` by **filename/path ONLY**, never via `title` or `aliases` (confirmed for v1.12.7). Phase 14 was re-planned around the correct approach. Wrong-premise artifacts quarantined under `14-graph-link-resolution/_superseded-premise/`.
- **Convention + schema (LINK-01..03):** `CLAUDE.md`/`AGENTS.md` §3/§5/§8/§15/§16 corrected to mandate **uniform piped links** `[[id|Title]]` (target = page `id` = filename, always resolves; display = canonical title); the false self-alias invariant removed (`aliases` reverts to optional); superseding decision record `dr-2026-06-03-uniform-piped-links` supersedes the wrong-premise DR; `schema/AGENTS.template.md` + 12 templates mirrored; AGENTS.md kept byte-identical to CLAUDE.md.
- **Lint enforcement (LINK-04..06):** `bin/lint.sh` `linkres` re-pointed to validate intra-wiki link *targets* (bare `[[X]]` and unknown-`id` targets are errors; knowledge-gap red links stay `gap`/info); `--fix` rewrites bare → piped for unique matches; `orphan` reconciled to resolve by `id`/filename only; shared `mask_markdown()` helper (LINT_VERSION 1.6.0); regression tests added.
- **Data remediation (LINK-07..10):** All `wiki/` + `examples/` body links rewritten to piped form; variant reconciliation dissolved (plural/parens/casing live in cosmetic display text); orphan count 19→0; `domain-driven-design` now has 18 inbound links; connected graph human-verified in Obsidian.

**Known deferred items (acknowledged at close):**

- 1 pending todo `phase-14-lint-mask-fence-edge-cases` — WR-02/03 fence-edge-case hardening for lint markdown masking; in `.planning/todos/pending/`, promote via `/gsd-quick`. Recorded in STATE.md Deferred Items.
- 4 audit-flagged quick tasks (`260415-fvc`, `260415-gzu`, `260501-g5n`, `260602-d6a`) are all complete (each has a SUMMARY.md; flagged only by an unparseable status field) — no action.
- Backlog Phases 999.3–999.6 and v1.2-deferred items carry forward from the v1.1 close (see below).

**Archives:**

- `milestones/v1.1.1-ROADMAP.md`
- `milestones/v1.1.1-REQUIREMENTS.md`

---

## v1.1 Shareability (Shipped: 2026-06-02)

**Phases completed:** 15 phase directories (Phases 7–13.2), 52 plans
**Requirements:** 97/97 v1.1 requirements complete (0 drift, 0 incomplete — `bin/requirements-sync.sh --strict --require-complete` exits 0)
**Timeline:** 2026-04-15 → 2026-06-02 (~48 days, 382 commits)

**Key accomplishments:**

- **Neutral template foundation (Phase 7):** Public orphan-branch starter template (`YishaiRetyk/compendium`) with the Kahneman cluster relocated to `examples/`, a `bin/check-neutrality.sh` denylist CI gate over template-public paths, and the `bin/requirements-sync.sh` mechanical ledger check. Four-track `/docs/` (quickstart, guided, manual, reference).
- **Two-track setup + collaborative curation (Phases 8–9):** `bin/init-wizard.sh` guided wizard plus a byte-equivalent manual track (canonical-fixture parity enforced in CI); git-based PR curation workflow with a `log.md` contributor field, and a three-job CI gate (`bin/lint.sh --ci --format json` severity remap, privacy-leak guard, `--strict` ratchet).
- **Brownfield onboarding (Phases 10–11):** `bin/brownfield.sh scan|bootstrap|suggest|review-typing|verify` with the `bootstrap_stage` lifecycle sentinel, ruamel.yaml round-trip, four canonical migration script classes (apply vs advisory), and a 5-gate `verify --promote`. Strict mechanical-vs-judgment boundary; `--apply` deferred to v1.2.
- **Complementary-systems boundary (Phases 12, 12.1):** Decision record + `docs/reference/three-layer-model.md` defining compendium as durable wiki-memory inside a multi-system stack (task/working-memory/wiki layers, capture/clarify/organize/review routing, explicit anti-features); NEUT-08 personal-term denylist curation closed.
- **Trust + closure semantics (Phases 12.2, 13):** Local pre-commit write gate blocking zero-provenance new synthesized pages (`bin/lint.sh --strict --staged`); `bin/audit-claims.sh` claim-faithfulness sampler (supports/weak/contradicts/insufficient verdicts, review-only, fail-closed privacy chokepoint).
- **Docs finalization + closure gate (Phases 13.1, 13.2):** `/docs/reference/` fill-out + minimal Obsidian starter; the v1.1 closure gate re-ran the Obsidian render (Dataview counts 3/2/2/2/5), accepted the Codex agent-parity column as blocked-on-host-runtime, audited write-back, confirmed docs consistency + zero scope-leak, and drove `requirements-sync --strict --require-complete` to exit 0 milestone-wide.

**Known deferred items (acknowledged at close):**

- 1 pending todo `a1-lexical-dedup-lint-category` — near-duplicate page detection (`duplicate` lint category); explicitly `blocked_on: Phase 13.2`, promote via `/gsd-quick` post-v1.1. Recorded in STATE.md Deferred Items.
- Backlog Phases 999.3–999.6 (template placeholder system, v1.2 schema progressive-disclosure refactor, external source drift detection, observed GTD review patterns) remain in `.planning/ROADMAP.md` Backlog.
- v1.2-deferred from PROJECT.md: Obsidian plugin distribution, one-command installer, hosted docs site, brownfield `--apply` mode.
- Pre-existing tech debt (per the superseded 2026-04-30 milestone audit): 3 unsummarized pre-Phase-7 Kahneman raw sources (DRFT-01 warning), brownfield WR-*/IN-* nits, Phase 11 human-UAT visual items, lint `[[Page Title]]` red-link false-positives. All non-blocking.

**Archives:**

- `milestones/v1.1-ROADMAP.md`
- `milestones/v1.1-REQUIREMENTS.md`
- `milestones/v1.1-MILESTONE-AUDIT.md` (superseded 2026-04-30 snapshot; authoritative closure is the Phase 13.2 gate)

---

## v1.0 LLM Wiki Compiler MVP (Shipped: 2026-04-15)

**Phases completed:** 6 phases, 24 plans, 44 tasks
**Requirements:** 95/95 v1 requirements complete
**Timeline:** 2026-04-06 → 2026-04-15 (9 days)

**Key accomplishments:**

- **Phase 1 — Schema & Structure:** Complete 1,178-line AGENTS.md (16 sections) with structured operations vocabulary, four prescriptive workflows, fail-closed privacy routing, progressive disclosure conventions, and provisional scaling boundaries. All 19 Phase 1 requirements pass automated validation.
- **Phase 2 — Page Types & Navigation:** Five copy-paste templates (entity, concept, source, comparison, overview) with FORBIDDEN PATTERNS guardrails; five connected example pages forming a Kahneman/cognitive-biases cluster; populated index.md and parseable log.md; section 6 epistemic inline syntax.
- **Phase 3 — Ingestion & Provenance:** `bin/ingest.sh` with UTC-dated source directories, SHA-256 hashing, and collision handling. Two end-to-end validation ingests (article + journal entry) producing 20+ atomic provenance markers, clean privacy separation via dedicated local_only pages, and diff-driven page-creation judgment.
- **Phase 4 — Query & Structured Operations:** `bin/search.sh` dual-mode (index lookup + full-text + query prompt scaffolding); `bin/validate-op.sh` deterministic validator enforcing 5 mechanical checks + per-operation preconditions; compilation_status state machine; section 11.2 rewritten with write-back rules and delta compilation; three query scenarios executed end-to-end.
- **Phase 5 — Lint & Quality:** `bin/lint.sh` with YAML validation, provenance checks, orphan/cross-ref detection, domain-based staleness decay, contradiction candidate detection (section-level multi-source flagging), red-link and sparse-coverage gap detection. Zero-error wiki validates phases 1–4 schema quality.
- **Phase 6 — Reflection & Drift Detection:** Decision record page type (template, directory, sections 4.6/5/12, inaugural bootstrapping record); drift detection integrated into lint (5 checks); three-tier reflect workflow with checkpoint state and skip criteria to prevent record inflation.

**Known Tech Debt (from audit):**

- REQUIREMENTS.md bookkeeping: 9 Pending flags on QURY-01/04/05 and SOPS-01..06 flipped during completion (quick-260415-gzu); 15 requirements verified but not echoed in SUMMARY frontmatter.
- CMPL-06/07 and SOPS-06 absent from SUMMARY frontmatter (covered by Plan 03-01 and Plan 04-03).
- Article validation ingest produced 20 provenance markers vs 8–15 target (accepted during human semantic review).
- Phase 4: deferred human verification of genuine write-back scenario and Obsidian vault link/Dataview rendering.
- Phases 01/04/05/06 have partial Nyquist coverage (02/03 compliant); no substantive gaps.

**Archives:**

- `milestones/v1.0-ROADMAP.md`
- `milestones/v1.0-REQUIREMENTS.md`
- `milestones/v1.0-MILESTONE-AUDIT.md`

---

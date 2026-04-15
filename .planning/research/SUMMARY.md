# Project Research Summary

**Project:** LLM Wiki Compiler
**Milestone:** v1.1 Shareability
**Domain:** LLM-maintained Obsidian wiki compiler → shareable starter kit (template repo, two-track setup, PR workflow, brownfield onboarding)
**Researched:** 2026-04-15
**Confidence:** MEDIUM-HIGH

## Executive Summary

v1.1 turns the v1.0 personal-use starter into a cloneable public template that a technically-comfortable Obsidian user can adopt in under an hour — either via a guided bash wizard or a documented manual-edit track — and onboard an existing vault through a staged brownfield path. The four research tracks converge on a single posture: **add zero new runtime dependencies**, extend the v1.0 primitives (AGENTS.md, `bin/lint.sh`, frontmatter schema, structured ops) additively, and treat the strict mechanical-vs-judgment boundary in brownfield as the defining architectural bet. The whole milestone ships on bash + python3 + pyyaml + git + GitHub Actions; every addition is a new bash script, a new markdown file, or a new (optional) frontmatter field.

The dominant risk is **adoption-killing first impressions** — either (a) creator-specific content (Kahneman, personal journal, `local_only` leakage) surviving into the "neutral" template, or (b) `bin/brownfield.sh bootstrap` silently corrupting a real Obsidian vault on first run. Both land before any other v1.1 feature can be trusted. The second-order risk is that v1.0 debt (deferred Obsidian/Dataview render verification, untested Codex agent-parity, REQUIREMENTS.md bookkeeping drift) threads through v1.1's Dataview-visible frontmatter additions and template-vs-manual consistency gates — if those debts aren't paid, v1.1 ships on an unverified substrate.

Recommended shape: **five phases, ~8–10 plans**. Phase 1 does the neutrality/Kahneman-relocation work and ships a safe public repo. Phase 2 builds the wizard + manual track against that neutral substrate. Phase 3 lands the git PR workflow + CI lint gate. Phase 4 delivers brownfield (the largest single surface), split into bootstrap-first then suggest/verify. Phase 5 is a verification gate that explicitly closes v1.0 debt — Obsidian/Dataview render, Codex agent-parity, and a mechanical requirements-sync check — before v1.1 is declared complete.

## Key Findings

### Recommended Stack

Zero new runtime dependencies. Every v1.1 deliverable runs on the fixed v1.0 baseline (bash ≥ 4, python3 + PyYAML inline, git, Obsidian-compatible markdown). See [STACK.md](./STACK.md).

**Core technologies (all existing):**
- **bash `read` + case-statement menus** — wizard UI; rejected gum/whiptail/dialog/click as they break clone-and-go.
- **GitHub template-repository setting + `.github/` config files** (CODEOWNERS, PR/issue templates, CONTRIBUTING.md, SECURITY.md) — native GitHub UX; rejected cookiecutter/copier.
- **GitHub Actions `ubuntu-latest` with `actions/checkout@v6` + `actions/setup-python@v6`** — single ~20-line `.github/workflows/lint.yml` invoking `bin/lint.sh`.
- **Plain markdown in `/docs/`** (four tracks: quickstart, guided-setup, manual-setup, reference) — no SSG. **Critical finding:** MkDocs Material entered maintenance mode Nov 2025; Insiders repo deleted May 2026 — pre-wiring it would bet on an unmaintained project. Docusaurus deferred until v1.2 has a scoped hosted-docs decision.
- **Plain markdown brownfield report** at `.brownfield/REPORT.md` + per-class idempotent migration scripts at `.brownfield/migrations/NNN-<slug>-<sha8>.sh` — pattern confirmed across notion2obsidian, obsidian-vault-manager, obsidian-export.

**Stack confidence:** HIGH on all five additions (verified 2026 via Context7/WebSearch for action versions, Ubuntu 24.04 rollout, MkDocs Material maintenance status, gum/whiptail availability, brownfield tool patterns).

### Expected Features

Six feature buckets, ordered by dependency. See [FEATURES.md](./FEATURES.md).

**Must have (table stakes):**
- **B1 — Template-based GitHub starter repo** — "Use this template" button, empty `wiki/` with `index.md`/`log.md` skeletons, `.gitignore` for Obsidian noise, `LICENSE`, four-track `/docs/`, `examples/kahneman/` preserved intact.
- **B6 — Domain-agnostic AGENTS.md** — Kahneman examples replaced by generic placeholders; `examples/` holds the validated worked cluster.
- **B2 — Guided wizard** — bash prompts for domain, privacy defaults, LLM agent; writes personalized AGENTS.md; idempotent; `--non-interactive` with answers file; `.wizard-answers.yaml` for upgrade path.
- **B3 — Manual setup track** — `/docs/manual-setup.md` walkthrough that produces byte-identical end state to the wizard.
- **B4 — Git PR workflow** — `CONTRIBUTING.md`, PR template, CI lint gate, log.md `contributor::` Dataview inline field, `local_only` leak grep check.
- **B5 — `bin/brownfield.sh scan|bootstrap|suggest|verify`** — dry-run default, `bootstrap_stage` sentinel, content-hashed migrations, staged judgment-heavy scripts.

**Should have (differentiators):**
- Diátaxis mapping in `/docs/README.md` (tutorial/how-to/reference/explanation).
- Lint `--format json` + `--ci` mode with severity policy per category.
- PR lint comment with clickable annotations (`::error file=...,line=...::`).
- Provenance-bootstrap marks imported content with `[inferred:bootstrap]` epistemic tag.
- Agent-parity fixture (Claude Code vs Codex) — closes v1.0 flag.

**Defer (post-v1.1 backlog):**
- Obsidian plugin distribution, one-command `curl|bash` installer, hosted docs site — already in PROJECT.md out-of-scope.
- Brownfield `--apply` for judgment-heavy ops — explicitly v1.2.
- `bin/upgrade.sh` for template-fork upgrades — document ownership boundary now, implement later.
- Multi-domain example stubs, second-domain starter, CLA bot, auto-merge.

### Architecture Approach

Seven integration decisions, all extending v1.0 primitives additively. AGENTS.md stays at repo root (SCHM-01). See [ARCHITECTURE.md](./ARCHITECTURE.md).

**Major components:**
1. **`schema/AGENTS.template.md` + `bin/init-wizard.sh`** — template substitution over canonical AGENTS.md using ≤6 named placeholders (`{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`, `{{EXAMPLE_CLUSTER_REF}}`). `.wizard-answers.yaml` powers upgrades. **Rejected:** layered `AGENTS.local.md` override (violates single-schema SCHM-01) and pure generator (loses diffability).
2. **`examples/kahneman/`** — full move with wikilink rewrite; new optional frontmatter `example: true`; `EXCLUDE_DIRS` in lint gains `examples`. SUPERSEDE-class decision record required.
3. **`contributor::` Dataview inline field in log.md** — not YAML, not header-line; `bin/ingest.sh --contributor` flag auto-detects from `git config user.email`.
4. **`bootstrap_stage` optional frontmatter enum** (`raw|bootstrapped|verified`) — lint downgrades allowlisted findings to info when present; separates procedural from semantic state.
5. **`.brownfield/applied.log` with sha256 operation hashes** — content-hashed migration filenames (`NNN-<slug>-<sha8>.sh`); deterministic, re-runnable, idempotent-in-effect.
6. **`bin/lint.sh --format json --ci --skip-category`** — structural checks stay errors in PR mode; drift-external/stale/gap downgrade; `contradiction` stays error; JSON output feeds GitHub annotation shim.
7. **`/docs/` flat with `/docs/reference/` subdirectory** — four top-level docs + six reference docs; AGENTS.md stays at root (operator schema); `/docs/` is user docs.

**New frontmatter fields (both additive, default absent):** `example: boolean`, `bootstrap_stage: raw|bootstrapped|verified`.

**New CLI:** `bin/init-wizard.sh`, `bin/brownfield.sh`; flags on existing scripts: `bin/ingest.sh --contributor`, `bin/lint.sh --format|--ci|--skip-category`.

### Critical Pitfalls

See [PITFALLS.md](./PITFALLS.md) for the full 4 critical + 12 moderate + 8 minor taxonomy.

1. **C-1 Creator-content leakage into "neutral" template** — Kahneman/journal/`local_only` survives into template root via incomplete moves or git history. Prevention: `bin/check-neutrality.sh` denylist CI gate; publish from orphan branch (fresh `git init`, never history-rewrite from v1.0 repo); empty starter vault. **Must block release.**
2. **C-2 Brownfield bootstrap silently corrupts existing frontmatter** — YAML edge cases (tabs, Dataview inline, BOM, CRLF, multi-doc) + key collisions silently mangle vaults on first run. Prevention: mandatory `--dry-run` default; pre-flight `yaml.safe_load` gate; `check_key_collision` refusal; `brownfield-fixtures/` golden-output CI; `--backup` ON by default. Highest-risk surface in v1.1.
3. **C-3 Idempotency violations** — second bootstrap run re-injects sentinels / duplicates skeletons / renumbers migrations. Prevention: `test_bootstrap_idempotent` zero-byte diff on second run; content-hashed migration names; timestamp-free sentinels; skeleton markers guarding injection.
4. **C-4 PR lint gate simultaneously too strict and too loose** — whole-vault rules (orphan, cross-ref) fail on partial PR context; contributors `--no-verify` around it. Prevention: `--pr` vs `--full` two-mode lint; merge-base comparison; severity escalation policy; expected-contradiction escape hatch; gap detection exempts PR-new topics.
5. **M-10 Dataview queries break on new empty-value frontmatter** — bootstrap-injected fields match existence-check queries; user's dashboards regress silently. Prevention: schema-documented sentinels (`unknown`/`[]`/absent, never `""`); `examples/dataview-fixtures/` with known-good queries; `docs/reference/dataview-impact.md`; **close v1.0's deferred Phase 4 Obsidian/Dataview verification here**.
6. **M-12 Multi-agent interpretation drift (Claude Code vs Codex)** — natural-language schema interprets differently across agents; `log.md` diverges silently. Prevention: `test_agent_parity` canonical ingest fixture; deterministic gates do real enforcement (expand lint/validate-op); `schema/agent-notes/{claude-code,codex}.md` addendums; **close v1.0's agent-agnostic flag by running full v1.0 workflows with Codex against Kahneman cluster**.

## Implications for Roadmap

### Cross-Doc Agreement on Build Order

Stack, Features, and Architecture **all independently converge** on the same sequence. Pitfalls add sequencing constraints (C-1 gates release; C-2/C-3 front-load brownfield risk; M-10/M-12 gate milestone completion).

| Step | Consensus Across Docs |
|------|----------------------|
| 1. Kahneman relocation + neutral AGENTS.md + template repo scaffolding first | FEATURES B1+B6; ARCHITECTURE Decision 2+1; PITFALLS C-1 |
| 2. Wizard depends on neutral AGENTS.md substrate | FEATURES B2→B6; ARCHITECTURE Decision 1 after 2; PITFALLS M-1 (wizard-template drift) |
| 3. Manual track co-designed with wizard (shared answers schema) | FEATURES B3 co-ships with B2; PITFALLS M-3 (track divergence) |
| 4. CI + PR workflow depend on neutral repo existing but are otherwise independent | FEATURES B4 independent; ARCHITECTURE Decision 6 after 4; PITFALLS C-4 |
| 5. Brownfield is largest/last and benefits from stable lint `--ci` | FEATURES B5 last; ARCHITECTURE Decisions 4+5; PITFALLS C-2/C-3/M-9/M-11 |
| 6. Docs written against stable features | FEATURES in MVP notes; ARCHITECTURE Decision 7 last; PITFALLS M-3 |
| 7. Verification gate closes v1.0 debt | All four docs flag this independently |

**Minor disagreement:** ARCHITECTURE puts Decision 3 (`contributor::`) at order 6 (after PR workflow), while FEATURES suggests B4 as an independent early-ish slice. Resolution: land the schema amendment + `bin/ingest.sh --contributor` flag with the PR workflow phase; don't pre-extract it.

### Top 7 Decisions That Shape Phase Boundaries

1. **Template release is an orphan-branch `git init`, not a history-rewrite.** (C-1) Gates everything downstream; forces a dedicated scaffolding phase.
2. **Kahneman moves to `examples/` with `example: true` frontmatter and `EXCLUDE_DIRS` lint carve-out — before the wizard touches AGENTS.md.** (ARCH Decision 2; FEATURES B1+B6 co-ship) Single phase boundary.
3. **Wizard uses template substitution over the canonical AGENTS.md (placeholders), not a parallel template file.** (ARCH Decision 1; PITFALLS M-1) Prevents wizard-vs-manual drift by construction.
4. **Wizard and manual track ship together with byte-equality CI test.** (FEATURES B2+B3; PITFALLS M-3) Single phase.
5. **PR lint introduces `--format json --ci` + severity policy table before brownfield uses `verify`.** (ARCH Decision 6 before brownfield `verify`; PITFALLS C-4) Sequences PR workflow before brownfield.
6. **Brownfield splits into two phases: `scan` + `bootstrap` first (mechanical, highest-risk), then `suggest` + `verify`.** (FEATURES complexity note; PITFALLS C-2/C-3 concentrate on bootstrap) Split brownfield across two phases, not one.
7. **Final verification phase is a v1.0-debt closure gate, not cosmetic polish.** (PITFALLS M-10, M-12, m-4, m-5, m-6; PROJECT.md Active list) Must be a named phase, not slipped into the last plan.

### Pitfall-Driven Sequencing Changes

Explicit callouts where PITFALLS research changes naive ordering:

- **C-1 forces a release-gate CI check (`bin/check-neutrality.sh`) in the first phase**, before any public push. Without this, all downstream phases build on a potentially-leaky substrate.
- **C-2/C-3 justify splitting brownfield** — `bootstrap` carries the highest-risk surface in the whole milestone, deserving its own phase with full attention; `suggest`/`verify` can be a second phase.
- **M-10 requires the final verification phase to actually open Obsidian** and exercise Dataview queries on both fresh-starter and post-bootstrap fixtures — not just run `bin/lint.sh`. Schedule headless-Obsidian tooling research early if needed.
- **M-12 requires a canonical ingest fixture runnable under both Claude Code and Codex** before v1.1 completion — this is the v1.0 agent-agnostic flag finally closing.
- **m-4 (REQUIREMENTS.md drift) says build `requirements-sync` command in the first phase of v1.1**, not the last, so later phases benefit from it.
- **m-5 (partial Nyquist) says run `/gsd:validate-phase` at each phase transition**, not at milestone end — process fix, not feature.

### v1.0 Debt Items That MUST Land in v1.1

Three items from PROJECT.md "Active" + retrospective are non-negotiable gates on v1.1 completion:

1. **Obsidian render / Dataview query verification** (deferred from Phase 4; surfaced in PITFALLS M-10 and m-6, PROJECT.md Active list, PROJECT.md Key Decisions "⚠️ Revisit"). Resolution: final verification phase opens Obsidian (automated via Obsidian CLI/headless if available, else documented manual checklist with screenshots) against fresh-starter and post-bootstrap fixtures. `examples/dataview-fixtures/` with golden row counts per query.
2. **Codex agent-parity validation** (PROJECT.md "only Claude Code exercised in v1.0"; PITFALLS M-12). Resolution: `test_agent_parity` fixture — a canonical ingest scenario with expected page diff; run under both agents; diff output against golden reference; document findings in `docs/reference/agent-parity.md`. Gate v1.1 completion on this existing.
3. **Mechanical REQUIREMENTS.md sync check** (retrospective recommendation; PITFALLS m-4). Resolution: `requirements-sync` command compares each phase's VERIFICATION.md Observable Truths against REQUIREMENTS.md status; auto-flips or fails. Build in **Phase 1** so all subsequent phases benefit.

All three are named in the phase plan below.

### Suggested Phase Structure

#### Phase 1: Neutral Template Foundation
**Rationale:** C-1 gates every other phase; neutral AGENTS.md is the substrate the wizard edits and the PR workflow enforces. Pair with the `requirements-sync` tooling so m-4 never recurs.
**Delivers:** public template repo on orphan branch; Kahneman → `examples/`; neutral AGENTS.md with placeholders; `example` frontmatter field + lint `EXCLUDE_DIRS`; `.gitignore`, `.gitattributes`, LICENSE, README, four-track `/docs/` skeleton; `bin/check-neutrality.sh` CI gate; `requirements-sync` command.
**Addresses:** FEATURES B1, B6; ARCHITECTURE Decision 2; v1.0 debt item #3.
**Avoids:** C-1, m-2 (example staleness), m-4.

#### Phase 2: Two-Track Setup (Wizard + Manual)
**Rationale:** Wizard and manual must ship together to prevent drift (M-3). Template-substitution architecture (Decision 1) avoids wizard-vs-canonical drift (M-1). Depends on Phase 1's neutral substrate.
**Delivers:** `bin/init-wizard.sh` (bash `read` prompts, two-phase collect→confirm→write, `.wizard-answers.yaml`, `--non-interactive`, `--dry-run`, `--resume`); `schema/AGENTS.template.md` with ≤6 placeholders; `/docs/guided-setup.md`, `/docs/manual-setup.md`, `/docs/quickstart.md`; `test_wizard_output_matches_manual` byte-equality CI.
**Addresses:** FEATURES B2, B3; ARCHITECTURE Decision 1.
**Avoids:** M-1, M-2, M-3, m-1 (bash-only explicitly documented).

#### Phase 3: Git PR Workflow + CI Lint Gate
**Rationale:** Independent of the wizard; unlocks the shareability thesis. Introduces `--format json --ci` that brownfield `verify` will consume (Decision 6 before Decision 5 downstream).
**Delivers:** `.github/workflows/lint.yml`, `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*.yml`, `.github/CONTRIBUTING.md`, `.github/SECURITY.md`; `bin/lint.sh --format json --ci --skip-category` with severity-policy table; `bin/ingest.sh --contributor` + `log.md` `contributor::` inline field; `check_no_local_only_in_commit` gate; merge-base lint comparison; PR comment annotation shim.
**Addresses:** FEATURES B4; ARCHITECTURE Decisions 3, 6.
**Avoids:** C-4, M-5, M-6, M-7, M-8, m-7.

#### Phase 4a: Brownfield Scan + Bootstrap
**Rationale:** Highest-risk surface in v1.1 (C-2, C-3). Deserves its own phase. Must land `--dry-run` default, backups, key-collision refusal, idempotency tests, and byte-exact fixtures before any judgment-heavy work.
**Delivers:** `bin/brownfield.sh scan` (classification report with confidence signals, unknown list with reasons, dry-run only); `bin/brownfield.sh bootstrap` (mechanical-only: sentinel `bootstrap_stage`, SHA hashing, index.md/log.md skeletons, YAML normalization via order-preserving loader); `.brownfield/REPORT.md` + `.brownfield/backups/` + `.brownfield/applied.log`; `bootstrap_stage` frontmatter field + lint downgrade logic; `brownfield-fixtures/` golden-output CI; `test_bootstrap_idempotent`; transformation manifest doc.
**Addresses:** FEATURES B5 (scan + bootstrap); ARCHITECTURE Decisions 4, 5.
**Avoids:** C-2, C-3, M-9, M-11, m-8.

#### Phase 4b: Brownfield Suggest + Verify
**Rationale:** Staged judgment-heavy migration scripts; needs Phase 3's `lint --ci` stable. Split from 4a so bootstrap risk is fully absorbed first.
**Delivers:** `bin/brownfield.sh suggest` generating four-class content-hashed migration scripts (`01-page-typing`, `02-provenance-bootstrap`, `03-cross-link-inference`, `04-privacy-classification`); `[inferred:bootstrap]` epistemic sub-marker; `bin/brownfield.sh verify` shelling to `bin/lint.sh --ci`; `/docs/reference/brownfield.md` with mechanical-vs-judgment architecture.
**Addresses:** FEATURES B5 (suggest + verify).
**Avoids:** C-3 carry-forward, M-9.

#### Phase 5: Docs Finalization + Verification Gate (v1.0 Debt Closure)
**Rationale:** Docs written against stable features (ARCHITECTURE Decision 7 last); verification is an explicit gate closing v1.0 debt, not cosmetic polish.
**Delivers:** `/docs/reference/{schema-tour,brownfield,privacy-model,ci,examples,agent-parity,dataview-impact,merge-conflicts,attribution,ownership}.md`; `bin/doctest-docs.sh` fresh-clone smoke test; `examples/dataview-fixtures/` with golden queries; Obsidian render verification (headless or documented manual checklist) on fresh-starter + post-bootstrap fixtures; `test_agent_parity` fixture run under Claude Code + Codex with diff report; final `requirements-sync` reconciliation across all v1.1 phases.
**Addresses:** FEATURES B1 differentiators; ARCHITECTURE Decision 7; v1.0 debt items #1 and #2.
**Avoids:** M-3, M-10, M-12, m-3, m-5, m-6.

### Phase Ordering Rationale

- **Phase 1 before all others** because C-1 (creator-content leakage) blocks release and every downstream phase assumes a neutral substrate.
- **Phase 2 before Phase 3** because the wizard exercises the schema that PR workflow enforces; reversed order would build the lint gate against a Kahneman-flavored file and then immediately change it.
- **Phase 3 before Phase 4b** because brownfield `verify` consumes `bin/lint.sh --ci`; that flag surface must be stable.
- **Phase 4a before Phase 4b** to absorb the highest-risk surface (bootstrap) in isolation — C-2 and C-3 can't be retrofitted cleanly.
- **Phase 5 last** because docs and verification both need everything else stable; also both Obsidian/Dataview verification and Codex agent-parity require the full v1.1 feature surface to exercise.

Approximate plans per phase: [Phase 1: 1.5], [Phase 2: 2.5], [Phase 3: 1.5], [Phase 4a: 2], [Phase 4b: 1.5], [Phase 5: 1.5]. Total ≈ 10.5 plans, matching FEATURES' 8–10 estimate with verification-phase expansion.

### Research Flags

Phases likely needing deeper `/gsd:research-phase` during planning:

- **Phase 4a (Brownfield Scan + Bootstrap):** Highest-novelty surface; YAML round-trip preservation via `ruamel.yaml` vs `PyYAML` (M-11) needs a spike; Obsidian-vault edge-case fixture enumeration needs community search; the strict mechanical-vs-judgment boundary has no exact prior art per FEATURES sources (treat as architectural bet).
- **Phase 5 (Verification gate):** Headless Obsidian / Obsidian CLI automation status in 2026 is unverified — may need to fall back to documented manual checklist with screenshots. Agent-parity fixture design (what exactly is byte-compared; what's the tolerance) needs spike.

Phases with standard patterns (skip or minimal research):

- **Phase 1 (Template foundation):** Well-documented GitHub template-repo conventions; Diátaxis framework is canonical; orphan-branch release is a known git recipe.
- **Phase 2 (Wizard):** bash `read` prompt patterns are mature; copier's `answers.yml` pattern is the reference.
- **Phase 3 (PR workflow):** GitHub Actions + `bin/lint.sh` wiring is mechanical; severity-policy table design follows from v1.0's existing category system.
- **Phase 4b (Suggest + verify):** Reuses Phase 4a infrastructure; judgment-heavy heuristics are content-specific but architecturally routine.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All five additions verified 2026 (Context7/WebSearch): action versions, Ubuntu 24.04, MkDocs Material maintenance status, gum/whiptail availability, brownfield tool patterns. Zero-new-dep policy follows directly from milestone constraint. |
| Features | MEDIUM-HIGH | HIGH on Diátaxis, copier/cookiecutter patterns, docs-as-code PR workflows (multiple canonical sources agree). MEDIUM on specific Obsidian-starter conventions and brownfield tool ecosystem (active space, churns). The strict mechanical-vs-judgment boundary is a novel architectural bet, not a convention. |
| Architecture | MEDIUM-HIGH | HIGH on frontmatter extensibility, lint severity mechanism, log.md inline-field compatibility (all precedented in v1.0). MEDIUM on placeholder-vs-layered-override (Decision 1 — worth a decision record at Phase 2 start), flat-vs-nested `/docs/`, applied-log-vs-checksumming idempotency. LOW on wizard 3-way merge for schema upgrades (post-v1.1 spike). |
| Pitfalls | MEDIUM-HIGH | Grounded in prior-art (yeoman/copier/create-react-app, Dataview issues, Git-wiki experience) plus concrete v1.0 retrospective evidence (REQUIREMENTS drift, deferred Obsidian verification, untested Codex path). Specific prevention mechanisms named as checks/flags/docs sections. Headless-Obsidian automation status is the main unresolved unknown. |

**Overall confidence:** MEDIUM-HIGH. The posture is solid; the bets are named; the debts are scheduled.

### Gaps to Address

- **Headless Obsidian / Dataview render automation in 2026** — may not exist in a form suitable for CI. If not: documented manual checklist with screenshots as the v1.0-debt closure for M-10/m-6. Decide during Phase 5 planning.
- **Wizard schema-version upgrade path** (ARCH LOW confidence) — 3-way merge mechanism for `bin/init-wizard.sh --upgrade` unspecified. Acceptable: ship v1.1 without `--upgrade`; document `docs/reference/ownership.md` boundary (template-owned vs user-owned files); implement `bin/upgrade.sh` in v1.2.
- **`.obsidianignore` vs separate vault for `examples/`** (ARCH gap) — needs Obsidian verification during Phase 1. Graph-view contamination is the concrete failure; verify with real Obsidian open.
- **Codex availability and agent-parity test design** (PITFALLS M-12) — requires access to Codex; fixture tolerance rules ("what counts as a parity diff?") need a spike before Phase 5 can green.
- **YAML round-trip library choice** (PITFALLS M-11) — `ruamel.yaml` preserves order and comments but is a new runtime dep; conflicts with zero-new-dep posture. Either accept `ruamel.yaml` as the single exception (Phase 4a decision), or constrain bootstrap to transformations that PyYAML's order-loss doesn't break. Decide at Phase 4a planning.

## Sources

### Primary (HIGH confidence)

- v1.0 internal artifacts: `AGENTS.md` (1,178 lines, 16 sections), `bin/lint.sh`, `bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh`, `wiki/kahneman*`, `REQUIREMENTS.md`, Phase 1–6 VERIFICATION docs, v1.0 retrospective.
- [Diátaxis framework](https://diataxis.fr/start-here/) — canonical.
- [Copier documentation](https://copier.readthedocs.io/en/stable/comparisons/) — scaffolding patterns.
- [actions/checkout](https://github.com/actions/checkout), [actions/setup-python](https://github.com/actions/setup-python) — v6 verified 2026-04.
- [Ubuntu 24.04 GH-runner PSA](https://discourse.ubuntu.com/t/psa-for-folks-using-python-in-github-action-runners-and-ubuntu-latest-label/48654).
- [GitHub Docs — PR templates, CODEOWNERS, template-repository setting](https://docs.github.com/en).
- [kepano/kepano-obsidian](https://github.com/kepano/kepano-obsidian) — canonical Obsidian starter.

### Secondary (MEDIUM confidence)

- [Material for MkDocs alternatives](https://squidfunk.github.io/mkdocs-material/alternatives/) — maintenance-mode context.
- [MkDocs vs Docusaurus 2026 — Damavis](https://blog.damavis.com/en/mkdocs-vs-docusaurus-for-technical-documentation/).
- [Cookiecutter article — Wiley 2026](https://onlinelibrary.wiley.com/doi/full/10.1002/spe.70024).
- [notion2obsidian](https://github.com/bitbonsai/notion2obsidian), [obsidian-vault-manager](https://github.com/mpfilbin/obsidian-vault-manager), [obsidian-export](https://github.com/zoni/obsidian-export) — brownfield patterns.
- [natelandau/obsidian-metadata](https://github.com/natelandau/obsidian-metadata), [HananoshikaYomaru/Obsidian-Frontmatter-Generator](https://github.com/HananoshikaYomaru/Obsidian-Frontmatter-Generator) — frontmatter migration.
- [charmbracelet/gum](https://github.com/charmbracelet/gum) — rejected TUI option.
- [Sequin Diátaxis adoption](https://blog.sequinstream.com/we-fixed-our-documentation-with-the-diataxis-framework/).

### Tertiary (LOW confidence)

- [14 example Obsidian vaults roundup — forum](https://forum.obsidian.md/t/14-example-vaults-from-around-the-web-kepano-nick-milo-the-sweet-setup-and-more/81788).
- [Obsidian forum: bulk restructure YAML frontmatter](https://forum.obsidian.md/t/how-to-bulk-restructure-yaml-frontmatter/40169) — community patterns, varying quality.
- Strict mechanical-vs-judgment boundary in brownfield: no exact prior art found; treat as architectural bet.

---
*Research completed: 2026-04-15*
*Ready for roadmap: yes*

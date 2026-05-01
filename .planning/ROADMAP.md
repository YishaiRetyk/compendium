# Roadmap: LLM Wiki Compiler

## Milestones

- ✅ **v1.0 LLM Wiki Compiler MVP** — Phases 1–6 (shipped 2026-04-15) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Shareability** — Phases 7–13.2 (started 2026-04-15)

## Phases

<details>
<summary>✅ v1.0 LLM Wiki Compiler MVP (Phases 1–6) — SHIPPED 2026-04-15</summary>

- [x] Phase 1: Schema, Structure & Conventions (3/3 plans) — completed 2026-04-09
- [x] Phase 2: Page Types, Examples & Navigation (3/3 plans) — completed 2026-04-10
- [x] Phase 3: Ingestion & Provenance Pipeline (5/5 plans) — completed 2026-04-11
- [x] Phase 4: Query & Structured Operations (6/6 plans) — completed 2026-04-13
- [x] Phase 5: Lint & Quality (4/4 plans) — completed 2026-04-14
- [x] Phase 6: Reflection & Drift Detection (3/3 plans) — completed 2026-04-15

</details>

### 🚧 v1.1 Shareability (Phases 7–13.2)

- [x] **Phase 7: Neutral Template Foundation** — Public orphan-branch template, Kahneman → `examples/`, neutrality CI gate, `requirements-sync` mechanical check. (5/5 plans complete 2026-04-15)
- [x] **Phase 8: Two-Track Setup (Wizard + Manual)** — `bin/init-wizard.sh` plus byte-equivalent manual track, co-shipped to prevent drift. (5/5 plans complete 2026-04-16)
- [x] **Phase 9: Collaborative PR Workflow + CI Lint Gate** — Git-based PR workflow, `log.md` contributor field, `bin/lint.sh --ci --format json` severity policy, privacy-leak guard. (6/6 plans complete 2026-04-16)
- [x] **Phase 10: Brownfield Scan + Bootstrap** — `bin/brownfield.sh scan|bootstrap` with `bootstrap_stage` sentinel, ruamel.yaml round-trip, byte-exact fixture tests. (completed 2026-04-17)
- [x] **Phase 11: Brownfield Suggest + Verify** — Four staged migration script classes, `verify` wrapper over lint. (completed 2026-04-20)
- [ ] **Phase 12: Complementary Systems Boundary + GTD Alignment** — Decision record + reference doc defining compendium as durable wiki memory inside a multi-system agent stack; routes capture/clarify/organize/review without expanding schema or directory taxonomies.
- [ ] **Phase 12.1: NEUT-08 Personal-Term Denylist Curation** — Hand-curate a vetted subset of `.planning/backlog-neutrality-denylist-candidate.txt` (861 lines) into `.neutrality-denylist.txt`, closing the only outstanding partial v1.1 requirement before the closure gate. Promoted from backlog 999.2.
- [ ] **Phase 12.2: Local Wiki Write Gate** — Pre-commit gate over staged `wiki/{entities,concepts,overviews,comparisons}/` changes reusing `bin/lint.sh --strict` semantics where possible; blocks zero-provenance new synthesized pages before they land locally.
- [ ] **Phase 13: Claim Faithfulness Audit** — `bin/audit-claims.sh` samples high-risk claims (inferred/tentative/stale/high-fanout) and emits structured verdicts (supports / weak / contradicts / insufficient) against the cited source passage; review-only, privacy-respecting, no auto-fix.
- [ ] **Phase 13.1: Docs Finalization + Obsidian Starter** — `/docs/reference/` fill-out, Obsidian render check, Codex agent-parity, write-back scenario re-run, minimal Obsidian starter (templates + reference doc only; no prescribed workflows).
- [ ] **Phase 13.2: v1.1 Closure Verification Gate** — Final requirements-sync, Obsidian render, agent-parity, write-back, docs consistency, and scope-leak checks after all v1.1 work is complete.

## Phase Details

### Phase 7: Neutral Template Foundation
**Goal**: A stranger can clone the public template repo and get a Kahneman-free, license-clean, traceability-enforced starter — and the creator's private vault history never reaches the public release.
**Depends on**: Nothing (first v1.1 phase)
**Requirements**: TMPL-01, TMPL-02, TMPL-03, TMPL-04, TMPL-05, TMPL-06, TMPL-07, TMPL-08, TMPL-09, TMPL-10, TMPL-11, NEUT-01, NEUT-02, NEUT-03, NEUT-04, NEUT-05, NEUT-06, NEUT-07, DEBT-03
*(Note: NEUT-08 infrastructure shipped in Phase 7; denylist curation deliverable lives in Phase 12.1)*
**Success Criteria** (what must be TRUE):
  1. User visits the public GitHub repo and sees a "Use this template" button; the cloned repo contains `README.md`, `LICENSE`, four-track `/docs/` skeleton, empty `wiki/` (only `index.md`/`log.md` skeletons), `PRIVACY.md`, and `CLAUDE.md` alongside `AGENTS.md`. The public control-plane surfaces — `AGENTS.md`, `CLAUDE.md`, `README.md`, `PRIVACY.md`, `/docs/**`, `.github/**`, `wiki/**`, `bin/**` — contain zero Kahneman or personal-vault strings. Kahneman content remains intact under `examples/kahneman/**`, which is the sole permitted home for it.
  2. User runs a fresh `git log` on the public repo and finds only the v1.1 release commit — no v1.0 personal-knowledge history is reachable (orphan-branch release runbook documented and executed).
  3. User opens `examples/kahneman/` and finds the full 7-page cluster preserved with internal wikilinks intact and a README explaining it is a reference example; `bin/lint.sh` does not warn on it because `EXCLUDE_DIRS`/`example: true` are honored.
  4. A PR that reintroduces Kahneman terminology into `AGENTS.md`, or any personal-vault denylist term into public paths, fails CI via the neutrality + denylist grep gate.
  5. User runs `bin/requirements-sync.sh` and sees a mechanical diff between `VERIFICATION.md` truths and `REQUIREMENTS.md` checkbox status; any drift is flagged before merge.
**Plans:** 5 plans
Plans:
- [x] 07-01-PLAN.md — DEBT-03 requirements-sync.sh + Wave 0 test harness
- [x] 07-02-PLAN.md — Relocate Kahneman cluster to examples/, shrink wiki to skeleton, extend lint EXCLUDE_DIRS, commit NEUT-07 decision record
- [x] 07-03-PLAN.md — Neutralize AGENTS.md + produce schema/AGENTS.template.md + CLAUDE.md byte-dup + pre-commit hook
- [x] 07-04-PLAN.md — Top-level scaffolding (README, LICENSE, PRIVACY, .gitignore) + docs/ four-track skeleton + release runbook
- [x] 07-05-PLAN.md — bin/check-neutrality.sh + human-reviewed denylist + bin/release.sh + neutrality CI workflow

### Phase 8: Two-Track Setup (Wizard + Manual)
**Goal**: A new adopter can reach a working personalized `AGENTS.md` by either running `bin/init-wizard.sh` or hand-editing per `docs/manual-setup.md` — and both paths produce a byte-identical end state.
**Depends on**: Phase 7 (neutral `AGENTS.md` substrate + template placeholders)
**Requirements**: WZRD-01, WZRD-02, WZRD-03, WZRD-04, WZRD-05, WZRD-06, WZRD-07, WZRD-08, WZRD-09, WZRD-10, WZRD-11, MANUAL-01, MANUAL-02, MANUAL-03, MANUAL-04, MANUAL-05, MANUAL-06
**Success Criteria** (what must be TRUE):
  1. User runs `bin/init-wizard.sh`, answers ~6 semantically-grouped prompts (Domain → LLM agent → Privacy → Obsidian), and the wizard writes a personalized `AGENTS.md`, `.wizard-answers.yaml`, and an initial decision record; on completion it prints a diff summary of every file written.
  2. User runs `bin/init-wizard.sh --dry-run` and sees the full rendered diff without any file mutation; re-running the wizard on an already-initialized repo is idempotent (no-op or clear refusal).
  3. User runs `bin/init-wizard.sh --answers-file canonical.yaml` in CI (non-interactive) and produces an `AGENTS.md` that is byte-equal to the end state described by `docs/manual-setup.md`'s checklist — enforced by a CI test.
  4. User who prefers the hand-edit path follows `docs/manual-setup.md` section-by-section, using a one-to-one wizard-prompt checklist and a concrete minimal-diff example, and lands in the same configured state.
  5. Wizard pre-flight detects missing `git`/`bash >= 4` and prints an actionable remediation message before touching anything; invalid input (bad domain slug, unknown agent, unknown privacy tier) is rejected with a clear error.
**Plans:** 5 plans
Plans:
- [x] 08-01-test-harness-and-fixtures-PLAN.md — Wave 0 test harness + canonical fixtures (tests/phase-08/, schema/fixtures/, .gitattributes EOL pin)
- [x] 08-02-init-wizard-core-PLAN.md — bin/init-wizard.sh core (preflight, prompts, validator, render, --dry-run, --render-to, idempotency guard) + 7 tests
- [x] 08-03-wizard-side-effects-PLAN.md — Wizard write side (.wizard-answers.yaml atomic, initial decision record, sync-claude invoke, wiki/index.md edit) + 4 tests
- [x] 08-04-manual-track-and-docs-PLAN.md — docs/manual-setup.md (D-07 11-section walkthrough), guided-setup, quickstart, setup-prerequisites, WZRD-07 amendment + 5 doc tests
- [x] 08-05-ci-byte-equality-PLAN.md — MANUAL-06 byte-equality test + .github/workflows/setup-parity.yml CI gate
**UI hint**: yes

### Phase 9: Collaborative PR Workflow + CI Lint Gate
**Goal**: A contributor can fork the template, ingest on a branch, open a PR, and have lint + privacy + attribution gates run automatically — with severity policies that distinguish structural errors from judgment-shaped findings.
**Depends on**: Phase 7 (public template + CI infrastructure); concurrent-capable with Phase 8.
**Requirements**: COLAB-01, COLAB-02, COLAB-03, COLAB-04, COLAB-05, COLAB-06, COLAB-07, COLAB-08, CI-01, CI-02, CI-03, CI-04, CI-05, CI-06, CI-07, CI-08, CI-09
**Success Criteria** (what must be TRUE):
  1. A contributor opens a PR and `.github/workflows/lint.yml` runs `bin/lint.sh --ci --format json` on `ubuntu-latest`; structural findings (`yaml`, `orphan`, `crossref`, `provenance`) block merge while `stale`, `gap`, and `contradiction` surface as warnings; JSON output is converted to inline GitHub annotations.
  2. `bin/ingest.sh --contributor <handle>` (auto-detected from git config on multi-author repos, omitted on single-author) writes a `contributor::` Dataview inline field in `log.md`; git commit authorship remains the documented attribution source of truth.
  3. A PR that introduces `privacy: local_only` into a public path (`examples/**`, `docs/**`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/**`) fails the privacy-leak guard; `local_only` used inside `wiki/**` user content passes cleanly.
  4. User runs `bin/lint.sh --strict` on a branch adding an `[inferred]`/`[tentative]` claim without a matching decision record, or a new page lacking provenance, and lint exits non-zero (quality ratchet at merge time).
  5. `CONTRIBUTING.md` and `/docs/reference/ci.md` document the PR workflow, merge-conflict recipes for `index.md` and `log.md`, version-pinning via `--version`, and GitLab/Gitea/Codeberg equivalents of the GitHub workflow.
**Plans:** 6 plans
Plans:
- [x] 09-01-test-harness-and-fixtures-PLAN.md — Wave 0 test harness + 8 fixture repos (lib.sh helpers, run.sh aggregator)
- [x] 09-02-lint-flags-json-ci-version-PLAN.md — bin/lint.sh flags: --format json, --ci severity remap, --skip-category, --version, --require-version (CI-02/03/04/08)
- [x] 09-03-lint-strict-escape-hatch-contributor-PLAN.md — bin/lint.sh --strict (DR-match + new-page provenance), escape-hatch marker parser, --count-skips, contributor category (CI-06, COLAB-08)
- [x] 09-04-privacy-ingest-search-contributor-PLAN.md — bin/check-privacy.sh standalone + bin/ingest.sh --contributor + bin/search.sh --contributor + .git-author-map.txt (CI-07, COLAB-04, COLAB-07)
- [x] 09-05-ci-workflow-agents-amendments-pr-template-PLAN.md — .github/workflows/lint.yml (3 parallel jobs) + json-to-annotations.py + PR template + AGENTS.md §§11.1/11.3/12 amendments (CI-01, CI-05, COLAB-02, COLAB-03)
- [x] 09-06-contributing-docs-integration-PLAN.md — CONTRIBUTING.md + docs/reference/ci.md full populate + cross-links (COLAB-01/05/06, CI-09)

### Phase 09.1: Progressive Disclosure Extraction (INSERTED)

**Goal**: Reduce `AGENTS.md`/`CLAUDE.md` (~1,785 lines) by extracting §4 worked examples to `schema/examples/<type>.md` (6 files) and §16 Appendices A & B to `docs/reference/{dataview-queries,commit-examples}.md` (2 files); preserve byte-equality (AGENTS.md ≡ CLAUDE.md), canonical-fixture parity (setup-parity CI), Codex agent-parity, and the "sole authoritative specification" framing via uniform `See: <path>` pointers matching §§11.1/11.2/12 convention.
**Requirements**: TBD
**Depends on:** Phase 9
**Plans:** 2/2 plans complete

Plans:
- [x] 09.1-01-PLAN.md — Wave-0 test scaffolding (tests/phase-09.1/run.sh + lib.sh + 10 RED tests asserting I-1..I-15 extraction invariants)
- [x] 09.1-02-PLAN.md — Atomic extraction: 6 schema/examples/* + 2 docs/reference/* + DR; edit AGENTS.md + schema/AGENTS.template.md residue; regenerate canonical fixture; update wiki/index.md Decisions; CLAUDE.md auto-syncs via pre-commit hook

### Phase 10: Brownfield Scan + Bootstrap
**Goal**: A user with a real existing Obsidian vault can run `bin/brownfield.sh scan` safely (no vault mutation) and `bin/brownfield.sh bootstrap` confidently (mechanical-only, idempotent, byte-exact reproducible) without corrupting frontmatter or losing content.
**Prerequisite dependency** (user-facing): Brownfield phases require **Python 3 with `ruamel.yaml`** installed locally. Unlike the bash-native wizard/ingest/search/lint paths, brownfield onboarding has a narrowly-scoped Python runtime dependency used for YAML comment-and-key-order-preserving round-trip. `docs/reference/brownfield.md` and `docs/quickstart.md` must surface this install step (`pip install ruamel.yaml` or distro package) before a user attempts brownfield. This is the single new runtime dependency introduced in v1.1, revising STACK.md's "zero new deps" posture for brownfield only.
**Depends on**: Phase 7 (`EXCLUDE_DIRS` lint extensibility and `AGENTS.md §5` frontmatter schema); Phase 9 (`bin/lint.sh --ci` severity policy referenced by downgrade logic).
**Requirements**: BRWN-01, BRWN-02, BRWN-03, BRWN-04, BRWN-05, BRWN-06, BRWN-07, BRWN-08, BRWN-09, BRWN-10, BRWN-21
**Success Criteria** (what must be TRUE):
  1. User runs `bin/brownfield.sh scan` on their vault and gets `.brownfield/REPORT.md` inventorying each page with a provisional (non-authoritative) type suggestion and confidence signal; `unknown` pages are listed with a one-line reason framed as an open question; no vault file is mutated.
  2. User runs `bin/brownfield.sh bootstrap` and the tool touches only mechanical transforms — sentinel frontmatter (empty values + `bootstrap_stage: bootstrapped`), SHA hashing of source files, `index.md`/`log.md` skeletons if absent, and YAML normalization — preserving page bodies verbatim and preserving comments/key order via `ruamel.yaml` round-trip.
  3. Running `bootstrap` twice on the same vault produces zero-byte diff on the second run (idempotency); a byte-exact fixture CI test validates this across sample vaults.
  4. After bootstrap, `bin/lint.sh` downgrades the allowlist findings (unknown `type`, empty `knowledge_domain`, missing `sources`, `epistemic_status: tentative`) from `error` to `info` when `bootstrap_stage: bootstrapped`; a new `brownfield` lint category reports counts and warns on pages `bootstrapped` older than 30 days.
  5. If `bin/ingest.sh` encounters `bootstrap_stage` on a normal ingest, it strips the field to prevent pollution; `AGENTS.md §5` documents `bootstrap_stage` narrowly as the **brownfield onboarding sentinel** (enum `raw|bootstrapped|verified`) — explicitly NOT a substitute for the claim-level + source-linked provenance model (PROV-01..05). The field tracks migration state and marks imported-vs-LLM-generated lineage at page level; it is not the general provenance mechanism.
**Plans:** 6/6 plans complete
Plans:
- [x] 10-01-PLAN.md — Wave 1: tests/phase-10/ harness + 7 byte-frozen fixtures (dual golden contract per D-07) + 2 self-check tests
- [x] 10-02-PLAN.md — Wave 2: bin/brownfield.sh subcommand dispatch + scan subcommand + bin/lib/brownfield_classify.py + .brownfield-ignore parser + 6 tests (BRWN-01, BRWN-02, BRWN-16)
- [x] 10-03-PLAN.md — Wave 3: bin/brownfield.sh bootstrap (dry-run default + --apply) + bin/lib/brownfield_yaml.py ruamel round-trip + typed-merge Class A/B/C + APPLIED.md/SKIPPED.md + idempotency + 12 tests (BRWN-03, BRWN-04, BRWN-05, BRWN-06, BRWN-07, BRWN-21)
- [x] 10-04-PLAN.md — Wave 3: AGENTS.md §5 bootstrap_stage + bootstrap_date rows + CLAUDE.md byte-sync + schema/AGENTS.template.md mirror + canonical-AGENTS.md regen + bin/ingest.sh BRWN-10 strip + bin/lint.sh BRWN-08 downgrade + brownfield category + 9 tests (BRWN-07, BRWN-08, BRWN-09, BRWN-10)
- [x] 10-05-PLAN.md — Wave 4: docs/reference/brownfield.md scan+bootstrap full populate + suggest/verify stubs + docs/quickstart.md ruamel.yaml prereq + 10-VERIFICATION.md + 3 docs tests (BRWN-01..10, BRWN-21)
- [x] 10-06-PLAN.md — Gap closure: BROWNFIELD_FIXTURE_CREATED_AT env override in bin/lib/brownfield_yaml.py (BRWN-21 transformed-output byte-equality across calendar dates)

### Phase 11: Brownfield Suggest + Verify
**Goal**: A user who has completed `bootstrap` can run `bin/brownfield.sh suggest` to generate four staged, idempotent, user-invoked migration scripts for judgment-heavy work — and run `verify` to re-lint the vault after applying them, with zero claim-level schema expansion.
**Prerequisite dependency** (user-facing): Inherits Phase 10's Python 3 + `ruamel.yaml` requirement. Users who skipped brownfield in Phase 10 do not need this; users on the brownfield path need it before running any Phase 11 subcommand. Surfaced in `docs/reference/brownfield.md`.
**Depends on**: Phase 10 (scan/bootstrap infrastructure + `bootstrap_stage` field); Phase 9 (`bin/lint.sh --strict` + JSON mode consumed by `verify` wrapper).
**Requirements**: BRWN-11, BRWN-12, BRWN-13, BRWN-14, BRWN-15, BRWN-16, BRWN-17, BRWN-18, BRWN-19, BRWN-20
**Success Criteria** (what must be TRUE):
  1. User runs `bin/brownfield.sh suggest` and gets `.brownfield/REPORT.md` plus four migration scripts in `.brownfield/migrations/` — `01-page-typing.sh`, `02-provenance-bootstrap.sh`, `03-cross-link-inference.sh`, `04-privacy-classification.sh` — each rule-based (no LLM calls), self-describing, dry-run by default, with `--apply` to execute that single class.
  2. Each migration script is idempotent when re-run: header carries `# op_hash: <sha256>` derived from normalized operation descriptors, and `.brownfield/applied.log` records executions; running a script after it has been applied is a safe no-op.
  3. `02-provenance-bootstrap.sh` tags pre-existing claims using only the existing epistemic vocabulary (`inferred` per EPST-01) — no new claim-level schema fields, no magic-string provenance values; the imported-vs-LLM-generated distinction lives at page level via `bootstrap_stage`.
  4. User runs `bin/brownfield.sh verify` and it wraps `bin/lint.sh` with brownfield-appropriate severity thresholds to confirm the vault passes after user-applied migrations.
  5. `docs/reference/brownfield.md` and `AGENTS.md §11.5 Brownfield Workflow` explain the mechanical-vs-judgment boundary explicitly, document the `git reset` canonical undo recipe, and note that v1.1 requires manual per-script invocation (auto-apply chain-runner is explicitly deferred to v1.2 BRWNAPPLY-01).
**Plans:** 5/5 plans complete
Plans:
- [x] 11-01-PLAN.md — Wave-0 test harness + 7 fixtures + 4 canonical script skeletons + RED test suite locking the D-19 contract — completed 2026-04-20 (47 tests; PHASE 11 TESTS: 4/47 RED)
- [x] 11-02-PLAN.md — `bin/brownfield.sh suggest` (hybrid byte-copy + candidate-file generation) + `cluster_by_signals()` in brownfield_classify
- [x] 11-03-PLAN.md — Four canonical migration scripts (01 apply-from-manifest, 02 direct-apply + soft prereq WARN, 03/04 advisory) + brownfield_provenance.py
- [x] 11-04-PLAN.md — `bin/brownfield.sh review-typing` (TTY + AI-handoff) + `verify [--promote]` (D-14 5-gate) + end-to-end golden fixture
- [x] 11-05-PLAN.md — AGENTS.md §11.5 populate (Option C renumber §11.5→§11.6; closes WR-03) + docs/reference/brownfield.md + REQUIREMENTS BRWN-12 rename + BRWN-22 new + Tier-1 DR

### Phase 12: Complementary Systems Boundary + GTD Alignment

**Goal**: Explicitly define compendium's role inside a multi-system agent stack — durable wiki memory and review support, not task execution, reminders, calendar, or high-churn operational state — before v1.1 closes.
**Depends on**: Phases 7–11
**Why this phase exists**: The project now has a concrete GTD/backend framing, but the boundary still lives in exploratory notes rather than the canonical shipped surface. This phase makes the intended architecture explicit before scope creep hardens into accidental features.
**Requirements**: BOUND-01, BOUND-02, BOUND-03
**Success Criteria** (what must be TRUE):
  1. A decision record states that compendium owns durable, provenance-backed synthesis and reflective memory, while complementary systems own executable commitments, reminders, calendars, and transactional/operational state.
  2. A reference doc explains the 3-layer model: task layer, working-memory layer, wiki-compiler layer.
  3. The doc gives routing rules for capture / clarify / organize / review without adding new wiki page types or new `wiki/` directory taxonomies.
  4. The shipped docs make clear that compendium is meant to complement a GTD/task backend, not replace it.
  5. The boundary is reflected consistently across README / docs / decision records with no contradictory "all-in-one PKM/task system" framing.
**Non-goals**:
- No task manager features
- No reminders/calendar support
- No Slack/ticket/event ingest pipeline
- No GTD-specific filesystem expansion
- No canonical review dashboards
**Plans:** 3/4 plans executed
Plans:
**Wave 1**
- [x] 12-01-decision-record-PLAN.md — BOUND-01 decision record at wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md (type: decision, trigger_type: schema-update, affected_pages: [], 7 required sections per AGENTS.md §4.6)
- [x] 12-02-reference-doc-PLAN.md — BOUND-02 reference doc at docs/reference/three-layer-model.md (3-layer model + 4-verb routing table + anti-features section)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 12-03-surface-integration-PLAN.md — README pointer (D-10 locked wording) + docs/reference/index.md bullet + wiki/index.md Decisions entry + wiki/log.md reflect entry

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 12-04-audit-and-verification-PLAN.md — Capture phase-base SHA, run reviewed-match audit grep (D-12 patterns over D-13 scope), write 12-VERIFICATION.md, flip REQUIREMENTS.md BOUND-01/02/03 status, run bin/requirements-sync.sh --strict --phase 12

### Phase 12.1: NEUT-08 Personal-Term Denylist Curation (PROMOTED FROM 999.2)

**Goal**: Hand-curate the personal-domain term set deferred from Phase 7 and merge a vetted subset into `.neutrality-denylist.txt`, closing the only outstanding partial v1.1 requirement before the closure gate.
**Depends on**: Phase 7 (`bin/check-neutrality.sh` infrastructure, `.neutrality-denylist.txt` file, `.planning/backlog-neutrality-denylist-candidate.txt` 861-line `--suggest-denylist` output).
**Why this phase exists**: NEUT-08 was deferred at the end of Phase 7 per user decision "approved — minimal" (infrastructure shipped; entries deferred). NEUT-08 remains the only outstanding partial v1.1 requirement. Completing the curation before Phase 13.2's closure gate is a milestone-integrity requirement — the closure gate cannot sign off while any active requirement is partial.
**Requirements**: NEUT-08
**Success Criteria** (what must be TRUE):
  1. A human-vetted subset of `.planning/backlog-neutrality-denylist-candidate.txt` is merged into `.neutrality-denylist.txt`, with each kept term annotated by category (personal vault, prior project, ambient project name, etc.).
  2. `bin/check-neutrality.sh` exits 0 on the live tree post-merge (no false positives on legitimately neutral text).
  3. A neutrality-leak fixture (introducing a denylisted term into a public path) fails the gate as expected, proving the new entries are wired correctly.
  4. NEUT-08 flips from `Deferred (partial)` to `Complete` in REQUIREMENTS.md and the Phase 7 → Phase 12.1 reassignment is reflected in the phase-mapping table.
  5. A Phase 12.1 verification artifact records NEUT-08 as `Complete` (rationale, kept-term count, and fixture evidence), and `bin/requirements-sync.sh --strict --phase 12.1` reports zero drift against the post-curation traceability state.
**Non-goals**:
- No expansion of `bin/check-neutrality.sh` semantics (infrastructure already shipped in Phase 7)
- No new categories beyond what the candidate file surfaces
- No retroactive lint of historical commits
**Plans**: TBD

### Phase 12.2: Local Wiki Write Gate

**Goal**: Catch structurally invalid wiki writes and zero-provenance new synthesized pages before they are committed locally, while preserving semantic claim-faithfulness checking for Phase 13.
**Depends on**: Phase 9 (CI / `--strict` infrastructure), Phase 12
**Why this phase exists**: `bin/lint.sh --strict` already enforces a merge-time quality ratchet in PRs, but the local ingest/query write path has no equivalent gate. This leaves a gap where low-quality wiki writes can land in history before the next lint run.
**Requirements**: WGATE-01, WGATE-02, WGATE-03, WGATE-04
**Success Criteria** (what must be TRUE):
  1. The local commit path runs a deterministic gate against staged wiki changes before commit completes.
  2. New staged pages under `wiki/{entities,concepts,overviews,comparisons}/` fail the gate if they contain zero `[prov:...]` markers.
  3. The gate reuses existing `bin/lint.sh --strict` semantics where possible rather than inventing a second policy surface.
  4. Exemptions remain aligned with current schema/tooling: `type: source`, `type: decision`, `examples/`, and brownfield-specific transitional cases are not falsely blocked.
  5. The pre-commit UX is actionable: failures point the user to the relevant file/path and the exact reason.
  6. The existing `AGENTS.md` ↔ `CLAUDE.md` sync hook continues to work unchanged or is cleanly composed with the new gate.
  7. The gate is explicitly staged-index aware; it does not rely blindly on PR-mode `origin/main...HEAD` behavior from `bin/lint.sh --strict`.
**Non-goals**:
- No semantic claim-faithfulness checking (see Phase 13)
- No cloud API use
- No auto-rewrite of pages
- No full-vault lint on every commit
**Plans**: TBD

### Phase 13: Claim Faithfulness Audit

**Goal**: Add a source-grounded audit workflow that checks whether wiki claims faithfully reflect the cited source passage, not just whether `[prov:]` markers exist.
**Depends on**: Phase 5 (lint foundations), Phase 6 (drift detection), Phase 9 (privacy / CI infrastructure), Phase 12 (boundary clarification), Phase 12.2 (local write gate)
**Why this phase exists**: The current system validates provenance presence and locator syntax, but not semantic faithfulness. This is the highest-leverage remaining integrity gap behind the "error compounding" critique.
**Requirements**: FAITH-01, FAITH-02, FAITH-03, FAITH-04
**Success Criteria** (what must be TRUE):
  1. `bin/audit-claims.sh` exists and can sample claims from recently modified pages plus high-risk claims (`[epistemic:: inferred]`, `[epistemic:: tentative]`, stale-source claims, and claims on high-fanout pages).
  2. The audit resolves each claim's `[prov:source_id#locator]` to the relevant source passage and checks whether the passage supports, weakly supports, contradicts, or does not establish the claim.
  3. `privacy: local_only` claims are never sent to cloud APIs; the audit either uses a local verifier or emits an explicit skipped/privacy finding.
  4. The audit writes structured review findings with page path, line number, source ID, locator, verdict, and rationale.
  5. The workflow is review-only by default: no automatic wiki edits, no auto-fix, no default CI gate.
  6. The audit can optionally emit machine-readable findings that future lint/report tooling can consume.
**Non-goals**:
- No auto-rewrite of claims
- No required CI blocking gate in the first shipped version
- No SQLite requirement
- No full-vault audit by default
**Plans**: TBD

### Phase 13.1: Docs Finalization + Obsidian Starter

**Goal**: All `/docs/reference/` material is filled out against the now-stable v1.1 feature surface, every deferred v1.0 verification (Obsidian render, multi-agent parity, write-back scenario) is executed end-to-end, and a minimal shipped Obsidian starter -- page-type templates derived from the schema templates plus a reference doc -- closes the day-1 page-creation ergonomics gap without prescribing review workflows.

**Scope note**: Phase 13.1's Obsidian scope is intentionally minimal: verify renderability and ship page-creation ergonomics only. Review dashboards, GTD-specific views, hotkey bundles, and workflow-specific Dataview surfaces remain deferred until observed practice justifies them (see backlog Phase 999.6).
**Depends on**: Phases 7–13 (all feature surfaces stable).
**Requirements**: DEBT-01, DEBT-02, DEBT-04, OBSID-01, OBSID-02, OBSID-03
**Success Criteria** (what must be TRUE):
  1. User opens the generated wiki (both fresh-starter and post-bootstrap fixtures) in Obsidian and confirms that wikilinks resolve, Dataview queries render with expected row counts against `examples/dataview-fixtures/`, and graph view is not contaminated by `examples/` — closing v1.0's deferred Phase 4 verification.
  2. User runs the canonical v1.0 ingest scenario end-to-end against the Kahneman example cluster under a second agent (Codex or other non-Claude), diffs against a golden reference, and documents the findings plus agent-parity tolerance in `docs/reference/agent-parity.md` — closing v1.0's untested Codex path.
  3. User executes the Phase 4 genuine write-back query scenario (the one that produced NO-WRITE-BACK in the v1.0 re-run) end-to-end; the query produces synthesized claims that are compiled back into the wiki with correct provenance and no drift.
  4. Every `/docs/reference/` file (`schema-tour.md`, `brownfield.md`, `privacy-model.md`, `ci.md`, `examples.md`, plus `agent-parity.md` and any Dataview/merge-conflict reference) is filled out with accurate descriptions of the shipped v1.1 features.
  5. Phase 13.1 verification notes document the Obsidian render, agent-parity, and write-back results so the Phase 13.2 closure gate can re-run or audit them.
  6. A minimal Obsidian starter ships for day-1 use: page-type templates derived from the schema templates plus a reference doc explaining how to use them. This starter improves page creation ergonomics without introducing canonical dashboards, hotkey bundles, or workflow prescriptions.
**Plans**: TBD

### Phase 13.2: v1.1 Closure Verification Gate

**Goal**: Close v1.1 only after all active v1.1 phases have been implemented, verified, documented, and checked for scope creep.
**Depends on**: Phase 13.1
**Why this phase exists**: Phase 13.1 (Docs Finalization) carries the documentation and verification tasks, but the milestone needs a dedicated end-of-line gate that runs after all v1.1 implementation work is complete.
**Requirements**: CLOSE-01, CLOSE-02, CLOSE-03, CLOSE-04
**Success Criteria** (what must be TRUE):
  1. `bin/requirements-sync.sh --strict` shows zero drift between `REQUIREMENTS.md` and phase verification artifacts across all v1.1 phases.
  2. Obsidian render, non-Claude agent-parity, and genuine write-back scenarios have been re-run or explicitly audited after Phases 12, 12.1, 12.2, 13, and 13.1 are in place.
  3. README, docs, decision records, and roadmap consistently describe the final v1.1 feature surface, including complementary-system boundaries and explicitly deferred work.
  4. A final scope-leak check confirms no task engine, reminder/calendar layer, high-frequency event ingest, premature scaling tier, or canonical GTD dashboard has entered v1.1.
**Non-goals**:
- No new product features
- No new schema expansion except fixes required by failed verification
- No speculative GTD review pattern documentation
**Plans**: TBD

## Backlog

### Phase 999.1: Brownfield Vault Initialization (SUPERSEDED — absorbed into v1.1 Phases 10–11)

**Status:** Superseded 2026-04-15. The backlog goal — scan/bootstrap/suggest/verify workflow for existing Obsidian vaults — is fully captured by v1.1 Phases 10 (Scan + Bootstrap) and 11 (Suggest + Verify) under REQ-IDs BRWN-01..21. This entry is retained for historical traceability only; do not plan new work against it.

**Supersedes:** promoted backlog → v1.1 Phases 10–11
**Original goal:** Workflow to scan an existing Obsidian vault with non-conforming pages and bring them into compliance: schema inference, bulk frontmatter injection, provenance bootstrapping, index auto-generation, template application, and conformance linting with auto-fix.

### Phase 999.2: NEUT-08 Personal-Term Denylist Curation (PROMOTED — see Phase 12.1)

**Status:** Promoted 2026-05-01 to active v1.1 as **Phase 12.1** so the only outstanding partial v1.1 requirement (NEUT-08) clears before the Phase 13.2 closure gate. This entry is retained for historical traceability only; do not plan new work against it.

**Promoted to:** Phase 12.1 (NEUT-08 Personal-Term Denylist Curation)
**Original goal:** Hand-review `.planning/backlog-neutrality-denylist-candidate.txt` (861 lines of deterministic `bin/check-neutrality.sh --suggest-denylist` output) and merge a curated personal-domain term set into `.neutrality-denylist.txt`. Ships today with Kahneman category only (10 lines); infrastructure (gate + suggest + candidate) is complete. Remaining work is human curation, not engineering.
**Origin:** Phase 7 scope-deferred per user (reaffirmed 2026-04-16 during human-UAT walkthrough). Tracked in REQUIREMENTS.md as NEUT-08 "Deferred (partial)"; evidence in `.planning/phases/07-neutral-template-foundation/07-VERIFICATION.md` `human_verification_deferred` block.

### Phase 999.3: Template Placeholder System for Published Surfaces (BACKLOG)

**Goal:** [Captured for future planning] Extend the `{{...}}` placeholder pattern — currently only on `AGENTS.template.md` (4 placeholders: `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`, `{{DEFAULT_PRIVACY}}`, `{{PRIMARY_DOMAIN}}`) — to other template-shaped surfaces (`README.md` title, and potentially `PRIVACY.md`, `docs/quickstart.md`, `docs/guided-setup.md`). Have `bin/init-wizard.sh` substitute them at adoption time. Enforce the placeholder set with a test analogous to `tests/phase-07/test_agents_template_placeholders.sh`.
**Origin:** Surfaced 2026-04-16 while resolving a `test_readme.sh` regression from the voice-pass commit `ed6f7e0`. Option C in the README placeholder tradeoff analysis — deferred today because the existing `<org>/<repo>` prose convention works and expanding the placeholder set touches init-wizard + schema + tests in concert (not a one-line fix). Short-term fix: Option A (revert README title to `<org>/<repo>`).
**Relevant prior art:** Phase 8 WZRD-07 reduced the `AGENTS.template.md` placeholder set from 6 to 4 per D-02 (minimalism). This backlog item moves in the OPPOSITE direction for a different surface — whoever plans this should re-visit that minimalism decision first and justify any expansion against it.
**Scope to scope at planning time:** which published surfaces benefit enough to justify placeholders vs. leaving prose conventions in place.
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.4: v1.2 Schema Architecture — Progressive Disclosure Refactor (BACKLOG)

**Goal:** [Captured for future planning] Reduce `AGENTS.md` / `CLAUDE.md` from ~1,412 lines (post-09.1) to a 500–700 line core by extracting procedural workflows, schema reference tables, and validation checklists into plain markdown under `schema/reference/*.md` and `schema/workflows/*.md`. Preserve markdown-authoritative architecture (Claude-optimized, harness-portable). Add optional `.claude/skills/` thin-wrapper overlay as a last step. Proposed as a standalone v1.2 milestone titled "Schema Architecture," not a v1.1 phase.

**Origin:** Surfaced 2026-04-16 during a design thread reviewing the project against Anthropic Agent Skills best-practices. Diagnosis: Phase 09.1 extracted the easy ~21% (worked examples + appendices); remaining ~79% is workflow procedures and schema reference material. Spec loaded every turn, violating the project's own §7 progressive disclosure principle (applied to wiki pages but not to the spec itself).

**Advisor-corrected direction:** Markdown-first, not Claude-skills-first. Two independent advisors rejected a `.claude/skills/`-centric extraction as vendor coupling. Adopted framing: *Claude-optimized, markdown-authoritative, future-harness-friendly.* Core target raised from an initially-proposed 180 lines to 500–700 lines to preserve always-loaded safety invariants (privacy defaults, provenance requirement, MUST NOT list, write-back mandatory, structured-op vocabulary).

**Proposed phase sequence within v1.2:**
- **Phase A — Reference extraction** (low-risk): §4, §5, §6, §7, §8, §13 → `schema/reference/*.md`; §14, §15 → `docs/reference/*.md`; §16 deleted.
- **Phase B — Workflow extraction** (medium-risk): §9, §10, §11.1–11.4 → `schema/workflows/*.md`; §12 structured-op details → `schema/reference/log-format.md`.
- **Phase C — Claude skills overlay** (optional): thin `.claude/skills/` wrappers pointing to `schema/workflows/*.md`; skill body is one paragraph (router pattern). Consider `disable-model-invocation: true` for explicit triggering.

**Acceptable alternative:** Narrow Phase 09.2 doing only Phase A under v1.1 (captures ~50–60% of the reduction at low risk), deferring B + C to v1.2.

**Constraints to preserve:** `AGENTS.md` ↔ `CLAUDE.md` byte-equality via `.githooks/pre-commit`; `bin/init-wizard.sh` rendering pipeline; CI gates (lint / privacy-leak / strict / neutrality / setup-parity); `local_only` fail-closed semantics; `bin/lint.sh` / `bin/validate-op.sh` / `bin/check-privacy.sh` enforcement unchanged (they operate on content, not file boundaries).

**Open questions for `/gsd-discuss-phase`:** milestone vs. single phase; exact core line target within 500–700 range; include Phase C in v1.2 or defer to v1.3; split §6 provenance/decay at extraction time or follow-up; differentiation between `docs/reference/` (end-user) and `schema/reference/` (agent-authoritative); extension of `bin/sync-claude.sh` to the full `schema/` tree; wizard behavior for the extracted tree; evolution of AGENTS.md's "sole authoritative specification" framing.

**Detailed design notes:** see `.planning/phases/999.4-v1-2-schema-architecture-progressive-disclosure-refactor/CONTEXT-NOTES.md` — comprehensive thread capture including extraction table (section → target file), best-practice recommendations beyond extraction, constraints checklist, research lineage, and draft exit criteria.

**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.5: External Source Drift Detection (BACKLOG)

**Goal:** [Captured for future planning] Extend drift detection from local source-file hash changes to URL-backed sources, marking affected source summaries `stale` when upstream content changes.
**Origin:** Surfaced 2026-04-24 during roadmap review. Valuable once the wiki contains more live web-backed sources, but lower leverage than local write gating (Phase 12.2), boundary clarification (Phase 12), and claim faithfulness audit (Phase 13).
**Non-goals:**
- No broad web-ingestion system
- No automatic re-compilation by default
- No mandatory network dependency for core workflows
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.6: Observed GTD Review Patterns (BACKLOG)

**Goal:** [Captured for future planning] Document GTD-review and agent-backend integration patterns only after they have been used repeatedly in real practice.
**Origin:** Surfaced 2026-04-24 during roadmap review. The system should document what has worked, not what ought to work in theory — this prevents speculative template-kit documentation.

**Trigger to promote:**
- Compendium has been used in a GTD review loop for at least 2 months
- At least 3 Dataview queries or review views are actually re-run in practice
- At least 2–3 review behaviors have proven durable enough to describe as patterns rather than experiments

**Scope when promoted:**
- Capture observed review patterns
- Distinguish durable patterns from one-off experiments
- Document how compendium complements task/working-memory systems in practice

**Non-goals:**
- No task-manager features
- No premature dashboards marketed as canonical
- No GTD-specific filesystem/schema expansion without separate justification

**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.7: requirements-sync Strict-Mode Completion Check (DELIVERED via quick task 260501-g5n on 2026-05-01)

**Status:** Delivered 2026-05-01 via `/gsd-quick` (quick task `260501-g5n` at `.planning/quick/260501-g5n-requirements-sync-strict-mode-completion/`). Promoted directly from backlog without a standalone phase since the work was scope-trivial (one CLI flag + 4 tests). `bin/requirements-sync.sh` now accepts `--require-complete`, which exits 2 when any in-scope REQ-ID has status != Complete in REQUIREMENTS.md. Composes with `--phase N` for phase-scope closure. Phase 13.2 closure can now consume `--require-complete` instead of relying on `--strict` alone (which only detects drift, not incompleteness).

**Goal:** [Captured for future planning — historical] Extend `bin/requirements-sync.sh --strict` so it fails when active requirements are still `Pending` at phase/milestone closure, not just when REQUIREMENTS.md and VERIFICATION.md drift.
**Origin:** Surfaced 2026-05-01 while reconciling Phase 12.1 (NEUT-08 promotion). Current strict mode passes trivially for any active-but-unstarted phase: `requirements-sync --phase 12.1 --strict` reports "0 drift / NEUT-08 Pending / not found / ok" and exits 0. This means closure gates that lean only on `requirements-sync --strict` cannot detect incomplete work — they can only detect *inconsistent* work. Phase 12.1's success criterion now requires a verification artifact in addition to the drift check; longer term the script itself should encode a closure-mode check.
**Trigger to promote:**
- Multiple phases approaching closure want a single mechanical "all required REQ-IDs Complete" gate, OR
- The Phase 13.2 closure-verification gate authoring exposes the same gap and benefits from a shared primitive.
**Scope when promoted:**
- New flag (e.g., `--require-complete` or `--mode closure`) that fails when any in-scope REQ-ID has `Pending` status in REQUIREMENTS.md
- Composes with `--phase N` for phase-scope closure and `--milestone X` (if added) for milestone-scope closure
- Preserves backward compatibility: default `--strict` semantics (drift-only) unchanged
**Non-goals:**
- No automatic status flipping
- No replacement of human-authored verification artifacts
- No coupling to a specific milestone's closure script
**Requirements:** TBD
**Plans:** 0 plans

Plans:
- [ ] TBD (promote with /gsd-review-backlog when ready)

### Explicitly Deferred

The following are intentionally deferred until real usage demands them, captured here so the roadmap does not drift into "compendium as everything":

- **Tier 2–4 scaling work** (`split index`, `incremental lint`, SQLite metadata) — see AGENTS.md §14 scaling tiers; only promote when observed signals warrant it.
- **Multi-agent merge UX beyond current git/PR discipline** — `CONTRIBUTING.md` + `docs/reference/ci.md` cover the current Phase 9 contract.
- **Canonical GTD review dashboards or workflow-specific Dataview surfaces** — review surfaces emerge from observed practice (see Phase 999.6), not speculative design.
- **Hotkey bundles / editor-personalization packs** — out of scope for the shipped starter; users personalize their own Obsidian config.
- **Task, reminder, calendar, inbox, or waiting-for engine features inside compendium** — excluded by the Phase 12 system boundary.
- **High-frequency event / Slack / ticket / operational data ingestion** — excluded by the Phase 12 system boundary.

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1. Schema, Structure & Conventions | v1.0 | 3/3 | Complete | 2026-04-09 |
| 2. Page Types, Examples & Navigation | v1.0 | 3/3 | Complete | 2026-04-10 |
| 3. Ingestion & Provenance Pipeline | v1.0 | 5/5 | Complete | 2026-04-11 |
| 4. Query & Structured Operations | v1.0 | 6/6 | Complete | 2026-04-13 |
| 5. Lint & Quality | v1.0 | 4/4 | Complete | 2026-04-14 |
| 6. Reflection & Drift Detection | v1.0 | 3/3 | Complete | 2026-04-15 |
| 7. Neutral Template Foundation | v1.1 | 5/5 | Complete | 2026-04-15 |
| 8. Two-Track Setup (Wizard + Manual) | v1.1 | 5/5 | Complete | 2026-04-16 |
| 9. Collaborative PR Workflow + CI Lint Gate | v1.1 | 6/6 | Complete | 2026-04-16 |
| 10. Brownfield Scan + Bootstrap | v1.1 | 6/6 | Complete    | 2026-04-18 |
| 11. Brownfield Suggest + Verify | v1.1 | 5/5 | Complete    | 2026-04-20 |
| 12. Complementary Systems Boundary + GTD Alignment | v1.1 | 3/4 | In Progress|  |
| 12.1. NEUT-08 Personal-Term Denylist Curation | v1.1 | 0/0 | Not started | - |
| 12.2. Local Wiki Write Gate | v1.1 | 0/0 | Not started | - |
| 13. Claim Faithfulness Audit | v1.1 | 0/0 | Not started | - |
| 13.1. Docs Finalization + Obsidian Starter | v1.1 | 0/0 | Not started | - |
| 13.2. v1.1 Closure Verification Gate | v1.1 | 0/0 | Not started | - |

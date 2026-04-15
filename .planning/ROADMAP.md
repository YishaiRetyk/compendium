# Roadmap: LLM Wiki Compiler

## Milestones

- ✅ **v1.0 LLM Wiki Compiler MVP** — Phases 1–6 (shipped 2026-04-15) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Shareability** — Phases 7–12 (started 2026-04-15)

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

### 🚧 v1.1 Shareability (Phases 7–12)

- [ ] **Phase 7: Neutral Template Foundation** — Public orphan-branch template, Kahneman → `examples/`, neutrality CI gate, `requirements-sync` mechanical check.
- [ ] **Phase 8: Two-Track Setup (Wizard + Manual)** — `bin/init-wizard.sh` plus byte-equivalent manual track, co-shipped to prevent drift.
- [ ] **Phase 9: Collaborative PR Workflow + CI Lint Gate** — Git-based PR workflow, `log.md` contributor field, `bin/lint.sh --ci --format json` severity policy, privacy-leak guard.
- [ ] **Phase 10: Brownfield Scan + Bootstrap** — `bin/brownfield.sh scan|bootstrap` with `bootstrap_stage` sentinel, ruamel.yaml round-trip, byte-exact fixture tests.
- [ ] **Phase 11: Brownfield Suggest + Verify** — Four staged migration script classes, `verify` wrapper over lint.
- [ ] **Phase 12: Docs Finalization + v1.0 Debt Verification Gate** — `/docs/reference/` fill-out, Obsidian render check, Codex agent-parity, write-back scenario re-run.

## Phase Details

### Phase 7: Neutral Template Foundation
**Goal**: A stranger can clone the public template repo and get a Kahneman-free, license-clean, traceability-enforced starter — and the creator's private vault history never reaches the public release.
**Depends on**: Nothing (first v1.1 phase)
**Requirements**: TMPL-01, TMPL-02, TMPL-03, TMPL-04, TMPL-05, TMPL-06, TMPL-07, TMPL-08, TMPL-09, TMPL-10, TMPL-11, NEUT-01, NEUT-02, NEUT-03, NEUT-04, NEUT-05, NEUT-06, NEUT-07, NEUT-08, DEBT-03
**Success Criteria** (what must be TRUE):
  1. User visits the public GitHub repo and sees a "Use this template" button; the cloned repo contains `README.md`, `LICENSE`, four-track `/docs/` skeleton, empty `wiki/` (only `index.md`/`log.md` skeletons), `PRIVACY.md`, and `CLAUDE.md` alongside `AGENTS.md`. The public control-plane surfaces — `AGENTS.md`, `CLAUDE.md`, `README.md`, `PRIVACY.md`, `/docs/**`, `.github/**`, `wiki/**`, `bin/**` — contain zero Kahneman or personal-vault strings. Kahneman content remains intact under `examples/kahneman/**`, which is the sole permitted home for it.
  2. User runs a fresh `git log` on the public repo and finds only the v1.1 release commit — no v1.0 personal-knowledge history is reachable (orphan-branch release runbook documented and executed).
  3. User opens `examples/kahneman/` and finds the full 7-page cluster preserved with internal wikilinks intact and a README explaining it is a reference example; `bin/lint.sh` does not warn on it because `EXCLUDE_DIRS`/`example: true` are honored.
  4. A PR that reintroduces Kahneman terminology into `AGENTS.md`, or any personal-vault denylist term into public paths, fails CI via the neutrality + denylist grep gate.
  5. User runs `bin/requirements-sync.sh` and sees a mechanical diff between `VERIFICATION.md` truths and `REQUIREMENTS.md` checkbox status; any drift is flagged before merge.
**Plans:** 5 plans
Plans:
- [x] 07-01-PLAN.md — DEBT-03 requirements-sync.sh + Wave 0 test harness
- [ ] 07-02-PLAN.md — Relocate Kahneman cluster to examples/, shrink wiki to skeleton, extend lint EXCLUDE_DIRS, commit NEUT-07 decision record
- [ ] 07-03-PLAN.md — Neutralize AGENTS.md + produce schema/AGENTS.template.md + CLAUDE.md byte-dup + pre-commit hook
- [ ] 07-04-PLAN.md — Top-level scaffolding (README, LICENSE, PRIVACY, .gitignore) + docs/ four-track skeleton + release runbook
- [ ] 07-05-PLAN.md — bin/check-neutrality.sh + human-reviewed denylist + bin/release.sh + neutrality CI workflow

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
**Plans**: TBD
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
**Plans**: TBD

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
**Plans**: TBD

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
**Plans**: TBD

### Phase 12: Docs Finalization + v1.0 Debt Verification Gate
**Goal**: All `/docs/reference/` material is filled out against the now-stable v1.1 feature surface, and every deferred v1.0 verification (Obsidian render, multi-agent parity, write-back scenario) is executed end-to-end before v1.1 ships.
**Depends on**: Phases 7–11 (all feature surfaces stable and documented).
**Requirements**: DEBT-01, DEBT-02, DEBT-04
**Success Criteria** (what must be TRUE):
  1. User opens the generated wiki (both fresh-starter and post-bootstrap fixtures) in Obsidian and confirms that wikilinks resolve, Dataview queries render with expected row counts against `examples/dataview-fixtures/`, and graph view is not contaminated by `examples/` — closing v1.0's deferred Phase 4 verification.
  2. User runs the canonical v1.0 ingest scenario end-to-end against the Kahneman example cluster under a second agent (Codex or other non-Claude), diffs against a golden reference, and documents the findings plus agent-parity tolerance in `docs/reference/agent-parity.md` — closing v1.0's untested Codex path.
  3. User executes the Phase 4 genuine write-back query scenario (the one that produced NO-WRITE-BACK in the v1.0 re-run) end-to-end; the query produces synthesized claims that are compiled back into the wiki with correct provenance and no drift.
  4. Every `/docs/reference/` file (`schema-tour.md`, `brownfield.md`, `privacy-model.md`, `ci.md`, `examples.md`, plus `agent-parity.md` and any Dataview/merge-conflict reference) is filled out with accurate descriptions of the shipped v1.1 features.
  5. Final run of `bin/requirements-sync.sh` across all v1.1 phases shows zero drift between VERIFICATION.md truths and REQUIREMENTS.md checkboxes before milestone closure.
**Plans**: TBD

## Backlog

### Phase 999.1: Brownfield Vault Initialization (SUPERSEDED — absorbed into v1.1 Phases 10–11)

**Status:** Superseded 2026-04-15. The backlog goal — scan/bootstrap/suggest/verify workflow for existing Obsidian vaults — is fully captured by v1.1 Phases 10 (Scan + Bootstrap) and 11 (Suggest + Verify) under REQ-IDs BRWN-01..21. This entry is retained for historical traceability only; do not plan new work against it.

**Supersedes:** promoted backlog → v1.1 Phases 10–11
**Original goal:** Workflow to scan an existing Obsidian vault with non-conforming pages and bring them into compliance: schema inference, bulk frontmatter injection, provenance bootstrapping, index auto-generation, template application, and conformance linting with auto-fix.

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1. Schema, Structure & Conventions | v1.0 | 3/3 | Complete | 2026-04-09 |
| 2. Page Types, Examples & Navigation | v1.0 | 3/3 | Complete | 2026-04-10 |
| 3. Ingestion & Provenance Pipeline | v1.0 | 5/5 | Complete | 2026-04-11 |
| 4. Query & Structured Operations | v1.0 | 6/6 | Complete | 2026-04-13 |
| 5. Lint & Quality | v1.0 | 4/4 | Complete | 2026-04-14 |
| 6. Reflection & Drift Detection | v1.0 | 3/3 | Complete | 2026-04-15 |
| 7. Neutral Template Foundation | v1.1 | 0/5 | Not started | - |
| 8. Two-Track Setup (Wizard + Manual) | v1.1 | 0/0 | Not started | - |
| 9. Collaborative PR Workflow + CI Lint Gate | v1.1 | 0/0 | Not started | - |
| 10. Brownfield Scan + Bootstrap | v1.1 | 0/0 | Not started | - |
| 11. Brownfield Suggest + Verify | v1.1 | 0/0 | Not started | - |
| 12. Docs Finalization + v1.0 Debt Verification Gate | v1.1 | 0/0 | Not started | - |

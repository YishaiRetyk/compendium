---
phase: 7
slug: neutral-template-foundation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-15
updated: 2026-04-16
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test scripts (`tests/phase-07/*.sh`) + CI workflow (`.github/workflows/neutrality.yml`) |
| **Config file** | none — scripts self-contained; uses python3 (PyYAML for lint) |
| **Quick run command** | `bash tests/phase-07/run.sh` |
| **Full suite command** | `bash tests/phase-07/run.sh && bash bin/check-neutrality.sh && bash bin/sync-claude.sh --check && bash bin/requirements-sync.sh --phase 7` |
| **Estimated runtime** | ~30 seconds |
| **Aggregator output** | `PHASE 07 TESTS: 22/22` |

---

## Sampling Rate

- **After every task commit:** Run the test that targets the changed surface (e.g., `bash tests/phase-07/test_kahneman_moved.sh`).
- **After every plan wave:** `bash tests/phase-07/run.sh` (full phase suite).
- **Before `/gsd:verify-work`:** Full suite + manual orphan-branch dry-run pass.
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

| REQ-ID | Plan | Wave | Description | Test File | Automated Command | Status |
|--------|------|------|-------------|-----------|-------------------|--------|
| DEBT-03 | 07-01 | 1 | requirements-sync mechanical traceability | `tests/phase-07/test_requirements_sync.sh` | `bash tests/phase-07/test_requirements_sync.sh` | COVERED |
| NEUT-01 | 07-02 | 2 | Kahneman cluster relocated to `examples/kahneman/` | `tests/phase-07/test_kahneman_moved.sh` | `bash tests/phase-07/test_kahneman_moved.sh` | COVERED |
| NEUT-04 | 07-02 | 2 | `bin/lint.sh` honors `examples/` + `example: true` | `tests/phase-07/test_lint_exclude.sh` | `bash tests/phase-07/test_lint_exclude.sh` | COVERED |
| NEUT-05 | 07-02 | 2 | No stale `wiki/.../kahneman/...` paths in public surfaces | `tests/phase-07/test_no_stale_kahneman_paths.sh` + `test_kahneman_readme.sh` | `bash tests/phase-07/test_no_stale_kahneman_paths.sh && bash tests/phase-07/test_kahneman_readme.sh` | COVERED |
| NEUT-07 | 07-02 | 2 | Canonical `type: decision` SUPERSEDE record for Kahneman→examples | `tests/phase-07/test_kahneman_readme.sh` (DR schema assertions) | `bash tests/phase-07/test_kahneman_readme.sh` | COVERED |
| TMPL-05 | 07-02 | 2 | `wiki/` reduced to skeleton (`index.md`, `log.md`, `decisions/`) | `tests/phase-07/test_wiki_skeleton.sh` | `bash tests/phase-07/test_wiki_skeleton.sh` | COVERED |
| NEUT-02 | 07-03 | 3 | AGENTS.md neutralized (zero Kahneman tokens, ≥3 `See:` pointers) | `tests/phase-07/test_agents_neutralized.sh` | `bash tests/phase-07/test_agents_neutralized.sh` | COVERED |
| NEUT-03 | 07-03 | 3 | `schema/AGENTS.template.md` with EXACTLY 4 `{{...}}` wizard placeholders | `tests/phase-07/test_agents_template.sh` + `test_agents_template_placeholders.sh` | `bash tests/phase-07/test_agents_template.sh && bash tests/phase-07/test_agents_template_placeholders.sh` | COVERED |
| TMPL-10 | 07-03 | 3 | CLAUDE.md byte-identical to AGENTS.md; pre-commit hook resyncs on drift | `tests/phase-07/test_sync_claude.sh` + `test_sync_claude_hook_roundtrip.sh` | `bash tests/phase-07/test_sync_claude.sh && bash tests/phase-07/test_sync_claude_hook_roundtrip.sh` | COVERED |
| TMPL-02 | 07-04 | 4 | Top-level README with required sections + `<org>/<repo>` placeholder | `tests/phase-07/test_readme.sh` | `bash tests/phase-07/test_readme.sh` | COVERED |
| TMPL-03 | 07-04 | 4 | MIT LICENSE boilerplate | `tests/phase-07/test_license.sh` | `bash tests/phase-07/test_license.sh` | COVERED |
| TMPL-04 | 07-04 | 4 | docs/ four-track skeleton (Diátaxis mapping) | `tests/phase-07/test_docs_skeleton.sh` | `bash tests/phase-07/test_docs_skeleton.sh` | COVERED |
| TMPL-06 | 07-04 | 4 | Reference stubs marked `Status: stub` (release.md is full runbook) | `tests/phase-07/test_reference_stubs.sh` | `bash tests/phase-07/test_reference_stubs.sh` | COVERED |
| TMPL-07 | 07-04 | 4 | `.gitignore` covers Obsidian / `.brownfield/` / `.planning/` / OS noise | `tests/phase-07/test_gitignore.sh` | `bash tests/phase-07/test_gitignore.sh` | COVERED |
| TMPL-08 | 07-04 | 4 | No Kahneman terms in README/PRIVACY/docs | `tests/phase-07/test_no_kahneman_in_public_docs.sh` | `bash tests/phase-07/test_no_kahneman_in_public_docs.sh` | COVERED |
| TMPL-09 | 07-04 | 4 | PRIVACY.md documenting `local_only` / `cloud_safe` tiers | `tests/phase-07/test_privacy.sh` | `bash tests/phase-07/test_privacy.sh` | COVERED |
| NEUT-06 | 07-05 | 5 | `bin/check-neutrality.sh` denylist gate on public paths (excludes `examples/`) | `tests/phase-07/test_neutrality_gate.sh` + `test_denylist_gate.sh` | `bash tests/phase-07/test_neutrality_gate.sh && bash tests/phase-07/test_denylist_gate.sh` | COVERED |
| NEUT-08 | 07-05 | 5 | CI personal-content denylist (gate infrastructure) | `tests/phase-07/test_neutrality_gate.sh` (`--suggest-denylist` deterministic) | `bash tests/phase-07/test_neutrality_gate.sh` | COVERED (infra); denylist content curation deferred → Manual-Only |
| TMPL-01 | 07-05 | 5 | Public GitHub template repo with "Use this template" button | (GitHub UI — not scriptable from repo) | n/a | MANUAL-ONLY |
| TMPL-11 | 07-05 | 5 | Orphan-branch single-commit publish (mechanics) | `tests/phase-07/test_release_dryrun.sh` + `test_release_allowlist.sh` | `bash tests/phase-07/test_release_dryrun.sh && bash tests/phase-07/test_release_allowlist.sh` | COVERED (mechanics); real-repo push deferred → Manual-Only |

**Coverage:** 18/20 requirements fully automated; 2 (TMPL-01, deferred portions of TMPL-11/NEUT-08) routed to Manual-Only as scope-deferred decisions.

**Sampling continuity check:** No three consecutive tasks lack automated verification. Every plan (07-01 through 07-05) ships at least one automated test on every commit.

---

## Wave 0 Requirements

- [x] `tests/phase-07/run.sh` — phase aggregator iterating `test_*.sh` files
- [x] `bin/requirements-sync.sh` — DEBT-03 mechanical traceability (Wave 1, dependency for all later plans)
- [x] `tests/phase-07/fixtures/requirements-sync/` — clean + drift fixtures
- [x] `tests/phase-07/fixtures/lint-exclude/` — lint EXCLUDE_DIRS + `example: true` fixtures
- [x] `tests/phase-07/fixtures/neutrality/` — clean / leak-kahneman / leak-personal / example-ok fixtures + denylist
- [x] `bin/check-neutrality.sh` with deterministic `--suggest-denylist` (NEUT-06/08 gate)
- [x] `bin/release.sh` with allowlist staging (TMPL-11 mechanics)
- [x] `bin/sync-claude.sh` + `.githooks/pre-commit` + `bin/install-hooks.sh` (TMPL-10 byte-equality enforcement)
- [x] `.github/workflows/neutrality.yml` (CI: pull_request hard gate, push advisory)
- [x] `.neutrality-denylist.txt` populated (Kahneman category — 10 lines; NEUT-08 personal-term curation deferred)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub "Use this template" toggle visible | TMPL-01 | GitHub UI / repo settings — not scriptable from repo | After publishing to real public remote: navigate to Settings → General → Template repository, toggle on; confirm green "Use this template" button on repo home page |
| Orphan-branch real-repo publish produces single-commit history | TMPL-11 (real-repo portion) | Destructive git operation against a real public remote; only dry-run + allowlist staging are automated | Execute `bash bin/release.sh --apply --remote <REAL_REPO_URL>`; clone published repo; assert `git rev-list --all --count` returns exactly `1`; assert `.planning/`, `.brownfield/`, `wiki/{entities,concepts,comparisons,overviews,sources,maintenance}/` absent; assert `examples/kahneman/` + allowlist essentials present |
| Branch protection requires `neutrality` workflow check | TMPL-01 (enforcement portion) | GitHub UI / repo settings — branch protection rule | Settings → Branches → Branch protection rule for `main`: require `neutrality` status check to pass before merge |
| `examples/kahneman/` wikilinks render in Obsidian | NEUT-05 (Obsidian portion) | Obsidian-specific rendering; full Obsidian verification deferred to Phase 12 DEBT-01 | Open vault in Obsidian; click each in-cluster wikilink; confirm resolution |
| PRIVACY.md tone / wording review | TMPL-09 | Legal/policy wording; voice not programmatically verifiable | Human reads and approves |
| README.md "tech-Obsidian-user voice" | TMPL-02 | Voice / tone not programmatically verifiable | Human reads and confirms it pitches accurately to a technical Obsidian user |
| NEUT-08 personal-term denylist curation | NEUT-08 (curation portion) | Hand-review of `.planning/backlog-neutrality-denylist-candidate.txt`; explicit deferred-scope decision per user ("approved — minimal") | Review candidate file; curate final personal-domain term set into `.neutrality-denylist.txt`; commit in follow-up PR |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are routed to Manual-Only with documented rationale
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s (`bash tests/phase-07/run.sh` ≈ 5–10s on this repo)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-04-16 — 22/22 phase 7 tests green; 18/20 REQ-IDs fully automated; 2 REQ-IDs (TMPL-01, deferred portions of TMPL-11/NEUT-08) explicitly routed to Manual-Only as scope-deferred decisions tracked in `07-VERIFICATION.md` `human_verification`.

---

## Validation Audit 2026-04-16

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to Manual-Only | 0 (3 already documented as scope-deferred in VERIFICATION.md) |
| Per-Task Map populated | 20/20 REQ-IDs |
| Test files cross-referenced | 22/22 |
| Aggregator pass rate | 22/22 |

**Audit notes:** VALIDATION.md was a draft template at the start of this audit (Per-Task Map empty, Wave 0 unchecked, sign-off pending). The phase had already shipped with full test coverage per `07-VERIFICATION.md` (verified 2026-04-15). This audit reconciled the validation contract with the as-shipped state: populated the Per-Task Map from the 22 test files, marked Wave 0 requirements complete, expanded Manual-Only with the three scope-deferred items already tracked in `human_verification`, and set `nyquist_compliant: true`. No new tests were generated because no engineering gaps existed.

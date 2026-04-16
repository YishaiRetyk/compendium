---
phase: 9
slug: collaborative-pr-workflow-ci-lint-gate
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
audited: 2026-04-16
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test harness (per Phase 7/8 convention: `tests/phase-NN/run.sh`) |
| **Config file** | none — Plan 01 (Wave 0) installs `tests/phase-09/run.sh` + `tests/phase-09/lib.sh` + 8 fixture repos |
| **Quick run command** | `bash tests/phase-09/run.sh` |
| **Full suite command** | `bash tests/phase-09/run.sh && bash bin/lint.sh --ci --format json wiki/ > /tmp/lint.json && bash bin/check-privacy.sh && bash bin/lint.sh --strict wiki/ || true` |
| **Regression chain** | `bash tests/phase-09/run.sh && bash tests/phase-08/run.sh && bash tests/phase-07/run.sh` |
| **Estimated runtime** | ~30-45 seconds (27 test files, each <2s) |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/phase-09/run.sh`
- **After every plan wave:** Run full suite (harness + lint + privacy guard + strict)
- **Before `/gsd:verify-work`:** Full suite must be green; regression chain (Phase 07, 08) must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Plan | Task | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01 | T1 run.sh + lib.sh | 0 | CI-06, CI-07, COLAB-04 | harness | `bash tests/phase-09/run.sh \| tail -1 \| grep -q "PHASE 09 TESTS:"` | ✅ exists | ✅ green |
| 09-01 | T2 8 fixture dirs | 0 | CI-06, CI-07, COLAB-04 | unit | `test -d tests/phase-09/fixtures/strict-missing-dr && test -d tests/phase-09/fixtures/privacy-leak-public && (6 more)` | ✅ 8/8 exist | ✅ green |
| 09-02 | T1 --version + --require-version | 1 | CI-08 | unit | `bash tests/phase-09/test_lint_version.sh && bash tests/phase-09/test_lint_require_version.sh` | ✅ exists | ✅ green |
| 09-02 | T2 --format json + --ci + --skip-category | 1 | CI-02, CI-03, CI-04 | unit | `bash tests/phase-09/test_lint_format_json.sh && bash tests/phase-09/test_lint_ci_mode.sh && bash tests/phase-09/test_lint_skip_category.sh` | ✅ exists | ✅ green |
| 09-03 | T1 --strict + escape-hatch | 2 | CI-06 | unit+integration | `bash tests/phase-09/test_lint_strict_dr_match.sh && bash tests/phase-09/test_lint_strict_new_page.sh && bash tests/phase-09/test_lint_strict_escape_hatch.sh` | ✅ exists | ✅ green |
| 09-03 | T2 --count-skips + contributor | 2 | COLAB-08 | unit+integration | `bash tests/phase-09/test_lint_count_skips.sh && bash tests/phase-09/test_lint_contributor_check.sh` | ✅ exists | ✅ green |
| 09-04 | T1 bin/check-privacy.sh + 3 tests | 1 | CI-07 | unit+integration | `bash tests/phase-09/test_check_privacy_clean.sh && bash tests/phase-09/test_check_privacy_leak.sh && bash tests/phase-09/test_check_privacy_wiki_ok.sh` | ✅ exists | ✅ green |
| 09-04 | T2 bin/ingest.sh --contributor + .git-author-map.txt | 1 | COLAB-04 | unit+integration | `bash tests/phase-09/test_ingest_single_author.sh && bash tests/phase-09/test_ingest_auto_detect.sh && bash tests/phase-09/test_ingest_auto_detect_miss.sh && bash tests/phase-09/test_ingest_contributor_explicit.sh && bash tests/phase-09/test_author_map_seed.sh` | ✅ exists | ✅ green |
| 09-04 | T3 bin/search.sh --contributor | 1 | COLAB-07 | unit | `bash tests/phase-09/test_search_contributor.sh` | ✅ exists | ✅ green |
| 09-05 | T1 lint.yml + annotation shim | 3 | CI-01, CI-05 | unit | `bash tests/phase-09/test_lint_workflow.sh && bash tests/phase-09/test_annotation_shim.sh` | ✅ exists | ✅ green |
| 09-05 | T2 PR template | 3 | COLAB-02 | unit | `bash tests/phase-09/test_pr_template.sh` | ✅ exists | ✅ green |
| 09-05 | T3 AGENTS.md amendments + CLAUDE.md sync | 3 | COLAB-03 | unit | `bash tests/phase-09/test_agents_section_11_1.sh && bash tests/phase-09/test_agents_section_11_3.sh && bash tests/phase-09/test_agents_section_12.sh && bash bin/sync-claude.sh --check` | ✅ exists | ✅ green |
| 09-06 | T1 CONTRIBUTING.md | 4 | COLAB-01, COLAB-05, COLAB-06 | unit | `bash tests/phase-09/test_contributing_md.sh` | ✅ exists | ✅ green |
| 09-06 | T2 ci.md populate + cross-links | 4 | CI-09 | unit | `bash tests/phase-09/test_ci_docs.sh && bash tests/phase-09/test_docs_cross_links.sh` | ✅ exists | ✅ green |

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements (Plan 09-01)

- [x] `tests/phase-09/run.sh` — aggregator (copy + rename from `tests/phase-08/run.sh`, summary line `PHASE 09 TESTS: N/M`)
- [x] `tests/phase-09/lib.sh` — shared helpers: `make_fixture_repo`, `setup_git_author`, `assert_exit_code`, `assert_json_has_finding`, `cleanup_fixture_repo`
- [x] `tests/phase-09/fixtures/strict-missing-dr/` — `[epistemic:: inferred]` claim without matching DR
- [x] `tests/phase-09/fixtures/strict-missing-prov/` — new (status A) concept page with zero `[prov:]` markers
- [x] `tests/phase-09/fixtures/strict-escape-hatch/` — `<!-- lint:expect-inferred id=... reason=... -->` on line immediately above claim
- [x] `tests/phase-09/fixtures/privacy-leak-public/` — `privacy: local_only` in `docs/sample.md` frontmatter
- [x] `tests/phase-09/fixtures/privacy-ok-wiki/` — `privacy: local_only` in `wiki/local.md` (valid per §13)
- [x] `tests/phase-09/fixtures/contributor-single/` — single-author repo scaffold
- [x] `tests/phase-09/fixtures/contributor-multi/` — multi-author scaffold + `.git-author-map.txt` with `alice@example.com -> @alice`
- [x] `tests/phase-09/fixtures/ci-lint-json/` — minimal wiki for severity-remap tests (wiki/index.md skeleton)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Actions annotations render inline on PR | CI-05 | Requires actual PR run against a live GitHub repo. Local harness verifies shim output (`::error file=X,line=Y::` lines) but their rendering as inline PR annotations is GitHub-side behavior. | After merge to the public repo: open a throwaway PR that introduces one `yaml`-severity error. Confirm annotation appears on the offending line in the "Files changed" tab. |
| Branch-protection required-check enforcement | CI-01, CI-06, CI-07 | Operator-side action (Settings → Branches → Branch protection rule). Cannot be verified by bash tests. | On the public repo, add `lint`, `privacy-leak`, `strict` as required status checks alongside existing `neutrality` and `setup-parity`. Confirm a PR with a `lint` failure cannot be merged. |
| GitLab/Gitea/Codeberg CI equivalents render correctly | CI-09 | Documentation only — no runner available for each provider in CI. | Reviewer confirms the GitLab `.gitlab-ci.yml` snippet in `docs/reference/ci.md` matches current GitLab syntax; spot-checks Gitea/Codeberg runner-image notes against current provider docs. |
| `CONTRIBUTING.md` merge-conflict recipes actually resolve a synthesized conflict | COLAB-06 | Requires interactive git session with two concurrent branches. | Create two branches that each add a line to `wiki/log.md`; attempt merge; follow CONTRIBUTING.md recipe; confirm clean merge and `bin/lint.sh` exits 0. |
| `.gitattributes merge=union` opt-in actually union-merges log.md conflicts | COLAB-06 | Requires local `.gitattributes` addition + synthetic conflict; operator opt-in by design. | Same synthetic-conflict setup as above but with `wiki/log.md merge=union` added to local `.gitattributes`; confirm git auto-resolves. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify — every task in 09-01..06 carries a bash-executable verification command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — each plan's tasks all have automated checks
- [x] Wave 0 covers all MISSING references — 09-01 creates the harness + all 8 fixture repos Plans 02–06 reference
- [x] No watch-mode flags — all tests are one-shot bash commands
- [x] Feedback latency < 45s — full phase-09 suite runs in <30s; with Phase 7/8 regression ≤45s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-16

---

## Validation Audit 2026-04-16

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Tests passing | 28/28 |

Audit method: `bash tests/phase-09/run.sh` → `PHASE 09 TESTS: 28/28`; `bash bin/sync-claude.sh --check` → OK; 8/8 fixture dirs present under `tests/phase-09/fixtures/`. Every row in the Per-Task Verification Map resolves to an existing test file that runs green. No gaps to fill.

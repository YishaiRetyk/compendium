---
phase: 09-collaborative-pr-workflow-ci-lint-gate
verified: 2026-04-16T00:00:00Z
status: passed
score: 5/5 success criteria verified
---

# Phase 9: Collaborative PR Workflow + CI Lint Gate Verification Report

**Phase Goal:** A contributor can fork the template, ingest on a branch, open a PR, and have lint + privacy + attribution gates run automatically — with severity policies that distinguish structural errors from judgment-shaped findings.

**Verified:** 2026-04-16
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Success Criteria from ROADMAP.md)

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | `.github/workflows/lint.yml` runs `bin/lint.sh --ci --format json` on `ubuntu-latest`; structural findings block merge, stale/gap/contradiction surface as warnings; JSON output converted to inline GitHub annotations | VERIFIED | `/home/yishai/Documents/life/.github/workflows/lint.yml` lines 32-52 define `lint` job on `ubuntu-latest`, invokes `bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json`, then `.github/scripts/json-to-annotations.py /tmp/lint.json`. Severity remap in `bin/lint.sh` line 309 (`contributor -> warning`) and documented in AGENTS.md §11.3 line 1357 |
| 2 | `bin/ingest.sh --contributor <handle>` with auto-detect from git config on multi-author repos, omitted on single-author | VERIFIED | `bin/ingest.sh` lines 19, 30-32, 73-75, 98-142, 180. Flag present. Auto-detect: reads `.git-author-map.txt`; single-author detection via `git log --all --format='%ae' \| sort -u \| wc -l == 1`. `contributor::` is Dataview inline body field per AGENTS.md §12 (lines 1557-1581) |
| 3 | A PR introducing `privacy: local_only` into a public path fails the privacy-leak guard; `local_only` in `wiki/**` passes cleanly | VERIFIED | `bin/check-privacy.sh` exists and executable. `PUBLIC_PATHS=(examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github)` at line 71. `wiki/**` explicitly excluded (line 33). Exit code 2 on leak, 0 on clean. Running on this repo exits 0 |
| 4 | `bin/lint.sh --strict` fails on new `[inferred]`/`[tentative]` without matching DR, or new page lacking provenance | VERIFIED | `bin/lint.sh` line 411 Plan 03 strict helpers, line 637 `Run --strict checks`. Tests `test_lint_strict_dr_match.sh` + `test_lint_strict_new_page.sh` + `test_lint_strict_escape_hatch.sh` all PASS |
| 5 | `CONTRIBUTING.md` and `/docs/reference/ci.md` document PR workflow, merge-conflict recipes, version-pinning, GitLab/Gitea/Codeberg equivalents | VERIFIED | `CONTRIBUTING.md` (6904 bytes) covers fork->branch->ingest->lint->PR, 3-tier severity, attribution (COLAB-05 explicit on line 28), merge-conflict recipes for log.md (lines 58-82) and index.md (lines 84-100), `.gitattributes merge=union` opt-in note. `docs/reference/ci.md` (267 lines, 12801 bytes) — severity policy table, JSON schema, privacy guard, `--strict`, escape-hatch markers, `--require-version`, GitLab section (line 183), Gitea Actions (line 228), Codeberg/Forgejo (line 239) |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `bin/lint.sh` | Phase 9 flags present | VERIFIED | `--version`, `--require-version`, `--format json`, `--ci`, `--skip-category`, `--strict`, `--count-skips`, `contributor` category all present. `bin/lint.sh --version` prints `1.1.0`. 75355 bytes, executable |
| `bin/check-privacy.sh` | Standalone script | VERIFIED | Exists, executable (5112 bytes). Exits 0 on clean repo (verified). Scans PUBLIC_PATHS only, excludes wiki/**. Frontmatter-only (D-14) |
| `bin/ingest.sh` | `--contributor` flag with auto-detect | VERIFIED | Flag present at line 180. Auto-detect via `.git-author-map.txt` parse_author_map() (line 103). Single-author omit (AGENTS.md §11.1 lines 1202-1204). `--contributor` appears 4× in `contributor::` references |
| `bin/search.sh` | `--contributor` flag | VERIFIED | Flag at line 135. Filters wiki/log.md by `contributor:: @handle`. 9965 bytes, executable |
| `.git-author-map.txt` | Repo-root file with header | VERIFIED | 602 bytes. Header documents email→@handle mapping format, case-insensitive match, single-author empty-file behavior |
| `.github/workflows/lint.yml` | Three parallel jobs + fetch-depth: 0 on strict | VERIFIED | `lint`, `privacy-leak`, `strict` jobs, all `ubuntu-latest`. Strict uses `fetch-depth: 0` (line 77). Draft-skip condition (line 72). Uses `actions/checkout@v6` + `actions/setup-python@v6` |
| `.github/scripts/json-to-annotations.py` | Converts JSON to GitHub annotations | VERIFIED | 3292 bytes, executable. `error→::error`, `warning→::warning`, `info→::notice`. Severity sort, 10/10/50 caps, dropped-notice. Tested with sample JSON: emits `::error file=test.md,line=1::[yaml] boom` |
| `.github/pull_request_template.md` | 6-section D-29 structure | VERIFIED | 6 `##` headings: Summary, Ingest type, Source attribution, Privacy review, Lint, Expected findings (optional) |
| `AGENTS.md` | §§11.1, 11.3, 12 amendments | VERIFIED | §11.1 contributor:: emission (lines 1202-1204); §11.3 CI mode table (lines 1348, 1357, 1359, 1378); §12 contributor:: Dataview inline field docs (lines 1557-1581) |
| `CLAUDE.md` | Byte-identical to AGENTS.md | VERIFIED | `bash bin/sync-claude.sh --check` → `OK: AGENTS.md == CLAUDE.md` (exit 0) |
| `CONTRIBUTING.md` | D-23-scoped workflow | VERIFIED | 6904 bytes. Fork→branch-per-ingest→lint→PR. Severity tiers. Privacy review. Attribution (git authorship = source of truth). Merge-conflict recipes for log.md + index.md. Escape-hatch marker docs. Links to docs/reference/ci.md 3× |
| `docs/reference/ci.md` | Fully populated (not stub) | VERIFIED | 267 lines, 12801 bytes. Severity policy table, JSON schema, privacy-leak explainer, --strict docs, escape-hatch markers, --require-version, multi-provider (GitHub + GitLab + Gitea + Codeberg) |
| `docs/reference/index.md` | Cross-link to ci.md | VERIFIED | Line 6: `[ci.md](ci.md)`. Line 12: `[../../CONTRIBUTING.md]` |
| `tests/phase-09/run.sh` + `lib.sh` | Test harness + 28 tests | VERIFIED | `run.sh` (1144 bytes), `lib.sh` (4835 bytes) with 4 helpers (make_fixture_repo, setup_git_author, seed_origin_main_ref, assert_json_has_finding). 28 test scripts present |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `.github/workflows/lint.yml` lint job | `bin/lint.sh --ci --format json` | bash step invocation | WIRED | Line 46: `run: bash bin/lint.sh --require-version 1.1.0 --ci --format json > /tmp/lint.json` |
| `.github/workflows/lint.yml` annotation step | `.github/scripts/json-to-annotations.py` | python3 call | WIRED | Line 49: `python3 .github/scripts/json-to-annotations.py /tmp/lint.json` |
| `.github/workflows/lint.yml` privacy-leak job | `bin/check-privacy.sh` | bash step invocation | WIRED | Line 66: `bash bin/check-privacy.sh` |
| `.github/workflows/lint.yml` strict job | `bin/lint.sh --strict` | bash step invocation | WIRED | Line 84: `bash bin/lint.sh --require-version 1.1.0 --strict` with fetch-depth: 0 |
| `bin/ingest.sh` contributor:: emission | `.git-author-map.txt` | parse_author_map() + git config user.email | WIRED | `.git-author-map.txt` found 7×; `git config user.email` found 5×; emit `contributor:: @handle` into log entry |
| `bin/search.sh --contributor` | `wiki/log.md contributor::` fields | grep-based filter | WIRED | Flag at line 135, filters log.md content by @handle pattern |
| `bin/lint.sh contributor check` | `.git-author-map.txt` + git log | reverse lookup + subprocess | WIRED | `contributor_check()` at line 796, reads git log --all --format=%ae (line 788) |
| `bin/lint.sh --strict` | git diff origin/main...HEAD | subprocess.run in python3 block | WIRED | Strict helpers at line 411, fallback WARN at line 433 |
| `CONTRIBUTING.md` | `docs/reference/ci.md` | inline markdown link | WIRED | 3 links to `docs/reference/ci.md` |
| `docs/reference/ci.md` | `bin/lint.sh` + `bin/check-privacy.sh` | CLI documentation | WIRED | 20 references to these binaries |
| `AGENTS.md` §12 | `CLAUDE.md` §12 | `bin/sync-claude.sh` byte-identical | WIRED | sync-claude.sh --check passes (exit 0) |
| `tests/phase-09/test_*.sh` | `tests/phase-09/lib.sh` | `source lib.sh` | WIRED | Every test script sources lib.sh; 4 helpers exported |

Note: gsd-tools `verify key-links` reported some false negatives because the `from` side of several key_links is a conceptual label (e.g., "Plan 09-03 strict-mode tests", "bin/lint.sh --format json output") rather than a literal file path. Manual verification (above) confirms every link is wired in the actual codebase.

### Data-Flow Trace (Level 4)

Not applicable — this phase produces infrastructure (CLI flags, CI workflow, docs), not UI/dynamic-data artifacts. The `.github/workflows/lint.yml` does consume actual data (stdout of bin/lint.sh → JSON file → annotation commands), and this flow is verified under Behavioral Spot-Checks below.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| `bin/lint.sh --version` prints semver | `bash bin/lint.sh --version` | `1.1.0` | PASS |
| `--require-version` enforces minimum | `bash bin/lint.sh --require-version 2.0.0` | Exit 1, stderr with "not satisfied. Running version: 1.1.0" | PASS |
| `--format json` emits valid JSON array | `bash bin/lint.sh --format json \| python3 -c 'json.load'` | `JSON array OK, len= 8` | PASS |
| `bin/check-privacy.sh` on clean repo | `bash bin/check-privacy.sh` | Exit 0 (no output, clean) | PASS |
| `sync-claude.sh --check` AGENTS=CLAUDE | `bash bin/sync-claude.sh --check` | `OK: AGENTS.md == CLAUDE.md` exit 0 | PASS |
| `json-to-annotations.py` converts error finding | Sample JSON input with error severity | `::error file=test.md,line=1::[yaml] boom` exit 0 | PASS |
| Full Phase-9 test suite | `bash tests/phase-09/run.sh` | `PHASE 09 TESTS: 28/28` | PASS |
| PR template section count | `grep -E '^##' .github/pull_request_template.md \| wc -l` | 6 sections (Summary, Ingest type, Source attribution, Privacy review, Lint, Expected findings) | PASS |

### Requirements Coverage

All 17 requirement IDs from ROADMAP Phase 9 are claimed across Plans 01-06 (union verified: no orphans). Each requirement cross-referenced against REQUIREMENTS.md and mapped to implementation evidence below.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| COLAB-01 | 09-06 | Top-level CONTRIBUTING.md | SATISFIED | `/home/yishai/Documents/life/CONTRIBUTING.md` (6904 bytes, 129 lines) |
| COLAB-02 | 09-05 | PR template | SATISFIED | `.github/pull_request_template.md` with 6-section D-29 structure |
| COLAB-03 | 09-05 | log.md `contributor::` schema amended in AGENTS.md §12 | SATISFIED | AGENTS.md §12 lines 1557-1581 |
| COLAB-04 | 09-01, 09-04 | `bin/ingest.sh --contributor` + auto-detect | SATISFIED | `bin/ingest.sh` flag + parse_author_map + single-author short-circuit |
| COLAB-05 | 09-06 | Git commit authorship = attribution source of truth | SATISFIED | `CONTRIBUTING.md` line 28 explicit |
| COLAB-06 | 09-06 | Merge-conflict recipes for index.md + log.md | SATISFIED | `CONTRIBUTING.md` lines 58-100 with opt-in `merge=union` note |
| COLAB-07 | 09-04 | `bin/search.sh --contributor` filter | SATISFIED | `bin/search.sh` line 135, test `test_search_contributor.sh` PASS |
| COLAB-08 | 09-03 | `bin/lint.sh` contributor-handle-in-git-authors warning | SATISFIED | `contributor_check()` at `bin/lint.sh` line 796, severity `warning` |
| CI-01 | 09-05 | `.github/workflows/lint.yml` uses checkout@v6 + setup-python@v6 + ubuntu-latest | SATISFIED | Workflow lines 36-41, 57-62, 73-78 |
| CI-02 | 09-02 | `bin/lint.sh --format json` emits structured findings | SATISFIED | JSON test PASS, 8-finding sample verified |
| CI-03 | 09-02 | `bin/lint.sh --ci` severity remap | SATISFIED | Dispatch table at `bin/lint.sh` line 309, docs in AGENTS.md §11.3 line 1357 |
| CI-04 | 09-02 | `--skip-category drift-external` | SATISFIED | Test `test_lint_skip_category.sh` PASS with 5 assertions including `drift-external` |
| CI-05 | 09-05 | Annotation shim converts JSON to GitHub annotations | SATISFIED | `.github/scripts/json-to-annotations.py` (96 lines); spot-check produces correct `::error` syntax |
| CI-06 | 09-01, 09-03 | `bin/lint.sh --strict` quality ratchet | SATISFIED | Strict helpers at `bin/lint.sh` lines 411, 637; 3 strict tests PASS |
| CI-07 | 09-01, 09-04 | Privacy-leak guard | SATISFIED | `bin/check-privacy.sh` + 3 privacy tests PASS (clean/leak/wiki_ok) |
| CI-08 | 09-02 | `bin/lint.sh --version` | SATISFIED | Prints `1.1.0`, exits 0; `--require-version` enforcement verified |
| CI-09 | 09-06 | `/docs/reference/ci.md` documents GitLab/Gitea/Codeberg | SATISFIED | ci.md lines 183-239 cover all three providers |

No orphaned requirements — every requirement ID mapped to Phase 9 in REQUIREMENTS.md table (lines 200-216) appears in at least one plan's `requirements` frontmatter.

### Anti-Patterns Found

No TODO/FIXME/XXX/HACK/PLACEHOLDER markers in any Phase 9 artifact (bin/check-privacy.sh, bin/lint.sh Phase-9 sections, bin/ingest.sh, bin/search.sh, .github/workflows/lint.yml, json-to-annotations.py, pull_request_template.md, CONTRIBUTING.md, docs/reference/ci.md). No empty-return stubs. No placeholder text.

### Human Verification Required

None. All success criteria are programmatically verifiable through CLI spot-checks and the 28-test harness. The only "human" aspects (PR UI, actual GitHub annotations in browser) are implementation details that the CI runner exercises end-to-end; the shim's output conforms to the documented `::error file=...,line=...::` schema per GitHub Actions docs.

### Gaps Summary

No gaps. All 5 success criteria verified. All 17 requirements satisfied with concrete implementation evidence. All 46 artifacts across 6 plans pass gsd-tools artifact checks (10+6+6+13+5+6 = 46/46). All 28 Phase-9 tests pass. CLAUDE.md byte-equal to AGENTS.md. CI workflow jobs correctly wire to all Phase-9 scripts. Multi-provider CI equivalents documented. Attribution, privacy, and quality-ratchet paths are all in place for a safe multi-contributor template.

---

_Verified: 2026-04-16_
_Verifier: Claude (gsd-verifier)_

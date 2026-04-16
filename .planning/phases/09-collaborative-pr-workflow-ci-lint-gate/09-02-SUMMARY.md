---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 02
subsystem: testing
tags: [lint, ci, json, semver, bash, python3, cli]

requires:
  - phase: 09-01
    provides: tests/phase-09/lib.sh helpers (make_fixture_repo, assert_json_has_finding, cleanup_fixture_repo) and ci-lint-json fixture
provides:
  - LINT_VERSION="1.1.0" bash constant on bin/lint.sh
  - --version flag (prints LINT_VERSION, exit 0)
  - --require-version X.Y.Z flag (minimum-version semantics, semver tuple compare)
  - --format text|json flag (JSON array to stdout, no lint-report.md write)
  - --ci flag (severity remap dispatch table, default-skip drift-external, exit 1 on error)
  - --skip-category <cat> flag (repeatable, supports drift-external logical subcategory)
  - CI_SEVERITY_REMAP python dispatch table with 12 category -> severity mappings
  - matches_skip() helper implementing drift-external EXTERNAL: prefix convention
  - --category (inclusive) / --skip-category (exclusive) precedence = intersect-then-subtract
affects: [09-03, 09-05, 09-06]

tech-stack:
  added: []
  patterns:
    - "Flag-composition pattern: --ci --format json --require-version X.Y.Z --skip-category <cat> compose orthogonally"
    - "EXTERNAL: message prefix convention for tagging external-state drift findings without breaking add_finding() 4-tuple shape"
    - "Semver tuple comparison via inline python3 heredoc (avoids bash string-compare pitfalls)"
    - "Category precedence: inclusive filter narrows first, then skip subtracts (set math)"

key-files:
  created:
    - tests/phase-09/test_lint_version.sh
    - tests/phase-09/test_lint_require_version.sh
    - tests/phase-09/test_lint_format_json.sh
    - tests/phase-09/test_lint_ci_mode.sh
    - tests/phase-09/test_lint_skip_category.sh
  modified:
    - bin/lint.sh (+161 lines: LINT_VERSION constant, 5 new flag cases, version-pin check, CI_SEVERITY_REMAP table, matches_skip helper, filter/remap/emit branch, CI exit policy, EXTERNAL: prefix on DRFT-03 findings, usage() docs)

key-decisions:
  - "LINT_VERSION=1.1.0 ships as the Phase-9 v1.1 baseline (v1.0 had no version)"
  - "drift-external is a LOGICAL subcategory, not an add_finding category; EXTERNAL: message prefix tags external-state findings"
  - "JSON line field is OMITTED (not null) when unknown; Plan 02 4-tuple has no line slot so line is always omitted here"
  - "--category narrow first, --skip-category subtract second — documented in usage() + exercised by precedence regression test"
  - "--ci default-skip is drift-external ONLY; plain drift findings (DRFT-01/02, content-hash, index-coverage) still emitted as warnings"
  - "--require-version uses semver tuple comparison (1.10.0 > 1.1.0), not bash string compare"
  - "Non-CI mode preserves v1.0 exit-0-always behavior; CI mode exits 1 iff any post-remap error-severity finding"

patterns-established:
  - "Pattern: Flag-composition — each flag adds orthogonal capability; Plan 03 extends with --strict and --count-skips over the same dispatch path"
  - "Pattern: EXTERNAL: prefix for opt-in skipping — grep-friendly, backward-compat with 4-tuple add_finding(), documented inline + in usage()"
  - "Pattern: LINT_VERSION bump semantics — MAJOR on breaking (removed category, changed severity), MINOR on additions, PATCH on bug fixes; --require-version is a minimum check"

requirements-completed: [CI-02, CI-03, CI-04, CI-08]

duration: 8min
completed: 2026-04-16
---

# Phase 09 Plan 02: Lint Flags (JSON, CI, Version) Summary

**bin/lint.sh v1.1.0 gains --format json, --ci, --skip-category, --version, and --require-version as orthogonal CI-mode primitives that downstream plans compose.**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-04-16T07:40:01Z
- **Completed:** 2026-04-16T07:48:00Z
- **Tasks:** 2 (both TDD, both green first attempt)
- **Files modified:** 1 existing (bin/lint.sh, +161 lines), 5 new tests

## Accomplishments

- `bin/lint.sh --version` prints exactly `1.1.0` and exits 0 (CI-08 primitive)
- `bin/lint.sh --require-version X.Y.Z` implements minimum-version semantics with semver TUPLE comparison (1.10.0 > 1.1.0, NOT string compare); actionable stderr includes running version, required version, and recovery hint
- `bin/lint.sh --format json <wiki>` emits a `[{severity, category, path, message}, ...]` JSON array to stdout; the `line` key is OMITTED (not null) when a finding lacks line info — per the P0 review fix (Codex MEDIUM #3). Does NOT write `wiki/maintenance/lint-report.md` (D-03 contract)
- `bin/lint.sh --ci` applies the CI_SEVERITY_REMAP dispatch table (yaml/orphan/crossref/provenance -> error; stale/gap/contradiction/drift/contributor -> warning; autofix/skip-count -> info) and exits 1 iff any post-remap error-severity finding is present
- `bin/lint.sh --skip-category <cat>` implements a repeatable exclusion filter that supports both plain-category skips AND the logical `drift-external` subcategory, which targets drift findings whose message starts with `EXTERNAL: ` (DRFT-03 Obsidian-vault awareness). Plain `drift` in the skip set drops ALL drift findings regardless of origin
- `--category` / `--skip-category` precedence is documented AND tested: intersect-then-subtract (`final = (category_filter or ALL) - skip_set`). The plan's canonical example `--category stale --skip-category stale` correctly yields zero findings

## Task Commits

Each task was committed atomically:

1. **Task 1: --version + --require-version flags** — `7670ba2` (feat)
   - LINT_VERSION="1.1.0" constant near top of bin/lint.sh
   - --version prints LINT_VERSION, exit 0
   - --require-version uses python3 inline heredoc for semver tuple comparison
   - Actionable stderr on failure: running + required + hint
   - usage() documents both flags
   - 2 TDD test files: test_lint_version.sh, test_lint_require_version.sh

2. **Task 2: --format json + --ci + --skip-category + severity remap + precedence** — `8f08d17` (feat, landed inside a misattributed-title parallel-agent commit due to concurrent `git add` race; content verified green)
   - 3 new flag defaults + parser cases
   - CI default-skip drift-external applied when --ci and no user --skip-category
   - Env vars exported to python3 block
   - CI_SEVERITY_REMAP dispatch table (12 category mappings) + matches_skip() helper with drift-external logic
   - Findings filter pipeline: narrow (via existing category_filter) -> skip -> remap -> emit
   - JSON emitter branch: stdout only, no lint-report.md write (D-03), line key OMITTED when unknown
   - CI exit policy: exit 1 iff any error-severity post-remap finding
   - EXTERNAL: prefix tagged on DRFT-03 Obsidian-awareness findings (both no-.obsidian and non-md-files variants)
   - 3 TDD test files: test_lint_format_json.sh, test_lint_ci_mode.sh, test_lint_skip_category.sh

## Files Created/Modified

- `bin/lint.sh` — Added LINT_VERSION constant, 5 new flags, 2 env vars wired through to python3 block, CI_SEVERITY_REMAP table, matches_skip helper, filter/remap/emit branch with JSON vs text dispatch, CI exit policy, EXTERNAL: prefix on 2 DRFT-03 finding sites, extensive usage() updates documenting precedence and drift-external. ~161 lines added, zero existing behavior removed.
- `tests/phase-09/test_lint_version.sh` — CI-08 single-line assertion on --version output
- `tests/phase-09/test_lint_require_version.sh` — 4 cases: exact-match pass, older-pin pass, newer-pin fail with stderr token validation, semver-tuple ordering (1.10.0 > 1.1.0 is the discriminator vs string compare)
- `tests/phase-09/test_lint_format_json.sh` — JSON shape validation: keys subset check, required keys present, severity enum, line-field-omitted-when-unknown invariant (explicit `'line' not in item` check when integer is required), no lint-report.md write
- `tests/phase-09/test_lint_ci_mode.sh` — 3 cases: dirty wiki + --ci exits 1 with yaml-error finding; same dirty wiki without --ci exits 0; clean wiki + --ci exits 0
- `tests/phase-09/test_lint_skip_category.sh` — 4 cases: --skip-category yaml suppresses yaml; --ci default-skips drift-external (EXTERNAL: prefix); --category narrows; --category X + --skip-category X yields empty (narrow-then-subtract precedence)

## JSON Payload Shape

```json
[
  {
    "severity": "error|warning|info",
    "category": "yaml|orphan|crossref|stale|contradiction|contradiction-sync|gap|provenance|drift|autofix|contributor|skip-count",
    "path": "relative/path.md or red-link:Target or sparse:domain or .obsidian/",
    "message": "Free-form description (may start with EXTERNAL: for external-state drift)",
    "line": 42   // OMITTED (not null) when unknown; integer 1-indexed when known
  }
]
```

**Invariant:** `line` is OMITTED when unknown. Plan 02's 4-tuple `(sev, cat, path, msg)` has no line slot, so `line` is always absent in Plan 02 findings. Plan 03's strict/skip-count findings will carry lines via their own mechanism.

## CI_SEVERITY_REMAP Dispatch Table

```python
CI_SEVERITY_REMAP = {
    'yaml':               'error',
    'orphan':             'error',
    'crossref':           'error',
    'provenance':         'error',
    'stale':              'warning',
    'gap':                'warning',
    'contradiction':      'warning',
    'contradiction-sync': 'warning',
    'drift':              'warning',
    'contributor':        'warning',   # Plan 03 populates
    'autofix':            'info',
    'skip-count':         'info',      # Plan 03 populates
}
```

Plan 03 extends this table in ONE LINE each for new categories (`contributor`, `skip-count` already pre-allocated per D-05).

## drift-external Subcategory Convention

Internal drift findings (DRFT-01, DRFT-02, content-hash-drift, index-coverage) emit with `category='drift'` and no prefix. External-state drift findings (DRFT-03 Obsidian-vault awareness) emit with `category='drift'` and a literal `EXTERNAL: ` token at the start of the message. `matches_skip()` implements:

```python
if cat in skip_set:                                 return True
if 'drift-external' in skip_set and cat == 'drift' \
   and msg.startswith('EXTERNAL: '):                return True
return False
```

Thus `--skip-category drift-external` drops only external drift; `--skip-category drift` drops ALL drift; `--ci` applies `drift-external` as its default skip (unless user passes their own `--skip-category` value).

## --category / --skip-category Precedence

Set math: `final_cats = (category_filter or ALL) - skip_set`.

- `--category yaml` narrows to yaml-only findings (existing v1.0 behavior)
- `--skip-category yaml` drops yaml findings from the narrowed set
- Combined: `--category yaml --skip-category yaml` yields zero findings (narrowed to {yaml}, then subtract {yaml} = empty). Exit 0 (non-ci).
- `--category stale --skip-category yaml` yields stale findings only (yaml was not in narrowed set, so skip is a no-op).

Documented in usage() help with the canonical zero-findings example and exercised by test_lint_skip_category.sh case 4.

## Decisions Made

- LINT_VERSION=1.1.0 is the v1.1 baseline (Phase-9 ship). Bumps: MAJOR on breaking semantic changes (removed category, changed severity policy), MINOR on non-breaking additions (new category in the table), PATCH on bug fixes
- `line` is OMITTED (not null) when unknown per P0 review fix (JSON-idiomatic: consumers can `.get('line')` safely). Rejected alternative: emitting `null` (would require every consumer to special-case null handling)
- `drift-external` handled via EXTERNAL: message-prefix convention rather than a 5-tuple schema change to add_finding(). Rationale: backward-compat with all existing check functions; grep-friendly ("EXTERNAL: " is stable + human-visible); zero risk of accidental false-positive tagging since the prefix is explicit and literal at every call site
- JSON mode does NOT write lint-report.md (D-03). Rationale: CI workflows want pure JSON on stdout; writing a markdown file as a side-effect would mutate the working tree inside containerized CI runs
- CI mode exits 1 iff any post-remap error-severity finding. Rationale: composes cleanly with `set -e` in workflow shells; warnings and info don't gate merges
- Category narrowing is enforced at check-time (existing `should_run()` helper) rather than post-filter. The new post-filter only applies the skip + remap, ensuring we don't run unnecessary checks if `--category` already excludes them

## Deviations from Plan

None — plan executed exactly as written. All P0 review fixes (drift-external convention, category precedence, line-field policy) were already encoded in the plan's must_haves and implemented as specified.

## Issues Encountered

**1. Parallel-agent commit collision:** Task 2's commit was absorbed into a concurrently-running 09-04 agent's commit (`8f08d17 feat(09-04): add --contributor filter to bin/search.sh`) when both agents staged and committed near-simultaneously. The 09-04 commit title misattributes Plan 02 content, but all 161 lines of bin/lint.sh changes + 3 test files are in the tree at HEAD and all 5 plan tests pass green. This is a coordination artifact of parallel execution, not a correctness issue — a future `git log` archaeologist will need to inspect the commit diff rather than title.

## Verification Results

All 5 TDD tests pass:

```
PASS: bin/lint.sh --version -> 1.1.0
PASS: --require-version minimum + semver tuple ordering
PASS: JSON shape valid (line omitted when unknown, not null)
PASS: --format json
PASS: --ci severity remap + exit-code policy
PASS: --skip-category yaml excluded category
PASS: --ci default-skips drift-external (internal drift retained)
PASS: --category filter narrows
PASS: --category/--skip-category precedence (narrow then subtract)
PASS: --skip-category + --ci default skip + precedence
```

Acceptance-criteria greps:

```
PASS: CI_SEVERITY_REMAP present in bin/lint.sh
PASS: FORMAT= default set
PASS: CI_MODE= default set
PASS: SKIP_CATEGORIES= default set
PASS: matches_skip / drift-external implementation present
PASS: EXTERNAL: prefix applied at DRFT-03 emission sites
PASS: LINT_VERSION="1.1.0" anchored at top of script
```

Regression:

```
bash bin/lint.sh --dry-run wiki/     # text mode unchanged, exit 0
bash tests/phase-07/run.sh           # PHASE 07 TESTS: 22/22, exit 0
```

## Self-Check: PASSED

All created files exist:
- `bin/lint.sh` — FOUND (contains CI_SEVERITY_REMAP, matches_skip, LINT_VERSION, EXTERNAL: prefix)
- `tests/phase-09/test_lint_version.sh` — FOUND
- `tests/phase-09/test_lint_require_version.sh` — FOUND
- `tests/phase-09/test_lint_format_json.sh` — FOUND
- `tests/phase-09/test_lint_ci_mode.sh` — FOUND
- `tests/phase-09/test_lint_skip_category.sh` — FOUND

Commits verified:
- `7670ba2` — FOUND (Task 1: --version and --require-version)
- `8f08d17` — FOUND (Task 2: --format json, --ci, --skip-category; misattributed title, content correct)

## Next Phase Readiness

- Plan 05's `.github/workflows/lint.yml` can invoke `bash bin/lint.sh --require-version 1.1.0 --ci --format json > lint.json` and get a deterministic severity-remapped JSON array with exit-1-on-error semantics
- Plan 03 extends the same codepath with `--strict` (ratchet mode) and `--count-skips` (info emission), adding one line each to CI_SEVERITY_REMAP for new categories (`contributor`, `skip-count` already pre-allocated in the dispatch table)
- `drift-external` skip mechanism is extensible: future external-state drift checks (Zotero, web-clipper bundles) need only prefix their message with `EXTERNAL: ` and they will be auto-suppressed under `--ci`
- `--category` / `--skip-category` precedence is set-math and documented; Plan 03's `--strict` flag can compose freely (narrow to strict-only categories via `--category`, or skip strict-only findings via `--skip-category`)

---
*Phase: 09-collaborative-pr-workflow-ci-lint-gate*
*Plan: 02*
*Completed: 2026-04-16*

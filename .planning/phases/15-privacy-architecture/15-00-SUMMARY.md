---
phase: 15-privacy-architecture
plan: 00
subsystem: testing
tags: [bash, privacy, tdd, nyquist, test-scaffold]

# Dependency graph
requires: []
provides:
  - "tests/phase-15/lib.sh: test harness (make_bare_repo, assert_exit_code, write_page, cleanup_fixture_repo)"
  - "13 RED test files under tests/phase-15/ covering all PRIV-01..07 requirements"
  - "Nyquist contract satisfied: every PRIV requirement has a failing automated gate before structural change"
  - "Wave 0 closed all 5 Nyquist gaps (neutrality W1 tripwire, source-tier resolver, generated-frontmatter, lint-required-field, raw-source cloud-safe guard)"
affects:
  - "15-01 (Wave 1 migration: every test GREEN validates the lockstep commit)"
  - "15-02 (Wave 2 enforcement: test_cloud_deny_profile + test_lint_xtier_link turn GREEN)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0-RED-first: all 13 tests fail today, will turn GREEN only after Wave 1/2 structural changes"
    - "resolver-direct-call idiom: python3 - REPO_ROOT <<'PY' ... from privacy_resolve import ... (mirrored from phase-13)"
    - "FAIL-CLOSED guard test: behavioral fixture-repo test asserts guard exits non-zero on non-cloud-safe input"

key-files:
  created:
    - "tests/phase-15/lib.sh"
    - "tests/phase-15/test_layout_migrated.sh"
    - "tests/phase-15/test_schema_13_rewritten.sh"
    - "tests/phase-15/test_privacy_field_stripped.sh"
    - "tests/phase-15/test_priv_resident_reduced.sh"
    - "tests/phase-15/test_decision_record.sh"
    - "tests/phase-15/test_lint_xtier_link.sh"
    - "tests/phase-15/test_check_privacy_rekey.sh"
    - "tests/phase-15/test_cloud_deny_profile.sh"
    - "tests/phase-15/test_neutrality_leak_source_rekey.sh"
    - "tests/phase-15/test_resolver_structural.sh"
    - "tests/phase-15/test_generated_frontmatter_clean.sh"
    - "tests/phase-15/test_lint_required_field_dropped.sh"
    - "tests/phase-15/test_raw_sources_cloud_safe_guard.sh"
  modified: []

key-decisions:
  - "Wave-0-first: scaffold all 13 RED tests before any structural change to give Wave 1 a deterministic GREEN target"
  - "resolver test (case iii) is legitimately RED because current fail-closed resolver returns local_only for wiki-cloud/ paths (correct for old ladder, wrong for new path-prefix collapse)"
  - "check-privacy rekey test scoped to PATH guard (docs/wiki-local/leak.md), not content-equivalence — check-neutrality owns content scanning"
  - "cloud-deny test uses static JSON assertion + fail-direction table check; live headless behavioral surfaces documented as MANUAL comments"
  - "raw-source guard test checks bin/check-sources-cloud-safe.sh as primary candidate; guard home is executor discretion"

patterns-established:
  - "Pattern: phase-15 lib.sh is verbatim copy of phase-13 lib.sh with mktemp prefix bumped to phase15-"
  - "Pattern: all test skeletons use set -euo pipefail + source lib.sh + REPO_ROOT-relative assertions + echo PASS"

requirements-completed: [PRIV-01, PRIV-02, PRIV-03, PRIV-04, PRIV-05, PRIV-06, PRIV-07]

# Metrics
duration: 6min
completed: 2026-06-04
---

# Phase 15 Plan 00: Privacy Architecture Wave 0 Summary

**1 harness + 13 RED test files establishing the Nyquist verification gate for all PRIV-01..07 requirements before any structural migration**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-04T14:04:04Z
- **Completed:** 2026-06-04T14:10:00Z
- **Tasks:** 3
- **Files modified:** 14 (created)

## Accomplishments

- Created `tests/phase-15/lib.sh` as verbatim copy of phase-13 harness with `phase15-` mktemp prefix
- Created 13 RED test files — every PRIV requirement has a failing automated gate before structural change
- Closed 5 Nyquist gaps per cycle-1/cycle-2 review findings: W1 neutrality tripwire, source-tier resolver guard, generated-frontmatter clean, lint-required-field-dropped, FAIL-CLOSED raw-source cloud-safe guard

## Task Commits

1. **Task 1: Harness + 4 grep/yaml RED tests** - `b954dc7` (test)
2. **Task 2: DR, lint cross-tier, check-privacy, cloud-deny RED tests** - `439a1af` (test)
3. **Task 3: 5 review-driven RED tests** - `2de10a2` (test)

## Files Created/Modified

- `tests/phase-15/lib.sh` - Test harness (4 core helpers, phase15- prefix)
- `tests/phase-15/test_layout_migrated.sh` - PRIV-01: wiki-cloud/+wiki-local/maintenance/ existence
- `tests/phase-15/test_schema_13_rewritten.sh` - PRIV-02: §13 asymmetric language + Privacy Decision Table removed
- `tests/phase-15/test_privacy_field_stripped.sh` - PRIV-04: no privacy: key in pages; CLAUDE.md base-field line removed
- `tests/phase-15/test_priv_resident_reduced.sh` - PRIV-07: §13 < 15 lines, pointer phrase, no fail-closed/Three-Level/inheritance
- `tests/phase-15/test_decision_record.sh` - PRIV-06: DR at wiki-cloud/decisions/, trigger_type:schema-update, >= 2 alternatives
- `tests/phase-15/test_lint_xtier_link.sh` - PRIV-05: cloud->local link = linkres error (D-09 check absent RED)
- `tests/phase-15/test_check_privacy_rekey.sh` - PRIV-05: check-privacy structural PATH guard (not frontmatter grep)
- `tests/phase-15/test_cloud_deny_profile.sh` - PRIV-03: settings.cloud.json + fail-direction table in privacy-model.md
- `tests/phase-15/test_neutrality_leak_source_rekey.sh` - PRIV-05 W1 tripwire: neutrality uses wiki-local/ walk, not frontmatter regex
- `tests/phase-15/test_resolver_structural.sh` - PRIV-05 review HIGH #2: source-tier-privacy survives path-prefix collapse
- `tests/phase-15/test_generated_frontmatter_clean.sh` - PRIV-04 review HIGH #4: no privacy: in generated audit/lint templates
- `tests/phase-15/test_lint_required_field_dropped.sh` - PRIV-04 review HIGH #5: privacy removed from BASE_FIELDS+VALID_PRIVACY
- `tests/phase-15/test_raw_sources_cloud_safe_guard.sh` - PRIV-03 cycle-2 HIGH: FAIL-CLOSED raw-source cloud-safe guard

## Decisions Made

- `test_resolver_structural.sh` Case (iii) is correctly RED for the right reason: current fail-closed resolver returns `local_only` for all `None`-frontmatter paths (correct under old ladder, wrong under the new path-prefix collapse where `wiki-cloud/` sources should resolve `cloud_safe`)
- `test_check_privacy_rekey.sh` behavioral fixture uses `docs/wiki-local/leak.md` (the explicit PATH appears under PUBLIC_PATHS) — NOT arbitrary text pasted into `docs/private.md` (that is content-equivalence scanning, belonging to check-neutrality.sh per the plan's MEDIUM correction)
- `test_raw_sources_cloud_safe_guard.sh` uses `bin/check-sources-cloud-safe.sh` as primary guard candidate; Wave-1/2 executor's discretion whether to implement as standalone script, check-privacy.sh flag, or lint drift check

## Deviations from Plan

None — plan executed exactly as written. All 13 tests are RED today. No production code, schema, or page changes were made (git diff --name-only touches only tests/phase-15/).

## Known Stubs

None — this plan creates only test files; no wiki content or functional code.

## Threat Flags

None — test files only; no new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

Files exist:
- tests/phase-15/lib.sh: FOUND
- tests/phase-15/ (all 13 test_*.sh): FOUND

Commits exist:
- b954dc7 (Task 1): FOUND
- 439a1af (Task 2): FOUND
- 2de10a2 (Task 3): FOUND

All 13 tests RED: VERIFIED (full suite output above)
No production code changes: VERIFIED (git diff --name-only shows only tests/phase-15/)

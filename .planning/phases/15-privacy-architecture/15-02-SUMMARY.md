---
phase: 15-privacy-architecture
plan: 02
subsystem: privacy-enforcement
tags: [privacy, enforcement, lint, d-09, cloud-deny-profile, priv-03, priv-05]

# Dependency graph
requires: [15-01]
provides:
  - "D-09 cloud->local linkres check in bin/lint.sh (PRIV-05; LINT_VERSION 1.7.0)"
  - ".claude/settings.cloud.json: cloud deny-profile with Read(./wiki-local/**) deny"
  - "docs/reference/privacy-model.md: complete honest fail-direction table + separate-repo runbook + raw-source rule (already authored in Plan 01)"
  - "tests/phase-15/test_lint_xtier_link.sh: GREEN (D-09 check fires on cloud->local link)"
  - "tests/phase-15/test_cloud_deny_profile.sh: GREEN (deny artifact + docs assertions pass)"
affects:
  - "16 (Reference Extraction: §13 fully asymmetric; cloud->local link enforcement complete)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-root page universe: wiki-local/ walk extends known_ids so cloud->local links resolve to KNOWN targets before D-09 fires (not red-link gaps)"
    - "Tier-SET semantics: page_tier[id] is a set not scalar; dual-tier id emits duplicate-id error + treated local (fail-safe; walk-order-independent)"
    - "Additive linkres check: D-09 fires inside the existing PIPED_LINK_RE loop after tier resolution; reuses mask_markdown + add_finding plumbing"
    - "Honest fail-open labeling: settings.cloud.json labeled convenience/fail-open; separate-repo is the documented fail-closed path (D-12)"
    - ".gitignore exception: !.claude/settings.cloud.json preserves other .claude/ state as ignored while versioning the enforcement artifact"

key-files:
  created:
    - ".claude/settings.cloud.json"
  modified:
    - "bin/lint.sh (LINT_VERSION 1.6.0 -> 1.7.0; D-09 two-root + tier-SET + cloud->local check)"
    - ".gitignore (!.claude/settings.cloud.json exception)"
    - "docs/reference/privacy-model.md (confirmed complete from Plan 01; no net-new changes needed)"

decisions:
  - "page_tier[id] as SET (not scalar): chosen to make duplicate-id semantics deterministic and walk-order-independent (cycle-2 MEDIUM requirement)"
  - "D-09 check as a subcategory within linkres (not a new top-level category): minimal churn, inherits linkres->error remap, satisfies RESEARCH Open Q3/A4"
  - ".gitignore exception rather than force-add: !.claude/settings.cloud.json cleanly un-ignores the enforcement artifact while keeping other .claude/ state ignored"
  - "docs/reference/privacy-model.md already complete from Plan 01 Task 6: all acceptance criteria (fail-open, fail-closed, git show, python, raw-source rule, check-privacy scope, forward-reference) were present -- no new edits needed"

# Metrics
duration: 5min
completed: 2026-06-04
---

# Phase 15 Plan 02: Additive D-09 Enforcement Artifacts Summary

**Net-new D-09 cross-tier link check + cloud deny-profile artifact, both GREEN, on top of Plan 01's already-migrated tree.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-04T15:07:25Z
- **Completed:** 2026-06-04T15:12:49Z
- **Tasks:** 2
- **Files modified:** 3 (bin/lint.sh, .gitignore, .claude/settings.cloud.json)

## Accomplishments

### Task 1: D-09 Cloud->Local Linkres Check (bin/lint.sh)

- **LINT_VERSION bumped:** 1.6.0 → 1.7.0 (additive minor for the new check)
- **Two-root page universe:** added `wiki-local/` walk inside the `should_run('linkres')` block; local page ids are added to `known_ids` so a cloud->local link resolves as KNOWN (not a red-link gap) before D-09 fires
- **`page_tier[id]` as a SET:** `{'cloud'}`, `{'local'}`, or `{'cloud','local'}` — deterministic, walk-order-independent (cycle-2 MEDIUM requirement)
- **Duplicate-ID finding:** same id in both tiers emits a `linkres` error + treated as local for D-09 (fail-safe toward flagging)
- **D-09 check inside piped-link loop:** when the linking file is under `wiki-cloud/` AND the resolved target id's tier-set contains `'local'`, emits `add_finding('error', 'linkres', ...)` with the `cloud->local link forbidden (PRIV-05/D-09)` message
- **Additive:** does not fire on the real wiki-cloud/ tree (0 false positives); the test confirms it fires correctly on a fixture with a genuine cross-tier link
- **Predicates untouched:** `bin/lib/privacy_resolve.py`, `bin/check-neutrality.sh`, `bin/check-privacy.sh`, `bin/audit-claims.sh` — all Plan 01 work confirmed unchanged

### Task 2: Cloud Deny-Profile + Docs Confirmation

- **`.claude/settings.cloud.json` created:** `{ "permissions": { "deny": ["Read(./wiki-local/**)"] } }` — cloud-scoped deny-profile; labeled fail-open/convenience in docs (D-12 honest labeling)
- **`.gitignore` exception added:** `!.claude/settings.cloud.json` un-ignores the enforcement artifact while keeping other `.claude/` state (settings.local.json, locks, worktrees) gitignored
- **`docs/reference/privacy-model.md` confirmed complete:** authored in Plan 01 Task 6; all acceptance criteria (fail-open, fail-closed, git show, python surface, raw-source rule, check-sources-cloud-safe guard, sources-local/ forward-reference, check-privacy path-vs-content scope honesty) already present — no net-new edits needed
- **`bin/release.sh` ALLOWLIST confirmed:** `wiki-local/` excluded by absence (no change needed)
- **Plan-01 predicate gates confirmed still green:** `test_check_privacy_rekey.sh`, `test_neutrality_leak_source_rekey.sh`, and all 33 phase-13 audit suite tests pass over the additive D-09 changes

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | `5afa08f` | feat(15-02): add D-09 cloud->local linkres check + two-root discovery (PRIV-05) |
| 2 | `bf14c14` | feat(15-02): ship cloud deny-profile artifact + confirm docs already complete (PRIV-03) |

## Verification Results

### Wave-2 Phase-15 Tests (both GREEN)
- `test_lint_xtier_link`: PASS (D-09 check fires; lint exits 1 on cloud->local link)
- `test_cloud_deny_profile`: PASS (deny artifact valid + fail-direction table present)

### Full Phase-15 Suite (13/13 GREEN)
All 13 phase-15 tests pass.

### Plan-01 Predicate Gates (no regression)
- `test_check_privacy_rekey`: PASS
- `test_neutrality_leak_source_rekey`: PASS
- Phase-13 audit suite (33/33): all PASS

### Lint Gate
`bash bin/lint.sh wiki-cloud/` → 0 errors, 62 warnings (pre-existing), 0 info — exits 0.
D-09 check does not false-fire on the real migrated tree.

## Deviations from Plan

### Deviation 1: .claude/ gitignore prevented direct `git add`

**Found during:** Task 2 commit
**Issue:** `.claude/` directory is gitignored as "Local agent/tool state". `git add .claude/settings.cloud.json` failed with "ignored by .gitignore".
**Fix (Rule 3 — blocking issue):** Added `!.claude/settings.cloud.json` exception to `.gitignore`; used `git add -f` for the initial staging (future `git add` works without `-f` since the file is now un-ignored).
**Files modified:** `.gitignore`
**Commit:** `bf14c14`

### Deviation 2: docs/reference/privacy-model.md already complete

**Found during:** Task 2 pre-flight
**Issue:** The plan's Task 2 action listed several doc additions to make (4-surface fail-direction table, raw-source rule, etc.), but `docs/reference/privacy-model.md` already contained ALL required content from Plan 01 Task 6 — all acceptance criteria already passed.
**Outcome:** No edits made to the doc; deviation documented as a "Plan 01 exceeded scope" observation. All test assertions pass.

## Known Stubs

None — all enforcement artifacts are complete and functional.

## Threat Flags

None beyond what was planned:
- `.claude/settings.cloud.json` is a new tracked file in the `.claude/` directory (previously fully gitignored); the `!.claude/settings.cloud.json` exception is narrow and does not expose other `.claude/` state

## Self-Check: PASSED

Files exist:
- bin/lint.sh (LINT_VERSION 1.7.0): FOUND
- .claude/settings.cloud.json: FOUND
- docs/reference/privacy-model.md: FOUND
- .gitignore (!.claude/settings.cloud.json): FOUND

Commits exist:
- 5afa08f (D-09 linkres check): FOUND
- bf14c14 (deny-profile artifact): FOUND

All 13 phase-15 tests: GREEN
Both Wave-2 tests (test_lint_xtier_link + test_cloud_deny_profile): GREEN
bin/lint.sh wiki-cloud/ exits 0: VERIFIED
No stray uncommitted lint artifacts: VERIFIED

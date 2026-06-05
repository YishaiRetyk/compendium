---
phase: 16-reference-extraction
plan: "00"
subsystem: bin
tags:
  - neutrality-gate
  - privacy-guard
  - schema
  - security
dependency_graph:
  requires: []
  provides:
    - neutrality-gate-green
    - schema-in-public-paths-check-neutrality
    - schema-in-public-paths-check-privacy
    - basename-path-name-scanning
    - lint-report-exemption-durable
  affects:
    - bin/check-neutrality.sh
    - bin/check-privacy.sh
    - bin/lint.sh
    - wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md
    - wiki-cloud/maintenance/lint-report.md
    - wiki-cloud/log.md
tech_stack:
  added: []
  patterns:
    - PATH_NAME_EXEMPT set for basename path-name denylist scanning
    - neutrality_exempt frontmatter exemption (established pattern, now applied to 3 more files)
    - Durable frontmatter template in lint.sh report generator
key_files:
  created: []
  modified:
    - bin/check-neutrality.sh
    - bin/check-privacy.sh
    - bin/lint.sh
    - wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md
    - wiki-cloud/maintenance/lint-report.md
    - wiki-cloud/log.md
decisions:
  - "All six tasks land in one atomic Wave-0 commit to avoid transient red commits (each edit alone would not clear all three pre-existing wiki-cloud/ content hits)"
  - "PATH_NAME_EXEMPT uses exact relative path (not regex) for the single legitimately-named historical DR — precise exemption prevents future misuse"
  - "Basename scanning uses separator-normalized form (hyphens/underscores -> spaces) so slugified filenames match multi-word denylist terms"
  - "lint.sh template gets neutrality_exempt: true baked in to make lint-report.md exemption durable across all future lint regenerations"
  - "log.md exemption via frontmatter only — body entries are append-only per AGENTS.md §12 and cannot be reworded"
metrics:
  duration: "~15 minutes"
  completed: 2026-06-05
  tasks_completed: 6
  files_modified: 6
---

# Phase 16 Plan 00: Wave-0 Gate-Arming + Neutrality Pre-Clear Summary

Wave-0 gate-arming commit landing `schema` in both PUBLIC_PATHS arrays, basename path-name scanning with a narrow PATH_NAME_EXEMPT, durable lint-report exemption, and three wiki-cloud/ file exemptions so `bash bin/check-neutrality.sh` exits 0 on the committed tree before any extraction commit gates on it.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add `schema` to PUBLIC_PATHS in bin/check-neutrality.sh | 1d3b3e5 | bin/check-neutrality.sh |
| 2 | Add `schema` to PUBLIC_PATHS in bin/check-privacy.sh + help-text | 1d3b3e5 | bin/check-privacy.sh |
| 3 | Add `neutrality_exempt: true` to privacy DR | 1d3b3e5 | wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md |
| 4 | Make lint-report exemption DURABLE in lint.sh template + current file | 1d3b3e5 | bin/lint.sh, wiki-cloud/maintenance/lint-report.md |
| 5 | Add `neutrality_exempt: true` to wiki-cloud/log.md | 1d3b3e5 | wiki-cloud/log.md |
| 6 | Add basename path-name scanning + PATH_NAME_EXEMPT + land Wave-0 commit | 1d3b3e5 | bin/check-neutrality.sh |

## Verification Results

All plan verification checks passed:

- `grep 'schema' bin/check-neutrality.sh | grep 'PUBLIC_PATHS'` — schema present in PUBLIC_PATHS
- `grep -E 'PUBLIC_PATHS=\(.*schema' bin/check-privacy.sh` — schema present in PUBLIC_PATHS
- `grep -q 'PATH_NAME_EXEMPT' bin/check-neutrality.sh` — basename scanning with explicit exemption present
- `grep -q '^neutrality_exempt: true' wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` — privacy DR exempt (hit 1)
- `grep -q 'neutrality_exempt: true' bin/lint.sh` — durable template exemption present
- `grep -q '^neutrality_exempt: true' wiki-cloud/maintenance/lint-report.md` — lint-report.md exempt (hit 2)
- `grep -q '^neutrality_exempt: true' wiki-cloud/log.md` — log.md exempt (hit 3)
- `bash bin/check-neutrality.sh; echo "exit=$?"` prints `exit=0` — THE load-bearing precondition
- `bash bin/check-privacy.sh` exits 0
- `bash tests/phase-15/test_check_privacy_rekey.sh` still passes
- REGENERATION-SAFETY: `bash bin/lint.sh >/dev/null 2>&1; bash bin/check-neutrality.sh` prints `post-lint exit=0`

## Deviations from Plan

None — plan executed exactly as written. All six tasks are in the single Wave-0 commit `1d3b3e5`.

## Known Stubs

None. This plan modifies only `bin/` scripts and wiki control-plane files.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond those explicitly tracked in the plan's threat model.

| Flag | File | Description |
|------|------|-------------|
| (none) | — | All threat mitigations applied as specified in task actions |

## Self-Check: PASSED

- Commit `1d3b3e5` exists: confirmed (git log --oneline -1)
- Files modified: bin/check-neutrality.sh, bin/check-privacy.sh, bin/lint.sh, wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md, wiki-cloud/maintenance/lint-report.md, wiki-cloud/log.md — all present
- No file deletions in commit
- `bash bin/check-neutrality.sh` exits 0 on committed tree
- Regeneration-safety confirmed: lint.sh run followed by check-neutrality.sh exits 0

---
id: 260415-gzu
mode: quick
description: Flip 9 Pending → Complete in REQUIREMENTS.md (QURY-01, QURY-04, QURY-05, SOPS-01..06)
---

# Plan 260415-gzu: Flip 9 Pending Requirements

## Context

v1.0 milestone audit (`.planning/v1.0-MILESTONE-AUDIT.md`) found 9 requirements marked `Pending` in REQUIREMENTS.md that are substantively satisfied:

- **QURY-01, QURY-04, QURY-05** — verified in Phase 4 VERIFICATION.md truths 1/2/3; listed in 04-04-SUMMARY and 04-06-SUMMARY frontmatter.
- **SOPS-01..05** — verified in Phase 4 VERIFICATION.md truth 4; listed in 04-05-SUMMARY frontmatter.
- **SOPS-06** — verified in Phase 4 VERIFICATION.md truth 4 (`bin/validate-op.sh`, 407 lines, 5 mechanical checks); integration check confirmed wired.

This is bookkeeping cleanup — no code changes.

## Tasks

### Task 1: Flip checkboxes in requirement list

- files: `.planning/REQUIREMENTS.md`
- action: Change `[ ]` → `[x]` for QURY-01, QURY-04, QURY-05, SOPS-01..06 (9 lines).
- verify: `grep -c '^- \[ \] \*\*\(QURY\|SOPS\)' .planning/REQUIREMENTS.md` returns 0.
- done: All 9 target requirements show `[x]`.

### Task 2: Flip traceability status rows

- files: `.planning/REQUIREMENTS.md`
- action: Change `Pending` → `Complete` in traceability table rows for QURY-01, QURY-04, QURY-05, SOPS-01..06 (9 rows).
- verify: `grep -c '| Pending |' .planning/REQUIREMENTS.md` returns 0.
- done: No `Pending` rows remain in the traceability table.

### Task 3: Update footer "Last updated" line

- files: `.planning/REQUIREMENTS.md`
- action: Change the trailing `*Last updated:*` line to reflect 2026-04-15 cleanup with reference to this quick task.
- verify: `grep 'Last updated: 2026-04-15' .planning/REQUIREMENTS.md` returns a match.
- done: Footer mentions 2026-04-15 and quick-260415-gzu.

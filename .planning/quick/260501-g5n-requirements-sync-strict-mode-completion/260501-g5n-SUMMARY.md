---
quick_id: 260501-g5n
description: requirements-sync strict-mode completion check
date: 2026-05-01
status: complete
backlog_origin: ROADMAP.md Phase 999.7
---

# Quick Task 260501-g5n — Summary

## What changed

`bin/requirements-sync.sh` now accepts `--require-complete`, a closure-gate primitive that exits 2 when any in-scope REQ-ID has status != Complete in REQUIREMENTS.md. It is orthogonal to `--strict` (which checks REQUIREMENTS.md vs VERIFICATION.md drift). Composes with `--phase N` for phase-scope closure.

## Why

Surfaced 2026-05-01 reconciling Phase 12.1's NEUT-08 promotion. The bare `--strict` check passed trivially (`0 drift / NEUT-08 Pending / not found / ok / exit 0`), meaning closure gates that lean on it cannot detect incomplete work — only inconsistent work. Phase 13.2's closure-verification gate authoring would have re-surfaced the same gap, so we shipped the primitive ahead of it. Phase 13.2 stays pure verification: it consumes `--require-complete`, doesn't build it.

## Files changed

- `bin/requirements-sync.sh` — new flag, new sentinel, exit 2 on incomplete in --require-complete mode, --help block updated
- `tests/phase-07/test_requirements_sync.sh` — 4 new tests (t8–t11)
- `.planning/ROADMAP.md` — Phase 999.7 backlog entry marked DELIVERED via this quick task

## Verification

```
$ bash tests/phase-07/test_requirements_sync.sh
PASS t1_clean_advisory ... t11_strict_does_not_check_completion
requirements_sync: 11/11

$ bash bin/requirements-sync.sh --strict; echo $?           # unchanged behavior
0
$ bash bin/requirements-sync.sh --require-complete; echo $?  # full milestone, multiple Pending
2
$ bash bin/requirements-sync.sh --require-complete --phase 12.1; echo $?
2  # NEUT-08 still Pending
$ bash bin/requirements-sync.sh --require-complete --phase 7; echo $?
0  # all Phase 7 REQ-IDs Complete
```

## Backward compatibility

- `--strict` semantics unchanged (drift-only).
- New flag is opt-in. Existing call sites unaffected.

## Follow-ups

- When Phase 13.2 lands, its closure-verification plan should call `bin/requirements-sync.sh --require-complete` (without `--phase`) as one of the gate checks.
- Consider a `--milestone X` flag in the future if multi-milestone repos need scoped closure (out of scope here — current call sites all imply "current milestone" = "all rows").

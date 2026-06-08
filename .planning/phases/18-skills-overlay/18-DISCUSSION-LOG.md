# Phase 18: Skills Overlay - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 18-skills-overlay
**Areas discussed:** Generator data layout, --check wiring & drift behavior, Thinness enforcement depth, Spec/core visibility

---

## Todo triage

| Option | Description | Selected |
|--------|-------------|----------|
| Keep deferred | `phase-14-lint-mask-fence-edge-cases` is unrelated lint-masking debt, coincidental keyword match | ✓ |
| Fold into Phase 18 | Pull lint-masking hardening into scope | |

**User's choice:** Keep deferred
**Notes:** Stays in `.planning/todos/pending/`; recorded under CONTEXT.md Reviewed Todos.

---

## Generator data layout

| Option | Description | Selected |
|--------|-------------|----------|
| All inline in gen-skills.sh | Bash `DESC[op]` array + heredoc body template, zero deps, single SOT file | ✓ |
| Body template as schema/ file | `schema/skills/SKILL.template.md` + inline descriptions | |
| Separate data manifest | Per-op data in a parsed manifest file | |

**User's choice:** All inline in gen-skills.sh
**Notes:** Mirrors sync-claude's zero-dep minimalism; the script is the artifact source-of-truth. (D-01/D-02)

---

## --check wiring & drift behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-commit (auto-fix) + CI | Pre-commit regenerate+restage (after sync-claude) AND CI hard-fail | ✓ |
| CI only, hard-fail | No pre-commit; PR fails on drift | |
| Pre-commit only (auto-fix) | Local auto-fix, no CI | |

**User's choice:** Pre-commit (auto-fix) + CI
**Notes:** Pre-commit drift UX mirrors sync-claude exactly (regenerate → git add → exit 1, ask re-run); CI is hard-fail only. Inserted between sync-claude and the write-gate. (D-03/D-04/D-05)

---

## Thinness enforcement depth

| Option | Description | Selected |
|--------|-------------|----------|
| Regenerate-diff + structural asserts | Diff PLUS ≤3-line body / only-SKILL.md-per-dir / no-first-person asserts | ✓ |
| Regenerate-diff only | Trust the template stays thin | |
| Separate lint `skills` category | Asserts in bin/lint.sh instead | |

**User's choice:** Regenerate-diff + structural asserts
**Notes:** Key rationale — a fattened *template* passes a pure diff (committed == fattened template), so the independent asserts are the real guard on template thinness. All inside gen-skills.sh, no new lint surface. (D-06/D-07)

---

## Spec/core visibility

| Option | Description | Selected |
|--------|-------------|----------|
| DR + neutrality + docs, no core line | Decision record + check-neutrality surface + docs/reference page; no resident-core line | ✓ |
| Also add a core routing line | All of the above PLUS a one-line core mention | |
| Minimal — no DR, no core line | Just generate + gate + neutrality | |

**User's choice:** DR + neutrality + docs, no core line
**Notes:** Skills are pointers (not authoritative) → don't belong in the routing table, and omitting them protects the v1.2 core-shrink goal. DR records the "why"; docs page serves adopters. (D-08/D-09/D-10/D-11)

---

## Claude's Discretion

- Exact per-op `description` wording (third-person, what+when, ~1–2 sentences).
- Docs page filename (`docs/reference/skills.md` suggested) and DR slug date-stamp.
- Aggregated vs per-file structural-assert error output (UX detail).

## Deferred Ideas

- Skills for audit/brownfield/release/structured-operations + convenience skills — out of scope (minimalism).
- Wizard/installer materializing `.claude/skills/` in adopter repos — release/template-shipping workstream.
- `bin/sync-claude.sh --check-tree` whole-`schema/`-tree drift diff — broader tooling, not this phase.

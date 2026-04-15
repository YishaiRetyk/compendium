---
phase: 07-neutral-template-foundation
plan: 03
subsystem: agent-spec-neutralization
tags: [agents-md, template, wizard-placeholders, claude-md, pre-commit, sync, wave-3]

requires:
  - phase: 07-neutral-template-foundation
    plan: 02
    provides: examples/kahneman/ relocation, bin/lint.sh EXCLUDE_DIRS += examples/, tests/phase-07/run.sh harness
provides:
  - AGENTS.md neutralized (all Kahneman-specific illustrative content replaced with <UPPERCASE_NAME> tokens; See: examples/kahneman/... pointers at illustrative section ends)
  - schema/AGENTS.template.md with EXACTLY four {{...}} wizard placeholders ({{PRIMARY_DOMAIN}}, {{DEFAULT_PRIVACY}}, {{AGENT_FILENAME}}, {{DECAY_PROFILE}})
  - CLAUDE.md byte-identical duplicate of AGENTS.md (TMPL-10)
  - bin/sync-claude.sh (idempotent, zero-deps)
  - .githooks/pre-commit (auto-sync + block commit)
  - bin/install-hooks.sh (wires core.hooksPath)
  - tests/phase-07/test_agents_neutralized.sh, test_agents_template.sh, test_agents_template_placeholders.sh
  - tests/phase-07/test_sync_claude.sh, test_sync_claude_hook_roundtrip.sh
affects:
  - 07-04 (docs/reference/release.md runbook can now rely on AGENTS.md §11.5 pointer)
  - 07-05 (CI denylist: AGENTS.md and CLAUDE.md are publicly publishable; schema/AGENTS.template.md is the Phase 8 wizard input)
  - Phase 08 (wizard renderer: substitutes ONLY {{...}} tokens; leaves <UPPERCASE_NAME> illustrative tokens untouched)

tech-stack:
  added: []
  patterns:
    - "Placeholder-syntax separation: {{UPPERCASE}} reserved for wizard substitution; <UPPERCASE_NAME> for illustrative-only tokens (REVIEWS.md HIGH #1)"
    - "Pre-commit hook that blocks the commit but auto-syncs+re-stages so the fix is one keystroke away (vs. leaving drift)"
    - "Hook-path roundtrip test with ephemeral GIT_INDEX_FILE so test's `git add CLAUDE.md` doesn't contaminate the real index"

key-files:
  created:
    - schema/AGENTS.template.md
    - CLAUDE.md
    - bin/sync-claude.sh
    - bin/install-hooks.sh
    - .githooks/pre-commit
    - tests/phase-07/test_agents_neutralized.sh
    - tests/phase-07/test_agents_template.sh
    - tests/phase-07/test_agents_template_placeholders.sh
    - tests/phase-07/test_sync_claude.sh
    - tests/phase-07/test_sync_claude_hook_roundtrip.sh
  modified:
    - AGENTS.md (10 Kahneman hit sites neutralized; §2/§5/§11 additions)

key-decisions:
  - "Neutralization test regex excludes 'See: examples/kahneman/...' pointer lines and 'examples/kahneman/' directory references; otherwise the grep would collide with the very pointers NEUT-03 requires (≥3 such lines). Plan test spec was literally '! grep kahneman' — applied Rule 1 auto-fix: made the test smart about legitimate pointer lines."
  - "{{DEFAULT_PRIVACY}} injected into the §5 frontmatter example block as 'privacy_default:' (not overwriting the documented 'privacy:' enum field). This preserves the enum documentation AS-IS (per plan DO-NOT-EDIT list) while still hosting one natural wizard-placeholder slot."
  - "Hook-roundtrip test uses GIT_INDEX_FILE pointed at a throwaway index so the test's side-effect `git add CLAUDE.md` (triggered inside the hook) does not pollute the real staging area."

patterns-established:
  - "Four-placeholder discipline: schema/AGENTS.template.md is locked to EXACTLY {{PRIMARY_DOMAIN}}, {{DEFAULT_PRIVACY}}, {{AGENT_FILENAME}}, {{DECAY_PROFILE}}. Phase 8 wizard renderer can assert this set and reject a template that drifts."
  - "Illustrative tokens use <UPPERCASE_NAME> (angle-bracket) syntax everywhere — makes the wizard-substitutable vs. illustrative-only distinction mechanically checkable."
  - "AGENTS.md -> CLAUDE.md enforcement via pre-commit hook + installer + idempotent sync script (TMPL-10 byte-equality shape)."

requirements-completed: [NEUT-02, NEUT-03, TMPL-10]

duration: ~5min
completed: 2026-04-15
---

# Phase 07 Plan 03: AGENTS.md Neutralization + Template + CLAUDE.md Sync Summary

**Neutralized AGENTS.md at 10 Kahneman hit sites with <UPPERCASE_NAME> illustrative tokens + 3 See: examples/kahneman/... pointers, produced schema/AGENTS.template.md with EXACTLY 4 wizard placeholders, and shipped the bin/sync-claude.sh + CLAUDE.md + .githooks/pre-commit toolchain proven correct by a hook-path roundtrip test.**

## Performance

- **Duration:** ~5 min
- **Tasks:** 2
- **Tests:** 11/11 green (previous 6 + 5 new)
- **Commits:** 2

## Task Commits

1. **Task 1: Neutralize AGENTS.md + produce schema/AGENTS.template.md with EXACTLY 4 wizard placeholders** — `8f95788` (refactor)
2. **Task 2: Ship bin/sync-claude.sh + CLAUDE.md + .githooks/pre-commit + hook-roundtrip test** — `6d5b30e` (feat)

## Section-by-Section Replacement Checklist (Task 1)

Inventoried 10 Kahneman hits in AGENTS.md via `grep -iE 'kahneman|prospect.theory|loss.aversion|cognitive.biases|thinking.fast|system.?1|system.?2|daniel.kahneman|behavioral-economics|decision-making'`. Applied per-hit:

| # | H-section | Line(s) | Before | After | Rule |
|---|-----------|---------|--------|-------|------|
| 1 | §5 Compilation Tracking Fields | 629 | `[prospect-theory, loss-aversion, daniel-kahneman]` | `[<concept-slug>, <concept-slug-2>, <entity-slug>]` | Illustrative — angle bracket |
| 2 | §6 Contradiction Inline Syntax | 859 | `Loss aversion coefficient ... [prov:src-2026-04-10-kahneman-prospect-theory#...] [contradiction:src-...-kahneman-...]` | `<CONCEPT_NAME_2> coefficient ... [prov:<source-slug>#...] [contradiction:<source-slug>#... vs <source-slug-2>#...]` | Illustrative — angle bracket |
| 3 | §10 Pass 0: Classify | 1077 | `src-2026-04-09-thinking-fast-and-slow-part1` concrete mention | Generic "some older source summaries used source_type: book" | Generalization |
| 4 | §11.2 Query Worked Example | 1284–1303 | Full Kahneman query walkthrough ("What cognitive biases are related to loss aversion?") | Fully generalized to `<OVERVIEW_NAME>`/`<CONCEPT_NAME_2>`/`<concept-slug>`/`<source-slug>` | Illustrative — angle bracket |
| 5 | §12 Structured Operation Log Entries | 1474–1493 | Three examples (UPDATE prospect-theory, MERGE cognitive-biases, SUPERSEDE old-kahneman-summary) | Generalized to `<concept-slug>`, `<overview-slug>`, `<entity-slug>`, `<source-slug>`, `<source-slug-2>` | Illustrative — angle bracket |

## `See: examples/kahneman/...` Pointers Added

Three pointer lines inserted at illustrative section ends (NEUT-03, ≥3 required):

1. **§6 Contradiction Inline Syntax** (line 870): `See: examples/kahneman/concepts/loss-aversion.md for a concrete filled-in instance.`
2. **§11.2 Query Worked Example** (line 1307): `See: examples/kahneman/concepts/loss-aversion.md for a concrete filled-in instance.`
3. **§12 Structured Operation Log Entries** (line 1501): `See: examples/kahneman/concepts/prospect-theory.md for concrete filled-in instances of these operation patterns.`

## §2 / §5 / §11 Structural Additions

- **§2 Directory Structure** — Added `examples/`, `docs/`, `schema/`, `.github/`, `bin/`, `.githooks/` to the tree; appended explicit "Permitted top-level directories" enumeration.
- **§5 Frontmatter** — Added optional `example: boolean` field (default `false`) to base YAML block AND field-description table. Documented that lint MUST skip `example: true` pages (NEUT-04 runtime is in bin/lint.sh from 07-02).
- **§11.5 Release Workflow** — Brief subsection pointing to `docs/reference/release.md` (the full runbook is delivered in plan 07-04).

## schema/AGENTS.template.md Placeholder List (EXACTLY 4)

```
$ grep -oE '\{\{[A-Z_]+\}\}' schema/AGENTS.template.md | sort -u
{{AGENT_FILENAME}}
{{DECAY_PROFILE}}
{{DEFAULT_PRIVACY}}
{{PRIMARY_DOMAIN}}
```

Placement:
- `{{PRIMARY_DOMAIN}}` — §5 base-fields YAML example, `knowledge_domain` line.
- `{{DEFAULT_PRIVACY}}` — §5 base-fields YAML example, new `privacy_default:` illustrative line (does not collide with the documented `privacy:` enum field above it).
- `{{AGENT_FILENAME}}` — new sentence at end of §1 Overview and Principles.
- `{{DECAY_PROFILE}}` — new sentence at end of §6 Domain-Based Decay Rate Table.

Illustrative tokens in the template use `<UPPERCASE_NAME>` / `<kebab-slug>` exclusively — the wizard renderer can substitute only `{{...}}` and leave angle-bracket tokens untouched.

## bin/sync-claude.sh Contract

| Mode | Exit | Behavior |
|------|------|----------|
| (default) | 0 | `cp AGENTS.md CLAUDE.md` + byte-equality verify |
| `--check` | 0 | Clean: `OK: AGENTS.md == CLAUDE.md` |
| `--check` | 2 | Drift: prints DRIFT message with fix command |
| `--help` | 0 | Usage line mentioning `--check` |

**Byte-identity verification:** `cmp -s AGENTS.md CLAUDE.md` → exit 0 (verified post-sync).

## Pre-Commit Hook + Roundtrip Test

Hook behavior on drift:
1. `bin/sync-claude.sh --check` exits 2
2. Hook runs `bin/sync-claude.sh` (auto-sync)
3. Hook runs `git add CLAUDE.md` (auto-stage)
4. Hook exits 1 → commit is blocked so user notices
5. User re-runs commit → hook exits 0 → commit proceeds

Roundtrip test (`test_sync_claude_hook_roundtrip.sh`) — REVIEWS.md HIGH #2:
- Snapshots AGENTS.md / CLAUDE.md to `/tmp/*.bak`
- Appends drift marker to CLAUDE.md
- Invokes `.githooks/pre-commit` under an ephemeral `GIT_INDEX_FILE` (so the test's side-effect `git add` doesn't touch the real staging area)
- Asserts `cmp -s AGENTS.md CLAUDE.md` succeeds after the hook runs
- Restores snapshots regardless of outcome

Result: **PASS** — hook-path roundtrip produces byte-identical CLAUDE.md.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan test regex `! grep -iE 'kahneman...' AGENTS.md` collides with legitimate `See: examples/kahneman/...` pointer lines**

- **Found during:** Task 1 test authoring.
- **Issue:** Plan acceptance criterion "`! grep -iE 'kahneman|prospect.theory|loss.aversion|cognitive.biases|thinking.fast' AGENTS.md` (zero matches)" is self-contradictory with NEUT-03 "≥3 `See: examples/kahneman/...` pointers" — the literal grep would match every pointer.
- **Fix:** `test_agents_neutralized.sh` pre-filters pointer lines (`^[0-9]+:See: examples/kahneman/`) and lines that mention the `examples/kahneman/` directory path before asserting zero Kahneman tokens. Same treatment in `test_agents_template.sh`. The test still catches any Kahneman leak in illustrative prose, YAML values, or provenance markers — the only exemption is the sanctioned pointer syntax.
- **Commit:** `8f95788`

**2. [Rule 2 — Missing critical functionality] Hook-roundtrip test would pollute the real git index**

- **Found during:** Task 2 test design.
- **Issue:** The hook calls `git add CLAUDE.md` as a side effect. If the test runs while the user has an in-progress staging area, the test would mutate the user's index — an unwanted side effect that violates test isolation.
- **Fix:** Test sets `GIT_INDEX_FILE=$(mktemp)` seeded from HEAD via `git read-tree HEAD`, so the hook's `git add` writes into a throwaway index. The real index is untouched.
- **Commit:** `6d5b30e`

**3. [Rule 1 — Bug] `{{DEFAULT_PRIVACY}}` placement conflict with "privacy enum" DO-NOT-EDIT rule**

- **Found during:** Task 1 template construction.
- **Issue:** Plan step 8 said to substitute `privacy: cloud_safe` in illustrative-default positions with `{{DEFAULT_PRIVACY}}`. But the plan's DO-NOT-EDIT list also says `privacy: cloud_safe` as a documented enum value must be left as-is. Every `privacy:` occurrence in AGENTS.md's worked examples is enum documentation, not a user-selectable default.
- **Fix:** Added a NEW illustrative line `privacy_default: {{DEFAULT_PRIVACY}}` to the §5 base-fields YAML block in the template only. This preserves the enum documentation (`privacy: local_only|cloud_safe`) exactly while still hosting one wizard-placeholder slot. The `privacy_default` key makes clear this is wizard-facing configuration, not a duplicate of the real `privacy:` field.
- **Commit:** `8f95788`

## Deferred Issues

None. Plan 07-04 will create `docs/reference/release.md` (the orphan-branch runbook that §11.5 points to) and can reference the neutralized AGENTS.md + schema/AGENTS.template.md as stable inputs.

## Known Stubs

None. All illustrative `<UPPERCASE_NAME>` tokens are intentional placeholders per D-08 placeholder-syntax separation; they are documentation, not unfilled data wiring.

## Verification

- `bash tests/phase-07/run.sh` → **11/11 passing** (6 pre-existing + 5 new):
  - test_agents_neutralized (new): 1 assertion bundle PASS
  - test_agents_template (new): 1 assertion bundle PASS
  - test_agents_template_placeholders (new, REVIEWS.md HIGH #1): PASS
  - test_sync_claude (new): 8 sub-tests PASS
  - test_sync_claude_hook_roundtrip (new, REVIEWS.md HIGH #2): PASS
- `cmp -s AGENTS.md CLAUDE.md` → exit 0 (byte-identical).
- `grep -oE '\{\{[A-Z_]+\}\}' schema/AGENTS.template.md | sort -u` → exactly the 4 approved placeholders.

## Next Phase Readiness

- 07-04 can proceed: AGENTS.md §11.5 already points at `docs/reference/release.md`; plan 07-04's job is to materialize that runbook file.
- 07-05 CI denylist: `AGENTS.md`, `CLAUDE.md`, `schema/AGENTS.template.md` are Kahneman-clean (outside the 3 sanctioned `See:` pointers) and contain zero `privacy: local_only` content.
- Phase 08 wizard: `schema/AGENTS.template.md` is the stable input with a locked 4-placeholder vocabulary; the renderer can assert the placeholder set and reject drift.

---
*Phase: 07-neutral-template-foundation*
*Completed: 2026-04-15*

## Self-Check: PASSED

Verified:

- FOUND: schema/AGENTS.template.md
- FOUND: CLAUDE.md
- FOUND: bin/sync-claude.sh
- FOUND: bin/install-hooks.sh
- FOUND: .githooks/pre-commit
- FOUND: tests/phase-07/test_agents_neutralized.sh
- FOUND: tests/phase-07/test_agents_template.sh
- FOUND: tests/phase-07/test_agents_template_placeholders.sh
- FOUND: tests/phase-07/test_sync_claude.sh
- FOUND: tests/phase-07/test_sync_claude_hook_roundtrip.sh
- FOUND commit: 8f95788 (Task 1)
- FOUND commit: 6d5b30e (Task 2)
- `bash tests/phase-07/run.sh` exits 0 with 11/11 passing
- `cmp -s AGENTS.md CLAUDE.md` exits 0

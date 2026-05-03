# Phase 12.2 Deferred Items

Out-of-scope discoveries logged during plan execution per executor scope-boundary rule.

## Discovered during Plan 12.2-02 execution

### Pre-existing AGENTS.md / CLAUDE.md drift

- **Discovered:** 2026-05-04 (during Plan 12.2-02 execution)
- **Test affected:** `tests/phase-09/test_agents_section_12.sh`
- **Symptom:** `CLAUDE.md` has an extra line at line 130 (the placeholder
  rule about not using real wiki slugs in template-public files) that
  `AGENTS.md` does NOT contain.
- **Diff (CLAUDE.md side):**
  ```
  > - DO NOT use real slugs, page IDs, or terms drawn from the user's
  >   private wiki content (under `examples/`, archived sources, or any
  >   `privacy: local_only` page) when authoring or editing
  >   **template-public files**: ... (full line under §3 What Agents
  >   Must NOT Do)
  ```
- **Why deferred:** The drift exists in commits prior to Plan 12.2-02
  (commits `b1c3691` "docs: bias agents toward placeholders in
  template-public files" and `b241cea`). It is NOT caused by Plan 12.2-02's
  changes (which touch only `bin/lint.sh`). Plan 12.2-04 amends AGENTS.md
  §11.3 and runs `bash bin/sync-claude.sh` as part of its workflow, which
  will resolve this drift in the natural course of phase progression.
- **Suggested resolution:** Plan 12.2-04 (AGENTS.md §11.3 amendment) will
  re-run `bin/sync-claude.sh` and `git add CLAUDE.md`, restoring byte
  equality. If the rule line in CLAUDE.md is intentional, it should be
  added back to AGENTS.md as the canonical source.

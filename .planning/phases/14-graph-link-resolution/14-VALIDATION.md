---
phase: 14
slug: graph-link-resolution
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash + inline `python3 -` JSON assertions (no new deps) |
| **Config file** | none — existing `tests/phase-09/lib.sh` harness (self-contained temp wiki) |
| **Quick run command** | `bash tests/phase-09/test_lint_linkres.sh` |
| **Full suite command** | `bash tests/phase-09/run.sh` |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash bin/lint.sh --category linkres --dry-run wiki/` (fast, no write)
- **After every plan wave:** Run `bash tests/phase-09/run.sh`
- **Before `/gsd-verify-work`:** Full suite green + `bin/lint.sh --category linkres` exits 0 over `wiki/` + `bin/sync-claude.sh --check` clean
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-P01 | 01 | 1 | LINK-01 | — | N/A | grep | `grep -q "filename.*aliases" CLAUDE.md` | ❌ W1 | ⬜ pending |
| 14-P01 | 01 | 1 | LINK-02 | — | N/A | grep | `grep -q "title.*aliases" CLAUDE.md` | ❌ W1 | ⬜ pending |
| 14-P01 | 01 | 1 | LINK-03 | — | N/A | yaml+existence | inline DR `trigger_type: schema-update` + index entry check | ❌ W1 | ⬜ pending |
| 14-P01 | 01 | 1 | LINK-02 (sync) | — | byte-equality | CLI | `bash bin/sync-claude.sh --check` | ❌ W1 | ⬜ pending |
| 14-P02 | 02 | 1 | LINK-04 | — | N/A | unit | `bash tests/phase-09/test_lint_linkres.sh` | ❌ W1 | ⬜ pending |
| 14-P02 | 02 | 1 | LINK-05 | — | N/A | unit | `bash tests/phase-09/test_lint_linkres.sh` | ❌ W1 | ⬜ pending |
| 14-P02 | 02 | 1 | LINK-06 | — | idempotent `--fix` | unit (double-run diff) | `bash tests/phase-09/test_lint_linkres.sh` | ❌ W1 | ⬜ pending |
| 14-P02 | 02 | 1 | LINK-06 (CI) | — | strict stays green | CI | `bash bin/lint.sh --ci --strict` over fixture | ❌ W1 | ⬜ pending |
| 14-P03 | 03 | 2 | LINK-07 | — | N/A | e2e | `bash bin/lint.sh --category linkres wiki/` (exit 0) | ❌ W2 | ⬜ pending |
| 14-P03 | 03 | 2 | LINK-08 | — | N/A | e2e | no `linkres error` for body-link variants | ❌ W2 | ⬜ pending |
| 14-P03 | 03 | 2 | LINK-09 | — | respects `example: true` | e2e/grep | self-alias presence + resolve over `examples/` | ❌ W2 | ⬜ pending |
| 14-P03 | 03 | 2 | LINK-10 | — | N/A | manual | Obsidian graph connected; `domain-driven-design.md` not orphan | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/phase-09/test_lint_linkres.sh` — new file; 8 cases covering LINK-04, LINK-05, LINK-06:
  1. Title-unreachable → linkres error
  2. After `--fix`, title-unreachable becomes OK (alias backfilled)
  3. Unique-normalized-match → linkres error (`Hack (Agentive Stack)` ↔ `Hack Agentive Stack`)
  4. Multi-match → linkres warning (not error)
  5. No-match → stays `gap`, NOT `linkres`
  6. `--fix` idempotency (double-run, identical file contents)
  7. CI `strict` stays green with `linkres` active
  8. `orphan` reconciliation (D-03: previously-masked link now surfaces)
- [ ] `tests/phase-09/test_lint_require_version.sh` — update hardcoded version assertions (1.4.0 → 1.5.0) atomically with the `LINT_VERSION` bump

*Existing `tests/phase-09/lib.sh` (self-contained temp wiki + inline assertions) covers all phase requirements — no new framework, no conftest.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Connected graph in Obsidian | LINK-10 | Obsidian graph view is third-party GUI; connectivity is a visual property not scriptable in the harness | Open the vault at repo root in Obsidian with `hideUnresolved` ON; confirm the graph is connected and `domain-driven-design.md` (plus other previously-orphaned pages) are no longer orphan nodes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (LINK-10 is the sole sanctioned manual checkpoint)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`test_lint_linkres.sh`, version-assertion update)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

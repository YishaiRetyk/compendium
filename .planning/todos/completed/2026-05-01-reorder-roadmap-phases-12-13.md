---
created: 2026-05-01T00:00:00
title: Reorder roadmap phases 12–13 and fix cross-cutting issues
area: planning
files:
  - .planning/ROADMAP.md
  - .planning/REQUIREMENTS.md
---

## Problem

Current phase ordering in ROADMAP.md is broken: Phase 12 "Docs Finalization" claims to document the stable v1.1 surface, but Phases 12.1, 12.2, 12.3, and 13 all change that surface afterward. This creates a false success criterion and cascading cross-reference errors throughout ROADMAP.md, REQUIREMENTS.md, and the closure gate.

Secondary issues:
- REQUIREMENTS.md summary counts Phase 7 as 20 requirements but should be 19; Phase 12.3 (NEUT-08 curation) accounts for the 20th and is not yet in the mapped phase counts.
- Phase 7 roadmap detail still lists NEUT-08 as a Phase 7 requirement rather than clarifying that infrastructure shipped in Phase 7 and curation completes in Phase 12.1/12.3.
- CLOSE-02 closure gate does not include Phase 12.3 in its re-run/audit list.
- Phase 12.3 text incorrectly claims `requirements-sync.sh --strict` will fail while NEUT-08 is partial — the script does not actually enforce that.

## Solution

Minimal reorder and cross-cutting fixes:

**New phase sequence:**
1. Phase 12: Complementary Systems Boundary + GTD Alignment (move to front — constrains docs scope)
2. Phase 12.1: NEUT-08 Personal-Term Denylist Curation (small, release-critical, independent)
3. Phase 12.2: Local Wiki Write Gate (before faithfulness audit)
4. Phase 13: Claim Faithfulness Audit (after boundary + write gate)
5. Phase 13.1: Docs Finalization + Obsidian Starter + v1.0 Debt Verification (rename/renumber current Phase 12)
6. Phase 13.2: v1.1 Closure Verification Gate (pure verification, no impl)

**Cross-cutting fixes needed in the same pass:**
- Fix REQUIREMENTS.md phase count: Phase 7 → 19, add Phase 12.3 → 1
- Clarify Phase 7 NEUT-08 entry: "infrastructure shipped in 7; curation in 12.1/12.3"
- Add Phase 12.3 to CLOSE-02 re-run list
- Either update `requirements-sync.sh --strict` to actually fail on non-Complete active requirements, or rephrase Phase 12.3 language to say "milestone-integrity failure" rather than "current tool behavior"

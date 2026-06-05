---
phase: 16-reference-extraction
plan: "03"
subsystem: schema
tags:
  - reference-extraction
  - schema-refactor
  - agents-md
  - wikilinks
  - privacy
  - scaling
  - tooling
dependency_graph:
  requires:
    - schema-reference-provenance-md
    - schema-workflows-lint-md-seed
    - agents-md-section-6-stub
    - template-mirror-ref-09-section-6
  provides:
    - schema-reference-wikilinks-md
    - schema-reference-privacy-md
    - docs-reference-scaling-md
    - docs-reference-tooling-md
    - agents-md-section-8-stub
    - agents-md-section-13-stub
    - agents-md-section-14-stub
    - agents-md-section-15-stub
    - agents-md-section-16-deleted
    - template-mirror-ref-09-sections-8-13-14-15-16
  affects:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/reference/wikilinks.md
    - schema/reference/privacy.md
    - docs/reference/scaling.md
    - docs/reference/tooling.md
tech_stack:
  added: []
  patterns:
    - REF-05 verbatim guard (grep-gated v1.1.1 'filename/path ONLY' truth)
    - Appendix C disposition table verification (10-rule programmatic audit before §16 deletion)
    - bottom-up AGENTS.md editing (§16 delete first, then §15, §14, §13, §8, Red Links — avoids line drift)
    - per-commit template mirror obligation (REF-09: same commit as AGENTS.md edits)
    - Privacy default rule anchored in privacy.md (Appendix C rule 6 home for §16 deletion)
key_files:
  created:
    - schema/reference/wikilinks.md
    - schema/reference/privacy.md
    - docs/reference/scaling.md
    - docs/reference/tooling.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
decisions:
  - "§8 → one-liner stub 'Use [[id|Title]] for ALL intra-wiki links — see schema/reference/wikilinks.md' (full §8 + §3 Red Links moved verbatim to wikilinks.md)"
  - "§3 Red Links → stub '→ See schema/reference/wikilinks.md (red links section)' — pointer-only, content preserved in wikilinks.md"
  - "§13 → terse 2-line stub pointing to schema/reference/privacy.md (agent-facing) and docs/reference/privacy-model.md (human-facing)"
  - "§14/§15 → stub pointers only; content moved verbatim to docs/reference/scaling.md and docs/reference/tooling.md"
  - "§16 deleted after programmatic Appendix C disposition table verification: all 10 rule homes confirmed present"
  - "Appendix C rule 6 ('Privacy default: wiki-local/ tier') anchored in schema/reference/privacy.md 'Privacy default:' line"
  - "REF-05 grep gates: 'filename/path ONLY' and 'for ALL intra-wiki' both required in wikilinks.md (a paraphrase would fail these gates)"
  - "Template mirror applied in same commit (REF-09); stubs byte-identical between AGENTS.md and schema/AGENTS.template.md"
metrics:
  duration: "~25 minutes"
  completed: 2026-06-05
  tasks_completed: 2
  files_modified: 7
---

# Phase 16 Plan 03: §8 Wikilinks + §13 Privacy + §14/§15 docs/ + §16 Deletion Summary

Extract §8 Wikilink Conventions → `schema/reference/wikilinks.md` (carrying v1.1.1 verbatim 'filename/path ONLY' truth); extract §13 privacy → `schema/reference/privacy.md`; extract §14 → `docs/reference/scaling.md`; extract §15 → `docs/reference/tooling.md`; delete §16 (after programmatic Appendix C 10-rule disposition audit); AGENTS.md §8/§13/§14/§15 replaced with stubs; §16 deleted; all changes mirrored into `schema/AGENTS.template.md` in the same commit (REF-09 per-commit).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create schema/reference/wikilinks.md and schema/reference/privacy.md | bd8856a | schema/reference/wikilinks.md, schema/reference/privacy.md |
| 2 | Create docs/reference/scaling.md + tooling.md; stub/delete §8/§13/§14/§15/§16 in AGENTS.md AND schema/AGENTS.template.md; sync CLAUDE.md | bd8856a | docs/reference/scaling.md, docs/reference/tooling.md, AGENTS.md, CLAUDE.md, schema/AGENTS.template.md |

Note: Per plan instructions (commit at Task 2), all 7 files were staged and committed together as one atomic commit at the end of Task 2.

## Verification Results

All plan verification checks passed:

- `grep -q 'filename/path ONLY' schema/reference/wikilinks.md` → PASS (REF-05 verbatim gate 1)
- `grep -q 'for ALL intra-wiki' schema/reference/wikilinks.md` → PASS (REF-05 verbatim gate 2)
- `wc -l schema/reference/wikilinks.md` → 62 lines (≥45 minimum)
- `wc -l schema/reference/privacy.md` → 24 lines (≥15 minimum)
- `wc -l docs/reference/scaling.md` → 53 lines (≥40 minimum)
- `wc -l docs/reference/tooling.md` → 31 lines (≥20 minimum)
- `test -f docs/reference/scaling.md && test -f docs/reference/tooling.md` → PASS
- `! grep -q "^## 16. Appendices" AGENTS.md` → PASS (§16 deleted from core)
- `! grep -q "^## 16. Appendices" schema/AGENTS.template.md` → PASS (§16 deleted from template)
- `grep -q "schema/reference/wikilinks.md" AGENTS.md` → PASS (§8 stub pointer present)
- `grep -q "schema/reference/privacy.md" AGENTS.md` → PASS (§13 stub pointer present)
- `grep -q "docs/reference/scaling.md" AGENTS.md` → PASS (§14 stub present)
- `grep -q "docs/reference/tooling.md" AGENTS.md` → PASS (§15 stub present)
- `grep -q "schema/reference/wikilinks.md" schema/AGENTS.template.md` → PASS (template mirrored)
- `grep -q "docs/reference/scaling.md" schema/AGENTS.template.md` → PASS (template mirrored)
- `grep -q "docs/reference/tooling.md" schema/AGENTS.template.md` → PASS (template mirrored)
- `bash bin/sync-claude.sh --check` → OK: AGENTS.md == CLAUDE.md
- `bash bin/check-neutrality.sh` → exit=0
- `bash bin/check-privacy.sh` → exit=0

## Appendix C Disposition Table Verification

All 10 QRC rules verified before §16 deletion:

| QRC rule | Confirmed home | Status |
|----------|----------------|--------|
| 1: read index.md first | §3 LLM Navigation Rule (resident) | PASS |
| 2: TL;DR/Key Facts before Detail | §3 LLM Navigation Rule (resident) | PASS |
| 3: [[id\|Title]] first mention only | §3 MUST-NOT (resident) + wikilinks.md | PASS |
| 4: [prov:] for every claim | §6 remnant (resident) | PASS |
| 5: one commit per operation | §3 Commit Conventions (resident) | PASS |
| 6: Privacy default wiki-local/ | schema/reference/privacy.md "Privacy default:" + §3 MUST-NOT | PASS |
| 7: ISO 8601 dates | §3 Date Format (resident) | PASS |
| 8: snake_case field names | §3 Frontmatter Field Names (resident) | PASS |
| 9: UPDATE/MERGE/SUPERSEDE/ARCHIVE | §9 Operations Vocabulary (resident) | PASS |
| 10: see §3 MUST-NOT for full list | §3 What Agents Must NOT Do (resident — self-referential) | PASS |

§16 deletion proceeded only after ALL 10 confirmations passed.

## Deviations from Plan

None — plan executed exactly as written. The bottom-up editing approach (§16 delete, then §15, §14, §13, §8, Red Links stub) prevented line-number drift. The §16 deletion was confirmed gone before proceeding to §15 replacement, etc. Template mirrors were applied with identical bottom-up sequencing.

The plan specified §16 deletion as "DELETION 1" first (before stub replacements) but the §16 section was correctly deleted and confirmed gone before each subsequent stub was applied.

## Known Stubs

None. All new schema reference files contain full verbatim content extracted from their respective AGENTS.md sections. The AGENTS.md stubs are intentional (the D-01 remnant pattern — the full content now lives in the leaf files).

## Threat Flags

All threat mitigations applied as specified in plan threat model:

| Flag | File | Status |
|------|------|--------|
| T-16-03-01 (Information Disclosure) | schema/reference/wikilinks.md | MITIGATED — bin/check-neutrality.sh exits 0; §8 uses only abstract examples |
| T-16-03-02 (Information Disclosure) | schema/reference/privacy.md | MITIGATED — no vault-specific content; neutrality check exits 0 |
| T-16-03-03 (Tampering — REF-05 verbatim guard) | schema/reference/wikilinks.md | MITIGATED — grep gates for 'filename/path ONLY' and 'for ALL intra-wiki' both pass |
| T-16-03-04 (Tampering — §16 Appendix C rule 6 silent drop) | AGENTS.md / schema/reference/privacy.md | MITIGATED — 'Privacy default' present in privacy.md; 'DO NOT read wiki-local/ from a cloud session' confirmed in AGENTS.md §3 before deletion |
| T-16-03-05 (Tampering — AGENTS.md ≡ CLAUDE.md) | AGENTS.md / CLAUDE.md | MITIGATED — bin/sync-claude.sh --check exits 0 |

## Self-Check: PASSED

- Commit `bd8856a` exists: confirmed
- Files created: schema/reference/wikilinks.md (62 lines), schema/reference/privacy.md (24 lines), docs/reference/scaling.md (53 lines), docs/reference/tooling.md (31 lines)
- Files modified: AGENTS.md, CLAUDE.md, schema/AGENTS.template.md
- No file deletions in commit (7 files = 4 creates + 3 in-place modifications): confirmed
- `bash bin/sync-claude.sh --check` exits 0
- `bash bin/check-neutrality.sh` exits 0
- `bash bin/check-privacy.sh` exits 0
- Template stubs match AGENTS.md stubs exactly (byte-identical per-section)
- REF-05 grep gates pass: wikilinks.md carries 'filename/path ONLY' verbatim truth

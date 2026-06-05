---
phase: 16-reference-extraction
plan: "04"
subsystem: schema
tags:
  - reference-extraction
  - schema-refactor
  - agents-md
  - routing-table
  - d09-framing
  - decision-record
dependency_graph:
  requires:
    - schema-reference-wikilinks-md
    - schema-reference-privacy-md
    - docs-reference-scaling-md
    - docs-reference-tooling-md
    - agents-md-section-16-deleted
    - template-mirror-ref-09-sections-8-13-14-15-16
  provides:
    - agents-md-routing-table-ref-08
    - agents-md-d09-router-framing
    - schema-fixtures-canonical-agents-md-regenerated
    - ref-10-decision-record
    - phase-09-1-tests-reconciled
    - phase-10-tests-reconciled
    - phase-07-tests-reconciled
  affects:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/fixtures/canonical-AGENTS.md
    - wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md
    - wiki-cloud/index.md
    - wiki-cloud/log.md
    - tests/phase-09.1/test_template_parity.sh
    - tests/phase-09.1/test_agents_section_4_residue.sh
    - tests/phase-09.1/test_agents_section_16.sh
    - tests/phase-10/test_agents_template_parity_section_5.sh
    - tests/phase-10/test_agents_section_5_bootstrap_stage.sh
    - tests/phase-07/test_agents_template.sh
    - tests/phase-07/test_agents_template_placeholders.sh
    - tests/phase-07/test_agents_neutralized.sh
tech_stack:
  added: []
  patterns:
    - IMPORTANT:-flagged split routing table (two-axis: resolvable refs + Phase-17 workflow rows)
    - D-09 router framing (AGENTS.md is dispatch; each leaf file is authoritative for its own sections)
    - direction-pinned resident-drift reconciliation (template brought UP to AGENTS.md; §3 safety bullet never deleted)
    - region-scoped resident-range parity check (NOT unsound whole-file grep -v '{{' diff)
    - byte-faithful wizard render for fixture regeneration (frozen env: WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA)
    - Phase 16 precedent test relaxation (08-04/09-06/13.1 pattern)
key_files:
  created:
    - wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - schema/fixtures/canonical-AGENTS.md
    - wiki-cloud/index.md
    - wiki-cloud/log.md
    - tests/phase-09.1/test_template_parity.sh
    - tests/phase-09.1/test_agents_section_4_residue.sh
    - tests/phase-09.1/test_agents_section_16.sh
    - tests/phase-10/test_agents_template_parity_section_5.sh
    - tests/phase-10/test_agents_section_5_bootstrap_stage.sh
    - tests/phase-07/test_agents_template.sh
    - tests/phase-07/test_agents_template_placeholders.sh
    - tests/phase-07/test_agents_neutralized.sh
decisions:
  - "AGENTS.md preamble updated: 'sole authoritative specification' + 'No other file contains...' → router framing; §2 dir-tree comment 'sole authority' → 'router; see routing table'; §2 Schema rules 'does NOT contain rules' → correct schema/reference/ + schema/workflows/ description"
  - "Routing table placed between §1 and §2 with two sub-tables: 8 resolvable refs + 4 Phase-17 workflow rows (visually marked 'do NOT dereference yet' to prevent dangling pointer override)"
  - "§3 MUST-NOT updated: 'sole source of truth' → 'AGENTS.md is the router; each linked file is authoritative for its own sections; routing table files also permitted'"
  - "Template STEP E.3: direction-pinned drift reconciliation — §3 neutrality MUST-NOT bullet ('DO NOT use real slugs') added TO template (missing pre-existing drift); blank line at 33a34 hunk removed from template. NEVER the reverse direction."
  - "Resident-range parity gate: REGION-SCOPED diff (§1→^## 4.) modulo {{placeholder}} lines — empty after reconciliation; unsound whole-file grep -v '{{' diff removed"
  - "canonical-AGENTS.md fixture regenerated via byte-faithful wizard render (frozen WIZARD_GENERATED_AT=2026-04-16T00:00:00Z, WIZARD_TEMPLATE_SHA=<frozen-fixture>); phase-08 CI-wired byte-equality passes 21/21"
  - "REF-10 DR: affected_pages: [] per §4.6 infra-record precedent + DRFT-04 (index/log tokens excluded from page-ID resolution; schema/reference/*.md not id-bearing wiki pages)"
  - "Phase-07 test reconciliation: test_agents_template + test_agents_template_placeholders relaxed from 4 placeholders to 2 core ({{DEFAULT_PRIVACY}}/{{DECAY_PROFILE}} extracted to leaf files); test_agents_neutralized See: threshold relaxed from >=3 to >=1 (§4 pointers moved to page-types.md)"
metrics:
  duration: "~35 minutes"
  completed: 2026-06-05
  tasks_completed: 3
  files_modified: 15
---

# Phase 16 Plan 04: Routing Table + D-09 Framing + DR + Test Reconciliation Summary

Add the IMPORTANT:-flagged routing table to AGENTS.md core; update D-09 framing (preamble + §3 MUST-NOT); run multi-surface authority-language sweep; mirror this plan's 3 structural changes into schema/AGENTS.template.md; reconcile pre-existing resident-drift (direction-pinned); regenerate canonical fixture; write REF-10 decision record; reconcile 5 plan-specified + 3 phase-07 prior-phase parity tests to the post-extraction shape.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add routing table + D-09 framing + authority sweep + template mirror | f4afc5f | AGENTS.md, CLAUDE.md, schema/AGENTS.template.md |
| 2 | Regenerate canonical fixture + write REF-10 DR + update wiki nav | bb348ba | schema/fixtures/canonical-AGENTS.md, wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md, wiki-cloud/index.md, wiki-cloud/log.md |
| 3 | Reconcile phase-09.1/phase-10/phase-07 parity tests to post-extraction shape | a2b787b | 8 test files |

## Verification Results

All plan verification checks passed:

- `bash bin/sync-claude.sh --check` → OK: AGENTS.md == CLAUDE.md
- `bash bin/check-neutrality.sh` → exit=0
- `bash bin/check-privacy.sh` → exit=0
- `grep -q "IMPORTANT" AGENTS.md` → PASS (routing table present)
- `grep -q "do NOT dereference" AGENTS.md` → PASS (Phase-17 rows non-dereferenceable)
- `! grep -qE 'sole authoritative|sole source of truth|sole authority|No other file|does NOT contain rules|does NOT contain conventions' AGENTS.md CLAUDE.md schema/AGENTS.template.md schema/fixtures/canonical-AGENTS.md` → PASS (multi-surface authority sweep clean)
- `grep -q 'DO NOT use real slugs' AGENTS.md` → PASS (§3 neutrality bullet present)
- `grep -q 'DO NOT use real slugs' schema/AGENTS.template.md` → PASS (bullet added to template by STEP E.3)
- `diff <(awk '/^## 4\./{exit}{print}' AGENTS.md | grep -v '{{') <(awk '/^## 4\./{exit}{print}' template | grep -v '{{')` → empty (resident range parity)
- `grep -q 'IMPORTANT — Reference Routing Table' schema/fixtures/canonical-AGENTS.md` → PASS
- `! grep -q '^## 16\. Appendices' schema/fixtures/canonical-AGENTS.md` → PASS
- `bash tests/phase-08/run.sh` → 21/21 PASS (CI-wired; byte-equality gate passes against regenerated fixture)
- `bash tests/phase-09.1/run.sh` → 11/11 PASS (all 3 plan-specified tests + pre-existing tests)
- `bash tests/phase-10/run.sh` → 32/32 PASS (both plan-specified tests + pre-existing tests)
- `bash tests/phase-07/run.sh` → 20/22 (see Deferred Issues below)
- All 8 routing-table resolvable target files exist on disk
- `grep -q 'trigger_type: schema-update' wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md` → PASS
- `grep -q 'affected_pages: \[\]' wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md` → PASS

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Reconcile 3 additional phase-07 tests caused by Phase 16 extraction**

- **Found during:** Task 3
- **Issue:** Phase 16 Plans 01-03 extracted §4/§5/§6 content from AGENTS.md. This caused 3 phase-07 tests to fail that weren't in the plan's list of 5 tests to reconcile: `test_agents_template.sh` (looked for `{{DEFAULT_PRIVACY}}` and `{{DECAY_PROFILE}}`), `test_agents_template_placeholders.sh` (same), `test_agents_neutralized.sh` (expected >=3 `See: examples/kahneman/` pointers, now 2 in AGENTS.md).
- **Fix:** Updated all 3 tests following the same 08-04/09-06/13.1 precedent used for the 5 plan-specified tests.
- **Files modified:** tests/phase-07/test_agents_template.sh, tests/phase-07/test_agents_template_placeholders.sh, tests/phase-07/test_agents_neutralized.sh
- **Commit:** a2b787b

**2. [Rule 1 - Bug] Stray extra blank line in template resident range**

- **Found during:** Task 1 STEP E.3
- **Issue:** The template had an extra blank line (`33a34` hunk) between the `{{AGENT_FILENAME}}` line and the routing table. After filtering with `grep -v '{{'`, this produced a spurious diff vs AGENTS.md.
- **Fix:** Removed the extra blank line from the template so the resident range passes the empty-diff gate.
- **Files modified:** schema/AGENTS.template.md
- **Commit:** f4afc5f

## Deferred Issues

**1. test_kahneman_moved.sh (phase-07):** `amos-tversky` entity page missing from the examples/kahneman/ cluster; `bounded-rationality` page missing. These are pre-existing issues in the example cluster (not caused by Phase 16 extraction). Status: warning. Out of scope for this plan.

**2. test_wiki_skeleton.sh (phase-07):** wiki-cloud/ has real content (93 lines in index.md > 40 limit); wiki-cloud/ subdirectories for entities/concepts/etc. present. These are pre-existing issues from wiki content added in prior phases. The test was designed for the Phase 7 skeleton state. Status: info. Out of scope for this plan.

## Known Stubs

None. All routing table targets exist on disk. Phase-17 workflow rows are intentionally marked "do NOT dereference yet" — these are not stubs, they are future-work declarations.

## Threat Flags

No new security-relevant surface introduced beyond what was planned. All threat mitigations from the plan's threat model applied:

| Flag | File | Status |
|------|------|--------|
| T-16-04-01 (Information Disclosure — routing table) | AGENTS.md | MITIGATED — routing table uses only file paths; bin/check-neutrality.sh exits 0 |
| T-16-04-02 (Information Disclosure — DR) | wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md | MITIGATED — abstract placeholders only; neutrality check exits 0 |
| T-16-04-03 (Tampering — template parity) | schema/AGENTS.template.md | MITIGATED — REGION-SCOPED parity (resident range §1→^## 4. empty diff modulo placeholders); phase-08 run.sh passes |
| T-16-04-07 (Tampering — §3 safety bullet deletion) | AGENTS.md | MITIGATED — STEP E.3 direction-pinned; §3 bullet present in BOTH AGENTS.md AND template; guardrail passed |
| T-16-04-08 (Tampering — stale fixture) | schema/fixtures/canonical-AGENTS.md | MITIGATED — fixture regenerated via wizard render (byte-faithful frozen env); phase-08 21/21 |
| T-16-04-04 (Tampering — dangling Phase-17 pointers) | AGENTS.md routing table | MITIGATED — workflow rows marked "do NOT dereference yet" / *(Phase 17)*; STEP F test -f only on resolvable rows |
| T-16-04-05 (Tampering — CI/test regression) | test suite | MITIGATED — all specified tests reconciled and green; phase-08/09.1/10 pass |
| T-16-04-06 (Tampering — false authority language) | all surfaces | MITIGATED — BROADENED sweep including 'sole authority' ran across all 4 surfaces; no hits remaining |

## Self-Check: PASSED

- Commit `f4afc5f` exists: confirmed (Task 1 — AGENTS.md + CLAUDE.md + template)
- Commit `bb348ba` exists: confirmed (Task 2 — fixture + DR + wiki nav)
- Commit `a2b787b` exists: confirmed (Task 3 — 8 test files)
- Files created: wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md
- Files modified: AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md, wiki-cloud/index.md, wiki-cloud/log.md, 8 test files
- No unexpected file deletions in any commit (all intended changes)
- `bash bin/sync-claude.sh --check` exits 0
- `bash bin/check-neutrality.sh` exits 0
- `bash tests/phase-08/run.sh` → 21/21 (CI-wired gate)
- `bash tests/phase-09.1/run.sh` → 11/11
- `bash tests/phase-10/run.sh` → 32/32
- `bash tests/phase-07/run.sh` → 20/22 (2 pre-existing failures documented above)
- All 8 routing table target files present on disk
- DR: trigger_type: schema-update, affected_pages: [], all 7 sections present

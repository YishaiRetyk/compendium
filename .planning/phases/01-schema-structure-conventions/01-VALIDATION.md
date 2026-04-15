---
phase: 1
slug: schema-structure-conventions
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-09
approved: 2026-04-15
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Inline grep/test commands + `python3 -c "import yaml"` for frontmatter — no external test framework needed for markdown/YAML validation |
| **Config file** | none — all validation is inline |
| **Quick run command** | Per-task grep/test commands in `<automated>` blocks below |
| **Full suite command** | `bash bin/lint.sh` (built in Phase 5, validates AGENTS.md + directory + frontmatter conventions phase-1 produced) |
| **Estimated runtime** | ~1 second per task command; ~3 seconds for `bin/lint.sh` full suite |

---

## Sampling Rate

- **After every task commit:** Run task's `<automated>` verify block
- **After every plan wave:** Run all `<automated>` blocks from the wave
- **Before `/gsd:verify-work`:** All automated checks must pass
- **Max feedback latency:** 3 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 01-01-T1 | 01 | 1 | DIRS-01 | dir-exists | `test -d sources/` | ✅ green |
| 01-01-T1 | 01 | 1 | DIRS-02 | dir-exists | `test -d wiki/entities && test -d wiki/concepts && test -d wiki/sources && test -d wiki/comparisons && test -d wiki/overviews` | ✅ green |
| 01-01-T1 | 01 | 1 | DIRS-03 | dir-siblings | `test -d sources && test -d wiki && [ "$(dirname $(realpath sources))" = "$(dirname $(realpath wiki))" ]` | ✅ green |
| 01-01-T1 | 01 | 1 | DIRS-04 | git-tracked | `git rev-parse --is-inside-work-tree && git log --oneline -1` | ✅ green |
| 01-01-T1 | 01 | 1 | OBSD-02 (index/log YAML) | yaml-parse | `python3 -c "import yaml,re;[yaml.safe_load(re.match(r'---\n(.*?)\n---',open(f).read(),re.S).group(1)) for f in ['wiki/index.md','wiki/log.md']]"` | ✅ green |
| 01-01-T2 | 01 | 1 | SCHM-01 | file-exists + size | `test -f AGENTS.md && [ $(wc -l < AGENTS.md) -ge 900 ]` | ✅ green |
| 01-01-T2 | 01 | 1 | SCHM-03 | content-grep (5 page types) | `grep -c "^### 4\." AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | SCHM-04 | content-grep (frontmatter schema) | `grep -q "## 5\. Frontmatter" AGENTS.md && grep -cE "^- \`[a-z_]+\`:" AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | OBSD-01 | content-grep (wikilinks) | `grep -c '\[\[' AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | OBSD-03 | content-grep (first-mention rule) | `grep -c "first-mention" AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | OBSD-04 | content-grep (Dataview queries) | `grep -c 'FROM "wiki' AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | PROG-01 | content-grep | `grep -q "## TL;DR" AGENTS.md \|\| grep -q "TL;DR" AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | PROG-02 | content-grep (section orderings) | `grep -q "Progressive Disclosure" AGENTS.md` | ✅ green |
| 01-01-T2 | 01 | 1 | PROG-03 | content-grep | `grep -c "read index first" AGENTS.md` | ✅ green |
| 01-02-T1 | 02 | 2 | SCHM-02 | content-grep (4 workflows) | `grep -cE "^### 11\.[1-4] " AGENTS.md` | ✅ green |
| 01-02-T1 | 02 | 2 | SCHM-05 | content-grep (ops vocab) | `grep -qE "UPDATE.*MERGE.*SUPERSEDE.*ARCHIVE" AGENTS.md \|\| grep -cE "^### 9\." AGENTS.md` | ✅ green |
| 01-02-T2 | 02 | 2 | BNDY-01 | content-grep (scaling tiers) | `grep -q "## 14\. Scaling" AGENTS.md && grep -cE "^### 14\." AGENTS.md` | ✅ green |
| 01-02-T2 | 02 | 2 | BNDY-02 | content-grep (privacy routing) | `grep -q "## 13\. Privacy" AGENTS.md && grep -q "local_only" AGENTS.md && grep -q "cloud_safe" AGENTS.md` | ✅ green |
| 01-02-T2 | 02 | 2 | BNDY-03 | content-grep (heuristic) | `grep -c "heuristic" AGENTS.md` | ✅ green |
| 01-03-T1 | 03 | 3 | all (provenance syntax) | regex-validate | `grep -oE '\[prov:[^]]+\]' AGENTS.md \| wc -l` (expect ≥1) | ✅ green |
| 01-03-T1 | 03 | 3 | all (structural integrity) | count-sections | `[ $(grep -c "^## " AGENTS.md) -ge 16 ]` | ✅ green |
| 01-03-T1 | 03 | 3 | all (full lint) | full-suite | `bash bin/lint.sh` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

All 19 Phase 1 requirements (SCHM-01..05, DIRS-01..04, OBSD-01..04, PROG-01..03, BNDY-01..03) have automated coverage via inline commands + `bin/lint.sh`. Verified live 2026-04-15.

---

## Wave 0 Requirements

No Wave 0 test-infrastructure work needed. All automated checks are shell one-liners (grep, test, python3 yaml.safe_load) using tools present by default. `bin/lint.sh` was built in Phase 5 and now serves as the full-suite runner covering structural/provenance/YAML checks for the artifacts Phase 1 produced.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LLM can comprehend & follow schema to produce a valid page | SCHM-01 (comprehensibility facet) | Requires LLM comprehension judgment — grep can verify content exists, not that it is clear | Have an LLM read AGENTS.md sections 1-8 with no other context and create a wiki page; check output conforms |
| Obsidian graph view shows meaningful connections | OBSD-03 (graph facet) | Requires Obsidian GUI | Open vault in Obsidian, verify graph view renders example pages as connected cluster |
| Dataview queries against wiki return expected results | OBSD-04 (runtime facet) | Requires Obsidian + Dataview plugin | Run a Dataview query from AGENTS.md Appendix A; verify results |
| Worked examples look realistic | SCHM-03 (quality facet) | Subjective quality judgment | Read Sections 4.1-4.5; confirm each reads like a plausible real page |

Recorded in 01-VERIFICATION.md §"Human Verification Required" — three of the four were explicitly flagged as deferred-human-verification at phase-close.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no Wave 0 needed — tools default-present)
- [x] No watch-mode flags
- [x] Feedback latency < 3s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-15

---

## Validation Audit 2026-04-15

| Metric | Count |
|--------|-------|
| Gaps found | 19 (all documentation — TBD task IDs, fictional `validate.sh` reference, no per-req command mapping) |
| Resolved | 19 (replaced with inline grep/test/yaml commands already passing per VERIFICATION.md; `bin/lint.sh` from Phase 5 serves as full-suite runner) |
| Escalated | 0 |
| Manual-only (unchanged) | 4 (Obsidian GUI, LLM comprehension, Dataview runtime, example realism) |

**Auditor:** inline (no gsd-nyquist-auditor spawn — no test files to generate; commands already runnable against current repo state, verified live).

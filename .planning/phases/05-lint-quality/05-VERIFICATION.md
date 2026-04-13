---
phase: 05-lint-quality
verified: 2026-04-13T20:15:00Z
status: passed
score: 5/5 success criteria verified
must_haves:
  truths:
    - "Running the lint workflow detects orphan pages, missing cross-references, stale claims, and contradictions, and reports them in a structured format"
    - "When two sources disagree on a claim, the contradiction is surfaced with both sides cited and flagged in the affected wiki pages"
    - "Claims inherit temporal relevance from source dates, different knowledge types decay at configurable rates, and the lint flags claims older than their threshold"
    - "The lint identifies topics mentioned frequently but lacking dedicated pages, and categories with sparse source coverage"
    - "A CLI lint helper exists that runs all lint rules and reports findings, and the lint workflow is documented step-by-step in the schema"
  artifacts:
    - path: "bin/lint.sh"
      provides: "CLI lint helper with 9 checks across 7 categories"
    - path: "wiki/maintenance/lint-report.md"
      provides: "Persistent lint report with findings organized by severity"
    - path: "AGENTS.md"
      provides: "Schema extensions for decay rates, contradiction syntax, severity tiers, auto-fix boundary, new frontmatter fields"
  key_links:
    - from: "bin/lint.sh"
      to: "AGENTS.md section 6"
      via: "DECAY_RATES dict matching decay rate table values"
    - from: "bin/lint.sh"
      to: "wiki/maintenance/lint-report.md"
      via: "script generates the report page"
    - from: "bin/lint.sh"
      to: "wiki/log.md"
      via: "script appends log entry"
---

# Phase 5: Lint & Quality Verification Report

**Phase Goal:** The wiki has a comprehensive health-check system that detects contradictions, stale claims, orphan pages, missing cross-references, and knowledge gaps on demand
**Verified:** 2026-04-13T20:15:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running the lint workflow detects orphan pages, missing cross-references, stale claims, and contradictions, and reports them in a structured format | VERIFIED | `bash bin/lint.sh wiki/ --dry-run` exits 0 and prints 4 findings (2 warnings, 2 info) across all categories. Report has Errors/Warnings/Info sections. |
| 2 | When two sources disagree on a claim, the contradiction is surfaced with both sides cited and flagged in the affected wiki pages | VERIFIED | Check 6 (lines 564-632) flags sections with 2+ source_ids, excludes comparison/overview pages. Finding text includes both source IDs and "agent review needed". |
| 3 | Claims inherit temporal relevance from source dates, different knowledge types decay at configurable rates, and the lint flags claims older than their threshold | VERIFIED | DECAY_RATES dict (lines 139-145) with software=180, science=730, biography=1825, personal-goals=90. EPISTEMIC_MODIFIERS (lines 148-153). Date fallback chain (lines 497-515). Hash override (lines 445-460). |
| 4 | The lint identifies topics mentioned frequently but lacking dedicated pages, and categories with sparse source coverage | VERIFIED | Check 8 (lines 692-775) detects red links on 2+ pages or in TL;DR/Key Facts. Check 9 (lines 778-838) detects sparse coverage with maturity guardrail. Actual finding: "Amos Tversky" red link on 4 pages, maturity guardrail correctly skips sparse coverage. |
| 5 | A CLI lint helper exists that runs all lint rules and reports findings, and the lint workflow is documented step-by-step in the schema | VERIFIED | bin/lint.sh (972 lines) is executable with --help, --dry-run, --fix, --category flags. AGENTS.md section 11.3 (lines 1213-1241) documents the 13-step lint workflow with severity tiers and auto-fix boundary. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/lint.sh` | CLI lint helper with structural checks, staleness, contradiction, gap detection | VERIFIED | 972 lines, bash + inline python3, 9 checks across 7 categories, all CLI flags working |
| `wiki/maintenance/lint-report.md` | Persistent lint report with valid frontmatter | VERIFIED | Valid AGENTS.md section 5 compliant frontmatter (id: lint-report, type: overview, has_contradictions: false, knowledge_domain: ""), Errors/Warnings/Info sections with counts |
| `AGENTS.md` | Schema extensions for decay rates, contradiction syntax, severity tiers, auto-fix boundary, new frontmatter fields | VERIFIED | knowledge_domain referenced 4+ times, has_contradictions 6+ times, Domain-Based Decay Rate Table present, Contradiction Inline Syntax present, severity tiers table present, Auto-Fix Boundary present, staleness policy bucket distinction documented |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| bin/lint.sh | AGENTS.md section 6 | DECAY_RATES dict | WIRED | Lines 139-145 contain exact values from decay rate table (180, 730, 1825, 90, default 365) |
| bin/lint.sh | wiki/maintenance/lint-report.md | script generates report | WIRED | Lines 865-935 generate report with full frontmatter and severity sections |
| bin/lint.sh | wiki/log.md | script appends log entry | WIRED | Lines 938-942 append log entry with severity breakdown |
| bin/lint.sh | wiki/index.md | reads index for orphan detection | WIRED | Lines 344-357 scan index.md and log.md for wikilinks feeding orphan resolution |
| AGENTS.md section 6 | AGENTS.md section 5 | knowledge_domain field | WIRED | Decay rate table references knowledge_domain, section 5 defines it as "staleness policy bucket" |
| AGENTS.md section 11.3 | AGENTS.md section 6 | staleness checks reference decay rate table | WIRED | Step 6 says "domain decay rate table (Section 6)" |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| bin/lint.sh | findings[] | wiki page parsing via python3 yaml + regex | Yes -- actual wiki files parsed, real findings produced | FLOWING |
| wiki/maintenance/lint-report.md | report content | bin/lint.sh findings accumulator | Yes -- 4 real findings from actual wiki content | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Help flag works | `bash bin/lint.sh --help` | Usage text with all flags, exit 0 | PASS |
| Dry-run produces summary | `bash bin/lint.sh wiki/ --dry-run` | Errors: 0, Warnings: 2, Info: 2, exit 0 | PASS |
| Category filter works | `bash bin/lint.sh wiki/ --dry-run --category orphan` | Only orphan check runs, 0 findings, exit 0 | PASS |
| Report has valid frontmatter | `grep 'id: lint-report' wiki/maintenance/lint-report.md` | Match found | PASS |
| Script is executable | `test -x bin/lint.sh` | True | PASS |
| Contradiction detection excludes overview/comparison | dry-run output | No contradiction findings for decision-making.md or system-1-vs-system-2.md (both are overview/comparison) | PASS |
| Red link detection works | dry-run output | "Amos Tversky" flagged on 4 pages with investigative question | PASS |
| Maturity guardrail works | dry-run output | "Sparse coverage check skipped: wiki needs 5+ domains" with current counts | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-----------|-------------|--------|----------|
| CNTR-01 | 03 | Lint rule that identifies when sources disagree on the same claim | SATISFIED | Check 6 flags multi-source sections as contradiction candidates |
| CNTR-02 | 03, 04 | Contradictions surfaced with both sides cited | SATISFIED | Finding text includes both source IDs in output |
| CNTR-03 | 01, 04 | Contradictions flagged in affected wiki pages | SATISFIED | has_contradictions frontmatter sync (Check 7) + contradiction inline syntax in AGENTS.md |
| STALE-01 | 02, 04 | Claims inherit temporal relevance from source publication dates | SATISFIED | Date fallback chain: checked_at -> ingested_at -> updated_at |
| STALE-02 | 02, 04 | Lint rule flags claims older than configurable threshold | SATISFIED | Decay rate check with domain-specific thresholds and epistemic modifiers |
| STALE-03 | 01 | Different knowledge types decay at different rates | SATISFIED | DECAY_RATES dict with 5 domain-specific periods |
| STALE-04 | 01, 04 | Decay rate conventions documented in schema per knowledge domain | SATISFIED | AGENTS.md section 6 "Domain-Based Decay Rate Table" with 5 domains |
| GAP-01 | 03, 04 | Topics mentioned frequently but lacking dedicated pages | SATISFIED | Check 8 red link detection (2+ pages or TL;DR/Key Facts) |
| GAP-02 | 03, 04 | Categories with sparse source coverage relative to others | SATISFIED | Check 9 sparse coverage with maturity guardrail |
| LINT-01 | 02, 04 | Lint workflow that health-checks the wiki on demand | SATISFIED | bin/lint.sh runs all checks on demand |
| LINT-02 | 02, 04 | Detect orphan pages (no inbound links) | SATISFIED | Check 3 with case-insensitive alias-aware resolution |
| LINT-03 | 02, 04 | Detect missing cross-references (related pages not linked) | SATISFIED | Check 4 flags pages sharing 2+ domains and 2+ tags without mutual links |
| LINT-04 | 02, 04 | Detect stale claims (per STALE-01/02) | SATISFIED | Check 5 with decay rates, epistemic modifiers, hash override |
| LINT-05 | 03, 04 | Detect contradictions (per CNTR-01/02/03) | SATISFIED | Check 6 contradiction candidates + Check 7 has_contradictions sync |
| LINT-06 | 03, 04 | Suggest new questions to investigate and new sources to look for | SATISFIED | Investigative questions in red link and sparse coverage findings |
| LINT-07 | 01, 04 | Lint workflow documented step-by-step in schema | SATISFIED | AGENTS.md section 11.3 has 13-step lint workflow with severity tiers |
| CLI-03 | 02, 04 | Lint helper that runs all lint rules and reports findings | SATISFIED | bin/lint.sh with --help, --dry-run, --fix, --category flags |

**Orphaned requirements:** None. All 17 Phase 5 requirements from REQUIREMENTS.md are covered by plans and satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | - | - | - | No TODO, FIXME, placeholder, or stub patterns found in bin/lint.sh |

### Human Verification Required

### 1. Lint Report Readability in Obsidian

**Test:** Open wiki/maintenance/lint-report.md in Obsidian and verify it renders cleanly
**Expected:** Proper heading hierarchy, bullet-point findings, valid frontmatter parsed by Dataview
**Why human:** Visual rendering quality cannot be verified programmatically

### 2. Contradiction Candidate Quality

**Test:** Review the 2 contradiction candidates flagged in cognitive-biases.md and daniel-kahneman.md
**Expected:** Multi-source Key Facts sections with claims from both Kahneman books are reasonable candidates, not false positives
**Why human:** Semantic judgment about whether the flagging is useful requires human assessment

### 3. Investigative Question Quality

**Test:** Read the suggested question for the "Amos Tversky" red link
**Expected:** The question "What is Amos Tversky and how does it relate to the pages that reference it?" is a useful starting point for investigation
**Why human:** Question quality and usefulness require human judgment

### Gaps Summary

No gaps found. All 5 success criteria from ROADMAP.md are verified against the actual codebase. The bin/lint.sh script is a substantive 972-line implementation with 9 checks across 7 categories, all producing real findings on the existing wiki. The AGENTS.md schema extensions are complete with decay rate table, contradiction syntax, severity tiers, auto-fix boundary, and new frontmatter fields. All 17 requirements are satisfied. All wiki pages have knowledge_domain and has_contradictions fields backfilled.

---

_Verified: 2026-04-13T20:15:00Z_
_Verifier: Claude (gsd-verifier)_

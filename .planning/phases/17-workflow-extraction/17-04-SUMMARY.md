---
phase: 17-workflow-extraction
plan: "04"
subsystem: lint + schema + wiki
tags:
  - lint
  - routing
  - inclusion-audit
  - agent-parity
  - decision-record
dependency_graph:
  requires:
    - "17-03 (zero cross-file §N in corpus before routing green)"
  provides:
    - "routing lint category (bin/lint.sh 1.8.0)"
    - "inclusion-audit baseline header (AGENTS.md/CLAUDE.md/template)"
    - "WF-09 desk-check evidence (docs/reference/agent-parity.md)"
    - "schema-update DR (wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md)"
  affects:
    - "bin/lint.sh (routing category + LINT_VERSION bump)"
    - "AGENTS.md / CLAUDE.md (inclusion-audit header + per-section comments)"
    - "schema/AGENTS.template.md (mirrored)"
    - "docs/reference/agent-parity.md (WF-09 sections)"
    - "wiki-cloud/decisions/, wiki-cloud/index.md, wiki-cloud/log.md"
tech_stack:
  added:
    - "routing lint category in bin/lint.sh"
    - "remap_ci_severity(sev,cat,msg) helper (centralized severity exception handler)"
    - "inclusion-audit drift info check"
  patterns:
    - "LINT_REPO_ROOT-rooted walk independent of WIKI_DIR (empty-wiki bypass)"
    - "ROUTING_ROW_RE for table-row-only reachability (not stub arrows)"
    - "PATH_REF_RE scoped to schema/(reference|workflows)/*.md and docs/reference/*.md"
    - "ORPHAN/AUDIT message-prefix exceptions centralized in remap_ci_severity"
key_files:
  created:
    - wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md
  modified:
    - bin/lint.sh
    - AGENTS.md
    - CLAUDE.md
    - schema/AGENTS.template.md
    - docs/reference/agent-parity.md
    - wiki-cloud/index.md
    - wiki-cloud/log.md
decisions:
  - "LINT_VERSION 1.7.0 → 1.8.0 (MINOR: new routing category is a non-breaking addition)"
  - "remap_ci_severity() helper centralizes severity exceptions — not inline prefix-matching"
  - "Inclusion-audit baseline = real post-extraction N (no guessed value) — re-synced after Task 3 comments"
  - "DR creation date: 2026-06-05 (per plan specification)"
  - "WF-09 empirical run: blocked-on-host-runtime (AppArmor), desk-check is gating floor"
metrics:
  duration: "~2 hours (including context compaction resume)"
  completed_date: 2026-06-07
  tasks_completed: 4
  tasks_total: 4
  files_created: 1
  files_modified: 7
---

# Phase 17 Plan 04: Routing Guard + Inclusion Tripwire + WF-09 Evidence + DR Summary

One-liner: Routing lint category (forward error/inverse warning, schema/-rooted), inclusion-audit baseline header (N=287) with drift tripwire, WF-09 desk-check + blocked empirical run, schema-update DR for Phase 17 extraction.

## Tasks Completed

| Task | Name | Commit | Key Deliverables |
|------|------|--------|-----------------|
| 1 | Add `routing` lint category | 2abedf7 | bin/lint.sh v1.8.0; routing exits 0 on extracted tree |
| 2 | WF-08 inclusion-audit baseline + drift check | 4e8c4a5 | Header in AGENTS.md/CLAUDE.md/template; drift info check silent at delta 0 |
| 3 | WF-08 section justification + WF-09 evidence | 82ddfaa | 14 inline inclusion comments; agent-parity.md desk-check + empirical sections |
| 4 | DR + index + log + CI gate suite | b5ebe05 | dr-2026-06-05-workflow-extraction.md; all CI gates green |

## Routing Category Implementation

### Architecture

The `routing` category walks the schema corpus independently of `WIKI_DIR`, bypassing the empty-wiki workflow abort. Corpus: `AGENTS.md` + `schema/reference/*.md` + `schema/workflows/*.md`.

**Forward check (dangling refs → error):**
- `PATH_REF_RE`: scoped to `schema/(reference|workflows)/*.md` and `docs/reference/*.md` only — NOT broader repo paths (prevents false-positives on `sources/YYYY/…`, `wiki-local/…`, etc.)
- Each captured path is resolved ON DISK via `os.path.isfile(os.path.join(REPO_ROOT, target))`
- Missing file → `add_finding('error', 'routing', referrer, f'dangling path ref …')`

**Section-ref prohibition (→ error):**
- `SECTION_REF_RE`: `§[0-9]|\bSection [0-9]`
- ANY match in a corpus file → error (Plans 01-03 abolished all §N; no allow-list needed)
- Section headings (`## 9.`, `### 11.3`) never match these patterns — exempt by construction

**Inverse check (orphan workflow files → warning):**
- `ROUTING_ROW_RE`: `^> \|[^\n|]*\|[^\n|]*\`([^\`\n]+)\`[^\n|]*\|` (multiline)
- Reachability = routing-table ROW only; `→ See \`path\`` stub arrows do NOT count (NEW-HIGH-B)
- Workflow files in `schema/workflows/` without a matching routing-table row → `add_finding('warning', 'routing', path, 'ORPHAN: …')`

**WF-08 drift check (→ info):**
- Parses `<!-- inclusion-audit: N lines @ date -->` from `AGENTS.md`
- If `current_lines - N > max(25, ceil(0.20 * N))` → `add_finding('info', 'routing', 'AGENTS.md', 'AUDIT: core drifted …')`

### Severity Handling

`remap_ci_severity(sev, cat, msg)` centralizes severity exceptions:

```python
def remap_ci_severity(sev, cat, msg):
    if cat == 'routing' and msg.startswith('ORPHAN: '):
        return 'warning'   # inverse stays warning, never promoted to error
    if cat == 'routing' and msg.startswith('AUDIT: '):
        return 'info'      # WF-08 drift stays info, never promoted to error
    return CI_SEVERITY_REMAP.get(cat, sev)
```

The `CI_SEVERITY_REMAP` dict has `'routing': 'error'` — forward dangling refs and §N violations gate CI. The helper's ORPHAN/AUDIT prefix exceptions prevent the inverse-orphan and drift-info findings from being promoted.

### Acceptance Tests (All Passed)

- `bash bin/lint.sh --version` → `1.8.0`
- `bash bin/lint.sh --category routing` → exit 0, 0/0/0 findings
- Inverse-orphan test: removing ONLY the routing-table row for `audit.md` (leaving stub arrow) triggers ORPHAN warning under `--ci --format json`
- Resolve-on-disk test: `docs/reference/scaling.md` reference produces no dangling finding
- Negative forward-dangling test: temp copy with `nonexistent.md` ref → dangling error fires
- Empty-wiki bypass: routing scan runs even with near-empty wiki

## WF-08 Inclusion-Audit Baseline and Drift Check

### Baseline

- Recorded N = **287** lines at `2026-06-07`
- Header present in AGENTS.md, CLAUDE.md (mirrored via sync-claude.sh), and schema/AGENTS.template.md
- `wc -l < AGENTS.md` == 287 == baseline N → delta = 0, drift check silent

### Per-Resident-Section Inclusion Justification

| Section | Clause | Rationale |
|---------|--------|-----------|
| §1 Overview and Principles | ambient | Four-operation vocabulary + wiki layering mental model loaded every turn; no dispatch target exists for a 5-line conceptual scaffold |
| §2 Directory Structure | ambient | Path conventions govern file placement on every mutation; agents must know wiki-cloud/ vs wiki-local/ split and sources/ nesting to write any file |
| §3 Global Rules (date, frontmatter, commits, navigation, red links, what-not) | ambient | Date format, snake_case, commit prefixes, navigation order govern every turn; miss cost is silent malformed output not caught by any script |
| Routing Table (IMPORTANT blockquote) | dispatch | The router itself — this is the routing mechanism; it cannot extract from core without becoming self-referential |
| §9 operations stub | dispatch | One-line pointer to schema/workflows/operations.md; the solo-op commit-prefix summary (D-01) is ambient; full definitions JIT-load |
| §10 pipeline stub | dispatch | One-line pointer to schema/workflows/pipeline.md; full pipeline is JIT-loaded at pipeline-reasoning time |
| §11 workflows stubs | dispatch | Write-back-mandatory line is ambient (governs every query); full procedure stubs are dispatch pointers to schema/workflows/*.md |
| §12 index/log stub | dispatch | One-line pointer to schema/reference/log-format.md; full format JIT-loaded when writing log entries |
| §4/§5/§6/§8 stubs | dispatch | "See schema/reference/*.md" routing pointers only; no content resident |
| §13/§14/§15 stubs | dispatch | "See schema/reference/privacy.md" and docs/reference/* routing pointers; no content resident |

All 14 per-section `<!-- inclusion: <clause> — <reason> -->` HTML comments are placed immediately below each section header in AGENTS.md/CLAUDE.md (verified by `grep -c '<!-- inclusion:' CLAUDE.md` → 14; both files byte-identical via sync-claude).

## WF-09 Agent-Parity Evidence

### Three-Tier Reachability Stack

| Tier | Method | Status | Gating? |
|------|--------|--------|---------|
| Mechanical resolvability | `bash bin/lint.sh --category routing` | PASS (exit 0) | Yes (CI-gated error severity) |
| Routing desk-check | Non-mechanized judgment dims (prominence + content self-sufficiency) | PASS | Yes (gating floor) |
| Empirical agent run | Codex/Cursor behavioral discoverability | blocked-on-host-runtime | No (non-gating) |

### Routing Desk-Check Verdict: PASS

**Dimension 1 — Routing-table prominence:** The IMPORTANT routing table is the first content block after the overview, labeled "Reference Routing Table" with an explicit "read before acting" directive. The ingest workflow row points to `schema/workflows/ingest.md`. PASS.

**Dimension 2 — Content self-sufficiency of schema/workflows/ingest.md:** The file contains all ingest steps (Pass 0–4), claim granularity table, Append-Then-Synthesize policy, compilation-tracking fields, and contributor attribution rules. Cross-references dispatch to leaf files. PASS.

### Empirical Run: blocked-on-host-runtime

Codex blocked by AppArmor `apparmor_restrict_unprivileged_userns=1` (bubblewrap cannot create user namespaces). Consistent with Phase 13.2 D-02 acceptance. Desk-check is the gating floor.

## Decision Record

`wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md` created with:
- `trigger_type: schema-update`
- `affected_pages: []` (infrastructure record, no id-bearing wiki pages affected)
- All 7 required sections (TL;DR, Decision, Why, Alternatives Considered, Consequences, Affected Pages, Sources)
- Records: §9–§12 extraction targets, solo-op commit-prefix (D-01), abolish-§N routing guard (D-05), inclusion-audit tripwire (D-09..D-12)
- DR indexed in wiki-cloud/index.md under Decisions
- Reflect log entry appended to wiki-cloud/log.md

## CI Gate Suite Results

| Command | Exit Status |
|---------|-------------|
| `bash bin/sync-claude.sh --check` | 0 (OK) |
| `bash bin/lint.sh --ci --format json` | 0 |
| `bash bin/lint.sh --category routing` | 0 |
| `bash bin/check-neutrality.sh` | 0 |
| `bash bin/check-privacy.sh` | 0 |
| `bash bin/init-wizard.sh --dry-run` | 0 |
| `bash bin/validate-op.sh UPDATE wiki-cloud/index.md` | 0 (PASS) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ROUTING_ROW_RE matched across lines**
- **Found during:** Task 1 testing
- **Issue:** `[^|]*` in the regex matched newlines (since `|` is not `\n`), causing multi-line matches and incorrect capture groups
- **Fix:** Changed `[^|]` to `[^\n|]` to constrain matching to single-line
- **Files modified:** bin/lint.sh
- **Commit:** 2abedf7

**2. [Rule 1 - Bug] PATH_REF_RE too broad**
- **Found during:** Task 1 verification
- **Issue:** Initial regex matched paths like `wiki-local/index.md`, `sources/YYYY/…`, `schema/examples/source.md` — none are valid routing targets; would have caused false-positive dangling findings for non-schema paths
- **Fix:** Scoped regex to `schema/(reference|workflows)/*.md` and `docs/reference/*.md` ONLY
- **Files modified:** bin/lint.sh
- **Commit:** 2abedf7

**3. [Rule 2 - Missing functionality] Baseline needed re-sync after Task 3 comments**
- **Found during:** Task 3 completion
- **Issue:** Task 2 recorded baseline N=273 before Task 3 added 14 inclusion comments, causing baseline to lag actual line count
- **Fix:** Re-counted `wc -l < AGENTS.md` after all inclusion comments added; updated header from N=273 → N=287 in all three files; re-ran sync-claude.sh
- **Files modified:** AGENTS.md, CLAUDE.md, schema/AGENTS.template.md
- **Commit:** 82ddfaa

**4. [Rule 1 - Bug] §N references in agent-parity.md new sections**
- **Found during:** Task 3 Part B verification
- **Issue:** Two instances of `§11.1` in the new Routing Desk-Check section
- **Fix:** Replaced with descriptive text ("the inline workflow content in AGENTS.md")
- **Files modified:** docs/reference/agent-parity.md
- **Commit:** 82ddfaa

## Known Stubs

None — all deliverables are fully implemented. The empirical run section documents blocked-on-host-runtime honestly rather than as a stub; this is the designed outcome per D-15.

## Self-Check: PASSED

**Files verified:**
- FOUND: bin/lint.sh
- FOUND: docs/reference/agent-parity.md
- FOUND: wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md
- FOUND: AGENTS.md (baseline N=287 == actual)
- FOUND: CLAUDE.md (byte-identical to AGENTS.md)
- FOUND: schema/AGENTS.template.md

**Commits verified:**
- FOUND: 2abedf7 (Task 1: routing category)
- FOUND: 4e8c4a5 (Task 2: inclusion-audit baseline + drift check)
- FOUND: 82ddfaa (Task 3: WF-08 inclusion comments + WF-09 desk-check)
- FOUND: b5ebe05 (Task 4: DR + index + log + CI gate suite)

**All acceptance criteria met:** LINT_VERSION 1.8.0, routing exit 0, remap entry present, helper exists, gated, baseline synced, DR created, indexed, logged, all CI gates exit 0.

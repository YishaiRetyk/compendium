---
phase: 17-workflow-extraction
verified: 2026-06-07T20:10:00Z
status: passed
score: 9/9
overrides_applied: 0
human_resolution: "User chose to fix all 3 flagged items before close (commit 95504a4). WR-01 routing category now documented in schema/workflows/lint.md (severity-remap table + category list); WR-02 DR file names corrected (structured-operations.md, §10 folded into ingest.md); WR-03 agent-parity.md desk-check updated to past tense. All gates re-verified green (routing exit 0, sync/neutrality/privacy PASS)."
human_verification:
  - test: "Confirm WR-01 (routing category undocumented in schema/workflows/lint.md) is a polish item not a goal-blocking gap"
    expected: "schema/workflows/lint.md line 81 should list 'routing -> error' in the severity-remap table, and line 150 should list 'routing' in the category list. Currently omitted."
    why_human: "The REVIEW called this a regression by lint.md's own stated rule, but the routing category itself works (exits 0, enforced at CI). Whether undocumented-in-authority-file is goal-blocking vs. polish requires a judgment call."
  - test: "Confirm WR-02 (DR names operations.md/pipeline.md which don't exist) is a polish item not a goal-blocking gap"
    expected: "wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md lines 36-37 should say 'structured-operations.md' and 'folded into ingest.md' respectively. Currently says 'operations.md' and 'pipeline.md'."
    why_human: "The DR misdescribes the change it records. It matters for future-reader understanding. Whether correcting it is required for goal achievement or is polish needs a decision."
  - test: "Confirm WR-03 (agent-parity.md describes Phase 17 as in-progress) is a polish item"
    expected: "docs/reference/agent-parity.md lines 103 and 115 should be updated to past tense — the routing table row is unconditional and the inline workflow content has been removed."
    why_human: "The doc has stale text saying Phase 17 extraction is pending. The desk-check itself passed and the routing guard works, but the evidence doc describes a prior state."
---

# Phase 17: Workflow Extraction Verification Report

**Phase Goal:** Every procedural workflow (structured operations, ingest, query, lint, reflect, brownfield, release, audit) lives in its own standalone file under `schema/workflows/`, the resident core is verified section-by-section against the inclusion test, and a non-Claude agent can ingest using only the routing table and the extracted workflow file.
**Verified:** 2026-06-07T20:10:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every workflow section exists at target path or is correctly folded/deleted per the Extraction Map | VERIFIED | 8 files in schema/workflows/: structured-operations.md, ingest.md, query.md, lint.md, reflect.md, brownfield.md, release.md, audit.md. §10 pipeline.md intentionally absent — folded into ingest.md per WF-02 LOCK. schema/reference/log-format.md exists (115 lines). |
| 2 | Solo structured-op commit-prefix gap (Open Q9) is closed | VERIFIED | AGENTS.md line 219: `update(<page>): … / merge(<page>): … / supersede(<page>): … / archive(<page>): …` with the D-01 definition present |
| 3 | 182-line brownfield workflow is in schema/workflows/brownfield.md; lint.md preserves "source of truth for CI contracts" framing | VERIFIED | brownfield.md is 190 lines. lint.md line 5: "This file wins" authority framing confirmed. |
| 4 | Every resident section carries a one-line justification; core is visibly smaller than 1,689 lines with tripwire seeded | VERIFIED | AGENTS.md: 287 lines (vs 1,689 original; 83% reduction). `grep -c '<!-- inclusion:' AGENTS.md` = 14. Baseline header `<!-- inclusion-audit: 287 lines @ 2026-06-05 -->` matches `wc -l` exactly → drift check silent. |
| 5 | docs/reference/agent-parity.md updated with evidence a Codex/Cursor agent can ingest using routing table | VERIFIED (with note) | Routing Desk-Check section (PASS), Empirical Agent Run section (blocked-on-host-runtime — consistent with Phase 13.2 D-02 acceptance). Per D-15 this is the correct outcome. |
| 6 | `bash bin/lint.sh --category routing` exits 0 over the fully-extracted tree | VERIFIED | Confirmed: `EXIT: 0`, 0/0/0 findings. All 9 extracted files have routing-table rows; zero dangling refs; zero §N residue in corpus (AGENTS.md + schema/reference/ + schema/workflows/). |
| 7 | AGENTS.md byte-identical to CLAUDE.md | VERIFIED | `bash bin/sync-claude.sh --check` exits 0 with "OK: AGENTS.md == CLAUDE.md" |
| 8 | Full CI gate suite passes | VERIFIED | All gates exit 0: sync-claude --check, lint.sh --ci --format json (18 pre-existing crossref errors in wiki-cloud/ content, none from this phase), lint.sh --category routing, check-neutrality.sh, check-privacy.sh, init-wizard.sh --dry-run |
| 9 | Schema-update decision record for the workflow extraction is authored and indexed | VERIFIED | wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md exists; `trigger_type: schema-update`; 7 required sections present; indexed in wiki-cloud/index.md; log entry in wiki-cloud/log.md. (WR-02 doc inaccuracy noted separately.) |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `schema/workflows/structured-operations.md` | §9 extraction | VERIFIED | 102 lines; contains UPDATE/MERGE/SUPERSEDE/ARCHIVE definitions; executor model present |
| `schema/workflows/ingest.md` | §11.1 + folded §10 blocks | VERIFIED | 77 lines; contains Pass 0–4, Claim Granularity Rules, Append-Then-Synthesize policy |
| `schema/workflows/query.md` | §11.2 extraction | VERIFIED | 121 lines; Write-back rules, privacy-tier routing, delta compilation |
| `schema/workflows/lint.md` | §11.3 extraction | VERIFIED | 160 lines; decay/staleness, 15-step procedure, CI contracts framing |
| `schema/workflows/reflect.md` | §11.4 extraction | VERIFIED | 80 lines; three-tier reflect model, decision record procedure |
| `schema/workflows/brownfield.md` | §11.5 extraction | VERIFIED | 190 lines; bootstrap_stage lifecycle, 5 subcommands |
| `schema/workflows/release.md` | §11.6 extraction | VERIFIED | 11 lines; pointer to docs/reference/release.md (111 lines) — thin dispatch pattern, by design |
| `schema/workflows/audit.md` | §11.7 extraction | VERIFIED | 37 lines; review-only diagnostic workflow |
| `schema/reference/log-format.md` | §12 extraction | VERIFIED | 115 lines; index/log entry formats, structured operation log entries, contributor inline field |
| `bin/lint.sh` | routing category + WF-08 drift check | VERIFIED | LINT_VERSION 1.8.0; `routing` in CI_SEVERITY_REMAP; `remap_ci_severity` helper; `should_run('routing')` gate; inclusion-audit drift check; all confirmed |
| `docs/reference/agent-parity.md` | WF-09 three-tier evidence | VERIFIED | Routing Desk-Check section (PASS); Empirical Agent Run (blocked-on-host-runtime); cites `bin/lint.sh --category routing` |
| `wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md` | Schema-update DR | VERIFIED (with WR-02) | exists; trigger_type: schema-update; 7 sections; indexed; logged. Lines 36-37 name `operations.md`/`pipeline.md` which do not exist on disk. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| AGENTS.md routing table | schema/workflows/*.md | `> \| … \| path \|` routing-table rows | VERIFIED | All 8 workflow files + log-format.md have routing-table rows in AGENTS.md; routing lint confirms inverse-orphan check passes |
| bin/lint.sh routing category | schema/ tree + AGENTS.md | LINT_REPO_ROOT-rooted walk, WIKI_DIR-independent | VERIFIED | Code confirmed at lines 2385-2396; corpus = AGENTS.md + schema/reference/*.md + schema/workflows/*.md |
| AGENTS.md inclusion-audit header | bin/lint.sh WF-08 drift check | `inclusion-audit:` comment parsed by the info check | VERIFIED | Header present in AGENTS.md/CLAUDE.md/template; drift check code confirmed at ~L2500; delta=0 after resync |
| remap_ci_severity helper | CI_SEVERITY_REMAP | Centralizes ORPHAN/AUDIT severity exceptions | VERIFIED | `def remap_ci_severity(sev, cat, msg)` confirmed in bin/lint.sh; ORPHAN stays warning, AUDIT stays info |

### Requirements Coverage

| Requirement | Phase | Description | Status | Evidence |
|-------------|-------|-------------|--------|---------|
| WF-01 | 17 | Extract §9 structured ops; close solo-op commit-prefix gap | SATISFIED | structured-operations.md exists; solo-op prefix at AGENTS.md L219 |
| WF-02 | 17 | §10 diagram stays (1 line), NO pipeline.md; fold into relevant files | SATISFIED | pipeline.md absent; Pass 0-4 + Append-Then-Synthesize in ingest.md; 1-line diagram at AGENTS.md L227 |
| WF-03 | 17 | Extract §11.1 ingest + folded §10 claim-granularity rules | SATISFIED | ingest.md; Claim Granularity Rules confirmed |
| WF-04 | 17 | Extract §11.2 query; core keeps write-back-mandatory line | SATISFIED | query.md; AGENTS.md L243 write-back mandatory |
| WF-05 | 17 | Extract §11.3 lint + folded §6 decay/staleness; preserve CI-source-of-truth framing | SATISFIED | lint.md; authority framing at L5 |
| WF-06 | 17 | Extract §11.4 reflect, §11.5 brownfield (182-line miss), §11.6 release, §11.7 audit | SATISFIED | reflect.md, brownfield.md (190L), release.md, audit.md all exist |
| WF-07 | 17 | Extract §12 formats → schema/reference/log-format.md | SATISFIED | log-format.md (115L) |
| WF-08 | 17 | Verify core section-by-section; inclusion tripwire | SATISFIED | 14 inline `<!-- inclusion: -->` comments; baseline N=287 == actual wc -l; drift check silent |
| WF-09 | 17 | Agent-parity check with evidence in docs/reference/agent-parity.md | SATISFIED | Routing Desk-Check (PASS) + Empirical blocked-on-host-runtime (non-gating, correct per D-15) |

### Anti-Patterns Found

| File | Location | Pattern | Severity | Impact |
|------|----------|---------|----------|--------|
| wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md | Lines 36-37 | Names `operations.md`/`pipeline.md` which do not exist on disk | Warning (WR-02) | Decision record misdescribes the change it records; future readers following the DR would look for non-existent files |
| docs/reference/agent-parity.md | Lines 103, 115 | Describes Phase 17 extraction as in-progress ("Future home", "Phase-17-gated") when it has shipped | Warning (WR-03) | Stale desk-check evidence; confusing to a reader |
| schema/workflows/lint.md | Lines 81, 150 | `routing` category absent from CI severity-remap table and category list, despite lint.md declaring itself the authoritative spec for these | Warning (WR-01) | By lint.md's own rule ("drift between this section and the shipped code is a regression"), this is a regression |
| schema/workflows/structured-operations.md | Line 1 (implicit) | Operations Vocabulary verb table (UPDATE/MERGE/SUPERSEDE/ARCHIVE → What It Does) is only in AGENTS.md core, not in the leaf | Info (IN-03) | Leaf not fully self-sufficient for a JIT-loading agent; intentional per inclusion annotation but flagged |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| routing category exits 0 over live tree | `bash bin/lint.sh --category routing` | Exit 0, 0/0/0 findings | PASS |
| LINT_VERSION is 1.8.0 | `bash bin/lint.sh --version` | `1.8.0` | PASS |
| sync-claude byte equality | `bash bin/sync-claude.sh --check` | Exit 0, "OK: AGENTS.md == CLAUDE.md" | PASS |
| Inclusion-audit baseline matches actual | `wc -l < AGENTS.md` vs header N | 287 == 287 | PASS |
| Full CI suite | `bash bin/lint.sh --ci --format json` | Exit 0; 18 pre-existing crossref errors only (not from this phase) | PASS |
| check-neutrality | `bash bin/check-neutrality.sh` | Exit 0 | PASS |
| check-privacy | `bash bin/check-privacy.sh` | Exit 0 | PASS |
| wizard dry-run | `bash bin/init-wizard.sh --dry-run` | Exit 0 | PASS |
| §N residue in corpus (AGENTS.md + schema/reference/ + schema/workflows/) | `grep -rnE '§[0-9]' AGENTS.md schema/reference/ schema/workflows/` | Zero matches | PASS |

### Human Verification Required

#### 1. WR-01: routing category undocumented in lint.md authority file

**Test:** Read schema/workflows/lint.md lines 81 (CI severity-remap table) and 150 (category list). Confirm `routing` is missing from both. Then decide: does this absence block the phase goal?
**Expected:** The phase goal is "every procedural workflow lives in its own standalone file, core verified against inclusion test, agent-parity check." The routing lint itself works (exits 0, enforced in CI). The missing documentation is in an authority file that says "drift between this section and the shipped code is a regression." The question is whether this is a goal-blocking gap requiring a fix commit before phase close, or acceptable polish.
**Why human:** Requires a judgment call on whether an authority file's self-declared regression standard gates phase closure. The mechanical deliverable works; the documentation describing it lags.

#### 2. WR-02: Decision record names non-existent files (operations.md, pipeline.md)

**Test:** Read wiki-cloud/decisions/dr-2026-06-05-workflow-extraction.md lines 36-37. Confirm they say `schema/workflows/operations.md` and `schema/workflows/pipeline.md`, neither of which exists (actual file: `structured-operations.md`; §10 folded into `ingest.md`).
**Expected:** Correct lines would read: "§9 → `schema/workflows/structured-operations.md`" and "§10 → folded into `schema/workflows/ingest.md` (Pass 0–4 + Append-Then-Synthesize)". The DR is the canonical "why is the wiki shaped this way" record for this phase.
**Why human:** A factually wrong DR is an information-integrity issue, but the wiki structure itself is correct. Whether fixing it is required before phase close (rather than as a quick follow-on) requires a judgment call.

#### 3. WR-03: agent-parity.md desk-check describes pre-extraction state

**Test:** Read docs/reference/agent-parity.md lines 103 and 115. Confirm they say "the ingest workflow row is marked 'Future home: `schema/workflows/ingest.md`' with a '(Phase 17)' annotation" and "the inline workflow content in AGENTS.md is still the 'live' text in Phase 17 cycle 4."
**Expected:** The actual AGENTS.md has no "Future home" text; the routing table row is unconditional; the inline workflow content is gone. The desk-check describes a state that no longer exists.
**Why human:** The desk-check verdict (PASS) is still correct — the judge evaluated the pre-extraction state and found the routing table unambiguous. But the evidence record describes the wrong state. Whether this requires a correction before phase close is a judgment call.

### Gaps Summary

No goal-blocking gaps found. The headline deliverable (`bash bin/lint.sh --category routing` exits 0 over the live tree) is verified. All 9 WF requirements have implementation evidence. All 5 ROADMAP success criteria are met.

The three items requiring human review (WR-01, WR-02, WR-03) are documentation-accuracy issues found by the code review. They do not break any automated gate, do not cause incorrect behavior, and do not prevent an agent from using the extracted workflow files. The REVIEW itself characterized the mechanical core as "sound" and confirmed the routing lint, byte-equality, and content fidelity empirically before listing these as warnings.

The verifier's assessment: all three are polish-level fixes. However, WR-01 has the highest friction because lint.md explicitly declares itself the authoritative spec and says "drift is a regression" — which is then violated by this phase. If that self-declared standard is taken literally, WR-01 is a spec inconsistency that the deliverable itself created.

Human decision requested on whether to close with these three as known follow-on items or require fix commits before marking the phase complete.

---

_Verified: 2026-06-07T20:10:00Z_
_Verifier: Claude (gsd-verifier)_

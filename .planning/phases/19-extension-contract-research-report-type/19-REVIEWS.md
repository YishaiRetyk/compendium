---
phase: 19
reviewers: [codex]
reviewed_at: 2026-06-10T22:21:23+03:00
plans_reviewed: [19-01-PLAN.md, 19-02-PLAN.md, 19-03-PLAN.md, 19-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 19

## Codex Review

## Summary

The plans are strong overall: they decompose Phase 19 into clear schema, tooling, lint, audit, and retro-classification work, with good traceability to EXT/RPT requirements and explicit safeguards around neutrality, routing, byte-sync, and the dangerous D-08/sweep coupling. The biggest risk is not conceptual coverage but execution ordering: Plan 04 can race ahead of Plan 03 even though `source_type: research-report` depends on Plan 03’s lint enum change, and Plan 03’s lint check depends on Plan 04’s source-summary reclassification before D-08 can actually detect the two reports as research reports.

## Strengths

- Clear requirement mapping: EXT-01..03 and RPT-01..06 are all represented.
- Good separation of concerns: contract docs, provenance/audit support, lint enforcement, and wiki mutations are split cleanly.
- Strong handling of template-public neutrality with repeated checks and placeholder guidance.
- The D-08 anti-laundering rule is correctly treated as a mechanical CI gate, not just documentation.
- Source summary self-citations are explicitly protected from the `direct` → `derived` sweep.
- The `#r<n>` resolver design is simple and appropriate: multiple bibliography headers, positional bullets, graceful failure.
- The plans correctly preserve the no-web-research and no-auto-promotion boundaries.

## Concerns

- **HIGH:** Plan 03 and Plan 04 ordering is under-specified. Plan 03’s D-08 check only fires for sources whose summary frontmatter already says `source_type: research-report`, but that frontmatter change is in Plan 04. If Plan 03 runs before Plan 04, provenance lint may pass without actually proving the sweep is complete.

- **HIGH:** Plan 04 says it can run in parallel with Plan 03, but its `source_type: research-report` values require Plan 03’s D-09 enum change to avoid lint failure. This contradicts the “parallel Wave 2” claim.

- **MEDIUM:** Plan 03’s acceptance count says 97 markers, but the research text also contains inconsistent counts: 168 in CONTEXT, 97 in RESEARCH, and per-page counts that appear to sum differently in places. The plan needs one canonical machine-checkable count.

- **MEDIUM:** Plan 04’s PDF registry intentionally collapses two Mistral URLs into one `r9`, but the resolver resolves bullets, not URLs. That is defensible, but the registry entry currently only links the news URL and drops the pricing URL from the rendered entry, weakening fidelity to the raw bibliography.

- **MEDIUM:** Plan 02’s `derived-report` selector selects any claim citing a research-report source, not specifically claims with `support_type: derived`. That may be acceptable, but the name and RPT-04 wording imply derived research-report claims. If a future bad `direct` marker exists, audit selection should probably still include it, but documentation should say “claims citing research-report sources,” not only “derived claims.”

- **LOW:** `grep -c "r[0-9]*::"` can overcount if comments or text include similar tokens. It is probably fine here, but `grep -E '^- r[0-9]+::'` would be safer.

- **LOW:** Plan 01’s evaluated candidates rows for PDF/video say “Acquisition only,” but PDF also introduces degraded-scan epistemic guidance in Phase 20. That may change epistemic default, so the row should avoid prematurely locking the dimension assessment.

## Suggestions

- Make Wave 2 sequential: `19-03` and `19-04` should not be parallel. Prefer either:
  - Plan 04 source-summary `source_type` changes happen before Plan 03 D-08 verification, or
  - merge Plan 03 and Plan 04 into one atomic Wave 2 operation.

- Add an explicit verification after both Plan 03 and Plan 04:
  ```bash
  bash bin/lint.sh --category provenance
  grep -r "|direct|" wiki-cloud/entities wiki-cloud/concepts wiki-cloud/comparisons wiki-cloud/overviews \
    | grep "src-2026-06-09-pdf-to-text-llm-ingestion-sota\|src-2026-04-16-claude-code-frameworks-report" | wc -l
  ```

- Add a negative test for D-08, even temporary/manual: create or simulate a non-source page marker with `[prov:<research-report>#...|direct|...]` and confirm lint errors.

- In Plan 04, preserve both Mistral URLs in `r9`, either by including both links in one entry or splitting into URL-level entries and documenting that registry numbering is URL-based instead of bullet-based.

- Replace brittle registry counts with anchored checks:
  ```bash
  grep -Ec '^- r[0-9]+::' <file>
  ```

- Update Plan 02/audit.md wording so `derived-report` means “claims citing research-report sources,” while noting that malformed `direct` uses are intentionally included for audit visibility.

## Risk Assessment

**Overall risk: MEDIUM.** The architecture is sound and the plans are detailed enough to execute, but the Wave 2 dependency issue is real: lint enforcement, source reclassification, and provenance sweeping are mutually coupled. If the execution order is corrected and the final full lint/provenance checks run after both Plans 03 and 04, the residual risk drops to low.

---

## Consensus Summary

Single reviewer (Codex) — no cross-reviewer consensus available. Findings below are from one independent AI system; treat HIGH items as priority candidates for `/gsd-plan-phase 19 --reviews`.

### Top Concerns (by severity)

1. **HIGH — Wave 2 ordering under-specified:** Plan 03's D-08 lint check only fires for sources whose summary frontmatter says `source_type: research-report`, but that frontmatter change lives in Plan 04. Run order Plan 03 → Plan 04 lets provenance lint pass without proving the sweep is complete; run order Plan 04 → Plan 03 hits the D-09 enum gap. The "parallel Wave 2" claim is contradicted — Wave 2 should be sequential or merged into one atomic operation.
2. **MEDIUM — Marker count inconsistency:** 168 (CONTEXT) vs 97 (RESEARCH) needs one canonical machine-checkable count in Plan 03.
3. **MEDIUM — r9 dual-URL fidelity:** PDF registry collapses two Mistral URLs into one entry but only records one URL.
4. **MEDIUM — `derived-report` selector naming:** selects claims citing research-report sources, not strictly `derived` claims; documentation wording should match.

### Divergent Views

N/A — single reviewer.

---

## Resolution (2026-06-10)

All concerns addressed inline in the plans (no replan):

| Concern | Severity | Fix |
|---------|----------|-----|
| Wave 2 ordering circular | HIGH | Plan 19-04 moved to Wave 3 with `depends_on: 19-03`; sequencing rationale added to both plans' objectives; Plan 04 Task 2 gained a phase-final combined gate (full lint + zero-residual grep + D-08 negative test); Plan 03's vacuous-D-08 status made explicit; ROADMAP wave annotation updated to 3 waves |
| Marker count inconsistency (168 vs 97) | MEDIUM | Plan 03 Task 2 now declares the live grep as canonical (97 at planning time; CONTEXT's 168 superseded), captures the pre-sweep count, and binds acceptance to residual count 0 |
| r9 dual-URL fidelity | MEDIUM | Plan 04 registry spec now requires BOTH Mistral URLs in the r9 entry, read verbatim from the raw source bullet; acceptance criterion added |
| `derived-report` selector wording | MEDIUM | Plan 02's audit.md paragraph reworded: selector = "claims citing research-report sources" regardless of support type; malformed `direct` markers intentionally included for visibility |
| Brittle `grep -c "r[0-9]*::"` | LOW | Replaced with anchored `grep -Ec '^- r[0-9]+::'` in Plan 04 acceptance/verification and VALIDATION.md |
| Premature "Acquisition only" lock-in | LOW | Plan 01's pdf/video candidate rows marked *provisional* with a note that Phases 20/21 finalize verdict and dimensions via contract walk-through |

---

## Codex Re-Review — Validation Pass (2026-06-10, Round 2)

All 7 Round-1 concerns verdict: **RESOLVED**. Codex confirms the D-08/D-09 coupling logic is now sound and Plan 04's final full lint + residual grep is the right end-to-end gate.

### New Issues (Round 2)

| # | Severity | Finding | Orchestrator verification |
|---|----------|---------|---------------------------|
| R2-1 | MEDIUM | Plan 03 Task 1 still says D-08 "will emit errors" before the sweep — stale under fixed sequencing (D-08 is vacuous until Plan 04 sets the frontmatter) | Confirmed — stale note at end of Task 1 action |
| R2-2 | MEDIUM | Plan 04 acceptance `grep "UPDATE.*src-2026-06-09" wiki-cloud/log.md` cannot match: the UPDATE header and `source:` line are separate lines | Confirmed — header line has page title, source ID is on the next block line |
| R2-3 | MEDIUM | D-08 negative test is not a hard gate: `\|\| echo "OK"` always exits 0; should `exit 1` on unexpected lint success and grep for the D-08 error text | Confirmed |
| R2-4 | LOW | Negative test locator `#sec-1` isn't the documented `#sec:<name>` syntax | Confirmed (cosmetic — D-08 keys on support type) |
| R2-5 | LOW | `git checkout <file>` is a broad revert for test cleanup | Accepted as-is (Plan 04 doesn't otherwise edit that file) |
| R2-6 | LOW | ROADMAP "Plans: 4 plans (3 waves)" appears twice | **False positive** — artifact of the validation prompt including the phase section twice; the file has exactly one occurrence |
| R2-7 | LOW | agent-skills percentage inconsistent: 4/22 (~18%) vs 2/22 (9%) in Plan 03 | Confirmed — and ground truth is **3/23 (~13%)** (0 PDF-citing + 3 frameworks-citing of 23 total markers); conclusion (stays `sourced`) unchanged |

### Additional findings from orchestrator ground-truth verification (not visible to Codex)

| # | Severity | Finding |
|---|----------|---------|
| GT-1 | HIGH | Plan 03 lists `wiki-cloud/concepts/agent-skills.md` and `wiki-cloud/entities/subagents.md` — **both paths are wrong**. Actual: `wiki-cloud/overviews/agent-skills.md`, `wiki-cloud/concepts/subagents.md`. Wrong paths appear in frontmatter `files_modified`, task `<files>`, sed file lists, and read_first. sed would exit non-zero / skip; Plan 04's negative test `>>` to the nonexistent concepts/ path would silently create a stray file |
| GT-2 | INFO | Canonical pre-sweep count re-confirmed live: 97 report-citing `\|direct\|` markers across the four page directories; agent-skills.md has 0 PDF-citing markers, so it belongs only in the frameworks sed list |

### Residual Risk (Codex): MEDIUM — drops to LOW once R2-2 and R2-3 are fixed. Orchestrator adds GT-1 as a must-fix before execution.

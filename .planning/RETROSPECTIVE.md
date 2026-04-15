# Retrospective: LLM Wiki Compiler

Living document. One section per shipped milestone; cross-milestone trends at the bottom.

---

## Milestone: v1.0 — LLM Wiki Compiler MVP

**Shipped:** 2026-04-15
**Phases:** 6 | **Plans:** 24 | **Tasks:** 44 | **Timeline:** 9 days (2026-04-06 → 2026-04-15)

### What Was Built

A full v1 starter kit for an LLM-maintained Obsidian wiki: agent-agnostic 1,178-line AGENTS.md schema (16 sections), five page-type templates with worked Kahneman examples, claim-level provenance syntax, structured operations vocabulary (UPDATE/MERGE/SUPERSEDE/ARCHIVE) with a deterministic bash validator, multi-pass ingest pipeline with `bin/ingest.sh`, query/write-back workflow with `bin/search.sh`, comprehensive `bin/lint.sh` (structural + staleness + contradiction + drift), and decision record page type with three-tier reflect workflow.

### What Worked

- **Schema-first phase ordering.** Building the schema (Phase 1) before any content (Phase 2+) meant every downstream phase had a single source of truth to extend rather than renegotiate. Section 11.x workflow slots made later phases feel like filling in templates.
- **Two real validation ingests in Phase 3.** The article + journal-entry combo caught privacy-separation and granularity-adaptation bugs that synthetic fixtures would have missed.
- **Deterministic validators (bash + Python3 inline).** `bin/validate-op.sh` and `bin/lint.sh` using inline Python3+PyYAML kept the stack dependency-free while giving the LLM precondition/postcondition checks it can actually trust.
- **Append-then-synthesize update policy.** Decided in Phase 03, survived unchanged through Phases 4–6. Append-first avoided destructive merge bugs during incremental updates.
- **Diff-pass-drives-selection.** Plans listed candidate pages but merge targets were decided from the actual diff. Produced better judgment calls (e.g. splitting prospect-theory and loss-aversion into separate concept pages).

### What Was Inefficient

- **REQUIREMENTS.md bookkeeping drifted from reality.** Nine Pending flags (QURY + SOPS) survived through verification despite phase VERIFICATION.md passing all truths; required a separate quick task (260415-gzu) during milestone completion to reconcile. SUMMARY.md `requirements_completed` frontmatter was inconsistently populated — 15 requirements verified but not echoed.
- **Provenance marker count drift.** Article ingest produced 20 markers vs 8–15 target. No gate caught this; accepted via human semantic review. A mechanical soft-ceiling check would be cheap.
- **Deferred Obsidian renders.** Dataview queries and graph view were never opened in Obsidian proper during v1.0 — pure markdown parsing only. Convention correctness is not rendering correctness.
- **Phase 04/05/06 Nyquist gaps.** Partial coverage slipped through because audit only ran at milestone end. Moving audit to phase transition would catch earlier.

### Patterns Established

- **Inline Python3+PyYAML heredoc** over separate script files for validator logic (keeps operator tools in `bin/` single-file).
- **`knowledge_domain` vs `domains`:** staleness policy bucket is orthogonal to topical classification.
- **Severity-tiered lint with category grouping** inside each severity level — makes drift findings scannable.
- **Decimal phase numbers** reserved for insertions; integer numbering never restarts across milestones.
- **Skip-criteria on reflect triggers.** Explicitly enumerating trivial-merge / routine-stale skips prevents decision-record inflation.

### Key Lessons

- **Traceability tables need a mechanical check.** Manual Pending→Complete flipping during verification drifted; a `requirements-sync` command comparing VERIFICATION.md truths against REQUIREMENTS.md status would eliminate this class of debt.
- **Human-in-the-loop gates need explicit deferral tracking.** "Deferred: open in Obsidian" was recorded but not surfaced until milestone audit. A persistent `deferred_verification` list visible during `/gsd:progress` would close the loop.
- **Single source of truth for AGENTS.md sections.** Cross-plan edits to sections 9, 11.x, and 12 worked because each plan owned non-overlapping line ranges — would have collided if parallelized without that discipline.

### Cost Observations

- **Model mix:** Not instrumented. v1.0 ran on quality profile (Opus) throughout — no explicit sonnet/haiku routing data captured.
- **Sessions:** Multiple sessions across 9 days; exact count not tracked.
- **Notable:** 44 tasks across 24 plans averaged ~3 minutes per plan execution (per STATE.md performance table). The sub-minute Phase 05 P04 and 1-minute Phase 01 P03 suggest end-of-phase validation plans are cheap once earlier plans are tight.

---

## Cross-Milestone Trends

(To be populated as additional milestones ship.)

### Shipped Milestones

| Version | Name | Shipped | Phases | Plans | Days |
|---------|------|---------|--------|-------|------|
| v1.0 | LLM Wiki Compiler MVP | 2026-04-15 | 6 | 24 | 9 |

### Recurring Patterns

- TBD after v1.1+

### Recurring Inefficiencies

- TBD after v1.1+

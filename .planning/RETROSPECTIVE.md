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

## Milestone: v1.1 — Shareability

**Shipped:** 2026-06-02
**Phases:** 15 directories (Phases 7–13.2) | **Plans:** 52 | **Commits:** 382 | **Span:** 2026-04-15 → 2026-06-02 (~48 days)

### What Was Built

A shareable starter kit: neutral public template (Phase 7), two-track wizard/manual setup with byte-equality CI (Phase 8), collaborative PR workflow + three-job CI lint gate (Phase 9), brownfield vault onboarding scan/bootstrap/suggest/verify (Phases 10–11), the complementary-systems boundary + three-layer model (Phases 12, 12.1), a local pre-commit write gate (Phase 12.2), a claim-faithfulness audit (Phase 13), docs finalization + Obsidian starter (Phase 13.1), and a dedicated end-of-line closure verification gate (Phase 13.2).

### What Worked

- **Mechanical closure gate.** `bin/requirements-sync.sh --strict --require-complete` turned milestone closure into a single deterministic check (0 drift of 97, all 97 Complete) instead of a manual audit — built mid-milestone as backlog 999.7 precisely because the closure phase would need it.
- **Edit-on-drift discipline.** The CLOSE-03/04 consistency pass found zero drift and zero scope leaks, leaving every file byte-unchanged — proof the canonical surface stayed coherent throughout, not patched at the end.
- **Honest deferral over fake-green.** Codex agent-parity was blocked by a host AppArmor user-namespace restriction; it was recorded as blocked-on-host-runtime (with the Claude-vs-golden EXACT diff carrying the verdict) rather than fabricated as a pass.
- **Separating two human checkpoints from autonomous work** let the closure phase run almost entirely unattended, pausing only for the GUI Obsidian render and the milestone-archive go-ahead.

### What Was Inefficient

- **Tooling drift.** The installed `gsd-tools.cjs` predates the `gsd-sdk query` interface the current workflows assume, so execute-phase and complete-milestone had to be driven manually. Faithful but slower; a tooling-version pin would remove the friction.
- **Stale milestone audit.** The 2026-04-30 `v1.1-MILESTONE-AUDIT.md` (`gaps_found`) lingered as a scary-looking artifact until its own superseded-note clarified Phase 13.2 was the authoritative closure audit. A fresher re-audit before closure would have avoided the second-guess.
- **CLOSE-02 over-claim risk.** The verifier report needed an explicit, guarded two-part framing (scenarios re-run *now* vs ledger-consistency, NOT a behavioral re-run) to avoid conflating documentation consistency with regression-testing — caught by cross-AI review, but only after a replan cycle.

### Patterns Established

- **Decimal closure phase (X.2) as a milestone end-of-line gate** — a dedicated phase whose only job is verify + reconcile + archive, distinct from the docs-finalization phase (13.1).
- **Paired closure artifacts** — a plan-authored `VERIFICATION.md` plus an independent `VERIFIER-REPORT.md` that re-runs the gates, mirroring prior-phase format.
- **STEP-0 hard gate on human input** — a human-reported render that can *fail* the milestone (divergent counts keep the drift row), not just be recorded.

### Key Lessons

- Build the mechanical gate the closure phase needs *before* the closure phase (999.7 → 13.2).
- A superseded artifact must shout its supersession in its own frontmatter, or it will be misread as live state at the worst moment.
- When a human checkpoint gates a milestone, give the operator a pre-filled, copy-paste-ready artifact (the scratch note) — it converts a vague "go render in Obsidian" into a 2-minute task.

### Cost Observations

- Model mix: predominantly Opus for orchestration + execution (this milestone's closure was driven inline rather than via subagents due to the tooling mismatch).
- Notable: the closure phase was almost fully autonomous apart from two `autonomous: false` human checkpoints (Obsidian render, milestone archive).

---

## Cross-Milestone Trends

(To be populated as additional milestones ship.)

### v1.0 → v1.1

| Dimension | v1.0 MVP | v1.1 Shareability |
|-----------|----------|-------------------|
| Phases | 6 | 15 (incl. 4 decimal insertions) |
| Plans | 24 | 52 |
| Span | 9 days | ~48 days |
| Focus | Build the compiler | Make it shareable + trustworthy + closable |
| Closure | Manual audit | Mechanical `requirements-sync --require-complete` gate |

### Shipped Milestones

| Version | Name | Shipped | Phases | Plans | Days |
|---------|------|---------|--------|-------|------|
| v1.0 | LLM Wiki Compiler MVP | 2026-04-15 | 6 | 24 | 9 |

### Recurring Patterns

- TBD after v1.1+

### Recurring Inefficiencies

- TBD after v1.1+

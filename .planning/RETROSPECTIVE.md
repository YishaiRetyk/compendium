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

## Milestone: v1.1.1 — Graph Integrity

**Shipped:** 2026-06-04
**Phases:** 1 (Phase 14) | **Plans:** 3

### What Was Built

A correctness patch making the Obsidian graph actually connect: the **uniform piped-link convention** `[[id|Title]]` in §8/§5 + 12 templates, a re-pointed `bin/lint.sh` `linkres` check that validates link *targets* (with `--fix` bare→piped) plus an alias-free `orphan` check (LINT_VERSION 1.6.0), and full remediation of `wiki/` + `examples/` body links. Orphan count 19→0; connected graph human-verified in Obsidian.

### What Worked

- **The human-verify gate caught a false premise before it shipped as "done."** The milestone was planned around self-aliases; the LINK-10 human-verify step proved Obsidian ignores `aliases` for `[[X]]` resolution. The gate did exactly its job — it stopped a plausible-but-wrong approach.
- **Re-plan over patch.** Rather than bolt a fix onto the wrong-premise work, Phase 14 was re-planned from scratch with the prior artifacts quarantined under `_superseded-premise/` — keeping the false trail visible without letting it pollute the live plan.
- **A superseding decision record** (`dr-2026-06-03-uniform-piped-links`) captured both the corrected reality and the rejected alternatives, so the reversal is legible to future readers.

### What Was Inefficient

- The original premise (`filename + aliases`) was never validated against Obsidian's actual behavior before a full phase was planned and executed against it — a cheap upfront check (or reading the Obsidian docs / forum on alias resolution) would have avoided the executed-then-discarded first attempt.
- Cosmetic drift slipped through: the requirements checkboxes were flipped to `[x]` but the traceability table was left at `Pending` (caught and fixed at this close).

### Patterns Established

- **Uniform piped links `[[id|Title]]`** as the single intra-wiki link form — target = `id` (always resolves), display = canonical title. Dissolves the entire class of plural/parens/casing variant-reconciliation problems (display text is cosmetic).
- `linkres` validates link *targets*; `duplicate` (shipped v1.1) detects near-dup *pages* — orthogonal checks.

### Key Lessons

- **Validate the load-bearing premise of a milestone before planning against it**, especially when it's a claim about third-party tool behavior. A 10-minute check would have saved a phase.
- A human-verify success criterion on the *observable outcome* (does the graph connect in Obsidian?) is worth more than any number of mechanical checks against an assumed mechanism.

### Cost Observations

- Model mix: predominantly Opus, driven inline (single-phase patch; no subagent fan-out needed).
- Notable: ~2 calendar days, 75 commits — high commit density for a small phase, reflecting the execute → invalidate → re-plan → re-execute cycle.

---

## Milestone: v1.2 — Schema Architecture

**Shipped:** 2026-06-08
**Phases:** 4 (15–18) | **Plans:** 15

### What Was Built

A self-applied progressive-disclosure refactor: the always-loaded `AGENTS.md`/`CLAUDE.md` monolith (1,689 lines) reduced to a ~287-line resident core via an explicit inclusion test, with the rest extracted into a markdown-authoritative `schema/reference/*.md` + `schema/workflows/*.md` tree. Privacy was re-architected from a per-page §13 rule into the asymmetric two-directory `wiki-cloud/` / `wiki-local/` model enforced as a harness `deny`-read permission; a `routing` lint category (LINT_VERSION 1.8.0) now gates path-ref integrity bidirectionally; and a thin, drift-gated `.claude/skills/` overlay (four pointer-only routers generated by `bin/gen-skills.sh --check`) was added without forking authority away from markdown. 28/28 requirements Complete.

### What Worked

- **Structural enforcement over remembered rules.** Privacy moved from "a rule the cloud model must recall each turn" to a directory boundary + harness permission — the safety property is now true by construction, and the resident core shrank as a side effect.
- **Gate-arming before migration.** Phases led with RED test harnesses (Phase 15's PRIV harness, Phase 18's 10-test skills harness) so the structural change had a Nyquist gate to satisfy rather than a post-hoc check.
- **A generator + `--check` drift gate for derived artifacts.** The skills overlay is generated, not hand-maintained; the `--check` regenerate-diff + structural assertions make "skills add zero authoritative content" mechanically enforced in pre-commit and CI rather than a reviewer's judgment.
- **An inclusion test as the sizing principle.** Treating ~287 lines as an *output* of the test (ambient / unscriptable-unacceptable-miss / dispatch) rather than a line target kept the extraction principled and auditable (a tripwire fires on upward drift).

### What Was Inefficient

- **`phase.complete` mis-advanced to a superseded backlog phase (999.1) at every phase close**, including the milestone boundary — each required a hand-correction of STATE.md. A known recurring tool defect (now documented in memory) rather than a one-off.
- **A prior-phase test hard-coded an exact CI-job count**, so Phase 18's intended new `skills-check` job registered as a cross-phase regression; the regression gate had to distinguish it from pre-existing baseline failures before fixing the stale assertion.
- **`gen-skills.sh` shipped with cwd-relative path resolution** (latent — hook/CI always run from root), caught only by code review; the review's own reproduction briefly corrupted a generated file. Fixed in the `--fix` pass, but it should have anchored to repo root from the start.
- **The milestone-complete CLI miscounted phases (7 vs 4) and produced garbled auto-extracted accomplishments** — the MILESTONES entry needed a full manual rewrite.

### Patterns Established

- **Derived-artifact discipline:** generate + `--check` drift gate + structural assertions, wired into both pre-commit (auto-fix) and CI (hard-fail). Reusable for any future generated surface.
- **Anchor scripts to repo root** (`BASH_SOURCE` → `REPO_ROOT` → `cd`) so they are cwd-independent and their failure mode is a loud error, not silent side-effecting writes.
- **Inclusion test for resident context:** every always-loaded section carries a one-line justification citing its clause; drift is a tripwire, not a target.

### Key Lessons

- **Move safety properties from rules into structure** whenever possible — a directory boundary the harness enforces beats a sentence the model must remember.
- **Baseline before judging regressions:** when prior-phase tests fail after a change, diff against the pre-change commit to separate real regressions from pre-existing debt before touching anything.
- **Don't trust completion CLIs' auto-counts/auto-summaries** at milestone close — verify phase/plan counts and rewrite extracted accomplishments by hand.

### Cost Observations

- Model mix: orchestrator on Opus; executors/verifier/reviewer/fixer on Sonnet (wave-based subagent fan-out, worktree isolation per plan).
- Sessions: phase 18 executed + reviewed + fixed + milestone-closed across one continued session.
- Notable: ~4 calendar days for a 4-phase structural refactor; the heaviest cost was cross-phase regression triage, not the extraction itself.

---

## Milestone: v1.3 — Source Ingestion

**Shipped:** 2026-06-14
**Phases:** 3 (19–21) | **Plans:** 11 | **Commits:** 104 | **Span:** 2026-06-10 → 2026-06-14 (~5 days)

### What Was Built

Three new source ingestion paths designed once via a shared abstraction: the 5-dimension source-type extension contract (acquisition / locator / extraction / drift / epistemics + primary-vs-secondary axis) in `schema/reference/source-types.md`, with `research-report` as the worked secondary instance (second-order `derived`-only provenance, `#r<n>` citation-registry locators, D-08/D-09 lint gates, anti-epistemic-laundering defenses), PDF as an article/paper sub-case (`bin/pdf-extract.sh` olmOCR-2 pipeline, `#p<N>` locators, VLM-hallucination guidance), and video as a transcript sub-case (tool-generic acquisition runbook, `#t` locators, link-rot drift stance). Each phase closed with a real-artifact end-to-end validation ingest.

### What Worked

- **Contract-first, instances-second.** Designing the extension contract from the three real cases (not in a vacuum) and then applying its own decision rule to PDF and video — both landed as *sub-cases*, not new types — kept the type system at 7 entries instead of 9. The contract paid for itself within the same milestone.
- **Real-artifact validation gates per phase.** Every phase ended with a genuine ingest (retro-classified reports, a real PDF, a real 3-speaker YouTube interview). The video ingest's source-scoped audit (37 claims, 0 `insufficient-locator`) made the `#t` locator convention's correctness non-vacuous.
- **Verification catching vacuous gates.** The Phase 19 verifier caught that D-08 passed vacuously on table-cell markers (`\|direct\|` escaped-pipe blind spot) and forced a gap-closure wave (19-05) — the second time a "green" gate was proven hollow and fixed before close.
- **Code review as a first-class phase step.** The Phase 19 review found the headline audit tier was 71% unresolvable (`#sec:` slug mismatches predating the phase) — a silent-degradation defect no test caught. The fix (token-subsequence fallback + resolvable-ratio tripwire) hardened the audit for every future source type.

### What Was Inefficient

- **External model dependency churn mid-phase.** Phase 20 paused when the `richardyoung/olmocr2` Ollama repull produced garbage (M-RoPE bug); the working path moved to a bartowski GGUF on a pinned Ollama version. Acquisition runbooks now note versions, but the phase absorbed a full day of tool triage that wasn't ingestion work.
- **Diarization stack pinning.** The Phase 21 STT run needed an unplanned `torchcodec==0.10.0` pin to unblock pyannote under torch 2.10 — same class of external-dependency friction.
- **`gsd phase.complete` mis-advance recurring** (STATE pointed at superseded backlog 999.1 at every phase close) — hand-corrected each time; the tool defect is documented in memory but still costs a correction per phase.
- **Locator debt discovered late.** The `#sec:` slug mismatches that hollowed the derived-report audit tier were authored at v1.0/v1.1 ingest time but only surfaced when Phase 19 built machinery on top of them. Earlier resolvable-ratio checks would have caught them at authoring time.

### Patterns Established

- **Sub-case-over-new-type default:** a new `source_type` is justified only if it changes ≥1 of the 5 contract dimensions; otherwise document a sub-case convention (PDF, video both confirmed this way).
- **Acquisition tooling stays outside the repo** — the milestone ships conventions + at most thin glue (`pdf-extract.sh`); heavy tools (STT CLI, Ollama models) live in their own projects and are referenced tool-generically on template-public surfaces.
- **Tiered epistemic defaults by extraction quality** (clean-born-digital → `sourced`; degraded/VLM-extracted → `tentative` + spot-verification) rather than one blanket trust level.
- **Hollow-audit tripwire:** when <50% of sampled locators resolve, the audit warns loudly — a meta-check that the verification machinery itself is functioning.

### Key Lessons

- **Verify the verification machinery.** Two independent incidents (vacuous D-08 table-cell gate; 71% unresolvable audit tier) show a green gate can be structurally incapable of failing. Gates need at least one injected-failure proof (non-vacuity check) before they count as shipped.
- **Second-order sources need mechanical anti-laundering enforcement** — the `derived`-only mandate is only real because lint errors on violations; a documented convention alone would have eroded.
- **Pin external model/tool versions in runbooks at authoring time** — Ollama model tags and Python-stack versions drifted underneath two of three phases.

### Cost Observations

- Model mix: quality profile restored 2026-06-11 (the `resolve_model_ids: "omit"` defect had silently downgraded all GSD agents to Sonnet before then); Phases 20–21 ran orchestrator-on-Opus.
- Notable: ~5 calendar days for 3 phases / 11 plans; the dominant unplanned cost was external-tool triage (olmOCR repull, torchcodec pin), not schema or wiki work.

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
| v1.1 | Shareability | 2026-06-02 | 15 | 52 | ~48 |
| v1.1.1 | Graph Integrity | 2026-06-04 | 1 | 3 | ~2 |
| v1.2 | Schema Architecture | 2026-06-08 | 4 | 15 | ~4 |
| v1.3 | Source Ingestion | 2026-06-14 | 3 | 11 | ~5 |

### Recurring Patterns

- **Mechanical enforcement over remembered rules / manual audits** — each milestone has pushed a correctness property into a gate or structure: `requirements-sync --require-complete` (v1.1), `linkres` target validation (v1.1.1), `routing` lint + `gen-skills --check` + privacy-as-harness-permission (v1.2), D-08 derived-never-direct + hollow-audit tripwire (v1.3).
- **Gate-arming with RED test harnesses before a structural change** (v1.1.1 remediation, v1.2 Phases 15/18).
- **Superseding decision records** capture reversals and rejected alternatives legibly (v1.1.1 piped-links DR, v1.2 privacy + skills DRs).
- **Design-once, instantiate-N abstractions extracted from real cases** — the v1.3 extension contract was distilled from three concrete candidates, then immediately re-applied to classify two of them as sub-cases.

### Recurring Inefficiencies

- **Cosmetic/tracking drift surfaced at close** — requirements traceability left `Pending` while checkboxes were flipped (v1.1.1); STATE/MILESTONES auto-fields wrong at close (v1.2). Tracking artifacts lag the real work and need a manual reconciliation pass.
- **`phase.complete` mis-advances STATE to the superseded backlog 999.1** at phase/milestone close — recurring across v1.1.1, v1.2, and v1.3; always hand-corrected.
- **Premises/assumptions validated late** — third-party tool behavior (v1.1.1 Obsidian aliases) and script cwd-assumptions (v1.2 `gen-skills.sh`) caught at a gate/review rather than upfront.
- **External model/tool version churn absorbed mid-phase** — olmOCR Ollama repull breakage and the torchcodec pin (v1.3) each cost unplanned triage; runbooks now record pinned versions, but acquisition-adjacent phases should budget for it.

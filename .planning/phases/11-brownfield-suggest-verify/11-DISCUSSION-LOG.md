# Phase 11: Brownfield Suggest + Verify - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-19
**Phase:** 11-brownfield-suggest-verify
**Areas discussed:** Per-script judgment semantics, Suggest generation + op_hash + applied.log, Verify subcommand scope + bootstrap_stage transitions, AGENTS.md §11.5 workflow prose structure, Plan structure + test strategy

---

## Area 1 — Per-script judgment semantics

### Q1.1: 01-page-typing.sh — how should it handle pages the D-16 classifier returned as `unknown`?

| Option | Description | Selected |
|--------|-------------|----------|
| Skip + list in REPORT.md (Recommended) | Apply `type:` only on `high` confidence; `medium`/`low`/`unknown` → REPORT.md 'Needs user judgment' | |
| Apply on high+medium, skip low+unknown | Aggressive: apply `type:` on `high` AND `medium` | |
| Apply on all non-unknown, comment low | Most aggressive: write `type:` on high/medium/low; comment low-confidence inline | |
| Interactive prompt per page | Per-page y/n prompt (breaks dry-run / CI replay) | |
| **Other (freeform)** | **User rewrote the question** | **✓** |

**User's choice:** Rewrote the architecture. Neither "skip forever" nor "auto-apply with confidence tiers" alone — introduced a THREE-LAYER model:
1. **01-page-typing.sh** = deterministic discovery + clustering + manifest generation + apply-from-manifest.
2. **`bin/brownfield.sh review-typing`** = orchestration entrypoint. Small-batch TTY (approve/reject/inspect/override per cluster). Large-batch pivots to AI-guided review via generated prompt + manifest.
3. **AI-assisted review** = layer on top of structured artifacts (candidates.yaml + decisions.yaml). Not inside the CLI (preserves BRWN-16).

Confidence policy:
- `high` → auto-apply
- `medium` → behind threshold flag OR send to review (planner's empirical call)
- `low` → review queue
- `unknown` → always review queue
- Review outputs → `.brownfield/page-typing-decisions.yaml`
- Apply step → reads manifest only, non-interactive, idempotent

**Notes:** *"Review may be interactive and AI-guided; apply must always be deterministic."* This principle reshapes the whole phase. Page-typing stays interactive where judgment matters without locking that interactivity into a mutation script.

---

### Q1.2: 02-provenance-bootstrap.sh — at what granularity should `[epistemic:: inferred]` be attached?

| Option | Description | Selected |
|--------|-------------|----------|
| TL;DR + Key Facts bullets only (Recommended) | Top-level bullets in scannable sections only | ✓ |
| All bullets across all sections | Tag every bullet except Sources | |
| Page-level `[epistemic:: inferred]` note only | Single italicized note under TL;DR; no per-claim tagging | |
| Paragraphs with ≥2 factual sentences | Heuristic paragraph-level tagging | |

**User's choice:** Option 1 — TL;DR + Key Facts top-level bullets only.

**Notes:** Align with progressive-disclosure model — TL;DR + Key Facts are the scan-first surfaces. Top-level bullets are the cleanest "claim units." Keeps diff small + reviewable; easy to undo when real `[prov:...]` markers arrive. Avoids polluting Detail (narrative flow; heuristics weakest there). Skip rules: bullets already carrying `[epistemic::...]`, link-only / source-list bullets, questions/tasks/placeholders. Honest report when no eligible bullets found. Page-level `bootstrap_stage: bootstrapped` carries lineage.

---

### Q1.3: 03-cross-link-inference.sh — apply wikilinks or report candidates?

| Option | Description | Selected |
|--------|-------------|----------|
| Report-only to REPORT.md (Recommended) | No writes; candidates to REPORT.md | ✓ |
| Apply exact-title matches only | Insert `[[Title]]` on exact-title word-boundary match | |
| Apply exact-title + aliases | Same + alias matching | |
| Apply with confidence threshold | Score candidates; apply above threshold | |

**User's choice:** Option 1 — report-only. Per-candidate fields: source_page, line_number, matched_text, proposed_target, match_type (exact-title|alias), short_rationale, target_already_linked_from_source. Grouped by source page.

**Notes:** Link-worthiness is rhetorical, not statistical. "Exact title appears" is not enough evidence that a wikilink belongs there. First-mention-only rule makes automatic insertion brittle. Future direction (not v1.1): same report + review manifest pattern as 01-page-typing. For now, strict advisory.

---

### Q1.4: 04-privacy-classification.sh — scope given fail-closed default?

| Option | Description | Selected |
|--------|-------------|----------|
| Scan body for privacy patterns — report only (Recommended) | Scan + REPORT.md; never flip `privacy:` | ✓ |
| Promote to `cloud_safe` if no private patterns found | Auto-promote on clean pages | |
| Scan + log + add suggested `privacy` comment | Inject YAML comment with suggestion | |
| Path-based `cloud_safe` allowlist | User-authored path allowlist file | |

**User's choice:** Option 1 + rename the script: `04-privacy-classification.sh` → `04-privacy-review.sh`. Explicit contract: "classifies only for review priority, not for frontmatter mutation." Never auto-flip `privacy`.

**Notes:** Naming was load-bearing — "classification" implied authoritative mutation. "Review" makes the advisory scope explicit. Future enhancement (not v1.1): user-authored allowlist as explicit override layer; scanner still never promotes.

**Emergent pattern:** The four-script split crystallizes:
- page typing: human review or high-confidence automation (apply class)
- provenance bootstrap: light, high-value claim annotation only (apply class, narrow surface)
- cross-link inference: advisory only
- privacy review: advisory only, fail-closed preserved

---

## Area 2 (follow-up) — Rename, review UX, generation, applied.log

### Q2.1: Rename 04-privacy-classification.sh?

| Option | Description | Selected |
|--------|-------------|----------|
| Rename to 04-privacy-review.sh (Recommended) | Update BRWN-12 wording; ship accurate name | ✓ |
| Keep name + explicit advisory contract | Don't touch REQUIREMENTS.md; add script-header contract | |
| Rename to 04-privacy-scan.sh | Neutral verb; less coupled to "review" framing | |

**User's choice:** Rename to `04-privacy-review.sh`. Amend BRWN-12 wording.

---

### Q2.2: Where does the batched-review UX for 01-page-typing live?

| Option | Description | Selected |
|--------|-------------|----------|
| New subcommand: `brownfield review-typing` (Recommended) | Script = mechanical; subcommand = UX orchestrator | |
| Inside script: `01-page-typing.sh --review` | Mixes mechanical + interactive in one file | |
| No interactive UX — manifest editing only | Hand-edit decisions YAML; no TTY | |
| Separate top-level helper: `bin/brownfield-review.sh` | Factored out of brownfield.sh | |
| **Other (freeform)** | **User refined option 1** | **✓** |

**User's choice:** Option 1 with a three-layer refinement:
- `bin/brownfield.sh review-typing` = orchestration entrypoint (never source of truth).
- Small-batch path: TTY cluster prompts.
- Large-batch path: generate deterministic prompt artifact → AI-guided review via manifest → deterministic apply.
- `01-page-typing.sh --apply` reads manifest only.

**Notes:** "Review may be interactive and AI-guided; apply must always be deterministic." Storage + apply model is one path regardless of review style. Constraints kept to stay Phase-11-sized: simple TTY, simple prompt template, no fancy TUI, no LLM-in-CLI, no skills layer yet.

---

### Q2.3: Suggest generation — static, vault-specific, or hybrid?

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid: static scripts + vault-specific data files (Recommended) | Canonical scripts in `schema/`; data in `.brownfield/` | ✓ |
| Static only — scripts discover vault state at run time | Scripts re-walk vault each invocation | |
| Vault-specific generation | Bake vault data into rendered shell code | |

**User's choice:** Hybrid. Canonical migration logic in `schema/brownfield/migrations/*.sh`; byte-copied to `.brownfield/migrations/`. Vault-specific candidate + decision files in `.brownfield/`. Candidate files carry a metadata header (schema version, tool version, generated_at, vault_root, source_script_hash).

**Notes:** Cleanly separates logic from state. Most testable (byte-equal scripts + exact candidate-file shapes). Best fit for AI-guided review (AI needs structured candidate data). Keeps apply deterministic (review produces manifest; apply reads manifest; no hidden rescans).

---

### Q2.4: applied.log scope + format?

| Option | Description | Selected |
|--------|-------------|----------|
| Single `.brownfield/applied.log`, markdown blocks (Recommended) | One file; strict block schema; UTC timestamps | ✓ |
| Single log, JSON Lines | Machine-readable; less human-auditable | |
| Per-script logs: `.brownfield/applied/<script>.log` | Fragments history | |
| No separate log — append to REPORT.md | Conflates discovery with execution history | |

**User's choice:** Option 1 with a precise contract:
- Apply-class (01, 02): append on real `--apply` only.
- Advisory-class (03, 04): append on advisory execution with findings or completed review pass.
- Plain dry-run candidate regeneration: NO append.
- Strict block schema for apply (mode, op_hash, exit_code, prereq_check, inputs with sha256s, files_touched/created/updated/skipped, changes, summary).
- Strict block schema for advisory (mode, op_hash, exit_code, prereq_check, mutations: none, report_section, summary).

**Notes:** Include input hashes for apply runs (load-bearing traceability: "what review state produced these mutations?").

---

## Area 2 (closure) — op_hash, prereqs, 02-review-or-not

### Q3.1: What goes into `# op_hash: <sha256>`?

| Option | Description | Selected |
|--------|-------------|----------|
| Script semantics only (Recommended) | Canonical body + schema version; stable across vaults | ✓ |
| Script + data-file input hashes | Changes every run; duplicates applied.log info | |
| Script + normalized vault state | Expensive; changes on unrelated vault edits | |

**User's choice:** Option 1. op_hash answers "what operation definition is this script implementing?" NOT "what exact vault state did this run consume?" — that's applied.log's job. Pair with explicit comment: `# op_hash_scope: canonical-script-body + data-schema-version`. Future: separate `run_hash` if needed.

---

### Q3.2: Should scripts check prerequisites?

| Option | Description | Selected |
|--------|-------------|----------|
| Soft check with warn-only (Recommended) | Read applied.log; warn if prereq missing; proceed | |
| Hard check — refuse if prereqs missing | Non-zero exit; contradicts BRWN-13 | |
| No check — fully independent | Matches BRWN-13 literally | |
| Script-specific: 02 depends on 01, others independent | Middle ground | |
| **Other (freeform)** | **User refined: state-based, not log-based** | **✓** |

**User's choice:** Script-specific soft checks, based on current **vault state** (not applied.log history).
- 01: no check.
- 02: soft readiness warn — "WARN: N bootstrapped pages still have empty type:. Proceeding anyway."
- 03: no check.
- 04: no check.

**Notes:** *"Check readiness, not history."* applied.log is supporting context, never authoritative dependency source. User may have valid `type:` from bootstrap already; history-based prereq would misfire.

---

### Q3.3: Does 02-provenance-bootstrap need a review-and-apply layer?

| Option | Description | Selected |
|--------|-------------|----------|
| Direct apply — no review layer (Recommended) | Narrow, mechanical surface; preview report + --apply | ✓ |
| Symmetric with 01 — review manifest + apply | Consistency at cost of heaviness | |
| Direct apply + per-page opt-out file | `.brownfield/02-exclude.txt` escape hatch | |

**User's choice:** Direct apply. Discovery writes `provenance-bootstrap-report.yaml` preview; user inspects counts + examples; `--apply` runs deterministically.

**Notes:** Mirroring 01's manifest pattern here would train users to expect manifests everywhere, weakening the apply/advisory distinction. git-reset handles rollback cheaply. Future escape hatch (Option 3) only if real-world heuristic noise emerges.

---

### Q3.4: verify scope + bootstrap_stage `verified` transition?

| Option | Description | Selected |
|--------|-------------|----------|
| verify = lint wrapper + stage-transition gate (Recommended) | `--promote` gate flips bootstrapped → verified on pass-list | ✓ |
| verify = pure thin lint wrapper (BRWN-17 minimal) | Never mutates; manual stage edits | |
| verify checks + stamps every page that passes | Auto-flip on every run (risky) | |
| verify stays read-only; separate `promote` subcommand | Clean separation; +1 subcommand | |

**User's choice:** Option 1 with refinement: read-only by default, explicit `--promote` flag to flip. Per-page objective gate:
- Currently `bootstrap_stage: bootstrapped`.
- `type:` set and valid.
- No blocking findings in relevant categories.
- Required type-specific fields present where applicable.
- No pending review decision remains for the page in page-typing flow.

Privacy is NOT a lint category (separate `bin/check-privacy.sh` on public paths only) — verify does not claim to gate on privacy advisory completion. `--promote` carries human sign-off for advisory steps that aren't mechanically provable.

**Notes:** verify = mechanical gate. `--promote` = mechanical gate + explicit human sign-off. Implementation note: phrase verify as "brownfield-relevant lint categories + brownfield-specific review-state checks," not as a literal privacy lint category.

---

## Area 3 — §11.5 shape, review-typing scope, plans

### Q4.1: AGENTS.md §11.5 content shape?

| Option | Description | Selected |
|--------|-------------|----------|
| Full workflow per §11.1-§11.4 pattern, one block per subcommand (Recommended) | Canonical contract; compact; lean | ✓ |
| Compact narrative + deep pointer to docs/reference | Shorter AGENTS; weakens authority | |
| Full workflow for scan/bootstrap/suggest/verify; review-typing + migrations in docs/reference | Subcommand-level only | |

**User's choice:** Option 1 implemented deliberately lean.
- One compact canonical workflow block per subcommand: scan, bootstrap, suggest, review-typing, verify.
- Load-bearing principles in §11.5 body: mechanical-vs-judgment boundary; review-may-be-AI-guided-apply-must-be-deterministic; apply-vs-advisory split; bootstrap_stage lifecycle.
- Migration internals + operator ergonomics → docs/reference.

**Notes:** *"Put decisions, boundaries, and lifecycle in AGENTS; put examples, UX, and operational detail in docs."* Reduces future v1.2 extraction cost because the workflow is already cleanly modularized by subcommand.

---

### Q4.2: review-typing subcommand — Phase 11 scope or deferred?

| Option | Description | Selected |
|--------|-------------|----------|
| Ship review-typing with small-batch TTY + AI-guided handoff doc (Recommended) | TTY for small; prompt artifact for large | ✓ |
| Ship TTY only; defer AI-guided flow to v1.2 | Simpler scope | |
| Ship manifest-editing only — no review-typing subcommand | Absolute minimum | |
| Ship review-typing TTY + prompt-template hook + a Claude Code skill | Expands into skills; wrong coupling point for v1.1 | |

**User's choice:** Option 1 constrained to Phase-11 size. 01-page-typing without usable review surface is only half a feature. Large-vault brownfield is exactly where AI-guided review matters most. No LLM calls in `bin/brownfield.sh` (preserves BRWN-16).

Constraints to keep Phase-11-sized:
- Simple TTY (cluster-by-cluster primitives).
- Simple prompt template pointing at candidates + decisions.
- AI edits manifest only (not pages).
- No fancy TUI. No LLM integration in CLI. No skills yet.

Deferred to later phases: skills, Claude-only wrappers, 999.4 extraction coupling.

---

### Q4.3: Plan structure + test strategy?

| Option | Description | Selected |
|--------|-------------|----------|
| 5 plans: harness + suggest + 4 scripts + verify/review + docs (Recommended) | Matches Phase 10 grain | ✓ |
| 3 bigger plans: infra + scripts + docs | Fewer plans; bigger diffs | |
| 6 plans: harness + suggest + 1 per migration script + verify/review/docs | Finest grain; per-script isolation | |
| Let planner decide after research pass | Defer structure | |

**User's choice:** Option 1 default with explicit escape hatch: if 01-page-typing is materially larger than 02+03+04 combined after research, planner splits 11-03 into 11-03a + 11-03b. Don't pre-plan that split; trust planner post-research.

Test strategy: 11-01 locks the RED contract suite, not just harness scaffold. Fifteen concrete RED targets listed including suggest byte-copy, candidate-file shapes, per-script apply/advisory contracts, review-typing branching, applied.log schema, op_hash stability, verify/--promote gate, state-based prereqs, and ONE end-to-end happy-path test (`suggest → review-typing → 01 --apply → 02 --apply → 03 advisory → 04 advisory → verify → verify --promote`).

Fixture design (5 fixtures): small ambiguous-pages vault for TTY; larger vault to trigger AI-handoff; vault with pre-existing valid `type:` (prove state-based prereq); sensitive-string vault (04 surface); already-tagged-bullets vault (02 skip behavior).

---

## Claude's Discretion

- `medium`-confidence default for 01-page-typing: planner's call (auto-apply behind flag vs review queue).
- Exact threshold for small-batch vs large-batch review-typing mode.
- Exact form of the AI-handoff prompt template.
- Internal `bin/lib/` module structure (extend `brownfield_classify.py` vs new modules for clustering + provenance).
- Whether to split 11-03 after research (D-18 escape hatch).
- Exact REQUIREMENTS.md BRWN-12 rename wording + new REQ-ID wording for `review-typing`.
- TTY-color conventions (inherit Phase 8 NO_COLOR pattern).
- applied.log UTC timestamp exact format (ISO-8601 with `Z` suffix recommended).
- Whether `suggest --force` is needed in v1.1 (probably not).

## Deferred Ideas

- Single-command chain-runner (v1.2 BRWNAPPLY-01).
- Runtime-specific skills (.claude/skills/brownfield-*).
- Manifest-backed apply for 03 and 04.
- Page-level opt-out for 02 (add only if real-world noise emerges).
- `--force` on suggest.
- `--format json` on applied.log.
- Separate `brownfield-review.sh` helper script.
- Introspection subcommands (status/list).
- TUI with arrow keys.
- Obsidian plugin wrapper.
- Multi-vault brownfield.
- `run_hash` derived identifier.
- Auto-downgrade `verified` → `bootstrapped` on invariant break.
- Extending lint with a `brownfield-review` sub-category (planner discretion).
- Shell completion.
- Phase 10 WR-01/WR-02/WR-03 fixes (opportunistic only).

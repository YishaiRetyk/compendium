# Phase 13: Claim Faithfulness Audit - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a source-grounded audit (`bin/audit-claims.sh`) that checks whether sampled wiki claims *semantically follow* from the source passage they cite — not merely that `[prov:]` markers resolve and locators are syntactically valid (which `bin/lint.sh` + AGENTS.md §6 already enforce). This closes the "error compounding" integrity gap: a paraphrase that drifts from its source currently survives every existing gate.

The design splits along the project's established deterministic/judgment seam (cf. brownfield "review may be AI-guided; apply must be deterministic" §11.5; lint "auto-fix mechanical, contradictions report-only" §11.3). `bin/audit-claims.sh` owns a **deterministic core** — select claims (FAITH-01) → resolve each `[prov:source_id#locator]` to a bounded passage from the *raw* source at `path:` (FAITH-02) → privacy-route (FAITH-04) → emit structured findings (FAITH-03). The **per-claim entailment verdict** is the only judgment step and is performed by a **pluggable verifier**, defaulting to agent-in-the-loop. The deterministic core never sends anything anywhere; the verifier dispatch is the single privacy chokepoint, fail-closed.

**In scope:** `bin/audit-claims.sh` (deterministic selector + locator→passage resolver + privacy router + emitter); the 4-way verdict (`supports`/`weak`/`contradicts`/`insufficient`) plus operational verdicts (`insufficient-locator`/`skipped-privacy`/`skipped-nontext`); a documented `--verifier <cmd>` contract (no bundled verifier script); `audit-report.md` + lint-compatible JSON output; `wiki/maintenance/audit-state.md` checkpoint; an **optional `<!-- page: N -->` source page-marker convention** documented in AGENTS.md §6; a non-binding reflect-tier "audit recommended" suggestion; tests under `tests/phase-13/`; flip FAITH-01..04 in REQUIREMENTS.md; `13-VERIFICATION.md`.

**Out of scope (ROADMAP non-goals, LOCKED):** auto-rewrite of claims; required CI blocking gate in v1; SQLite / any DB; full-vault audit by default; embedding/`ragas` library dependency. Also out: changing the `[prov:]` grammar itself; auto-inserting page markers at ingest (deferred — see Deferred).
</domain>

<decisions>
## Implementation Decisions

### Verifier model + privacy contract (Area 1)
- **D-01:** **Contract-only verifier.** Agent-in-the-loop is the default verdict engine (the operating LLM reads passage + claim and produces the verdict; no API key, no network call from the script). ALSO define a documented `--verifier <cmd>` contract for headless/automation — stdin `{claim, passage, support_type}` → stdout `{verdict, rationale, sub_claims:[...]}`. **Ship NO bundled verifier script** (no in-repo Claude-API or ollama example). Rationale: preserves zero-new-dependency posture and keeps API keys / cloud-call surface out of the repo; automation users supply their own model behind the contract. Rejected: bundling reference verifiers (maintenance + in-repo cloud-call surface); agent-only with no hook (forecloses automation needlessly — the contract is just a subprocess interface, costs nothing).
- **D-02:** **Fail-closed `local_only` egress, mechanically enforced.** The deterministic core resolves each claim's *source* privacy via §13 precedence (frontmatter → enclosing-dir → `local_only` default; stricter wins; unknown → `local_only`) BEFORE the verdict step. By default it **withholds `local_only` passages from the emitted worklist** and marks them `skipped-privacy`. Including them requires an explicit opt-in (a local `--verifier`, or an `--allow-local`-style flag asserting a local verdict engine). A cloud operating model therefore *mechanically* never receives `local_only` passages — enforcement, not a documented promise. Rejected: a single trust `--operator-local` flag with no worklist partition (weaker); doc-only honor system (not fail-closed).
- **D-03:** **`skipped-privacy` on `local_only` is acceptable UX.** For a primarily-local vault, emitting `skipped-privacy` for every `local_only` claim (absent a local verifier) is the accepted default behavior — it satisfies FAITH-04 / SC-3 ("uses a local verifier OR emits an explicit skipped/privacy finding") without forcing a local-model dependency. The audit's value on the `cloud_safe` subset stands on its own.

### Locator resolution + page-marker convention (Area 2)
- **D-04:** **Ship the page-marker convention in v1** (user override of the design-note recommendation, which deferred it to v1.2). Markdown-native sources lose page boundaries, so `#p<n>` locators have nothing to bound against. The convention makes `#p` resolvable where authors opt in. This is an accepted, scoped expansion past the audit script into the source-authoring/AGENTS.md §6 surface — kept minimal per D-05/D-06/D-07.
- **D-05:** **Marker syntax = HTML comment at page boundaries:** `<!-- page: N -->` inserted in the raw source at each page break. Obsidian-invisible (does not render), grep-able, and requires **no change to the `[prov:]` grammar** (`#p` already exists in §6). `resolve_locator` slices `#p8` from the `page: 8` marker to the `page: 9` marker; `#p12-14` spans the `page: 12` marker to the `page: 15` marker (exclusive). Rejected: frontmatter page-offset map (brittle, hand-maintained, decoupled from the text); visible delimiter line (pollutes rendered source).
- **D-06:** **Optional, with `insufficient-locator` fallback.** Markers are an *optional* convention, never required. When present, `#p` resolves to a bounded passage; when absent, the claim degrades to the first-class `insufficient-locator` verdict (the other half of Area 2). Additive — imposes nothing on existing sources; unmarked paginated sources are not errors. This keeps both halves: the convention unlocks `#p` where opted-in, and `insufficient-locator` honestly handles everything else (and nudges authors toward `#sec:`).
- **D-07:** **Document now, helper later.** Define + document the `<!-- page: N -->` convention in AGENTS.md §6 in v1; the human/curator hand-marks sources for now and the audit just *consumes* the markers (zero new ingest logic). Any auto-insertion helper (e.g. PDF→md page-break detection in `bin/ingest.sh`) is deferred to v1.2. Convention lands now; tooling is incremental.

### Sampling + cadence (Area 3)
- **D-08:** **Cadence = on-demand + non-binding reflect-tier suggestion.** The operator runs `bin/audit-claims.sh` manually (primary path). Additionally, lint/reflect MAY emit a non-binding `audit recommended: ...` note (§11.4 Tier-2 recommendation pattern) when high-risk claims accumulate — discoverable without automation. Rejected: on-demand only (nothing surfaces the need); periodic/post-ingest auto-trigger (heavier, drifts toward an implicit gate, cuts against "no default CI gate").
- **D-09:** **Default `--sample 20`, priority-ranked union.** Union the four FAITH-01 selectors, dedupe, order by risk priority (**stale-source → `inferred`/`tentative` → recently-modified → high-fanout**), then cap at 20. The operator raises `--sample` for more coverage. **Always log selected-vs-skipped counts** (honest sampling, "no silent caps" — a green audit on a capped sample is not a green vault). Rejected: default 10 (too thin a default); no cap by default (unbounded cost/privacy surface; against "no full-vault by default").

### contradicts → marker handoff (Area 4)
- **D-10:** **Defined, human-approved handoff.** The audit itself stays strictly report-only (SC-5). But DOCUMENT a follow-on bridge: a human or agent MAY, as a **separate explicit operation**, add `[epistemic:: tentative]` or a `[contradiction:source_a vs source_b]` marker (§6) to a claim with a confirmed `contradicts` verdict. **Never automatic** — the audit produces a finding, a subsequent decision promotes it. This defines the connection to existing §6/§9 machinery rather than leaving the "what now?" unstated. Rejected: report-only with no defined handoff (leaves a dangling question); deferring the handoff design to v1.2 (cheap to specify now).

### Carried forward from design notes (LOCKED — not re-litigated)
- **D-11:** Verify against the **raw source file at the source page's `path:`**, NEVER the source-summary page's `## Extracted Claims` (circular — same extraction pass that may have erred). Highest-severity design pitfall.
- **D-12:** Four-way verdict `supports` / `weak` / `contradicts` / `insufficient`, adapted from ragas `faithfulness` (decompose claim → per-sub-claim entailment → aggregate). Plus operational verdicts `insufficient-locator` (no passage extractable), `skipped-privacy` (D-02), `skipped-nontext` (`#img`). `insufficient` (passage doesn't address claim) is distinct from `insufficient-locator` (couldn't extract a passage).
- **D-13:** **Zero new claim-level vocabulary.** Reuse existing `[epistemic::]` markers as FAITH-01 selectors; do not invent magic-string provenance values (consistent with BRWN-15).
- **D-14:** Output = extend lint's `{severity, category, path, message}` finding tuple with `verdict`, `line`, `source_id`, `locator`, `rationale` (SC-4/SC-6 — downstream lint/report tooling can consume both). Human report at `wiki/maintenance/audit-report.md` (pattern-twin of `lint-report.md`), grouped by verdict. **No wiki page is ever mutated** (SC-5). Severity mapping: `contradicts` → warning; `weak`/`insufficient`/`skipped-*`/`insufficient-locator` → info; `supports` → info or omitted. **No `error`** — never a gate in v1.
- **D-15:** Checkpoint `wiki/maintenance/audit-state.md` (frontmatter `last_audit_commit`, `last_audit_at`, `last_sample_size`) mirrors `reflect-state.md`; control-plane, not indexed; advances even on a no-finding run.
- **D-16:** Keep it a **separate script**, NOT a `bin/lint.sh` category (lint is fast/deterministic/offline; faithfulness is slow/sampled/judgment-bearing). It MAY share the JSON schema so report tooling consumes both.

### Claude's Discretion
- Exact `bin/audit-claims.sh` arg surface beyond the design-note sketch (`--since`, `--sample N`, `--select`, `--format json|report`, `--emit-worklist`, `--apply-verdicts <f>`, `--verifier <cmd>`, the `--allow-local` opt-in name) — semantics fixed by decisions above; flag names/decomposition are the planner's call.
- Whether the agent-in-the-loop loop is "emit worklist → agent writes report" vs "emit worklist → `--apply-verdicts <file>`" — both satisfy D-01; implementation pattern open.
- Exact prose/placement of the `<!-- page: N -->` convention within AGENTS.md §6 (and its `schema/AGENTS.template.md` mirror) — D-05 fixes the syntax + slice semantics; cadence/wording open.
- High-fanout computation method (reuse lint's orphan/cross-ref inbound-link pass vs a dedicated count) — D-09 fixes it as a selector + its rank position; the computation is downstream.
- Whether the reflect-tier suggestion (D-08) lives in the lint workflow, the reflect workflow, or both — §11.4 Tier-2 is the pattern; exact host is the planner's call.
- Exact `13-VERIFICATION.md` evidence layout (follow Phase 12.1/12.2 mirror format).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 13 contract + design
- `.planning/phases/13-claim-faithfulness-audit/13-DESIGN-NOTES.md` — the authoritative pre-planning design (146 lines): architecture, ragas mapping, locator→passage table, privacy chokepoint, output schema, "Don't Hand-Roll", "Common Pitfalls", and the 5 open questions this CONTEXT resolves. **Read first.**
- `.planning/REQUIREMENTS.md` lines 135–141 — FAITH-01..04 verbatim (the four requirements this phase closes); also CLOSE-02 (re-run audit dependency at v1.1 closure).
- `.planning/ROADMAP.md` Phase 13 entry (lines 226–244) — Goal, dependencies, 6 success criteria (SC-1..6), non-goals.

### Schema surfaces the audit consumes (do NOT change the grammar)
- `AGENTS.md §6` (Provenance/Epistemics/Staleness) — `[prov:<source_id>#<locator>|<support_type>|<checked_at>]` grammar; locator types (lines ~410–418: `#p`, `#sec:`, `#para`, `#t`, `#img`); support types (lines ~420–427); `[epistemic::]` markers (FAITH-01 selectors); `[contradiction:...]` marker (D-10 handoff target). **The `<!-- page: N -->` convention (D-05) is added HERE.**
- `AGENTS.md §13` (Privacy Routing) — three-level precedence + fail-closed; the D-02 verdict-dispatch chokepoint is grounded here. Source-summary pages ARE the source registry (`id`, `path`, `content_hash`, `compiled_against_hash`).
- `AGENTS.md §11.4` (Reflect Workflow) — Tier-2 `reflect recommended: ...` recommendation pattern; precedent for the D-08 "audit recommended" suggestion. `wiki/maintenance/reflect-state.md` is the checkpoint pattern-twin for D-15.
- `AGENTS.md §11.3` (Lint Workflow / CI mode) — finding severities, `--format json`, category model; the deterministic/judgment + report-only ethos the audit mirrors.

### Existing code to reuse (Don't Hand-Roll)
- `bin/lint.sh` (1895 lines, `LINT_VERSION` line 13):
  - `add_finding()` + finding tuple (lines ~403–404) — extend this shape (D-14), don't fork.
  - `PROVENANCE_PRESENCE_RE = re.compile(r'\[prov:')` (line ~307) and prov parse `\[prov:([^#\]]+)#([^|\]]+)` (line ~386) — claim detection + source_id/locator extraction.
  - Source-registry read (lines ~977–1070) + `SOURCE_EXTRA_FIELDS` (line ~382: `path`, `content_hash`, `ingested_at`, `source_type`, `compilation_status`) — resolve `source_id` → raw `path:` (D-11).
  - Staleness/drift `content_hash != compiled_against_hash` (lines ~1225–1238) — reuse for the stale-source selector (D-09).
  - `EXCLUDE_DIRS` (line ~379), orphan/cross-ref inbound-link pass — high-fanout selector input (D-09).
  - frontmatter parser pattern — reuse verbatim for page/source loading.
- `bin/check-privacy.sh` (148 lines) — `PUBLIC_PATHS` (line ~71), frontmatter `privacy: local_only` regex (lines ~86–87), exit-code 0/1/2 convention. Pattern reference for the D-02 §13 resolution (consider factoring shared logic into `bin/lib/`).
- git diff for "recently modified": `git diff --name-only <audit-checkpoint>...HEAD -- wiki/` — copy the `--strict`/reflect approach (design notes §Standard Stack).

### Test + verification precedent
- `tests/phase-12.2/` and `tests/phase-09/lib.sh` — `run.sh` aggregator + `lib.sh` helpers + per-scenario `test_*.sh`; `make_fixture_repo` shape. `tests/phase-13/` mirrors this.
- `.planning/phases/12.2-local-wiki-write-gate/12.2-VERIFICATION.md` and `.../12.1-.../12.1-VERIFICATION.md` — VERIFICATION.md mirror format (REQ-IDs + per-requirement file-path evidence); `bin/requirements-sync.sh --strict --phase 13` + `--require-complete --phase 13` exit-0 as the green-light gate.

### Schema mirror + sync
- `schema/AGENTS.template.md` + `CLAUDE.md` — the §6 page-marker addition must mirror to both; `CLAUDE.md` byte-equality auto-handled by `.githooks/pre-commit` sync-claude; `schema/AGENTS.template.md` + canonical fixture (Phase 11-05 regenerate path) updated manually.

### Project context
- `.planning/PROJECT.md` — local-first / file-based / zero-cloud-for-core constraints (LLM calls are the documented exception); "technically comfortable early adopters" audience.
- `.planning/seeds/wiki-quality-heuristics.md` — connectivity-ranking (high-fanout) selector shares lineage with this phase; cluster/overview detection is the deferred sibling.
- `.planning/config.json` `git.branching_strategy: none` — trunk-based; planning docs commit to `main`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`bin/lint.sh` finding tuple + `add_finding()`** — the audit's JSON output is this shape + 5 fields (D-14). SC-6 compatibility depends on not forking it.
- **`bin/lint.sh` prov regex + frontmatter parser** — claim detection (a body line with ≥1 `[prov:]`), source_id/locator extraction, and page/source loading all already exist. Zero new parsing primitives.
- **`bin/lint.sh` source-registry + hash-drift logic** — resolves `source_id` → `path:` (D-11) and computes the stale-source signal (D-09) already.
- **`bin/check-privacy.sh` §13 resolution + exit-code convention** — the D-02 privacy chokepoint reuses this precedence; candidate to factor into `bin/lib/`.
- **`wiki/maintenance/reflect-state.md` + §11.4 checkpoint mechanics** — pattern-twin for `audit-state.md` (D-15) and the Tier-2 suggestion (D-08).
- **`tests/phase-09/lib.sh` / `tests/phase-12.2/`** — fixture-repo + aggregator harness shape for `tests/phase-13/`.

### Established Patterns
- **Deterministic-core / judgment-step seam** — brownfield (§11.5) + lint (§11.3): mechanical plumbing is deterministic, the one judgment step is isolated/pluggable. The verifier dispatch is the only judgment + only privacy egress.
- **Report-only diagnostics, never a gate** — lint contradictions + brownfield advisory class. The audit proposes; promotion to markers is a separate human-approved op (D-10).
- **Single source of truth in AGENTS.md, docs link don't restate** (Phase 9-06 / 12.2) — the §6 page-marker convention is normative in AGENTS.md; any docs reference points back.
- **No silent caps** — log selected-vs-skipped (D-09), mirroring lint's no-silent-truncation principle.
- **Privacy fail-closed, single chokepoint** (§13) — unknown → `local_only`; stricter wins.
- **VERIFICATION.md mirror + `requirements-sync` exit-0 green-light** (Phase 7/12.1/12.2).

### Integration Points
- **New file `bin/audit-claims.sh`** — bash arg-parse → single python3 block (select → resolve → privacy-route → verdict-dispatch → emit → checkpoint), reusing lint's parser/finding/regex.
- **`AGENTS.md §6`** — add the `<!-- page: N -->` convention + `#p` slice semantics (D-05/D-06/D-07); mirror to `schema/AGENTS.template.md` + `CLAUDE.md` (+ canonical fixture).
- **`AGENTS.md` workflow surface** — document the Audit as a workflow/operation procedure (review-only) + the D-10 contradicts→marker handoff + the D-08 reflect-tier suggestion. (Whether this is a new §11.x workflow subsection vs folded into reflect/lint is the planner's call — note it does NOT add a wiki page type and keeps the four-operation framing unless the planner deliberately elevates it.)
- **`wiki/maintenance/audit-report.md` + `audit-state.md`** — new control-plane artifacts (not indexed).
- **`.planning/REQUIREMENTS.md`** — flip FAITH-01..04 post-`13-VERIFICATION.md`.
- **`tests/phase-13/`** — new harness; must cover each verdict path (incl. `insufficient-locator`, `skipped-privacy` fail-closed partition, `#p` resolution against marked vs unmarked sources), priority-ranked sampling + cap logging, and the `--verifier` contract.
- **`bin/requirements-sync.sh --strict --phase 13`** — exit 0 after VERIFICATION.md lands.
</code_context>

<specifics>
## Specific Ideas

- The user accepted the recommended option on 6 of 7 sub-decisions (verifier contract-only, fail-closed privacy, on-demand+reflect cadence, sample-20 priority union, contradicts handoff) — consistent with their Phase 12.2 pattern of trusting established minimal patterns. **Signal:** don't over-engineer; reuse lint/reflect/brownfield precedent; keep the script's footprint small.
- The **one deliberate override**: the user wants the **page-marker convention shipped in v1**, not deferred to v1.2. They accepted the *minimal* shape of it (optional, HTML-comment syntax, document-now/helper-later, with `insufficient-locator` fallback intact) — i.e. they want the coverage win without the heavyweight ingest tooling. **Signal:** locator precision matters to them; treat `#p` resolution as a real v1 deliverable, but keep it additive and dependency-free.
- The user paused to clarify the privacy contract (1b) before answering — they care that FAITH-04 is *mechanically* enforced, not just documented. The fail-closed worklist partition (D-02) is the load-bearing privacy decision; planner/executor must not let any pre-verdict step egress.
- `skipped-privacy` being acceptable means the audit is allowed to be partial on a local-heavy vault — do NOT treat high `skipped-privacy` counts as a failure or pad coverage to avoid them.
</specifics>

<deferred>
## Deferred Ideas
- **Auto-insertion of `<!-- page: N -->` markers at ingest** (e.g. PDF→md page-break detection in `bin/ingest.sh`) — deferred to v1.2 (D-07). Ships as a documented hand-authored convention now; helper is incremental.
- **Bundled reference verifier scripts** (cloud Claude-API + local ollama) — not shipped (D-01); the `--verifier` contract is documented so users can supply their own. Revisit if automation adoption justifies a maintained example.
- **Required page markers / `#p`-against-unmarked = error** — rejected (D-06); convention stays optional with `insufficient-locator` fallback.
- **Periodic / post-ingest auto-trigger of the audit** — rejected for v1 (D-08); on-demand + non-binding suggestion only. Revisit if a cadence need emerges.
- **Auto-promotion of `contradicts` findings to markers** — rejected (D-10, SC-5); promotion is always a separate human-approved operation.
- **Faithfulness as a `bin/lint.sh` category / a CI blocking gate** — rejected (D-16 + LOCKED non-goals); separate script, review-only, no default gate. A future opt-in gate is a later-version question.
- **Embedding/`ragas` library, SQLite, full-vault default** — LOCKED out by non-goals; borrow the algorithm, not the dependencies.
- **Elevating Audit to a 5th top-level operation** (changing the "four operations" framing) — not decided here; left to the planner. Default expectation is to document Audit as a workflow without churning the four-operation framing unless the planner makes a deliberate case.
</deferred>

---

*Phase: 13-claim-faithfulness-audit*
*Context gathered: 2026-05-31*

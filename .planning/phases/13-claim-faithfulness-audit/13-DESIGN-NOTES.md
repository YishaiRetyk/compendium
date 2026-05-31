# Phase 13: Claim Faithfulness Audit — Design Notes

> Pre-planning design input, not the auto-generated `gsd-phase-researcher` artifact. Authored from a comparison against Neo4j Labs `llm-graph-builder`. Intended to seed `/gsd-discuss-phase 13` and inform the planner; deliberately named to avoid colliding with a generated `13-RESEARCH.md`.

**Authored:** 2026-05-31
**Domain:** Source-grounded semantic verification of wiki claims against cited source passages; bash + python3 + pluggable LLM verifier; review-only, privacy-respecting
**Confidence:** HIGH for the deterministic plumbing (sampling, locator→passage resolution, output, privacy routing — all verifiable against in-repo code); MEDIUM for the verdict step (depends on a verifier choice that should be settled in discuss-phase).
**Reference design:** Neo4j Labs `llm-graph-builder` — `backend/src/ragas_eval.py` (the `ragas` `faithfulness` metric) is the validated algorithm this phase adapts. See SUMMARY at end for the mapping.

## Summary

Phase 13 closes the integrity gap named on the roadmap: the system today validates that `[prov:]` markers **resolve** and that locators are **syntactically valid** (`bin/lint.sh` provenance check, AGENTS.md §6), but never that a claim **semantically follows** from the passage it cites. This is the "error compounding" critique — a paraphrase that drifts from its source survives every existing gate.

The load-bearing design insight is to **split the audit along the same deterministic/judgment seam the project already uses elsewhere** (cf. brownfield's "review may be AI-guided; apply must be deterministic", §11.5; lint's "auto-fix is mechanical, contradictions are report-only", §11.3). `bin/audit-claims.sh` owns the **deterministic core**: select claims (FAITH-01), resolve each `[prov:source_id#locator]` to a bounded passage from the *raw* source (FAITH-02), route by privacy (FAITH-04), and emit a structured worklist + findings (FAITH-03). The **per-claim entailment verdict** — the only judgment step — is performed by a *verifier*, which is pluggable: the default is **agent-in-the-loop** (the LLM operator running the workflow produces verdicts, which is privacy-trivial because the agent already holds the content under its own privacy context), with an optional `--verifier <cmd>` hook for headless/automated runs (where the ragas algorithm applies). The deterministic core **never sends anything to any API** — the verifier dispatch is the single privacy chokepoint, fail-closed per §13.

The hard problems are NOT "can an LLM judge entailment" (ragas does this in `faithfulness`, decompose-then-verify, and it works). They are project-specific: **(1) locator precision** — `#sec:`/`#para` resolve to bounded markdown passages cleanly, but `#p8` page locators on markdown-native sources have nothing to bound against, so they must degrade to an explicit `insufficient-locator` verdict rather than silently auditing the whole document; **(2) circularity** — the audit MUST verify against the raw source file at the source page's `path:` field, never against the source-summary page's own `## Extracted Claims` (those were written by the same extraction pass that may have erred); **(3) honest sampling** — per the project's "no silent caps" principle, the audit must log what it sampled vs. skipped so a bounded run never reads as "audited everything"; **(4) privacy** — FAITH-04 is the whole point, and the deterministic-core/verifier-dispatch split is what makes it mechanically enforceable rather than a promise.

**Primary recommendation:** Build `bin/audit-claims.sh` as a deterministic selector+resolver+emitter that mirrors `bin/lint.sh`'s structure (bash arg-parse → single python3 block → JSON or markdown-report emitter, reusing the `{severity, category, path, message}` tuple extended with `verdict`, `line`, `source_id`, `locator`, `rationale`). Make the verifier pluggable with agent-in-the-loop as the default and a documented `--verifier` contract for automation. Ship a checkpoint file `wiki/maintenance/audit-state.md` (pattern-twin of `reflect-state.md`). Default review-only, no CI gate (SC-5, non-goals).

## Phase Requirements

| Req | Statement | Where addressed |
|-----|-----------|-----------------|
| FAITH-01 | Sample recently modified + high-risk claims (`inferred`/`tentative`, stale-source, high-fanout) | §Architecture "Claim selection" |
| FAITH-02 | Resolve `[prov:source_id#locator]` to the cited passage; verdict ∈ supports/weak/contradicts/insufficient | §Architecture "Locator→passage" + "Verdict step" |
| FAITH-03 | Structured, review-only output: page path, line, source ID, locator, verdict, rationale; no auto-edits | §Architecture "Output schema" |
| FAITH-04 | `local_only` claims never sent to cloud; local verifier OR explicit skipped/privacy finding | §Architecture "Privacy routing" |

**Success criteria (from ROADMAP):** SC-1 sampling exists; SC-2 locator resolution + 4-way verdict; SC-3 privacy; SC-4 structured findings with the 6 fields; SC-5 review-only/no-auto-fix/no-default-CI-gate; SC-6 optional machine-readable output for downstream tooling.

**Non-goals (LOCKED):** no auto-rewrite; no required CI blocking gate in v1; no SQLite; no full-vault audit by default.

## Project Constraints (from AGENTS.md / CLAUDE.md)

- **§13 Privacy, fail-closed.** Per-claim source privacy resolves via three-level precedence (frontmatter `privacy` → enclosing-dir default → system default `local_only`). Stricter wins. The verifier dispatch must apply this; unknown → `local_only`.
- **§6 Provenance grammar.** Marker form `[prov:<source_id>#<locator>|<support_type>|<checked_at>]`. Locator types: `#p<n>`/`#p<a>-<b>`, `#sec:<name>`, `#para<n>`, `#t<start>-<end>`, `#img<n>`. The audit consumes these; it does not change the grammar.
- **§6 epistemic markers.** `[epistemic:: inferred|tentative|...]` are the high-risk selectors for FAITH-01. **Zero new claim-level vocabulary** (consistent with BRWN-15's "no magic-string provenance values").
- **Review-only ethos.** Like lint's report-only findings and the brownfield advisory class — the audit proposes, never mutates. Verdicts are diagnostics, not gates.
- **No silent caps.** AGENTS.md lint "no silent truncation" principle applies: log sampled-vs-skipped counts.

## Standard Stack

### Core (all already in repo, zero new dependencies)
- **bash + python3 + pyyaml** — same runtime as `bin/lint.sh`. Frontmatter parsing, finding tuples, JSON emit: copy the established patterns, don't re-invent.
- **git** — for "recently modified" selection (`git diff --name-only <audit-checkpoint>...HEAD -- wiki/`) and high-fanout/recency, mirroring how `reflect` reads a checkpoint and `lint --strict` reads a diff.

### Verifier (the one new moving part — settle in discuss-phase)
- **Default: agent-in-the-loop.** The script emits a worklist (`--emit-worklist`); the operating LLM agent produces verdicts and feeds them back (`--apply-verdicts <file>` or the agent writes the report directly). No API key, no network call from the script, privacy handled by the agent's own context tier.
- **Optional: `--verifier <cmd>`** for headless/CI. Contract: receives `{claim, passage, support_type}` as JSON on stdin, returns `{verdict, rationale, sub_claims:[...]}` on stdout. Two reference verifiers worth providing: a cloud one (Claude API, for `cloud_safe` only) and a local one (e.g. ollama, eligible for `local_only`). If no local verifier is configured, `local_only` claims emit `skipped-privacy` (satisfies FAITH-04 + SC-3 without forcing a local-model dependency).

### Alternatives considered and rejected
- **Embed `ragas` directly** (the reference impl). Rejected: drags in `datasets`, `ragas`, `nltk`, embedding models — contradicts the zero-/minimal-dep, markdown-first thesis and the "no SQLite/heavy infra" non-goal. Borrow the *algorithm* (decompose → per-claim entailment → aggregate), not the library.
- **Verify against the source-summary page's `## Extracted Claims`.** Rejected as circular — those claims came from the same extraction that may have introduced the drift. FAITH-02 says "the cited source passage": resolve to the raw file at `path:`.
- **Make it a `bin/lint.sh` category.** Rejected: lint is fast/deterministic/offline; faithfulness needs a verifier and is slow/sampled/judgment-bearing. Keep it a separate script (it MAY share the JSON schema so lint/report tooling can consume it — SC-6).

## Architecture Patterns

### Recommended structure (`bin/audit-claims.sh`)
```
arg-parse (bash)              # --since, --sample N, --select <selectors>, --format json|report,
                              #   --emit-worklist, --apply-verdicts <f>, --verifier <cmd>, --category
   │
   └─ single python3 block:
        1. load wiki pages + source registry (reuse lint's frontmatter parser)
        2. SELECT claims        → FAITH-01 selectors below
        3. RESOLVE locator→passage from raw source at path:  → FAITH-02 (deterministic)
        4. PRIVACY route each claim (§13)                    → FAITH-04 chokepoint
        5. VERDICT: agent-in-the-loop (default) | --verifier cmd | skipped-privacy
        6. EMIT findings (JSON array or audit-report.md)     → FAITH-03 / SC-4 / SC-6
        7. advance checkpoint wiki/maintenance/audit-state.md
```

### Claim selection (FAITH-01) — also borrows graph-builder's connectivity ranking
A "claim" = a body line/bullet containing ≥1 `[prov:]` marker (same definition lint uses for staleness, §6). Selectors, union'd then capped by `--sample`:
- **Recently modified:** pages changed since the audit checkpoint (`git diff`), like `reflect`/`--strict`.
- **`[epistemic:: inferred]` / `[epistemic:: tentative]`** claims — already grep-able.
- **Stale-source:** claims whose source has `content_hash != compiled_against_hash` (lint already computes this in the drift check — reuse), or decay-stale per §6.
- **High-fanout:** claims on pages with many inbound wikilinks. *This is the transferable idea from llm-graph-builder's `community_rank` (rank by connectivity) — high-fanout pages are exactly the roadmap's "high-risk" target because an error there propagates widest.* The inbound-link count is already partially computed by lint's orphan/cross-ref pass.
- **Honest reporting:** emit an `info` finding with `selected: N, skipped (over --sample cap): M` so a capped run never reads as exhaustive.

### Locator → passage resolution (FAITH-02) — the deterministic crux
`resolve_locator(raw_source_text, locator) -> passage | None`. Read the **raw** source at the source page's `path:` (NOT the summary). Per locator type:
- `#sec:<name>` → slice from the matching markdown heading to the next same-or-higher heading. **Clean.**
- `#para<n>` → the n-th blank-line-delimited paragraph. **Clean.**
- `#t<start>-<end>` → lines within the timestamp window, if the transcript carries timestamps. **Usually clean for transcripts.**
- `#p<n>` / `#p<a>-<b>` → page range. Raw sources are markdown (un-paginated) → **no reliable bound**. Degrade to verdict `insufficient-locator`, do NOT silently feed the whole document to the verifier (false confidence + cost + privacy surface). Surface count of these — it is itself an actionable finding (tighten locators to `#sec:`).
- `#img<n>` → non-text → `skipped-nontext` (text verifier can't adjudicate).

> **Design implication worth flagging to discuss-phase:** the value of the whole audit is bounded by locator precision. The page-locator gap is the single biggest determinant of coverage. Options: (a) accept `insufficient-locator` as a real verdict that nudges authors toward section locators; (b) add an optional page-marker convention to paginated sources (out of scope here, note for v1.2). Recommend (a) for v1.

### Verdict step (FAITH-02 four-way) — adapted from ragas `faithfulness`
For each claim+passage, the verifier:
1. **Decompose** the claim into atomic sub-assertions (ragas does this; it's why partial-support is detectable — a bullet can be 70% right).
2. **Entailment per sub-claim** against the passage: supported / not / contradicted.
3. **Aggregate** to the roadmap's four verdicts:
   - `supports` — all sub-claims entailed by the passage.
   - `weak` — some entailed, none contradicted, but the passage doesn't fully establish the claim (ragas "partial faithfulness").
   - `contradicts` — ≥1 sub-claim contradicted by the passage.
   - `insufficient` — passage does not address the claim (distinct from `insufficient-locator`, which is "couldn't extract a passage at all").
4. **Rationale** — one line citing what the passage does/doesn't say (required field, SC-4).

Optional enrichment (borrowed from ragas `context_entity_recall`): flag when a claim introduces a named entity/figure absent from the passage — a cheap hallucination signal.

### Privacy routing (FAITH-04 / SC-3) — single chokepoint, fail-closed
Steps 1–4 of the pipeline are pure-local (read files, extract passages) and send nothing anywhere. Privacy only matters at step 5:
- Resolve each claim's **source** privacy via §13 (frontmatter → dir → `local_only` default; stricter wins).
- `cloud_safe` → eligible for a cloud verifier.
- `local_only` → cloud verifier FORBIDDEN. Route to a configured local verifier; else emit verdict `skipped-privacy` with the source ID (explicit, auditable — exactly SC-3's "uses a local verifier OR emits an explicit skipped/privacy finding").
- Agent-in-the-loop default: the agent inherits the run's privacy context; it must honor the same rule (document in the workflow that an audit run touching `local_only` claims must not itself be running against a cloud model unless... — settle the precise operator contract in discuss-phase).

### Output schema (FAITH-03 / SC-4 / SC-6)
Extend lint's JSON finding so downstream tooling can consume both (SC-6):
```json
{ "severity": "warning|info", "category": "faithfulness",
  "path": "wiki/concepts/foo.md", "line": 42,
  "source_id": "src-...", "locator": "#sec:intro",
  "verdict": "supports|weak|contradicts|insufficient|insufficient-locator|skipped-privacy|skipped-nontext",
  "message": "<rationale, one line>" }
```
Plus a human report `wiki/maintenance/audit-report.md` (pattern-twin of `lint-report.md`), grouped by verdict. **No wiki page is mutated** (SC-5). Severity mapping suggestion: `contradicts` → warning; `weak`/`insufficient` → info; `supports` → info or omitted; the `skipped-*` → info. (No `error` — this is never a gate in v1.)

### Checkpoint
`wiki/maintenance/audit-state.md` — frontmatter `last_audit_commit`, `last_audit_at`, `last_sample_size`. Mirrors `reflect-state.md`. `wiki/maintenance/` is control-plane (not indexed). A run advances the checkpoint even if it finds nothing.

## Don't Hand-Roll
- **Frontmatter parsing / page loading** — reuse `bin/lint.sh`'s python parser pattern verbatim.
- **Finding tuple + JSON emit** — extend the existing `{severity, category, path, message}` shape; don't invent a parallel format (SC-6 depends on compatibility).
- **Privacy precedence** — §13 is fully specified; don't re-derive. Consider factoring the resolution into `bin/lib/` if `check-privacy.sh` has reusable logic.
- **"Recently modified" diff** — copy the `--strict`/reflect git-diff approach.
- **Checkpoint mechanics** — copy `reflect-state.md` handling.

## Common Pitfalls
1. **Circular verification.** Auditing against the source-summary's extracted claims instead of the raw `path:` file validates the wiki against itself. Always read raw. *(Highest-severity design error.)*
2. **Silent locator failure.** Feeding the whole document to the verifier when a `#p8` locator can't bound a passage → false `supports`/`contradicts` at high cost and privacy surface. Make `insufficient-locator` a first-class verdict.
3. **Privacy leak through the verifier.** The entire reason for the deterministic-core/verifier-dispatch split. If any pre-verdict step ever calls out, FAITH-04 is unenforceable. Keep step 5 the sole egress; fail-closed on unknown privacy.
4. **Silent sampling cap → "looks audited."** Log selected-vs-skipped. A green audit on a capped sample is not a green vault.
5. **Non-determinism read as regression.** LLM verdicts vary run-to-run. Keep review-only, low temperature, log rationale, never gate — and say so in the workflow doc so a flipped verdict isn't mistaken for new drift.
6. **Scope creep into auto-fix.** SC-5 + non-goals are explicit: propose, never rewrite. A "contradicts" verdict produces a finding for human/agent review, not an edit.

## Open Questions for discuss-phase
- **Verifier default:** agent-in-the-loop only for v1, or ship a reference `--verifier` script too? (Affects whether a local-model dependency is introduced.)
- **Operator privacy contract** for agent-in-the-loop runs touching `local_only` claims — exact rule for which model may run the audit.
- **Page-locator gap:** accept `insufficient-locator` for v1 (recommended) vs. introduce a source page-marker convention (defer to v1.2).
- **Sample size + cadence:** default `--sample` N, and whether this is operator-invoked only or also a periodic reflect-tier suggestion.
- **Should `audit-report.md` findings optionally promote to `[epistemic:: tentative]` or a `[contradiction:]`-style marker on confirmed `contradicts`?** (Would be a *separate* human-approved operation, not auto — but worth deciding the handoff.)
```

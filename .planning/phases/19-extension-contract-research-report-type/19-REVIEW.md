---
phase: 19-extension-contract-research-report-type
reviewed: 2026-06-10T22:59:09Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - AGENTS.md
  - bin/audit-claims.sh
  - bin/lint.sh
  - CLAUDE.md
  - schema/reference/frontmatter.md
  - schema/reference/provenance.md
  - schema/reference/source-types.md
  - schema/workflows/audit.md
  - schema/workflows/ingest.md
  - wiki-cloud/comparisons/claude-code-orchestration-frameworks.md
  - wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md
  - wiki-cloud/concepts/progressive-disclosure.md
  - wiki-cloud/concepts/spec-driven-development.md
  - wiki-cloud/concepts/subagents.md
  - wiki-cloud/concepts/vlm-ocr-hallucination.md
  - wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md
  - wiki-cloud/entities/claude-code.md
  - wiki-cloud/entities/gsd.md
  - wiki-cloud/entities/olmocr.md
  - wiki-cloud/entities/omnidocbench.md
  - wiki-cloud/entities/spec-kit.md
  - wiki-cloud/entities/superpowers.md
  - wiki-cloud/index.md
  - wiki-cloud/log.md
  - wiki-cloud/overviews/agent-skills.md
  - wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md
  - wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md
  - wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md
findings:
  critical: 0
  warning: 7
  info: 7
  total: 14
status: resolved
resolved_at: 2026-06-11
fixes_applied: 14
---

# Phase 19: Code Review Report (re-review, post-19-05 gap closure)

**Reviewed:** 2026-06-10T22:59:09Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

This re-review covers the final Phase 19 state: the source-type extension contract, the `research-report` type, `#r<n>` locator + `_resolve_ref`, D-08/D-09 lint enforcement, the `derived-report` audit selector, the 114-marker sweep (including the 19-05 table-cell gap closure), the retro-classification of two report sources, and the decision record.

What was verified to work (empirically, in a sandboxed repo copy — no working-tree mutation):

- D-08 flags both prose `|direct|` and table-cell `\|direct\|` markers citing a research-report source on topic pages (2/2 injected markers caught), and the `support_type.rstrip('\\')` normalization in `bin/lint.sh:1143` is correct.
- D-09 rejects unknown `source_type` values; both retro-classified source pages parse and validate; `bin/lint.sh --dry-run --category provenance` is clean on the current tree (sweep complete for the two classified reports — zero residual `|direct|`/`\|direct\|` markers cite them).
- `_resolve_ref` correctly resolves `#r1`–`#r12` against `## Source Citations` and `#r1`–`#r15` against `## Sources by Topic` in the real raw sources, including out-of-range → `None` → `insufficient-locator`.
- AGENTS.md and CLAUDE.md are byte-identical; routing-table row, frontmatter enum, provenance locator table, ingest classification step, and audit workflow doc are mutually consistent; lint routing category passes.

However, the review found that the phase's headline verification mechanism is largely hollow in practice (WR-01: 71% of the new audit tier's claims have unresolvable locators), the 19-05 table-cell fix is incomplete in `bin/audit-claims.sh` (WR-02: locator not normalized, only support_type), and the D-08 gate has three enforcement gaps (WR-03, WR-04, WR-07). No Critical findings (no security, data-loss, or crash defects); review is read-only and no source files were modified.

## Warnings

### WR-01: 71% of derived-report audit-tier claims are unresolvable — `#sec:` locators do not match raw-source heading slugs

**File:** `wiki-cloud/entities/spec-kit.md:42-55`, `wiki-cloud/entities/superpowers.md:41-53`, `wiki-cloud/entities/gsd.md`, `wiki-cloud/entities/olmocr.md:48,56`, `wiki-cloud/concepts/subagents.md`, `wiki-cloud/concepts/progressive-disclosure.md`, `wiki-cloud/concepts/spec-driven-development.md`, `wiki-cloud/concepts/vlm-ocr-hallucination.md:43-46`, `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md:9-48`, `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md:50,52,62`, `wiki-cloud/overviews/agent-skills.md:69-70`, `wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md:46-47,63,65`, `wiki-cloud/entities/claude-code.md`
**Issue:** Empirical run of `bin/audit-claims.sh --select derived-report --sample 200` (sandboxed copy of HEAD): **78 of 110 tier-5 claims resolve to `insufficient-locator`**. The `#sec:` names were authored as short slugs at ingest, but `_resolve_sec` requires an exact match against the slugified raw heading. Examples: `#sec:spec-kit` vs heading `### Spec Kit (github/spec-kit)` → slug `spec-kit-githubspec-kit`; `#sec:gsd` vs `### GSD / Get-Shit-Done (gsd-build/get-shit-done)`; `#sec:hallucination-caveat` vs `## VLM Hallucination Caveat` → `vlm-hallucination-caveat`; `#sec:self-hosted` vs `## Self-Hosted / Local Tier`; `#sec:commercial` vs `## Cloud / Commercial Tier`; `#sec:comparative-matrix` vs `## Part III — Comparative Matrix`. Only `#sec:executive-summary`, `#sec:three-camps`, `#sec:paradigm-comparison`, `#sec:olmocr`, `#sec:omnidocbench`, `#sec:recommendations` (32 claims) resolve. The locator mismatches predate Phase 19, but the phase's central deliverable — faithfulness auditing of secondary-source claims via the `derived-report` tier — silently degrades to `insufficient-locator` for ~3/4 of its targets, and the phase shipped without detecting this. The same broken slugs also exist on the two source summary pages (`#sec:refuted` vs `## Refuted Claims`, etc.), though summary-page claims are excluded from audit selection.
**Fix:** One UPDATE-op sweep correcting the `#sec:` names to the actual heading slugs (or, cheaper and more robust: relax `_resolve_sec` to also match when the target slug is a hyphen-token subsequence/prefix of the heading slug, e.g. match `spec-kit` against `spec-kit-githubspec-kit` — keep exact match as first preference). Add a verification step to the audit workflow: after classifying a tier, assert resolvable-locator ratio above a floor.

### WR-02: 19-05 table-cell normalization is incomplete in `bin/audit-claims.sh` — locator keeps the trailing backslash

**File:** `bin/audit-claims.sh:529-534` (claim_tuples_for_page), `bin/audit-claims.sh:812-815`
**Issue:** The gap-closure fix added `support_type.rstrip('\\')` (group 3) but did not normalize the **locator** (group 2). For a table-cell marker `[prov:<id>#<loc>\|derived\|<date>]`, `PROV_RE`'s group 2 (`[^|\]]+`) captures `<loc>\` with the trailing backslash. Empirically observed in the sandbox run: findings carry `locator: "#sec:comparative-matrix\"` and `"#sec:hallucination-caveat\"`. Consequences: (a) `#sec:` locators only survive by accident (`_slugify` strips the backslash); (b) `#para<n>`, `#p<n>`, `#r<n>`, and `#t` locators in table cells will ALWAYS fail their digit/format validation (`'3\\'.isdigit()` → False) and degrade to `insufficient-locator` — so the `#r<n>` convention this phase introduced is unusable inside any table cell; (c) the un-normalized locator is emitted in the findings JSON, worklist, and audit-report.md, and is the join key for `--apply-verdicts` matching, so a verdict file with clean locators will not match a backslash-suffixed finding key.
**Fix:** In `claim_tuples_for_page`, normalize at extraction time (one site fixes all consumers):
```python
sid, loc = m.group(1), m.group(2).rstrip('\\')
```
(`resolve_locator` could additionally defensively `loc = loc.rstrip('\\')`.)

### WR-03: D-08 exemption is type-wide, not self-citation-only — a source page citing a DIFFERENT research-report with `|direct|` is not flagged

**File:** `bin/lint.sh:1148-1157`
**Issue:** The skip condition is `if fm.get('type') != 'source':` — every `type: source` page is exempt from D-08 for ALL markers, not just self-citations. Empirically verified: appending `[prov:src-2026-06-09-pdf-to-text-llm-ingestion-sota#sec:olmocr|direct|2026-06-09]` to the body of `src-2026-04-16-claude-code-frameworks-report.md` (a different source's summary) produces zero findings. This is exactly the cross-report laundering channel the anti-laundering note in `schema/reference/source-types.md` warns about ("Two reports citing each other can manufacture false consensus"). The DR (line 65) describes the exemption as "outside `wiki-cloud/sources/`", which also does not match the implemented type-based predicate.
**Fix:** Restrict the exemption to genuine self-citation:
```python
if not (fm.get('type') == 'source' and fm.get('id') == source_id):
    src_fm = source_registry.get(source_id)
    ...
```

### WR-04: D-08 enforces less than the schema mandates — only `direct` is flagged; omitted/`inferred`/`tentative` support types on report citations pass

**File:** `bin/lint.sh:1153`; `schema/reference/source-types.md:41,65`; `schema/workflows/ingest.md:53`
**Issue:** The contract says `support_type: derived` is MANDATORY for research-report claims ("derived only" in the retro-fit table; "every claim MUST carry `support_type: derived`" in ingest.md). The lint check only errors on `support_type == 'direct'`. A bare marker `[prov:<report-id>#sec:x]` (no support type), or `|inferred|`/`|tentative|`, evades the gate entirely while still violating the documented mandate. No such markers exist in the wiki today (verified by grep), so this is a prospective evasion hole, not a current defect — but the gate's purpose is to catch exactly the markers a future ingest writes carelessly.
**Fix:** Flag any report-citing marker whose support type is not `derived` (treat empty/missing as a violation too, or as a separate lower-severity finding if a softer rollout is preferred). At minimum, document in `source-types.md` that lint enforces only the `direct` case.

### WR-05: Spec contradiction — source-summary self-citations use `|direct|` but the authoritative contract says "ALL claims ... MUST use derived" with no carve-out

**File:** `schema/reference/source-types.md:65,94-101`; `schema/workflows/ingest.md:53`; `wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md:59-104`; `wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md:60-117`
**Issue:** Both retro-classified summary pages carry dozens of `|direct|` markers in `## Key Takeaways` / `## Extracted Claims`; lint deliberately exempts them and the DR asserts they "correctly remain `|direct|`" (a summary claim IS directly stated in the report). But `source-types.md` §5 — which declares "If you find a discrepancy between this file and AGENTS.md, this file wins" — says "ALL claims extracted from a research-report source MUST use `support_type: derived` ... Using `support_type: direct` on a research-report source is an epistemic-laundering error", and the ingest checklist (item 4) and the ingest.md granularity row repeat the unconditional rule. An agent following the authoritative docs on the next research-report ingest will author the source summary with `derived` markers, contradicting the established convention; an agent auditing the existing summaries against the contract will flag them as violations. The carve-out currently lives only in a lint code comment and the DR.
**Fix:** Add one sentence to `source-types.md` §5 Provenance (and the ingest.md row): "Exception: the source summary page's own claims self-cite the report with `direct` — `direct` describes the claim-to-cited-source relation; the laundering rule applies to all OTHER pages."

### WR-06: `--select` values are not validated — a typo (or stale help text) silently selects zero claims

**File:** `bin/audit-claims.sh:50-51` (usage), `bin/audit-claims.sh:635-636,654-658`
**Issue:** `selector_active(name)` is a bare membership test against the user CSV; an unknown selector name is silently ignored, and `--select derived_report` (underscore) or `--select derived` selects nothing with no warning — the run completes "successfully" with `Selected 0, skipped 0`. The committed `wiki-local/maintenance/audit-state.md`/`audit-report.md` show the most recent real run selected 0 of 0 claims at `--sample 5`, consistent with this hazard. Compounding it, the `--select` help text was not updated for this phase: it still reads "Subset of selectors: stale,epistemic,recency,fanout (default: all four)" — the new `derived-report` selector is undiscoverable from `--help` and the "all four" claim is now false (the default is five).
**Fix:** Validate in the python block: `unknown = set(SELECT) - set(RANK); if unknown: print(f"ERROR: unknown selector(s): {sorted(unknown)}", file=sys.stderr); sys.exit(1)`. Update the usage text to `stale,epistemic,recency,fanout,derived-report (default: all five)`.

### WR-07: Retro-classification missed a third report-shaped source — `src-2026-05-04-financial-ai-repo-comparison-report` stays `article` with `|direct|` downstream markers

**File:** `wiki-cloud/sources/src-2026-05-04-financial-ai-repo-comparison-report.md:32,65` (out of listed scope, found by cross-reference); downstream `|direct|` markers at `wiki-cloud/overviews/financial-ai-repository-landscape.md:48-59`, `wiki-cloud/entities/tradingagents.md:42-53`, `wiki-cloud/entities/openbb.md:41-52`
**Issue:** The page self-describes as "an LLM-authored synthesis of public repository documentation" — matching the §5 classification rule for `research-report` ("AI-synthesized report ... a report that synthesizes primary sources") word-for-word — yet it retains `source_type: article`, `epistemic_status: sourced`, and at least 10 downstream `|direct|` markers: precisely the laundering pattern D-08 exists to block, currently invisible to the gate because classification is the check's trigger. The DR says "the two existing AI deep-research reports" were retro-classified; if this third one was deliberately deferred, no deferral is recorded in the DR or the source-types sub-case registry. (The `src-2026-05-04-*-investigation` sources were spot-checked and are genuine primary repository inspections — `article` is correct for them.)
**Fix:** Either retro-classify it (`source_type: research-report`, sweep its `|direct|` markers to `|derived|`, backfill `## References` if the raw source has a bibliography) or record the explicit deferral decision in the DR / sub-case registry so the gap is visible.

## Info

### IN-01: Stale priority-rank comment in audit-claims.sh

**File:** `bin/audit-claims.sh:665-666`
**Issue:** "Priority-rank order: stale(1) -> epistemic(2) -> recency(3) -> fanout(4)" omits `derived-report(5)`, added one screen above.
**Fix:** Append `-> derived-report(5)`.

### IN-02: `_resolve_ref` nits — shadowed import, misleading docstring, truncated multi-line bullets

**File:** `bin/audit-claims.sh:423-443`
**Issue:** (a) `import re` inside the function shadows the module-level import (harmless, but inconsistent with every other resolver). (b) Docstring says "Searches candidate headers in order: ... (first match wins)" — actual behavior is first-in-document wins via a single alternation regex, not priority order across header names; a stray early `## Sources` section would beat a later `## References` bibliography. (c) `^- (.+)` returns only the first line of a bullet; wrapped/multi-line bibliography entries are silently truncated.
**Fix:** Drop the inner import; reword the docstring ("first matching header in document order"); optionally capture continuation lines.

### IN-03: D-09 enum check lets `source_type: ""` pass

**File:** `bin/lint.sh:1098-1102`
**Issue:** `if st and st not in VALID_SOURCE_TYPES` — an explicitly empty `source_type: ""` passes both the missing-field check (`'source_type' in fm` is True) and the enum check (falsy `st` short-circuits). Matches the pre-existing `compilation_status` idiom, so consistent, but it leaves a typo-adjacent hole D-09 was meant to close.
**Fix:** `if st not in VALID_SOURCE_TYPES:` for source pages (empty string then errors), or explicitly flag empty values.

### IN-04: DR overstates the PDF/video verdicts as settled

**File:** `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md:48`
**Issue:** "(PDF verdict: article sub-case; video: transcript sub-case)" — the authoritative registry (`schema/reference/source-types.md:49-53`) marks both rows **provisional** ("sub-case of `article` or `paper` (provisional)"), with Phases 20/21 finalizing. The DR reads as if the verdicts are final.
**Fix:** Add "(provisional, finalized in Phases 20/21)" to the DR sentence.

### IN-05: Worklist `support_type` taken from the FIRST marker on a multi-marker line

**File:** `bin/audit-claims.sh:811-815`
**Issue:** `mprov = PROV_RE.search(line_text)` always grabs the first marker, even when the claim tuple being processed corresponds to a later marker on the same line (multi-marker lines exist, e.g. `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md:62` has two markers). The worklist/verifier `support_type` can therefore belong to a different marker than `(source_id, locator)`. Pre-existing, but the new `derived-report` tier samples these lines.
**Fix:** Carry the matched support type through `claim_tuples_for_page` (it already iterates `PROV_RE.finditer`; add `m.group(3)` to the tuple).

### IN-06: AGENTS.md inclusion-audit baseline not re-stamped after adding the routing row

**File:** `AGENTS.md:7-8`
**Issue:** Baseline reads `287 lines @ 2026-06-05`; the file is now 288 lines after the source-types routing row. Within the lint AUDIT drift tolerance (no finding fires), but the comment's own instruction is to justify the line and update the baseline.
**Fix:** Re-stamp `<!-- inclusion-audit: 288 lines @ 2026-06-11 -->` in both AGENTS.md and CLAUDE.md (the row is dispatch-class, so it passes the inclusion test).

### IN-07: D-08 is single-tier — wiki-local topic pages citing a cloud research-report are never checked

**File:** `bin/lint.sh:94,1022,1130-1157`
**Issue:** Lint walks only `WIKI_DIR` (default `wiki-cloud/`); a `wiki-local/` topic page citing a `wiki-cloud/` research-report with `|direct|` is invisible to D-08 in default runs, and running `bin/lint.sh wiki-local/` would instead produce false "Broken prov ref" errors because the source registry would then contain only local source pages. Inherited single-tier lint architecture (pre-existing), but D-08's anti-laundering guarantee is therefore cloud-tier-only — worth a one-line scope note in the DR or `schema/workflows/lint.md`.
**Fix:** Document the scope limit, or (larger change) build the source registry across both tiers the way `bin/audit-claims.sh` already does.

---

## Resolution (2026-06-11)

All 14 findings fixed inline and verified:

- **WR-01** — `_resolve_sec` in `bin/audit-claims.sh` relaxed: exact slug match preferred, contiguous hyphen-token subsequence match as fallback. The 3 residual locators that token-matching cannot reach (dot-collapsed heading slug) were corrected on the citing pages. Empirical re-run: 0 of 158 tier-5 claims unresolvable (was 78 of 110). The suggested resolvable-ratio floor was also added as a warning-only tripwire (stderr banner + warning finding when <50% of resolution attempts succeed, min 5 attempts; exit code unchanged — review-only contract preserved), documented in `schema/workflows/audit.md`.
- **WR-02** — locator (group 2) and support_type (group 3) now normalized at extraction in `claim_tuples_for_page` (single site fixes findings, worklist, and the `--apply-verdicts` join key); `resolve_locator` also strips defensively. Verified: 0 trailing-backslash locators in a full tier run.
- **WR-03** — D-08 exemption restricted to genuine self-citation (`type: source` AND `id == source_id`). Verified by injection: a source page citing a different report with `|direct|` now errors.
- **WR-04** — D-08 now flags ANY non-`derived` support type (direct, inferred, tentative, omitted) on report citations. Verified by injection of a bare marker.
- **WR-05** — self-citation carve-out documented in `schema/reference/source-types.md` (Provenance + checklist item 4) and the `schema/workflows/ingest.md` granularity row.
- **WR-06** — unknown `--select` names now exit 1 with the valid list; usage text lists all five selectors.
- **WR-07** — `src-2026-05-04-financial-ai-repo-comparison-report` retro-classified to `research-report` (no `## References` — raw source has no bibliography, graceful degradation); 46 downstream `|direct|` markers swept to `|derived|` across 8 pages; 6 entity pages re-graded `sourced` → `mixed`; recorded in the DR and `wiki-cloud/log.md`.
- **IN-01** — rank comment now includes `derived-report(5)`.
- **IN-02** — shadowed `re` import dropped, docstring corrected to document-order semantics, wrapped bullets capture continuation lines.
- **IN-03** — explicitly empty `source_type` now errors (D-09).
- **IN-04** — DR marks the PDF/video sub-case verdicts provisional (finalized in Phases 20/21).
- **IN-05** — each claim tuple carries its own marker's support_type; the first-marker re-extraction is gone.
- **IN-06** — inclusion-audit baseline re-stamped (288 lines @ 2026-06-11) in AGENTS.md and CLAUDE.md.
- **IN-07** — D-08 tier-scope limit documented in `schema/workflows/lint.md` (provenance step).

LINT_VERSION bumped 1.9.0 → 1.9.1. Full lint: 0 errors. Neutrality and sync gates green.

---

_Reviewed: 2026-06-10T22:59:09Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

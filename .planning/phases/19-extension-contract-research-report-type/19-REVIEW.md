---
phase: 19-extension-contract-research-report-type
reviewed: 2026-06-11T00:00:00Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - AGENTS.md
  - CLAUDE.md
  - bin/audit-claims.sh
  - bin/lint.sh
  - schema/reference/frontmatter.md
  - schema/reference/provenance.md
  - schema/reference/source-types.md
  - schema/workflows/audit.md
  - schema/workflows/ingest.md
  - wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md
  - wiki-cloud/sources/src-2026-06-09-pdf-to-text-llm-ingestion-sota.md
  - wiki-cloud/sources/src-2026-04-16-claude-code-frameworks-report.md
  - wiki-cloud/log.md
  - wiki-cloud/index.md
  - wiki-cloud/entities/claude-code.md
  - wiki-cloud/entities/gsd.md
  - wiki-cloud/entities/spec-kit.md
  - wiki-cloud/entities/superpowers.md
  - wiki-cloud/entities/omnidocbench.md
  - wiki-cloud/entities/olmocr.md
  - wiki-cloud/concepts/subagents.md
  - wiki-cloud/concepts/vlm-ocr-hallucination.md
  - wiki-cloud/concepts/progressive-disclosure.md
  - wiki-cloud/concepts/spec-driven-development.md
  - wiki-cloud/overviews/agent-skills.md
  - wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md
  - wiki-cloud/comparisons/claude-code-orchestration-frameworks.md
  - wiki-cloud/overviews/pdf-text-extraction-for-llm-ingestion.md
findings:
  critical: 2
  warning: 8
  info: 4
  total: 14
status: issues_found
---

# Phase 19: Code Review Report

**Reviewed:** 2026-06-11
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Summary

Phase 19 added a source-type extension contract, the `#r<n>` locator + `derived-report` audit selector, D-08/D-09 lint checks (v1.9.0), and a `|direct|` → `|derived|` sweep across 14 pages. The schema files are internally consistent, the `#r<n>` resolver was verified to resolve correctly against both raw bibliographies (12 and 15 bullets, positional alignment confirmed against the `## References` registries), and the prose sweep was correctly scoped (primary-source markers untouched).

However, the phase's central deliverable — the anti-epistemic-laundering guarantee — is broken at HEAD. Markdown tables escape pipes as `\|`, so table-cell markers read `\|direct\|`. The sweep's grep/sed targeted only unescaped `|direct|`, leaving **11 live `direct` markers citing the two research-report sources** in the two comparison pages. Worse, the D-08 lint check shares the same blind spot: `PROV_RE` captures the support type as `direct\` (trailing backslash), so `support_type == 'direct'` never fires on table markers. Verified empirically: `bin/lint.sh --dry-run` reports **0 errors** against a tree containing 11 D-08 violations. The decision record's claim "All 103 `|direct|` markers ... were rewritten" and the 19-03 summary's "residual = 0 confirmed" are both false — the true pre-sweep total was 114.

## Critical Issues

### CR-01: D-08 lint gate is blind to escaped-pipe markers in markdown tables (BLOCKER)

**File:** `bin/lint.sh:449-454` (PROV_RE), `bin/lint.sh:1147-1156` (D-08 check)
**Issue:** Inside markdown table cells, provenance markers are written with escaped pipes: `[prov:<id>#sec:x\|direct\|2026-06-09]`. `PROV_RE` (`[^|\]]+` for locator and support_type) treats the backslash as a content character, capturing the support type as `'direct\'` and the locator as `'sec:x\'`. The D-08 comparison `support_type == 'direct'` is therefore always false for table markers, and the anti-laundering gate silently passes in exactly the context (comparison tables) where the wiki's own pages use it. Verified:

```
>>> PROV_RE groups on a real table row from claude-code-orchestration-frameworks.md:48
('src-2026-04-16-claude-code-frameworks-report', 'sec:comparative-matrix\\', 'direct\\', '2026-06-09')
```

`bin/lint.sh --dry-run --category provenance` returns 0 errors despite 11 live violations (CR-02). The same `PROV_RE` byte-copy lives in `bin/audit-claims.sh:173-178`, where the worklist's `support_type` field will carry `direct\` for these claims (the locator survives because `_slugify` strips the backslash).
**Fix:** Normalize escaped pipes before matching in the provenance scan (the scan uses `findall`, no positional offsets needed):

```python
prov_matches = PROV_RE.findall(mask_markdown(body).replace('\\|', '|'))
```

or strip trailing backslashes from the captured groups before comparison: `support_type = support_type.rstrip('\\')` (apply the same normalization to `locator`). Apply the identical fix to the copied symbols in `bin/audit-claims.sh` (per the script's own "re-copy on drift" contract, `bin/audit-claims.sh:144-153`). Add a table-cell `\|direct\|` case to whatever hard-negative test exercised D-08.

### CR-02: 11 unswept `\|direct\|` markers citing research-report sources remain on dependent pages (BLOCKER)

**File:** `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md:48`, `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md:48-52`
**Issue:** The retro-classification sweep converted 103 prose markers but missed all 11 escaped table-cell markers (1 in the frameworks comparison table, 10 across five rows of the OCR comparison table — two markers per row on lines 48-52). These are live epistemic-laundering defects under the phase's own D-08 rule: claims citing `source_type: research-report` sources with `direct` support. Consequently:
- `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md:70` ("All 103 `|direct|` markers across 14 dependent wiki pages ... were rewritten to `|derived|`") is factually wrong — the pre-sweep total was 114, and 11 remain.
- `.planning/phases/.../19-03-SUMMARY.md` ("binding acceptance criterion (residual = 0) confirmed after sweep") is wrong; the residual grep used the unescaped pattern and could not see table markers.
**Fix:** Rewrite the 11 table markers to `\|derived\|`:

```bash
sed -i 's/\\|direct\\|/\\|derived\\|/g' \
  wiki-cloud/comparisons/claude-code-orchestration-frameworks.md \
  wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md
```

(scoped to the report-citing markers — in these two files every `\|direct\|` cites a research-report source, verified by grep). Correct the count claim in the decision record (`103` → `114`, or state "103 prose + 11 table markers").

## Warnings

### WR-01: D-08 exemption for source pages is over-broad — exempts cross-citations, not just self-citations

**File:** `bin/lint.sh:1148-1149`
**Issue:** The check skips any page with `fm.get('type') == 'source'`. The stated intent (comment, and DR §4) is that "source summary pages self-cite with direct (correct)". But the implementation also exempts a source page citing a *different* research-report source with `|direct|` — which is the same laundering defect the rule exists to catch (e.g. a future article-type source summary whose contradiction note cites a research-report directly).
**Fix:** Exempt only the self-citation case:

```python
if fm.get('type') == 'source' and fm.get('id') == source_id:
    continue  # self-citation of own raw source is correctly direct
```

### WR-02: D-08 under-enforces the documented "derived-only" MUST — bare and inferred/tentative markers pass

**File:** `bin/lint.sh:1152-1156`; contract in `schema/reference/source-types.md:65` and `schema/workflows/audit.md` ("the only valid support type for research-report sources")
**Issue:** The schema mandates "ALL claims extracted from a research-report source MUST use `support_type: derived`". The lint check only flags `support_type == 'direct'`. A basic-form marker `[prov:<report-id>#sec:x]` (no support type — the schema's documented basic form), or `|inferred|` / `|tentative|`, passes silently. No such markers exist today, so the hole is latent, but the gate does not enforce the contract it claims to enforce.
**Fix:** Flag any non-`derived` support type (including empty) on research-report citations from non-source pages, or narrow the schema text to match the implemented scope ("`direct` is an error") if bare markers are intentionally tolerated.

### WR-03: `_resolve_ref` docstring promises priority-order header search; implementation is document-order

**File:** `bin/audit-claims.sh:423-443`
**Issue:** The docstring says "Searches candidate headers in order: ## Source Citations, ## Sources by Topic, ## Sources, ## References (first match wins)" — implying candidate priority. The implementation compiles one alternation and takes `header_re.search(text)`, i.e. the first matching header *by document position*. A raw source containing an early non-bibliography `## Sources` section before its real `## Source Citations` block would silently bind `#r<n>` to the wrong section and return wrong passages (a faithfulness-audit correctness risk, not a crash). Both current raw sources happen to have exactly one matching header, so the defect is latent. Secondary limitations worth a comment: only h2 (`## `) headers are recognized (an `# References` h1 or `### References` h3 bibliography degrades to `insufficient-locator`), and only column-0 `- ` bullets count (numbered `1.` bibliographies degrade too — consistent with source-types.md's "nth bullet" wording, but worth stating).
**Fix:** Iterate candidates in priority order:

```python
for name in ('Source Citations', 'Sources by Topic', 'Sources', 'References'):
    m = re.search(rf'^##\s+{re.escape(name)}\s*$', text, re.MULTILINE | re.IGNORECASE)
    if m:
        break
else:
    return None
```

or fix the docstring to say "first matching header in document order".

### WR-04: `--select` help text and rank comment not updated for the 5th selector

**File:** `bin/audit-claims.sh:50-51` (usage: "Subset of selectors: stale,epistemic,recency,fanout (default: all four)"), `bin/audit-claims.sh:665-666` (comment: "Priority-rank order: stale(1) -> epistemic(2) -> recency(3) -> fanout(4)")
**Issue:** The default `SELECT` (line 71) and `RANK` (line 631) gained `derived-report`, but the user-facing `--help` still lists four selectors and says "default: all four". An operator reading `--help` cannot discover `derived-report`, the selector the phase shipped.
**Fix:** Update usage to `stale,epistemic,recency,fanout,derived-report (default: all five)` and extend the rank-order comment with `-> derived-report(5)`.

### WR-05: provenance.md Support Types table now contradicts the research-report mandate

**File:** `schema/reference/provenance.md:60-67`
**Issue:** The phase added the `#r<n>` locator row and degradation note to provenance.md but left the Support Types table untouched. `direct` is defined as "Claim is directly stated in the source" — which literally describes a verbatim claim quoted from a research-report, yet using `direct` there is now a lint *error*. `derived` is defined only as "Synthesized from multiple parts of the source or across sources", with no mention of the new mandatory-for-secondary-sources semantics. provenance.md is the file the routing table sends agents to for support types (and source-types.md's See Also defers to it for "support_type values"), so an agent following the router will author exactly the markers D-08 rejects.
**Fix:** Add a sentence/cross-reference to the Support Types section: claims citing `source_type: research-report` (secondary) sources MUST use `derived` regardless of how directly the report states them — see `schema/reference/source-types.md`.

### WR-06: 13 of 14 swept pages did not get `updated_at` bumped

**File:** `wiki-cloud/entities/{claude-code,gsd,spec-kit,superpowers,omnidocbench,olmocr}.md`, `wiki-cloud/concepts/{subagents,progressive-disclosure,spec-driven-development}.md`, `wiki-cloud/overviews/{agent-skills,pdf-text-extraction-for-llm-ingestion}.md`, `wiki-cloud/comparisons/{ocr-pipeline-vs-vlm-ingestion,claude-code-orchestration-frameworks}.md` (frontmatter `updated_at: 2026-06-09`)
**Issue:** `schema/reference/frontmatter.md:44` defines `updated_at` as "ISO 8601 date when the page was last modified". All 14 pages were modified on 2026-06-10 by the sweep, but only `vlm-ocr-hallucination.md` (which also had an `epistemic_status` change) was bumped. Besides the schema violation, lint's stale-claim check uses `updated_at` as the `checked_at` fallback (`bin/lint.sh:1440-1445`), so the stale metadata feeds the decay math.
**Fix:** Set `updated_at: 2026-06-10` on the 13 remaining swept pages (can ride along with the CR-02 fix commit).

### WR-07: log.md tail is internally inconsistent — leaked test-run entries and scoped runs logged as full health checks

**File:** `wiki-cloud/log.md:594-641`
**Issue:** Two defects in the committed activity log:
1. The final entry (line 638, `[2026-06-11] lint ... findings: 1 total (1 errors ...) report: wiki-cloud/maintenance/lint-report.md`) does not match the committed `lint-report.md` (last run 2026-06-10, 73 findings, 0 errors). This looks like the D-08 hard-negative test run (inject a `|direct|` marker, lint, revert) whose log append was committed while its report was reverted — the log's last word on wiki health is a phantom error pointing at a report that disproves it.
2. Five near-duplicate `[2026-06-10] lint | wiki-cloud health check` entries (lines 594-618) alternate `73 total` / `0 total` — the `0 total` entries are category-scoped runs recorded with the same "wiki-cloud health check" title as full runs, misrepresenting wiki health to any reader of the log.
**Fix:** Remove (or annotate as test runs) the phantom 2026-06-11 single-error entry and the scoped-run `0 total` entries; going forward, do not let `--category` runs append full-health-check log entries, and run negative tests with `--dry-run` so no log/report mutation occurs.

### WR-08: The 14-page marker sweep itself was never logged

**File:** `wiki-cloud/log.md:624-630`
**Issue:** AGENTS.md §9 requires every wiki mutation to go through a structured operation "with mandatory logging". The log records UPDATE entries only for the two source pages (retro-classification + References registries). The sweep that rewrote 103 markers across 14 dependent pages — the largest content mutation in the phase — has no log entry at all; a future agent reading the log cannot discover why every report-citing marker changed on 2026-06-10.
**Fix:** Append one UPDATE (or `lint`-style batch) entry summarizing the sweep: source ids, 14 affected pages, `|direct|` → `|derived|`, reason (D-08 retro-classification).

## Info

### IN-01: Redundant local `import re` in `_resolve_ref`

**File:** `bin/audit-claims.sh:434`
**Issue:** `re` is already imported at module top (line 137); the function-local `import re` is dead weight and inconsistent with every other resolver in the file.
**Fix:** Delete the line.

### IN-02: Vault-roadmap references embedded in a template-public schema file

**File:** `schema/reference/source-types.md:45,49-51`
**Issue:** "Phases 20 and 21 finalize the pdf and video rows", "(Phase 20)", "Pairs with 999.5 drift machinery" reference this vault's private `.planning/` roadmap. `schema/` ships in the public template (the neutrality rule explicitly covers "examples in schema docs"); these references are meaningless to template consumers and leak development-process internals. Not slugs, so `check-neutrality.sh` won't catch them.
**Fix:** Replace with neutral wording ("a future evaluation finalizes...", "deferred pending drift machinery") or strip at release time.

### IN-03: Decision record wording defects

**File:** `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md:48,76-81`
**Issue:** (a) "The mechanical defense is three-layered:" is followed by four numbered layers. (b) "PDF verdict: article sub-case" drops the qualifier from the authoritative table, which says "sub-case of `article` or `paper` (provisional)" — the DR presents a seeded provisional verdict as settled.
**Fix:** "four-layered" (or merge two layers); "PDF verdict: provisional article/paper sub-case, finalized by the PDF walk-through".

### IN-04: ingest.md granularity table still lists generic "report" as an article/paper sub-case

**File:** `schema/workflows/ingest.md` (Claim Granularity table, first row)
**Issue:** The first row reads "article, paper, report, technical doc — sub-cases of `article` or `paper`" while a new `research-report` row sits three rows below. An agent classifying an AI-synthesized report could match the word "report" in row 1 and pick atomic-`direct` extraction instead of the derived-only row.
**Fix:** Rename the row-1 term to "primary report / technical doc" or add "(not research-report — see below)".

---

_Reviewed: 2026-06-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

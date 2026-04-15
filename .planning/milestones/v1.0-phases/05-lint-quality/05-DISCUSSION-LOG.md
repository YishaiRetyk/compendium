# Phase 5: Lint & Quality - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-13
**Phase:** 05-lint-quality
**Areas discussed:** Contradiction detection strategy, Staleness thresholds & decay rates, Lint report format & fix policy, Knowledge gap detection heuristics

---

## Contradiction Detection Strategy

### What counts as a contradiction?

| Option | Description | Selected |
|--------|-------------|----------|
| Source-level disagreement | Two different sources assert conflicting claims. Focus on factual disagreements traceable to provenance markers. | ✓ |
| Claim-level semantic conflict | Any two logically incompatible claims anywhere in the wiki, even from the same source or inferred. | |
| Epistemic status mismatch | Flag when sourced claims conflict with tentative/inferred claims on another page. | |

**User's choice:** Source-level disagreement
**Notes:** User provided detailed rationale: grounded in provenance, auditable, avoids overclaiming semantic certainty. Semantic conflict stays out of v1 scope. Potential future lighter category ("tension" or "possible_conflict") for weaker clashes.

### How should contradictions be flagged in pages?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline marker on conflicting claims | Add marker like [contradiction:src_a vs src_b] directly on the claim. | ✓ |
| Dedicated contradictions section per page | Add a '## Contradictions' section at bottom of affected pages. | |
| Centralized contradictions page only | Don't modify wiki pages; contradictions live only in lint report. | |

**User's choice:** Inline marker on claims + centralized lint report as secondary aggregation
**Notes:** Fits existing design — provenance is inline, epistemic status is inline, contradiction flags should be inline too. User suggested example syntax patterns. Best architecture: primary flag = inline, secondary aggregation = lint output / contradictions index.

### Should lint auto-update epistemic_status for contradictions?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, set to 'mixed' | Reuse mixed to signal uncertainty from contradicting sources. | |
| No, leave epistemic_status unchanged | Keep contradiction and epistemic status as independent dimensions. | ✓ |
| You decide | Let Claude determine the approach. | |

**User's choice:** Keep independent — add new `has_contradictions` frontmatter field instead
**Notes:** User rejected overloading `mixed`: sourced means "grounded in sources" not "sources agree." Mixed already means something else (mix of sourced/inferred/tentative). Clean model: epistemic_status = support quality, has_contradictions = whether sourced claims conflict. Solves discoverability without muddying mixed.

---

## Staleness Thresholds & Decay Rates

### How should decay categories be organized?

| Option | Description | Selected |
|--------|-------------|----------|
| Per knowledge domain | Decay rates by topic area (software ~6mo, biography ~5yr, etc.). | ✓ |
| Per source type | Decay tied to source classification (article, paper, journal entry). | |
| Per claim epistemic status | Decay tied to evidence quality (sourced, inferred, tentative). | |

**User's choice:** Per knowledge domain as primary, with epistemic status as secondary modifier and source hash as override
**Notes:** User designed a three-layer model: domain base → epistemic modifier → hash override. Example rates provided. If a claim is tentative, decay faster than domain default. If source changed, mark stale regardless.

### Where should decay rate definitions live?

| Option | Description | Selected |
|--------|-------------|----------|
| In AGENTS.md section 6 | Add decay rate table to existing Provenance/Epistemics/Staleness section. | ✓ |
| Separate config file in schema/ | Dedicated schema/decay-rates.md file. | |
| Per-page frontmatter override | Each page declares its own decay_rate. | |

**User's choice:** AGENTS.md §6 with pages referencing via a domain field
**Notes:** Centralized definitions, per-page applicability via frontmatter field.

### Should lint auto-fix stale claims?

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-fix epistemic markers | Auto-set stale markers when claims cross decay threshold. | ✓ (with limits) |
| Report only, manual fix | Lint flags but doesn't touch pages. | |
| You decide | Let Claude determine. | |

**User's choice:** Auto-fix claim-level markers; cautious on page-level status
**Notes:** Claim-level staleness is precise and mechanical — auto-fix is appropriate. Page-level epistemic_status is a rollup and easier to muddy. Only update page-level if rollup clearly requires it (all material stale, or TL;DR materially stale).

---

## Lint Report Format & Fix Policy

### How should lint report be delivered?

| Option | Description | Selected |
|--------|-------------|----------|
| Wiki page + CLI summary | Persistent report page + compact CLI stdout output. | ✓ |
| CLI output only | Ephemeral stdout output, no persistent file. | |
| Dedicated lint directory | Timestamped files per lint run. | |

**User's choice:** Wiki page + CLI summary
**Notes:** User agreed with recommendation but refined placement: prefer `wiki/maintenance/lint-report.md` over `wiki/overviews/` because lint output is operational state, not topic synthesis. CLI prints counts by finding type, top critical findings, auto-fix summary.

### Should lint findings have severity levels?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, three tiers | error / warning / info | ✓ |
| Yes, two tiers | finding / suggestion | |
| No severity levels | Organized by category only. | |

**User's choice:** Three tiers
**Notes:** Define tiers explicitly in AGENTS.md. Important: contradictions are warnings, not errors — source disagreement is not a system failure.

### What's the auto-fix boundary?

| Option | Description | Selected |
|--------|-------------|----------|
| Mechanical fixes only | Deterministic + reversible = auto-fix. Judgment = report only. | ✓ |
| Conservative — report everything | Lint never modifies pages. | |
| You decide | Let Claude determine. | |

**User's choice:** Mechanical fixes only
**Notes:** "Obvious" defined narrowly for provenance repair — any ambiguity means report-only.

---

## Knowledge Gap Detection Heuristics

### When should a red link trigger a finding?

| Option | Description | Selected |
|--------|-------------|----------|
| Frequency threshold (2+ pages) | Flag when red link appears on 2+ distinct pages. | ✓ (with exception) |
| Always flag all red links | Every unresolved wikilink reported. | |
| Context-aware flagging | Flag red links in high-visibility sections regardless of count. | |

**User's choice:** Frequency threshold (2+ pages) plus high-salience exception
**Notes:** Default rule: 2+ distinct pages. Exception: TL;DR / Key Facts red links are always reportable. Hybrid of options 1 and 3 for low noise + good recall.

### How should sparse source coverage be measured?

| Option | Description | Selected |
|--------|-------------|----------|
| Relative to other domains | Compare source counts across knowledge domains. Flag outliers. | ✓ |
| Absolute minimum threshold | Flag any domain with fewer than N sources. | |
| You decide | Let Claude determine. | |

**User's choice:** Relative to other domains with maturity guardrail
**Notes:** Sparse is inherently comparative. Don't run until wiki has enough domains/sources for comparison to be meaningful. Prevents false alarms on young wikis where every domain is equally thin.

### Should lint suggest sources or just flag gaps?

| Option | Description | Selected |
|--------|-------------|----------|
| Flag gap + suggest questions | Flag gap and suggest investigative questions. | ✓ |
| Flag gap only | Report the gap, user decides what to do. | |
| Flag gap + suggest source types | Suggest kinds of sources that would help. | |

**User's choice:** Flag gap + suggest questions
**Notes:** Matches LINT-06. Actionable without being prescriptive about specific sources.

---

## Claude's Discretion

- Exact inline syntax for contradiction markers
- Exact decay rate numbers per domain
- CLI `bin/lint.sh` implementation details
- Lint report page structure and Dataview frontmatter
- Maturity threshold for sparse coverage detection
- Whether `wiki/maintenance/` is a new directory or integrated differently

## Deferred Ideas

None — discussion stayed within phase scope

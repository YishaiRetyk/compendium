---
title: "Research-report ingest — a secondary-source type for Claude/ChatGPT/Perplexity deep research (deferred)"
trigger_condition: "First time you want to ingest a Claude/ChatGPT/Perplexity (or similar) deep-research report into the wiki and keep its sources/references — i.e. an external AI-synthesized artifact with its own bibliography needs to land as a curated source. Pairs naturally with 999.5 (External Source Drift) when the report's cited URLs need monitoring."
planted_date: 2026-06-04
milestone_hint: v1.3+ (or standalone; NOT v1.2 — that milestone is extraction, not new capability)
---

# Research-report ingest — secondary-source type for AI deep research (deferred)

## What

A new `source_type: research-report` (working name) plus an ingest convention for absorbing an
AI-generated deep-research report (Claude / ChatGPT / Perplexity / similar) **as a curated source**,
preserving its bibliography as provenance instead of flattening its synthesis into bare wiki claims.

**The framing that makes this fit the architecture (the load-bearing distinction):** separate
*performing* research from *ingesting* a research artifact.

- **Do NOT add a web-research operation.** A 5th operation would make the LLM the *sourcer* (breaking
  the human-curates-sources role division), and it is an explicit ROADMAP non-goal ("No broad
  web-ingestion system", 999.5). The four-op vocabulary (ingest/query/lint/reflect) stays intact.
- **DO add a secondary-source *type*.** A deep-research report is one curated artifact ingested like
  any other source — this is NOT a "broad web-ingestion system", so it does not violate the non-goal.
- **The loop is already ~80% built:** lint/query already surface knowledge gaps and emit "suggested
  questions / sources to find" (D-23). The human runs deep research externally; the *report* comes back
  as a source; ingest preserves its citations. The only missing piece is the ingest path for that
  artifact type.
- *(Optional, controlled live-fetch variant — explicitly bounded:* a web-assist *inside the existing
  query workflow* may fetch to answer, but anything fetched MUST be registered as a source and every
  claim provenance-tracked. Web-assist produces sources; it never bypasses the source model. This is
  the only form of "live research" that doesn't break the architecture. Likely out of scope even when
  this seed promotes — note it, don't build it by default.)*

## Provenance model — report-as-source with a promotion path (the design crux)

The core question is *what counts as the source* — the report, or the pages it cites. Three options;
**recommend C**:

| Model | Source is… | Chain | Verdict |
|-------|-----------|-------|---------|
| A — Report-as-source | the whole report (1 source) | wiki-claim → report → (URL inside) | simple; second-order |
| B — Citations-as-sources | each cited page (N sources) | wiki-claim → primary page (direct) | over-engineered (30+ src/report, link rot, you often only have the report's paraphrase) |
| **C — Hybrid (RECOMMEND)** | report is primary; bibliography captured as an addressable **citation registry**; any citation **promotable** to a first-class source when a claim earns it | wiki-claim → report#ref → URL, upgradable to direct | balanced; mirrors red-link / seed / backlog-promotion patterns (capture cheap now, upgrade when load-bearing) |

## Ingest mechanics (Model C)

1. **Save the raw report WITH its bibliography intact** → `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/source.md`.
   The reference list **is part of the immutable source** — never strip it (Perplexity numbered
   `[n]`+URLs, ChatGPT/Claude sources section — keep all of it).
2. **`source_type: research-report`** — small schema addition (§5 source-type enum + §10 Pass 0
   classify list). Flags the report as a *synthesized secondary* source, changing downstream treatment.
3. **Capture the bibliography in the source summary** as structured, addressable data — a `## References`
   block and/or frontmatter `cited_urls` (URL, title, access-date). This is the citation registry.
4. **Second-order provenance + honest support type.** Extracted claims cite the report
   (`[prov:src-…-report#sec:X]`) with `support_type: derived` (NOT `direct`). Reuse the report's own
   footnote anchors as locators (a `#r3`-style reference-locator needs no new grammar — the locator
   table already allows arbitrary `#sec:`/`#para` forms).
5. **Lower default epistemic tier + audit flag.** Default `epistemic_status: mixed` (or `tentative`);
   claims are prime targets for `bin/audit-claims.sh`.

## The risk this exists to prevent: epistemic laundering

The failure mode is NOT mechanical — it's that an AI report's hallucinated/unsupported citations get
ingested and the wiki then asserts them with a provenance marker that *looks* as solid as a hand-read
paper. Two reports citing each other can manufacture false consensus. The defenses are all already in
the system and must be **encoded, not flattened**: `support_type: derived`, a lower epistemic default,
the Phase 13 faithfulness audit, and the `research-report` type making the secondary-ness *visible* so
a reader knows to trace it. The provenance discipline makes compendium *better* at absorbing AI research
than a plain notes app — but only if the second-order-ness is recorded rather than erased.

## Why this is deferred

1. **No artifact yet.** Trigger is the first real deep-research report you want to file — build it then,
   against a concrete example, not speculatively.
2. **Not v1.2.** v1.2 Schema Architecture is extraction (relocating existing text); this is *new
   capability* (new source type + ingest convention + epistemic policy). Different theme.
3. **Pairs with 999.5.** The report's `cited_urls` are URL-backed sources — the natural trigger to
   finally promote External Source Drift detection. Best designed together or back-to-back.

## Out of scope at revisit time

- A 5th "web research" operation / free-roaming research agent (breaks role division + 999.5 non-goal).
- Broad web-ingestion / RAG-style auto-crawl (explicit non-goal).
- Auto-promoting every citation to a first-class source (Model B by default) — promote on demand only.
- Ingesting a report's claims as `direct`/high-epistemic without the secondary-source markers (the
  laundering anti-pattern this seed exists to prevent).
- Sending `local_only`-derived research prompts/results to cloud — standard §13 / two-dir privacy rules
  still apply (a research report is normally cloud-derived → `cloud_safe`, but confirm per artifact).

## Revisit trigger

Surface when ANY becomes true:
- You have a concrete Claude/ChatGPT/Perplexity deep-research report you want in the wiki with its refs.
- 999.5 (External Source Drift) is promoted — design the URL-backed citation registry alongside it.
- Lint/query gap-suggestions are routinely answered by external deep research and the manual
  copy-paste-without-provenance friction appears.

## Unification (Source Ingestion cluster)

This seed and `[[primary-source-type-extensions]]` (repos, videos) are **co-instances of one
"source-type extension" pattern** — same surfaces (§5 enum, §10 Pass 0, §6 locators, §11.1 ingest,
999.5 drift, `support_type` defaults). Per the 2026-06-04 unification decision: **unify the *design*,
not the *deliverable*.** A future "Source Ingestion" milestone designs the extension *contract* once
(the 5-dimension recipe + primary/secondary axis), then ships per-type implementations independently.
**This seed is the LOCKED reference *secondary* instance and ships first — it does NOT wait on the open
repo/video work.** See `.planning/notes/2026-05-31-milestone-grouping-proposal.md` → "Source Ingestion".

## Related artifacts

- Binding role-division + source-of-truth framing: `.planning/notes/2026-04-24-openbrain-vs-compendium-critique.md`
- Cross-linked backlog: ROADMAP.md Phase 999.5 (External Source Drift Detection) — URL-backed source drift
- Faithfulness defense: `wiki/maintenance/audit-report.md` + `bin/audit-claims.sh` (Phase 13);
  design notes `phases/13-claim-faithfulness-audit/13-DESIGN-NOTES.md`
- Source-type enum + classify: AGENTS.md §5 (`source_type`), §10 Pass 0
- Provenance grammar this reuses: AGENTS.md §6 (locators, `support_type: derived`, epistemic markers)
- Gap-suggestion loop already shipped: AGENTS.md §11.3 lint (knowledge-gap / suggested questions, D-23)
- Privacy: AGENTS.md §13 + the v1.2 Phase-0 two-dir model (`.planning/milestones/v1.2-MILESTONE-BRIEF.md`)

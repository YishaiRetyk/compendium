---
title: "Primary source-type extensions — code repositories (GitHub) and videos (YouTube)"
trigger_condition: "Active intent: the creator wants to ingest GitHub repos and YouTube videos as first-class sources. Promote to /gsd-discuss-phase when ready to plan; NOT in v1.2 (that milestone is extraction, not new capability)."
planted_date: 2026-06-04
milestone_hint: v1.3+ or standalone (repository pairs with 999.5 External Source Drift)
---

# Primary source-type extensions — repositories + videos

## What

Two **primary** source types the creator actively wants to ingest:

- **Code repositories (GitHub)** — currently ingested informally *as entities* (OpenBB, FinRL, Dexter,
  TradingAgents, FMNM all have entity pages + source summaries + the Financial-AI comparison/overview).
- **Videos (YouTube)** — currently ingested *as transcripts* (the Hack "Systems Thinking" + "DDD"
  videos). The `#t00:12:10-00:12:48` timestamp locator (§6) already exists for these.

So the system already absorbs both; this seed is about deciding whether/how to **formalize** their
acquisition, locators, drift, and epistemic handling. **Both are primary** (the actual artifact), in
contrast to the secondary/synthesized `research-report` seed (`[[research-report-ingest]]`).

## Decision framework (a lens for discuss — NOT a verdict)

A new `source_type` is justified only if the candidate changes one of: **acquisition** (how you get the
raw text), **locator scheme** (how `[prov:#locator]` points in), **extraction logic** (§10 granularity),
**drift mechanism** (`content_hash`/staleness), or **epistemic default** (trust). If it maps cleanly onto
an existing type's locators + extraction, it's a **sub-case** (metadata + convention), not a new type.
This project leans to FEWER types (it collapsed `book`→`book-chapter`, reduced placeholders 6→4) — so the
bar should be real.

> **Deliberately NOT locked.** Unlike the research-report seed (which locked its provenance model), this
> seed keeps the design choices OPEN for `/gsd-discuss-phase`. The analysis below is *input*, not decision.

## Candidate A — code repository (leaning: distinct type, but OPEN)

Touches four of the five dimensions, so it *looks* like a real type — confirm at discuss:

- **Locator (new scheme).** A repo isn't one document: candidate locators are `#sec:` (README sections),
  `#path:src/foo.py:L157-160` (code — the line-range analog of the `#p` page marker), `#commit:<sha>`,
  `#issue:<n>`/`#pr:<n>`. *(Already used informally — the neo4j note cites `graphDB_dataAccess.py:410`.)*
- **Drift (cleanest case in the system).** `content_hash` = commit SHA at ingest; staleness = compare to
  current default-branch HEAD. Git gives precise identity AND a diff → the natural pilot for **999.5**.
- **Epistemic default (the subtle one).** A README is self-descriptive marketing. Claims may split
  *within* one source: code (`#path:…:L…`) = `direct`; capability claims ("fast", "production-ready") =
  self-described → `tentative`; benchmarks = `direct`-but-cite-the-number.
- **Metadata/decay.** Structured frontmatter (URL, SHA, license, primary language, stars-at-ingest) —
  what the financial-repos comparison already leans on; `knowledge_domain: software` (180-day decay) fits.
- **Raw source scope (open).** Likely README + key docs + metadata + SHA — NOT a full clone (the wiki
  compiles *claims about* the repo via `#path:` locators, not the repo itself). Confirm at discuss.

## Candidate B — video / YouTube (leaning: sub-case of `transcript`, but OPEN)

Appears to change only metadata + acquisition, so it *looks* like a transcript sub-case — confirm:

- **Locator (reuse).** `#t<start>-<end>` already exists — zero grammar change.
- **Extraction.** Same as any transcript — utterance/turn clusters (§10).
- **Acquisition (the real friction).** Getting a **timestamped** transcript so `#t` resolves (YouTube
  captions API, or yt-dlp + whisper). A convention/tooling note, not a type.
- **Metadata.** `url`, channel, title, publish date, duration → frontmatter.
- **Drift.** Videos are immutable once published; concern is link-rot/deletion, not content change.
- **The one thing that could push it to its own `video` type:** slide/demo-heavy videos where the audio
  transcript misses the visual content → frame capture (`#frame:<ts>` + screenshots as bundle assets,
  leaning on the existing `#img` locator + `image-heavy` handling). Open whether to handle now or defer.

## Open questions for `/gsd-discuss-phase` (do NOT pre-decide)

1. **Repo: distinct `source_type: repository`/`codebase`, or keep ingesting repos via existing types +
   entity pages?** (What does a dedicated type buy beyond the locator grammar + SHA drift?)
2. **Repo locator grammar:** which of `#path:file:L`, `#commit:`, `#issue:`/`#pr:` to add to the §6
   Locator Types table? Minimal viable set?
3. **Repo raw-source scope:** README+docs only / curated code snapshot / metadata-only-with-URL?
4. **Repo drift:** `content_hash` = commit SHA vs release tag; couple to 999.5 now or design alongside?
5. **Repo epistemics:** how to encode README-self-description (`tentative`) vs code (`direct`) vs
   benchmarks — a per-claim convention, or a source-level default?
6. **Video: sub-case of `transcript` (metadata + convention) or its own `video` type?**
7. **Video acquisition:** which timestamped-transcript path is the documented default?
8. **Video multimodal:** handle slide/demo frames (`#frame`/`#img` + assets) in scope, or defer until a
   demo-heavy video actually needs it?
9. **Privacy:** both are normally `cloud_safe`, but a private repo / unlisted video → which tier under the
   v1.2 two-dir model? (Fail-closed default still applies.)
10. **Packaging:** one type-extension effort or two separate (repos and videos may be wanted at different
    times)?

## Out of scope at revisit time

- Full repo cloning / code-as-claims wholesale ingest (compile *claims about* the repo, not the repo).
- Auto-crawling repos or channels (no broad ingestion — cf. 999.5 non-goals).
- Auto re-ingest on upstream change without human confirmation (drift *flags*, human decides).
- Proliferating types for every variant — apply the decision framework; default to sub-case.

## Why deferred (not v1.2)

New *capability* (source types + possible locator-grammar + drift hooks), not extraction. v1.2 Schema
Architecture relocates existing text; this adds behavior. v1.3-ish or standalone; repository pairs with
999.5 (shared SHA-drift machinery).

## Revisit trigger

- The creator has a concrete GitHub repo or YouTube video to ingest and wants it as a formalized source.
- 999.5 (External Source Drift) is promoted — design the repo SHA-drift alongside it.
- A slide/demo-heavy video surfaces the multimodal frame-capture need (would reopen the `video`-type Q).

## Unification (Source Ingestion cluster)

This seed and `[[research-report-ingest]]` are **co-instances of one "source-type extension" pattern** —
same surfaces (§5 enum, §10 Pass 0, §6 locators, §11.1 ingest, 999.5 drift, `support_type` defaults).
Per the 2026-06-04 unification decision: **unify the *design*, not the *deliverable*.** A future "Source
Ingestion" milestone designs the extension *contract* once (the 5-dimension recipe + primary/secondary
axis — this seed's two candidates are *primary* instances), then ships per-type implementations
independently. **`research-report-ingest` (secondary, LOCKED) ships first; repo and video here stay
separable and open** so the ready one doesn't wait on the undecided ones. See
`.planning/notes/2026-05-31-milestone-grouping-proposal.md` → "Source Ingestion".

## Related artifacts

- Primary-vs-secondary contrast: `.planning/seeds/research-report-ingest.md`
- Drift complement: ROADMAP.md Phase 999.5 (External Source Drift Detection)
- Existing precedent — repos as entities: `wiki/entities/{openbb,finrl,dexter,tradingagents,...}.md`,
  `wiki/comparisons/`, `wiki/overviews/` (Financial AI Repository landscape)
- Existing precedent — videos as transcripts: the Hack "Systems Thinking" / "DDD" source summaries
- Informal code-locator precedent: `.planning/notes/2026-05-31-neo4j-graph-tools-comparison.md` (file:line citations)
- Grammar to extend: AGENTS.md §6 Locator Types (`#t` exists; `#path:`/`#commit:`/`#frame:` candidates),
  §5 `source_type` enum, §10 Pass 0 classify list
- Decay bucket: AGENTS.md §6 `knowledge_domain: software` (180-day)
- Privacy: AGENTS.md §13 + v1.2 Phase-0 two-dir model

# Phase 3: Ingestion & Provenance Pipeline - Research

**Researched:** 2026-04-10
**Domain:** LLM-driven document ingestion pipeline, markdown wiki compilation, claim-level provenance, bash CLI tooling
**Confidence:** HIGH

## Summary

Phase 3 makes the conceptual compiler pipeline (AGENTS.md section 10) and ingest workflow (section 11.1) operational. The existing codebase already has: 5 page templates, 5 example wiki pages in the Kahneman/decision-making domain, a populated index, a populated log, full provenance and epistemic syntax documented in AGENTS.md, and structured operations vocabulary (UPDATE, MERGE, SUPERSEDE, ARCHIVE). The phase adds no new software dependencies -- it produces markdown documentation updates (AGENTS.md encoding of user decisions), a bash CLI script, and two real source ingestions that validate the full pipeline.

The core technical challenge is not infrastructure but specification clarity: encoding claim granularity rules and incremental update policy into AGENTS.md so that any LLM agent can follow the pipeline without ambiguity. The validation ingestions (article + journal entry) test both atomic and paragraph-level extraction, and critically test incremental updates to existing Phase 2 pages rather than only greenfield creation.

**Primary recommendation:** Structure the plan as: (1) AGENTS.md updates encoding decisions D-01 through D-10, (2) CLI bash script, (3) first validation ingest (article, incremental update), (4) second validation ingest (journal, different source type), (5) final verification pass. Each ingest is a complete end-to-end pipeline run.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Adaptive granularity by source type. Source classification (AGENTS.md section 10 Pass 0) drives extraction depth.
- **D-02:** Per-type defaults: papers/articles get atomic claims; book chapters get atomic for factual + paragraph-level for interpretive; transcripts/journals get paragraph/utterance clusters; image-heavy tied to specific images/captions.
- **D-03:** Bias toward atomic for durable factual/conceptual claims across all types. Heuristic: "the smallest unit that preserves meaningful provenance without making the page unreadable."
- **D-04:** Split when a paragraph contains multiple independently important assertions. Keep grouped when a passage is only useful as one bundled observation.
- **D-05:** Encode these rules directly in AGENTS.md section 10 Pass 2 (Extract).
- **D-06:** Append-then-synthesize as the default update policy for living wiki pages.
- **D-07:** Operational rule: (1) Add new claims preserving existing, (2) Mark old claims as superseded/stale -- never silently delete, (3) Re-synthesize TL;DR and Key Facts, (4) Record framing changes in decision/reflection entries.
- **D-08:** Full section rewrite reserved for exceptional cases only.
- **D-09:** Strict append-only reserved for logs and source summary pages only.
- **D-10:** Encode in AGENTS.md section 10 Pass 3 (Merge) and reference from section 9.
- **D-11:** Bash scaffold script (not Node.js, not a full LLM orchestrator). Agent-agnostic, zero API dependencies.
- **D-12:** Script responsibilities: accept source file path + optional slug, create dated directory structure, copy/move file in, compute content_hash, print ready-to-ingest instructions.
- **D-13:** The LLM agent runs the actual pipeline. The CLI handles file bookkeeping only.
- **D-14:** Phase 3 includes two real source ingestions to validate the pipeline end-to-end.
- **D-15:** First ingest: an article in the Kahneman/decision-making domain. Tests atomic claim extraction AND incremental updates to existing Phase 2 example pages.
- **D-16:** Second ingest: a journal entry. Tests coarser paragraph-level extraction and a different source type path.
- **D-17:** Both ingests must produce: source summary page with provenance, updated/new wiki pages, updated index, updated log, valid git commit.

### Claude's Discretion
- Exact content of validation test sources (as long as they exercise the pipeline as specified)
- CLI script internal implementation details (argument parsing, hash algorithm, output formatting)
- Exact wording of AGENTS.md updates (as long as decisions D-01 through D-10 are faithfully encoded)
- Whether to update AGENTS.md sections incrementally per plan or batch at the end

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INGST-01 | Source classification (article, paper, journal entry, transcript, image-heavy, data file) | AGENTS.md section 10 Pass 0 already defines types; D-01/D-02 add extraction depth rules per type |
| INGST-02 | Type-appropriate extraction logic per source classification | D-01 through D-05 define granularity rules to encode in Pass 2 |
| INGST-03 | Per-source summary page created with claim-level provenance | Source-summary template exists; existing example shows exact format |
| INGST-04 | Existing wiki pages updated when new source adds relevant information | D-06 through D-10 define append-then-synthesize policy for Pass 3 |
| INGST-05 | Cross-references (wikilinks) generated between related pages | AGENTS.md section 8 defines first-mention linking; Pass 3 generates wikilinks |
| INGST-06 | Index and log updated after each ingest | Workflow steps 8-9 in section 11.1; existing index/log formats established |
| CMPL-01 | Multi-pass compilation pipeline: diff -> extract -> merge -> lint | AGENTS.md section 10 defines all passes; validation ingests prove it works |
| CMPL-02 | Diff pass -- identify new information relative to existing wiki state | Pass 1 defined; reads index.md then TL;DR/Key Facts of related pages |
| CMPL-03 | Extract pass -- pull claims, entities, relationships with provenance | Pass 2 defined; D-01 through D-05 add granularity rules |
| CMPL-04 | Merge pass -- integrate extracted knowledge into existing wiki pages | Pass 3 defined; D-06 through D-10 add incremental update policy |
| CMPL-05 | Lint pass -- verify consistency after merge | Pass 4 defined; checks provenance resolution, wikilinks, frontmatter |
| CMPL-06 | Optional follow-on passes for summaries, images, restructuring | Already documented in AGENTS.md; not required every ingest |
| CMPL-07 | Pipeline documented step-by-step in schema as canonical ingest workflow | Section 11.1 exists; needs D-01 through D-10 encoding updates |
| PROV-01 | Provenance attaches to individual claims, not just pages | Inline syntax `[prov:source_id#locator]` defined in section 6 |
| PROV-02 | Each claim links to specific source passage(s) | Locator types defined: page, section, paragraph, timestamp, image |
| PROV-03 | Provenance metadata includes source ID, passage reference, extraction date | Extended form includes `checked_at` field |
| PROV-04 | Source hash stored so stale claims can be detected when sources change | `content_hash` field on source summary pages; CLI script computes it |
| PROV-05 | Provenance conventions documented in schema with inline syntax | Section 6 already documents this; validation ingests demonstrate it |
| CLI-02 | Ingest helper that scaffolds the ingest workflow | D-11 through D-13 define bash script scope |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

No CLAUDE.md exists in this project. No additional project-specific constraints beyond AGENTS.md conventions.

## Standard Stack

This phase involves no software library dependencies. The entire system is markdown-based with LLM agents as the runtime.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | 5.2 | CLI ingest helper script | Decision D-11: agent-agnostic, zero API dependencies |
| sha256sum | GNU coreutils 9.4 | Content hash computation | Available on system; standard UNIX tool |
| git | system | Version control for all wiki mutations | Commit convention: `ingest(<source-slug>): <one-line summary>` |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| date (GNU) | coreutils | ISO 8601 date generation in CLI script | Directory naming, frontmatter dates |
| cp/mv | coreutils | File placement in sources/ directory | CLI script file operations |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| sha256sum | shasum -a 256 | shasum is macOS default; sha256sum is Linux default. Script should try both |
| bash | python3/node | Both available but D-11 explicitly locks bash. Zero-dependency requirement |

## Architecture Patterns

### Pipeline Pass Structure (from AGENTS.md section 10)
```
Source -> [Pass 0: Classify] -> [Pass 1: Diff] -> [Pass 2: Extract] -> [Pass 3: Merge] -> [Pass 4: Lint] -> Wiki
```

Each pass has defined inputs and outputs. The LLM agent executes passes sequentially within a single session. There is no inter-process communication or state file between passes -- the LLM maintains context across passes within one invocation.

### Source Directory Convention
```
sources/
  YYYY/
    YYYY-MM/
      YYYY-MM-DD-slug/
        source.md          # The actual source document
        [assets/]          # Optional images, PDFs, etc.
```
Or for single-file sources: `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug.md`

### Wiki Page Mutation Pattern (UPDATE operation)
1. Read existing page
2. Add new claims to appropriate detail section with provenance markers
3. Preserve all existing provenance markers (never remove)
4. Add new source ID to `sources` list in frontmatter
5. Update `updated_at` to today's date
6. Re-synthesize TL;DR and Key Facts to reflect new state (D-07 step 3)
7. Log the UPDATE operation

### CLI Script Architecture
```
bin/
  ingest.sh              # The CLI helper script
```
Script flow:
1. Accept: `./bin/ingest.sh <source-file> [--slug <slug>]`
2. Compute today's date -> derive directory path
3. Create `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/`
4. Copy source file into directory as `source.md` (or appropriate name)
5. Compute `sha256sum` of the source file -> print `content_hash`
6. Print instructions: what to tell the LLM agent to do next

### Anti-Patterns to Avoid
- **Silent deletion of existing claims:** D-07 explicitly forbids this. Mark as superseded/stale instead.
- **Full page rewrites on every ingest:** D-08 reserves this for exceptional cases only.
- **CLI script calling LLM APIs:** D-11/D-13 lock the script to file bookkeeping only.
- **Creating duplicate pages instead of updating:** The Diff pass (Pass 1) exists specifically to detect existing coverage and route to UPDATE rather than CREATE.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Content hashing | Custom hash function | `sha256sum` (GNU coreutils) | Standard, portable, battle-tested |
| Date formatting | Manual string construction | `date -u +%Y-%m-%d` | Avoids timezone bugs |
| Directory creation | Complex path logic | `mkdir -p` with date-derived path | UNIX standard, handles existing dirs |
| Duplicate detection | Page title matching | `content_hash` comparison against existing source summary frontmatter | Hash is definitive; title matching is fragile |

## Common Pitfalls

### Pitfall 1: Provenance Markers That Don't Resolve
**What goes wrong:** Claims created with `[prov:source_id#locator]` where source_id doesn't match any page in `wiki/sources/`.
**Why it happens:** Typos in source IDs, or source summary page not yet created when wiki pages are being updated.
**How to avoid:** Pass 4 (Lint) must validate that every `[prov:...]` reference resolves. Create source summary page (Pass 2) BEFORE updating wiki pages (Pass 3).
**Warning signs:** Grep for `[prov:` across wiki/ and cross-reference against `wiki/sources/` filenames.

### Pitfall 2: Incremental Update Destroys Existing Content
**What goes wrong:** An UPDATE operation overwrites existing claims instead of appending alongside them.
**Why it happens:** LLM rewrites entire sections rather than inserting new material into them.
**How to avoid:** Explicit instruction in AGENTS.md Pass 3: "Preserve all existing content. Insert new claims at the end of the relevant section. Never remove or rewrite existing claims unless explicitly superseding them."
**Warning signs:** Git diff shows deletions of existing provenance markers.

### Pitfall 3: TL;DR/Key Facts Drift from Detail Section
**What goes wrong:** After multiple ingests, the summary layer no longer accurately reflects the detail layer.
**Why it happens:** D-07 step 3 (re-synthesize summaries) is skipped or done poorly.
**How to avoid:** Make re-synthesis an explicit step in the pipeline, not an afterthought. The validation ingests must verify that summaries reflect all claims in detail sections.
**Warning signs:** Key claims in Detail section absent from TL;DR/Key Facts.

### Pitfall 4: Source Type "book" Not in Classify Enum
**What goes wrong:** The existing example source uses `source_type: book` but AGENTS.md Pass 0 lists types as: article, paper, transcript, journal entry, data file, image-heavy. "book" is not in the list.
**Why it happens:** Phase 2 created the example before the type enum was finalized.
**How to avoid:** Either add "book" to the official types in AGENTS.md, or treat book chapters as "article" type. This must be resolved in the AGENTS.md update.
**Warning signs:** Source classification fails to match any defined type.

### Pitfall 5: CLI Script Portability (sha256sum vs shasum)
**What goes wrong:** Script fails on macOS because `sha256sum` doesn't exist by default.
**Why it happens:** macOS ships `shasum` not `sha256sum`.
**How to avoid:** Script should try `sha256sum` first, fall back to `shasum -a 256`.
**Warning signs:** Script errors on hash computation step.

### Pitfall 6: Wikilinks to Non-Existent Pages Created During Ingest
**What goes wrong:** New wiki pages or updated pages contain `[[Page Title]]` links to pages that don't exist yet.
**Why it happens:** Extract pass identifies entities/concepts not yet in the wiki; Merge pass references them before creating them.
**How to avoid:** AGENTS.md section 8 already handles this -- intentional red links are acceptable. The Lint pass should distinguish intentional red links from errors.
**Warning signs:** Pass 4 reports many broken wikilinks.

## Code Examples

### Provenance Syntax (from AGENTS.md section 6)
```markdown
- Claim text here. [prov:src-2026-04-09-thinking-fast-and-slow-part1#sec:heuristics|direct|2026-04-09] [epistemic:: sourced]
```

### Source Summary Frontmatter (from existing example)
```yaml
---
id: src-2026-04-09-thinking-fast-and-slow-part1
title: "Kahneman - Thinking, Fast and Slow Part 1"
type: source
status: active
summary: "Part 1 of Kahneman's synthesis of decades of research on judgment, heuristics, and cognitive biases"
created_at: 2026-04-09
updated_at: 2026-04-09
sources: []
epistemic_status: sourced
tags:
  - psychology
  - behavioral-economics
  - heuristics
domains:
  - psychology
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Thinking Fast and Slow Part 1
path: sources/2026/2026-04/2026-04-09-thinking-fast-and-slow-part1/source.md
url: ""
content_hash: "sha256:a1b2c3d4e5f6..."
ingested_at: 2026-04-09
source_type: book
---
```

### UPDATE Operation Pattern (from AGENTS.md section 9)
```markdown
1. Add new claims with provenance markers to the appropriate section
2. Preserve all existing provenance markers
3. Add new source IDs to the `sources` list in frontmatter
4. Update `updated_at` in frontmatter
5. If new claims change the evidence balance, update `epistemic_status`
6. Log: "UPDATE <page_id>: <one-line rationale>"
```

### CLI Script Hash Computation Pattern
```bash
#!/usr/bin/env bash
compute_hash() {
    local file="$1"
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        echo "ERROR: No SHA-256 tool found" >&2
        exit 1
    fi
}
```

### Index Entry Format (from AGENTS.md section 12)
```markdown
- [[Page Title]] -- <one-line summary> (<epistemic_status>, <updated_at>)
```

### Log Entry Format (from AGENTS.md section 12)
```markdown
## [YYYY-MM-DD] ingest | <source title>

<what was done, which pages were affected, brief rationale>
```

## Existing Assets Inventory

The following assets exist and will be used or modified during this phase:

| Asset | Path | Role in Phase 3 |
|-------|------|------------------|
| AGENTS.md sections 9, 10, 11.1 | `AGENTS.md` | Updated with D-01 through D-10 encoding |
| Source summary template | `schema/templates/source-summary.md` | Used by Extract pass (Pass 2) |
| Entity template | `schema/templates/entity.md` | Used by Merge pass (Pass 3) if new entity pages needed |
| Concept template | `schema/templates/concept.md` | Used by Merge pass (Pass 3) if new concept pages needed |
| Overview template | `schema/templates/overview.md` | Used by Merge pass (Pass 3) if new overview pages needed |
| Comparison template | `schema/templates/comparison.md` | Used by Merge pass (Pass 3) if new comparison pages needed |
| Daniel Kahneman page | `wiki/entities/daniel-kahneman.md` | Target for incremental UPDATE during validation ingest 1 |
| Cognitive Biases page | `wiki/concepts/cognitive-biases.md` | Target for incremental UPDATE during validation ingest 1 |
| System 1 vs System 2 | `wiki/comparisons/system-1-vs-system-2.md` | Potential UPDATE target during validation ingest 1 |
| Decision Making | `wiki/overviews/decision-making.md` | Potential UPDATE target during validation ingest 1 |
| Existing source summary | `wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` | Reference format; NOT modified |
| Index | `wiki/index.md` | Updated after each ingest |
| Log | `wiki/log.md` | Appended to after each ingest |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual validation + grep/shell verification |
| Config file | none -- no automated test framework for markdown wiki |
| Quick run command | `grep -r '\[prov:' wiki/ \| head -20` (spot check provenance) |
| Full suite command | Shell script validating frontmatter, provenance resolution, index consistency |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INGST-01 | Source classification in source summary frontmatter | manual + grep | `grep 'source_type:' wiki/sources/*.md` | N/A |
| INGST-02 | Type-appropriate extraction (atomic vs paragraph) | manual review | Visual inspection of claim granularity | N/A |
| INGST-03 | Source summary page with provenance | grep | `ls wiki/sources/src-2026-04-10-*.md` | Wave 0 |
| INGST-04 | Existing pages updated (not duplicated) | git diff | `git diff wiki/entities/ wiki/concepts/` | N/A |
| INGST-05 | Wikilinks generated | grep | `grep -c '\[\[' wiki/entities/daniel-kahneman.md` | N/A |
| INGST-06 | Index and log updated | grep | `grep '2026-04-10' wiki/index.md wiki/log.md` | N/A |
| CMPL-01 | Multi-pass pipeline executed | manual | Check log entry describes all passes | N/A |
| CMPL-02 | Diff pass identifies delta | manual | Verify new claims are actually new, not duplicates of existing | N/A |
| CMPL-03 | Extract pass produces provenance | grep | `grep -c '\[prov:' wiki/sources/src-2026-04-10-*.md` | Wave 0 |
| CMPL-04 | Merge pass integrates into existing | git diff | `git diff --stat` shows modifications, not just additions | N/A |
| CMPL-05 | Lint pass catches issues | manual | Verify no broken provenance refs or invalid frontmatter | N/A |
| CMPL-07 | Pipeline documented in schema | grep | `grep -c 'granularity\|append-then-synthesize' AGENTS.md` | Wave 0 |
| PROV-01 | Claim-level provenance | grep | `grep '\[prov:' wiki/entities/*.md wiki/concepts/*.md` | N/A |
| PROV-02 | Links to specific passages | grep | `grep '\[prov:.*#' wiki/` (verify locators present) | N/A |
| PROV-03 | Source ID + passage ref + date | grep | `grep '\[prov:.*\|.*\|' wiki/` (extended form with checked_at) | N/A |
| PROV-04 | Source hash stored | grep | `grep 'content_hash:' wiki/sources/src-2026-04-10-*.md` | Wave 0 |
| PROV-05 | Conventions documented | read | Verify AGENTS.md section 6 is complete | Already exists |
| CLI-02 | Ingest helper script | smoke test | `bash bin/ingest.sh --help` | Wave 0 |

### Sampling Rate
- **Per task commit:** `grep -r '\[prov:' wiki/ | wc -l` (provenance count should increase)
- **Per wave merge:** Full frontmatter validation across all modified pages
- **Phase gate:** Both validation ingests complete, all req IDs verifiable

### Wave 0 Gaps
- [ ] `bin/ingest.sh` -- CLI helper script (created in this phase)
- [ ] Validation source documents -- two test sources to ingest (created in this phase)
- [ ] No automated test framework needed -- this is a documentation/process phase, verification is through grep and manual inspection

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | CLI script (D-11) | Yes | 5.2 | -- |
| sha256sum | Content hash (D-12) | Yes | coreutils 9.4 | shasum -a 256 |
| git | Commit convention | Yes | system | -- |
| mkdir/cp/mv | CLI file ops | Yes | coreutils | -- |
| date | ISO date generation | Yes | coreutils | -- |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Open Questions

1. **Source type "book" vs existing enum**
   - What we know: AGENTS.md Pass 0 lists: article, paper, transcript, journal entry, data file, image-heavy. Existing example uses `source_type: book`.
   - What's unclear: Whether "book" should be added as an official type or treated as a sub-type of article.
   - Recommendation: Add "book" (or "book-chapter") to the official source_type enum in AGENTS.md during the encoding update. It has distinct extraction characteristics (D-02).

2. **CLI script location**
   - What we know: D-11 says bash script; CONTEXT.md mentions "location TBD by planner."
   - What's unclear: `bin/`, `scripts/`, or root?
   - Recommendation: `bin/ingest.sh` -- standard UNIX convention for executable scripts.

3. **Validation source content**
   - What we know: D-15 says article in Kahneman/decision-making domain; D-16 says journal entry. Exact content is Claude's discretion.
   - What's unclear: Whether to use real published articles or synthetic test documents.
   - Recommendation: Create synthetic but realistic test documents. A real article would have copyright concerns. Synthetic documents can be precisely crafted to exercise the pipeline (e.g., include claims that overlap with existing pages AND claims that require new pages).

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` sections 5, 6, 8, 9, 10, 11.1, 12 -- full pipeline specification, provenance syntax, operations vocabulary
- `.planning/phases/03-ingestion-provenance-pipeline/03-CONTEXT.md` -- all locked decisions D-01 through D-17
- `.planning/REQUIREMENTS.md` -- requirement definitions for INGST, CMPL, PROV, CLI
- Existing wiki pages (5 pages) -- format reference, incremental update targets
- Existing templates (5 templates) -- page creation skeletons

### Secondary (MEDIUM confidence)
- None needed -- this phase is fully specified by existing project documents.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no external dependencies; all tools verified on system
- Architecture: HIGH -- pipeline fully specified in AGENTS.md; decisions lock implementation choices
- Pitfalls: HIGH -- derived from close reading of existing assets and AGENTS.md requirements

**Research date:** 2026-04-10
**Valid until:** 2026-05-10 (stable -- this is a self-contained project with no external dependency drift)

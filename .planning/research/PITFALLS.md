# Domain Pitfalls

**Domain:** LLM-maintained personal wiki / knowledge compilation system
**Researched:** 2026-04-06
**Sources:** Training data (mid-2025 cutoff). Web search unavailable; confidence levels adjusted accordingly.

## Critical Pitfalls

Mistakes that cause rewrites, data corruption, or system abandonment.

---

### Pitfall 1: Silent Hallucination During Compilation

**What goes wrong:** The LLM fabricates claims, invents cross-references to pages that do not exist, or subtly rewrites source material while "summarizing" it. Because the output looks plausible and is written in the wiki's own voice, hallucinated content becomes indistinguishable from sourced content once it enters the wiki. Over time the wiki accumulates confident-sounding claims with no actual backing.

**Why it happens:** LLMs are completion engines, not retrieval engines. When a source is ambiguous or the context window does not include the full source, the model fills gaps with plausible-sounding content. Summarization prompts ("extract key claims") actively encourage the model to generate text that goes beyond the literal input.

**Consequences:** The wiki's core value proposition -- that it is a compiled, trustworthy knowledge store -- is destroyed. The user cannot trust any claim without re-checking the source, which eliminates the labor-saving benefit. Worse, hallucinated claims that link to real sources create false provenance, which is harder to detect than no provenance at all.

**Warning signs:**
- Claims in wiki pages that cannot be found in the cited source when spot-checked
- Cross-references (wikilinks) pointing to pages that do not exist
- Suspiciously specific statistics, dates, or proper nouns that were not in the source
- Two wiki pages citing the same source but presenting contradictory claims

**Prevention:**
1. Every claim in a wiki page MUST have an explicit source pointer (file path + section/paragraph). No exceptions, no "generally known" claims.
2. The ingest workflow should operate in extract-then-compile mode: first extract verbatim quotes/claims from the source into a structured intermediate format, then compile those extracts into wiki prose. This creates an auditable chain.
3. Implement a lint pass that checks every `[[wikilink]]` resolves to an actual file and every source citation points to an existing raw source.
4. Epistemic status markers (sourced/inferred/tentative) are not optional nice-to-haves -- they are the primary defense. "Inferred" means "the LLM generated this beyond what the source literally says." The user can then decide trust level.
5. Periodic spot-check workflow: randomly select N claims, verify against cited source.

**Detection:** Broken-link lint catches the most obvious cases. For subtle hallucination, the spot-check workflow is essential. Log every compilation operation so you can trace when a claim was introduced and by which agent invocation.

**Phase relevance:** Must be addressed in Phase 1 (core schema). Provenance tracking and epistemic markers are not Phase 2 polish -- they are foundational to the system's integrity.

**Confidence:** HIGH -- this is the most well-documented failure mode of LLM-generated content systems.

---

### Pitfall 2: Context Window Collapse as Wiki Grows

**What goes wrong:** The wiki starts at 10 pages and the LLM can hold the entire index + relevant pages in context. At 200 pages, the LLM cannot read the full wiki. Operations that require cross-wiki awareness (contradiction detection, cross-referencing, merge decisions) start failing silently. The agent either truncates its view (missing relevant pages) or the user hits token limits and operations fail outright.

**Why it happens:** Even with 100K-200K token context windows, a wiki of 200+ pages with frontmatter, content, and cross-references easily exceeds capacity. The schema might instruct the agent to "check for contradictions across the wiki" but the agent physically cannot load enough pages to do so.

**Consequences:** Cross-references become incomplete. Contradictions go undetected. The agent creates duplicate pages for concepts that already exist under different names. The wiki fragments into disconnected clusters that the agent maintains independently.

**Warning signs:**
- Agent creates a new page for a concept that already has a page (under a slightly different name)
- Contradiction detection stops finding anything (not because there are none, but because the agent cannot see enough pages)
- Agent asks "I don't see a page for X" when one exists
- Operations that used to work start timing out or hitting token limits

**Prevention:**
1. Design for index-first navigation from day one. The index is a lightweight catalog (title, type, one-line summary, tags) that fits in a single context window even at 500+ pages. The agent reads the index first, identifies relevant pages, then loads only those pages.
2. Never design workflows that require loading the entire wiki. Every workflow should specify exactly which subset of pages to load.
3. The index itself must be maintained incrementally -- updated when pages change, not regenerated from scratch.
4. Set explicit page count thresholds in the schema: "If wiki exceeds N pages, switch from full-scan lint to index-based sampling."
5. Keep individual pages focused and bounded in length. A 10,000-word page is a sign the page should be split.

**Detection:** Track the ratio of (tokens loaded per operation) / (total wiki tokens). When this ratio drops below a threshold for cross-cutting operations, the wiki has outgrown the workflow design.

**Phase relevance:** The index system must exist in Phase 1. Retrofitting an index onto a wiki that was built without one is extremely painful because every existing page needs cataloging.

**Confidence:** HIGH -- context window limitations are a hard constraint, well-understood.

---

### Pitfall 3: Over-Engineering the Framework Before Validating the Pattern

**What goes wrong:** The project spends months designing a perfect schema with 15 page types, 8 epistemic markers, 6 structured operations, 3 compilation pipeline stages, and a formal ontology -- before a single real source has been ingested. When actual use begins, the schema does not match how knowledge actually flows. The elaborate type system becomes a burden rather than an aid. The user (or the LLM) starts working around the schema rather than with it.

**Why it happens:** This is a "framework project" -- the product IS the framework. It is extremely tempting to design the complete framework upfront because that feels like progress. The PROJECT.md explicitly wants "full framework from v1" including provenance, epistemic status, structured operations, and compilation pipeline.

**Consequences:** Either (a) the user abandons the system because it is too complex to use, or (b) the schema gets progressively ignored as agents take shortcuts, creating a gap between the documented schema and actual wiki state.

**Warning signs:**
- Schema document exceeds 3000 words before the wiki has 20 pages
- More than 4 page types defined before any are battle-tested
- Structured operations (MERGE, SUPERSEDE, ARCHIVE) defined but never actually invoked
- The user dreads ingesting a new source because of the "process"

**Prevention:**
1. Start with exactly 3 page types: source summary, entity page, concept page. Add comparison pages and others only when a real need arises during use.
2. Start with exactly 3 epistemic markers: sourced, inferred, uncertain. Expand the taxonomy only after discovering that these three are insufficient for a real case.
3. Define all structured operations in the schema but accept that the first 20 ingestions will mostly use CREATE and UPDATE. Do not build elaborate MERGE/SUPERSEDE tooling until you have actually encountered pages that need merging.
4. Set a validation gate: after 30 pages, review the schema against actual usage. What was used? What was never used? What was missing? Prune and adjust.
5. The compilation pipeline can be a simple checklist (diff, extract, merge, lint) without automation. Automation comes in v2 when the pattern is validated.

**Detection:** Track which schema features are actually invoked in the log. If a feature has zero log entries after 30 pages, it is either unnecessary or too burdensome to use.

**Phase relevance:** This pitfall affects Phase 1 design directly. The tension is real: the project wants a full framework, but the framework must be designed to grow rather than be complete upfront. The resolution is: define the extension points and conventions in Phase 1, but keep the initial instantiation minimal.

**Confidence:** HIGH -- this is the classic second-system effect / premature abstraction, extremely well-documented in software and knowledge management.

---

### Pitfall 4: Schema Drift Across Agents and Sessions

**What goes wrong:** The schema (CLAUDE.md / AGENTS.md) says one thing, but different LLM agents interpret it differently. Claude Code uses `status: sourced` in frontmatter; Codex uses `epistemic_status: verified`. One session creates `[[See Also]]` sections; another creates `## Related` sections. Over dozens of sessions, the wiki accumulates inconsistent formatting, frontmatter schemas, link conventions, and page structures. The wiki becomes a patchwork rather than a coherent system.

**Why it happens:** LLMs interpret natural-language instructions with variance. Even the same model produces slightly different output across sessions. Different models (Claude vs Codex vs GPT) have different default behaviors and formatting preferences. The schema is a markdown document, not executable code -- there is no compiler to enforce it.

**Consequences:** Dataview queries break because frontmatter keys are inconsistent. Lint passes produce false positives/negatives. The graph view shows fragmented clusters because link conventions vary. The user loses confidence in the wiki's structure.

**Warning signs:**
- Dataview queries returning partial results
- Same concept represented with different frontmatter key names across pages
- Inconsistent heading hierarchies (## vs ### for the same structural role)
- Agent asks "should I use X or Y format?" -- indicating the schema is ambiguous

**Prevention:**
1. The schema must include EXACT examples, not just descriptions. Do not write "include epistemic status in frontmatter." Write the exact YAML block: `epistemic_status: sourced | inferred | uncertain`.
2. Provide a complete template for each page type with every field filled in. The agent copies the template and fills in values rather than inventing structure.
3. Frontmatter schema must be specified as a strict list of allowed keys with allowed values. Anything not in the list is a lint error.
4. Include a "canonical examples" section in the schema -- 2-3 complete wiki pages that demonstrate every convention. Agents can reference these when uncertain.
5. The lint workflow must check frontmatter schema compliance, heading structure, and link format on every page. Run lint after every ingest.
6. When testing with a new agent, ingest the same source with both agents and diff the output. Fix schema ambiguities that caused divergence.

**Detection:** A simple frontmatter audit script (list all unique frontmatter keys across all pages) reveals drift instantly. Run monthly.

**Phase relevance:** Phase 1 must nail the schema with examples and templates. The lint workflow (also Phase 1) is the enforcement mechanism.

**Confidence:** HIGH -- multi-agent consistency is a known hard problem in LLM systems.

---

### Pitfall 5: Provenance Links Rot and Become Unverifiable

**What goes wrong:** Wiki claims cite sources by file path (e.g., `sources/articles/deep-work.md`). Over time, source files get renamed, reorganized, or the wiki references a specific section that was restructured. Provenance links that were once valid now point to nothing or to the wrong content. The wiki appears well-sourced but the citations are unverifiable.

**Why it happens:** Source files are treated as living documents even though the schema treats them as immutable. Or the source organization scheme changes. Or citations point to a page-level source when they should point to a specific passage.

**Consequences:** The provenance system -- the core differentiator of this project -- becomes a Potemkin village. Claims look sourced but the citations cannot be verified. This is arguably worse than having no provenance at all, because it creates false confidence.

**Warning signs:**
- Provenance lint pass starts finding broken source references
- Source directory reorganization that does not update wiki citations
- Citations point to a file but the specific claim cannot be located within that file

**Prevention:**
1. Raw sources MUST be immutable once ingested. Never edit a source file after it enters the system. If a new version arrives, ingest it as a new source and use SUPERSEDE to update wiki claims.
2. Use content-addressable references where possible: cite by source file path + heading or paragraph hash, not just file path.
3. The ingest workflow must record the exact source state (could be a git commit hash) at ingestion time.
4. Source reorganization must be a formal operation that updates all wiki citations. Never move source files casually.
5. The lint workflow must validate that every source citation resolves to an existing file.

**Detection:** Broken-citation lint is the primary defense. Run on every commit.

**Phase relevance:** Immutability of sources and the citation format must be established in Phase 1. Retrofitting citation granularity is extremely labor-intensive.

**Confidence:** HIGH -- link rot is universal in knowledge management systems.

---

## Moderate Pitfalls

---

### Pitfall 6: Stale Claims Without Expiry Signals

**What goes wrong:** The wiki contains a claim like "Current best practice for X is Y" sourced from an article written in 2023. By 2026, best practice has changed, but the wiki shows this as a confident, sourced claim. There is no mechanism to flag time-sensitive claims or trigger re-evaluation.

**Why it happens:** Most knowledge management systems treat claims as timeless once recorded. The system lacks a model of claim freshness. The LLM does not spontaneously flag that a claim might be outdated.

**Prevention:**
1. Frontmatter must include `last_verified: YYYY-MM-DD` and optionally `freshness: evergreen | time-sensitive`.
2. Time-sensitive claims (statistics, best practices, tool recommendations) should include a `valid_until` or `review_by` date.
3. The lint workflow should flag pages where `last_verified` exceeds a threshold (e.g., 6 months for time-sensitive, 18 months for evergreen).
4. When ingesting a source, record the source's publication date. Claims from older sources are automatically lower freshness.

**Detection:** A lint pass that checks `last_verified` dates. A dashboard (Dataview query) showing pages sorted by staleness.

**Phase relevance:** Phase 1 schema should include freshness metadata. The lint rule can be Phase 2.

**Confidence:** MEDIUM -- the approach is sound but the specific freshness model needs validation through use.

---

### Pitfall 7: Obsidian Compatibility Breakage

**What goes wrong:** The LLM generates markdown that is valid markdown but breaks Obsidian-specific features. Common issues: YAML frontmatter with unquoted special characters breaks Dataview. Wikilinks with pipe aliases (`[[page|alias]]`) generated incorrectly. Nested tags with spaces. Mermaid diagrams or callout syntax that works in standard markdown but not in Obsidian (or vice versa). Frontmatter arrays formatted as strings instead of YAML lists.

**Why it happens:** LLMs know "markdown" but do not have precise knowledge of Obsidian's specific markdown parser quirks. Obsidian's markdown flavor has undocumented behaviors. Different Obsidian plugins have different requirements.

**Prevention:**
1. The schema must include an "Obsidian Compatibility" section with explicit rules: quote all frontmatter string values, use `[[wikilinks]]` not `[markdown](links)` for internal links, use Obsidian callout syntax (`> [!note]`), etc.
2. Include specific anti-patterns: "Do NOT use `---` horizontal rules inside pages with frontmatter (Obsidian may misparse). Do NOT use colons in frontmatter values without quoting."
3. Test every page type template by actually opening it in Obsidian and verifying: frontmatter parses in Dataview, wikilinks resolve, graph view shows the page correctly, tags appear in tag pane.
4. Validate frontmatter YAML programmatically as part of lint.

**Warning signs:**
- Dataview queries returning errors or empty results
- Pages showing raw YAML instead of rendered content
- Broken links in graph view
- Tags not appearing in the tag pane

**Detection:** Open the wiki in Obsidian after every batch of changes. Run Dataview queries as integration tests.

**Phase relevance:** Phase 1. Templates must be Obsidian-tested before being used at scale.

**Confidence:** MEDIUM -- the specific issues depend on Obsidian version and plugin configuration, which varies.

---

### Pitfall 8: Structured Operations Become a Straitjacket

**What goes wrong:** The schema defines operations like UPDATE, MERGE, SUPERSEDE, ARCHIVE with specific semantics. But real knowledge work does not always fit neatly into these categories. The agent is asked to "incorporate this new article about sleep" and has to decide: is this an UPDATE to the existing sleep page? A MERGE of the new source's claims with existing claims? A new page that SUPERSEDES old claims? The rigid operation taxonomy creates friction, and the agent either picks the wrong operation or punts to the user for a decision on every ingest.

**Why it happens:** Structured operations are designed for predictability and auditability. But knowledge compilation is inherently messy -- a single new source might trigger updates to 5 pages, create 1 new page, supersede 2 claims, and leave 3 claims unchanged. Forcing this into a linear sequence of named operations adds overhead without proportional value.

**Prevention:**
1. Operations should be descriptive (logged after the fact), not prescriptive (chosen before the fact). The agent does the work, then logs what it did using operation vocabulary.
2. Allow compound operations: "INGEST source X: CREATED page A, UPDATED pages B and C, SUPERSEDED claim D.3 on page E." The log entry describes the full impact.
3. The schema should give the agent permission to make judgment calls about operation type. Reserve human-in-the-loop for truly ambiguous cases (e.g., two pages that might need merging).
4. Keep the operation vocabulary small: CREATE, UPDATE, SUPERSEDE, ARCHIVE. Do not add MERGE, SPLIT, REFACTOR, ANNOTATE, etc. until real usage demands them.

**Detection:** If the agent frequently asks the user to choose an operation type, the taxonomy is too rigid or too ambiguous.

**Phase relevance:** Phase 1 schema design. Get the operation model right -- descriptive not prescriptive.

**Confidence:** MEDIUM -- this tension is real but the optimal balance depends on actual usage patterns.

---

### Pitfall 9: The Index Becomes a Bottleneck

**What goes wrong:** The index is a single file that every operation must read and many operations must update. As the wiki grows, the index file becomes large, and concurrent or rapid-fire operations create conflicts. The index also becomes the single point of failure -- if it gets corrupted or out of sync with actual wiki pages, navigation breaks.

**Why it happens:** A single-file index is the simplest design and works well at small scale. But it violates the principle that any file that every operation touches will become a coordination bottleneck.

**Prevention:**
1. Design the index as a collection of smaller index files (by category, by type, or by first letter) rather than a single monolith. A master index can be a lightweight aggregation.
2. The index must be regenerable from page frontmatter. It is a cache, not a source of truth. If the index is lost or corrupted, a full rebuild from scanning all pages should restore it.
3. Include an index-rebuild operation in the CLI helpers.
4. Each page's frontmatter contains enough metadata (title, type, tags, summary) that the index is just a convenience, not a necessity.

**Detection:** Index file exceeds 500 lines. Index and page frontmatter disagree about a page's metadata. Operations start failing because of index corruption.

**Phase relevance:** Phase 1 should design the index as regenerable from page metadata. The split-index optimization can wait until the wiki grows.

**Confidence:** MEDIUM -- the bottleneck risk is real but may not manifest until 100+ pages.

---

### Pitfall 10: Compilation Creates Orphan State

**What goes wrong:** The compilation pipeline (diff, extract, merge, lint) fails partway through. The source has been partially processed: some wiki pages were updated, others were not, the index is half-updated, and the log entry was never written. The wiki is now in an inconsistent state that is hard to diagnose and harder to repair.

**Why it happens:** LLM operations are not transactional. There is no rollback mechanism in a file-based system. An agent session might time out, hit a rate limit, or produce an error mid-pipeline.

**Prevention:**
1. Use git as the transaction mechanism. Before any ingest operation, ensure the working tree is clean. If the operation fails, `git checkout .` restores the previous state.
2. The log entry should be written FIRST (as "in progress") and updated to "complete" at the end. This makes partial operations visible.
3. Design each pipeline stage to be idempotent: running it again on the same input produces the same output without double-creating pages or double-updating claims.
4. Include a "resume" capability: the agent should be able to detect a partially completed ingest and pick up where it left off rather than starting over.

**Detection:** Log entries marked "in progress" with no corresponding "complete." Pages that reference a source but the source is not fully reflected in all relevant pages.

**Phase relevance:** Phase 1 should establish the git-as-transaction pattern. Idempotency can be refined in Phase 2.

**Confidence:** MEDIUM -- git-based rollback is a well-known pattern, but idempotent LLM operations require careful prompt engineering.

---

## Minor Pitfalls

---

### Pitfall 11: Graph View Becomes Noise

**What goes wrong:** Obsidian's graph view is a key navigation tool, but if every page links to every related page, the graph becomes a hairball. The visual benefit of graph view -- seeing clusters and connections -- is lost when everything is connected to everything.

**Prevention:**
1. Distinguish between primary links (core relationships, in the body) and secondary links (see-also, in a footer section). Consider whether graph view should show only primary links.
2. Use Obsidian's graph view filters and groups (by folder, by tag) to manage visual complexity.
3. Keep cross-references meaningful: link to directly related pages, not tangentially related ones.

**Phase relevance:** Phase 1 schema should establish link conventions. Graph view tuning is ongoing.

**Confidence:** LOW -- optimal link density depends on personal preference and wiki size.

---

### Pitfall 12: Agent Log Grows Unbounded

**What goes wrong:** The append-only activity log grows to thousands of entries. It becomes too large to include in context, and historical entries provide diminishing value. But pruning or archiving log entries risks losing the audit trail.

**Prevention:**
1. Design the log with a rotation scheme from day one: active log (current month) and archive logs (by month or quarter).
2. The active log should be bounded to fit in a context window (aim for under 500 lines / 10K tokens).
3. Archive logs are never loaded in full -- only queried when investigating a specific page's history.

**Phase relevance:** Phase 1 should set up the log format with rotation in mind. Actual rotation can be manual initially.

**Confidence:** MEDIUM -- log management is straightforward but easy to defer until it becomes a problem.

---

### Pitfall 13: Personal Knowledge Domain Has Unique Sensitivity

**What goes wrong:** The first domain is personal -- goals, health, psychology, journal entries. LLM agents process this deeply personal content. The wiki might compile sensitive health information alongside career goals alongside relationship reflections. If the wiki is ever shared (accidentally or intentionally), or if LLM API calls send this content to external servers, there is a privacy risk that does not exist with, say, a technical wiki.

**Prevention:**
1. Establish a clear data classification in the schema: what is sensitive (health, relationships, finances) vs. shareable (book notes, concept summaries).
2. Consider whether sensitive pages should be in a separate vault or folder with different handling rules.
3. Be explicit in the schema about what gets sent to LLM APIs -- the raw journal entry, the compiled wiki page, or both.
4. Git history preserves all versions permanently. If sensitive content is ingested and then deleted, it remains in git history unless explicitly purged.

**Phase relevance:** Phase 1. The directory structure and data classification should account for sensitivity from the start.

**Confidence:** MEDIUM -- the risk is real but severity depends on the user's specific data and sharing patterns.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Schema design (Phase 1) | Over-engineering -- too many page types, operations, markers before validation | Start minimal (3 page types, 3 epistemic markers). Define extension points, not extensions. |
| Template creation (Phase 1) | Obsidian compatibility issues in templates | Test every template in Obsidian before declaring Phase 1 complete. |
| First ingestions (Phase 1/2) | Hallucination during summarization goes undetected | Spot-check first 10 ingestions manually. Establish the audit habit early. |
| Index system (Phase 1) | Index designed as single file, becomes bottleneck later | Make index regenerable from frontmatter. Keep it lightweight. |
| Cross-references (Phase 2) | Broken wikilinks accumulate | Lint pass for link resolution must run on every ingest. |
| Schema drift (Phase 2+) | Second agent (Codex) produces different formatting | Test new agents with a controlled ingest. Diff output against Claude's output for same source. |
| Scale (Phase 3+) | Context window limits break cross-wiki operations | Design all workflows as index-first from Phase 1. Monitor token usage per operation. |
| Staleness (Phase 3+) | Time-sensitive claims go stale without warning | Freshness metadata in Phase 1 schema. Lint rules for staleness in Phase 2. |
| Compilation pipeline (Phase 2+) | Partial failures leave wiki in inconsistent state | Git-as-transaction pattern. Log operations as in-progress/complete. |

## Sources

- Training data (cutoff: mid-2025). Web search was unavailable during this research session.
- Pitfalls are synthesized from: LLM agent system design patterns, knowledge management system failure modes, Obsidian plugin ecosystem conventions, and distributed systems consistency principles.
- Confidence levels are generally MEDIUM because web verification was not possible. The core patterns (hallucination, context limits, schema drift, over-engineering) are HIGH confidence from extensive training data coverage.

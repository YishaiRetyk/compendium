# Phase 4: Query & Structured Operations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-12
**Phase:** 04-query-structured-operations
**Areas discussed:** Query write-back scope, Delta compilation, CLI search helper, Operations executor

---

## Query Write-Back Scope

### New page vs update existing

| Option | Description | Selected |
|--------|-------------|----------|
| Topic match decides | UPDATE existing page if topic matches, create new only when no page covers topic | |
| Always new page | Every query synthesis creates a new page | |
| Threshold-based | Minor additions UPDATE, substantial synthesis creates new page | |
| Page ownership (user-proposed) | Existing page owner -> update; no clear owner or distinct artifact -> new page | ✓ |

**User's choice:** Hybrid approach — update if a page clearly owns the topic, create new page only for distinct reusable artifacts no single page cleanly owns. Not "topic match decides" and not generic "threshold-based."
**Notes:** User emphasized: do not create query-specific pages just because output came from a query. Do create new pages for comparisons, overviews, and reflections when they deserve to exist as first-class pages.

### Write-back threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Novel claims or connections | Write back when answer produces claims/connections/framing not in wiki | |
| Novel or durable synthesis (refined) | Broader: includes comparisons, reframings, decision notes | ✓ |
| Always write back | Every query answer written to wiki | |
| User decides per query | LLM proposes, user confirms | |

**User's choice:** Novel or durable synthesis (refined from "novel claims or connections")
**Notes:** User provided concrete trigger list: new claim, new connection, meaningful reframing, reusable artifact, correction. And concrete skip list: pure lookup, reformatted restatement, transient answer. Emphasis on "novel or durable" being broader than just "novel claims."

### Page type for query-created pages

| Option | Description | Selected |
|--------|-------------|----------|
| Match content to existing types | Use 5 existing types based on what synthesis actually is | ✓ |
| New 'synthesis' page type | Distinct type for query-generated output | |
| Always overview type | Default all to overview/synthesis | |

**User's choice:** Match content to existing types
**Notes:** Principle: "type by semantic role, not by origin." User added that decision/reflect pages should also be an option if that type exists in schema. Splitting wiki by workflow instead of knowledge structure was explicitly rejected.

### Write-back audit trail

| Option | Description | Selected |
|--------|-------------|----------|
| Log the reasoning | Log entry includes which trigger was met or why skipped | ✓ |
| Just log the outcome | What pages created/updated, no why | |

**User's choice:** Log the reasoning — structured and terse, not narrative.

---

## Delta Compilation

### Detection mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Source-page gap check | Check if source claims appear in topic pages via provenance | |
| Timestamp comparison | Compare source dates against page updated_at | |
| Explicit compilation status | Add compilation_status field to source frontmatter | |
| Explicit status + gap validation (user-proposed) | Primary: compilation_status field; secondary: provenance gap check | ✓ |

**User's choice:** Explicit compilation status as primary mechanism, source-page gap validation as secondary check.
**Notes:** User specified multi-state model: `pending | partial | compiled | stale` (not just boolean). Additional fields: `compiled_against_hash` and `compiled_targets`. Timestamps explicitly rejected as too noisy. User emphasized: query-time detection should not rely on inference if you can track state directly.

### Compilation scope at query time

| Option | Description | Selected |
|--------|-------------|----------|
| Query-scoped only | Compile only claims relevant to current query | ✓ |
| Full source compilation | Run full merge pass for any uncompiled source found | |
| Flag only, don't compile | Note gap, user triggers compilation later | |

**User's choice:** Query-scoped only as default
**Notes:** Full-source compilation as exception (source central to many pages, or user explicitly asks). Never flag-only as main behavior — weakens compounding loop. Log remaining uncompiled material for later pickup by ingest, lint, or another query.

---

## CLI Search Helper

### Script scope

| Option | Description | Selected |
|--------|-------------|----------|
| Index lookup + grep | Parse index, grep wiki/, print paths + snippets | |
| Query scaffolder | Accept question, find pages, print LLM prompt | |
| Both modes | Default: index/grep search. --query flag: scaffolder mode | ✓ |

**User's choice:** Both modes (dual-mode script)
**Notes:** Same philosophy as ingest helper. Default mode useful as standalone primitive for lint, debugging, inspection. --query mode for LLM handoff with progressive-disclosure instructions.

### Output format

| Option | Description | Selected |
|--------|-------------|----------|
| Path + TL;DR | File path + first line of TL;DR section | ✓ |
| Path only | Just file paths, one per line | |
| Full frontmatter | Path + key frontmatter fields | |

**User's choice:** Path + TL;DR as default
**Notes:** Optional flags for other modes: --paths-only, --frontmatter, --json (deferred).

---

## Operations Executor

### Enforcement approach

| Option | Description | Selected |
|--------|-------------|----------|
| Schema-encoded self-validation | LLM validates against AGENTS.md rules only | |
| Bash validator script | bin/validate-op.sh checks preconditions deterministically | ✓ |
| Pre-commit hook | Git hook validates at commit time | |

**User's choice:** Bash validator script (with AGENTS.md rules as first layer)
**Notes:** User explicitly disagreed with the self-validation recommendation. Reasoning: "deterministic executor/validator" implies checks happen outside the model. LLM can skip its own rules. The most important validations (file exists, YAML parses, provenance resolves, privacy flags) are easy to script deterministically. Policy (AGENTS.md) vs enforcement (bash script) — two layers. Pre-commit hook deferred as optional defense-in-depth.

### Validator checks

| Option | Description | Selected |
|--------|-------------|----------|
| Four mechanical checks | Target exists, YAML parses, provenance resolves, privacy respected | |
| Four + log validation | Same four plus verify operation logged | |
| Five checks (four + MERGE) | Four checks plus MERGE-specific (both pages exist and distinct) | ✓ |
| Minimal: target exists only | Just file existence | |

**User's choice:** Five checks (four mechanical + MERGE-specific)

### Validation timing

| Option | Description | Selected |
|--------|-------------|----------|
| Before each operation | Validate one-at-a-time, fail-fast per op | |
| Batch after all proposed | Propose all, validate all, apply all or abort | ✓ |
| Post-apply verification | Apply first, validate after | |

**User's choice:** Batch after all proposed, with fail-fast before any apply
**Notes:** User disagreed with per-operation recommendation. Reasoning: pipeline is batch-shaped (diff -> extract -> merge -> lint), validator should match. Per-op validation misses cross-operation issues and increases tool chatter. Optional per-op re-validation for destructive operations (MERGE, SUPERSEDE, ARCHIVE).

### Invocation pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Direct CLI call | bin/validate-op.sh OPERATION target — args, prints PASS/FAIL | ✓ |
| Stdin JSON | Pipe JSON descriptor to script | |

**User's choice:** Direct CLI call

### Log format

| Option | Description | Selected |
|--------|-------------|----------|
| Structured prefix + terse rationale | Parseable operation/target prefix, human-readable rationale | ✓ |
| Full structured (JSON-like) | Explicit fields for everything | |
| Prose only | Free-form narrative | |

**User's choice:** Structured prefix + terse rationale
**Notes:** User specified format: `## [YYYY-MM-DD] OPERATION | target` with source/result/reason lines. Avoid JSON dumps; avoid prose only.

---

## Claude's Discretion

- Exact implementation of bin/search.sh and bin/validate-op.sh internals
- AGENTS.md wording for new sections
- Whether to update AGENTS.md incrementally or batch

## Deferred Ideas

None — discussion stayed within phase scope

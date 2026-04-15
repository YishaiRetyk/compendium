# Phase 3: Ingestion & Provenance Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-10
**Phase:** 03-ingestion-provenance-pipeline
**Areas discussed:** Claim extraction granularity, Incremental update strategy, CLI ingest helper UX, Validation with real source

---

## Claim Extraction Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic claims | One provenance marker per distinct assertion. High density, maximum traceability. | |
| Paragraph-level claims | One claim per paragraph or logical section. Coarser but faster. | |
| Adaptive by source type | Atomic for papers/articles, paragraph-level for transcripts/journals. Source classification drives depth. | ✓ |

**User's choice:** Adaptive by source type, with bias toward atomic for durable factual/conceptual claims.
**Notes:** User consulted an external advisor who recommended adaptive-by-source-type with specific per-type defaults. Key heuristic: "the smallest unit that preserves meaningful provenance without making the page unreadable." User and Claude agreed this is the right approach — it matches the existing source classification in AGENTS.md §10 Pass 0.

---

## Incremental Update Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Append-then-synthesize | Add new claims to detail sections, re-synthesize summaries. Balances auditability with readability. | ✓ |
| Full section rewrite | Rewrite affected sections from scratch. Most coherent but risks losing nuance, harder to diff. | |
| Strict append-only | Only add below existing content, never touch existing text. Maximum auditability but degrades coherence. | |

**User's choice:** Append-then-synthesize as default. Full rewrite reserved for exceptional drift. Strict append only for logs/source summaries.
**Notes:** User provided a detailed operational rule: (1) add claims to detail sections preserving existing material, (2) mark old claims superseded/stale explicitly — never silently delete, (3) re-synthesize TL;DR and Key Facts, (4) record framing changes in decision entries. Mantra: "append in the detail layer, synthesize in the summary layer, supersede explicitly when needed."

---

## CLI Ingest Helper UX

| Option | Description | Selected |
|--------|-------------|----------|
| Scaffold only | Bash script: creates directory, copies file, computes hash, prints instructions. No LLM API. | ✓ |
| Full orchestrator | Node.js CLI that scaffolds AND calls LLM API. Turnkey but breaks agent-agnosticism. | |
| Prompted template | No CLI — just a documented prompt template in AGENTS.md. Zero tooling. | |

**User's choice:** Scaffold only, implemented in Bash.
**Notes:** Keeps the system agent-agnostic with zero API dependencies. Script handles file bookkeeping; LLM agent runs the actual pipeline.

---

## Validation with Real Source

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, 2 sources | Two contrasting types to validate pipeline + adaptive granularity + incremental updates. | ✓ |
| Yes, 1 source | Single ingest, simpler but doesn't test incremental updates. | |
| No, defer to user | Phase delivers pipeline and CLI only, user does first ingest. | |

**User's choice:** Two sources — an article (Kahneman domain, tests atomic extraction + incremental updates) and a journal entry (tests coarser extraction).
**Notes:** Article chosen in Kahneman domain specifically to test incremental updates against existing Phase 2 example pages.

---

## Claude's Discretion

- Exact content of validation test sources
- CLI script internal implementation details
- Exact wording of AGENTS.md updates
- Batching of AGENTS.md changes across plans

## Deferred Ideas

None — discussion stayed within phase scope

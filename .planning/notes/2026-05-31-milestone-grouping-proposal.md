# Milestone Grouping Proposal — seeds + backlog → v1.2/v1.3/v1.4

Captured 2026-05-31 from a roadmap-organization discussion. **Advisory lineage, not a commitment.** This records *how* the current seeds and live backlog phases would group into future milestones, so the reasoning survives until `/gsd-new-milestone` formalizes it. It deliberately does NOT bake v1.3/v1.4 phase structure into ROADMAP.md — see "Why this stays a note."

## Two framing decisions

1. **Notes are lineage, not work items.** The seven `.planning/notes/` files are evidence/reasoning referenced *by* phases, never *scheduled into* them. Only the 4 seeds + the live 999.x backlog (999.3–999.6) are milestone material. (Note dispositions: openbrain-critique + agentic-gtd-boundary → absorbed into Phase 12 DR; wiki-compiler-idea + agents-md-size-risk + planning-dir-git-asymmetry → historical/resolved; progressive-disclosure-framework-comparison → feeds v1.2 below; neo4j-graph-tools-comparison → feeds Phase 13 + 3 seeds.)
2. **The organizing axis is gating type, not theme.** *Prioritization-gated* = build whenever chosen. *Observation-gated* = build only when usage/scale produces the signal. Mixing them in one schedule is how roadmaps rot, so each item below is tagged.

## Proposed grouping

### v1.1 (finish — committed, no reshuffling)
Phases 13 (Claim Faithfulness) → 13.1 (Docs + Obsidian) → 13.2 (Closure Gate). Nothing from the backlog jumps this queue.

### v1.2 — Schema Architecture  [prioritization-gated; do next; foundational]
The project already named this v1.2 (backlog 999.4). The `workflows-operations-to-skills` seed is literally its Phase C. Merge:
- **2A Reference extraction** (999.4-A): §4–8, §13 → `schema/reference/*.md` (low-risk)
- **2B Workflow extraction** (999.4-B + `workflows-operations-to-skills` seed): §9–12 → `schema/workflows/*.md`
- **2C Skills overlay** (999.4-C, optional): thin `.claude/skills/` routers
- **Fold-in candidate:** `llm-drafted-domain-scaffold` seed + 999.3 (template placeholders) both touch `init-wizard.sh` + `AGENTS.template.md` + `schema/` — the same files 2A/2B restructure. Doing them here = touch the wizard once, not twice. Add as a 4th phase rather than a separate "adoption" milestone.

**Why first / why it waits for v1.1 close:** it shrinks the always-loaded spec (the project violates its own §7 progressive-disclosure principle *on its own spec*). But 999.4 refactors `AGENTS.md`, which phases 13/13.1/13.2 actively execute against — refactoring mid-flight = churn. So: gated on v1.1 closure, then it's the next milestone. Pre-designed in `.planning/phases/999.4-…/CONTEXT-NOTES.md`.

### v1.3 — Wiki Intelligence  [mostly observation/scale-gated]
Structure-level sibling of Phase 13's claim-level integrity. From the `wiki-quality-heuristics` seed + 999.5:
- **3.1 Tag/domain consolidation** (seed b) — needs vocabulary sprawl to be worth it
- **3.2 Cluster/overview detection + connectivity ranking** (seed c) — needs wiki volume
- **3.3 External-source drift** (999.5) — needs web-backed sources
- **3.4 Embedding index + semantic dedup (a2) + local/global routing** (seed d + a2 + e) — Tier-4-gated (§14) + local embedding model
- **NOT in this milestone:** lexical dedup (seed a1) is dependency-free and carved out as a `/gsd-quick` enhancement promotable the moment a duplicate-ish pair appears (precedent: 999.7). See the seed.

### v1.4 — Agent Interface  [mixed gating; biggest forward bet]
From the `agent-memory-interface` seed:
- **4.1 Tier-1 read/search/compare MCP surface** — prioritization-gated; low-risk; could pull *earlier* if a second system needs read access
- **4.2 Tier-2 guarded write operations** — observation-gated; needs a real second system AND Tier-4 concurrency

**Shared prerequisite:** 4.2 and v1.3's 3.4 both need §14 Tier 4 — whichever milestone reaches Tier 4 first pays that cost for both.

### Standing / unscheduled
- **999.6 (Observed GTD patterns)** — trigger-gated on 2 months real usage; documents what emerged, by definition un-schedulable. No milestone number.

## Why this stays a note (not a ROADMAP edit)

v1.2 is prioritization-gated and ready, so it can be formalized via `/gsd-new-milestone` the moment v1.1 closes. But **v1.3 and v1.4 are observation-gated** — it is not yet known whether a Wiki-Intelligence or Agent-Interface milestone is even warranted (needs wiki volume / a real second system). Writing their phase structure into ROADMAP.md now would be speculative scheduling — exactly the rot the gating-type framing exists to prevent, and against the project's "Explicitly Deferred / don't drift into compendium-as-everything" stance. They stay as seeds with trigger conditions (their correct durable form); this note records the *intended grouping* so it isn't re-derived later.

## Actionable now vs. later

- **Now:** ROADMAP housekeeping — fixed the stale 12.1 progress-table row (was `0/4 Planned`, now `4/4 Complete 2026-05-03`); reorganized the backlog into live (999.3–999.6) vs. Archived/Delivered (999.1, 999.2, 999.7). (Done in the same commit as this note.)
- **At v1.1 close:** `/gsd-new-milestone` → formalize **v1.2 Schema Architecture**.
- **Later, on trigger:** promote `wiki-quality-heuristics` / `agent-memory-interface` seeds when their gates fire; lexical dedup anytime via `/gsd-quick`.

## Related artifacts
- Seeds: `agent-memory-interface.md`, `wiki-quality-heuristics.md`, `llm-drafted-domain-scaffold.md`, `workflows-operations-to-skills.md`
- Live backlog: ROADMAP.md §Backlog 999.3–999.6
- Comparison lineage: `.planning/notes/2026-05-31-neo4j-graph-tools-comparison.md`
- v1.2 design substance: `.planning/phases/999.4-v1-2-schema-architecture-progressive-disclosure-refactor/CONTEXT-NOTES.md`
- Tier-4 constraint: AGENTS.md §14; Phase-12 boundary: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md`

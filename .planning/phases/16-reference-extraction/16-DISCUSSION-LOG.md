# Phase 16: Reference Extraction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 16-reference-extraction
**Areas discussed:** Routing table, Stub format, sync drift guard (Q7), Authority framing (Q8), §4 resident remnant

---

## Routing table (REF-08)

| Option | Description | Selected |
|--------|-------------|----------|
| Operation + topic, two columns | Rows keyed by both the 4 ops AND static topics → target file + one-line "when you need this"; ~30 lines | ✓ |
| Section-number keyed | Rows keyed by old §-numbers; preserves muscle-memory but §-numbers vanish post-extraction | |
| Pure file index | Flat list of files + descriptions, no operation/topic mapping; weaker dispatch | |

**User's choice:** Operation + topic, two columns.
**Notes:** Load-bearing dispatch artifact (Vercel 56%-miss mitigation) — one-hop find from AGENTS.md alone.

---

## Stub format

| Option | Description | Selected |
|--------|-------------|----------|
| Resident-remnant per the map | Follow the map's per-section resident-remnant column (mixed depth) | |
| Uniform bare pointers | Every extracted section → 1-line pointer, no inline essence | ✓ |

**User's choice:** Bare link farm (uniform bare pointers).
**Notes:** User's rationale — "if we go 'always-loaded safety document' we lose single source of
truth and the agent is more likely to act based on it rather than read the ref." Claude agreed and
added the bounding distinction: bare-pointer applies to reproduced *reference content*; the
separately-locked **safety core** (MUST-NOT, write-back line, structured-op vocab, provenance
*requirement* one-liner) is a *trigger*, not a stub, and stays resident (milestone Design
Constraint). §6 inline example dropped as a consequence (drift risk; lives in provenance.md).

---

## §4 resident remnant

| Option | Description | Selected |
|--------|-------------|----------|
| Names-only (refine the lock) | Core keeps 6 type names (dispatch); section-ordering tables extract to page-types.md | ✓ |
| Honor the lock verbatim | Keep merged type-roster + section-ordering table resident (~10 lines) per the map | |

**User's choice:** Names-only — chosen after asking Claude "which is better practice?"
**Notes:** Claude's recommendation, accepted: names-only is what the milestone's own **inclusion
test** produces when applied strictly — the 6 type names are *dispatch* (stay); section-ordering
tables fail all three clauses (JIT load point at authoring + gate-caught miss via lint) so they
extract. This refines the LOCKED §4↔§7 dedupe's *remnant contents* without reversing the dedupe
itself; to be recorded as an explicit, justified deviation in the REF-10 decision record.

---

## sync drift guard (Open Q7 / REF-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Defer to v1.3 | Phase 16 keeps only AGENTS↔CLAUDE byte-check + AGENTS.template mirror | |
| Add --check-tree now (Phase 16) | Build tree-drift guard in Phase 16 | |
| Add --check-tree at END of Phase 17 (v1.2) | Build once the full reference+workflows tree exists | ✓ |

**User's choice:** End of Phase 17 (user pushed back: "perhaps defer to the end of phase 17? why not
close in this milestone?").
**Notes:** Claude conceded its "v1.3" framing was the lazy default. The tree only fully exists after
Phase 17 (16 creates reference/, 17 creates workflows/), so a Phase-16 guard covers half the tree;
end of Phase 17 is the natural close, stays in v1.2. Semantics pinned: `--check-tree` verifies
"every routing-stub target in core resolves to a file that exists" (resolution check, not a
byte-compare — there's no second copy to compare against).

---

## Authority framing (Open Q8 / REF-10)

| Option | Description | Selected |
|--------|-------------|----------|
| Router + per-section authority | "This file is the router; each linked file is authoritative for its own sections" | ✓ |
| Collective authority | "This file + reference/ + workflows/ collectively form the authoritative spec" | |

**User's choice:** Router + per-section authority.
**Notes:** Cleanest mental model; matches the progressive-disclosure thesis. Replaces core line 3
("No other file contains conventions, rules, or workflow definitions"). Capture in REF-10 DR.

---

## Claude's Discretion

- Exact stub wording, precise routing-table row set/ordering, extraction/move sequencing + commit
  structure, AGENTS.template.md mirror mechanics, `--check-tree` implementation (Phase 17), and how
  `schema/workflows/lint.md` is seeded for the §6 decay/staleness math without pre-empting Phase 17.

## Deferred Ideas

- `bin/sync-claude.sh --check-tree` build → END of Phase 17 (carry D-08 semantics into WF reqs).
- Open Q9 (solo structured-op commit prefix), Open Q10 (mutation→log coupling gate, recommended
  rejected) → Phase 17 §9/§12 extraction.
- `schema/workflows/*.md` except the lint.md decay/staleness seed → Phase 17.
- Reviewed-not-folded todo: `phase-14-lint-mask-fence-edge-cases` (Phase-14 lint residue; unrelated
  to reference-text extraction; belongs to Phase 17 or a standalone quick task).

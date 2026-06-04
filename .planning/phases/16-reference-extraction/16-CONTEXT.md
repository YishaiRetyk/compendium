# Phase 16: Reference Extraction - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract every **static reference section** of the 1,655-line `CLAUDE.md` / `AGENTS.md`
monolith into standalone markdown files, replacing each in core with a routing
**stub**, and add an `IMPORTANT:`-flagged **routing table** at the top of core. This is
Phase A of v1.2 — it applies the project's own §7 progressive-disclosure principle to
its own spec.

**Targets (per the Extraction Map — single source of truth for exact line ranges):**
- §4 page types → `schema/reference/page-types.md`
- §5 frontmatter → `schema/reference/frontmatter.md`
- §6 provenance (consumer-split) → syntax/epistemics to `schema/reference/provenance.md`; **decay table + staleness auto-fix to `schema/workflows/lint.md`** (created/seeded here, owned by Phase 17)
- §7 progressive disclosure → **dissolves** (no standalone file)
- §8 wikilinks (+ §3 Red Links) → `schema/reference/wikilinks.md`
- §13 privacy (Phase-15 asymmetric form) → `schema/reference/privacy.md`
- §14 scaling → `docs/reference/scaling.md`; §15 tooling → `docs/reference/tooling.md`
- §16 appendices → **deleted** (already pointers)

**Covers:** REF-01..REF-10.

**Depends on:** Phase 15 (§13 had to be rewritten to its asymmetric two-dir form
before it can be extracted; PRIV-07 feeds REF-06). Phase 15 is shipped.

**Out of scope (firm boundaries):**
- Workflow sections §9/§10/§11.1–11.7/§12 → **Phase 17** (WF). Phase 16 may *create/seed*
  `schema/workflows/lint.md` only because REF-03's consumer-split routes the §6 decay/staleness
  math there; the rest of `workflows/` is Phase 17's.
- Any **behavioral change** to lint/validate/privacy/neutrality logic. Extraction relocates
  *text*, not logic; all CI gates must pass unchanged in behavior.
- Skills overlay (Phase C/18) and Wizard fold-in (Phase D, deferred to backlog 999.3).
- Determinism pass (helper scripts/validators for extracted workflows) — explicit second pass, post-extraction.

</domain>

<decisions>
## Implementation Decisions

### Stub format — bare pointers, SSOT-first (NEW, this discussion)
- **D-01: Extraction stubs carry ZERO reproduced reference content.** Each of the ~10
  extracted sections collapses to a bare pointer (`→ see schema/reference/X.md`). Rationale
  (user): keeping inline essence creates a second copy that drifts from the leaf file (no single
  source of truth) AND tempts the agent to act on the partial inline text instead of reading the
  authoritative ref. Bare pointer removes both hazards.
- **D-02: The resident *safety core* is NOT an extraction stub and stays resident.** The four
  always-loaded safety items the milestone Design Constraints lock as resident — **MUST-NOT list
  (verbatim), write-back-mandatory line, structured-op vocabulary, and the provenance *requirement*
  one-liner** — are *triggers*, not reproduced reference content. They stay. Distinction that
  governs D-01: a **stub** points at content that lives in a leaf; the **safety core** is the one
  line that makes the agent go read the leaf (e.g. "every claim needs provenance — see
  provenance.md"). Removing it would not improve SSOT — it would remove the prompt to consult the
  SSOT, and an agent could start authoring and never learn the rule on demand.
- **D-03: §6 keeps its one-line provenance *requirement* but DROPS the inline example.** The
  example is reproduced reference content (drift risk, D-01) and lives in `provenance.md`. This
  refines the Extraction Map's "requirement + 1 example (~4 lines)" remnant down to the
  requirement line only.

### §4 resident remnant — names-only (NEW, refines a LOCKED decision)
- **D-04: Core keeps the 6 type *names* (dispatch vocabulary); the section-ordering tables
  EXTRACT to `page-types.md`.** This is a deliberate, justified refinement of the LOCKED §4↔§7
  dedupe ("one merged type-roster + section-ordering table resident"). Derivation via the
  milestone's own **inclusion test**: the 6 type names are *dispatch* (you can't route "which file
  documents this type?" without knowing the six options exist) → stay; the section-ordering tables
  fail all three inclusion-test clauses — they have a clean JIT load point (only needed when
  *authoring* a page, i.e. exactly when you'd open `page-types.md`) and a gate-caught miss-cost
  (lint validates per-type section structure) → extract. The §4↔§7 **dedupe itself** (one roster,
  §7 dissolves) is untouched; only *what the merged remnant contains* is trimmed.
- **Planner note:** record this as an explicit deviation from the Extraction Map's resident-remnant
  column in the REF-10 decision record, with the inclusion-test + SSOT rationale above.

### Routing table (REF-08) — operation + topic, two-axis
- **D-05: The `IMPORTANT:`-flagged routing table is keyed by BOTH the 4 operations
  (ingest/query/lint/reflect) AND static topics (page-types, frontmatter, provenance, wikilinks,
  privacy), each row → target file + a one-line "when you need this".** Most navigable; ~30 lines
  as the map budgets. This is the load-bearing dispatch artifact (Vercel 56%-miss mitigation): an
  agent given only `AGENTS.md` must find any reference material in one hop. Section-number keying
  (rejected — §-numbers vanish post-extraction, ages badly) and a pure flat file index (rejected —
  weak dispatch; forces the agent to infer the intent→file mapping, the exact miss this exists to
  prevent).

### sync-claude drift guard (Open Q7 / REF-09) — `--check-tree`, deferred to END of Phase 17
- **D-06: Phase 16 scope for REF-09 = the EXISTING `AGENTS.md ≡ CLAUDE.md` byte-check + mirror all
  routing stubs into `schema/AGENTS.template.md`.** No new tree-drift tooling in Phase 16.
- **D-07: Add a `bin/sync-claude.sh --check-tree` guard at the END of Phase 17, NOT v1.3.** Rationale
  (user, correcting the orchestrator's lazy "defer to v1.3"): the `schema/reference|workflows/*.md`
  tree does not fully exist until Phase 17 finishes (Phase 16 creates `reference/`, Phase 17 creates
  `workflows/`); a guard built in Phase 16 would only cover half the tree. End of Phase 17 is the
  natural close point — the full tree exists, the wizard's wholesale-copy path is settled — and it
  stays **in v1.2**.
- **D-08: What `--check-tree` guards = "every routing-stub target in core resolves to a file that
  exists."** Not a byte-compare (there is no second copy of these files, unlike AGENTS↔CLAUDE) — a
  link-target existence/resolution check over the routing table + all in-core stubs. (Carry this to
  Phase 17's WF requirements as the concrete REF-09-extension spec.)

### "Sole authoritative specification" framing (Open Q8 / REF-10) — router + per-section authority
- **D-09: Evolve core line 3** ("No other file contains conventions, rules, or workflow
  definitions") to **"this file is the router; each linked file is authoritative for its own
  sections."** Cleanest mental model and matches the milestone thesis: core dispatches, leaf files
  own their domain. The "collective authority" phrasing (this file + reference/ + workflows/
  *collectively*) was rejected as less crisp about who owns what. Capture in the REF-10 decision
  record.

### Claude's Discretion
- All plan-time mechanics: exact stub wording, the precise routing-table row set and ordering, the
  extraction/move sequencing and commit structure, the `--check-tree` implementation details (Phase
  17), the AGENTS.template.md mirror mechanics, and how `schema/workflows/lint.md` is seeded for the
  §6 decay/staleness math without pre-empting Phase 17's ownership. The Extraction Map's exact line
  ranges + the decisions above are sufficient direction.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design source of truth (extraction map + locked decisions)
- `.planning/milestones/v1.2-MILESTONE-BRIEF.md` — **the single source of truth** for exact line
  ranges, target files, and resident remnants per section. Read in full:
  - §"Extraction Map — Inclusion-Test Disposition" (lines ~132–214) — the per-section line ranges,
    the resident-core composition table, and the **Locked decisions** block (commit table, §5
    Option-B, §6 consumer-split, §4↔§7 dedupe, §10/§12 dispositions).
  - The **inclusion test** (lines ~138–148) — ambient / unscriptable-unacceptable-miss / dispatch.
    This is the governing rule for what stays resident; D-04 is derived from it.
  - §"Design Constraints (Non-Negotiable)" (lines ~216–231) — markdown-authoritative, byte-equality,
    wizard pipeline preserved, **always-loaded safety core stays resident**, CI gates unchanged.
  - §"Decisions Required Before / During Discuss" (lines ~341–364) — Open Q6/Q7/Q8 (Q7→D-06/07/08,
    Q8→D-09); Q9/Q10 belong to Phase 17.
- `.planning/REQUIREMENTS.md` — REF-01..REF-10 text + Out-of-Scope table + traceability.
- `.planning/ROADMAP.md` §"Phase 16: Reference Extraction" — Goal + 5 Success Criteria (what must
  be TRUE).

### Prior-phase context (Phase 15 — gates this phase)
- `.planning/phases/15-privacy-architecture/15-CONTEXT.md` — the asymmetric two-dir model now in
  §13 that REF-06 extracts (D-16 there: §13 reduced to a ~2-line structural pointer; 7-row
  precedence table removed, not relocated). REF-06 extracts the *already-rewritten* §13, not the
  per-page form.

### The file being refactored (`CLAUDE.md` ≡ `AGENTS.md`, byte-identical)
- `CLAUDE.md` / `AGENTS.md` — the live 1,655-line monolith. Every §4/§5/§6/§7/§8/§13/§14/§15/§16
  edit lands in BOTH (pre-commit `bin/sync-claude.sh --check`).
- `schema/AGENTS.template.md` (1,621 lines) — wizard source; every routing stub mirrors here (REF-09).

### Tooling / gates that must stay green (behavior unchanged)
- `bin/sync-claude.sh` — `--check` byte-equality gate (REF-09 base; `--check-tree` extension → Phase 17).
- `bin/init-wizard.sh` — `--dry-run` output unchanged for existing placeholders; extracted
  `schema/reference|workflows/*.md` are **copied wholesale** (no new render logic).
- `bin/lint.sh` (3-job CI), `bin/check-privacy.sh`, `bin/check-neutrality.sh` — operate on content,
  not file boundaries; must pass over the new `schema/reference/*.md` tree.
- `docs/reference/` already exists (agent-parity.md, ci.md, privacy-model.md, etc.) — §14/§15 land
  here; note the relationship between new `schema/reference/privacy.md` (agent-authoritative, terse)
  and existing `docs/reference/privacy-model.md` (end-user full model) — do not duplicate.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/sync-claude.sh` — existing `--check` byte-equality gate; case-based flag parsing (line ~11).
  REF-09 base behavior; `--check-tree` is a Phase-17 extension (D-07/08), not built here.
- `bin/init-wizard.sh` — renders `AGENTS.md` from `schema/AGENTS.template.md`; extracted files are
  copied wholesale, so no new render logic (milestone Design Constraint).
- `docs/reference/` tree already established (13 files) — §14/§15 slot in as siblings.

### Established Patterns
- **`CLAUDE.md` ≡ `AGENTS.md` byte-equality** enforced by pre-commit `sync-claude --check` — every
  section edit must land in both copies in the same commit.
- **DR-at-execution precedent** (`dr-2026-06-03-uniform-piped-links`, `dr-…-privacy-asymmetric-two-dir`)
  — schema-update decision records are written when the change ships, not pre-authored. REF-10's DR
  follows this.
- **`schema/reference/` and `schema/workflows/` do not exist yet** — Phase 16 creates `reference/`
  (Phase 17 creates `workflows/`). `schema/` currently holds templates/, fixtures/, examples/,
  brownfield/, obsidian/, and AGENTS.template.md.

### Integration Points
- The §6 **consumer-split** is the one cross-phase seam: decay table + staleness auto-fix route to
  `schema/workflows/lint.md`, which is otherwise Phase 17's file. Plan must seed it without
  conflicting with Phase 17's lint-workflow extraction.
- v1.1.1 **uniform-piped-link truth** (`[[X]]` resolves by filename/path ONLY; uniform `[[id|Title]]`
  mandated) must carry **verbatim** into `schema/reference/wikilinks.md` (REF-05 guard).

</code_context>

<specifics>
## Specific Ideas

- **User's governing principle for stubs (D-01):** "A bare link farm is the way to go. If we go
  'always-loaded safety document' we lose single source of truth and the agent is more likely to act
  based on it rather than read the ref." Applied uniformly to reference *content*; bounded by the
  locked safety-core residence (D-02).
- **`--check-tree` semantics (D-08):** specifically "every routing-stub target in core resolves to a
  file that exists" — a resolution check, not a byte-compare.
- **§4 names-only (D-04)** is the strict output of the inclusion test, not just a style call — the
  section-ordering tables do not *earn* residence (JIT load point + gate-caught miss).

</specifics>

<deferred>
## Deferred Ideas

- **`bin/sync-claude.sh --check-tree`** — built at END of Phase 17, not Phase 16 (D-07). Carry the
  D-08 semantics into Phase 17's WF requirements.
- **Open Q9 (solo structured-op commit prefix)** and **Open Q10 (mutation→log coupling gate,
  recommended rejected)** — belong to Phase 17 §9/§12 extraction, not Phase 16.
- **`schema/workflows/*.md` (except the lint.md decay/staleness seed)** — Phase 17.

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` ("Harden `bin/lint.sh` mask_markdown for fence edge cases",
  area: tooling, score 0.9) — **reviewed, NOT folded** (same call as Phase 15). Keyword-only match
  (bin/lint/markdown/link); it is Phase-14 lint markdown-masking residue, semantically unrelated to
  *reference text extraction*. Belongs to the lint-workflow extraction (Phase 17) or a standalone
  quick task. Remains in `.planning/todos/pending/`.

</deferred>

---

*Phase: 16-reference-extraction*
*Context gathered: 2026-06-04*

# Phase 14: Graph Link Resolution — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03 (re-discussion after premise invalidation)
**Mode:** discuss (default)

Context: the original Phase 14 (self-aliases) was executed, then its premise was proven false at the
LINK-10 human-verify gate — Obsidian resolves `[[X]]` by filename/path only, never via `aliases`.
The user chose to re-plan. This discussion settled the corrected approach.

## Area 1 — Resolution mechanism

**Options presented (with tradeoff analysis):**
- A. Piped links `[[id|Title]]` — resolves in stock Obsidian, clean display, no dependency, plain-markdown, mechanically enforceable.
- B. Bundle an Obsidian resolver plugin — keeps the clean `[[Title]]` convention + shipped self-alias work, but adds an unofficial/fragile internal-API dependency, violates §1 plain-markdown, and conflicts with the v1.2-deferred plugin-distribution boundary.
- C. Bare slug `[[id]]` — resolves, but shows ugly slugs in reading view (rejected in prior DR).

**User selection:** **A — Piped links.** ("lock Option A and move on")
**Rationale:** Only option that is simultaneously stock-Obsidian-resolving, readable, dependency-free, plain-markdown, and lint-enforceable. B's three independent dealbreakers (plain-markdown principle, internal-API fragility, v1.2-boundary) outweigh its zero-rewrite win; C sacrifices readability.

## Area 2 — Piping scope (defines the §8 go-forward rule)

**Options presented (with tradeoff analysis):**
- Uniform — pipe EVERY link unconditionally (`[[id|Title]]` even for single-word titles). Unconditional rule, trivial exact-match `linkres`, eliminates the variant problem, regression-proof; costs more source verbosity + larger diff.
- Minimal — pipe only links that don't already filename-resolve (~19 multi-word pages); keep bare `[[Title]]` elsewhere. Cleaner source, smaller diff; but conditional rule, retains variant reconciliation, silent re-orphan risk.

**User selection:** **Uniform.** ("uniform")
**Rationale:** Unconditional rule is reliable for an LLM-authored, lint-enforced wiki; it dissolves the entire variant-reconciliation layer (display text is cosmetic; only the `id` target resolves) and is regression-proof. Verbosity/churn are one-time, scripted, in source agents don't mind.

## Cascading decisions (Claude's discretion — presented, not objected to)
- `linkres` re-pointed: validate link *targets* resolve to a known `id` (was: self-alias presence).
- `--fix` re-pointed: rewrite bare `[[X]]` → `[[id|X]]` for unique matches (was: self-alias backfill).
- Self-alias invariant DROPPED from §5/§8/templates; the 53 shipped self-aliases KEPT as harmless residue.
- The wrong-premise DR (`dr-2026-06-02-obsidian-filename-alias-resolution`) SUPERSEDED by a corrected one.
- LINK-01..10 + ROADMAP success criteria REWRITTEN to the piped-link reality (first re-plan action).

## Deferred ideas
- Bundle an Obsidian plugin → aligns with v1.2-deferred "plugin distribution".
- Strip vestigial self-aliases → optional future cleanup.
- v1.2 schema progressive-disclosure refactor (999.4) → still sequenced after this phase.

## Notes
- No scope creep raised.
- Process note / retrospective signal: the original Phase 14 premise came from `14-RESEARCH.md` and
  was never validated against real Obsidian behavior before the convention/lint/data were built —
  caught only at the human-verify gate. Validate load-bearing third-party-tool assumptions (here:
  Obsidian link resolution) empirically before building multiple plans on them.

---

*Superseded the original 2026-06-02 discussion log (alias-premise alternatives), preserved in git history.*

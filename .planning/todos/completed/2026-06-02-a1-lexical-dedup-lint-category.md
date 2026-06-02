---
created: 2026-06-02T00:00:00
title: a1 lexical near-duplicate page detection — `duplicate` lint category
area: tooling
blocked_on: Phase 13.2 (v1.1 closure gate) passing
promote_via: /gsd-quick
files:
  - bin/lint.sh
  - AGENTS.md
  - CLAUDE.md
  - schema/AGENTS.template.md
  - docs/reference/ci.md
  - tests/
---

## Problem

`bin/lint.sh` has no near-duplicate page detection — nothing catches
`Geoff Hinton` vs `Geoffrey Hinton` or `Attention Mechanism` vs
`Attention Mechanisms`. This is compendium's weakest current relationship
heuristic. The capability is the dependency-free **a1 (lexical dedup)** stage of
the `wiki-quality-heuristics` seed, carved out for `/gsd-quick` (precedent: 999.7).

## Decision (2026-06-02)

Ship **a1 standalone as `/gsd-quick`, AFTER v1.1 closes** (Phase 13.2 gate passes).
NOT bundled with a2/(b)/(c) — those are observation/Tier-4-gated and stay in the
v1.3 Wiki Intelligence seed. a1 is a rework-free foundation for a2 later
(a2 = a1's code path + one extra candidate predicate). Auto-merge is a permanent
non-goal (§9 MERGE is human-confirmed), NOT part of this task.

## Scope

Full firmed scope (grounded in `bin/lint.sh` as of 2026-06-02) lives in
`.planning/seeds/wiki-quality-heuristics.md` → "a1 — scoped & queued". Summary:

- New `should_run('duplicate')` check in the single python3 block (after `gap`,
  before `drift`); `add_finding('warning', 'duplicate', ...)`, report-only.
- Same-`type` pairs only; candidate iff title/alias substring containment (len>5)
  OR Levenshtein < 3 (titles >5 chars). Pure-stdlib Levenshtein, no new deps.
- Survivor = higher inbound-wikilink count (reuse orphan/crossref link graph).
- Exclude `examples/`, `example: true`, archived/superseded. Feeds MERGE (§9),
  never auto-merges.
- Bump `LINT_VERSION` 1.2.0 → 1.3.0; leave out of `--ci` error remap (stays
  `warning`). Mirror `AGENTS.md §11.3` categories → CLAUDE.md (pre-commit sync) +
  `schema/AGENTS.template.md` + `docs/reference/ci.md`.
- Positive + negative test fixtures.

## Known risk

Live corpus (2026-06-02) shows the substring rule would emit a false positive on
`entities/anthropic.md` vs `entities/anthropic-financial-services.md` (parent org
vs. division). Report-only design absorbs this (human dismisses). If FP rate is
noisy at ship time, gate substring containment behind a token-boundary check.

## Promote when

Phase 13.2 closes (or earlier if a duplicate-ish pair causes real MERGE friction):
`/gsd-quick add a `duplicate` lexical near-duplicate-page lint category to bin/lint.sh per the seed scope`

---

**STATUS: DONE 2026-06-02** — delivered via quick task `260602-d6a` (commit `fcddefc`). `duplicate` lint category shipped; LINT_VERSION 1.4.0. a2/(b)/(c) remain v1.3-deferred in the seed.

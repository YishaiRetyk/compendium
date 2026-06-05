# Phase 17: Workflow Extraction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 17-workflow-extraction
**Areas discussed:** Solo-op commit prefix (Q9), --check-tree guard (D-07/08), Inclusion-test tripwire (WF-08), Agent-parity evidence (WF-09)

---

## Area A — Solo structured-op commit prefix (Open Q9)

| Option | Description | Selected |
|--------|-------------|----------|
| Lowercase op-name prefixes | `update:`/`merge:`/`supersede:`/`archive:` — mirrors §9 vocab + §12 log format; commit↔log symmetry; machine-parseable. Cost: 4 new prefixes. | ✓ |
| Map all solo ops to `reflect()` | Reuse existing reflect prefix; aligns with Tier-1 DR coupling. Cost: non-uniform; a solo UPDATE isn't reflection; loses which op. | |
| Single generic `op()` prefix | One new word covering all four. Cost: loses which op at prefix level; least symmetric with log. | |

**User's choice:** Lowercase per-op prefixes — `update:`/`merge:`/`supersede:`/`archive:`.
**Notes:** Same vocabulary across two surfaces (log `## [date] MERGE | page` ↔ commit `merge(page): …`). No conflict with one-commit-per-logical-operation: within a workflow ops roll up under the workflow prefix; only solo ops get their own. Explicitly rejected routing solo MERGE/SUPERSEDE under `reflect:` (they often spawn a Tier-1 DR) as non-uniform.

---

## Area B — `--check-tree` routing-integrity guard (Phase-16 D-07/D-08 carry-over)

> First-pass question (home + strictness) was rejected by the user as premature — the *scope* of the guard ("concern A") had to be settled first. Reformulated into a 5-decision fork.

| Decision | Options | Selected |
|----------|---------|----------|
| 1. Scope | Narrow (stub-target existence) vs **Broad** (all cross-file refs) | Broad |
| 2. Directionality | Forward-only vs **Bidirectional** (add inverse orphan check) | Bidirectional |
| 3. §-ref policy | Resolve §N vs **Abolish** cross-file §N (forbid pattern, paths only) | Abolish |
| 4. Concern B (external corpus) | In hard guard vs **Separate** (one-shot repoint + optional warning sweep) | Separate |
| 5. Pointer granularity | **File-level default**, anchors only where used | File-level |
| → Home (falls out) | Extend sync-claude.sh / standalone / **fold into lint.sh `routing` category** | lint.sh routing |
| → Enforcement | **CI-only error-checks; `--staged` stays provenance-only** | CI-only |

**User's choice:** Broad + bidirectional + abolish-§N + concern-B-separate + file-level → lint.sh `routing` category (corpus = `schema/` tree; bypass empty-wiki abort), CI-only.
**Notes:** Post-extraction every cross-file §N dangles *by construction* (narrow check would pass green over dead refs). Bidirectional = `linkres` (forward, error) + `orphan` (inverse/unreachable file, warning) — both already exist in lint, re-aimed at `schema/`. Abolish > resolve: forbids the §N pattern, killing the §-fragility that drove the 1,412→1,689 drift (generalizes Phase-16 D-05). Routing integrity is a whole-tree property the per-added-file `--staged` scope structurally can't see → CI-only. External referrers (`ci.md`/`CONTRIBUTING.md`/`lint.yml` → §11.3) fixed via one-shot WF-05 repoint + optional non-blocking warning sweep; hard error guard stays scoped to `schema/`.

---

## Area C — Inclusion-test tripwire (WF-08)

| Option | Description | Selected |
|--------|-------------|----------|
| CI warning at line threshold | Non-blocking warning past an absolute ceiling (e.g. 175). Cost: a budget = a target wearing a warning's clothes → Goodhart. | |
| Comment-in-core note only | HTML comment stating the invariant; no automation. Cost: relies on the discipline that already failed (silent drift). | |
| Both: comment + soft CI warning | Comment documents invariant + non-blocking CI warning. | ✓ (reframed) |

**User's choice:** Option 3 (both surfaces) — but **measured as delta-from-baseline, not absolute threshold.**
**Notes:** Absolute ceiling → Goodhart; comment-only → repeats silent drift. Delta-from-baseline threads both: no number to hit, so it can't become a target (literal "tripwire not target"). Single shared artifact = core header `<!-- inclusion-audit: <N> lines @ <YYYY-MM-DD> -->` (doubles as preventive surface); non-blocking lint `info` fires `core drifted +M lines since last inclusion audit (DATE) — re-run WF-08` past ~+20%/+25-line margin; baseline init = actual post-extraction count, reset by each audit; margin is the only tunable. Honest residual accepted: dishonest baseline bump mitigated by tying it to the WF-08 deliverable's commit/DR trail.

---

## Area D — Agent-parity evidence (WF-09)

| Option | Description | Selected |
|--------|-------------|----------|
| Actual Codex/Cursor run | Real foreign-agent ingest from AGENTS.md-only. Strongest; proves router for non-Claude agent. Cost: manual, needs tool, not CI-reproducible. | |
| Desk-check routing trace | Manually trace routing-table → ingest.md resolution + self-sufficiency. Reproducible, light. Cost: proves path resolves, not that a real agent succeeds. | |
| Both: trace + one recorded run | Desk-check as always-on evidence + one recorded Codex run. | ✓ (reframed to 3-tier) |

**User's choice:** Option 3 — three-tier reachability stack: Mechanical (Area-B routing guard, every CI run, gating) / Documented (scoped desk-check trace, gating floor) / Empirical (Codex/Cursor run, best-effort, NON-gating).
**Notes:** Desk-check assumes the agent *follows* a resolvable pointer → structurally can't validate WF-09's actual claim (behavioral discoverability = the Vercel-56% finding: resolvable ≠ followed). Real run is the only evidence for the headline claim, but can't gate (v1.1 "Codex blocked-on-host-runtime" precedent — never gate on external-tool availability). Desk-check scoped to judgment dims only (routing-table prominence/unambiguity + target-file content self-sufficiency); cite the guard for resolvability, don't re-prove by hand. A failed run is signal (Vercel-56% caught in the wild), recorded verbatim, not suppressed.

---

## Claude's Discretion

All plan-time mechanics: stub wording; per-workflow file naming/granularity; §10 fold framing; extraction/move sequencing + commit structure; WF-05 merge of §11.3 lint body with the Phase-16 decay/staleness seed (preserving "source of truth for CI contracts"); bare per-workflow log-format inlining; `routing` category implementation (severity remap, corpus walk, empty-wiki-abort bypass); WF-08 drift-check threshold mechanics; `--check-tree` ↔ `routing` naming reconciliation; agent-parity.md desk-check trace format. D-07 pre-commit wiring is a light CI-only steer, not a hard pin.

## Deferred Ideas

- **Mutation→log coupling gate** (Open Q10) — recommended REJECTED (false-positive surface for a low-miss-cost hygiene rule); logged for traceability, not adopted.
- **`bin/sync-claude.sh --check-tree` as a flag** — superseded by the lint `routing` category (D-06); intent satisfied, flag not built.
- **`phase-14-lint-mask-fence-edge-cases` todo** — reviewed, NOT folded (third time); behavioral lint change, out of scope for text extraction.

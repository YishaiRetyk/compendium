# Lint Reference: Staleness and Decay

> **Note:** This file contains only the decay table and staleness auto-fix rules (seeded by Phase 16).
> The full lint workflow procedure (`bin/lint.sh` steps, severity tiers, CI flags) is added in Phase 17.
> AGENTS.md §6 decay/staleness content points here.

### Domain-Based Decay Rate Table

Claims inherit temporal relevance from their source publication dates. Different knowledge domains decay at different rates. The lint workflow uses this table to flag stale claims mechanically.

| Domain | Base Decay Period | Rationale |
|--------|-------------------|-----------|
| `software` | 180 days (6 months) | Libraries, APIs, and tooling change rapidly |
| `science` | 730 days (2 years) | Replication and meta-analysis cycles |
| `biography` | 1825 days (5 years) | Biographical facts change slowly |
| `personal-goals` | 90 days (3 months) | Goals evolve with life circumstances |
| (default) | 365 days (1 year) | Fallback for unclassified domains |

**Epistemic status modifiers** (per D-08): Tentative and inferred claims decay faster than their domain default. Multiply the base decay period by the modifier:

| Epistemic Status | Modifier | Effect |
|------------------|----------|--------|
| `sourced` | 1.0 | Base rate |
| `mixed` | 0.85 | 15% faster decay |
| `inferred` | 0.75 | 33% faster decay |
| `tentative` | 0.5 | Twice as fast decay |

**Hash override** (per D-09): If a source page's `content_hash` differs from `compiled_against_hash`, ALL claims linked to that source via `[prov:]` markers are immediately stale regardless of decay window.

**Date fallback chain** for staleness calculation: When `checked_at` is missing from a provenance marker, use (in order): (1) the source page's `ingested_at` date, (2) the wiki page's `updated_at` date.

### Staleness Auto-Fix Rules

The lint workflow applies mechanical staleness fixes (per D-12):

**Claim-level auto-fix:** When a claim's provenance date exceeds its domain decay threshold (adjusted by epistemic modifier), the lint adds `[epistemic:: stale]` after the claim's provenance marker cluster. Rules for marker placement:
- One `[epistemic:: stale]` marker per claim -- do not duplicate if already present
- Place immediately after the last `[prov:...]` marker on the claim line
- If the claim already has `[epistemic:: sourced]` or `[epistemic:: inferred]`, replace it with `[epistemic:: stale]`
- A "claim" is defined as a single bullet point or paragraph containing `[prov:]` markers
- This operation is deterministic and reversible (removing the stale marker restores prior state)

**Page-level status:** The lint only auto-updates page-level `epistemic_status` to `stale` when the rollup clearly warrants it (per D-13): all material claims are stale, OR the TL;DR/Key Facts section contains materially stale claims. Default: do NOT auto-change page-level status.

**Logging:** All auto-fix staleness changes are logged in `wiki-cloud/maintenance/lint-report.md` and `wiki-cloud/log.md` (per D-14).

## See Also

- [AGENTS.md](../../AGENTS.md) — §6 stub (decay/staleness pointer to this file).
- `schema/reference/provenance.md` — provenance syntax, epistemic markers, contradiction markers.

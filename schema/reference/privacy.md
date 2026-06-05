# Privacy Routing

> Agent-authoritative reference for wiki privacy tier routing: `wiki-cloud/` (cloud-safe) vs `wiki-local/` (local-only).
> AGENTS.md §13 points here.

## Structural Rule

Vault tier is **structural**: the directory a page lives in determines its privacy tier.

- `wiki-cloud/` — cloud-safe tier. Cloud sessions may read freely.
- `wiki-local/` — local-only tier. Cloud sessions MUST NOT read this tier.

The enforcement mechanism is the **directory boundary** (harness permissions), not a per-turn agent rule.

**One-way permeability:** local sessions read both tiers; cloud sessions read only `wiki-cloud/`.

**Write-back rule:** If ANY contributing source-summary lives under `wiki-local/`, the write-back target page MUST go into `wiki-local/`.

**Privacy default:** When in doubt, place content in `wiki-local/` — do not expose to cloud sessions.

## See Also

- `docs/reference/privacy-model.md` — full asymmetric model: enforcement options (deny-profile vs. separate-repo), fail-direction table, `sources-local/` forward reference. End-user audience.
- [AGENTS.md](../../AGENTS.md) — §13 stub (pointer to this file).

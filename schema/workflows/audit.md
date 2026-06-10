# Audit Workflow

> Agent-authoritative reference for the review-only claim-faithfulness audit: `bin/audit-claims.sh`, the privacy-partitioned verifier model, and the audit checkpoint.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

The Audit is a **review-only** diagnostic workflow (preserving the four mutation operations: Ingest / Query / Lint / Reflect). It is NOT a fifth top-level operation — the four-operation framing is preserved. The Audit is layered on top, analogous to how Lint is a workflow rather than one of the four mutation operations. It adds no wiki page type.

```
Trigger:  Operator runs bin/audit-claims.sh on-demand; OR a non-binding
          "audit recommended" note surfaces during a lint run.
Inputs:   wiki-cloud/ + wiki-local/ pages with [prov:] claims + the raw sources at their path:.
Outputs:  wiki-local/maintenance/audit-report.md (+ lint-compatible JSON), advanced
          wiki-local/maintenance/audit-state.md checkpoint. NO wiki page is mutated.
Commit:   N/A by default (the audit writes only control-plane artifacts; the
          operator commits the report if they wish to track it).
```

**What it is.** `bin/audit-claims.sh` is a source-grounded, review-only audit. It samples high-risk claims, resolves each `[prov:source_id#locator]` to the cited passage in the **raw** source file at the source page's `path:` (never the source summary's `## Extracted Claims` -- that would be circular), and emits a verdict per claim: `supports` / `weak` / `contradicts` / `insufficient`, plus the operational verdicts `insufficient-locator` (no passage extractable -- e.g. a `#p` locator against an unmarked source per the `schema/reference/provenance.md` page-marker convention), `skipped-privacy` (withheld for privacy), and `skipped-nontext` (`#img`). Findings extend Lint's `{severity, category, path, message}` tuple with `verdict`, `line`, `source_id`, `locator`, and `rationale`, and are written to `wiki-local/maintenance/audit-report.md` (the pattern-twin of `lint-report.md`), grouped by verdict. The audit NEVER mutates a wiki page, never gates by default (no `error` severity -- `contradicts` maps to `warning`, the rest to `info`), and runs on-demand.

**Priority selectors (FAITH-01).** The audit samples from four risk tiers — `stale` (source drifted), `epistemic` (inline tentative/inferred), `recency` (recent changes), `fanout` (high-inbound pages) — plus a 5th tier: `derived-report` (**claims citing `source_type: research-report` sources**, regardless of the marker's support type). Use `bin/audit-claims.sh --select derived-report` to sample this tier in isolation. Such claims are normally `derived` — the only valid support type for research-report sources; a `direct` marker on one is itself a defect that lint flags, and the selector deliberately still includes it for audit visibility. Research-reports carry a lower epistemic default, so the anti-epistemic-laundering defense requires regular verification of this tier.

**Cadence.** The primary path is operator-invoked (`bin/audit-claims.sh`). Additionally, the Lint workflow MAY emit a non-binding `audit recommended: <reason>` note (the `schema/workflows/reflect.md` Tier-2 recommendation pattern) when high-risk-claim counts cross a threshold -- Lint already computes the stale / epistemic / orphan signals, so it is the cheapest host. This note is **informational only**: it does not run the audit, and the audit is never a CI gate in v1.

**Privacy (the load-bearing FAITH-04 contract).** The audit resolves each claim's **effective claim privacy** via the `schema/reference/privacy.md` structural predicate: a claim is effective-`local_only` iff its page OR any contributing source-summary lives under `wiki-local/`. This is NOT "source privacy" alone: the worklist payload carries the wiki page's own claim text, so a page under `wiki-local/` citing a `wiki-cloud/` source must still be withheld. Effective-`local_only` claims are withheld (their claim text AND the resolved passage) from BOTH the verifier subprocess AND the `--emit-worklist` stdout -- the partition gates every passage-bearing egress surface, not just the subprocess. Withheld claims emit a `skipped-privacy` verdict; on a primarily-local vault, a high `skipped-privacy` count is acceptable, expected UX (it satisfies FAITH-04 without forcing a local-model dependency), not a failure to pad around.

On the cloud-facing `--emit-worklist` stdout, a withheld claim's `skipped-privacy` metadata (`source_id` / `path` / `locator`) is redacted to a bare aggregate count; full per-record detail is written only to the local-control-plane `audit-report.md` under `wiki-local/maintenance/`. This keeps even the existence-metadata of local-only claims off the cloud-facing surface.

**Verifier-locality model.** Every `--verifier <cmd>` is treated as cloud / egress **by default**. The audit NEVER infers a verifier's locality from its command -- locality is an operator assertion via a flag, never a guess. An effective-`local_only` passage (from a page or source under `wiki-local/`) is admitted to a verifier ONLY via an explicit `--allow-local` flag (with `--local-verifier <cmd>` documented as sugar for `--verifier <cmd> --allow-local`). The script enforces this mechanically; the docs must never describe a weaker "local verifier auto-detected" behavior.

**The contradicts → marker handoff (D-10).** The audit stays strictly report-only. A human or agent MAY, as a SEPARATE explicit operation, add an `[epistemic:: tentative]` or a `[contradiction:source_a#locator vs source_b#locator]` marker (see `schema/reference/provenance.md`) to a claim with a confirmed `contradicts` verdict, then sync `has_contradictions` per `schema/workflows/lint.md`. This is **never automatic** -- the audit produces a finding; a subsequent human-approved decision promotes it to a marker.

**Checkpoint.** `wiki-local/maintenance/audit-state.md` (frontmatter `last_audit_commit`, `last_audit_at`, `last_sample_size`) mirrors `reflect-state.md`. It is control-plane (not listed in `wiki-cloud/index.md`) and advances even on a no-finding run.

## See Also

- [AGENTS.md](../../AGENTS.md) — routing-table stub (audit workflow pointer to this file).
- `schema/workflows/lint.md` — pattern-twin lint report; `has_contradictions` sync mechanics.
- `schema/reference/privacy.md` — FAITH-04 structural predicate for effective claim privacy.
- `schema/reference/provenance.md` — `[contradiction:]` and `[epistemic::]` marker syntax.

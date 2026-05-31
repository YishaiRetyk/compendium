---
phase: 13
cycle: 2
reviewers: [codex]
reviewed_at: 2026-05-31T20:13:48Z
plans_reviewed: [13-01-PLAN.md, 13-02-PLAN.md, 13-03-PLAN.md, 13-04-PLAN.md, 13-05-PLAN.md]
prior_cycle_high: 2
current_cycle_high: 2
---

# Cross-AI Plan Review — Phase 13 (Cycle 2)

> Cycle 2 re-review. Cycle 1 raised 2 HIGH concerns on the privacy boundary (verifier locality classification; `--emit-worklist` accidental egress). The plans were revised to address both. This cycle evaluates that resolution AND surfaces new HIGH concerns.

## Codex Review

## Summary

The revisions substantially improve the FAITH-04 boundary: verifier locality is now explicit-only, and `--emit-worklist` is correctly treated as passage-bearing egress. However, the privacy partition is still defined around **source privacy**, while the verifier/worklist payload includes the **wiki claim text**. That leaves a serious gap: a `privacy: local_only` wiki page citing a `cloud_safe` source can still send the local-only claim text to stdout or a verifier. I would not approve Phase 13 as fully privacy-safe until the partition uses the strictest privacy of the claim page, source summary/raw source, and path/default policy, and until generated audit reports are not marked `cloud_safe` when they can contain local-only metadata or verifier rationale.

## Cycle-1 HIGH Resolution

**HIGH-1: Verifier locality underspecified — FULLY RESOLVED at the plan level.**

Evidence:
- `13-02` explicitly pins the contract: “every `--verifier` is treated as cloud/egress by default” and local-only admission requires `--allow-local`; `--local-verifier` is sugar for `--verifier ... --allow-local`.
- `13-03` repeats the invariant more mechanically: “the partition reads ONLY `AUDIT_ALLOW_LOCAL`; the verifier command never influences whether `local_only` is admitted.”
- Acceptance criteria in `13-03` require `AUDIT_ALLOW_LOCAL`, forbid locality-from-command branches via grep, and add `test_local_verifier_alias.sh`.
- `test_local_verifier_alias.sh` is the right behavioral test: bare `--verifier` must still skip local-only, while `--local-verifier` admits it.

Residual note: `--allow-local` is necessarily an operator assertion, not proof that the command is local. That is acceptable if documented as a deliberate trust assertion.

**HIGH-2: `--emit-worklist` accidental egress — PARTIALLY RESOLVED.**

Evidence that the original worklist-passage issue is addressed:
- `13-02` now says `--emit-worklist` is “a passage-bearing egress surface exactly like the verifier subprocess” and must withhold `local_only` passages absent `--allow-local`.
- `13-02` adds `test_worklist_privacy_partition.sh`.
- `13-03` strengthens this to a single partitioned worklist consumed by both verifier dispatch and `--emit-worklist`.
- `13-03` adds `test_emit_worklist_partition.sh` and `test_privacy_partition_fail_closed.sh`.

Remaining gap:
- The plan partitions by **source privacy** only: `resolve_source_privacy(source_fm, source_path)`.
- But the worklist contains `{claim, passage, support_type, source_id, locator, line, path, privacy}`.
- A local-only wiki page claim citing a cloud-safe source would still expose the **claim text** to `--emit-worklist` or `--verifier`.
- FAITH-04 says `privacy: local_only claims NEVER sent to cloud APIs`, not only local-only source passages.

## Strengths

- The revised verifier-locality model is clear: no implicit trust based on command string.
- The single partitioned worklist design is the right architecture for preventing verifier/worklist drift.
- Negative tests using `make_recording_verifier` are well chosen for proving absence of local-only passage text.
- `shlex.split(cmd)` with `shell=False`, stdin-only payload, defensive JSON parse, and no `eval` address the prior command-injection concern.
- Locator behavior is now much better specified, especially `#p` marker semantics, `#sec` slug matching, malformed locators, and missing raw files.
- The plan preserves review-only behavior: no auto rewrites, no default CI gate, no error severity.

## Concerns

- **HIGH — NEW: Claim-page privacy is not enforced.**  
  `13-03` resolves “each claim’s SOURCE privacy” using `resolve_source_privacy(source_fm, source_path)`, but the egress payload includes the wiki `claim` text. A `privacy: local_only` page citing a `cloud_safe` source would leak the local-only claim to worklist stdout or a verifier. The effective privacy must be the strictest of claim page privacy, source summary privacy, raw source privacy if present, directory signal, and fail-closed default.

- **HIGH — NEW: `audit-report.md` is forced `privacy: cloud_safe`.**  
  `13-02` says the generated report copies lint-report frontmatter with `privacy: cloud_safe`. But findings include path/source_id/locator/rationale, skipped-private records can expose private slugs, and `--allow-local` verifier rationales may quote local-only claim or passage text. A cloud-safe label on that file creates a later egress hazard. The report should be `privacy: local_only` by default, or split into a redacted cloud-safe report and a local-only full report.

- **MEDIUM: Raw source frontmatter privacy appears ignored.**  
  The resolver signature only accepts `source_fm` from the source summary and `source_path`. The schema says source metadata, including privacy, lives in the raw source frontmatter. If raw source frontmatter says `local_only` but the summary says `cloud_safe`, strictest-wins should still block egress.

- **MEDIUM: Acceptance greps do not prove the single partition invariant.**  
  The runtime tests help, but source-order greps are weak. Add end-to-end tests asserting a distinctive local-only marker is absent from every output surface: verifier stdin log, `--emit-worklist` stdout, JSON findings, `audit-report.md`, and verification artifacts.

- **MEDIUM: `--apply-verdicts` can import unsafe rationale.**  
  The plan pins the merge key but does not specify strong validation. Verdict records should reject unknown verdicts, ignore any `passage`/`claim` fields, and treat rationale from local-only/admitted worklists as local-only report content.

- **MEDIUM: First-run “wiki-wide fallback” may conflict with the non-goal “no full-vault default.”**  
  The sample cap limits verdict volume, but the selector still appears to scan the whole wiki when no checkpoint exists. Clarify that this is metadata/claim selection only, capped, and not a full audit.

- **LOW: Plan 01 canary wording remains inconsistent.**  
  It is called a “RED canary,” but the shown script always passes and only prints INFO if `bin/audit-claims.sh` exists.

- **LOW: `test_verifier_with_args.sh` expects behavior not in the Plan 01 fake verifier.**  
  Plan 01’s `make_fake_verifier` ignores argv, while Plan 03 says the fake verifier echoes `$1`. Either update the helper or create a dedicated argv-recording verifier for that test.

## Suggestions

- Add `resolve_effective_claim_privacy(page_fm, page_path, source_fm, raw_source_fm, source_path)` and gate on that, not source privacy alone.
- Add tests for: local-only wiki page plus cloud-safe source; cloud-safe wiki page plus local-only raw source; conflicting raw/source-summary privacy; skipped-private output redaction.
- Make `audit-report.md` `privacy: local_only` by default. Only produce cloud-safe output if private metadata and verifier rationale are redacted.
- Ensure skipped-private findings do not include private slugs in cloud-facing modes unless the schema explicitly accepts metadata leakage.
- In Plan 05, avoid pasting `--emit-worklist` output from the real repo into verification unless the output is redacted or the report is local-only.

## Risk Assessment

**Overall risk: HIGH until the claim-page privacy and audit-report privacy issues are fixed.** The prior Cycle-1 verifier-locality concern is well handled, and the worklist partition is much stronger than before. But the current partition protects local-only **sources/passages**, not necessarily local-only **wiki claims**, and the generated report is labeled cloud-safe despite potentially containing local-only metadata or rationale. Those are privacy-boundary failures in the same threat class as the original HIGH findings.

---

## Consensus Summary

Single reviewer (Codex) this cycle. **Overall risk: HIGH.** The two Cycle-1 HIGH concerns are well handled at the plan level — verifier locality is now explicit-only (no command-string heuristic; admission reads only `AUDIT_ALLOW_LOCAL`), and `--emit-worklist` is correctly treated as a passage-bearing egress surface partitioned at the same boundary as the verifier subprocess (single partitioned worklist consumed by both). The MEDIUMs from Cycle 1 (out-of-enum `pending-verifier`, `shlex.split`/`shell=False`, locator edge cases, copied-from-lint manifest) are also closed.

**However, Cycle 2 surfaces two NEW HIGH concerns in the same privacy-boundary threat class** — the partition was hardened around *source* privacy but not around *page/claim* privacy or *output-artifact* privacy:

### Cycle-1 HIGH Resolution
- **HIGH-1 (verifier locality) — FULLY RESOLVED.** `13-02`/`13-03` pin "every `--verifier` is cloud/egress by default; admission reads ONLY `AUDIT_ALLOW_LOCAL`; `--local-verifier` is sugar for `--verifier … --allow-local`." Acceptance greps forbid any locality-from-command branch; `test_local_verifier_alias.sh` proves a bare `--verifier` leaves local_only as `skipped-privacy` while `--local-verifier` admits it. Residual (acceptable): `--allow-local` is an operator trust assertion, documented as such.
- **HIGH-2 (`--emit-worklist` egress) — RESOLVED for source-passage egress.** A single partitioned worklist gates BOTH `--emit-worklist` and the verifier subprocess; `test_emit_worklist_partition.sh` + `test_privacy_partition_fail_closed.sh` assert the local_only passage text reaches neither surface. The residual claim-text gap is broken out as NEW HIGH-A below (a distinct payload field, not the passage).

### Agreed / Highest-Priority Concerns (this cycle)
- **HIGH-A (NEW) — Claim-page privacy not enforced.** The partition resolves `resolve_source_privacy(source_fm, source_path)` (the *source*'s privacy), but the worklist/verifier payload includes the wiki **`claim`** text (`{claim, passage, support_type, source_id, locator, line, path, privacy}` — 13-03 line 171). A `privacy: local_only` wiki page citing a `cloud_safe` source would still egress its local-only claim text to `--emit-worklist` stdout or a cloud `--verifier`. FAITH-04 governs local_only **claims**, not only local_only source passages. The effective privacy must be the STRICTEST of {claim-page privacy, source-summary privacy, raw-source privacy, directory signal, fail-closed default}. No plan resolves page-level privacy. **Fix:** add `resolve_effective_claim_privacy(page_fm, page_path, source_fm, raw_source_fm, source_path)` and gate on that; add tests for (local-only page + cloud-safe source) and (cloud-safe page + local-only raw source).
- **HIGH-B (NEW) — `audit-report.md` forced `privacy: cloud_safe`.** `13-02` (line 202) copies lint-report frontmatter with `privacy: cloud_safe`. The report carries path/source_id/locator/rationale, `skipped-privacy` records can expose private slugs, and `--allow-local` verifier rationales may quote local-only claim/passage text. A `cloud_safe` label on that file is a downstream egress hazard. **Fix:** default the report to `privacy: local_only` (or split into a redacted cloud-safe report + a local-only full report). Also: Plan 05 should not paste un-redacted `--emit-worklist`/report output into 13-VERIFICATION.md if the report can contain local-only content.

### MEDIUM
- Raw-source frontmatter privacy appears ignored — resolver takes only the *summary* `source_fm`; if the raw source frontmatter says `local_only` but the summary says `cloud_safe`, strictest-wins should still block. (Subsumed by the HIGH-A fix.)
- Acceptance greps do not prove the single-partition invariant — add an end-to-end test asserting a distinctive local-only marker is absent from EVERY output surface (verifier stdin log, `--emit-worklist` stdout, JSON findings, `audit-report.md`, verification artifacts).
- `--apply-verdicts` lacks strong input validation — should reject unknown verdicts, ignore any `passage`/`claim` fields in the verdict file, and treat admitted-worklist rationale as local-only report content.
- First-run "wiki-wide fallback" recency selector may read as conflicting with the "no full-vault default" non-goal — clarify it is capped metadata/claim selection, not a full audit.

### LOW
- Plan 01 "RED canary" wording still slightly inconsistent (the canary always passes; only prints INFO when `bin/audit-claims.sh` exists). Cosmetic.
- `test_verifier_with_args.sh` (Plan 03) expects the fake verifier to echo `$1`, but Plan 01's `make_fake_verifier` ignores argv — either update the helper or add a dedicated argv-recording verifier.

### Divergent Views
None — single reviewer this cycle.

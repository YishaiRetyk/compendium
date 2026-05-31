---
phase: 13
cycle: 3
reviewers: [codex]
reviewed_at: 2026-05-31T23:55:00Z
plans_reviewed: [13-01-PLAN.md, 13-02-PLAN.md, 13-03-PLAN.md, 13-04-PLAN.md, 13-05-PLAN.md]
prior_cycle_high: 2
current_cycle_high: 1
---

# Cross-AI Plan Review — Phase 13 (Cycle 3, FINAL)

> Cycle 3 re-review. Cycle 1 raised 2 HIGH (verifier locality classification; `--emit-worklist` source-passage egress) — both resolved. Cycle 2 raised 2 NEW HIGH in the same privacy-boundary threat class (HIGH-A claim-page privacy not enforced; HIGH-B `audit-report.md` forced `cloud_safe`). This cycle confirms BOTH Cycle-2 HIGHs are now FULLY RESOLVED, and surfaces ONE genuinely-new HIGH (HIGH-C) in the same threat class: `skipped-privacy` finding metadata (`source_id`/`path`/`locator`) still egresses to the cloud-facing `--emit-worklist` stdout for withheld local-only claims.

## Codex Review

### Summary

The two named Cycle-2 HIGH concerns are resolved at the plan level for their stated failure modes: Phase 13 now gates claim text/passage on EFFECTIVE claim privacy (strictest of claim-page / source-summary / raw-source / dir / fail-closed default), and generated audit artifacts (`audit-report.md`, `audit-state.md`) are no longer mislabeled `cloud_safe`. However, one genuinely-new HIGH privacy gap remains: the plans still emit unredacted `skipped-privacy` metadata — `source_id`, `path`, and `locator` — to cloud-facing `--emit-worklist` stdout for withheld local-only claims, even though the plans' OWN threat register (T-13-21) acknowledges those fields can expose private slugs. **Phase 13 is NOT ready to execute until that metadata egress path is closed.**

### Cycle-2 HIGH Resolution

**HIGH-A — Claim-page privacy not enforced: FULLY RESOLVED.**

Evidence:
- `13-03` adds `bin/lib/privacy_resolve.py::resolve_effective_claim_privacy(page_fm, page_path, source_fm, raw_source_fm, source_path)`, folding the strictest of {claim-page privacy, source-summary privacy, raw-source privacy, dir signal, fail-closed default}; any `local_only` input → `local_only`.
- `13-03` explicitly gates the audit partition on `resolve_effective_claim_privacy`, NOT `resolve_source_privacy` alone (truth line 29; Task-1 step 4; acceptance grep at line 190 requires the call site to pass `page_fm`/`page_path` + raw-source frontmatter).
- The partition is a SINGLE point placed BEFORE both `--emit-worklist` and verifier dispatch (truth line 30; Task-1 step 4).
- Tests added: `test_claim_page_privacy.sh` (local-only page + cloud-safe source → withheld claim text AND passage), `test_raw_source_privacy.sh` (cloud-safe page/summary + local-only raw source → withheld), `test_emit_worklist_partition.sh`, and claim (c) in the load-bearing `test_privacy_partition_fail_closed.sh` (recording cloud verifier's sentinel log must never contain the local-only PAGE's claim-text marker NOR passage marker).
- STRIDE threat `T-13-19` (13-03) directly covers the local-only wiki page citing a cloud-safe source case.

This resolves the original HIGH-A failure mode: local-only page CLAIM text/passage no longer reaches either cloud-verifier stdin or worklist passage payload absent `--allow-local`.

**HIGH-B — `audit-report.md` forced `privacy: cloud_safe`: FULLY RESOLVED.**

Evidence:
- `13-02` requires BOTH generated `wiki/maintenance/audit-report.md` AND `audit-state.md` stamped `privacy: local_only` (truth line 42; Task-2 steps 3-4); `test_report_privacy_local_only.sh` asserts it against the GENERATED files (not just script source).
- `13-02` acceptance forbids `privacy: cloud_safe` anywhere the audit writes its own artifacts (line 221).
- STRIDE threat `T-13-21` (13-02) explicitly covers private slugs / path / source_id / locator / rationale in the report/checkpoint artifacts.
- `13-05` restricts the committed `13-VERIFICATION.md` (on `main`, not `local_only`-labeled) to REDACTION-SAFE counts/paths evidence; pastes NO `--emit-worklist` body, NO `--verifier` rationale; requires the `grep 'privacy:' wiki/maintenance/audit-report.md` → `local_only` label-proof line. STRIDE threat `T-13-22` covers this.

This closes the cloud-labeled / committed-artifact concern at the plan level.

### New Concerns

**HIGH-C (NEW) — `skipped-privacy` finding metadata still egresses via cloud-facing `--emit-worklist` stdout.**

The plans correctly withhold local-only CLAIM TEXT and PASSAGE from the worklist, but they still emit unredacted finding METADATA for the withheld local-only claim onto the same cloud-facing surface.

Concrete evidence:
- `13-03` Task-1 step 4 (line 173): a local-only-effective claim is "WITHHELD from that worklist and immediately emitted as a `skipped-privacy` finding (carrying its `source_id` and `path`)."
- `13-02` defines the 9-key finding shape (line 114) as including `path`, `line`, `source_id`, and `locator`.
- `13-02` threat `T-13-21` already acknowledges `path/source_id/locator/rationale` can expose **private slugs** — the audit-report.md mitigation is to label that file `local_only`. But `--emit-worklist` stdout is a DIFFERENT surface (an explicit cloud egress, by the plans' own framing) and is NOT a labeled file — it goes to a cloud operating agent's stdout.
- `13-03` `test_emit_worklist_partition.sh` (line 177) and `test_claim_page_privacy.sh` (line 180) REQUIRE the worklist to "carry a `skipped-privacy` record for the local source" — i.e., the tests pin the metadata leak as expected behavior. The negative assertions only cover claim/passage MARKER TEXT, never the `path`/`source_id`/`locator` metadata.

Net effect: a `privacy: local_only` page's slug (its `path`, e.g. `wiki/concepts/<private-slug>.md`) and `source_id` reach the cloud-facing `--emit-worklist` stdout, even though FAITH-04 + §13 fail-closed semantics treat that page as content that must never cross to a cloud API. This is the same threat class as Cycle-1 HIGH-2 and Cycle-2 HIGH-A/B — a narrower residual (metadata, not claim text) on a surface the partition was hardened for, but real.

Required plan-level fix (small, well-scoped):
- For cloud-facing stdout/worklist modes WITHOUT `--allow-local`, local-only `skipped-privacy` records must be REDACTED or AGGREGATED — do NOT emit local-only `source_id`, `path`, `line`, `locator`, page title, claim/passage text, or rationale to stdout. A bare count (e.g. `{"verdict":"skipped-privacy","count":N}` or a single aggregate record) is sufficient to keep the honest-counts contract (D-09 `selected=N skipped=M`).
- Detailed per-claim `skipped-privacy` findings can remain in `audit-report.md` because that file is now `privacy: local_only`.
- Adjust `test_emit_worklist_partition.sh` / `test_claim_page_privacy.sh` so the WITHOUT-`--allow-local` assertion proves ABSENCE of the local-only `path`/`source_id`/`locator` metadata from worklist stdout, not only absence of claim/passage marker text.

**MEDIUM — `13-04` audit docs should say "effective claim privacy," not "source privacy."**

`13-04` (AGENTS.md §6 / Audit-workflow docs) still describes the audit in terms of source privacy in places. Since AGENTS.md is the authoritative spec, the doc must mirror the actual implementation contract: the partition gates on the EFFECTIVE claim privacy = strictest of {claim-page, source-summary, raw-source, dir signal, fail-closed default}. (Doc/impl drift, not an egress bug.)

### Risk Assessment

**Overall risk: HIGH**, due to one remaining privacy egress path — local-only finding metadata (`path`/`source_id`/`locator`) on cloud-facing `--emit-worklist` stdout. The HIGH-A/HIGH-B fixes are structurally sound and well-tested; the skipped-record metadata redaction is a narrow, isolated fix (one emission site + two test assertions).

**Final unresolved HIGH count: 1.**

---

## Consensus Summary

Single reviewer (Codex) this cycle. **Overall risk: HIGH** — but materially closer to done than Cycle 2. Both Cycle-2 HIGHs are now FULLY RESOLVED with concrete plan truths, tests, and STRIDE threats:
- **HIGH-A (claim-page privacy) — FULLY RESOLVED:** `resolve_effective_claim_privacy` folds claim-page + source-summary + raw-source + dir + default (strictest-wins); the single partition gates on it; `test_claim_page_privacy.sh` + `test_raw_source_privacy.sh` + claim (c) of `test_privacy_partition_fail_closed.sh` prove a local-only PAGE's claim/passage never reaches a cloud verifier or worklist. T-13-19 added.
- **HIGH-B (`cloud_safe` artifact label) — FULLY RESOLVED:** generated `audit-report.md` + `audit-state.md` default to `privacy: local_only` (`test_report_privacy_local_only.sh`, T-13-21); committed `13-VERIFICATION.md` restricted to redaction-safe counts/paths (T-13-22).

### Agreed / Highest-Priority Concern (this cycle)
- **HIGH-C (NEW) — `skipped-privacy` metadata egress on `--emit-worklist` stdout.** The partition withholds local-only claim TEXT/PASSAGE but still emits the withheld claim's `source_id`/`path`/`locator` (a private slug, per the plans' own T-13-21) to the cloud-facing worklist stdout. `13-03` line 173 pins "carrying its `source_id` and `path`"; the worklist/claim-page tests require a `skipped-privacy` record on stdout and only negative-assert claim/passage marker text, not the metadata. **Fix:** redact/aggregate local-only `skipped-privacy` records on stdout/worklist surfaces absent `--allow-local` (a bare count suffices; full detail stays in the `local_only`-labeled `audit-report.md`); extend the two egress tests to assert absence of the `path`/`source_id`/`locator` metadata, not just the text markers.

### MEDIUM
- `13-04` audit docs should describe the gate as "effective claim privacy" (strictest of page/summary/raw/dir/default), not "source privacy" — AGENTS.md is the authoritative spec and must mirror the 13-03 implementation contract.

### Divergent Views
None — single reviewer this cycle.

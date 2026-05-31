---
phase: 13
slug: claim-faithfulness-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `13-RESEARCH.md` § Validation Architecture (22-row req→test map, fake-verifier insight).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash test scripts + per-phase aggregator (project convention — NO pytest/jest) |
| **Config file** | none — `tests/phase-13/run.sh` iterates `test_*.sh` (copy `tests/phase-12.2/run.sh`) |
| **Quick run command** | `bash tests/phase-13/run.sh` |
| **Full suite command** | `bash tests/phase-13/run.sh` (single aggregator; no `--full` split) |
| **Estimated runtime** | ~15–30 seconds (all deterministic; fake verifier, no model calls) |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/phase-13/run.sh` (fast — fully deterministic via fake verifier)
- **After every plan wave:** Run `bash tests/phase-13/run.sh` + `bash bin/lint.sh --category yaml` over new control-plane files
- **Before `/gsd-verify-work`:** Full suite green; `bash bin/requirements-sync.sh --strict --phase 13` exit 0; `--require-complete --phase 13` exit 0 after `13-VERIFICATION.md` lands
- **Max feedback latency:** ~30 seconds

**Load-bearing testability insight:** the verdict step is non-deterministic (LLM), but *everything else is deterministic and must be tested without invoking any model*. A **fake/stub `--verifier`** (reads the D-01 contract on stdin, echoes a canned `{verdict, rationale, sub_claims}`) makes the full pipeline reproducible end-to-end. A **recording `--verifier`** (appends every passage it receives to a sentinel log) proves the fail-closed privacy partition by *negative assertion* — the sentinel never contains a `local_only` source's text.

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| FAITH-01 | recency selector picks git-diff-changed claims | unit | `bash tests/phase-13/test_select_recency.sh` | ❌ W0 |
| FAITH-01 | inferred/tentative epistemic selector | unit | `bash tests/phase-13/test_select_epistemic.sh` | ❌ W0 |
| FAITH-01 | stale-source selector (hash mismatch) | unit | `bash tests/phase-13/test_select_stale_source.sh` | ❌ W0 |
| FAITH-01 | high-fanout selector (inbound-link count) | unit | `bash tests/phase-13/test_select_high_fanout.sh` | ❌ W0 |
| FAITH-01 | priority-rank order + cap-20 + `selected/skipped` log (D-09, no silent caps) | unit | `bash tests/phase-13/test_sampling_cap_logging.sh` | ❌ W0 |
| FAITH-02 | `#sec:` slices heading→next-heading from RAW file (not summary) | unit | `bash tests/phase-13/test_resolve_sec.sh` | ❌ W0 |
| FAITH-02 | `#para` n-th paragraph | unit | `bash tests/phase-13/test_resolve_para.sh` | ❌ W0 |
| FAITH-02 | `#p8` with `<!-- page: N -->` markers → bounded passage (D-05) | unit | `bash tests/phase-13/test_resolve_p_marked.sh` | ❌ W0 |
| FAITH-02 | `#p8` UNMARKED source → `insufficient-locator` (D-06) | unit | `bash tests/phase-13/test_resolve_p_unmarked.sh` | ❌ W0 |
| FAITH-02 | `#img` → `skipped-nontext` | unit | `bash tests/phase-13/test_resolve_img.sh` | ❌ W0 |
| FAITH-02 | raw-source-missing → graceful degrade (no crash) | unit | `bash tests/phase-13/test_resolve_missing_raw.sh` | ❌ W0 |
| FAITH-02 | D-11: resolver reads `path:` raw file, never summary `## Extracted Claims` | unit | `bash tests/phase-13/test_no_circular_verify.sh` | ❌ W0 |
| FAITH-02 | each verdict path via fake verifier: supports/weak/contradicts/insufficient | unit | `bash tests/phase-13/test_verdict_paths.sh` | ❌ W0 |
| FAITH-03 | output carries all 6 fields (path,line,source_id,locator,verdict,rationale) | unit | `bash tests/phase-13/test_output_schema.sh` | ❌ W0 |
| FAITH-03 | JSON output is lint-superset (4 shared keys present — SC-6) | unit | `bash tests/phase-13/test_json_lint_compat.sh` | ❌ W0 |
| FAITH-03 | NO wiki page mutated after a run (SC-5) | unit | `bash tests/phase-13/test_no_page_mutation.sh` | ❌ W0 |
| FAITH-04 | **fail-closed partition**: cloud verifier MECHANICALLY never receives `local_only` passage (D-02) | unit (load-bearing) | `bash tests/phase-13/test_privacy_partition_fail_closed.sh` | ❌ W0 |
| FAITH-04 | `local_only` + no local verifier → `skipped-privacy` finding (D-03) | unit | `bash tests/phase-13/test_skipped_privacy.sh` | ❌ W0 |
| FAITH-04 | §13 resolution: frontmatter / dir-default / system-default + stricter-wins | unit | `bash tests/phase-13/test_privacy_resolve_precedence.sh` | ❌ W0 |
| FAITH-04 | `--allow-local` / local `--verifier` opt-in admits `local_only` to worklist | unit | `bash tests/phase-13/test_allow_local_optin.sh` | ❌ W0 |
| D-01 | `--verifier <cmd>` contract: stdin `{claim,passage,support_type}` → stdout `{verdict,rationale,sub_claims}` | unit | `bash tests/phase-13/test_verifier_contract.sh` | ❌ W0 |
| D-15 | checkpoint `audit-state.md` advances even on a no-finding run | unit | `bash tests/phase-13/test_checkpoint_advance.sh` | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — all rows ⬜ pending until Wave 0 lands the harness.*

---

## Wave 0 Requirements

- [ ] `tests/phase-13/run.sh` — aggregator (copy `tests/phase-12.2/run.sh`)
- [ ] `tests/phase-13/lib.sh` — copy `make_bare_repo` / `write_page` / `assert_exit_code` / `cleanup_fixture_repo` from `tests/phase-12.2/lib.sh`; ADD `make_fake_verifier` (canned verdict) + `make_recording_verifier` (sentinel-log passages)
- [ ] `tests/phase-13/fixtures/` — **self-contained** page+source+raw-file fixtures: each writes BOTH the `wiki/sources/<id>.md` summary (with `path:` + `content_hash` + `compiled_against_hash`) AND the raw file at that `path:`, with real `## headings` / blank-line paragraphs / `<!-- page: N -->` markers (marked + unmarked + cloud_safe + local_only + img + missing-raw)
- [ ] No framework install needed — bash is the framework (project convention, verified phases 07–12.2)

*Fixture realism: `examples/kahneman/` source summaries point at raw `path:` files NOT on disk; every current `wiki/sources/*.md` is `local_only`. Fixtures MUST be self-contained; the D-03 local-heavy default is the real production state.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Agent-in-the-loop verdict quality (does an LLM judge entailment correctly) | FAITH-02 | The verdict step is the one non-deterministic, judgment-bearing operation; ragas validates the algorithm but per-run output varies (Pitfall 5). Tested deterministically via fake verifier for *pipeline* correctness; *verdict accuracy* is reviewed by a human against `audit-report.md` on a real sample. | Run `bash bin/audit-claims.sh --sample 5` against the live `cloud_safe` subset; read `wiki/maintenance/audit-report.md`; spot-check 2–3 verdicts against the cited raw passages. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (harness + fixtures + fake/recording verifiers)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

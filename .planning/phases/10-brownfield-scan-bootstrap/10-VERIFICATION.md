# Phase 10 Verification — Brownfield Scan + Bootstrap

**Completed:** <filled at execute-phase close>
**Plans:** 5 plans (10-01 harness, 10-02 scan, 10-03 bootstrap, 10-04 schema/lint/ingest wiring, 10-05 docs + VERIFICATION)

## Requirements Evidence

| REQ-ID  | Truth | Evidence |
|---------|-------|----------|
| BRWN-01 | `bin/brownfield.sh scan` writes `.brownfield/REPORT.md` with inventory, confidence labels, and signal traces without mutating vault content | `tests/phase-10/test_brownfield_scan_report.sh` (proves report written + no-mutation SHA-256 snapshot); `tests/phase-10/test_brownfield_scan_confidence.sh` |
| BRWN-02 | `scan` REPORT.md lists unclassifiable pages under "Needs human judgment" with prose open-questions | `tests/phase-10/test_brownfield_scan_unknown.sh` |
| BRWN-03 | `bootstrap --apply` is idempotent — two runs produce zero-byte diff | `tests/phase-10/test_brownfield_bootstrap_idempotent.sh` |
| BRWN-04 | `bootstrap` touches only mechanical transforms (sentinel frontmatter, SHA hashing, skeleton files, YAML normalization) | `tests/phase-10/test_brownfield_bootstrap_apply_clean.sh`; `tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh`; `tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh`; `tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh`; `tests/phase-10/test_brownfield_bootstrap_apply_comments.sh` (5 parseable fixture tests verify byte-equality of outputs); `docs/reference/brownfield.md` §"What bootstrap writes" documents the transform set |
| BRWN-05 | `bootstrap` preserves page bodies verbatim | Body-preservation assertion inside each `test_brownfield_bootstrap_apply_*.sh` (extracts post-`---` body bytes, asserts equality with original) |
| BRWN-06 | `bootstrap` uses ruamel.yaml round-trip preserving comments + key order | `tests/phase-10/test_brownfield_bootstrap_apply_comments.sh` (byte-equality on frontmatter-with-comments fixture); `bin/lib/brownfield_yaml.py` imports `ruamel.yaml.YAML(typ='rt')` |
| BRWN-07 | `bootstrap_stage` enum (`raw | bootstrapped | verified`) documented in AGENTS.md §5 as narrowly-scoped brownfield onboarding sentinel, NOT a substitute for claim-level provenance | `tests/phase-10/test_agents_section_5_bootstrap_stage.sh`; `tests/phase-10/test_agents_template_parity_section_5.sh`; `tests/phase-10/test_claude_sync_byte_equal.sh` |
| BRWN-08 | `bin/lint.sh --ci` downgrades allowlist findings from error to info when `bootstrap_stage: bootstrapped` (scope: `--ci` mode only per I-1) | `tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh` (asserts severity=info under --ci); `tests/phase-10/test_lint_ci_no_downgrade_when_absent.sh` (asserts no false-positive downgrade); `docs/reference/brownfield.md` §"Interaction with lint and ingest" documents the --ci-only scope |
| BRWN-09 | `bin/lint.sh` new `brownfield` category reports bootstrapped-page counts + warns on pages bootstrapped > 30 days ago | `tests/phase-10/test_lint_brownfield_category_help.sh`; `tests/phase-10/test_lint_brownfield_stale_30d.sh` |
| BRWN-10 | `bin/ingest.sh` strips `bootstrap_stage` + `bootstrap_date` on normal ingest with D-21 verbatim stderr warning (emitted as a single line per W-6) | `tests/phase-10/test_ingest_strip_bootstrap_stage.sh` (includes W-6 combined-line grep asserting single-line emission); `tests/phase-10/test_ingest_strip_no_warn_when_absent.sh` |
| BRWN-21 | Byte-exact fixture tests prove `bootstrap` produces identical output on sample vaults across runs (dual golden contract: transformed-output + skip-artifact per D-07) | 5 parseable fixture byte-equality tests (`tests/phase-10/test_brownfield_bootstrap_apply_clean.sh`, `_no_fm.sh`, `_crlf.sh`, `_dataview.sh`, `_comments.sh`); 2 unparseable fixture skip-artifact tests (`tests/phase-10/test_brownfield_bootstrap_skip_tabs.sh`, `_dupkeys.sh`); idempotency test (`tests/phase-10/test_brownfield_bootstrap_idempotent.sh`) |

## Deferred to Phase 11

- AGENTS.md §11.5 Brownfield Workflow full populate (D-22 reserves the slot; Phase 10 stubs only)
- suggest subcommand (BRWN-11..14)
- verify subcommand (BRWN-17)
- Migration scripts 01-page-typing.sh through 04-privacy-classification.sh (BRWN-12..15)

## Deferred to Phase 12

- Obsidian render verification of a bootstrapped vault (DEBT-01)
- Codex agent-parity run (DEBT-02)

## Deferred to v1.2

- `bin/brownfield.sh apply` single-command chain-runner (BRWNAPPLY-01)
- Content-hash sentinel (research C-3 prevention #3; intentionally rejected for v1.1 per D-12)

## Test Aggregator

All phase-10 tests under `tests/phase-10/run.sh`. Target: 100% pass across all wired tests (aggregator output matches the regex `PHASE 10 TESTS: ([0-9]+)/\1$` — i.e., `X/X` for any X, proving all wired tests pass regardless of the exact count as plans grow or shrink the roster). Approximate roster target as of Phase 10 landing: ~32 tests (2 Plan 01 + 6 Plan 02 + 12 Plan 03 + 9 Plan 04 + 3 Plan 05).

## Known limitations

- **Scan classification is heuristic:** The 4-signal rule set (D-16) uses filename conventions, frontmatter, heading structure, and outbound link density. It cannot distinguish every page type correctly — `unknown` is the honest output when signals conflict or are absent. Phase 11's `01-page-typing.sh` adds inbound-link context for higher accuracy.
- **Bootstrap does not infer provenance, privacy, or page type:** These are judgment calls that belong in Phase 11's suggest/verify workflow. Bootstrap only writes mechanical sentinel frontmatter.
- **Lint downgrade is CI-only:** The BRWN-08 error->info downgrade for bootstrapped pages fires in `bin/lint.sh --ci` mode only (I-1 scope). Local `bin/lint.sh` runs show full-severity findings on bootstrapped pages. Use `--ci` locally to mirror CI behavior.

## See also

- `.planning/REQUIREMENTS.md` §BRWN (Phase 10 + Phase 11 full REQ set)
- `.planning/ROADMAP.md` §Phase 10 (goal + success criteria 1-5)
- `docs/reference/brownfield.md` (user-facing runbook)

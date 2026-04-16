---
phase: 08-two-track-setup-wizard-manual
verified: 2026-04-16T10:00:00Z
status: passed
score: 5/5 success-criteria verified
re_verification: false
requirements:
  satisfied:
    - WZRD-01
    - WZRD-02
    - WZRD-03
    - WZRD-04
    - WZRD-05
    - WZRD-06
    - WZRD-07
    - WZRD-08
    - WZRD-09
    - WZRD-10
    - WZRD-11
    - MANUAL-01
    - MANUAL-02
    - MANUAL-03
    - MANUAL-04
    - MANUAL-05
    - MANUAL-06
  orphaned: []
  blocked: []
  needs_human: []
---

# Phase 8: Two-Track Setup Wizard + Manual Verification Report

**Phase Goal:** Two-track setup wizard (interactive `bin/init-wizard.sh`) + manual-setup docs, with CI byte-equality gate ensuring both paths produce identical AGENTS.md output.

**Verified:** 2026-04-16
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User runs `bin/init-wizard.sh`, answers 6 semantically-grouped prompts, wizard writes personalized `AGENTS.md`, `.wizard-answers.yaml`, and an initial decision record; prints diff summary of every file written | VERIFIED | Wizard exists at `bin/init-wizard.sh` (1140 lines, executable). Running against canonical answers via `--render-to` produces exactly 5 artifacts: `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/dr-2026-04-16-initial-setup.md`, `wiki/index.md` (Decisions subsection appended). Accidental real-run against the actual repo confirmed all 5 files written with size summary: `102562 bytes, new` for AGENTS.md, etc. D-13 semantic-group explainers verified by `test_wizard_semantic_groups.sh`: "all 5 D-13 explainer lines appear in interactive output". |
| 2 | User runs `bin/init-wizard.sh --dry-run` and sees the full rendered diff without any file mutation; re-running the wizard on an already-initialized repo is idempotent | VERIFIED | `--dry-run` emits unified-diff output (head: `--- a/AGENTS.md / +++ b/AGENTS.md @@ -28,6 +28,8 @@` with the `This file (CLAUDE.md)` insertion). Idempotency verified by `test_wizard_idempotent.sh`: "real run refused with exit 4 + D-04 message; --dry-run bypasses (D-06)". |
| 3 | User runs `bin/init-wizard.sh --answers-file canonical.yaml` in CI (non-interactive) and produces an `AGENTS.md` byte-equal to manual-setup.md's end state — enforced by CI | VERIFIED | Local byte-equality check PASSED: `cmp -s $WORK/AGENTS.md schema/fixtures/canonical-AGENTS.md → BYTE-EQUAL`. `CLAUDE.md` also byte-equal. CI workflow `.github/workflows/setup-parity.yml` runs aggregator on PR + push, includes `test_canonical_byte_equality.sh`. `PHASE 08 TESTS: 21/21` green. |
| 4 | User who prefers the hand-edit path follows `docs/manual-setup.md` section-by-section, using a one-to-one wizard-prompt checklist and a concrete minimal-diff example, and lands in the same configured state | VERIFIED | `docs/manual-setup.md` (286 lines) has all required sections: Pre-step (cp template to AGENTS.md), Sections 1–6 (6 prompts with minimal diffs), Section 7 (.wizard-answers.yaml heredoc), Section 8a (inline decision-record template), Section 8b (inline index.md append snippet), Section 9 (sync-claude), Section 10 (wizard-prompt checklist 6 items), Section 11 (equivalence statement), Section 12 (file-touch list 5 files), Section 13 (pointers). Minimal-diff example uses neutral `personal-knowledge` domain (D-10). Equivalence statement: "wizard track and the manual track produce a byte-identical end state". |
| 5 | Wizard pre-flight detects missing `git`/`bash >= 4` and prints actionable remediation message before touching anything; invalid input (bad domain slug, unknown agent, unknown privacy tier) is rejected with a clear error | VERIFIED | `test_wizard_preflight.sh`: "pre-flight failure returns exit 3 with clear message + docs pointer". `test_wizard_validation.sh`: "all 3 bad --answers-file cases fail with exit 5 + D-17 error shape". Usage text shows exit codes 3 (pre-flight), 5 (validation). `docs/reference/setup-prerequisites.md` covers macOS/Debian/Arch/Fedora/WSL. |

**Score:** 5/5 success criteria verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/init-wizard.sh` | Wizard with pre-flight, validator, render, --dry-run, --render-to, --answers-file, idempotency guard, 5-artifact atomic write | VERIFIED | 1140 lines, executable (`rwxrwxr-x`). `--help` surfaces all 4 flags, 6 exit codes, 3 env vars. Contains `schema/AGENTS.template.md`, `update_index_md()`, staging-dir pattern, `bash "$SCRIPT_DIR/sync-claude.sh"` invocation (6 refs). |
| `schema/fixtures/canonical-answers.yaml` | Canonical YAML answer set (6 answers + metadata) | VERIFIED | 16 lines, all 6 required keys present: maintainer_name, primary_domain, agent, default_privacy, decay_profile, obsidian. `default_privacy: "cloud_safe"` per Open Q2 resolution. |
| `schema/fixtures/canonical-AGENTS.md` | Byte-frozen expected wizard render (0 leftover {{...}} tokens) | VERIFIED | 1723 lines. `grep -c '{{[A-Z_]*}}' = 0` (no leftover placeholders). Line 32: `This file (CLAUDE.md) is the canonical agent spec`. Line 588: `knowledge_domain: "personal-knowledge"`. Line 589: `privacy_default: cloud_safe`. Line 848: `The default staleness decay profile is default`. |
| `schema/fixtures/README.md` | Documents cloud_safe-vs-local_only rationale + regeneration rule | VERIFIED | 2682 bytes, contains literal tokens `cloud_safe`, `local_only`, `Regeneration Rule`, `release.sh` (privacy-leak regex rationale). |
| `docs/manual-setup.md` | D-07 layout: copy-template-first pre-step + 6 prompt sections + inline decision-record + inline index.md + checklist + equivalence + file list | VERIFIED | 286 lines. Pre-step has `cp schema/AGENTS.template.md AGENTS.md` + sed pipeline. 6 prompt sections with minimal diffs. Section 8a inline decision-record heredoc (11 placeholder values). Section 8b inline index.md snippet matching `update_index_md()` format. Section 10 checklist (6 items), Section 11 equivalence, Section 12 file-touch list (5 files). |
| `docs/guided-setup.md` | Wizard walkthrough (invocation, prompts, output) | VERIFIED | 38 lines, describes 6 prompts, 3 modes, 5 files written, re-run/upgrade posture, prerequisites pointer. |
| `docs/quickstart.md` | Populated quickstart with wizard step + first-source-ingest pointer | VERIFIED | 41 lines, 4 numbered steps from clone → ingest → Obsidian, links to setup-prerequisites, guided-setup, manual-setup. |
| `docs/reference/setup-prerequisites.md` | bash/git/python3 install instructions across 5 platforms | VERIFIED | 55 lines, covers macOS/Debian-Ubuntu-WSL/Arch/Fedora-RHEL/Windows, verify section, references wizard pre-flight. |
| `.github/workflows/setup-parity.yml` | CI byte-equality gate on PR + push, aggregator-only invocation, determinism env vars | VERIFIED | 57 lines. `on: pull_request + push:branches:[main]`. `runs-on: ubuntu-latest`. Env: `WIZARD_GENERATED_AT=2026-04-16T00:00:00Z` + `WIZARD_TEMPLATE_SHA=<frozen-fixture>`. Steps: checkout@v6, setup-python@v6 (3.12), pip install pyyaml, phase-08 aggregator, phase-07 aggregator, check-neutrality. |
| `tests/phase-08/` aggregator | 21/21 tests passing | VERIFIED | Run produced `PHASE 08 TESTS: 21/21` with all individual tests PASS. File count: 1 lib, 1 run, 21 test_*.sh. |
| `.gitattributes` EOL pin | LF pin for fixtures | VERIFIED | Lines 5–7 pin `canonical-AGENTS.md`, `canonical-answers.yaml`, `README.md` to `text eol=lf`. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `bin/init-wizard.sh` | `schema/AGENTS.template.md` | python3 str.replace on 4 tokens | WIRED | Wizard reads template and substitutes `{{AGENT_FILENAME}}`, `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{DECAY_PROFILE}}`. Verified: render output has 0 leftover `{{...}}` tokens. |
| `bin/init-wizard.sh` | `bin/sync-claude.sh` | bash invocation after AGENTS.md promoted | WIRED | 6 refs in wizard source; line 1084: `(cd "$REPO_ROOT" && bash "$SCRIPT_DIR/sync-claude.sh" ...)`. Verified: wizard output has `AGENTS.md == CLAUDE.md BYTE-EQUAL`. |
| `bin/init-wizard.sh` | `schema/fixtures/canonical-AGENTS.md` | --render-to + cmp -s against fixture | WIRED | Local `cmp -s` PASS. Enforced in CI via `test_canonical_byte_equality.sh` running inside `.github/workflows/setup-parity.yml`. |
| `bin/init-wizard.sh` | `wiki/decisions/dr-<TODAY>-initial-setup.md` | deterministic template substitution into 7 sections | WIRED | File written at deterministic path with frontmatter `trigger_type: schema-update`, `type: decision`, 7 required sections. Verified by `test_wizard_decision_record.sh`. |
| `bin/init-wizard.sh` | `wiki/index.md` | `update_index_md()` helper with idempotency + duplicate-header guard | WIRED | 3-guardrail contract verified by `test_wizard_index_md.sh`: happy path, idempotency (re-render no-op), duplicate-header guard (2 headings → error). |
| `docs/manual-setup.md` | `AGENTS.md` | copy-from-template step (NOT edit-in-place) | WIRED | Line 12: `cp schema/AGENTS.template.md AGENTS.md`. Line 28: "Either way, schema/AGENTS.template.md stays pristine". `test_manual_setup_copy_not_edit.sh` verifies this structural commitment. |
| `docs/manual-setup.md` | `schema/fixtures/canonical-AGENTS.md` | minimal-diff example produces this exact end state | WIRED | Section 11 equivalence statement: "rendered AGENTS.md is byte-equal to `schema/fixtures/canonical-AGENTS.md`". |
| `.github/workflows/setup-parity.yml` | `tests/phase-08/run.sh` | workflow invokes aggregator | WIRED | Line 52: `run: bash tests/phase-08/run.sh`. Aggregator glob picks up `test_canonical_byte_equality.sh` (no duplicate invocation per review #7). |

### Data-Flow Trace (Level 4)

Data-flow trace not applicable — phase produces CLI/docs/CI artifacts, no dynamic-rendered components. The rendering data-flow (canonical-answers.yaml → wizard → canonical-AGENTS.md) is already verified by the byte-equality assertion.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase-08 test aggregator passes | `bash tests/phase-08/run.sh` | `PHASE 08 TESTS: 21/21` | PASS |
| Phase-07 regression still passes | `bash tests/phase-07/run.sh` | `PHASE 07 TESTS: 22/22` | PASS |
| Wizard --help prints usage with 4 flags | `bash bin/init-wizard.sh --help` | Prints 4 flags, 6 exit codes, 3 env vars, pointers to setup-prerequisites.md + manual-setup.md | PASS |
| Wizard --render-to produces byte-equal AGENTS.md | `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to $WORK` + `cmp -s` | Exit 0; `BYTE-EQUAL` vs fixture | PASS |
| AGENTS.md and CLAUDE.md byte-equal after wizard | `cmp -s $WORK/AGENTS.md $WORK/CLAUDE.md` | `BYTE-EQUAL` | PASS |
| All 5 artifacts written in --render-to mode | `find $WORK -type f` | AGENTS.md, CLAUDE.md, .wizard-answers.yaml, wiki/decisions/dr-2026-04-16-initial-setup.md, wiki/index.md | PASS |
| Wizard --dry-run produces unified diff without mutation | `bash bin/init-wizard.sh --dry-run --answers-file schema/fixtures/canonical-answers.yaml` | Unified diff with `--- a/AGENTS.md / +++ b/AGENTS.md` headers | PASS |
| Canonical fixture has zero leftover placeholders | `grep -c '{{[A-Z_]*}}' schema/fixtures/canonical-AGENTS.md` | `0` | PASS |
| setup-parity.yml is valid YAML | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/setup-parity.yml'))"` | Exit 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| WZRD-01 | 08-01, 08-02 | `bin/init-wizard.sh` exists, bash-only, no new runtime deps | SATISFIED | 1140-line bash script; dependency is bash + python3 stdlib + optional PyYAML (already present in project). |
| WZRD-02 | 08-02 | Wizard prompts semantically grouped with one-sentence explainers | SATISFIED | `test_wizard_semantic_groups.sh` PASS — "all 5 D-13 explainer lines appear in interactive output". |
| WZRD-03 | 08-03 | Non-interactive mode via `--answers-file <path>` | SATISFIED | Flag parsed at wizard lines 116–124; used throughout CI test. `test_wizard_answers_yaml.sh` PASS. |
| WZRD-04 | 08-02 | Validates input: slug regex, agent enum, privacy enum | SATISFIED | `test_wizard_validation.sh`: "all 3 bad --answers-file cases fail with exit 5 + D-17 error shape". |
| WZRD-05 | 08-02 | Idempotent re-run (no-op or clear refusal) | SATISFIED | `test_wizard_idempotent.sh`: "real run refused with exit 4 + D-04 message; --dry-run bypasses (D-06)". |
| WZRD-06 | 08-03 | `.wizard-answers.yaml` recording the inputs | SATISFIED | `test_wizard_answers_yaml.sh` PASS. Confirmed: `$WORK/.wizard-answers.yaml` exists with 6 expected keys. |
| WZRD-07 | 08-01, 08-02, 08-04 | Renders from template with exactly 4 placeholders (D-02 amendment) | SATISFIED | REQUIREMENTS.md line 46 amended to "exactly 4 named placeholders: {{PRIMARY_DOMAIN}}, {{DEFAULT_PRIVACY}}, {{AGENT_FILENAME}}, {{DECAY_PROFILE}}". Confirmed: rendered fixture has 0 leftover `{{...}}` tokens. |
| WZRD-08 | 08-02 | Prints file list + summary diff on completion | SATISFIED | `test_wizard_summary.sh`: "--render-to emits 'Wrote' summary block with file path + byte count". Confirmed: real-run output shows `Wrote (real-run mode):` followed by 5 file lines with bytes + status. |
| WZRD-09 | 08-02 | Pre-flight check for git, bash >= 4 with actionable message | SATISFIED | `test_wizard_preflight.sh`: "pre-flight failure returns exit 3 with clear message + docs pointer". |
| WZRD-10 | 08-03 | Writes initial decision record per DCSN-01 | SATISFIED | `test_wizard_decision_record.sh` PASS. Confirmed: `$WORK/wiki/decisions/dr-2026-04-16-initial-setup.md` exists with `trigger_type: schema-update`, 7 required sections. |
| WZRD-11 | 08-02 | `--dry-run` prints rendered diff without applying | SATISFIED | `test_wizard_dryrun.sh` PASS. Spot-check confirmed unified-diff output; no file mutation. |
| MANUAL-01 | 08-04 | `docs/manual-setup.md` walks through AGENTS.md section-by-section | SATISFIED | `test_manual_setup_sections.sh` PASS. 6 prompt sections + Sections 7–13 cover all AGENTS.md personalization points. |
| MANUAL-02 | 08-04 | Concrete minimal-diff example from neutral starter → working setup | SATISFIED | `test_manual_setup_example.sh` PASS. Sections 2–5 each include a minimal diff block. Uses neutral `personal-knowledge` per D-10. |
| MANUAL-03 | 08-04 | Checklist mapping one-to-one to wizard prompts | SATISFIED | `test_manual_setup_checklist.sh` PASS. Section 10 has 6 checkbox items matching 6 wizard prompts. |
| MANUAL-04 | 08-04 | Explicit equivalence statement | SATISFIED | `test_manual_setup_equivalence.sh` PASS. Section 11 states: "wizard track and the manual track produce a byte-identical end state. CI enforces this via tests/phase-08/test_canonical_byte_equality.sh". |
| MANUAL-05 | 08-04 | Lists every file the wizard touches | SATISFIED | `test_manual_setup_file_list.sh` PASS. Section 12 lists all 5 files: AGENTS.md, CLAUDE.md, .wizard-answers.yaml, wiki/decisions/dr-<TODAY>-initial-setup.md, wiki/index.md. |
| MANUAL-06 | 08-05 | Byte-equality test (wizard output matches manual track end state) | SATISFIED | `test_canonical_byte_equality.sh` PASS. `.github/workflows/setup-parity.yml` runs aggregator on PR (hard gate) + push (advisory). Local `cmp -s` confirmed BYTE-EQUAL. |

**Coverage:** 17/17 requirement IDs SATISFIED. Zero orphaned, zero blocked, zero needs-human.

**Cross-check against REQUIREMENTS.md:** All 17 Phase 8 REQ-IDs (WZRD-01..11, MANUAL-01..06) are marked `[x] Complete` in `.planning/REQUIREMENTS.md` lines 40–59 and in the Traceability table lines 183–199.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No blockers, warnings, or info findings | — | — |

A targeted scan of the phase-08 key artifacts (`bin/init-wizard.sh`, `docs/manual-setup.md`, `docs/guided-setup.md`, `docs/quickstart.md`, `schema/fixtures/*`, `tests/phase-08/test_*.sh`, `.github/workflows/setup-parity.yml`) surfaces no TODO/FIXME/PLACEHOLDER markers, no empty `return null/{}/[]` stubs in production code paths, no hardcoded-empty-prop leakage, no `console.log`-only implementations, no "coming soon" copy. Test assertions use deterministic fixtures; stubs inside test files (e.g., `return []` in synthetic YAML parser fallbacks) are inside the proper scope. The repo's `bin/check-neutrality.sh` passes clean as a secondary guard.

### Human Verification Required

None. All five ROADMAP success criteria were verified programmatically:
- Byte-equality is asserted mechanically (`cmp -s`) both locally and in CI.
- Pre-flight behavior is covered by `test_wizard_preflight.sh`.
- Validation behavior is covered by `test_wizard_validation.sh` (3 bad-input cases).
- `--dry-run` and idempotency are covered by their dedicated tests.
- Manual-track equivalence is both (a) documented in Section 11 of `docs/manual-setup.md` and (b) mechanically enforced by `test_canonical_byte_equality.sh` running the wizard's render routine that Section 11 claims parity with.

The one residual manual step documented in `08-05-SUMMARY.md` is an operator action (adding `setup-parity` to branch-protection required-status-checks on the public template repo); this is explicitly a post-merge GitHub UI action outside the repo's control surface and is not a verification-time concern.

### Gaps Summary

No gaps found. The phase goal — two-track setup (wizard + manual) with CI byte-equality gate ensuring identical AGENTS.md output — is fully achieved:

1. **Wizard track operational end-to-end:** `bin/init-wizard.sh` renders from `schema/AGENTS.template.md`, writes 5 artifacts atomically via staging-dir pattern, invokes `bin/sync-claude.sh` to maintain AGENTS.md==CLAUDE.md invariant, and handles all 5 ROADMAP success criteria (interactive write, --dry-run preview, --answers-file CI mode, hand-edit parity, pre-flight + validation).
2. **Manual track self-contained:** `docs/manual-setup.md` provides copy-not-edit flow (template stays pristine), inline deterministic decision-record heredoc, inline wiki/index.md append snippet — a hand-editor reaches byte-parity without invoking the wizard.
3. **Drift-prevention gate live:** `.github/workflows/setup-parity.yml` runs the full Phase 8 aggregator (includes `test_canonical_byte_equality.sh`) on every PR. Determinism env vars (`WIZARD_GENERATED_AT`, `WIZARD_TEMPLATE_SHA`) freeze the fixture comparison. `.gitattributes` LF-pins the fixtures against CRLF drift on Windows.
4. **All 17 REQ-IDs satisfied.** Phase-08 test aggregator green at 21/21; Phase-07 regression green at 22/22; neutrality gate clean.

Ready for transition / next phase. Operator must add `setup-parity` to public-repo branch protection required-status-checks list post-merge (documented in `08-05-SUMMARY.md`).

---

_Verified: 2026-04-16_
_Verifier: Claude (gsd-verifier)_

---
phase: 08-two-track-setup-wizard-manual
plan: 02
type: execute
wave: 1
depends_on:
  - 08-01-test-harness-and-fixtures-PLAN.md
files_modified:
  - bin/init-wizard.sh
  - tests/phase-08/test_wizard_exists.sh
  - tests/phase-08/test_wizard_preflight.sh
  - tests/phase-08/test_wizard_validation.sh
  - tests/phase-08/test_wizard_template_render.sh
  - tests/phase-08/test_wizard_dryrun.sh
  - tests/phase-08/test_wizard_idempotent.sh
  - tests/phase-08/test_wizard_summary.sh
  - tests/phase-08/test_wizard_semantic_groups.sh
  - tests/phase-08/test_wizard_not_yet_implemented.sh
autonomous: true
requirements:
  - WZRD-01
  - WZRD-02
  - WZRD-04
  - WZRD-05
  - WZRD-07
  - WZRD-08
  - WZRD-09
  - WZRD-11
must_haves:
  truths:
    - "bin/init-wizard.sh exists, executable, bash + python3 stdlib + PyYAML (with stdlib fallback for the controlled YAML key set)"
    - "Pre-flight (D-15) runs BEFORE any prompting or file I/O; checks bash >= 4, git, python3; emits one-line-per-missing-tool + pointer to docs/reference/setup-prerequisites.md"
    - "Interactive mode runs 6 prompts in D-11 order; semantic groups per D-13 print one-sentence explainers"
    - "WZRD-02 coverage: test_wizard_semantic_groups.sh feeds canned stdin to interactive wizard and greps stdout for all 4 D-13 explainer lines (Domain, LLM agent, Privacy defaults, Obsidian conventions)"
    - "Input validation per D-17 shape: `Invalid <field> \"<value>\". Must match <rule>. Try: <example>.`; interactive = fail-fast per prompt; --answers-file = collect-all + summary"
    - "Template render uses python3 `str.replace()` on exactly 4 tokens; post-render asserts no `{{[A-Z_]+}}` leftover"
    - "--dry-run emits unified diff via python3 `difflib.unified_diff`, mutates nothing, allowed regardless of init state (D-06)"
    - "--render-to <dir> writes rendered files to that dir without touching repo. MARKED CI/TESTING-ONLY in --help and surfaced as `(internal — CI/testing only)` per review concern #5; non-user-facing."
    - "Real-run mode (no --dry-run, no --render-to) WITHOUT Plan 03 wiring returns non-zero exit code 2 with message `not yet implemented — Plan 03 pending`; --dry-run and --render-to paths remain fully functional (review concern #6)"
    - "Re-run on initialized repo (presence of .wizard-answers.yaml at repo root) refuses with D-04 message + non-zero exit 4"
    - "git config user.name fallback: if empty/unset, default to \"unknown\" (never a literal empty prompt interpolation) per review concern #11"
    - "Completion summary prints `<path>  (<size>, <short status>)` per file + single `Next:` hint (D-19) — only emitted via --render-to in Plan 02"
    - "Color output respects TTY + NO_COLOR env var (D-20)"
  artifacts:
    - path: bin/init-wizard.sh
      provides: "Wizard entrypoint with interactive, --answers-file, --dry-run, --render-to <dir> modes"
      min_lines: 250
      contains: "schema/AGENTS.template.md"
    - path: tests/phase-08/test_wizard_preflight.sh
      provides: "Pre-flight failure path test (PATH manipulation to hide git/python3)"
    - path: tests/phase-08/test_wizard_validation.sh
      provides: "Validation failure shape test (invalid slug, agent, privacy)"
    - path: tests/phase-08/test_wizard_template_render.sh
      provides: "4-placeholder substitution test against fixture"
    - path: tests/phase-08/test_wizard_dryrun.sh
      provides: "--dry-run produces diff without mutation"
    - path: tests/phase-08/test_wizard_idempotent.sh
      provides: "Re-run refusal on initialized repo"
    - path: tests/phase-08/test_wizard_summary.sh
      provides: "Completion summary format test"
    - path: tests/phase-08/test_wizard_semantic_groups.sh
      provides: "WZRD-02: 4 D-13 semantic-group explainer lines printed in interactive output"
    - path: tests/phase-08/test_wizard_not_yet_implemented.sh
      provides: "Review concern #6: real-run invocation without --render-to or --dry-run returns exit 2 with clear message"
  key_links:
    - from: bin/init-wizard.sh
      to: schema/AGENTS.template.md
      via: "python3 inline block reads template + 4-token str.replace"
      pattern: "schema/AGENTS\\.template\\.md"
    - from: bin/init-wizard.sh
      to: docs/reference/setup-prerequisites.md
      via: "pre-flight error message pointer"
      pattern: "docs/reference/setup-prerequisites\\.md"
    - from: tests/phase-08/test_wizard_template_render.sh
      to: schema/fixtures/canonical-AGENTS.md
      via: "--render-to tmpdir + cmp -s against fixture"
      pattern: "schema/fixtures/canonical-AGENTS\\.md"
---

<objective>
Build the core `bin/init-wizard.sh`: pre-flight, prompt flow, validator, template render, --dry-run diff, --render-to <dir> (CI/testing-only), and idempotency guard. Plan 03 will add the repo-root file-write side-effects (.wizard-answers.yaml, decision record, sync-claude invocation, wiki/index.md edit) and remove Plan 02's explicit "not yet implemented" gate.

Purpose: Land the deterministic core (validation + render + flag posture) BEFORE the destructive side-effects so executors can hammer the render contract against the canonical fixture without worrying about cleanup. The render path is what MANUAL-06 enforces; getting it right here means Plan 03 is purely additive.

Output: bin/init-wizard.sh (interactive fails-fast-not-yet-implemented + --answers-file + --dry-run + --render-to modes; pre-flight; validator; render) + 9 phase-08 tests covering WZRD-01/02/04/05/07/08/09/11 plus the not-yet-implemented gate.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
@.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md
@.planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md
@.planning/phases/08-two-track-setup-wizard-manual/08-01-test-harness-and-fixtures-PLAN.md
@schema/AGENTS.template.md
@schema/fixtures/canonical-answers.yaml
@schema/fixtures/canonical-AGENTS.md
@bin/release.sh
@bin/check-neutrality.sh
@bin/sync-claude.sh
@bin/ingest.sh
@tests/phase-08/lib.sh

<interfaces>
<!-- Validator contract (RESEARCH.md Example 3, normative) -->

```python
# validate_answer(field: str, value) -> {"valid": bool, "errors": [{"field", "rule", "example"}]}
RULES = {
  "maintainer_name":   ("non-empty string", "Alex Doe", lambda v: isinstance(v, str) and len(v.strip()) > 0),
  "primary_domain":    ("^[a-z0-9-]+$",      "personal-knowledge", lambda v: isinstance(v, str) and re.match(r"^[a-z0-9-]+$", v) is not None),
  "agent":             ("one of {claude-code, codex, other}", "claude-code", lambda v: v in {"claude-code", "codex", "other"}),
  "default_privacy":   ("one of {local_only, cloud_safe}", "local_only", lambda v: v in {"local_only", "cloud_safe"}),
  "decay_profile":     ("one of {software, science, biography, personal-goals, default}", "default", lambda v: v in {"software", "science", "biography", "personal-goals", "default"}),
  "obsidian":          ("true or false", "true", lambda v: isinstance(v, bool)),
}
```

<!-- 4-placeholder render contract -->
TOKEN_MAP (computed from answers):
  "{{AGENT_FILENAME}}":  "CLAUDE.md" if answers.agent == "claude-code" else "AGENTS.md"
  "{{PRIMARY_DOMAIN}}":  answers.primary_domain
  "{{DEFAULT_PRIVACY}}": answers.default_privacy
  "{{DECAY_PROFILE}}":   answers.decay_profile

<!-- D-11 prompt order (NORMATIVE) -->
1. maintainer_name (default: `git config user.name` when present AND non-empty; else literal "unknown" per review concern #11)
2. primary_domain (default: personal-knowledge)
3. agent (default: claude-code)
4. default_privacy (default: local_only)
5. decay_profile (default: default)
6. obsidian (default: y)

<!-- D-13 semantic groups (NORMATIVE) -->
- Prompt 1 standalone (one-line explainer: "Recorded in the initial decision record for attribution.")
- Group: Domain (prompt 2) — explainer: "Your primary knowledge domain seeds the staleness decay rate and AGENTS.md frontmatter examples."
- Group: LLM agent (prompt 3) — explainer: "Determines which file the canonical-spec self-reference points at; both AGENTS.md and CLAUDE.md are always written byte-identical."
- Group: Privacy defaults (prompts 4 + 5) — explainer: "Default privacy tier applied to new pages, and how fast claims decay if their source is not re-verified."
- Group: Obsidian conventions (prompt 6) — explainer: "Whether you'll browse the wiki in Obsidian; recorded for future tooling, does not change AGENTS.md."

<!-- Exit codes (Claude's discretion per CONTEXT.md, planner's call) -->
0 — success
1 — generic failure (bad arg, write error)
2 — not yet implemented (Plan 02 real-run without --render-to or --dry-run; removed in Plan 03) [review concern #6]
3 — pre-flight failure (missing tool)
4 — re-run refusal (already initialized)
5 — validation failure (bad input or --answers-file errors)
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Implement bin/init-wizard.sh — flag parsing, pre-flight, validator, render, --dry-run, --render-to (CI-only), idempotency guard, not-yet-implemented gate</name>
  <files>bin/init-wizard.sh</files>
  <read_first>
    - schema/AGENTS.template.md (full file — substitution targets at lines 32, 56, 588, 589, 848)
    - bin/release.sh (flag-parsing pattern: lines 12, 91–100; trap cleanup idiom; usage() function)
    - bin/check-neutrality.sh (python3 inline block via env-vars pattern: lines 96–110)
    - bin/sync-claude.sh (zero-dep cmp -s + cp idiom — wizard does NOT invoke this in Plan 02; Plan 03 adds the invocation)
    - bin/ingest.sh (slug regex `^[a-z0-9-]+$` reference)
    - .planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md §Code Examples Examples 1, 3, 4 (atomic write, validator, pre-flight)
  </read_first>
  <behavior>
    - `bash bin/init-wizard.sh --help` exits 0, prints usage including all 4 flags (`--answers-file <path>`, `--dry-run`, `--render-to <dir>` marked `(internal — CI/testing only)`, `--help`).
    - With PATH stripped of `git`: pre-flight exits 3 with stderr containing "git: not found in PATH" AND "docs/reference/setup-prerequisites.md".
    - With `--answers-file path/to/bad-domain.yaml` (domain = "BadDomain!"): exits 5 with stderr containing `Invalid primary_domain "BadDomain!"`. Must match `^[a-z0-9-]+$`. Try: personal-knowledge.`
    - With `--answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-render`: exits 0; `/tmp/wz-render/AGENTS.md` is byte-equal to `schema/fixtures/canonical-AGENTS.md` (`cmp -s`); repo root unchanged (no AGENTS.md mutation in repo). NOTE: Plan 02 --render-to mode writes ONLY AGENTS.md (the rendered template output); CLAUDE.md, .wizard-answers.yaml, decision record, and wiki/index.md edit are added in Plan 03.
    - With `--answers-file schema/fixtures/canonical-answers.yaml --dry-run`: exits 0; stdout contains a unified-diff block for AGENTS.md (header `--- a/AGENTS.md` and `+++ b/AGENTS.md`); repo unchanged.
    - With `.wizard-answers.yaml` present at repo root + no --dry-run: exits 4 with stderr containing "already initialized" and "delete .wizard-answers.yaml and AGENTS.md".
    - --dry-run is ALLOWED even when `.wizard-answers.yaml` present (D-06): preview-only, never refused.
    - **Real-run mode without --render-to and without --dry-run (review concern #6):** exits with code 2 and message to stderr `bin/init-wizard.sh: not yet implemented — Plan 03 pending. Use --dry-run to preview or --render-to <dir> for CI testing.` This gate is REMOVED in Plan 03 once real-run repo-root writes are wired.
    - `NO_COLOR=1 bin/init-wizard.sh --help` produces output containing no `\033` escapes.
    - Empty/unset `git config user.name` (e.g., in CI without user configured): wizard uses literal default `"unknown"` instead of interpolating an empty string (review concern #11).
  </behavior>
  <action>
1. Create `bin/init-wizard.sh` with `#!/usr/bin/env bash` shebang, `set -euo pipefail`, executable mode (`chmod +x`).

2. Implement flag parsing (mirror `bin/release.sh:91–100` style):
   - `--help|-h` → call `usage()`, exit 0.
   - `--dry-run` → set `DRY_RUN=1`.
   - `--answers-file <path>` → set `ANSWERS_FILE="$2"`, shift 2; require non-empty path.
   - `--render-to <dir>` → set `RENDER_TO="$2"`, shift 2; mkdir -p target.
   - Unknown arg → echo to stderr, call usage to stderr, exit 1.

3. Implement `usage()` printing exactly (single quoted heredoc) — NOTE `--render-to` marked `(internal — CI/testing only)` per review concern #5:
```
Usage: bin/init-wizard.sh [--answers-file <path>] [--dry-run] [--render-to <dir>]

Modes:
  (default)               Interactive. Prompts for 6 answers, writes AGENTS.md, CLAUDE.md,
                          .wizard-answers.yaml, and an initial decision record at repo root.
                          (Plan 02 returns exit 2 until Plan 03 wires the repo-root writes.)
  --answers-file <path>   Non-interactive. Reads answers from YAML file, validates all
                          fields up front, exits non-zero with summary on validation errors.
  --dry-run               Preview-only. Renders all files and prints unified diff per file
                          to stdout. Mutates nothing. Always allowed regardless of init state.
  --render-to <dir>       (internal — CI/testing only) Write rendered files to <dir> instead
                          of repo root. Used by tests and CI; not intended as a user-facing
                          flag. Combine with --answers-file for non-interactive.

Exit codes:
  0  success
  1  generic failure (bad arg, write error)
  2  not yet implemented (Plan 02: real-run without --render-to or --dry-run; removed in Plan 03)
  3  pre-flight failure (missing bash >= 4 / git / python3)
  4  refused (repo already initialized; .wizard-answers.yaml present and not --dry-run)
  5  validation failure (invalid input or --answers-file errors)

Environment variables (CI/testing — internal):
  WIZARD_GENERATED_AT   ISO 8601 timestamp; overrides datetime.utcnow() for reproducible tests
  WIZARD_TEMPLATE_SHA   Overrides `git log -1 schema/AGENTS.template.md` SHA lookup
  NO_COLOR              When set (non-empty), disables ANSI escape codes in output

See: docs/reference/setup-prerequisites.md, docs/manual-setup.md
```

4. Implement `preflight()` per RESEARCH.md Example 4 — runs BEFORE flag parsing's actual work but AFTER --help handling so `--help` works without git installed:
   - Check `((BASH_VERSINFO[0] >= 4))` — if not, append "bash: need >= 4.0, have ${BASH_VERSION}" to errors.
   - `command -v git >/dev/null 2>&1` — if not, append "git: not found in PATH".
   - `command -v python3 >/dev/null 2>&1` — if not, append "python3: not found in PATH".
   - On any error: print "ERROR: pre-flight failed:" + bullet list to stderr + "See: docs/reference/setup-prerequisites.md for install instructions." + exit 3.

5. Implement TTY/NO_COLOR detection (RESEARCH.md Example Pattern 5) — set GREEN/RED/RESET vars; respect `[ -t 1 ] && [ -z "${NO_COLOR:-}" ]`.

6. Implement idempotency check (D-03/D-04):
   - If `[ -f .wizard-answers.yaml ]` AND `DRY_RUN=0`: print exact D-04 message from RESEARCH.md Example 6 (replace setup date with `stat`-derived mtime if available, otherwise "<unknown>") to stderr, exit 4.
   - If --dry-run: skip this check entirely (D-06).

7. Implement answer collection — two paths:
   a. Interactive (no `--answers-file`): print prompt 1 standalone with explainer, then 4 grouped sections with 1-line explainers (D-13). For prompt 1's default: `MAINTAINER_DEFAULT="$(git config user.name 2>/dev/null || true)"`; if empty or whitespace-only, fall back to literal `"unknown"` (review concern #11) — never render an empty-string default in the `[Default: ]` prompt. For each prompt: print prompt text + default in `[Default: X]` form; read input; if empty use default; call validator; on invalid print D-17 error format to stderr and re-prompt the same prompt (fail-fast). Use `read -r` for safe input.
   b. `--answers-file`: read YAML via python3 inline block (try `import yaml; yaml.safe_load(...)`; on `ImportError` fall back to a stdlib parser handling the controlled flat key set under `answers:` mapping). Iterate all 6 fields, accumulate validator errors, on any error print summary to stderr (`Found N validation errors:` + bullet list using D-17 shape) and exit 5.

8. Implement template render (RESEARCH.md Pattern 4) — single python3 inline block invoked from bash, args via env vars (mirror `bin/check-neutrality.sh` pattern):
   - `export WZRD_DOMAIN`, `WZRD_PRIVACY`, `WZRD_AGENT_FILENAME`, `WZRD_DECAY` from validated answers.
   - python3 reads `schema/AGENTS.template.md`, applies 4 `str.replace()` calls, asserts no `\{\{[A-Z_]+\}\}` leftover (sys.exit on leftover), writes to either `RENDER_TO/AGENTS.md` or stdout (for --dry-run diff path).
   - In Plan 02 scope:
     - `--render-to <dir>` mode: write `<RENDER_TO>/AGENTS.md` only (Plan 03 adds CLAUDE.md, .wizard-answers.yaml, decision record, wiki/index.md).
     - `--dry-run` mode: produce unified diff for AGENTS.md only (Plan 03 extends to all 5 files).
     - Real-run mode without --render-to and without --dry-run: exit 2 with `not yet implemented — Plan 03 pending` message (review concern #6). This explicit gate REPLACES Plan 02's prior "stubbed real run" behavior — no files written, no misleading success.

9. Implement --dry-run output (D-18, RESEARCH.md Pattern 3):
   - For AGENTS.md (Plan 02 scope): read existing content (empty string if missing), produce unified diff via python3 `difflib.unified_diff(a, b, fromfile=f"a/AGENTS.md", tofile=f"b/AGENTS.md", lineterm="")`, print to stdout.
   - Plan 03 will extend this to also emit diffs for CLAUDE.md, .wizard-answers.yaml, the decision record, and wiki/index.md.
   - Exit 0 after diff output.

10. Implement completion summary (D-19) for --render-to mode only in Plan 02 (real-run interactive path exits 2):
    ```
    Wrote (render-to mode):
      <RENDER_TO>/AGENTS.md                  (12345 bytes, new)

    Note: --render-to is CI/testing-only. Full wizard output (5 files) lands in Plan 03.
    ```

11. **CRITICAL (review concern #6):** Real-run mode — i.e., no `--dry-run` AND no `--render-to` AND (interactive OR `--answers-file`) — MUST exit with code 2 and print to stderr exactly:
    ```
    bin/init-wizard.sh: not yet implemented — Plan 03 pending.
    Use --dry-run to preview the rendered output, or --render-to <dir> for CI testing.
    ```
    No files are written. This gate is explicit and testable; Plan 03 removes it once real-run repo-root writes are wired.
  </action>
  <verify>
    <automated>bash bin/init-wizard.sh --help | grep -q 'internal — CI/testing only' && bash bin/init-wizard.sh --help | grep -q 'not yet implemented' && mkdir -p /tmp/wz-render && bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-render && cmp -s /tmp/wz-render/AGENTS.md schema/fixtures/canonical-AGENTS.md</automated>
  </verify>
  <acceptance_criteria>
    - `bash bin/init-wizard.sh --help` exits 0 and stdout contains all 4 flag names AND the literal string `(internal — CI/testing only)` next to `--render-to` (review concern #5).
    - `bash -n bin/init-wizard.sh` syntax-clean.
    - `test -x bin/init-wizard.sh`.
    - With `RENDER_TO=/tmp/wz-render-1` and `--answers-file schema/fixtures/canonical-answers.yaml`: `cmp -s /tmp/wz-render-1/AGENTS.md schema/fixtures/canonical-AGENTS.md` exits 0 (byte-equality preserved).
    - With a corrupt YAML answers file (domain = "Bad!"): exits 5, stderr contains literal substring `Invalid primary_domain "Bad!"`. Must match `^[a-z0-9-]+$`. Try: personal-knowledge.`
    - With `.wizard-answers.yaml` touch'd at repo root and no --dry-run: exits 4, stderr contains literal "already initialized" and "delete .wizard-answers.yaml and AGENTS.md". (Test harness must rm the touch'd file in cleanup.)
    - With `.wizard-answers.yaml` touch'd at repo root WITH --dry-run: exits 0 (D-06 preserved).
    - `--dry-run` mode prints `--- a/AGENTS.md` AND `+++ b/AGENTS.md` to stdout (unified diff headers present).
    - `NO_COLOR=1 bash bin/init-wizard.sh --help | grep -P '\x1b\['` returns no match (1).
    - **Not-yet-implemented gate (review concern #6):** Running `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml` (no --render-to, no --dry-run) exits with code 2 AND stderr contains literal `not yet implemented — Plan 03 pending`. No files written.
    - **git config empty fallback (review concern #11):** With `GIT_CONFIG_NOSYSTEM=1` and empty `HOME` (simulating no user configured), the interactive prompt for maintainer_name uses `[Default: unknown]` — never `[Default: ]`. Verify by sourcing wizard's fallback function in isolation or by feeding empty stdin and grepping prompt output.
    - `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` still exit 0 (no regression).
  </acceptance_criteria>
  <done>Wizard core (validate + render + dry-run + render-to + preflight + idempotency) shippable; `--render-to` clearly marked CI-only; real-run interactive mode returns exit 2 with a clear "not yet implemented" message; git config empty fallback uses "unknown"; Plan 03 removes the exit-2 gate once repo-root writes are wired.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Phase-08 tests for wizard core (9 test scripts covering WZRD-01/02/04/05/07/08/09/11 + review concern #6 gate)</name>
  <files>tests/phase-08/test_wizard_exists.sh, tests/phase-08/test_wizard_preflight.sh, tests/phase-08/test_wizard_validation.sh, tests/phase-08/test_wizard_template_render.sh, tests/phase-08/test_wizard_dryrun.sh, tests/phase-08/test_wizard_idempotent.sh, tests/phase-08/test_wizard_summary.sh, tests/phase-08/test_wizard_semantic_groups.sh, tests/phase-08/test_wizard_not_yet_implemented.sh</files>
  <read_first>
    - tests/phase-08/lib.sh (helpers from Plan 01 Task 1)
    - tests/phase-07/test_*.sh (look at any 2 existing test scripts to mirror style: shebang, source lib, set -euo pipefail, REPO_ROOT cd, descriptive echo, exit 0 on success)
    - bin/init-wizard.sh (just-shipped wizard from Task 1 — verify expected behaviors)
    - schema/fixtures/canonical-answers.yaml + schema/fixtures/canonical-AGENTS.md
  </read_first>
  <behavior>
    - All 9 tests source `tests/phase-08/lib.sh`, use mktemp_repo for isolation, use trap cleanup.
    - Tests cover the WZRD requirements stated in their filenames and exit 0 on PASS, non-zero on FAIL.
    - `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 9/9` after Plan 02 (will grow across Plans 03/04/05).
  </behavior>
  <action>
For each test file below: shebang `#!/usr/bin/env bash`, `set -euo pipefail`, `source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"`, descriptive `echo "TEST: <what>"`, assertions using lib.sh helpers, exit 0 on success.

1. `tests/phase-08/test_wizard_exists.sh` (WZRD-01):
   - `assert_file_exists "$REPO_ROOT/bin/init-wizard.sh"`
   - `[ -x "$REPO_ROOT/bin/init-wizard.sh" ] || { echo "FAIL: not executable"; exit 1; }`
   - `bash -n "$REPO_ROOT/bin/init-wizard.sh"` (syntax check)
   - `bash "$REPO_ROOT/bin/init-wizard.sh" --help | grep -qE -- '--answers-file' && bash "$REPO_ROOT/bin/init-wizard.sh" --help | grep -qE -- '--dry-run' && bash "$REPO_ROOT/bin/init-wizard.sh" --help | grep -qE -- '--render-to' && bash "$REPO_ROOT/bin/init-wizard.sh" --help | grep -qE -- '--help'`
   - **Review concern #5:** verify `--render-to` is marked internal in --help: `bash "$REPO_ROOT/bin/init-wizard.sh" --help | grep -q 'internal — CI/testing only'`.

2. `tests/phase-08/test_wizard_preflight.sh` (WZRD-09):
   - Strip `git` from PATH and verify. More robust: create a temp PATH containing only an empty dir, then run wizard: `PATH=/nonexistent bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" 2>&1` — capture exit code (must be 3) and stderr (must contain "git: not found" AND "docs/reference/setup-prerequisites.md"). NOTE: `bash` itself must remain accessible — test sets PATH only for the wizard invocation.
   - Use `set +e` around the failing call, capture `$?`, then `assert_eq 3 "$RC" "preflight exit code"`.

3. `tests/phase-08/test_wizard_validation.sh` (WZRD-04):
   - `WORK=$(mktemp_repo)`; write 3 bad answers files into $WORK:
     - `bad-domain.yaml`: same as canonical but `primary_domain: "BadDomain!"`
     - `bad-agent.yaml`: `agent: "vim"`
     - `bad-privacy.yaml`: `default_privacy: "secret"`
   - For each: run wizard with --answers-file, capture stderr + exit code, assert exit code 5, assert stderr matches D-17 pattern `Invalid <field> "<value>". Must match` for the offending field.
   - Sample assertion: `assert_grep 'Invalid primary_domain "BadDomain!"\. Must match' /tmp/stderr-bad-domain "domain validation error format"`

4. `tests/phase-08/test_wizard_template_render.sh` (WZRD-07):
   - `WORK=$(mktemp_repo)`
   - `bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" --render-to "$WORK"`
   - `assert_byte_equal "$WORK/AGENTS.md" "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"`
   - `! grep -qE '\{\{[A-Z_]+\}\}' "$WORK/AGENTS.md"` (no leftover placeholders)

5. `tests/phase-08/test_wizard_dryrun.sh` (WZRD-11):
   - `STDOUT=$(bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" --dry-run)`
   - `echo "$STDOUT" | grep -qE '^\-\-\- a/AGENTS\.md'` (unified-diff source header)
   - `echo "$STDOUT" | grep -qE '^\+\+\+ b/AGENTS\.md'` (unified-diff target header)
   - Assert no AGENTS.md was created in repo root: `git status --porcelain AGENTS.md | grep -qE '^\?\?' && { echo "FAIL: dry-run created AGENTS.md"; exit 1; } || true`

6. `tests/phase-08/test_wizard_idempotent.sh` (WZRD-05):
   - `WORK=$(mktemp_repo)`; cd "$WORK"; copy minimal repo skeleton (`schema/AGENTS.template.md`, `bin/init-wizard.sh`, `bin/sync-claude.sh`); `touch .wizard-answers.yaml`.
   - Run wizard with --answers-file pointing at a synthesized canonical answers file in $WORK; assert exit code 4, stderr contains `already initialized` and `delete .wizard-answers.yaml and AGENTS.md`.
   - Re-run WITH --dry-run: assert exit 0 (D-06 always-allowed preview).

7. `tests/phase-08/test_wizard_summary.sh` (WZRD-08):
   - `WORK=$(mktemp_repo)`
   - `STDOUT=$(bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" --render-to "$WORK")`
   - `echo "$STDOUT" | grep -qE '^Wrote'`
   - `echo "$STDOUT" | grep -qE 'AGENTS\.md\s+\([0-9]+ bytes'`

8. `tests/phase-08/test_wizard_semantic_groups.sh` (WZRD-02 — D-13 semantic-group explainers printed in interactive mode):
   - `WORK=$(mktemp_repo)`
   - Feed canned answers via stdin (one answer per prompt, terminated with newline) and capture combined stdout+stderr. Use `NO_COLOR=1` to strip ANSI escapes for deterministic grep. Invoke with `--render-to "$WORK"` so the wizard runs its full interactive prompt flow without touching repo root:
     ```bash
     OUT=$(NO_COLOR=1 printf 'Template Maintainer\npersonal-knowledge\nclaude-code\ncloud_safe\ndefault\ny\n' | bash "$REPO_ROOT/bin/init-wizard.sh" --render-to "$WORK" 2>&1 || true)
     ```
   - Assert all 4 D-13 group-header explainer strings appear verbatim in OUT (exact substrings from <interfaces> block D-13 NORMATIVE text):
     - `echo "$OUT" | grep -qF 'Your primary knowledge domain seeds the staleness decay rate and AGENTS.md frontmatter examples.' || { echo "FAIL: Domain explainer missing"; exit 1; }`
     - `echo "$OUT" | grep -qF 'Determines which file the canonical-spec self-reference points at; both AGENTS.md and CLAUDE.md are always written byte-identical.' || { echo "FAIL: LLM agent explainer missing"; exit 1; }`
     - `echo "$OUT" | grep -qF 'Default privacy tier applied to new pages, and how fast claims decay if their source is not re-verified.' || { echo "FAIL: Privacy defaults explainer missing"; exit 1; }`
     - `echo "$OUT" | grep -qF "Whether you'll browse the wiki in Obsidian; recorded for future tooling, does not change AGENTS.md." || { echo "FAIL: Obsidian explainer missing"; exit 1; }`
   - Also assert the prompt-1 standalone explainer appears: `echo "$OUT" | grep -qF 'Recorded in the initial decision record for attribution.' || { echo "FAIL: maintainer-name explainer missing"; exit 1; }`

9. `tests/phase-08/test_wizard_not_yet_implemented.sh` (review concern #6 — real-run gate):
   - Purpose: Verify Plan 02's explicit "not yet implemented" gate. Real-run invocation (no --render-to AND no --dry-run) MUST exit 2 with a clear message. No files written.
   - `WORK=$(mktemp_repo)`; cd "$WORK"; copy `schema/AGENTS.template.md` into `$WORK/schema/` to satisfy the wizard's render path read.
   - `set +e`
   - `RC=0; OUT=$(bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" 2>&1) || RC=$?`
   - `set -e`
   - `assert_eq 2 "$RC" "not-yet-implemented exit code"`
   - `echo "$OUT" | grep -qF 'not yet implemented — Plan 03 pending' || { echo "FAIL: expected 'not yet implemented — Plan 03 pending' in stderr"; exit 1; }`
   - Verify no files written: `[ ! -f "$WORK/AGENTS.md" ] && [ ! -f "$WORK/.wizard-answers.yaml" ] || { echo "FAIL: wizard wrote files despite exit 2"; exit 1; }`
   - NOTE: Plan 03 deletes this test (or converts it to assert the gate is gone) when real-run writes are wired.

Each test ends with `echo "PASS: <test name>"` and `exit 0`. Use `set +e` around expected-failure invocations to capture exit codes without crashing the test.

After writing all 9 tests:
- Run `bash tests/phase-08/run.sh` → must report `PHASE 08 TESTS: 9/9` and exit 0.
  </action>
  <verify>
    <automated>bash tests/phase-08/run.sh && bash tests/phase-08/run.sh 2>&1 | grep -qE 'PHASE 08 TESTS: 9/9'</automated>
  </verify>
  <acceptance_criteria>
    - All 9 test files exist under tests/phase-08/ with shebang `#!/usr/bin/env bash` and `set -euo pipefail`.
    - All 9 test files source `lib.sh` and use its helpers (`grep -l 'source.*lib\.sh' tests/phase-08/test_wizard_*.sh | wc -l` == 9).
    - `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 9/9` in stdout.
    - `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` still exit 0 (no regression).
  </acceptance_criteria>
  <done>9 phase-08 tests cover WZRD-01/02/04/05/07/08/09/11 (incl. WZRD-02 semantic-group explainers) + the explicit not-yet-implemented exit-2 gate; aggregator at 9/9; wizard core verified against canonical fixture.</done>
</task>

</tasks>

<verification>
1. `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 9/9`.
2. `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz && cmp -s /tmp/wz/AGENTS.md schema/fixtures/canonical-AGENTS.md` exits 0.
3. `bash bin/init-wizard.sh --help` exits 0 with usage (including `internal — CI/testing only` marker on --render-to).
4. `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml` exits 2 with `not yet implemented — Plan 03 pending`.
5. `bash bin/check-neutrality.sh` exits 0.
6. `bash tests/phase-07/run.sh` exits 0.
</verification>

<success_criteria>
- bin/init-wizard.sh ships with all 4 modes (`--render-to` explicitly marked internal; real-run returns exit 2 until Plan 03 wires writes).
- Pre-flight + validator + render contract verified against canonical fixture (byte-equal).
- git config user.name empty fallback uses "unknown" literal (never interpolates empty string).
- 9 phase-08 tests pass; harness aggregator green (WZRD-02 mechanically verified; not-yet-implemented gate mechanically verified).
- Real-run interactive repo-root mutation deferred to Plan 03 (with explicit exit-2 gate, not a silent stub).
</success_criteria>

<output>
After completion, create `.planning/phases/08-two-track-setup-wizard-manual/08-02-SUMMARY.md` capturing: line count of bin/init-wizard.sh, exit-code allocation table (including the new exit 2), fixture render verified byte-equal, list of 9 test files, and the explicit exit-2 gate that Plan 03 removes.
</output>

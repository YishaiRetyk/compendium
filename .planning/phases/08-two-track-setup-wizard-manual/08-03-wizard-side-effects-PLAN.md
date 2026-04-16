---
phase: 08-two-track-setup-wizard-manual
plan: 03
type: execute
wave: 2
depends_on:
  - 08-02-init-wizard-core-PLAN.md
files_modified:
  - bin/init-wizard.sh
  - tests/phase-08/test_wizard_answers_yaml.sh
  - tests/phase-08/test_wizard_decision_record.sh
  - tests/phase-08/test_wizard_sync_claude.sh
  - tests/phase-08/test_wizard_index_md.sh
  - tests/phase-08/test_wizard_partial_failure.sh
autonomous: true
requirements:
  - WZRD-03
  - WZRD-06
  - WZRD-10
must_haves:
  truths:
    - "Real-run mode (no --dry-run, no --render-to) writes 5 artifacts to repo root: AGENTS.md, CLAUDE.md (via bin/sync-claude.sh), .wizard-answers.yaml, wiki/decisions/dr-<TODAY>-initial-setup.md, and an updated wiki/index.md with a Decisions subsection entry"
    - "Plan 02's exit-2 'not yet implemented' gate is REMOVED; real-run now succeeds end-to-end"
    - "Staging-dir pattern (review concern #8): all 5 artifacts are rendered into a staging tempdir FIRST; only after every render+validate succeeds does the wizard atomically mv files to their final repo-root locations. A failure in step N leaves repo-root untouched."
    - ".wizard-answers.yaml contains 6 answers + wizard_version + generated_at (ISO 8601) + template_sha (resolved via env-var → git-lookup → `<unresolved>` chain per review concern #9)"
    - "Initial decision record conforms to AGENTS.md §4.6: type=decision, trigger_type=schema-update, affected_pages=[], all 7 required sections filled with deterministic substitution, no LLM-in-wizard"
    - "wiki/index.md edit is isolated behind a narrow helper function `update_index_md()` with: (a) idempotency check — refuse to add if the exact `[[dr-<TODAY>-initial-setup|...]]` wikilink already present, (b) duplicate-header guardrail — assert `## Decisions` heading appears 0 or 1 times before append, (c) clear recovery message on malformed index (review concern #2)"
    - "After AGENTS.md write, wizard invokes `bash \"$SCRIPT_DIR/sync-claude.sh\"` in real-run mode; CLAUDE.md ends byte-identical to AGENTS.md"
    - "Determinism env vars WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA enable reproducible fixtures for CI"
  artifacts:
    - path: bin/init-wizard.sh
      provides: "Wizard with full real-run write path: staging-dir render, atomic promote, wiki/index.md helper with guardrails, sync-claude invoke"
    - path: tests/phase-08/test_wizard_answers_yaml.sh
      provides: "WZRD-06: .wizard-answers.yaml shape + key set + atomic write"
    - path: tests/phase-08/test_wizard_decision_record.sh
      provides: "WZRD-10: decision record schema conformance, all 7 sections, frontmatter fields"
    - path: tests/phase-08/test_wizard_sync_claude.sh
      provides: "AGENTS.md == CLAUDE.md byte-equal after wizard real-run"
    - path: tests/phase-08/test_wizard_index_md.sh
      provides: "wiki/index.md gains Decisions subsection + entry; idempotent + duplicate-header guardrails verified"
    - path: tests/phase-08/test_wizard_partial_failure.sh
      provides: "Review concern #8: simulates mid-init failure, verifies repo-root stays clean (staging-dir recovery)"
  key_links:
    - from: bin/init-wizard.sh
      to: bin/sync-claude.sh
      via: "bash invocation after AGENTS.md promoted from staging dir"
      pattern: "bash.*sync-claude\\.sh"
    - from: bin/init-wizard.sh
      to: wiki/decisions/dr-<TODAY>-initial-setup.md
      via: "deterministic template substitution into 7 sections"
      pattern: "trigger_type: schema-update"
    - from: bin/init-wizard.sh
      to: wiki/index.md
      via: "update_index_md() helper with idempotency + duplicate-header guard"
      pattern: "## Decisions"
---

<objective>
Wire the destructive write side of `bin/init-wizard.sh`: staging-dir render + atomic promote for all 5 artifacts, deterministic initial decision record, AGENTS.md→CLAUDE.md sync via existing `bin/sync-claude.sh`, and a narrow `update_index_md()` helper for the wiki/index.md Decisions subsection edit (with idempotency + duplicate-header guardrails per review concern #2). Removes Plan 02's exit-2 gate so real-run interactive + `--answers-file` modes complete end-to-end.

Purpose: Plan 02 landed the deterministic core; Plan 03 adds the 4 file writes that make the wizard actually useful, leveraging existing zero-dep tooling (`bin/sync-claude.sh`) per Open Q4 and resolving Open Q1 (wizard owns the index.md edit) with isolation + guardrails. Staging-dir pattern ensures a mid-init failure never leaves a half-initialized repo (review concern #8).

Output: Updated bin/init-wizard.sh (real-run side-effects wired with staging-dir + narrow index.md helper) + 5 new phase-08 tests covering WZRD-03/06/10, the index.md/sync-claude integrations, and the partial-failure recovery path.
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
@.planning/phases/08-two-track-setup-wizard-manual/08-02-init-wizard-core-PLAN.md
@bin/init-wizard.sh
@bin/sync-claude.sh
@schema/AGENTS.template.md
@schema/fixtures/canonical-answers.yaml
@wiki/index.md
@wiki/decisions/dr-2026-04-14-phase6-decision-type.md
@wiki/decisions/dr-2026-04-15-kahneman-to-examples.md
@tests/phase-08/lib.sh

<interfaces>
<!-- .wizard-answers.yaml canonical shape (RESEARCH.md Example 2, NORMATIVE) -->
```yaml
# Generated by bin/init-wizard.sh v1.1.0 on 2026-04-16T14:32:11Z
# Source of truth for the wizard answer set; powers v1.2 `--upgrade`.
wizard_version: "1.1.0"
generated_at: "2026-04-16T14:32:11Z"
template_sha: "a1b2afd4e5f6..."   # or "<unresolved>" per D-25 + review concern #9
answers:
  maintainer_name: "Template Maintainer"
  primary_domain: "personal-knowledge"
  agent: "claude-code"
  default_privacy: "cloud_safe"
  decay_profile: "default"
  obsidian: true
```

<!-- template_sha resolution chain (review concern #9) -->
Order of resolution (first match wins):
1. `WIZARD_TEMPLATE_SHA` env var (set by CI/tests for determinism) — authoritative
2. `git log -1 --format=%H schema/AGENTS.template.md` (when in a git checkout with history) — best-effort
3. Literal string `"<unresolved>"` (final fallback — D-25)

Note: CI workflows in Plan 05 MUST always set `WIZARD_TEMPLATE_SHA` explicitly; the git-history path is non-authoritative and drops `fetch-depth: 2` reliance per review concern #9/#10.

<!-- Initial decision record skeleton (RESEARCH.md Example 5, NORMATIVE) -->
- Path: `wiki/decisions/dr-<TODAY>-initial-setup.md` where TODAY = `date -u +%Y-%m-%d` (UTC for determinism) OR the date portion of `WIZARD_GENERATED_AT` when set
- Frontmatter: id, title, type=decision, status=active, summary, created_at, updated_at, sources=[], epistemic_status=sourced, tags=[meta, setup], domains=[wiki-infrastructure], privacy=cloud_safe, knowledge_domain=software, supersedes=, superseded_by=, aliases=[], has_contradictions=false, trigger_type=schema-update, affected_pages=[]
- 7 required sections (AGENTS.md §4.6 ordering): TL;DR → Decision → Why → Alternatives Considered → Consequences → Affected Pages → Sources

<!-- wiki/index.md edit — `update_index_md()` helper (Open Q1 resolution + review concern #2) -->

Helper contract (implemented as a python3 inline function called from the main flow):

```python
def update_index_md(index_path, today, primary_domain):
    """
    Narrow helper — responsible for ONE thing: adding the initial-setup decision
    record entry to wiki/index.md's Decisions subsection.

    Guardrails:
      1. Idempotency: if the exact `[[dr-<today>-initial-setup|...]]` wikilink is
         already present in the file, no-op (return 'no-op').
      2. Duplicate-header guard: count occurrences of `## Decisions` at start-of-line.
         If > 1, raise RuntimeError with a clear recovery message ("wiki/index.md
         has multiple `## Decisions` headings — please resolve manually").
         If 0, create the section.
         If 1, append entry to the existing section.
      3. Malformed recovery: if the file is missing or unreadable in a mode that
         requires it, raise RuntimeError with "wiki/index.md missing/malformed —
         copy from template or run `bin/init-wizard.sh --dry-run` to inspect".
    """
    content = pathlib.Path(index_path).read_text(encoding="utf-8")
    entry_line = f"- [[dr-{today}-initial-setup|Initial Wizard Setup -- {primary_domain}]] -- Wizard-driven template personalization (wiki-infrastructure, {today})"
    # Idempotency check
    if entry_line in content:
        return "no-op"
    # Duplicate-header guard
    decisions_headers = re.findall(r"(?m)^## Decisions\s*$", content)
    if len(decisions_headers) > 1:
        raise RuntimeError(
            f"wiki/index.md has {len(decisions_headers)} `## Decisions` headings — "
            "please resolve manually (expected 0 or 1)."
        )
    # Append logic
    if len(decisions_headers) == 0:
        new = content.rstrip() + f"\n\n## Decisions\n\n{entry_line}\n"
    else:
        # Insert entry at end of existing Decisions section
        new = _insert_in_section(content, "## Decisions", entry_line)
    return new  # caller writes atomically
```

<!-- Staging-dir pattern (review concern #8) -->

Real-run flow:
1. Create staging tempdir: `STAGE=$(mktemp -d -t wizard-stage-XXXX)`
2. Render all 5 artifacts INTO $STAGE (render AGENTS.md, CLAUDE.md [cp of AGENTS.md], .wizard-answers.yaml, decision record, updated wiki/index.md computed from the current repo state).
3. Validate: all 5 files exist in staging, none contain leftover `{{...}}` placeholders, wiki/index.md passes the duplicate-header guard.
4. On any step 2/3 failure: `rm -rf $STAGE`, print error, exit non-zero. Repo root is untouched.
5. On success: atomically `mv` each file from $STAGE to its final repo-root destination. This step is best-effort atomic; `mv` within the same filesystem is rename (atomic), cross-filesystem is cp+rm (non-atomic but quick). The staging dir SHOULD be on the same filesystem as repo root (use `mktemp -d --tmpdir="$(pwd)/.wizard-stage-XXXX"` or similar pattern to stay on the same mount).
6. `rm -rf $STAGE` (staging dir cleanup after successful promote).
7. Finally: invoke `bash "$SCRIPT_DIR/sync-claude.sh"` on the now-promoted repo-root AGENTS.md (this is a no-op if CLAUDE.md was already promoted byte-identical from staging; it re-asserts the invariant).

<!-- bin/sync-claude.sh invocation pattern (Open Q4) -->
After AGENTS.md is promoted from staging to repo root:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/sync-claude.sh"   # re-asserts CLAUDE.md byte-identical to AGENTS.md
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Wire real-run side-effects into bin/init-wizard.sh (staging-dir render + atomic promote, narrow update_index_md() helper with guardrails, sync-claude invoke, template_sha fallback chain)</name>
  <files>bin/init-wizard.sh</files>
  <read_first>
    - bin/init-wizard.sh (Plan 02 output — find the exit-2 gate location to replace)
    - bin/sync-claude.sh (35 lines — invocation contract)
    - wiki/index.md (current state — verify the append point)
    - wiki/decisions/dr-2026-04-15-kahneman-to-examples.md (most recent decision record exemplar — use as frontmatter ordering reference)
    - .planning/phases/08-two-track-setup-wizard-manual/08-RESEARCH.md §Code Examples Examples 1, 2, 5 (atomic write, .wizard-answers.yaml shape, decision record skeleton); §Open Questions Q1, Q4
    - schema/AGENTS.template.md §4.6 (decision record schema requirements)
  </read_first>
  <behavior>
    - Real-run mode (no --dry-run, no --render-to) writes 5 artifacts to repo root atomically via staging-dir pattern: AGENTS.md, CLAUDE.md, .wizard-answers.yaml, wiki/decisions/dr-<TODAY>-initial-setup.md, wiki/index.md (appended Decisions subsection).
    - Plan 02's exit-2 gate is removed; real-run now proceeds through the full write path.
    - Staging-dir pattern (review concern #8): all renders happen in a tempdir first; on any failure, repo root is untouched; on success, atomic mv.
    - --render-to <dir> mode writes the same 5 artifacts into <dir>/ directly (no staging; <dir> IS the staging target). Still CI/testing-only marker preserved.
    - sync-claude.sh invocation: `bash "$SCRIPT_DIR/sync-claude.sh"` after AGENTS.md promoted to repo root in real-run mode. For --render-to mode, sync-claude is inlined (cp + cmp) within RENDER_TO since the script assumes repo-root paths.
    - .wizard-answers.yaml shape exactly matches RESEARCH.md Example 2 with snake_case keys; written even in --render-to mode.
    - template_sha resolution chain (review concern #9): WIZARD_TEMPLATE_SHA env var > `git log -1 --format=%H schema/AGENTS.template.md` > literal `<unresolved>`. No `fetch-depth: 2` reliance — CI must set the env var.
    - Decision record: deterministic substitution of 11 fields into RESEARCH.md Example 5 skeleton; all 7 sections present; type=decision; trigger_type=schema-update; affected_pages=[].
    - update_index_md() helper:
      - Idempotency: skip append if the exact wikilink entry already present.
      - Duplicate-header guard: exit non-zero with clear recovery message if `## Decisions` appears >1 times.
      - Malformed/missing index: exit non-zero with pointer-to-manual-recovery message.
  </behavior>
  <action>
1. Open `bin/init-wizard.sh`. Locate Plan 02's exit-2 gate block (the `not yet implemented — Plan 03 pending` early-exit). Remove it — real-run mode now proceeds.

2. Also remove from `--help` usage output: the line `(Plan 02 returns exit 2 until Plan 03 wires the repo-root writes.)` AND the exit-code-2 row in the exit codes table. Update the exit codes documentation to remove `2  not yet implemented`.

3. Add (within a python3 inline block invoked from bash after answers are validated) a function `write_artifacts(answers, target_root, template_sha, today, generated_at)` that performs all 5 writes via the staging-dir pattern:

   a. **Resolve common metadata** at the top of the python3 block:
      - `import datetime, os, sys, subprocess, tempfile, re, pathlib, shutil, filecmp, json`
      - TODAY resolution: if `WIZARD_GENERATED_AT` env var set, take the date portion (`YYYY-MM-DD`); else `datetime.datetime.utcnow().strftime("%Y-%m-%d")`.
      - GENERATED_AT resolution: `os.environ.get("WIZARD_GENERATED_AT") or datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")`.
      - `WIZARD_VERSION = "1.1.0"` (literal constant).
      - **template_sha resolution chain (review concern #9)** — first match wins:
        ```python
        template_sha = os.environ.get("WIZARD_TEMPLATE_SHA")
        if not template_sha:
            try:
                r = subprocess.run(
                    ["git", "log", "-1", "--format=%H", "schema/AGENTS.template.md"],
                    capture_output=True, text=True, check=False,
                )
                template_sha = r.stdout.strip() or "<unresolved>"
            except Exception:
                template_sha = "<unresolved>"
        ```

   b. **Define `atomic_write(path, content)`** per RESEARCH.md Example 1:
      ```python
      def atomic_write(path, content):
          path = pathlib.Path(path)
          path.parent.mkdir(parents=True, exist_ok=True)
          fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix="." + path.name + ".", suffix=".tmp")
          try:
              with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
                  f.write(content)
              os.replace(tmp, str(path))
          except Exception:
              if os.path.exists(tmp):
                  os.unlink(tmp)
              raise
      ```

   c. **Define `update_index_md(index_path, today, primary_domain)` helper** — the narrow helper from <interfaces> block with idempotency + duplicate-header guard + malformed recovery. Implementation must match the <interfaces> contract exactly; all 3 guardrails (a) (b) (c) tested by test_wizard_index_md.sh.

   d. **Staging-dir render (review concern #8):**
      - If `target_root == "."` (real-run repo-root mode): create `STAGE = pathlib.Path(tempfile.mkdtemp(dir=os.getcwd(), prefix=".wizard-stage-"))` (same-filesystem guarantee for atomic mv).
      - If `target_root != "."` (--render-to mode): `STAGE = pathlib.Path(target_root)` — render directly to the target; no staging needed (caller chose the location).
      - Try/except around the full render sequence:
        ```python
        try:
            _render_all_five(STAGE, answers, template_sha, today, generated_at)
            _validate_staging(STAGE)
            if target_root == ".":
                _promote_staging_to_repo_root(STAGE)
            # else: render-to mode already wrote to target_root directly
        except Exception as e:
            if target_root == "." and STAGE.exists():
                shutil.rmtree(STAGE, ignore_errors=True)
            print(f"ERROR: wizard write failed: {e}", file=sys.stderr)
            print("Repo root untouched. See `--dry-run` to preview.", file=sys.stderr)
            sys.exit(1)
        finally:
            if target_root == "." and STAGE.exists():
                shutil.rmtree(STAGE, ignore_errors=True)
        ```

   e. **Write AGENTS.md** into STAGE (rendered template).

   f. **Write CLAUDE.md** into STAGE:
      - Always: `shutil.copyfile(STAGE/"AGENTS.md", STAGE/"CLAUDE.md")` then `assert filecmp.cmp(..., shallow=False)`.
      - After promote (real-run mode), `bash "$SCRIPT_DIR/sync-claude.sh"` is invoked from the outer bash wrapper to re-assert the byte-equal invariant from the repo-root location.

   g. **Write .wizard-answers.yaml** into STAGE with the exact YAML shape (booleans serialized lowercase, strings `json.dumps()`-quoted):
      ```python
      answers_yaml = f"""# Generated by bin/init-wizard.sh v{WIZARD_VERSION} on {generated_at}
# Source of truth for the wizard answer set; powers v1.2 `--upgrade`.
wizard_version: "{WIZARD_VERSION}"
generated_at: "{generated_at}"
template_sha: "{template_sha}"
answers:
  maintainer_name: {json.dumps(answers['maintainer_name'])}
  primary_domain: {json.dumps(answers['primary_domain'])}
  agent: {json.dumps(answers['agent'])}
  default_privacy: {json.dumps(answers['default_privacy'])}
  decay_profile: {json.dumps(answers['decay_profile'])}
  obsidian: {'true' if answers['obsidian'] else 'false'}
"""
      atomic_write(STAGE / ".wizard-answers.yaml", answers_yaml)
      ```

   h. **Write decision record** into STAGE at `wiki/decisions/dr-{today}-initial-setup.md`:
      - Use the RESEARCH.md Example 5 skeleton verbatim, with 11 substitutions (TODAY, PRIMARY_DOMAIN, AGENT, AGENT_FILENAME, DEFAULT_PRIVACY, DECAY_PROFILE, OBSIDIAN_YN, MAINTAINER_NAME, TEMPLATE_SHA, WIZARD_VERSION, GENERATED_AT).
      - "Alternatives Considered" section enumerates the OTHER allowed values for prompts 2–5.
      - Post-render assert no `{{...}}` leftover.

   i. **Compute updated wiki/index.md** into STAGE:
      - If real-run mode: read current `<repo>/wiki/index.md` (if missing, raise — wiki/index.md MUST exist pre-wizard per the template repo baseline).
      - If --render-to mode and `target_root/wiki/index.md` missing: copy from `<repo>/wiki/index.md` first.
      - Call `update_index_md()` helper on the in-memory content; write result to `STAGE/wiki/index.md`.

   j. **Validation step `_validate_staging(STAGE)`**: assert all 5 files exist in staging; grep all rendered files for `\{\{[A-Z_]+\}\}` leftovers (raise on any match); re-run update_index_md's guardrails on the staged index.md (duplicate-header guard).

   k. **Promote step `_promote_staging_to_repo_root(STAGE)`**: for each of the 5 files, `shutil.move(STAGE / relpath, repo_root / relpath)`. Same-filesystem rename is atomic.

4. Update `--dry-run` path to also produce diffs for the 3 newly-handled files (.wizard-answers.yaml, decision record, wiki/index.md). The existing dry-run flow from Plan 02 already emits AGENTS.md; Plan 03 extends to emit all 5. Same render routine, against-existing-or-empty comparison.

5. Update completion summary (D-19) to include all 5 paths with sizes, marking CLAUDE.md as `(byte-identical to AGENTS.md)` and wiki/index.md as `(updated)` rather than `(new)`.

6. **CRITICAL determinism check**: with `--answers-file schema/fixtures/canonical-answers.yaml --render-to <tmp>` invoked twice with `WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=test-sha` set, both runs produce byte-identical .wizard-answers.yaml + decision record. Document both env vars in --help under the Environment block (already added in Plan 02 Task 1 step 3).

7. Run `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-real-run` — confirm:
   - `/tmp/wz-real-run/AGENTS.md` byte-equal to `schema/fixtures/canonical-AGENTS.md`
   - `/tmp/wz-real-run/CLAUDE.md` byte-equal to `/tmp/wz-real-run/AGENTS.md`
   - `/tmp/wz-real-run/.wizard-answers.yaml` exists, parses as YAML, contains all 6 answers + 3 metadata fields
   - `/tmp/wz-real-run/wiki/decisions/dr-<TODAY>-initial-setup.md` exists, has 7 sections, frontmatter `trigger_type: schema-update`
   - `/tmp/wz-real-run/wiki/index.md` exists, contains exactly one `## Decisions` heading and the wikilink entry
  </action>
  <verify>
    <automated>WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=test-sha bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-real-test && cmp -s /tmp/wz-real-test/AGENTS.md schema/fixtures/canonical-AGENTS.md && cmp -s /tmp/wz-real-test/AGENTS.md /tmp/wz-real-test/CLAUDE.md && test -f /tmp/wz-real-test/.wizard-answers.yaml && grep -q 'maintainer_name: "Template Maintainer"' /tmp/wz-real-test/.wizard-answers.yaml && test -f /tmp/wz-real-test/wiki/decisions/dr-2026-04-16-initial-setup.md && grep -q 'trigger_type: schema-update' /tmp/wz-real-test/wiki/decisions/dr-2026-04-16-initial-setup.md && grep -q '## Decisions' /tmp/wz-real-test/wiki/index.md && [ "$(grep -c '^## Decisions$' /tmp/wz-real-test/wiki/index.md)" -eq 1 ] && ! grep -qE '\{\{[A-Z_]+\}\}' /tmp/wz-real-test/wiki/decisions/dr-2026-04-16-initial-setup.md && ! grep -q 'not yet implemented — Plan 03 pending' bin/init-wizard.sh</automated>
  </verify>
  <acceptance_criteria>
    - With `WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=test-sha`, two consecutive runs into different tmpdirs produce byte-identical `.wizard-answers.yaml` AND byte-identical decision record (`cmp -s` exit 0 for each pair).
    - `cmp -s /tmp/wz/AGENTS.md /tmp/wz/CLAUDE.md` exits 0 (sync-claude byte-equal contract preserved).
    - `cmp -s /tmp/wz/AGENTS.md schema/fixtures/canonical-AGENTS.md` exits 0 (Plan 01/02 contract still holds).
    - `python3 -c "import yaml; d=yaml.safe_load(open('/tmp/wz/.wizard-answers.yaml')); assert set(d['answers'].keys()) == {'maintainer_name','primary_domain','agent','default_privacy','decay_profile','obsidian'}"` exits 0.
    - Decision record has all 7 sections (`grep -cE '^## (TL;DR|Decision|Why|Alternatives Considered|Consequences|Affected Pages|Sources)$' /tmp/wz/wiki/decisions/dr-*.md` returns 7).
    - Decision record frontmatter contains `type: decision`, `trigger_type: schema-update`, `affected_pages: []`.
    - wiki/index.md contains exactly one `## Decisions` heading after wizard run (`grep -c '^## Decisions$' /tmp/wz/wiki/index.md` returns 1).
    - Plan 02 exit-2 gate removed: `! grep -q 'not yet implemented — Plan 03 pending' bin/init-wizard.sh`.
    - update_index_md() helper function present in the wizard source (grep for function definition `def update_index_md` in the python3 inline block).
    - template_sha resolution chain present: grep for all three tokens `WIZARD_TEMPLATE_SHA`, `git log -1 --format=%H`, `<unresolved>` in bin/init-wizard.sh (review concern #9).
    - `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0 (no regression).
  </acceptance_criteria>
  <done>Wizard now produces all 5 artifacts via staging-dir + atomic promote; sync-claude invoked; index.md edit isolated behind narrow helper with 3 guardrails; template_sha fallback chain codified; deterministic via env-var injection; canonical fixture still byte-equal; Plan 02 exit-2 gate removed.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Phase-08 tests for side-effects (5 test scripts covering WZRD-03/06/10 + index.md + sync-claude + partial-failure recovery)</name>
  <files>tests/phase-08/test_wizard_answers_yaml.sh, tests/phase-08/test_wizard_decision_record.sh, tests/phase-08/test_wizard_sync_claude.sh, tests/phase-08/test_wizard_index_md.sh, tests/phase-08/test_wizard_partial_failure.sh</files>
  <read_first>
    - tests/phase-08/lib.sh
    - tests/phase-08/test_wizard_template_render.sh (Plan 02 sample test for style consistency)
    - bin/init-wizard.sh (post-Task 1 — verify expected output)
  </read_first>
  <behavior>
    - All 5 tests source lib.sh, use mktemp_repo, freeze time via WIZARD_GENERATED_AT + WIZARD_TEMPLATE_SHA, exit 0 on PASS.
    - Plan 02's `test_wizard_not_yet_implemented.sh` is DELETED by this task (or inverted — see step 6 below) since the exit-2 gate no longer exists.
    - `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 13/13` (9 from Plan 02 − 1 deleted not-yet-implemented + 5 from Plan 03 = 13).
  </behavior>
  <action>
1. `tests/phase-08/test_wizard_answers_yaml.sh` (WZRD-03 + WZRD-06):
   - `WORK=$(mktemp_repo)`
   - `WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" --render-to "$WORK"`
   - `assert_file_exists "$WORK/.wizard-answers.yaml"`
   - Verify YAML parses and contains all 6 answer keys + 3 metadata keys via python3 inline:
     ```bash
     python3 -c "
     import yaml, sys
     d = yaml.safe_load(open('$WORK/.wizard-answers.yaml'))
     assert d['wizard_version'] == '1.1.0'
     assert d['generated_at'] == '2026-04-16T12:00:00Z'
     assert d['template_sha'] == 'fixed-sha'
     assert set(d['answers'].keys()) == {'maintainer_name','primary_domain','agent','default_privacy','decay_profile','obsidian'}
     assert d['answers']['obsidian'] is True
     assert d['answers']['primary_domain'] == 'personal-knowledge'
     "
     ```
   - Determinism: re-run wizard into a second tmpdir with same env, `assert_byte_equal` between the two `.wizard-answers.yaml` files.

2. `tests/phase-08/test_wizard_decision_record.sh` (WZRD-10):
   - Same setup as Task 2.1.
   - `DR="$WORK/wiki/decisions/dr-2026-04-16-initial-setup.md"`
   - `assert_file_exists "$DR"`
   - `assert_grep '^type: decision$' "$DR" "type field"`
   - `assert_grep '^trigger_type: schema-update$' "$DR" "trigger_type field"`
   - `assert_grep '^affected_pages: \[\]$' "$DR" "affected_pages empty"`
   - `assert_grep '^privacy: cloud_safe$' "$DR" "privacy field"`
   - All 7 sections present: `[ "$(grep -cE '^## (TL;DR|Decision|Why|Alternatives Considered|Consequences|Affected Pages|Sources)$' "$DR")" -eq 7 ]`
   - No leftover placeholders: `! grep -qE '\{\{[A-Z_]+\}\}' "$DR"`
   - Frontmatter has `created_at: 2026-04-16` (TODAY-derived from WIZARD_GENERATED_AT).

3. `tests/phase-08/test_wizard_sync_claude.sh` (Open Q4 + WZRD-06 cross-cut):
   - `WORK=$(mktemp_repo)`
   - `WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" --render-to "$WORK"`
   - `assert_byte_equal "$WORK/AGENTS.md" "$WORK/CLAUDE.md"` (sync produced byte-identical CLAUDE.md)
   - `assert_byte_equal "$WORK/AGENTS.md" "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"` (Plan 01 contract still holds)
   - Verify wizard sources/invokes sync-claude.sh (or equivalent inlined logic): `grep -qE '(bash.*sync-claude\.sh|shutil\.copyfile.*CLAUDE\.md)' "$REPO_ROOT/bin/init-wizard.sh"`

4. `tests/phase-08/test_wizard_index_md.sh` (Open Q1 + review concern #2 — 3 guardrails):
   - **Guardrail 1 — happy path (empty starting index):**
     - `WORK=$(mktemp_repo)`
     - Pre-populate `$WORK/wiki/index.md` from the repo's existing skeleton: `mkdir -p "$WORK/wiki" && cp "$REPO_ROOT/wiki/index.md" "$WORK/wiki/index.md"`
     - `WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" --render-to "$WORK"`
     - `assert_grep '^## Decisions$' "$WORK/wiki/index.md" "Decisions heading present"`
     - `assert_grep '\[\[dr-2026-04-16-initial-setup\|Initial Wizard Setup -- personal-knowledge\]\]' "$WORK/wiki/index.md" "Decision wikilink entry"`
     - Exactly one `## Decisions` heading: `[ "$(grep -c '^## Decisions$' "$WORK/wiki/index.md")" -eq 1 ]`
   - **Guardrail 2 — idempotency:**
     - Pre-populate `$WORK2/wiki/index.md` containing the full starter skeleton PLUS an already-present `## Decisions` section with the exact same wikilink the wizard would add (simulating re-render).
     - Run wizard again with same env vars.
     - Assert: exit 0; `## Decisions` heading still appears exactly 1 time; the wikilink entry still appears exactly 1 time (not duplicated).
   - **Guardrail 3 — duplicate-header guard:**
     - `WORK3=$(mktemp_repo)`; pre-populate `$WORK3/wiki/index.md` with TWO `## Decisions` headings (malformed input simulating past manual edit).
     - Run wizard with `--render-to "$WORK3"`; capture exit code.
     - `assert_eq 1 "$RC" "duplicate-header guard exit code"`  (generic failure per exit code table)
     - Assert stderr contains `has 2 \`## Decisions\` headings` or equivalent recovery message.

5. `tests/phase-08/test_wizard_partial_failure.sh` (review concern #8 — staging-dir recovery):
   - Purpose: Verify that a simulated mid-init failure leaves the repo-root untouched. Uses real-run mode (not --render-to).
   - `WORK=$(mktemp_repo)`; populate $WORK with a minimal repo skeleton: schema/AGENTS.template.md, bin/init-wizard.sh, bin/sync-claude.sh, wiki/index.md; `cd $WORK`.
   - Induce a failure: write a deliberately-malformed `$WORK/wiki/index.md` containing TWO `## Decisions` headings (triggers the duplicate-header guard during staging validation). This fails AFTER AGENTS.md and CLAUDE.md have been rendered into staging but BEFORE the promote step.
   - `set +e`
   - `RC=0; OUT=$(WIZARD_GENERATED_AT=2026-04-16T00:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha bash "$REPO_ROOT/bin/init-wizard.sh" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" 2>&1) || RC=$?`
   - `set -e`
   - `[ "$RC" -ne 0 ] || { echo "FAIL: expected non-zero exit on duplicate-header"; exit 1; }`
   - **Verify repo-root stays untouched:** no `AGENTS.md`, no `CLAUDE.md`, no `.wizard-answers.yaml`, no `wiki/decisions/dr-*.md` at repo root. `[ ! -f "$WORK/AGENTS.md" ] && [ ! -f "$WORK/CLAUDE.md" ] && [ ! -f "$WORK/.wizard-answers.yaml" ] && [ -z "$(ls "$WORK/wiki/decisions/" 2>/dev/null)" ] || { echo "FAIL: partial state written to repo-root"; exit 1; }`
   - **Verify staging dir cleaned up:** no `.wizard-stage-*` directories remain in `$WORK`. `[ -z "$(ls -d "$WORK"/.wizard-stage-* 2>/dev/null)" ] || { echo "FAIL: staging dir not cleaned up"; exit 1; }`
   - Assert stderr contains `Repo root untouched` recovery message.

6. **DELETE** `tests/phase-08/test_wizard_not_yet_implemented.sh` (Plan 02 Task 2 step 9) — the exit-2 gate it verified no longer exists. Removal step: `rm "$REPO_ROOT/tests/phase-08/test_wizard_not_yet_implemented.sh"`. Update the aggregator expected count accordingly.

After all 5 written (and 1 deleted):
   - `bash tests/phase-08/run.sh` reports `PHASE 08 TESTS: 13/13` and exits 0. (9 from Plan 02 - 1 deleted + 5 from Plan 03 = 13.)
  </action>
  <verify>
    <automated>bash tests/phase-08/run.sh && bash tests/phase-08/run.sh 2>&1 | grep -qE 'PHASE 08 TESTS: 13/13' && [ ! -f tests/phase-08/test_wizard_not_yet_implemented.sh ]</automated>
  </verify>
  <acceptance_criteria>
    - All 5 new test files exist with shebang + `set -euo pipefail` + lib.sh source.
    - `tests/phase-08/test_wizard_not_yet_implemented.sh` has been DELETED (no longer present on disk).
    - `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 13/13` in stdout.
    - Each test exercises its WZRD requirement / review concern.
    - test_wizard_index_md.sh verifies all 3 guardrails (happy path, idempotency, duplicate-header guard) — grep the test file for 3 distinct assertion blocks.
    - test_wizard_partial_failure.sh verifies repo-root stays clean after induced failure (review concern #8).
    - `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0 (no regression).
  </acceptance_criteria>
  <done>Side-effect tests verify .wizard-answers.yaml shape, decision record schema conformance, sync-claude byte-equality, index.md edit with all 3 guardrails, and partial-failure recovery via staging-dir. Plan 02's not-yet-implemented test removed. Aggregator at 13/13.</done>
</task>

</tasks>

<verification>
1. `bash tests/phase-08/run.sh` exits 0 with `PHASE 08 TESTS: 13/13`.
2. Wizard real-run via --render-to produces all 5 artifacts deterministically (env-var-frozen time/SHA → byte-identical re-runs).
3. `cmp -s /tmp/wz/AGENTS.md /tmp/wz/CLAUDE.md` exits 0.
4. `cmp -s /tmp/wz/AGENTS.md schema/fixtures/canonical-AGENTS.md` exits 0 (Plan 02 contract preserved).
5. Decision record passes `wiki/decisions/` schema (7 sections, type=decision, trigger_type=schema-update).
6. wiki/index.md gains `## Decisions` subsection with exactly one entry; update_index_md() helper present with all 3 guardrails.
7. Induced partial-failure leaves repo-root untouched (staging-dir cleanup verified).
8. `bash bin/check-neutrality.sh && bash tests/phase-07/run.sh` exit 0.
</verification>

<success_criteria>
- Wizard produces complete personalized state (5 artifacts) end-to-end via real-run mode.
- Staging-dir + atomic-promote pattern prevents partial-state corruption on mid-init failure (review concern #8).
- update_index_md() helper isolates the fragile wiki/index.md edit with 3 guardrails: idempotency, duplicate-header, malformed recovery (review concern #2).
- template_sha resolution chain: env var > git-lookup > `<unresolved>` (review concern #9).
- Determinism harness (WIZARD_GENERATED_AT / WIZARD_TEMPLATE_SHA env vars) enables CI byte-equality testing.
- Side-effect tests (5 new) verify each artifact independently; aggregator at 13/13.
- Open Questions Q1 + Q4 resolved with guardrails.
</success_criteria>

<output>
After completion, create `.planning/phases/08-two-track-setup-wizard-manual/08-03-SUMMARY.md` capturing: exit-2 gate removal, the env-var determinism contract, the 5-artifact write inventory, staging-dir pattern chosen, update_index_md() helper's 3 guardrails, template_sha fallback chain, and the deleted `test_wizard_not_yet_implemented.sh` test.
</output>

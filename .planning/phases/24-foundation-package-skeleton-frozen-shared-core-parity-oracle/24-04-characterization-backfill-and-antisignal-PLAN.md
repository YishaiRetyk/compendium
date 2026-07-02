---
phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
plan: 04
type: execute
wave: 3
depends_on: [03]
files_modified:
  - tests/phase-24/lib.sh
  - tests/phase-24/run.sh
  - tests/phase-24/test_validate_op_characterization.sh
  - tests/phase-24/test_search_modes_characterization.sh
  - tests/phase-24/test_error_path_footprints.sh
  - tests/phase-24/test_mutating_footprint_characterization.sh
  - tests/phase-24/test_shim_preflight_exit3.sh
  - tests/goldens/validate-op/
  - tests/goldens/search/
  - tests/goldens/init-wizard/
  - tests/goldens/gen-skills/
  - tests/oracle-exempt.md
  - tests/oracle-exempt.txt
  - tests/phase-11/test_hashlib_not_sha256sum.sh
  - tests/phase-20/test_pdf_extract_markers.sh
  - tests/impl-assertion-inventory.md
  - tests/phase-24/test_impl_assertion_inventory.sh
autonomous: true
requirements: [TEST-03, TEST-04]
user_setup: []

must_haves:
  decisions:
    - "D-15: backfill coverage before any port (validate-op + untested search modes get characterization tests first)"
    - "D-16: quarantine/rewrite implementation-asserting anti-signal tests (hashlib grep, pdf-extract body-grep)"
    - "D-17: capture error-path footprints, not just happy paths (divergent exit codes incl. init-wizard 4 and 3)"
  truths:
    - "validate-op.sh (zero tests today) has 4-channel characterization goldens for all 4 ops + error/usage paths before any port"
    - "search.sh untested modes (--query, --paths-only, --fulltext) have 4-channel characterization goldens before any port"
    - "init-wizard's state-dependent error exits are captured from a WRITABLE EXTRACTED TREE (git archive <ref> | tar -x into a per-test temp dir the driver CAN seed), NOT the frozen/shared worktree: exit 4 = already-initialized is driven by placing .wizard-answers.yaml at the EXTRACTED tree's root (which IS the REPO_ROOT init-wizard computes from $0:55) and running bash <extracted>/bin/init-wizard.sh WITHOUT --dry-run so the :195 guard fires -> :221 exit 4; exit 3 = pre-flight is driven by stripping PYTHON3 ONLY from PATH (keeping git+bash+coreutils so the harness still runs) so preflight() :146-169 exits 3 (addresses REVIEWS cycle-3 HIGH finding #1)"
    - "exit-4 (and the class of $0-relative-REPO_ROOT state-dependent error paths) is recorded as ORACLE-EXEMPT / parity-exempt in tests/oracle-exempt.md WITH the WHY (the Phase-23 WIKI_IMPL=bash leg also runs from the frozen worktree and also cannot reach exit 4), so the parity matrix does not silently treat it as verifiable (addresses REVIEWS cycle-3 HIGH finding #1)"
    - "the gen-skills --check DRIFT golden (exit 1) is MANDATORY — captured deterministically from a WRITABLE EXTRACTED TREE (git archive <baseline> | tar -x, then modify a skill in the extracted tree to force drift); it is NOT optional and NOT droppable; the test FAILS if the committed tests/goldens/gen-skills/check-drift/exit golden is absent or != 1 (addresses REVIEWS cycle-3 finding #1 N-2 fold-in + cycle-4 finding #2a — closes the cycle-2 N-2 verification gap)"
    - "init-wizard exit 3 (pre-flight) has a SHIM-LEVEL preflight-preservation CONTRACT TEST asserting the FUTURE .sh shim preserves exit 3 (the pre-flight dependency check) BEFORE invoking Python — a Phase-23 compat boundary made enforceable NOW: the test drives a shim-shaped wrapper (the canonical Plan-01 shim form) with python3 stripped / a preflight-failing condition and asserts the shim itself returns exit 3 before reaching Python (addresses REVIEWS cycle-4 finding #2b — exit-3 enforced, not merely exempted)"
    - "CYCLE-6 fix #5: the exit-3 contract is BOUND to the real shipped shim population via a MANIFEST-DRIVEN loop — for each tool in tests/ported.manifest with a declared preflight contract (init-wizard→3), the test drives the REAL bin/<tool>.sh shim with the dependency stripped and asserts the contract exit before Python; empty in Phase 24, it enforces per real shim as Phase 25 appends tools; the loop mechanism is proven now via a WIKI_EXEC_ROOT-pointed scaffold with a seeded manifest entry (bare shim → 127 flagged, canonical shim → passes) — the property is no longer proven only on the synthetic exemplar"
    - "CYCLE-6 MEDIUM b: alongside the prose tests/oracle-exempt.md, a MACHINE-READABLE tests/oracle-exempt.txt is committed (one <pattern> per non-comment line — a tool name or pairing-key glob + optional reason) that Plan 05's --require-parity consumes to map a captured pairing key to its exemption; the two files are the human + machine views of ONE exemption set"
    - "happy-path / read-only goldens (validate-op, search, gen-skills in-sync exit-0) ARE captured through the worktree-backed oracle (Plan 03) — so script-relative tools resolve their real bin/-relative tree; only the STATE-DEPENDENT error paths that the frozen worktree cannot reach use the writable extracted tree"
    - "at least one MUTATING-tool golden exercises the file-tree channel (ingest or lint --fix) so the 4-channel design is proven on the case it exists for"
    - "the hashlib anti-signal test asserts the hash VALUE from the CONFIRMED emission channel (REPORT.md/applied.log sha256: line), not a sha256sum source-grep"
    - "the pdf-extract api/generate behavior is asserted against a LOCAL HTTP stub before the source-grep is removed"
    - "EVERY implementation-asserting test (lint.sh / audit-claims.sh / check-neutrality.sh / hook-command-form suites + the 2 named anti-signal tests) is INVENTORIED and classified behavioral / shim-contract / obsolete-or-deferred, and a guard fails if any UNCLASSIFIED impl-asserting test remains (addresses REVIEWS HIGH#7 / TEST-04)"
  artifacts:
    - path: "tests/phase-24/test_validate_op_characterization.sh"
      provides: "Characterization tests for UPDATE/MERGE/SUPERSEDE/ARCHIVE + error paths via invoke_tool"
      contains: "invoke_tool validate-op"
    - path: "tests/phase-24/test_error_path_footprints.sh"
      provides: "Divergent exit codes incl. init-wizard 4 (already-initialized, line 221) from a writable extracted tree + 3 (pre-flight, line 165) via python3-only PATH strip — committed exit-file goldens + the MANDATORY gen-skills drift exit-1 golden from the extracted tree (REVIEWS cycle-3 finding #1 + cycle-4 finding #2a)"
      contains: "git archive"
    - path: "tests/phase-24/test_shim_preflight_exit3.sh"
      provides: "SHIM-LEVEL exit-3 preflight-preservation contract test: drives the canonical Plan-01 shim form with python3 stripped / a preflight-failing condition and asserts the SHIM returns exit 3 BEFORE reaching Python (Phase-23 compat boundary enforced now — REVIEWS cycle-4 finding #2b)"
      contains: "exit 3"
    - path: "tests/goldens/init-wizard/"
      provides: "Committed exit-file goldens: <case>/exit == 4 (already-initialized, from a writable extracted tree) and == 3 (pre-flight dependency failure, python3-only strip)"
    - path: "tests/goldens/gen-skills/"
      provides: "Committed goldens: check-in-sync (exit 0, through the worktree oracle) AND the MANDATORY check-drift (exit 1, from a writable extracted tree) — REVIEWS cycle-4 finding #2a"
    - path: "tests/oracle-exempt.md"
      provides: "The HUMAN prose registry of oracle-exempt / parity-exempt code paths (init-wizard exit-4 + the $0-relative-REPO_ROOT state-dependent error class) with the WHY (REVIEWS cycle-3 finding #1)"
    - path: "tests/oracle-exempt.txt"
      provides: "The MACHINE-READABLE companion Plan 05's --require-parity consumes: one `<pattern>` per non-comment line (tool name or pairing-key glob) + optional TAB reason (REVIEWS cycle-6 MEDIUM b)"
    - path: "tests/phase-24/test_mutating_footprint_characterization.sh"
      provides: "A mutating-tool golden (ingest / lint --fix) exercising the file-tree channel"
    - path: "tests/goldens/validate-op/"
      provides: "Frozen 4-channel goldens (<case>/{stdout,stderr,exit,tree}) per validate-op case"
    - path: "tests/phase-11/test_hashlib_not_sha256sum.sh"
      provides: "Rewritten to assert hash VALUE from the confirmed channel (impl-agnostic)"
    - path: "tests/impl-assertion-inventory.md"
      provides: "Inventory of every impl-asserting test (lint/audit-claims/check-neutrality/hook-form) + classification + disposition (REVIEWS HIGH#7)"
    - path: "tests/phase-24/test_impl_assertion_inventory.sh"
      provides: "Guard: fails if any UNCLASSIFIED impl-asserting test remains (REVIEWS HIGH#7)"
  key_links:
    - from: "tests/phase-24/test_validate_op_characterization.sh"
      to: "tests/lib/invoke_tool.sh"
      via: "source the frozen seam + capture_footprint into tests/goldens/<tool>/<case>/"
      pattern: "source.*tests/lib/invoke_tool"
    - from: "tests/phase-24/test_error_path_footprints.sh"
      to: "a writable git-archive-extracted tree the driver seeds (.wizard-answers.yaml + a drifted skill) / python3-stripped PATH"
      via: "git archive <ref> | tar -x into a temp dir -> bash <extracted>/bin/init-wizard.sh + bash <extracted>/bin/gen-skills.sh --check"
      pattern: "git archive"
    - from: "tests/phase-24/test_shim_preflight_exit3.sh"
      to: "the canonical Plan-01 shim form (preflight-before-python) + docs/reference/python-shim-contract.md"
      via: "drive a shim-shaped wrapper with python3 stripped -> assert the shim returns exit 3 before reaching Python"
      pattern: "exit 3"
    - from: "tests/phase-11/test_hashlib_not_sha256sum.sh"
      to: "the tool's emitted hash value (confirmed channel)"
      via: "compare against sha256 of a known fixture"
      pattern: "sha256"
    - from: "tests/phase-24/test_impl_assertion_inventory.sh"
      to: "tests/impl-assertion-inventory.md"
      via: "grep the suites for impl-asserting forms and require each to be listed/classified"
      pattern: "impl-assertion-inventory"
---

<objective>
Backfill the single biggest parity-signal lever: characterization goldens (full stdout + stderr + exit code + resulting file tree, 4 channels, `<case>/` layout) for the two zero/under-tested surfaces (`validate-op.sh` and `search.sh` modes) BEFORE any port, plus error-path footprints for EVERY genuinely-divergent exit code — INCLUDING `init-wizard` exit 4 (already-initialized, source line 221) and exit 3 (pre-flight dependency failure, source line 165), each as a COMMITTED `exit`-file golden — plus the MANDATORY gen-skills `--check` DRIFT (exit 1) golden, plus a SHIM-LEVEL exit-3 preflight-preservation contract test, plus at least one MUTATING-tool golden so the file-tree channel is actually exercised. Then fix the anti-signal tests AND inventory every remaining implementation-asserting test:
(1) rewrite the `hashlib`-not-`sha256sum` test to assert the hash VALUE from the CONFIRMED emission channel;
(2) replace the `pdf-extract` `api/generate` source-grep with a LOCAL HTTP stub behavior assertion;
(3) produce `tests/impl-assertion-inventory.md` cataloguing EVERY impl-asserting test in `lint.sh`/`audit-claims.sh`/`check-neutrality.sh`/hook-command-form suites with a classification + disposition, plus a guard that fails on any UNCLASSIFIED impl-asserting test.

Purpose (D-15/D-16/D-17): "No test = zero parity signal." Happy-path goldens captured through the worktree-backed frozen seam (Plan 03) freeze today's bash behavior so Phase-23's `WIKI_IMPL=py` is diffed against it. CYCLE-2 + CYCLE-3 + CYCLE-4 REVIEWS:
- CYCLE-3 HIGH finding #1 (init-wizard exit-4 unproducible through the worktree oracle): SOURCE-VERIFIED — `bin/init-wizard.sh:55` derives `REPO_ROOT="$(cd "$SCRIPT_DIR/.." ...)"` from `$0` (= the script's own location = the FROZEN WORKTREE ROOT when run through the oracle), NOT from cwd. The exit-4 guard (`:195` `[ "$DRY_RUN" -eq 0 ] && [ -f "$REPO_ROOT/.wizard-answers.yaml" ]`) checks `<worktree>/.wizard-answers.yaml`. `.wizard-answers.yaml` is NOT git-tracked (`git ls-files` empty), so it is ABSENT from any frozen worktree, AND the frozen/shared worktree cannot be seeded. Therefore the cycle-2 driver ("`cd "$FIXTURE_REPO"` so PWD-based resolution sees the seeded .wizard-answers.yaml") is INERT — init-wizard is NOT PWD-based. This plan captures init-wizard's state-dependent error paths from a WRITABLE EXTRACTED TREE the driver CAN seed (the oracle's documented `git archive <ref> | tar -x` fallback into a per-test temp dir), placing `.wizard-answers.yaml` at THAT tree's root (which IS the REPO_ROOT init-wizard computes from `$0`), and marks exit-4 (and the class of `$0`-relative-REPO_ROOT state-dependent error paths) ORACLE-EXEMPT in `tests/oracle-exempt.md` because the Phase-23 `WIKI_IMPL=bash` leg ALSO runs from the frozen worktree and ALSO cannot reach exit 4.
- CYCLE-3 finding #1 exit-3 driver fix: the cycle-2 driver "PATH=/nonexistent" / "a PATH lacking git/python3" is UNSOUND because it also breaks the oracle/seam (`oracle-worktree.sh` needs `git`; `invoke_tool` needs `mktemp`). This plan strips PYTHON3 ONLY (keeping git + bash + coreutils on PATH) so `preflight()` (`:146-169`) exits 3 while the harness still runs.
- CYCLE-3 finding #1 N-2 fold-in → CYCLE-4 finding #2a (MANDATORY, NOT optional): the gen-skills `--check` DRIFT golden (exit 1) is ALSO unreachable through the frozen worktree (`gen-skills.sh:32 cd "$REPO_ROOT"` compares `<wt>/.claude/skills` vs `<wt>/schema`, in-sync in a pristine frozen checkout). The cycle-3 plan made this an OPTIONAL pick-one (capture-from-extracted-tree OR drop-with-rationale). Codex's cycle-4 review found that DROPPING the drift golden re-opens the cycle-2 N-2 verification gap (the exit-1 drift path would never be frozen). So this plan makes the gen-skills drift (exit-1) golden MANDATORY: captured deterministically from the writable extracted tree (`git archive "$(_oracle_baseline_ref)" | tar -x`, then modify a skill in the extracted tree to force drift). It is NOT optional and NOT droppable; the test FAILS if the committed `tests/goldens/gen-skills/check-drift/exit` golden is absent or != `1`.
- CYCLE-4 finding #2b (exit-3 SHIM-LEVEL preflight-preservation CONTRACT TEST): the cycle-3 plan marked init-wizard exit 3 (pre-flight) parity-EXEMPT in `tests/oracle-exempt.md` without any enforcement that the FUTURE `.sh` shim preserves exit 3 for Phase 25. exit 3 is a dependency-PRESENCE check (`preflight()` exits 3 if python3 is missing) — a Python port CANNOT detect "python3 missing" from inside python3, so the `.sh` shim MUST preserve the pre-flight before invoking Python. This plan adds a SHIM-LEVEL contract test (`tests/phase-24/test_shim_preflight_exit3.sh`) that drives the canonical Plan-01 shim form (with a preflight gate) with python3 stripped / a preflight-failing condition and asserts the SHIM ITSELF returns exit 3 BEFORE reaching Python — making the Phase-23 compat boundary enforceable now, not merely exempted.
- CYCLE-2 HIGH#1 ripple (preserved): happy-path / read-only goldens (validate-op, search, gen-skills in-sync exit-0) are captured through Plan 03's WORKTREE oracle, so gen-skills runs from its real `bin/`-relative tree and the golden records its REAL exit code.
- CYCLE-2 HIGH#7 (TEST-04): the prior plan fixed only 2 named anti-signal tests. Other suites still inspect bash internals (`lint.sh`, `audit-claims.sh`, `check-neutrality.sh`, hook command forms). This plan inventories ALL of them with dispositions and a guard.

Output: a `tests/phase-24/` suite (characterization + error-path + shim-preflight-exit3 + mutating-footprint + inventory-guard tests), `tests/goldens/{validate-op,search,init-wizard,gen-skills}/` frozen footprints (incl. the MANDATORY gen-skills drift exit-1 golden), `tests/oracle-exempt.md`, the two fixed anti-signal test files, and `tests/impl-assertion-inventory.md`.

CRITICAL: This plan captures happy-path goldens against the worktree-backed held-fixed `WIKI_IMPL=bash` oracle (Plan 03), and state-dependent error-path goldens (init-wizard exit 4, gen-skills drift exit 1) from a writable git-archive-extracted tree. It does NOT port anything. The goldens are the frozen reference Phase 25 diffs against. (Wave 3: depends on Plan 03's seam + oracle + conftest.)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-CONTEXT.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md

<interfaces>
<!-- The frozen seam from Plan 03 (source it; do not redefine). NOTE the case-dir layout + worktree oracle: -->
tests/lib/invoke_tool.sh   -> invoke_tool <tool> [args...]  (sets IT_STDOUT/IT_STDERR/IT_EXIT; ALWAYS returns 0 — read IT_EXIT);
                              capture_footprint <repo> <case-dir>  (writes <case-dir>/{stdout,stderr,exit,tree});
                              assert_parity <bash-case-dir> <py-case-dir>
tests/lib/oracle-worktree.sh -> the bash leg runs <worktree>/bin/<tool>.sh (full bin/-relative tree) — so gen-skills, audit-claims, brownfield resolve their real libs/REPO_ROOT (REVIEWS HIGH#1). _oracle_baseline_ref resolves the pinned ref; the documented `git archive <ref> | tar -x` fallback is what THIS plan reuses for the writable extracted tree.
tests/lib/normalize.sh     -> normalize  (stdin->stdout; time-bearing TS only)

<!-- The Plan-01 shim contract doc the exit-3 shim-level test reads (cycle-4 finding #2b): -->
docs/reference/python-shim-contract.md -> §4 names init-wizard exit 3 (pre-flight) as a Phase-23 COMPAT BOUNDARY the .sh shim must preserve BEFORE invoking Python; the canonical shim form (§1) is the wrapper the contract test drives.

<!-- validate-op.sh surface to cover (bin/validate-op.sh): -->
4 ops: UPDATE | MERGE | SUPERSEDE | ARCHIVE  (case at ~205-206)
exit 0 = all PASS ; exit 1 = any FAIL or usage error  (~34-35)
ARCHIVE rejects already-archived (~94) ; SUPERSEDE rejects already-superseded (~98)
MERGE requires two DISTINCT paths (~215-219)

<!-- search.sh modes to cover (bin/search.sh): --query "Q" (~127), --paths-only (~147), --fulltext (~151), missing-arg exit-1 (~111-112/129-130) -->

<!-- SOURCE-VERIFIED init-wizard.sh facts (REVIEWS cycle-3 finding #1): -->
bin/init-wizard.sh:54-55 -> SCRIPT_DIR="$(cd "$_script_dir" ...)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." ...)"  ($0-RELATIVE — REPO_ROOT = the script's own tree, NOT cwd)
bin/init-wizard.sh:146-169 -> preflight(): checks bash>=4 / git / python3; exits 3 at :165 if any missing (runs BEFORE the already-init guard)
bin/init-wizard.sh:195   -> if [ "$DRY_RUN" -eq 0 ] && [ -f "$REPO_ROOT/.wizard-answers.yaml" ]; then  (guard for already-initialized)
bin/init-wizard.sh:221   -> exit 4 = REFUSED / already-initialized
<!-- .wizard-answers.yaml is NOT git-tracked (confirmed: git ls-files empty) -> absent from any frozen worktree, frozen worktree cannot be seeded. -->
<!-- DRIVE exit 4 (finding #1): git archive <baseline-ref> | tar -x into a per-test temp dir <EXT>; place <EXT>/.wizard-answers.yaml;
     run `bash <EXT>/bin/init-wizard.sh` (NO --dry-run) -> REPO_ROOT resolves to <EXT> from $0 -> :195 guard true -> :221 exit 4. -->
<!-- DRIVE exit 3 (finding #1): strip PYTHON3 ONLY from PATH (keep git+bash+coreutils so the harness/seam still runs):
     run init-wizard with a PATH dir that omits python3 (but has git/bash/coreutils) -> preflight() collects "python3 not found" -> exit 3 at :165. -->

<!-- gen-skills.sh:30-32 -> SCRIPT_DIR/.. + cd "$REPO_ROOT"; --check compares <REPO_ROOT>/.claude/skills vs <REPO_ROOT>/schema.
     In a pristine frozen worktree these are IN SYNC (exit 0). To capture exit-1 DRIFT (N-2 / cycle-4 finding #2a — MANDATORY):
     modify a skill in a writable EXTRACTED tree to force drift (e.g. append a line to <EXT>/.claude/skills/<op>/SKILL.md),
     run `bash <EXT>/bin/gen-skills.sh --check`, assert exit 1, capture the golden. DO NOT drop this golden. -->

<!-- mutating tool for the file-tree channel: ingest (writes a source dir) OR lint --fix (rewrites stale markers / has_contradictions). Pick one that mutates deterministically on a small fixture. -->

<!-- CONFIRMED brownfield hash-emission channel (bin/brownfield.sh):
     hashing is `sha256:` + hashlib.sha256(...).hexdigest()  (lines ~790-811); op_hash headers are written
     into migrated scripts (lines 2+3) and the per-script hash block is recorded in applied.log / the bootstrap
     REPORT.md (report_path ~438-448), NOT plain stdout. The rewrite must parse the REPORT.md/applied.log
     `sha256:` line, NOT stdout. -->

<!-- anti-signal tests to fix: -->
tests/phase-11/test_hashlib_not_sha256sum.sh  (~14-44 greps bin/brownfield.sh + schema/brownfield/migrations/*.sh for literal 'sha256sum')
tests/phase-20/test_pdf_extract_markers.sh    (line 32 `grep -q 'api/generate'`; line 28 `! grep -q 'ollama run'`; KEEP marker-count asserts ~72-87 + Ollama SKIP ~53)

<!-- impl-asserting test SURFACES to inventory (REVIEWS HIGH#7) — tests that read bash SOURCE / assert bash internals: -->
tests/phase-09/, tests/phase-12.1/, tests/phase-12.2/, tests/phase-13/  (lint.sh + audit-claims.sh internals)
tests/phase-12.1/, tests/phase-09/  (check-neutrality.sh internals)
tests/phase-07/, tests/phase-09/   (hook-command-form suites — .githooks/pre-commit command shapes)
<!-- the inventory grep targets: `grep .* bin/<tool>.sh` source-reads, `cat bin/...`, assertions on bash function names / heredoc strings -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Characterization goldens for validate-op + search modes (through the oracle) + ALL divergent error paths (init-wizard exit 4 from a WRITABLE EXTRACTED TREE + exit 3 via python3-only PATH strip + the MANDATORY gen-skills drift exit-1 golden + the oracle-exempt registry) + a mutating-tool golden</name>
  <files>tests/phase-24/lib.sh, tests/phase-24/run.sh, tests/phase-24/test_validate_op_characterization.sh, tests/phase-24/test_search_modes_characterization.sh, tests/phase-24/test_error_path_footprints.sh, tests/phase-24/test_mutating_footprint_characterization.sh, tests/goldens/validate-op/, tests/goldens/search/, tests/goldens/init-wizard/, tests/goldens/gen-skills/, tests/oracle-exempt.md, tests/oracle-exempt.txt</files>
  <read_first>
    - bin/validate-op.sh (READ the op dispatch ~205-219, exit codes ~34-35, already-archived/already-superseded rejections ~94/98, print_check shape ~264 — every channel + every op + the usage-error exit-1 path)
    - bin/search.sh (READ the mode dispatch — --query ~127, --paths-only ~147, --fulltext ~151, missing-arg exit-1 ~111-112/129-130)
    - bin/init-wizard.sh (READ lines 54-55 [REPO_ROOT from $0, NOT cwd], 146-169 [preflight() exit 3 at :165 — checks bash>=4/git/python3], 190-221 [already-initialized guard at :195 -> exit 4 at :221], the header exit-code map ~89, AND the --dry-run / --answers-file / --render-to flags — so you know EXACTLY that the exit-4 driver must seed .wizard-answers.yaml at the EXTRACTED tree's ROOT (= REPO_ROOT from $0), NOT the caller cwd; and that exit-3 needs python3 stripped only — REVIEWS cycle-3 finding #1)
    - bin/gen-skills.sh (READ lines 28-40 — REPO_ROOT=$SCRIPT_DIR/.. + cd "$REPO_ROOT" + the schema/workflows existence check; confirm WHY the in-sync exit-0 golden goes through the worktree oracle but the drift exit-1 case needs a writable extracted tree; identify a deterministic skill-edit that forces drift — REVIEWS cycle-3 finding #1 N-2 / cycle-4 finding #2a MANDATORY)
    - bin/ingest.sh OR bin/lint.sh (the mutating tool for the file-tree golden — ingest writes a source dir; lint --fix rewrites markers; pick the one with a small deterministic mutation)
    - tests/phase-10/lib.sh (read assert_byte_equal ~41-54 + make_fixture_repo ~20-36 + the run.sh aggregator pattern)
    - tests/phase-09/run.sh (the run.sh aggregator shape to mirror for tests/phase-24/run.sh)
    - tests/lib/invoke_tool.sh + tests/lib/oracle-worktree.sh + tests/lib/normalize.sh (Plan 03 — source these; capture_footprint writes <case-dir>/{stdout,stderr,exit,tree}; the bash leg runs the WORKTREE oracle; _oracle_baseline_ref resolves the pinned ref the `git archive` extraction uses)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the characterization-goldens section — validate-op + search surfaces + storage layout)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (cycle-3 finding #1 [init-wizard exit 4 from a writable extracted tree + oracle-exempt mark; exit 3 strip python3 only; gen-skills drift N-2 fold-in], HIGH#1 ripple [happy-path goldens through the worktree oracle], cycle-4 finding #2a [gen-skills drift golden MANDATORY, not droppable])
  </read_first>
  <action>
**Suite scaffolding.** Create `tests/phase-24/lib.sh` that resolves `$REPO_ROOT` (mirror `tests/phase-10/lib.sh`) and `source`s the FROZEN seam: `source "$REPO_ROOT/tests/lib/invoke_tool.sh"` (which itself sources `oracle-worktree.sh` + `normalize.sh`). Re-use the existing `make_fixture_repo`/`assert_byte_equal`/`assert_exit_code` vocabulary by sourcing a phase lib OR defining thin local equivalents (do NOT modify the existing phase libs — D-13). ALSO define a local helper `extract_writable_tree()` that creates the writable extracted tree the state-dependent error paths use: `local ext; ext="$(mktemp -d)"; git -C "$REPO_ROOT" archive "$(_oracle_baseline_ref)" | tar -x -C "$ext"; printf '%s\n' "$ext"` (reuse the same baseline ref the oracle reads — Plan 03's `_oracle_baseline_ref`). Create `tests/phase-24/run.sh` as a `test_*.sh` aggregator mirroring `tests/phase-09/run.sh` — it MUST iterate via the `for t in "$SCRIPT_DIR"/test_*.sh` glob (CONFIRMED shape in tests/phase-09/run.sh:27-28) so EVERY `test_*.sh` in the dir (including Task 2's `test_shim_preflight_exit3.sh`, Task 3's `test_impl_assertion_inventory.sh`, and Plan 06's later-added `test_freeze_guard.sh`/`test_precommit_hooks.sh`) is AUTO-DISCOVERED with NO further edit to run.sh.

**Golden storage layout** — use the Plan-03 `<case>/{stdout,stderr,exit,tree}` directory layout (one DIRECTORY per case). For HAPPY-PATH / read-only goldens, generate each by running the tool through `invoke_tool` (the WORKTREE oracle) against a seeded fixture repo, then `capture_footprint <repo> tests/goldens/<tool>/<case>`. COMMIT these golden dirs. The test then re-runs the same invocation, re-captures to a temp case dir, and `assert_parity tests/goldens/<tool>/<case> <temp-case-dir>`. Because `invoke_tool` ALWAYS returns 0 (Plan 03 HIGH#2 fix), read `$IT_EXIT` after each call.

**`test_validate_op_characterization.sh`** — all 4 ops + error paths (through the oracle). For each: seed a fixture repo, `invoke_tool validate-op <op> <args>; rc=$IT_EXIT`, capture/assert a 4-channel golden:
- UPDATE on an existing page (exit 0).
- MERGE with two distinct existing pages (exit 0).
- MERGE with the SAME path twice (distinct-path rejection ~215-219) — assert exit code + stderr.
- SUPERSEDE on a normal page (exit 0) AND on an already-superseded page (rejection ~98).
- ARCHIVE on a normal page (exit 0) AND on an already-archived page (rejection ~94).
- No args / bad op -> usage error exit 1.

**`test_search_modes_characterization.sh`** — the untested modes (through the oracle):
- `--query "some query"` (~127), `--paths-only` (~147), `--fulltext` (~151), missing-arg -> exit 1 (~111-112/129-130). Seed a small wiki-cloud/index.md + a couple of pages. 4-channel golden per mode.

**`test_error_path_footprints.sh`** (D-17 + REVIEWS cycle-3 finding #1 + cycle-4 finding #2a) — capture EVERY genuinely-divergent exit code; init-wizard exits 4 AND 3 captured with COMMITTED exit-file goldens; the gen-skills DRIFT exit-1 golden is MANDATORY; the STATE-DEPENDENT init-wizard + gen-skills-drift paths use a WRITABLE EXTRACTED TREE, not the frozen worktree:
- `invoke_tool sync-claude --check` on a drifted AGENTS/CLAUDE pair -> exit 2 (through the oracle; golden `tests/goldens/sync-claude/<case>/`).
- `invoke_tool gen-skills --check` IN-SYNC -> exit 0 — captured THROUGH the worktree oracle so gen-skills resolves its real REPO_ROOT (REVIEWS HIGH#1 ripple); golden `tests/goldens/gen-skills/check-in-sync/` proving the worktree oracle does not report false drift.
- **gen-skills `--check` DRIFT -> exit 1 (MANDATORY — REVIEWS cycle-3 finding #1 N-2 / cycle-4 finding #2a).** The frozen worktree is in-sync, so this CANNOT be driven through the oracle. Capture it from a WRITABLE EXTRACTED TREE — this is REQUIRED, not optional, not droppable: `ext="$(extract_writable_tree)"`, modify a skill so `<ext>/.claude/skills` drifts from `<ext>/schema` (e.g. append a line to a `<ext>/.claude/skills/<op>/SKILL.md`), run `bash "$ext/bin/gen-skills.sh" --check; rc=$?`, assert `rc == 1`, `capture_footprint "$ext" tests/goldens/gen-skills/check-drift/`, COMMIT, assert the committed `tests/goldens/gen-skills/check-drift/exit` == `1`. DO NOT drop this golden — dropping it re-opens the cycle-2 N-2 verification gap (Codex cycle-4 finding #2a). (gen-skills drift is recorded in `tests/oracle-exempt.md` as "frozen-worktree-unreachable" ONLY to document that the IN-SYNC oracle leg cannot reach it; the committed exit-1 golden from the extracted tree IS the frozen drift reference and is mandatory.)
- **init-wizard exit 4 (already-initialized — source line 221; REVIEWS cycle-3 finding #1):** the cycle-2 "`cd "$FIXTURE_REPO"` seeds PWD" driver is INERT — init-wizard derives REPO_ROOT from `$0` (:55), not cwd, and `.wizard-answers.yaml` is NOT tracked so the frozen worktree has none and cannot be seeded. Instead: `ext="$(extract_writable_tree)"` (git archive <baseline> | tar -x into a temp dir), `printf 'x\n' > "$ext/.wizard-answers.yaml"` (place it at the EXTRACTED tree's ROOT = the REPO_ROOT init-wizard computes from `$0`), then run `bash "$ext/bin/init-wizard.sh"` WITHOUT `--dry-run` (so the `:195` guard `[ "$DRY_RUN" -eq 0 ] && [ -f "$REPO_ROOT/.wizard-answers.yaml" ]` fires) and capture its exit: `if bash "$ext/bin/init-wizard.sh" </dev/null >out 2>err; then rc=0; else rc=$?; fi`. Assert `rc == 4`. `capture_footprint "$ext" tests/goldens/init-wizard/already-initialized/` (or write the channels manually from out/err/rc into the `<case>/{stdout,stderr,exit,tree}` layout); COMMIT it; assert the committed `tests/goldens/init-wizard/already-initialized/exit` contains the literal `4`. (Pipe `</dev/null` so any interactive prompt past the guard cannot hang — but the guard exits 4 before prompting.)
- **init-wizard exit 3 (pre-flight dependency failure — source line 165; REVIEWS cycle-3 finding #1):** the cycle-2 "PATH=/nonexistent" / "PATH lacking git/python3" driver is UNSOUND (it breaks the seam/oracle which need git+mktemp). Strip PYTHON3 ONLY, keeping git+bash+coreutils on PATH so `preflight()` (`:146-169`) collects exactly "python3 not found" and exits 3 while the harness still runs. Build a minimal PATH dir that symlinks/has `bash git mktemp sed find sort cut stat readlink sha256sum tr grep` but NOT `python3` (or copy the current PATH dirs and shadow python3 with a non-executable stub earlier in PATH — read the script to choose the minimal omission that reaches :165 before any earlier exit). Run from a writable extracted tree (to avoid touching the frozen worktree): `ext="$(extract_writable_tree)"`, `( PATH="$STUBDIR"; bash "$ext/bin/init-wizard.sh" --dry-run </dev/null >out 2>err ); rc=$?` and assert `rc == 3`. `capture_footprint` into `tests/goldens/init-wizard/preflight-missing-dep/`; COMMIT; assert the committed `exit` file contains the literal `3`. Record in the SUMMARY that exit 3 is a dependency-PRESENCE check that MOVES INTO THE SHIM in Phase 25 (a Python port cannot check "is python3 missing" from inside python3) — the SHIM-LEVEL preservation of exit 3 is enforced by Task 2's `test_shim_preflight_exit3.sh` (cycle-4 finding #2b) AND noted in `tests/oracle-exempt.md`.
- a checker (`check-privacy`/`check-neutrality`/`check-sources-cloud-safe`) on a violating fixture -> exit 2 (through the oracle).
- `invoke_tool lint --ci --format json` vs text mode (dual-mode exit codes, through the oracle).
- a malformed-YAML page through lint -> the malformed-YAML stderr/exit path (through the oracle).

**`tests/oracle-exempt.md` (REVIEWS cycle-3 finding #1 — the parity-exempt registry).** Create a committed markdown table of code paths that CANNOT be verified through the held-fixed worktree oracle and are therefore parity-EXEMPT, each WITH the WHY, so the parity matrix (Plan 05) does not silently treat them as verifiable. At minimum:
- `init-wizard exit 4 (already-initialized, line 221)` — WHY: REPO_ROOT is `$0`-relative (:55) = the frozen worktree root; `.wizard-answers.yaml` is not git-tracked so the frozen worktree never has it AND cannot be seeded; the Phase-23 `WIKI_IMPL=bash` leg ALSO runs from the frozen worktree and ALSO cannot reach exit 4 — so there is no bash-vs-py differential to assert. The committed exit-4 golden (captured from a writable extracted tree) freezes the COMPAT BOUNDARY for documentation, but it is NOT a parity-checked case.
- the class of `$0`-relative-REPO_ROOT STATE-DEPENDENT error paths (any error gated by a non-tracked file at REPO_ROOT) — same root cause.
- `init-wizard exit 3 (pre-flight python3-missing, line 165)` — WHY: a dependency-PRESENCE check that moves INTO THE SHIM in Phase 25 (a python port cannot detect "python3 missing" from inside python3); it is parity-exempt for the python-MODULE diff, BUT it is NOT unenforced — the SHIM-LEVEL preservation of exit 3 is enforced by `tests/phase-24/test_shim_preflight_exit3.sh` (cycle-4 finding #2b). Cross-reference that test here so a reader knows exit-3 is a tested compat boundary, not a silent exemption.
- `gen-skills --check IN-SYNC oracle leg cannot reach DRIFT (exit 1)` — WHY: the frozen worktree is always in-sync, so the oracle's gen-skills `--check` always exits 0; the DRIFT exit-1 reference is the MANDATORY committed golden captured from a writable extracted tree (`tests/goldens/gen-skills/check-drift/`), NOT a parity diff against the in-sync oracle. The drift golden is NOT dropped (cycle-4 finding #2a).
Header: this registry IS the cycle-3 finding #1 deliverable; Plan 05's parity matrix and any future parity-coverage audit MUST treat listed paths as parity-exempt (their goldens are documentation of the compat boundary, not bash-vs-py diffs) — EXCEPT where a dedicated contract test enforces a compat boundary (exit-3 shim test), which is named inline.

**`tests/oracle-exempt.txt` — the MACHINE-READABLE companion (REVIEWS cycle-6 MEDIUM b).** The prose `.md` has no machine-readable mapping from a captured call to its exemption, so Plan 05's `--require-parity` had to match ad-hoc. Author a committed `tests/oracle-exempt.txt` that Plan 05's `--require-parity` CONSUMES: one exemption per non-comment line as `<pattern>` optionally followed by a TAB + human reason, where `<pattern>` matches either a bare TOOL NAME (e.g. `init-wizard`) or a capture PAIRING-KEY glob (e.g. `*/init-wizard-*`). `#`-prefixed and blank lines are ignored. At minimum include a line for each exempt case the `.md` documents — e.g.:
```
# tests/oracle-exempt.txt — machine-readable parity-exempt patterns consumed by run-all-suites.sh --require-parity (cycle-6 MEDIUM b).
# <pattern><TAB><reason>.  <pattern> = a tool name or a capture pairing-key glob.  Keep CONSISTENT with tests/oracle-exempt.md.
init-wizard	exit-4 already-initialized + exit-3 preflight are $0-relative / dependency-presence paths, not python-module parity-verifiable (exit-3 enforced by test_shim_preflight_exit3.sh)
```
The `.txt` MUST stay consistent with the `.md` prose (same set of exempt tools/cases) — the `.md` is the human rationale, the `.txt` is the consumed form. Do NOT list gen-skills drift here (its exit-1 golden IS a mandatory committed reference, not a parity-exempt path). Record in the SUMMARY that the two files are the human + machine views of ONE exemption set.

**`test_mutating_footprint_characterization.sh`** (exercise the file-tree channel, through the oracle). Pick ONE deterministically-mutating invocation and capture its 4-channel golden where the `tree` channel is the LOAD-BEARING signal:
- e.g. `invoke_tool ingest <args>` (writes a new source dir) OR `invoke_tool lint --fix <fixture>` (rewrites a stale marker / has_contradictions field). Seed a fixture repo, invoke through the seam, `capture_footprint` into `tests/goldens/<tool>/<mutating-case>`, and assert the tree channel records the mutation. REVIEWS L-1 (mutating-golden determinism): if the chosen tool embeds a bare run-date in a written report (e.g. `lint --fix` rewriting `wiki-cloud/maintenance/lint-report.md`), VERIFY the `tree` channel is stable across two captures (capture twice, `cmp` the two `tree` files); if a non-deterministic bare date leaks into the hashed report content, either pick a different mutating case OR inject a frozen `now` for that case (case-specific, never widen the shared normalizer). Document the chosen tool/case + the determinism check in the SUMMARY.

Make all test files executable. Run them so the goldens are GENERATED and committed (happy-path through the worktree-backed bash oracle; state-dependent error paths from the writable extracted tree). Do NOT port any tool. Do NOT route the existing 09-20 suites through the seam (Plan 05).

NOTE on baseline reality: `validate-op`/`search`/init-wizard/gen-skills-drift/the mutating case are NEW coverage — these new tests MUST pass green at HEAD against the bash oracle / extracted tree (they are your own goldens). Characterization = freeze what IS; if a happy path errors, capture that real behavior as the golden.
  </action>
  <verify>
    <automated>chmod +x tests/phase-24/*.sh && bash tests/phase-24/run.sh; echo "phase-24 run exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `test -d tests/phase-24 && test -f tests/phase-24/run.sh` exits 0
    - `grep -q 'source.*tests/lib/invoke_tool.sh' tests/phase-24/lib.sh` exits 0 (uses the frozen seam)
    - `grep -qE 'git archive|extract_writable_tree' tests/phase-24/lib.sh` exits 0 (the writable-extracted-tree helper exists — REVIEWS cycle-3 finding #1)
    - `grep -q 'invoke_tool validate-op' tests/phase-24/test_validate_op_characterization.sh` exits 0
    - `grep -cE 'UPDATE|MERGE|SUPERSEDE|ARCHIVE' tests/phase-24/test_validate_op_characterization.sh` returns 4 or more
    - `grep -cE '\-\-query|\-\-paths-only|\-\-fulltext' tests/phase-24/test_search_modes_characterization.sh` returns 3 or more
    - `grep -qE 'init-wizard|init_wizard' tests/phase-24/test_error_path_footprints.sh` exits 0 (init-wizard error paths captured NOW — REVIEWS cycle-3 finding #1)
    - `grep -qE 'git archive|extract_writable_tree' tests/phase-24/test_error_path_footprints.sh && grep -q 'wizard-answers' tests/phase-24/test_error_path_footprints.sh` exits 0 (exit-4 driven from a WRITABLE EXTRACTED TREE seeded with .wizard-answers.yaml, NOT the inert cd-PWD driver — REVIEWS cycle-3 finding #1)
    - `! grep -qiE 'cd .*FIXTURE_REPO.*PWD-based|PWD-based resolution.*sees' tests/phase-24/test_error_path_footprints.sh` (the INERT cycle-2 PWD-seed driver is NOT used — REVIEWS cycle-3 finding #1)
    - `grep -qiE 'python3|PYTHON3' tests/phase-24/test_error_path_footprints.sh && ! grep -qE 'PATH=/nonexistent' tests/phase-24/test_error_path_footprints.sh` (exit-3 strips PYTHON3 only, NOT the whole PATH — REVIEWS cycle-3 finding #1)
    - `test -f tests/goldens/init-wizard/already-initialized/exit && grep -qx '4' tests/goldens/init-wizard/already-initialized/exit` exits 0 (COMMITTED exit-4 golden for already-initialized = source line 221 — REVIEWS cycle-3 finding #1; captured from a writable extracted tree)
    - `test -f tests/goldens/init-wizard/preflight-missing-dep/exit && grep -qx '3' tests/goldens/init-wizard/preflight-missing-dep/exit` exits 0 (COMMITTED exit-3 golden for pre-flight = source line 165)
    - `test -f tests/oracle-exempt.md && grep -qiE 'init-wizard|exit 4|exit-4' tests/oracle-exempt.md && grep -qiE 'WIKI_IMPL=bash.*frozen worktree|frozen worktree.*cannot reach|0-relative|REPO_ROOT' tests/oracle-exempt.md` exits 0 (the oracle-exempt registry records exit-4 + the $0-relative class WITH the WHY — REVIEWS cycle-3 finding #1)
    - `test -f tests/oracle-exempt.txt && grep -q 'init-wizard' tests/oracle-exempt.txt && [ "$(grep -vcE '^#|^$' tests/oracle-exempt.txt)" -ge 1 ]` exits 0 (CYCLE-6 MEDIUM b: the MACHINE-READABLE companion exists with ≥1 pattern line for --require-parity to consume — one exemption per non-comment line)
    - `grep -qiE 'exit 3.*shim|shim.*exit 3|test_shim_preflight_exit3' tests/oracle-exempt.md` exits 0 (the exit-3 exemption CROSS-REFERENCES the shim-level contract test — exit-3 is enforced not silently exempted — cycle-4 finding #2b)
    - `grep -q 'gen-skills' tests/phase-24/test_error_path_footprints.sh && test -d tests/goldens/gen-skills` exits 0 (gen-skills --check in-sync golden captured through the worktree oracle — REVIEWS HIGH#1 ripple)
    - `test -f tests/goldens/gen-skills/check-drift/exit && grep -qx '1' tests/goldens/gen-skills/check-drift/exit` exits 0 (the gen-skills drift golden is MANDATORY exit-1, captured from a writable extracted tree — REVIEWS cycle-4 finding #2a; NOT optional, NOT dropped)
    - `! grep -qiE 'drift.*dropped|drop.*drift golden|OR drop' tests/phase-24/test_error_path_footprints.sh` (the cycle-3 optional "drop the drift golden" branch is GONE — the drift golden is now mandatory — cycle-4 finding #2a)
    - `test -f tests/phase-24/test_mutating_footprint_characterization.sh && grep -qE 'invoke_tool (ingest|lint)' tests/phase-24/test_mutating_footprint_characterization.sh` exits 0 (mutating-tool golden present)
    - `ls -d tests/goldens/validate-op/*/ | wc -l` returns 4 or more (one case DIR per op/case)
    - `test -f "$(ls -d tests/goldens/validate-op/*/ | head -1)exit"` exits 0 (4-channel: exit file inside the case dir — <case>/exit layout)
    - `find tests/goldens -name tree | wc -l` is non-zero (file-tree channel captured)
    - `bash tests/phase-24/run.sh` exits 0 (the new characterization suite is green against the worktree bash oracle + the writable-extracted-tree error paths)
    - `git diff --name-only HEAD -- bin/ | wc -l` returns `0` (no tool ported)
  </acceptance_criteria>
  <done>tests/phase-24/ captures 4-channel <case>/-layout goldens for all 4 validate-op ops + error paths, the 3 search modes (through the worktree oracle), EVERY divergent exit code INCLUDING init-wizard exit 4 (already-initialized, line 221) from a WRITABLE EXTRACTED TREE seeded with .wizard-answers.yaml and exit 3 (pre-flight, line 165) via a python3-ONLY PATH strip as COMMITTED exit-file goldens (REVIEWS cycle-3 finding #1), the gen-skills --check in-sync golden through the worktree oracle + the MANDATORY drift exit-1 golden captured from a writable extracted tree (REVIEWS cycle-4 finding #2a — not droppable), the oracle-exempt registry (tests/oracle-exempt.md) marking exit-4 + the $0-relative state-dependent class parity-exempt WITH the WHY and CROSS-REFERENCING the exit-3 shim contract test, and a mutating-tool golden (with a determinism check); suite green; no tool ported.</done>
</task>

<task type="auto">
  <name>Task 2: Rewrite the hashlib anti-signal test (confirmed channel); replace the pdf-extract source-grep with a LOCAL HTTP stub behavior assertion; add the SHIM-LEVEL exit-3 preflight-preservation contract test (cycle-4 finding #2b)</name>
  <files>tests/phase-11/test_hashlib_not_sha256sum.sh, tests/phase-20/test_pdf_extract_markers.sh, tests/phase-24/test_shim_preflight_exit3.sh</files>
  <read_first>
    - tests/phase-11/test_hashlib_not_sha256sum.sh (READ FULLY — the source-grep at ~14-44 over bin/brownfield.sh + schema/brownfield/migrations/*.sh for literal 'sha256sum')
    - bin/brownfield.sh (CONFIRM the hash-emission channel: hashing is `sha256:` + hashlib.sha256 at ~790-811; the op_hash/per-script hash is written to applied.log / REPORT.md [report_path ~438-448], NOT plain stdout. Identify the EXACT op + the EXACT file/line the rewrite parses.)
    - tests/phase-20/test_pdf_extract_markers.sh (READ FULLY — line 32 `grep -q 'api/generate'`, line 28 `! grep -q 'ollama run'`, the KEEP marker-count asserts ~72-87, the Ollama SKIP ~53)
    - bin/pdf-extract.sh (READ the HTTP POST to localhost:11434/api/generate — so the local stub can intercept it and the test can assert the tool POSTs a generate request; find any host/port override knob)
    - bin/init-wizard.sh (READ lines 146-169 — preflight(): checks bash>=4/git/python3, exits 3 at :165; this is the exit-3 behavior the SHIM must preserve BEFORE invoking Python — cycle-4 finding #2b)
    - docs/reference/python-shim-contract.md (Plan 01 — §1 canonical shim form + §4 naming init-wizard exit 3 as a Phase-23 compat boundary the shim must preserve before invoking Python; the shim-level test drives this contract — cycle-4 finding #2b)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the rewrite-anti-signal-tests section)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (MEDIUM "hashlib rewrite unverified — confirm channel"; MEDIUM "Replace PDF api/generate body-grep with a local HTTP stub before removing it"; cycle-4 finding #2b [add a shim-level exit-3 preflight-preservation contract test]; CYCLE-6 fix #5 [ADD a MANIFEST-DRIVEN loop iterating tests/ported.manifest so the exit-3 contract binds to the REAL shipped shim as Phase 25 ports it — proven now via a WIKI_EXEC_ROOT scaffold; not only the synthetic wrapper])
  </read_first>
  <action>
**Rewrite `tests/phase-11/test_hashlib_not_sha256sum.sh` (D-16).** Currently it greps `bin/brownfield.sh` + `schema/brownfield/migrations/*.sh` source for the literal `sha256sum` and FAILs if present — this false-fails a correct Python port (which uses `hashlib`). Replace the source-grep with an impl-agnostic BEHAVIOR assertion reading the CONFIRMED emission channel. The hash is emitted as a `sha256:<hex>` token written to `applied.log` / the bootstrap `REPORT.md` (NOT plain stdout). So:
1. Compute the expected value with the SAME canonicalization the tool uses (read bin/brownfield.sh `compute_op_hash` / `sha256_file` ~790-811 to match its input). If matching the op_hash canonicalization is impractical for a fixture, target a simpler `sha256_file`-style emission whose input is a whole known file: `expected="sha256:$(sha256sum "$FIXTURE" | cut -d' ' -f1)"`.
2. Run the brownfield op that emits the hash via `invoke_tool brownfield <op> <args>; rc=$IT_EXIT` (source the frozen seam).
3. Parse the emitted hash from the CONFIRMED channel (the applied.log / REPORT.md `sha256:` line in the fixture repo), NOT from `IT_STDOUT`:
```bash
got="$(grep -oE 'sha256:[0-9a-f]{64}' "$REPO/.brownfield/.../applied.log" | head -1)"   # the CONFIRMED channel
[ "$got" = "$expected" ] || { echo "FAIL: emitted hash $got != $expected"; exit 1; }
```
This holds for `sha256sum`, `hashlib`, or any implementation (a wrong/truncated hash now fails). Record in the SUMMARY the EXACT channel (file + line) the test parses. Remove the `schema/brownfield/migrations/*.sh` source-grep entirely (those migration scripts are out of v1.5 scope). Keep the test file name + its place in the phase-11 suite.

**Replace the pdf-extract source-grep with a LOCAL HTTP STUB (REVIEWS MEDIUM — do NOT merely quarantine).** In `tests/phase-20/test_pdf_extract_markers.sh`:
- Remove the line-32 `grep -q 'api/generate' bin/pdf-extract.sh` and the same-class line-28 `! grep -q 'ollama run'` source-greps (both false-fail a correct Python port).
- Replace them with a BEHAVIOR assertion using a local HTTP stub: stand up a minimal `python3 -c` `http.server.BaseHTTPRequestHandler` that records the request path/body and returns a canned olmOCR-style response, bound to a free localhost port; point `pdf-extract` at it via its endpoint/host env or arg (read bin/pdf-extract.sh for the override knob — it POSTs to `localhost:11434/api/generate`); run `invoke_tool pdf-extract <args>; rc=$IT_EXIT` against a tiny fixture PDF; and assert the stub RECEIVED a POST to a `/api/generate` path (assert the EFFECT, impl-agnostic). Tear the stub down in a trap. If the override knob does not exist (pdf-extract hardcodes host:port), the minimal viable form: bind the stub to `127.0.0.1:11434` for the test duration (skip if the port is already taken — mirror the existing Ollama SKIP idiom), so the real POST hits the stub. Document the chosen mechanism in the SUMMARY.
- KEEP the genuine behavior assertions: the marker-count assertions (~72-87) and the Ollama-down SKIP (~53). Do NOT weaken those.
- (Fallback ONLY if a local HTTP stub is genuinely infeasible at execute time: quarantine the two source-greps with a tracking note deferring the behavior rewrite to MIG-05, AND record in the SUMMARY why the stub was infeasible. The PRIMARY deliverable is the stub; quarantine is the documented fallback per RESEARCH Open Q4.)

**`tests/phase-24/test_shim_preflight_exit3.sh` — the SHIM-LEVEL exit-3 preflight-preservation CONTRACT TEST (REVIEWS cycle-4 finding #2b).** This makes the Phase-23 init-wizard compat boundary ENFORCEABLE now: the `.sh` shim MUST preserve the pre-flight (exit 3) behavior BEFORE invoking Python (a Python port cannot detect "python3 missing" from inside python3). Build a shim-shaped wrapper in an isolated temp scaffold (do NOT mutate the real repo) that models the CANONICAL Plan-01 shim form WITH a pre-flight gate, and drive it with python3 stripped / a preflight-failing condition:
1. In a temp scaffold, write a `bin/init-wizard.sh` shim-shaped wrapper that follows the documented Phase-23 contract: it runs the pre-flight dependency check (the exit-3 path — "is python3 present?") BEFORE the `exec python3 -m compendium.init_wizard "$@"`. Concretely the wrapper head is the canonical Plan-01 form plus a preflight gate, e.g.:
```bash
#!/usr/bin/env bash
set -euo pipefail
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# PRE-FLIGHT (exit 3) — MUST run in the shim BEFORE Python (a python port cannot check "python3 missing").
command -v python3 >/dev/null 2>&1 || { echo "init-wizard: python3 not found (pre-flight)" >&2; exit 3; }
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.init_wizard "$@"
```
   (You may instead DRIVE the REAL bin/init-wizard.sh from a writable extracted tree if its bash body already runs preflight before any python — but the contract under test is the SHIM-level preservation, so a shim-shaped wrapper that mirrors the documented Phase-23 form is the clearest enforcement. Document which you chose.)
2. **exit-3 with python3 stripped (the pre-fix-failing assertion):** run the wrapper with PYTHON3 stripped from PATH (keep bash/coreutils so the wrapper itself runs) — `( PATH="$STUBDIR_NO_PYTHON3"; bash "$scaffold/bin/init-wizard.sh" --dry-run </dev/null >out 2>err ); rc=$?` — and assert `rc == 3` AND that the wrapper exited BEFORE reaching Python (assert the python-module's output token is ABSENT from out, i.e. the `exec python3 -m ...` line was never reached). WHY PRE-FIX-FAILING: against a shim that does NOT preserve the pre-flight (a bare `exec python3 -m compendium.init_wizard "$@"` with no preflight gate), stripping python3 makes `exec python3` fail with code 127 (command not found), NOT the contractual 3 — so the `rc == 3` assertion FAILS. It PASSES only once the shim preserves the exit-3 pre-flight gate before invoking Python. (To make this concretely pre-fix-failing, the test SHOULD also run a BARE bootstrap-shim variant — `exec python3 -m compendium.init_wizard "$@"` with no preflight — under the same stripped PATH and assert its rc is NOT 3, demonstrating the contract is non-trivial.)
3. **happy passthrough (the inverse):** with python3 PRESENT on PATH, run the wrapper and assert it reaches Python (the stub module / `python3 -m` lane is invoked — e.g. it exits with the module's code, not 3) — confirming the preflight gate does not over-block.
4. **MANIFEST-DRIVEN per-shim enforcement — bind exit-3 to the REAL shipped shim as Phase 25 ports it (CYCLE-6 fix #5).** Steps 1-3 prove the property on a SYNTHETIC wrapper the test itself writes; a future real `bin/init-wizard.sh` shim that omits the preflight would not be caught. Add a manifest-driven loop that binds the contract to the shipped shim population. Define a tiny in-test contract registry mapping each preflight-bearing tool to (the dependency to strip, the expected exit code): today exactly `init-wizard → strip python3 → exit 3` (the ONLY tool whose bash `preflight()` gates on python3 presence — read `bin/init-wizard.sh:146-169`). Then, for EACH tool listed in `tests/ported.manifest` (read via the seam's exec root, `_oracle_exec_root`) that is ALSO in the contract registry, drive the REAL `<exec-root>/bin/<tool>.sh` shim with that dependency stripped from PATH (keeping bash/coreutils) and assert (a) it returns the registry exit code (3 for init-wizard) and (b) it exited BEFORE reaching Python (the module token is ABSENT). In Phase 24 `tests/ported.manifest` is EMPTY, so against the real repo this loop runs ZERO times — but it is the enforcement Phase 25 INHERITS: when the MIG-04 init-wizard port appends `init-wizard` to `ported.manifest` + flips `bin/init-wizard.sh`, this test AUTOMATICALLY asserts the real shim preserves exit 3 before Python, per shim, with no test edit. To PROVE the loop mechanism enforces (not vacuously passes on the empty real manifest), exercise it against a scaffold via the seam's `WIKI_EXEC_ROOT` knob: point `WIKI_EXEC_ROOT` at a scaffold whose `tests/ported.manifest` lists `init-wizard` and (a) with the scaffold's `bin/init-wizard.sh` = a BARE bootstrap shim (`exec python3 -m compendium.init_wizard "$@"`, NO preflight), assert the manifest-driven loop FLAGS it (with python3 stripped it returns 127, NOT 3 → the loop reports a contract violation); (b) with the CANONICAL preflight-preserving shim, assert the loop PASSES. This is the "manifest-driven test that iterates every ported shim and asserts the property per shim" the disposition requires — it binds the exit-3 compat boundary to the real shipped shim, not only the synthetic exemplar.
Make executable; auto-discovered by `tests/phase-24/run.sh`'s `test_*.sh` glob (Task 1's aggregator). Record in the SUMMARY that this is the cycle-4 finding #2b + cycle-6 fix #5 deliverable: exit 3 is now an ENFORCED Phase-23 shim compat boundary, bound to the real ported-shim population via a manifest-driven loop, cross-referenced from `tests/oracle-exempt.md`.

After editing, run all three files to confirm the rewritten hashlib test passes, the pdf-extract test asserts behavior (not source), and the shim-preflight-exit3 contract test passes. (The phase-11/phase-20 suites may have OTHER pre-existing failures — the pinned baseline, Plan 05's concern; this task asserts only that THESE tests behave correctly.)
  </action>
  <verify>
    <automated>chmod +x tests/phase-11/test_hashlib_not_sha256sum.sh tests/phase-20/test_pdf_extract_markers.sh tests/phase-24/test_shim_preflight_exit3.sh && bash tests/phase-11/test_hashlib_not_sha256sum.sh; echo "hashlib exit=$?"; bash tests/phase-20/test_pdf_extract_markers.sh; echo "pdf exit=$?"; bash tests/phase-24/test_shim_preflight_exit3.sh; echo "shim-preflight-exit3 exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `! grep -qE "grep .*-q .*sha256sum.*bin/brownfield" tests/phase-11/test_hashlib_not_sha256sum.sh` — the source-grep for the literal `sha256sum` in brownfield is gone
    - `grep -q 'invoke_tool brownfield' tests/phase-11/test_hashlib_not_sha256sum.sh` exits 0 (routes through the seam)
    - `grep -qE 'applied.log|REPORT|sha256:' tests/phase-11/test_hashlib_not_sha256sum.sh` exits 0 (parses the CONFIRMED emission channel, not assumed stdout — REVIEWS MEDIUM)
    - `! grep -q 'migrations/\*\.sh' tests/phase-11/test_hashlib_not_sha256sum.sh` — the out-of-scope migrations source-grep is removed
    - `bash tests/phase-11/test_hashlib_not_sha256sum.sh` exits 0 (rewritten behavior test passes against the bash oracle)
    - `! grep -E "^[^#]*grep -q 'api/generate'" tests/phase-20/test_pdf_extract_markers.sh` — the active api/generate SOURCE-grep no longer runs
    - `grep -qiE 'http.server|BaseHTTPRequestHandler|11434|api/generate' tests/phase-20/test_pdf_extract_markers.sh` exits 0 (a LOCAL HTTP STUB behavior assertion replaces the grep — REVIEWS MEDIUM; OR the documented quarantine fallback note is present)
    - `grep -cE 'marker|SKIP' tests/phase-20/test_pdf_extract_markers.sh` is non-zero (genuine behavior asserts + Ollama SKIP kept)
    - `test -x tests/phase-24/test_shim_preflight_exit3.sh` exits 0 (the shim-level exit-3 contract test exists + is executable — cycle-4 finding #2b)
    - `grep -qE 'exit 3|== 3|-eq 3' tests/phase-24/test_shim_preflight_exit3.sh && grep -qiE 'python3|preflight|pre-flight' tests/phase-24/test_shim_preflight_exit3.sh` exits 0 (the test drives a python3-stripped / preflight-failing condition and asserts exit 3)
    - `grep -qiE 'before.*python|preserve.*exit 3|shim.*exit 3|exit 3.*before' tests/phase-24/test_shim_preflight_exit3.sh` exits 0 (the test asserts the SHIM returns exit 3 BEFORE reaching Python — cycle-4 finding #2b)
    - `grep -q 'ported.manifest' tests/phase-24/test_shim_preflight_exit3.sh && grep -q 'WIKI_EXEC_ROOT' tests/phase-24/test_shim_preflight_exit3.sh && grep -qiE 'for .*(tool|shim)|iterate|per-shim|manifest-driven' tests/phase-24/test_shim_preflight_exit3.sh` exits 0 (CYCLE-6 fix #5: a MANIFEST-DRIVEN loop iterates every ported shim and asserts the exit-3 property per REAL shim — bound to the shipped population via WIKI_EXEC_ROOT, not only the synthetic wrapper)
    - `bash tests/phase-24/test_shim_preflight_exit3.sh` exits 0 (PRE-FIX-FAILING: the canonical shim preserves exit 3 before Python with python3 stripped, a bare bootstrap-shim returns 127 not 3, AND the manifest-driven loop flags a bootstrap/bare scaffold shim seeded in a WIKI_EXEC_ROOT ported.manifest — FAILS for a shim that does NOT preserve the preflight and for the cycle-5 exemplar-only design — REVIEWS cycle-4 finding #2b + cycle-6 fix #5)
  </acceptance_criteria>
  <done>hashlib test rewritten to assert the emitted hash VALUE from the CONFIRMED applied.log/REPORT.md sha256: channel (impl-agnostic, channel recorded in SUMMARY); migrations source-grep removed; the pdf-extract api/generate source-grep replaced with a LOCAL HTTP stub behavior assertion (or documented quarantine fallback) while marker-count + Ollama-SKIP asserts are kept; AND a SHIM-LEVEL exit-3 preflight-preservation contract test (tests/phase-24/test_shim_preflight_exit3.sh) drives the canonical shim with python3 stripped and asserts the shim returns exit 3 BEFORE reaching Python (a bare bootstrap-shim returns 127, proving the contract is non-trivial — REVIEWS cycle-4 finding #2b).</done>
</task>

<task type="auto">
  <name>Task 3: Inventory + classify EVERY implementation-asserting test (lint/audit-claims/check-neutrality/hook-form) with a guard that fails on any unclassified one</name>
  <files>tests/impl-assertion-inventory.md, tests/phase-24/test_impl_assertion_inventory.sh</files>
  <read_first>
    - tests/phase-09/ + tests/phase-12.1/ + tests/phase-12.2/ + tests/phase-13/ (READ enough test_*.sh to find every test that GREPS bin/lint.sh / bin/audit-claims.sh source, cats them, or asserts on bash internals/function names/heredoc strings rather than observable CLI behavior)
    - tests/phase-09/ + tests/phase-12.1/ (READ the check-neutrality.sh internal-asserting tests)
    - tests/phase-07/ + tests/phase-09/ (READ the hook-command-form suites — tests that assert on the exact command strings inside .githooks/pre-commit, e.g. `grep -q 'sync-claude --check' .githooks/pre-commit`)
    - tests/phase-11/test_hashlib_not_sha256sum.sh + tests/phase-20/test_pdf_extract_markers.sh (Task 2 — the 2 already-addressed anti-signal tests; they go in the inventory as rewritten-behavioral)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#7 [inventory every impl-asserting test, classify behavioral / shim-contract / obsolete-or-deferred — no silent omissions])
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the rewrite-anti-signal-tests section)
  </read_first>
  <action>
**Inventory every implementation-asserting test (REVIEWS HIGH#7 / TEST-04 — the residual beyond the 2 named ones).** An implementation-asserting test is one that reads bash IMPLEMENTATION SOURCE or asserts on bash internals (greps `bin/<tool>.sh` for a literal, cats a bin script and checks a function name / heredoc string / variable name, or asserts the EXACT command-string form inside `.githooks/pre-commit`) rather than observable CLI behavior (stdout/stderr/exit/file-tree). These either BLOCK a correct Python port (the Python source won't contain the asserted bash strings) or go VACUOUS against a thin shim.

1. **Discover them mechanically.** Grep the suites named in this task's read-first list for the impl-asserting forms — at minimum:
   - `grep` / `grep -q` whose target argument is `bin/lint.sh`, `bin/audit-claims.sh`, `bin/check-neutrality.sh`, `bin/check-privacy.sh`, `bin/check-sources-cloud-safe.sh`, or another `bin/<tool>.sh` (i.e. reading the SCRIPT SOURCE, not its output);
   - `cat`/`sed`/`awk` over a `bin/<tool>.sh` body used as the assertion subject;
   - greps/asserts over `.githooks/pre-commit` command-string forms (e.g. asserting the literal `sync-claude --check` / `gen-skills --check` / `lint --strict --staged` command shapes — these are hook-command-form tests).
   Produce the candidate list as file:line.

2. **Author `tests/impl-assertion-inventory.md`** — a committed table with one row per discovered impl-asserting test (and the 2 Task-2 anti-signal tests), each classified + disposed:
   - **behavioral** — KEEP as-is: it already asserts observable behavior (rare in this list; include only if a borderline grep is actually behavior-equivalent, with a note).
   - **shim-contract** — KEEP but the assertion is about the SHIM CONTRACT (e.g. the `.githooks/pre-commit` MUST call `sync-claude --check` regardless of language — the hook command-form IS the contract, not an impl detail). Note WHY it is a contract assertion, not an impl assertion.
   - **obsolete / impl-asserting** — either REWRITE-NOW to assert observable behavior, or DEFER with a written rationale: which test, why deferring is safe (the bash impl is frozen in Phase 24; the test only bites when that tool ports in Phase 25), and what tracks it (the specific MIG-0x cluster plan that ports the tool and must rewrite this test). NO silent omissions.
   The table columns: `test (file:line) | what it asserts | classification | disposition (rewrite-now / keep / defer-to-MIG-0x) | rationale`.
   Header: this inventory IS the TEST-04 deliverable required by REVIEWS HIGH#7; every Phase-23 cluster plan MUST consult it before porting its tool.

3. **Rewrite the cheap ones now** where a behavioral equivalent is trivial (e.g. a hook-form test that can assert the hook's EFFECT instead of its command string). For anything non-trivial, DEFER with the rationale above — do not expand scope into rewriting every test (that is Phase 25's per-cluster job). The hard requirement is COMPLETE CLASSIFICATION, not complete rewriting.

**`tests/phase-24/test_impl_assertion_inventory.sh`** — the guard (REVIEWS HIGH#7). It re-runs the mechanical discovery from step 1, and for EACH discovered impl-asserting test asserts it is ACCOUNTED FOR in `tests/impl-assertion-inventory.md` (its file:line or test name appears in the inventory with a non-empty classification + disposition). If ANY discovered impl-asserting test is NOT in the inventory (unclassified), the guard FAILS (exit non-zero) and prints the offending file:line. This makes "no UNCLASSIFIED impl-asserting test remains" mechanically enforced.
WHY THIS IS PRE-FIX-FAILING: against the current state (only the 2 named anti-signal tests addressed, no inventory file), the guard finds the lint/audit-claims/check-neutrality/hook-form impl-asserting tests UNLISTED → FAILS. It PASSES only once `tests/impl-assertion-inventory.md` exists and accounts for every discovered test. Make the guard executable; it is AUTO-DISCOVERED by `tests/phase-24/run.sh`'s `test_*.sh` glob (Task 1's aggregator) with no run.sh edit — do NOT modify run.sh here.
  </action>
  <verify>
    <automated>chmod +x tests/phase-24/test_impl_assertion_inventory.sh && bash tests/phase-24/test_impl_assertion_inventory.sh; echo "inventory guard exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `test -f tests/impl-assertion-inventory.md` exits 0 (the inventory artifact exists — REVIEWS HIGH#7)
    - `grep -qiE 'lint\.sh|lint' tests/impl-assertion-inventory.md && grep -qiE 'audit-claims' tests/impl-assertion-inventory.md && grep -qiE 'check-neutrality' tests/impl-assertion-inventory.md && grep -qiE 'pre-commit|hook' tests/impl-assertion-inventory.md` exits 0 (lint + audit-claims + check-neutrality + hook-form surfaces all covered)
    - `grep -qiE 'behavioral|shim-contract|obsolete|defer' tests/impl-assertion-inventory.md` exits 0 (the classification vocabulary is present)
    - `test -x tests/phase-24/test_impl_assertion_inventory.sh` exits 0 (the guard is executable)
    - `bash tests/phase-24/test_impl_assertion_inventory.sh` exits 0 (PRE-FIX-FAILING: every discovered impl-asserting test is accounted for — FAILS today with no inventory + only 2 tests addressed, PASSES once the inventory classifies all of them — REVIEWS HIGH#7)
    - `grep -qE 'for .* in .*/test_\*\.sh' tests/phase-24/run.sh && test -f tests/phase-24/test_impl_assertion_inventory.sh` exits 0 (run.sh globs test_*.sh, so the guard is auto-discovered in the phase-24 aggregator)
  </acceptance_criteria>
  <done>tests/impl-assertion-inventory.md catalogues EVERY impl-asserting test across lint.sh/audit-claims.sh/check-neutrality.sh/hook-command-form suites (+ the 2 Task-2 anti-signal tests) with a classification (behavioral / shim-contract / obsolete) + disposition (rewrite-now / keep / defer-to-MIG-0x with rationale); the guard test fails on any UNCLASSIFIED impl-asserting test and runs in the phase-24 aggregator (REVIEWS HIGH#7).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| golden ↔ frozen oracle | A golden captured against a non-deterministic or wrong baseline silently mis-pins Phase-23 parity |
| state-dependent error path ↔ frozen worktree | init-wizard exit-4 / the $0-relative-REPO_ROOT class cannot be reached through the frozen worktree; capturing it there yields the wrong code (REVIEWS cycle-3 finding #1) |
| gen-skills drift ↔ in-sync frozen worktree | the oracle's gen-skills --check is always in-sync (exit 0); the drift exit-1 reference must be captured from a writable extracted tree and NOT dropped (cycle-4 finding #2a) |
| init-wizard exit 3 ↔ Phase-23 shim | exit 3 is a dependency-PRESENCE check the .sh shim must preserve before invoking Python; documenting it exempt without a contract test leaves the compat boundary unenforced (cycle-4 finding #2b) |
| init-wizard exit code ↔ source line | Capturing exit 3 mislabeled as already-initialized pins the WRONG compat boundary |
| oracle-exempt registry ↔ parity matrix | A parity-unverifiable path treated as verifiable yields a false parity claim (REVIEWS cycle-3 finding #1) |
| anti-signal test ↔ correct port | A test that asserts implementation (not behavior) inverts on a correct port, masking real regressions if deleted wholesale |
| impl-assertion inventory ↔ Phase-23 ports | An unclassified impl-asserting test blocks a correct port or goes vacuous against a thin shim (REVIEWS HIGH#7) |
| pdf-extract HTTP boundary (Ollama) | The external egress surface; the api/generate contract is security-relevant and is now asserted via a local stub |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-22-13 | Spoofing | golden captured with collapsed channels | mitigate | `capture_footprint` (Plan 03) writes all 4 channels into <case>/; acceptance asserts the `exit` and `tree` files exist per case. |
| T-22-47 | Spoofing | exit-4 captured through the frozen worktree (wrong code / inert driver) | mitigate | The exit-4 / state-dependent error paths are captured from a WRITABLE git-archive-EXTRACTED TREE seeded with .wizard-answers.yaml at the tree root (= REPO_ROOT from $0), NOT the inert cd-PWD driver against the un-seedable frozen worktree (REVIEWS cycle-3 finding #1). Acceptance asserts `git archive`/`extract_writable_tree` + the absence of the PWD-seed driver. |
| T-22-48 | Spoofing | exit-4 silently treated as parity-verifiable in the matrix | mitigate | `tests/oracle-exempt.md` records exit-4 + the $0-relative-REPO_ROOT class as parity-EXEMPT with the WHY (the WIKI_IMPL=bash leg also runs from the frozen worktree); Plan 05's matrix must treat listed paths as exempt (REVIEWS cycle-3 finding #1). |
| T-22-49 | Denial of Service | exit-3 driver breaks the seam/oracle (strips git/mktemp) | mitigate | The exit-3 driver strips PYTHON3 ONLY, keeping git+bash+coreutils so preflight() exits 3 while the harness still runs (REVIEWS cycle-3 finding #1). Acceptance asserts python3-only strip, not PATH=/nonexistent. |
| T-22-57 | Spoofing | gen-skills drift exit-1 path never frozen (drift golden dropped) | mitigate | The gen-skills drift exit-1 golden is MANDATORY, captured from a writable extracted tree; the test FAILS if `tests/goldens/gen-skills/check-drift/exit` is absent or != 1 (cycle-4 finding #2a). The cycle-3 optional "drop the drift golden" branch is removed. |
| T-22-58 | Repudiation | Phase-23 shim drops the exit-3 pre-flight (unenforced compat boundary) | mitigate | `tests/phase-24/test_shim_preflight_exit3.sh` drives the canonical shim form with python3 stripped and asserts the SHIM returns exit 3 BEFORE Python (a bare bootstrap-shim returns 127, proving the contract is non-trivial — cycle-4 finding #2b), AND a MANIFEST-DRIVEN loop binds the contract to the REAL bin/<tool>.sh shim for each ported tool with a preflight contract (empty in P22, enforced per real shim in Phase 25; proven now via a WIKI_EXEC_ROOT scaffold — cycle-6 fix #5). oracle-exempt.md cross-references this test. |
| T-22-59 | Spoofing | a parity-exempt path has no machine-readable mapping (ad-hoc matching, silent mis-skip) | mitigate | `tests/oracle-exempt.txt` gives every exemption a machine-readable `<pattern>` (tool name / pairing-key glob) that Plan 05's --require-parity consumes to skip + annotate matching keys; kept consistent with the prose .md (cycle-6 MEDIUM b). |
| T-22-36 | Tampering | init-wizard exit code mis-pinned (3 vs 4) | mitigate | Exit 4 (already-initialized, line 221) and exit 3 (pre-flight, line 165) are captured SEPARATELY with COMMITTED exit-file goldens asserting the literal code; the SUMMARY records the source line each came from. |
| T-22-37 | Spoofing | gen-skills golden captured through the wrong tree (false drift) | mitigate | The gen-skills --check IN-SYNC golden is captured through Plan 03's WORKTREE oracle (no false drift); the DRIFT golden is captured from a writable extracted tree (mandatory — cycle-4 finding #2a). |
| T-22-14 | Tampering | deleting the anti-signal tests removes real coverage | mitigate | The hashlib test is REWRITTEN to assert the hash VALUE from the CONFIRMED channel. The pdf-extract grep is replaced with a LOCAL HTTP STUB behavior assertion, so the api/generate contract coverage survives the impl change. |
| T-22-38 | Tampering | residual impl-asserting tests silently block / invert on a port | mitigate | tests/impl-assertion-inventory.md classifies EVERY impl-asserting test and the guard fails on any unclassified one (REVIEWS HIGH#7); each deferred one names the MIG-0x plan that owns its rewrite. |
| T-22-29 | Spoofing | the 4-channel file-tree design is unproven (only read-only goldens) | mitigate | A mutating-tool golden (ingest / lint --fix) exercises the file-tree channel as the load-bearing signal, with a determinism check (REVIEWS L-1). |
| T-22-15 | Information Disclosure | the --verifier egress / api/generate contract weakened by a test edit | mitigate | This plan edits TEST files + adds the inventory + oracle-exempt registry + the shim-preflight test; it does NOT touch tool source. The local HTTP stub asserts the api/generate POST EFFECT, strengthening egress coverage. |
| T-22-16 | Tampering | characterization golden freezes buggy behavior as "correct" | accept | Characterization = freeze what IS (the bash oracle). Behavior fixes are a separate post-migration decision (Out-of-Scope). |
</threat_model>

<verification>
- `bash tests/phase-24/run.sh` exits 0 (new characterization suite + inventory guard + shim-preflight test green against the worktree bash oracle + the writable-extracted-tree error paths).
- `ls -d tests/goldens/validate-op/*/` shows 4+ committed case dirs each with {stdout,stderr,exit,tree}.
- `grep -qx '4' tests/goldens/init-wizard/already-initialized/exit` and `grep -qx '3' tests/goldens/init-wizard/preflight-missing-dep/exit` (REVIEWS cycle-3 finding #1 — committed exit files; exit-4 from a writable extracted tree).
- `grep -qx '1' tests/goldens/gen-skills/check-drift/exit` (the MANDATORY gen-skills drift exit-1 golden — REVIEWS cycle-4 finding #2a).
- `tests/oracle-exempt.md` records exit-4 + the $0-relative state-dependent class as parity-exempt with the WHY and cross-references the exit-3 shim contract test (REVIEWS cycle-3 finding #1 + cycle-4 finding #2b).
- `bash tests/phase-24/test_shim_preflight_exit3.sh` exits 0 (the shim preserves exit 3 before Python; a bare bootstrap-shim returns 127 — REVIEWS cycle-4 finding #2b, pre-fix-failing).
- the gen-skills --check in-sync golden was captured through the worktree oracle; the drift case is captured-from-extracted-tree (mandatory — cycle-4 finding #2a).
- the mutating-tool golden's `tree` channel records the mutation, stable across two captures (REVIEWS L-1).
- `bash tests/phase-11/test_hashlib_not_sha256sum.sh` exits 0 (rewritten, confirmed channel).
- the pdf-extract test asserts api/generate behavior via a local stub (REVIEWS MEDIUM).
- `bash tests/phase-24/test_impl_assertion_inventory.sh` exits 0 (no unclassified impl-asserting test — REVIEWS HIGH#7).
- `git diff --name-only HEAD -- bin/` is empty (no tool ported; only tests + goldens + inventory + oracle-exempt added).
</verification>

<success_criteria>
- TEST-03: characterization goldens (stdout + stderr + exit + file tree, 4 channels, <case>/ layout) frozen for `validate-op.sh` + `search.sh` modes + ALL divergent error paths (init-wizard exit 4 from a writable extracted tree AND exit 3 via python3-only strip, gen-skills in-sync via worktree oracle, gen-skills DRIFT exit-1 from a writable extracted tree [MANDATORY — cycle-4 finding #2a]) + a mutating-tool golden, captured BEFORE any port; oracle-exempt paths recorded in tests/oracle-exempt.md.
- TEST-04: the `hashlib` impl-asserting test is rewritten to assert the hash value from the confirmed channel; the `pdf-extract` `api/generate` source-grep is replaced with a local HTTP stub behavior assertion; AND every remaining impl-asserting test (lint/audit-claims/check-neutrality/hook-form) is inventoried + classified + disposed with a guard (REVIEWS HIGH#7).
- REVIEWS cycle-3 finding #1 (init-wizard exit 4 from a writable extracted tree + exit 3 python3-only + oracle-exempt registry + gen-skills drift), HIGH#1-ripple (gen-skills in-sync through the worktree oracle), HIGH#7 (impl-assertion inventory), MEDIUM (mutating-tool golden + determinism, hashlib channel, PDF local stub), cycle-4 finding #2a (gen-skills drift golden MANDATORY not droppable) + cycle-4 finding #2b (shim-level exit-3 preflight-preservation contract test) all resolved.
</success_criteria>

<output>
After completion, create `.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-04-SUMMARY.md`
</output>
</content>

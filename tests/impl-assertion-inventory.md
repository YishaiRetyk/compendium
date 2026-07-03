# Implementation-Assertion Inventory (Phase 24 Plan 04 — TEST-04, REVIEWS HIGH#7)

> Every test that reads a `bin/<tool>.sh` script (or `.githooks/pre-commit`) as SOURCE/data —
> rather than asserting observable CLI behavior — is catalogued here with a classification and
> disposition. **Every Phase-25 cluster plan MUST consult this inventory before porting its
> tool.** The guard `tests/phase-24/test_impl_assertion_inventory.sh` re-runs the mechanical
> discovery and FAILS if any discovered impl-asserting test is missing from this table.
>
> Classifications: **behavioral** (asserts observable behavior — keep),
> **shim-contract** (asserts the stable `.sh`-interface contract that survives the migration —
> keep, with the WHY), **impl-asserting** (reads bash internals — rewrite-now or
> defer-to-MIG-0x with rationale). Discovery sweep 2026-07-03 covered ALL suites
> `tests/phase-07 … tests/phase-23` (per RB-4, incl. the new 22/23 suites: NO impl-asserting
> tests found there — their assertions are invocation-based).

| Test (file:line) | What it asserts | Classification | Disposition | Rationale |
|------------------|-----------------|----------------|-------------|-----------|
| `tests/phase-09/test_lint_version.sh:11` | sed-extracts `LINT_VERSION="…"` from the `bin/lint.sh` SOURCE and compares it to `lint --version` output | impl-asserting | **defer-to-MIG-02** | Safe to defer: the bash impl is frozen through Phase 24, so the extraction keeps working until the lint port. The MIG-02 plan MUST rewrite it (assert the semver SHAPE of `--version` output, or read the constant from the ported module) — a Python lint has no `LINT_VERSION="…"` bash line, so the sed returns empty and the test false-fails on a correct port. |
| `tests/phase-07/test_sync_claude.sh:77,84` | `bin/install-hooks.sh` contains `core.hooksPath .githooks`; the hook file names `sync-claude.sh` | shim-contract | keep | `install-hooks.sh` STAYS BASH (MIG-06) and the hook keeps invoking the `.sh` shims (PKG-03) — the command form IS the stable contract, not an impl detail. Both assertions remain true across the migration. |
| `tests/phase-07/test_sync_claude_hook_roundtrip.sh:36` | executes `.githooks/pre-commit` under a temp index and asserts its EFFECT | behavioral | keep | Runs the hook and checks the outcome — already behavior-level (listed because it touches the hook file; no rewrite needed). |
| `tests/phase-18/test_hook_ordering_skills.sh:9–19` | `.githooks/pre-commit` invokes `bash bin/sync-claude.sh` → `bash bin/gen-skills.sh` → `bash bin/lint.sh` in that order | shim-contract | keep | The hook's gate ORDER and its `.sh`-shim invocation forms are the locked local-gate contract (the shims persist per PKG-03/SHIMOUT-deferred); a ported tool changes nothing here. Plan 06 extends the hook additively — the ordering assertion must stay green. |
| `tests/phase-11/test_hashlib_not_sha256sum.sh` | WAS: source-grep for the literal `sha256sum` in brownfield + migrations | behavioral (REWRITTEN 2026-07-03) | done (this phase) | Rewritten to assert the emitted `# op_hash: sha256:<64hex>` VALUE on line 2 of the suggest-generated migration copy (`.brownfield/migrations/01-page-typing.sh`) against a reference computation of the documented canonicalization — impl-agnostic (TEST-04/D-16). |
| `tests/phase-20/test_pdf_extract_markers.sh` | WAS: `! grep 'ollama run'` + `grep 'api/generate'` source-greps | behavioral (REWRITTEN 2026-07-03) | done (this phase) | Rewritten to a local HTTP stub (free port, `OLLAMA_URL` + `PDF_EXTRACT_MODEL` env knobs) asserting the EFFECT: the tool POSTs `/api/generate` and consumes the response. Marker-count + Ollama-SKIP asserts kept. The `test -x bin/pdf-extract.sh` executability check is shim-contract (the shim file persists). |

| `tests/phase-10/test_agents_section_5_bootstrap_stage.sh:36` | AGENTS.md §5 frontmatter-doc text mentions ``stripped by `bin/ingest.sh` `` | shim-contract (doc-content) | keep | The grep PATTERN names the tool; the TARGET is schema-doc text, not script source. Docs keep naming the `.sh` shims across the migration (PKG-03/CUT-01 verifies doc references), so the assertion survives the port. (Pre-existing known-red: the §5 text drifted in a prior phase — the pinned-baseline concern, not this inventory's.) |

**Not inventoried (non-matches reviewed and excluded):** `tests/phase-07/test_docs_skeleton.sh`
greps DOCS files for `bin/<tool>.sh` mentions — a docs-content contract, not a script-source
read; suite invocation lines (`bash "$REPO_ROOT/bin/<tool>.sh"` / `invoke_tool <tool>`) are
behavior-level by definition.

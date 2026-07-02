# Phase 24: Foundation — Package Skeleton + Frozen Shared Core + Parity Oracle - Pattern Map

**Mapped:** 2026-06-18
**Files analyzed:** 11 file-groups (pyproject, package init, ~15 stubs, common/**, shims, invoke_tool seam, conftest, characterization backfill, 3 CI workflows, CLAUDE.md/AGENTS.md §2)
**Analogs found:** 10 / 11 (one genuinely new surface — the wiki-page primitives — has no `bin/lib/` analog; it is an in-heredoc byte-copy)

> **Phase reality:** No script is ported. Every `bin/<name>.sh` keeps its bash body. `common/**` is a *copy-up* (lift, never move — `bin/lib/*.py` stays because the bash heredocs still `sys.path.insert` + import it). The acceptance bar is byte-parity of the untouched `WIKI_IMPL=bash` path. The analogs below are therefore "the source to lift verbatim" or "the existing shape to mirror," not "code to call."

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `pyproject.toml` | config | declarative-metadata | (no Python-packaging precedent in repo) | RESEARCH-only |
| `src/compendium/__init__.py` | package-init | n/a | (none — first Python package) | none |
| `src/compendium/<tool>.py` × ~15 stubs | entry-point module | request-response (stub) | `bin/install-hooks.sh` (trivial body) + RESEARCH Pattern 1 | partial |
| `src/compendium/common/privacy.py` | service (lib) | transform | `bin/lib/privacy_resolve.py` | **exact (verbatim lift)** |
| `src/compendium/common/yaml_rt.py` | service (lib) | transform / file-I/O | `bin/lib/brownfield_yaml.py` (`make_yaml`) | **exact (verbatim lift)** |
| `src/compendium/common/walk.py` | service (lib) | file-I/O / batch | `bin/lib/brownfield_walk.py` | **exact (verbatim lift)** |
| `src/compendium/common/classify.py` | service (lib) | transform | `bin/lib/brownfield_classify.py` | **exact (verbatim lift)** |
| `src/compendium/common/provenance.py` | service (lib) | transform | `bin/lib/brownfield_provenance.py` | **exact (verbatim lift)** |
| `src/compendium/common/page.py` (NEW primitives) | service (lib) | transform | inline heredoc dup in `bin/lint.sh` + `bin/audit-claims.sh` | role-match (extract from heredoc) |
| `bin/<name>.sh` shims (Phase-23 *target* form; documented not applied in P22) | route (process boundary) | request-response | `bin/pdf-extract.sh` arg-flow + RESEARCH Pattern 2 | role-match |
| `tests/lib/invoke_tool.sh` + `normalize.sh` (seam) | test-harness | request-response capture | `tests/phase-09/test_lint_strict_new_page.sh` invocation form + `tests/phase-10/lib.sh` | role-match |
| `tests/conftest.py` (pytest) | test-harness | n/a | `tests/phase-10/lib.sh::make_fixture_repo` + `tests/phase-13/lib.sh::make_bare_repo` | exact (port to pytest) |
| Characterization goldens for `validate-op.sh` + `search.sh` | test | characterization | `tests/phase-10/lib.sh::assert_byte_equal` + `tests/phase-09/test_lint_skip_category.sh` | role-match |
| Rewrite anti-signal tests (`phase-11/test_hashlib*`, `phase-20/test_pdf_extract_markers`) | test | characterization | the two existing test files themselves | exact (in-place edit) |
| `.github/workflows/{lint,neutrality,setup-parity}.yml` | config (CI) | event-driven | existing jobs in those files + `setup-parity.yml` suite-runner block | exact (additive edit) |
| `CLAUDE.md` §2 + `AGENTS.md` §2 | config (schema) | n/a | the existing §2 "Permitted top-level directories" line (byte-equal twins) | exact (in-place edit) |

## Pattern Assignments

### `pyproject.toml` (config, declarative-metadata)

**Analog:** None in-repo (first Python package). Use the canonical form in `24-RESEARCH.md` §"Code Examples → pyproject.toml" verbatim. Key constraints to copy:
- `[build-system] requires = ["setuptools >= 77.0.3"]`, `build-backend = "setuptools.build_meta"`.
- `requires-python = ">=3.11"` (D-05).
- `dependencies = ["PyYAML==<pin>", "ruamel.yaml==0.19.1"]` — **pin exact**; recommend pin-to-**installed** `PyYAML==6.0.1` (the version the committed brownfield goldens were generated under; see RESEARCH Open Q1). A bump is a separate parity-validated change.
- `[tool.setuptools.packages.find] where = ["src"]` (D-02; required or `import compendium` fails — Pitfall 8).
- `[project.scripts]` — ALL ~15 entry points pre-declared (D-03/SC#1), names `compendium-<tool>` → `compendium.<tool>:main`. **Module names use `_`, command names use `-`** (e.g. `compendium-audit-claims = "compendium.audit_claims:main"`).
- Add `[project.optional-dependencies] dev = ["pytest"]` and `[tool.pytest.ini_options]` (testpaths, markers) — pytest is NOT installed (Pitfall 1).

**Entry-point inventory (enumerate at plan time):** `ls bin/*.sh` = 17 files. Exclude `install-hooks.sh` (stays bash, MIG-06) and `migrate-privacy-dirs.sh` (retired, MIG-06) → **15 ported tools**. Reconcile the CONTEXT "~16" by listing the 15 explicitly; the exact count is not load-bearing as long as every ported tool has an entry. This table is FROZEN (D-08) — Phase-23 never edits it.

**FROZEN surface (D-08):** the whole `[project.scripts]` table + `dependencies`.

---

### `src/compendium/<tool>.py` (~15 stub modules) (entry-point module, request-response stub)

**Analog:** trivial-body bash script `bin/install-hooks.sh` (5 lines, no logic) is the closest "does nothing of consequence" precedent; the concrete stub form is RESEARCH §"Code Examples → Pattern 1".

**Stub pattern (RESEARCH Pattern 1) — copy this shape per tool:**
```python
# src/compendium/<tool>.py  (STUB — Phase 24)
import sys

def main(argv=None):
    # Phase 24: not yet ported. The bin/<tool>.sh shim still runs its bash body;
    # this stub exists only so the entry point resolves at install time.
    print("compendium.<tool>: not yet implemented (Phase 25)", file=sys.stderr)
    return 0

if __name__ == "__main__":          # enables `python3 -m compendium.<tool>`
    sys.exit(main(sys.argv[1:]))
```
**Decision note (planner):** RESEARCH recommends `return 0` + a stderr note so `pip install -e . && compendium-<tool> --help` smoke checks don't false-fail. Keep stubs **import-light** (no top-of-module `common/` imports) so the install smoke test stays cheap (RESEARCH Anti-Patterns). The `if __name__ == "__main__"` block is required so the D-04 `python3 -m compendium.<tool>` shim form works in Phase 25.

**Module-name note:** `audit_claims.py`, `check_neutrality.py`, `check_privacy.py`, `check_sources_cloud_safe.py`, `gen_skills.py`, `init_wizard.py`, `pdf_extract.py`, `requirements_sync.py`, `sync_claude.py`, `validate_op.py` — underscores (Python import rule) while the bin/ shims and console_scripts keep hyphens.

---

### `src/compendium/common/yaml_rt.py` (service/lib, transform) — THE BYTE-EXACT CHOKEPOINT

**Analog:** `bin/lib/brownfield_yaml.py` — **lift verbatim** (rename module file only; the import-surface rename `brownfield_yaml`→`yaml_rt` is the one-time cost paid before freeze).

**`make_yaml()` — the byte-exact canonicalization** (`bin/lib/brownfield_yaml.py` lines 164-183). DO NOT re-tune; any change to these four settings breaks every brownfield byte-equal golden (Pitfall 2):
```python
def make_yaml() -> YAML:
    y = YAML(typ='rt')                 # round-trip: preserves comments/key-order/quoting
    y.preserve_quotes = True           # Dataview-friendly: keeps 'value' as-is
    y.default_flow_style = False       # explicit block-style
    def _represent_none(self, data):   # None -> literal `null` (pins D-14 sentinel rendering)
        return self.represent_scalar('tag:yaml.org,2002:null', 'null')
    y.representer.add_representer(type(None), _represent_none)
    return y
```

**Two-stage parse to also lift** (`read_fm_body`, lines 186-227): PyYAML `safe_load` pre-flight → ruamel `make_yaml().load()` round-trip. This is *why both deps are pinned* (`import yaml as pyyaml` at line 34 + ruamel imports at lines 36-47). The `__all__` already lists `make_yaml` (line 482) and the other stable names — keep `__all__` intact.

**Other lifted functions (one Read of the file covers all):** `split_frontmatter` (90), `_pre_scan_duplicate_keys` (139), `infer_id_from_filename` (230), `extract_h1` (244), `file_mtime_iso` (250), `build_d14_sentinel_set` (259), `merge_sentinels` (332), `write_roundtrip` (420), plus the `FIELD_CLASS_A/B`, `VALID_ENUMS`, `DuplicateKeyError` exports.

**Seed unit test (TEST-06):** round-trip a known frontmatter block and `assert` byte-equality against a committed fixture (Pitfall 2 mitigation).

---

### `src/compendium/common/privacy.py` (service/lib, transform)

**Analog:** `bin/lib/privacy_resolve.py` — **lift verbatim** (4519 bytes, one Read covers it).

**The fail-closed `wiki-local/` predicate** (`bin/lib/privacy_resolve.py` lines 36-56) — the subtle-correctness already paid for (WR-02 case-fold, WR-03 `./`/leading-`/` normalize); do not re-implement:
```python
_WIKI_LOCAL_PREFIX = 'wiki-local/'

def _is_local(path):
    if not path:
        return False
    p = str(path)
    if p.startswith('./'):
        p = p[2:]
    p = p.lstrip('/').lower()
    return p.startswith(_WIKI_LOCAL_PREFIX) or ('/' + _WIKI_LOCAL_PREFIX) in ('/' + p)
```
**Stable public names (callers' import statements must keep working):** `resolve_source_privacy` (line 59), `resolve_effective_claim_privacy` (line 71). `bin/audit-claims.sh` imports both (audit-claims.sh line 143) — that import flips to `from compendium.common.privacy import …` in Phase 25, NOT in P22.

---

### `src/compendium/common/{walk,classify,provenance}.py` (service/lib)

**Analogs (lift verbatim):**
- `walk.py` ← `bin/lib/brownfield_walk.py` (stable names: `walk_vault_respecting_ignore`, `load_brownfield_ignore`, `any_match` — see the import in `bin/brownfield.sh` lines 2066-2069).
- `classify.py` ← `bin/lib/brownfield_classify.py` (stable names: `classify_page`, `unknown_reason` — imported in `bin/brownfield.sh` line 2062).
- `provenance.py` ← `bin/lib/brownfield_provenance.py` (stable name: `section_scan` — imported in `bin/brownfield.sh` line 1101).

Each already has clean `__all__` exports and stable APIs (RESEARCH: 1:1 lift, do NOT split finer — freezing an arbitrary boundary is worse than churn).

---

### `src/compendium/common/page.py` (service/lib, transform) — THE GENUINELY NEW EXTRACTION

**Analog:** NO `bin/lib/` file exists. These primitives live **duplicated inline** in two bash heredocs — `bin/audit-claims.sh` even labels them `# COPIED FROM bin/lint.sh`. This is the exact byte-copy PKG-02 retires. Host ONE copy in `common/page.py`.

**Source A — `bin/lint.sh` (authoritative copy, lines 449-486):**
```python
PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'
    r'(?:\|([^|\]]+))?'
    r'(?:\|([^\]]+))?'
    r'\]'
)
EPISTEMIC_INLINE_RE = re.compile(r'\[epistemic::\s*(sourced|mixed|inferred|tentative|stale)\]')

def parse_frontmatter(filepath):
    """Extract YAML frontmatter and body from a wiki page."""
    try:
        content = open(filepath, encoding='utf-8').read()
    except Exception as e:
        return None, '', str(e)
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'
```

**Also extract from `bin/lint.sh`:** the wikilink regexes (lines 410-416) — `WIKILINK_RE`, `PIPED_LINK_RE`, `BARE_LINK_RE`; the `mask_markdown` masking helper + its four regexes (lines 430-447, `_FENCE_RE`/`_HTMLCOM_RE`/`_INLINE_RE`/`_FM_RE`); and the `EXCLUDE_FILES`/`EXCLUDE_DIRS` sets (lines 458-459).

**The byte-copy to retire — `bin/audit-claims.sh` (lines 145-218):** the explicit "two sources of truth — expected drift risk" comment block (lines 145-154) names every duplicated symbol; `WIKILINK_RE` (173), `PROV_RE` (174-179), `EPISTEMIC_INLINE_RE` (180), `EXCLUDE_*` (181-182), and `parse_frontmatter` (185, commented "COPIED from lint.sh") are verbatim dups of the lint.sh originals above. `parse_frontmatter_str` (audit-claims.sh line 204) is the in-memory variant — host both in `common/page.py`.

**FROZEN once written (D-08).** Phase 25's `lint`/`audit-claims` ports import from here instead of re-inlining.

---

### `bin/<name>.sh` shims (route / process boundary, request-response) — DOCUMENTED IN P22, NOT APPLIED

**Analog:** `bin/pdf-extract.sh` is the established thin-shim-over-heavy-logic model (RESEARCH "Established Patterns"); the Phase-23 *target* form is RESEARCH Pattern 2.

**Target form (Phase 25 — do NOT apply in P22):**
```bash
#!/usr/bin/env bash
# bin/<tool>.sh  (Phase 25 target form)
exec python3 -m compendium.<tool> "$@"      # D-04: module invocation, hermetic
```
**Why `-m` not the console_script (D-04):** works whenever the package is importable, no `PATH` dependency on the install `bin/`. `exec` replaces the bash process so the exit code / signal behavior is Python's directly — preserves the PKG-03 exit-code contract with zero wrapper interference.

**Today's shim shape to preserve byte-identically (the `bin/<tool>.sh` head):** `#!/usr/bin/env bash` + `set -euo pipefail`, a `while [ "$#" -gt 0 ]; do case "$1" in …` arg loop, `usage()` heredoc, then `python3 << 'PYEOF' … PYEOF` (see `bin/pdf-extract.sh` lines 1-6 + 66-119 for the canonical arg-flow). In P22 these stay exactly as-is.

---

### `tests/lib/invoke_tool.sh` + `tests/lib/normalize.sh` (test-harness seam, request-response capture)

**Analog (invocation form being replaced):** the uniform `bash "$REPO_ROOT/bin/<tool>.sh" args... >out 2>err; rc=$?` pattern, e.g. `tests/phase-09/test_lint_strict_new_page.sh:25` and `tests/phase-09/test_lint_skip_category.sh:33-75` (129 invocation-site files; ~371 raw call sites per RESEARCH). The seam intercepts exactly this call.

**Seam body (RESEARCH §Code Examples → invoke_tool), copy verbatim:**
```bash
invoke_tool() {
    local tool="$1"; shift
    local impl="${WIKI_IMPL:-bash}"
    IT_STDOUT="$(mktemp)"; IT_STDERR="$(mktemp)"
    local script="$REPO_ROOT/bin/${tool}.sh"
    LC_ALL=C TZ=UTC bash "$script" "$@" >"$IT_STDOUT" 2>"$IT_STDERR"   # D-12 locale/TZ pin
    IT_EXIT=$?
    return "$IT_EXIT"
}
export -f invoke_tool
```
**Critical seam invariants (Pitfall 3):** run in the test's cwd, pass `"$@"` untouched, stdout→file and stderr→**separate** file (never merged — Pitfall 5), propagate the exact `$?`. Self-parity guard: `WIKI_IMPL=bash` through the seam must `cmp`-equal a direct `bash bin/X.sh` call (`tests/lib/test_invoke_tool_selfparity.sh`).

**4-channel capture + parity diff (RESEARCH `capture_footprint`/`assert_parity`):** stdout, stderr, exit, and a deterministic file-tree manifest (`find . -type f ! -path './.git/*' | sort` + per-file sha256). D-17: include error-path cases (`sync-claude`=2, `gen-skills`=1, `init-wizard`=3, checker exit 2, dual-mode `lint`).

**Normalizer (RESEARCH `normalize`, D-12):** `sed -E` redaction of `/tmp/...`, fixture names, ISO timestamps, dates, 40-char SHA1, 7-12 char short SHAs. **Conservative** — never sort `lint --ci --format json` array order (the `json-to-annotations.py` contract relies on within-severity order). Add a `tests/lib/test_normalize.sh` self-test pinning the redaction set.

**FROZEN surface (D-08).** D-13: route ALL invocations, rewrite NO assertions, leave the 12 `make_*_repo` helpers untouched.

---

### `tests/conftest.py` (pytest harness) — PORT THE BASH FIXTURES

**Analogs:** `tests/phase-10/lib.sh::make_fixture_repo` (lines 20-36) and `tests/phase-13/lib.sh::make_bare_repo` (lines 21-29). The pytest port mirrors these exactly (RESEARCH §Code Examples → conftest).

**`make_bare_repo` → `git_repo` fixture** mirror (bash original, `tests/phase-13/lib.sh:21-29`):
```bash
make_bare_repo() {
    tmp="$(mktemp -d -t phase13-XXXXXX)"
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
}
```
Port to pytest `tmp_path` + `subprocess.run(["git", ...])` — RESEARCH conftest gives the exact `_git()` helper, `git_repo`, `fixture_repo`, and `assert_golden_tree`. Keep the **same git identity** (`fixture@example.com` / `Fixture`) and `commit.gpgsign=false` `--allow-empty` seed so the pytest fixture is behaviorally identical to the bash one.

**`make_fixture_repo` → `fixture_repo` fixture** mirror (bash original, `tests/phase-10/lib.sh:20-36`): copies a `tests/phase-NN/fixtures/<name>/` tree **excluding per-fixture `README.md`** into a seeded repo. Preserve the README.md exclusion exactly.

**`skipif` markers:** mirror the bash curl-probe SKIP idiom (`tests/phase-20/test_pdf_extract_markers.sh` probes Ollama then SKIPs) as `pytest.mark.skipif(not _ollama_up(), ...)`.

---

### Characterization goldens: `validate-op.sh` (zero tests) + `search.sh` untested modes (test, characterization) — D-15/TEST-03

**Analog (assert form):** `tests/phase-10/lib.sh::assert_byte_equal` (lines 41-54) for byte-exact compare; `tests/phase-09/test_lint_skip_category.sh` (lines 33-75) for the multi-mode invoke-and-capture-JSON shape.

**`validate-op.sh` surface to cover** (`bin/validate-op.sh`): 4 operations `UPDATE|MERGE|SUPERSEDE|ARCHIVE` (case at line 205-206); exit `0`=all PASS / `1`=any FAIL-or-usage-error (lines 34-35); the 5 executor checks (`[5/5] MERGE-specific` at line 27); `ARCHIVE` rejects already-archived (line 94), `SUPERSEDE` rejects already-superseded (line 98); MERGE requires two distinct paths (line 215-219); the `print_check N "..." "PASS"` output shape (line 264). Capture all four channels per mode, including the usage-error exit-1 path (D-17).

**`search.sh` modes to cover** (`bin/search.sh`): `--query "Q"` (line 127, LLM-prompt generation), `--paths-only` (line 147), `--fulltext` (line 151), the contributor `--filter` python heredoc (line 183), and the missing-arg exit-1 paths (lines 111-112, 129-130). Default exit `0` on each success path.

**Storage (Claude's discretion, D-11):** golden tree `tests/goldens/<tool>/<case>/{stdout,stderr,exit,tree}` capturing all four channels (RESEARCH recommended layout).

---

### Rewrite anti-signal tests (test, characterization) — D-16/TEST-04

**Analog:** the two existing test files (edit in place).

**`tests/phase-11/test_hashlib_not_sha256sum.sh`** — currently greps `bin/brownfield.sh` + `schema/brownfield/migrations/*.sh` source for the literal `sha256sum` and FAILs if present (lines 14-44). This false-fails a correct Python port. **Rewrite to assert the hash VALUE** (RESEARCH §Code Examples): `expected="$(sha256sum fixtures/known.md | cut -d' ' -f1)"`, run the tool, compare its emitted hash — impl-agnostic.

**`tests/phase-20/test_pdf_extract_markers.sh`** — line 32 source-greps `grep -q 'api/generate' bin/pdf-extract.sh` (anti-signal). The marker-count behavior assertions (lines 72-87) and the Ollama-down SKIP (line 53) are KEEP (genuine behavior). **Quarantine the line-32 source-grep** with a tracking note (RESEARCH Open Q4: the HTTP-stub behavior rewrite rides the MIG-05 wiki-ops port where the HTTP boundary is touched anyway). Note line 28 (`! grep -q 'ollama run'`) is the same class — quarantine alongside.

---

### `.github/workflows/{lint,neutrality,setup-parity}.yml` (config/CI, event-driven) — PKG-04/TEST-02/D-14

**Analog:** the existing jobs in those files + the suite-runner block in `setup-parity.yml` (lines 47-54), which is the precedent for "run a phase suite as a CI step":
```yaml
      - name: Phase 8 full test suite (...)
        run: bash tests/phase-08/run.sh
      - name: Phase 7 regression test suite
        run: bash tests/phase-07/run.sh
```
This confirms **only 07-08 gate today** (TEST-02 wires 09-20). The `run.sh` glob-aggregator each suite exposes (`tests/phase-09/run.sh` iterates `test_*.sh`, tallies, exits non-zero on any failure) is the unit a CI step invokes.

**Existing job/setup pattern to mirror** (`lint.yml` lines 36-52): `actions/checkout@v6` → `actions/setup-python@v6` (python-version `'3.12'`, D-06 — no matrix on existing jobs) → `pip install …` → run. The `pip install pyyaml` lines become `pip install -e .` (pulls pinned deps from pyproject — Pitfall 1).

**Critical constraints (Pitfall 4):**
- Required-check names are a FROZEN public-template branch-protection contract: `lint`, `privacy-leak`, `strict` (lint.yml jobs 33/54/71), `skills-check` (lint.yml job 89), `neutrality`, `setup-parity` (own files). **Never rename. Never add a matrix to an existing required job** (that changes the rendered check name to `lint (bash)` etc.).
- Add suites 09-20 + the `WIKI_IMPL=[bash,py]` matrix (D-14) as **NEW jobs with NEW names** (e.g. `parity-suites (bash)` / `parity-suites (py)`, `common-freeze`).
- `WIKI_IMPL=py` is green-by-fallthrough in P22 (nothing ported). The matrix lights up per-port in Phase 25 with zero CI edits.
- **Do NOT assert universal green for 09-20** (Pitfall 7): suites 07/09/10/11/13 fail identically at base. Record each suite's CURRENT bash status as the baseline; the gate enforces *no regression vs baseline* / `py == bash`, never *universally passing*. Do not scope a task "make suite-NN pass."

**`common-freeze` guard (D-07, new job):** model on the drift gates — `bin/sync-claude.sh --check` (exit 2, `sync-claude.sh:26`) and `bin/gen-skills.sh --check` (exit 1, `gen-skills.sh:11-12`). The guard: `git diff --name-only <baseline>..HEAD -- src/compendium/common/ pyproject.toml tests/lib/` → fail if non-empty (modulo the D-09 escape hatch). Baseline-pin: a `phase-24-freeze` git tag (existing milestone-tag convention `v1.0`..`v1.3` confirmed present), with a committed fallback SHA (RESEARCH A6 — origin is the public template, never pushed; tag is local-only).

---

### `CLAUDE.md` §2 + `AGENTS.md` §2 (config/schema)

**Analog:** the existing §2 line (CLAUDE.md AND AGENTS.md **line 104**, confirmed byte-equal):
```
**Permitted top-level directories:** `sources/`, `wiki-cloud/`, `wiki-local/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. ...
```
**Edit (D-02):** add `src/`. RESEARCH recommends adding `tests/` at the same time (also a real top-level dir absent from the list) to avoid a future lint-routing surprise; `src/` is the locked requirement, `tests/` is the planner's call.

**MANDATORY sequence (the byte-twin contract):** edit `AGENTS.md` FIRST, then `bash bin/sync-claude.sh` (copies AGENTS.md → CLAUDE.md byte-for-byte, `sync-claude.sh:32`), then `bash bin/sync-claude.sh --check` to verify (exit 2 on drift). Never hand-edit CLAUDE.md directly — it would break the `cmp -s AGENTS.md CLAUDE.md` gate. Commit prefix: `schema:` (this is the only schema-body edit; code uses `feat`/`chore`/`test`/`docs` per RESEARCH §Project Constraints).

## Shared Patterns

### Bash → Python heredoc handoff (the form Phase 25 replaces; preserved verbatim in P22)
**Source:** `bin/brownfield.sh` lines 2040-2069 (and `bin/audit-claims.sh` lines 119-143, `bin/lint.sh` lines 255-292).
**Applies to:** every ported tool — the in-heredoc `sys.path.insert(0, os.environ['<X>_LIB_DIR']); from <module> import …` + env-var arg passing is exactly what Phase 25 collapses into `from compendium.common.<m> import …` + argv parsing. P22 leaves all of it byte-identical.
```bash
export <TOOL>_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"
export <TOOL>_ARG="$ARG"            # env-var bash->python handoff
python3 << 'PYEOF'
import os, sys
sys.path.insert(0, os.environ['<TOOL>_LIB_DIR'])
from brownfield_yaml import make_yaml          # ← P23: compendium.common.yaml_rt
PYEOF
```

### Drift-gate-as-CI-check (the freeze-guard precedent)
**Source:** `bin/sync-claude.sh` (`--check` → exit 2 on drift, lines 20-30) and `bin/gen-skills.sh` (`--check` → exit 1 on drift, lines 11-12).
**Applies to:** the new `common-freeze` CI job (D-07) — a baseline-diff check that hard-fails CI, structurally identical to these.

### Test fixture + assertion vocabulary
**Source:** `tests/phase-10/lib.sh` — `make_fixture_repo`, `assert_byte_equal`, `assert_exit_code`, `assert_file_exists`, `assert_grep` (all `export -f`'d).
**Applies to:** the `invoke_tool` seam (reuses the same `$REPO_ROOT` resolution + cwd discipline) and `conftest.py` (ports `make_*_repo` + adds `assert_golden_tree`). D-13: the bash helpers stay UNCHANGED.

### Tool head boilerplate (shim shape)
**Source:** `bin/pdf-extract.sh` lines 1-6 + 66-119, `bin/sync-claude.sh` lines 1-16.
**Applies to:** all ~15 `bin/<tool>.sh` — `#!/usr/bin/env bash` + `set -euo pipefail` + `while/case` arg loop + `usage()` heredoc. P22 preserves; P23 reduces to the one-line `exec python3 -m` form.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `pyproject.toml` | config | declarative-metadata | First Python package in repo — no packaging precedent. Use RESEARCH §Code Examples verbatim (PyPA-cited). |
| `src/compendium/__init__.py` + `common/__init__.py` | package-init | n/a | First Python package — empty/re-export inits; trivial, no analog needed. `common/__init__.py` re-exports the stable names from the 6 lifted modules (RESEARCH 1:1-lift recommendation). |
| `src/compendium/common/page.py` (the primitives) | service/lib | transform | The primitives have NO `bin/lib/` file — they live inline-duplicated in `lint.sh`/`audit-claims.sh` heredocs. "Analog" = the heredoc dup itself (excerpts above); this is the genuinely new extraction work. |

## Metadata

**Analog search scope:** `bin/*.sh` (17), `bin/lib/*.py` (5), `tests/phase-*/` (12 suites, lib.sh + test_*.sh + run.sh), `.github/workflows/*.yml` (3), `CLAUDE.md`/`AGENTS.md` §2.
**Files scanned:** ~30 (targeted reads + greps; large files `lint.sh`/`brownfield.sh`/`audit-claims.sh` read via offset/limit on located ranges, no full loads).
**Confirmed facts:** `AGENTS.md ≡ CLAUDE.md` byte-equal (§2 = line 104); byte-copy of `parse_frontmatter`/`PROV_RE`/`EPISTEMIC_INLINE_RE`/`WIKILINK_RE` between `lint.sh` and `audit-claims.sh` (audit-claims labels it "COPIED from lint.sh"); only suites 07-08 gate today (`setup-parity.yml:52-54`); `make_yaml` chokepoint at `brownfield_yaml.py:164-183`; tags `v1.0`..`v1.3` present (freeze-tag precedent); 129 invocation-site files / 12 phase suites.
**Pattern extraction date:** 2026-06-18

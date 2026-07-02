---
phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - pyproject.toml
  - src/compendium/__init__.py
  - src/compendium/lint.py
  - src/compendium/audit_claims.py
  - src/compendium/brownfield.py
  - src/compendium/check_neutrality.py
  - src/compendium/check_privacy.py
  - src/compendium/check_sources_cloud_safe.py
  - src/compendium/gen_skills.py
  - src/compendium/ingest.py
  - src/compendium/init_wizard.py
  - src/compendium/pdf_extract.py
  - src/compendium/release.py
  - src/compendium/requirements_sync.py
  - src/compendium/search.py
  - src/compendium/sync_claude.py
  - src/compendium/validate_op.py
  - tests/test_packaging.py
  - tests/ported.manifest
  - docs/reference/python-shim-contract.md
  - AGENTS.md
  - CLAUDE.md
autonomous: true
requirements: [PKG-01, PKG-03]
user_setup: []

must_haves:
  decisions:
    - "D-01: package/import name is compendium"
    - "D-02: src/ layout; src/ added to §2 permitted top-level dirs in AGENTS.md+CLAUDE.md"
    - "D-03: per-tool compendium-<tool> console_scripts pre-declared against stub modules"
    - "D-04: bin/<name>.sh shim invokes python3 -m compendium.<tool>"
    - "D-05: pyproject.toml pins requires-python >=3.11"
    - "D-10: worktree isolation and the common/ freeze are complementary, not redundant"
  truths:
    - "pip install -e . succeeds inside a bootstrapped venv (system python3 has no pip)"
    - "import compendium and python3 -m compendium.<tool> resolve for all 15 tools"
    - "pyproject.toml [project.scripts] declares all 15 entry points against stub modules and is frozen (Phase 25 never edits it)"
    - "src/ is added to the §2 permitted top-level dirs in AGENTS.md and CLAUDE.md byte-identically (sync-claude --check exits 0)"
    - "the canonical Phase-23 shim target form is documented + locked, the shim OWNS its own checkout-hermetic PYTHONPATH bootstrap (it does NOT rely on the seam/CI/user-shell having set PYTHONPATH), the WIKI_IMPL seam mechanism describes the WORKTREE oracle for bash AND the bin/<tool>.sh SHIM-on-the-parity-path for py (NO stale committed-copy language), the doc states the parity shim-smoke test exercises the shim with the seam's PYTHONPATH CLEARED so a missing bootstrap is caught (not masked by the seam preload), and a per-tool ported manifest defines which tools the seam routes to python (addresses REVIEWS HIGH#1, HIGH#9, cycle-3 finding #3 doc alignment + the cycle-4 residual: shim-owns-bootstrap-tested-with-seam-env-cleared)"
    - "every bin/<name>.sh still runs its bash body in Phase 24 (no script ported, no shim flipped)"
    - "stub main() exits NONZERO (distinct not-implemented failure) so an accidentally-activated unfinished module fails loudly (addresses REVIEWS MEDIUM 'stubs return success')"
  artifacts:
    - path: "pyproject.toml"
      provides: "Installable package metadata + 15 pre-declared console_scripts + pinned deps + pinned toolchain"
      contains: "[project.scripts]"
    - path: "src/compendium/__init__.py"
      provides: "Top-level package marker"
    - path: "src/compendium/lint.py"
      provides: "Stub entry-point module with main() (exit 70) and __main__ block (template for all 15)"
      contains: "def main"
    - path: "tests/ported.manifest"
      provides: "Per-tool ported? manifest the seam reads (empty in P22 — every tool unported, falls through to bash)"
    - path: "tests/test_packaging.py"
      provides: "PKG-01 install + import smoke test"
    - path: "docs/reference/python-shim-contract.md"
      provides: "The locked shim contract: target form, PYTHONPATH hermeticity OWNED BY THE SHIM (tested with seam env cleared), WIKI_IMPL seam mechanism (WORKTREE oracle for bash + SHIM-on-parity-path for py), ported-manifest (cycle-3 finding #3 doc alignment + cycle-4 residual)"
      contains: "WIKI_IMPL"
  key_links:
    - from: "pyproject.toml [project.scripts]"
      to: "src/compendium/<tool>.py:main"
      via: "console_scripts entry-point binding"
      pattern: "compendium\\.[a-z_]+:main"
    - from: "AGENTS.md §2"
      to: "CLAUDE.md §2"
      via: "bin/sync-claude.sh byte-twin propagation"
      pattern: "src/"
---

<objective>
Build the installable `compendium` src-layout package skeleton: `pyproject.toml` with pinned runtime deps + pinned build/test toolchain and all 15 `console_scripts` pre-declared against trivial stub modules; the per-tool `ported.manifest` the parity seam reads to decide bash-vs-py routing; the locked shim-contract doc (target form + PYTHONPATH hermeticity + the WIKI_IMPL seam mechanism); and the one schema-body edit that adds `src/` to the permitted top-level directories (AGENTS.md-first, then sync-claude propagates to CLAUDE.md).

Purpose: This is the frozen packaging surface (D-08). Phase-23 plans FILL the stub module bodies, flip each shim, and flip the tool's line in `ported.manifest` — they never touch `pyproject.toml` or its `[project.scripts]` table. Pre-declaring every entry point now is what makes the Phase-23 migration wave conflict-free. The shim-contract doc resolves the parity-oracle mechanism up front (addresses REVIEWS HIGH#1) and makes the local execution path checkout-hermetic (addresses REVIEWS HIGH#9) so unchanged callers never hit `ModuleNotFoundError`. CYCLE-3 finding #3 doc alignment: the doc must describe the WORKTREE oracle for the bash leg AND the `bin/<tool>.sh` SHIM ON THE PARITY PATH for the py leg, matching what Plan 03 implements — with NO stale "COMMITTED COPY under tests/oracle/" language (that flat-cp mechanism was removed by Plan 03's worktree). CYCLE-4 finding #3 residual: the doc must state the shim OWNS its own checkout-hermetic PYTHONPATH bootstrap and that Plan 03's shim-smoke test exercises it with the seam's `PYTHONPATH` CLEARED (so a bootstrap-free shim is CAUGHT, not masked by the seam's preload).

Output: `pyproject.toml`, `src/compendium/` with `__init__.py` + 15 stub modules, `tests/ported.manifest`, `tests/test_packaging.py`, `docs/reference/python-shim-contract.md`, and the `src/` addition to AGENTS.md/CLAUDE.md §2.
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
<!-- The 15 in-scope tools (enumerated from `ls bin/*.sh` = 17 minus install-hooks.sh [stays bash, MIG-06] and migrate-privacy-dirs.sh [retired, MIG-06]). -->
<!-- command name (hyphen)  ->  module name (underscore)  ->  binding -->
compendium-lint                     -> compendium.lint                     -> "compendium.lint:main"
compendium-audit-claims             -> compendium.audit_claims             -> "compendium.audit_claims:main"
compendium-brownfield               -> compendium.brownfield               -> "compendium.brownfield:main"
compendium-check-neutrality         -> compendium.check_neutrality         -> "compendium.check_neutrality:main"
compendium-check-privacy            -> compendium.check_privacy            -> "compendium.check_privacy:main"
compendium-check-sources-cloud-safe -> compendium.check_sources_cloud_safe -> "compendium.check_sources_cloud_safe:main"
compendium-gen-skills               -> compendium.gen_skills               -> "compendium.gen_skills:main"
compendium-ingest                   -> compendium.ingest                   -> "compendium.ingest:main"
compendium-init-wizard              -> compendium.init_wizard              -> "compendium.init_wizard:main"
compendium-pdf-extract              -> compendium.pdf_extract              -> "compendium.pdf_extract:main"
compendium-release                  -> compendium.release                  -> "compendium.release:main"
compendium-requirements-sync        -> compendium.requirements_sync        -> "compendium.requirements_sync:main"
compendium-search                   -> compendium.search                   -> "compendium.search:main"
compendium-sync-claude              -> compendium.sync_claude              -> "compendium.sync_claude:main"
compendium-validate-op              -> compendium.validate_op              -> "compendium.validate_op:main"
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write pyproject.toml + src-layout package skeleton with 15 stub modules (stubs exit NONZERO)</name>
  <files>pyproject.toml, src/compendium/__init__.py, src/compendium/lint.py, src/compendium/audit_claims.py, src/compendium/brownfield.py, src/compendium/check_neutrality.py, src/compendium/check_privacy.py, src/compendium/check_sources_cloud_safe.py, src/compendium/gen_skills.py, src/compendium/ingest.py, src/compendium/init_wizard.py, src/compendium/pdf_extract.py, src/compendium/release.py, src/compendium/requirements_sync.py, src/compendium/search.py, src/compendium/sync_claude.py, src/compendium/validate_op.py</files>
  <read_first>
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md (§Code Examples → pyproject.toml; §Architecture Patterns → Pattern 1 stub; Pitfall 1 [no pip], Pitfall 8 [packages.find required])
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (pyproject.toml section; the ~15 stub-module section; module-name underscore note)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (MEDIUM "Stubs return success" — make stubs exit nonzero; LOW "Toolchain determinism" — pin pytest + setuptools)
    - bin/lib/brownfield_yaml.py (confirm PyYAML import is `import yaml` — line 34 — so the dep pin name is `PyYAML`)
  </read_first>
  <action>
Create `pyproject.toml` at repo root with EXACTLY this content (D-01/D-02/D-03/D-05; pin PyYAML to the INSTALLED 6.0.1 per RESEARCH Open Q1 — the committed brownfield goldens were generated under 6.0.1 and the parity bar is byte-exact against today's output; a 6.0.1→6.0.3 bump is a separate parity-validated change, NOT folded here). Per REVIEWS LOW "Toolchain determinism": PIN the build backend exactly (`setuptools==80.9.0`, not `>=`) and PIN pytest exactly (`pytest==8.4.1`) so the foundation toolchain is reproducible — a floating backend/test runner is a parity-stability risk:

```toml
[build-system]
requires = ["setuptools==80.9.0"]
build-backend = "setuptools.build_meta"

[project]
name = "compendium"
version = "1.4.0"
requires-python = ">=3.11"
dependencies = [
    "PyYAML==6.0.1",
    "ruamel.yaml==0.19.1",
]

[project.optional-dependencies]
dev = ["pytest==8.4.1"]

[project.scripts]
compendium-lint                     = "compendium.lint:main"
compendium-audit-claims             = "compendium.audit_claims:main"
compendium-brownfield               = "compendium.brownfield:main"
compendium-check-neutrality         = "compendium.check_neutrality:main"
compendium-check-privacy            = "compendium.check_privacy:main"
compendium-check-sources-cloud-safe = "compendium.check_sources_cloud_safe:main"
compendium-gen-skills               = "compendium.gen_skills:main"
compendium-ingest                   = "compendium.ingest:main"
compendium-init-wizard              = "compendium.init_wizard:main"
compendium-pdf-extract              = "compendium.pdf_extract:main"
compendium-release                  = "compendium.release:main"
compendium-requirements-sync        = "compendium.requirements_sync:main"
compendium-search                   = "compendium.search:main"
compendium-sync-claude              = "compendium.sync_claude:main"
compendium-validate-op              = "compendium.validate_op:main"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
markers = [
    "requires_ollama: test needs a reachable Ollama endpoint",
    "requires_network: test needs network egress",
]
```

(If `setuptools==80.9.0` or `pytest==8.4.1` are unavailable at execute time, pin to the latest installable exact version and record the chosen version in the SUMMARY — the requirement is an exact `==` pin, not a specific number.)

Create `src/compendium/__init__.py` as an empty file (package marker; first Python package in repo — no analog needed).

Create the 15 stub modules. Each uses the underscore name (Python import rule) and follows this EXACT shape. CRITICAL CHANGE FROM PRIOR DESIGN (addresses REVIEWS MEDIUM "Stubs return success"): the stub MUST exit NONZERO with a distinct sentinel code (`70`, EX_SOFTWARE — chosen to never collide with any real tool exit code: tools use 0/1/2/3, never 70). In Phase 24 the bin/<tool>.sh shim still runs its bash body, so the stub is NEVER on the hot path; the only legitimate caller is the PKG-01 import smoke test (which imports the module — it does NOT run `main()` for the bash-routed tools). An accidentally-activated unfinished module must fail LOUDLY (distinct "not implemented" failure), never silently exit 0 and mask a missed port. Substitute the tool name in the message:

```python
# src/compendium/lint.py  (STUB — Phase 24; filled in Phase 25 MIG-02)
import sys

NOT_IMPLEMENTED_EXIT = 70  # EX_SOFTWARE sentinel — distinct from every real tool code (0/1/2/3)


def main(argv=None):
    # Phase 24: not yet ported. The bin/lint.sh shim still runs its bash body;
    # this stub exists only so the entry point resolves at install time.
    # It exits NONZERO so an accidentally-activated unfinished module fails loudly
    # (REVIEWS MEDIUM: a stub that exits 0 could mask a missed Phase-23 port).
    print("compendium.lint: not yet implemented (Phase 25)", file=sys.stderr)
    return NOT_IMPLEMENTED_EXIT


if __name__ == "__main__":          # enables `python3 -m compendium.lint`
    sys.exit(main(sys.argv[1:]))
```

Write one such stub for each of: lint, audit_claims, brownfield, check_neutrality, check_privacy, check_sources_cloud_safe, gen_skills, ingest, init_wizard, pdf_extract, release, requirements_sync, search, sync_claude, validate_op. The `if __name__ == "__main__"` block is REQUIRED so the D-04 `python3 -m compendium.<tool>` shim form works in Phase 25.

Do NOT create a `src/compendium/common/` directory in this plan — Plan 02 owns it. Do NOT create the `__main__.py` package dispatch (not required). Do NOT touch `bin/` (no shim is flipped in Phase 24).
  </action>
  <verify>
    <automated>python3 -c "import tomllib; d=tomllib.load(open('pyproject.toml','rb')); s=d['project']['scripts']; assert len(s)==15, f'expected 15 scripts got {len(s)}'; assert d['project']['dependencies']==['PyYAML==6.0.1','ruamel.yaml==0.19.1'], d['project']['dependencies']; assert d['project']['requires-python']=='>=3.11'; assert d['tool']['setuptools']['packages']['find']['where']==['src']; assert d['build-system']['requires'][0].startswith('setuptools=='), d['build-system']['requires']; print('pyproject OK')"</automated>
  </verify>
  <acceptance_criteria>
    - `python3 -c "import tomllib; d=tomllib.load(open('pyproject.toml','rb')); print(len(d['project']['scripts']))"` prints `15`
    - `grep -c ':main"' pyproject.toml` returns `15`
    - `grep -q 'requires-python = ">=3.11"' pyproject.toml` exits 0
    - `grep -q 'PyYAML==6.0.1' pyproject.toml && grep -q 'ruamel.yaml==0.19.1' pyproject.toml` exits 0
    - `grep -qE 'setuptools==[0-9]' pyproject.toml` exits 0 (build backend PINNED, not floated — REVIEWS LOW)
    - `grep -qE 'pytest==[0-9]' pyproject.toml` exits 0 (pytest PINNED — REVIEWS LOW)
    - `grep -q 'where = \["src"\]' pyproject.toml` exits 0
    - `ls src/compendium/*.py | grep -vc __init__` returns `15`
    - `test -f src/compendium/__init__.py` exits 0
    - `python3 -c "import sys; sys.argv=['x']; from importlib import import_module; m=import_module('compendium.lint') if False else None" 2>/dev/null; grep -c 'return NOT_IMPLEMENTED_EXIT' src/compendium/lint.py` returns `1` (stub returns the nonzero sentinel)
    - `for f in src/compendium/*.py; do [ "$(basename $f)" = __init__.py ] && continue; grep -q 'NOT_IMPLEMENTED_EXIT = 70' "$f" || { echo "STUB EXIT-0 LEAK: $f"; exit 1; }; done; echo all-stubs-nonzero` prints `all-stubs-nonzero` (every stub exits 70, not 0 — REVIEWS MEDIUM)
    - `grep -lc 'if __name__ == "__main__"' src/compendium/lint.py` returns 1 (and the same holds for every stub)
    - `test ! -d src/compendium/common` exits 0 (Plan 02 owns common/)
    - `git diff --name-only HEAD -- bin/ | wc -l` returns `0` (no bin/ changes)
  </acceptance_criteria>
  <done>pyproject.toml frozen-surface declares 15 entry points + pinned runtime deps + pinned build/test toolchain + src-layout config; all 15 import-light stub modules exist with main() that exits the nonzero sentinel 70 + __main__ block; bin/ untouched.</done>
</task>

<task type="auto">
  <name>Task 2: Per-tool ported.manifest + PKG-01 install smoke test + add src/ to AGENTS.md §2 (sync to CLAUDE.md)</name>
  <files>tests/ported.manifest, tests/test_packaging.py, AGENTS.md, CLAUDE.md</files>
  <read_first>
    - AGENTS.md (read §2 "Permitted top-level directories" line — confirmed at line 104 by the pattern mapper; see the exact current value below)
    - bin/sync-claude.sh (confirm: `bash bin/sync-claude.sh` copies AGENTS.md → CLAUDE.md; `--check` exits 2 on drift)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (CLAUDE.md §2 + AGENTS.md §2 section — the MANDATORY byte-twin sequence)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md (Pitfall 1 [pip absent → venv bootstrap]; Environment Availability table)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#1 — the per-tool ported manifest is the seam's bash-vs-py switch)
  </read_first>
  <action>
**Part A — the per-tool ported manifest (addresses REVIEWS HIGH#1).** Create `tests/ported.manifest` — a frozen-surface file the parity seam (Plan 03) reads to decide, per tool, whether `WIKI_IMPL=py` runs the Python entry point (THROUGH the bin/<tool>.sh shim — cycle-3 finding #3) or falls through to the held-fixed bash oracle. Format: one `tool` token per line (bare name, e.g. `lint`), plus comment lines starting `#`. In Phase 24 NO tool is ported, so the manifest contains ONLY the header comment and ZERO tool lines — every tool falls through to bash and the matrix stays green-by-fallthrough. Each Phase-23 cluster port appends its tool name here (one line) as it flips the shim. Write exactly:

```
# tests/ported.manifest — the parity seam's per-tool bash-vs-py switch (REVIEWS HIGH#1).
# One bare tool name per non-comment line means: WIKI_IMPL=py runs the Python entry point for that
# tool THROUGH its bin/<tool>.sh shim (cycle-3 finding #3 — so a broken shim is caught on the parity
# path); a tool ABSENT here falls through to the held-fixed bash WORKTREE oracle even under WIKI_IMPL=py,
# so it stays green in Phase 24 and parity-gated in Phase 25. Phase 24 ports NOTHING, so there are ZERO
# tool lines below. Each Phase-23 cluster port APPENDS its tool name as it flips bin/<tool>.sh. This file
# is FROZEN surface (D-08) for its EXISTENCE + FORMAT; the deliberate-additions escape hatch (D-09)
# governs appends — the common-freeze guard (Plan 06) excludes this file's content from the freeze (it is
# a controlled per-port mutation, see Plan 06). N-4: a non-empty manifest with no pinned freeze baseline
# makes the oracle FAIL LOUDLY rather than silently fall to HEAD (Plan 03).
```

(NOTE: `ported.manifest` is the ONE mutable shared file Phase-23 ports must edit; Plan 06 assigns it an explicit owner-per-append and excludes it from the blanket freeze — see Plan 06 frozen-surface scope. Do not list any tool here in Phase 24.)

**Part B — PKG-01 install smoke test.** Create `tests/test_packaging.py`. Because system python3 has NO pip (`No module named pip`), the test MUST bootstrap an isolated venv and install into it. Use `python3 -m venv` + the venv's pip. Concretely the test:
1. Creates a venv in a `tmp_path` (`python3 -m venv <tmp>/.venv`).
2. Runs `<tmp>/.venv/bin/pip install -e .` from the repo root (cwd = repo root) — asserts exit 0.
3. Runs `<tmp>/.venv/bin/python -c "import compendium, compendium.lint, compendium.validate_op"` — asserts exit 0 (importability, PKG-01).
4. Runs `<tmp>/.venv/bin/python -m compendium.lint` — asserts the documented stub behavior: exit `70` (the NOT_IMPLEMENTED sentinel) and stderr contains `not yet implemented` (this pins the D-04 module-invocation form works AND that the stub fails loudly per REVIEWS MEDIUM). Note: `proc.returncode == 70`, NOT 0 — this is the changed contract from the prior plan.

Write it as a pytest test (`def test_editable_install_and_imports(tmp_path):`) using `subprocess.run([...], check=False)` and `assert proc.returncode == 0` (for install/import) / `assert proc.returncode == 70` (for the stub invocation). Resolve the repo root as `pathlib.Path(__file__).resolve().parent.parent`. Include `proc.stderr` in each assertion message so a pip failure is legible. Do NOT assume a usable system pip — the venv is mandatory.

**Part C — schema §2 edit (AGENTS.md-first, then sync).** The current §2 line in AGENTS.md (and its byte-twin CLAUDE.md) reads:

```
**Permitted top-level directories:** `sources/`, `wiki-cloud/`, `wiki-local/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. ...
```

Edit ONLY `AGENTS.md`: add `` `src/` `` to the list (D-02). Add `` `tests/` `` at the same time — it is also a real top-level dir absent from the list, and adding both now avoids a future lint-routing surprise (RESEARCH §Project Constraints recommends adding both). Place them after `` `bin/` ``:

```
**Permitted top-level directories:** `sources/`, `wiki-cloud/`, `wiki-local/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `src/`, `tests/`, `.githooks/`. ...
```

Then run `bash bin/sync-claude.sh` to propagate AGENTS.md → CLAUDE.md byte-for-byte. Then run `bash bin/sync-claude.sh --check` and confirm it exits 0. NEVER hand-edit CLAUDE.md directly. Preserve the rest of the §2 line verbatim — only insert the two new entries.
  </action>
  <verify>
    <automated>test -f tests/ported.manifest && [ "$(grep -vcE '^#|^$' tests/ported.manifest)" = "0" ] && grep -q 'src/' AGENTS.md && grep -q '`tests/`' AGENTS.md && bash bin/sync-claude.sh --check; echo "checks exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `test -f tests/ported.manifest` exits 0
    - `grep -vcE '^#|^$' tests/ported.manifest` returns `0` (ZERO tool lines in P22 — nothing ported; only comments)
    - `grep -q 'WIKI_IMPL=py' tests/ported.manifest` exits 0 (the manifest documents its role as the seam's bash-vs-py switch)
    - `grep -qiE 'shim|bin/<tool>.sh' tests/ported.manifest` exits 0 (the py lane runs the SHIM — cycle-3 finding #3)
    - `grep -F '`src/`' AGENTS.md` exits 0 (src/ present in §2)
    - `grep -F '`tests/`' AGENTS.md` exits 0 (tests/ present in §2)
    - `bash bin/sync-claude.sh --check` exits 0 (AGENTS.md ≡ CLAUDE.md byte-equal after sync)
    - `cmp -s AGENTS.md CLAUDE.md` exits 0
    - `grep -F '`src/`' CLAUDE.md` exits 0 (propagated to the byte-twin)
    - `grep -q 'venv' tests/test_packaging.py` exits 0 (test bootstraps a venv — does not assume system pip)
    - `grep -q 'pip.*install.*-e' tests/test_packaging.py` exits 0 (editable install exercised)
    - `grep -qE 'returncode == 70|== 70' tests/test_packaging.py` exits 0 (asserts the NONZERO stub sentinel — REVIEWS MEDIUM)
    - `grep -q 'not yet implemented' tests/test_packaging.py` exits 0 (asserts the stub stderr via `python -m`)
    - Running the test in a venv passes: `python3 -m venv /tmp/p22v && /tmp/p22v/bin/pip -q install pytest -e . && /tmp/p22v/bin/python -m pytest tests/test_packaging.py -q` exits 0
  </acceptance_criteria>
  <done>tests/ported.manifest exists with zero tool lines (P22 ports nothing) and documents the py-lane-via-shim switch (cycle-3 finding #3); PKG-01 install/import smoke test passes inside a bootstrapped venv and asserts the nonzero stub sentinel (70); src/ and tests/ added to §2 of AGENTS.md and propagated byte-identically to CLAUDE.md (sync-claude --check exit 0).</done>
</task>

<task type="auto">
  <name>Task 3: Document + lock the shim contract — target form, PYTHONPATH hermeticity OWNED BY THE SHIM (tested with seam env cleared), the WIKI_IMPL seam mechanism (WORKTREE oracle for bash + SHIM-on-parity-path for py), the ported manifest (PKG-03; addresses REVIEWS HIGH#1, HIGH#9, cycle-3 finding #3 doc alignment + cycle-4 finding #3 residual)</name>
  <files>docs/reference/python-shim-contract.md</files>
  <read_first>
    - bin/pdf-extract.sh (READ lines 1-6 + the python3 heredoc head -- the established thin-shim-over-heavy-logic model; the `#!/usr/bin/env bash` + `set -euo pipefail` + arg-flow shape the shims preserve in P22)
    - bin/sync-claude.sh (READ lines 1-16 -- another shim head shape to reference)
    - .githooks/pre-commit (READ FULLY -- the real local gate; the sync-claude -> gen-skills -> lint hot path; these calls MUST keep working when bin/<tool>.sh flips to python -- HIGH#9)
    - bin/install-hooks.sh (READ FULLY -- 5-line git config; left as bash MIG-06; it does NOT install the package -- the hermeticity strategy must not depend on it)
    - .claude/settings.local.json (READ -- confirm it invokes `bash bin/validate-op.sh ...` / `bash tests/phase-NN/run.sh`; these callers MUST keep working unchanged -- PKG-03)
    - tests/lib/test_shim_smoke.sh + tests/lib/invoke_tool.sh (Plan 03 — confirm the doc's "shim-smoke runs with the seam PYTHONPATH UNSET" clause matches Plan 03's test; the seam exports PYTHONPATH for the normal lane but the smoke test must clear it — cycle-4 finding #3)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the `bin/<name>.sh` shims section -- RESEARCH Pattern 2 target form, the `-m`-not-console_script rationale, the "today's shim shape to preserve byte-identically" note)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md (Pattern 2 [thin exec-shim]; D-04 [module invocation, hermetic]; the Anti-Pattern "Touching the bash bodies or bin/lib in Phase 24")
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#1 [seam mechanism], HIGH#9 [package install breaks local callers — PYTHONPATH self-bootstrap], cycle-3 finding #3 [the py PARITY lane runs the shim], cycle-4 finding #3 residual / Codex new-HIGH #2 [the seam's PYTHONPATH preload MASKS a bootstrap-free shim — the doc must state the shim OWNS the bootstrap + the smoke test runs with seam PYTHONPATH cleared])
  </read_first>
  <action>
PKG-03's Phase-22 deliverable is to DOCUMENT + LOCK the canonical shim target form, the checkout-hermetic execution strategy, AND the parity-oracle mechanism so the Phase-23 ports are mechanical and the local gate never breaks. Phase 24 ports NOTHING and flips NO shim. Create `docs/reference/python-shim-contract.md` (a tooling reference doc -- NOT a wiki schema body edit; per RESEARCH Project Constraints, packaging conventions belong in code/docs, never in `schema/reference/*.md`). It must contain, verbatim:

1. **The canonical Phase-23 shim target form, made checkout-hermetic (D-04 + REVIEWS HIGH#9).** The prior bare `exec python3 -m compendium.<tool> "$@"` form fails with `ModuleNotFoundError` on a checkout where the package was never `pip install -e .`'d (install-hooks.sh + the pre-commit hook + the user shell do NOT install the package). The LOCKED form self-bootstraps `PYTHONPATH` so the import resolves from the in-tree `src/` without requiring an editable install:
```bash
#!/usr/bin/env bash
# bin/<tool>.sh  (Phase 25 target form -- NOT applied in Phase 24)
# Self-bootstrapping: resolve REPO_ROOT, prepend src/ to PYTHONPATH so `import compendium`
# works on a bare checkout (no `pip install -e .` required). This keeps install-hooks.sh +
# .githooks/pre-commit + the user shell working unchanged (REVIEWS HIGH#9 — no ModuleNotFoundError).
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.<tool> "$@"
```
State explicitly: this is the SINGLE consistently-applied hermeticity strategy (chosen over "make every caller run `pip install -e .`"), applied identically across every `bin/<tool>.sh` shim, and it requires NO change to `install-hooks.sh` (stays bash, MIG-06) or `.githooks/pre-commit`. The pinned runtime deps (PyYAML, ruamel.yaml) must still be importable — document that CI installs them via `pip install -e .` (Plan 05) and the local dev path installs them once into the user environment or a venv; the `src/`-on-PYTHONPATH bootstrap covers the `compendium` package itself, the deps cover the third-party imports.

**1a. THE SHIM OWNS ITS OWN PYTHONPATH BOOTSTRAP — and the parity test exercises it with the seam env CLEARED (REVIEWS cycle-3 finding #3 residual / Codex new-HIGH #2 — the cycle-4 fix).** Add this as a LOCKED contract clause, verbatim in the doc: the `bin/<tool>.sh` shim is RESPONSIBLE for prepending `src/` to `PYTHONPATH` itself (the `_REPO_ROOT`/`export PYTHONPATH` lines above) — it must NOT rely on any caller (CI, the parity seam, or the user shell) having set `PYTHONPATH` for it. The parity seam in Plan 03 ALSO exports `PYTHONPATH=$REPO_ROOT/src` for the NORMAL parity lane (cycle-1 hermeticity), but that export would MASK a shim that is missing its own bootstrap (a bootstrap-free `exec python3 -m compendium.<tool> "$@"` would still import, because the seam pre-set the path). Therefore the parity contract REQUIRES that Plan 03's shim-smoke test (`tests/lib/test_shim_smoke.sh`) runs the shim with the seam's `PYTHONPATH` (and any other seam-injected env that could mask the bootstrap) UNSET, proving the canonical shim (with its own bootstrap) SUCCEEDS while a bootstrap-free shim FAILS with `ModuleNotFoundError`. Document that this seam-env-cleared smoke check is the mechanism that keeps the shim's self-bootstrap a real, tested part of the PKG-03 contract rather than a coincidence of the seam's preload. State that the seam's `PYTHONPATH` export for the normal lane is NOT removed (the normal lane stays hermetic — REVIEWS must_not_regress); only the dedicated shim-smoke test clears it.

2. **Why `-m` not the console_script (D-04):** `python3 -m compendium.<tool>` works whenever `compendium` is importable (now guaranteed by the PYTHONPATH bootstrap), independent of whether the install's `bin/` is on PATH. `exec` replaces the bash process so exit code / signal behavior is the Python process's directly, preserving the PKG-03 exit-code contract.

3. **The WIKI_IMPL parity-oracle mechanism (the headline fix — addresses REVIEWS HIGH#1 + cycle-3 finding #3 doc alignment).** Document, as the locked design Plan 03 IMPLEMENTS (match it exactly — no stale language) and Phase 25 relies on:
   - `WIKI_IMPL=bash` ALWAYS executes the held-fixed Phase-22 BASH oracle, NEVER the (eventually-python) shim — so it is invariant across the migration even after a shim flips to python.
   - **The held-fixed bash oracle is a GIT WORKTREE checked out at the pinned baseline ref** (`tests/lib/oracle-worktree.sh`: `git worktree add --detach <wt> <ref>`, then run `<wt>/bin/<tool>.sh`). It is NOT a `cp` of a single `.sh` into a flat `tests/oracle/` dir (that flat-cp mechanism was REMOVED by Plan 03 — REVIEWS HIGH#1 keystone: a flat copy breaks every script that resolves its libs relative to `$0`, e.g. `audit-claims.sh`'s `AUDIT_LIB_DIR`, `brownfield.sh`'s `$(dirname $0)/..`, `gen-skills.sh`'s `$SCRIPT_DIR/..`). The worktree preserves the full `bin/`-relative layout so those resolve their REAL libs. DO NOT describe a "COMMITTED COPY under tests/oracle/" — that language is stale and contradicts the implementation.
   - **`WIKI_IMPL=py` runs the `bin/<tool>.sh` SHIM (`bash $REPO_ROOT/bin/<tool>.sh`, which itself execs `python3 -m compendium.<tool>`) ON THE PARITY PATH** — NOT `python3 -m compendium.<tool>` directly — ONLY IF the tool is listed in `tests/ported.manifest`; an unported tool falls through to the held-fixed bash worktree oracle even under `WIKI_IMPL=py`. Running the actual shim on the parity path is what catches a BROKEN shim (bad PYTHONPATH/quoting/module-name/exec) — the shim is part of the PKG-03 contract and must be exercised, not bypassed (cycle-3 finding #3). The seam still exports the hermetic `PYTHONPATH=$REPO_ROOT/src` + `LC_ALL=C` + `TZ=UTC` for the normal lane so the shim inherits the cycle-1 hermeticity; the dedicated shim-smoke test (1a) is the ONLY place that clears the seam `PYTHONPATH`, to prove the shim's own bootstrap is real.
   - THIS is what yields a real bash-vs-py differential: for a ported tool, `bash` runs the frozen bash worktree oracle and `py` runs the shim→python, and the harness diffs them byte-for-byte across 4 channels.
   - In Phase 24 the manifest is empty → both legs run the bash worktree oracle → green-by-fallthrough with zero porting, exactly as the success criteria require.

4. **The contract each shim must preserve byte-for-byte (PKG-03):** exact argv passthrough (`"$@"` untouched), exact exit-code propagation, stdout-vs-stderr discipline (diagnostics->stderr, payload->stdout), and cwd. List the divergent exit codes that MUST be preserved: `sync-claude`=2, `gen-skills`=1, `init-wizard`=3 (pre-flight) and =4 (already-initialized), checkers=2, `lint` dual-mode. State that `init-wizard` exit 3 (pre-flight dependency check) is a Phase-23 COMPAT BOUNDARY the `.sh` shim must preserve BEFORE invoking Python (a Python port cannot detect "python3 missing" from inside python3) — the shim-level preflight-preservation contract test that enforces this lives in Plan 04 (cross-reference it here so the Phase-23 init-wizard port knows the shim, not the Python module, owns the exit-3 preflight).

5. **Downstream callers that invoke the shims unchanged:** CI workflows, `.githooks/pre-commit` (the `sync-claude -> gen-skills -> lint` hot path — note this is the REAL local gate, REVIEWS HIGH#12), schema docs, and `.claude/settings.local.json` (which calls `bash bin/validate-op.sh ...`). These keep invoking `bash bin/<tool>.sh` with no change across the migration BECAUSE of the PYTHONPATH self-bootstrap.

6. **Phase-22 invariant:** every `bin/<name>.sh` still runs its ORIGINAL bash body in Phase 24; `WIKI_IMPL=py` falls through to the bash worktree oracle for every tool because the manifest is empty. Deleting `bin/lib/` or editing any bash body in Phase 24 is forbidden.

Use abstract placeholders (`<tool>`) -- neutrality rule. Then VERIFY (as part of this task) that `git diff --name-only HEAD -- bin/` is empty -- confirming Phase 24 ports nothing and flips no shim. Commit prefix for this doc is `docs:` (not a schema-body edit).
  </action>
  <verify>
    <automated>test -f docs/reference/python-shim-contract.md && grep -q 'exec python3 -m compendium' docs/reference/python-shim-contract.md && grep -q 'PYTHONPATH' docs/reference/python-shim-contract.md && grep -q 'ported.manifest' docs/reference/python-shim-contract.md && grep -q 'git worktree' docs/reference/python-shim-contract.md && ! grep -qi 'COMMITTED COPY' docs/reference/python-shim-contract.md && git diff --name-only HEAD -- bin/ | wc -l</automated>
  </verify>
  <acceptance_criteria>
    - `test -f docs/reference/python-shim-contract.md` exits 0
    - `grep -q 'exec python3 -m compendium.<tool>' docs/reference/python-shim-contract.md` exits 0 (canonical target form documented)
    - `grep -q 'PYTHONPATH=' docs/reference/python-shim-contract.md` exits 0 (the checkout-hermetic self-bootstrap — REVIEWS HIGH#9)
    - `grep -q 'ModuleNotFoundError' docs/reference/python-shim-contract.md` exits 0 (the failure mode HIGH#9 prevents is named)
    - `grep -qiE 'shim OWNS|owns its own.*bootstrap|shim is RESPONSIBLE' docs/reference/python-shim-contract.md` exits 0 (cycle-4 finding #3: the shim OWNS its own PYTHONPATH bootstrap, not the seam)
    - `grep -qiE 'seam.*PYTHONPATH.*(unset|cleared)|PYTHONPATH.*(unset|cleared).*shim-smoke|smoke.*seam.*PYTHONPATH' docs/reference/python-shim-contract.md` exits 0 (cycle-4 finding #3: the shim-smoke test runs with the seam PYTHONPATH cleared so a missing bootstrap is caught, not masked)
    - `grep -qiE 'mask|masked|coincidence of the seam' docs/reference/python-shim-contract.md` exits 0 (the masking failure mode the cycle-4 fix prevents is named)
    - `grep -q 'WIKI_IMPL=bash' docs/reference/python-shim-contract.md && grep -q 'WIKI_IMPL=py' docs/reference/python-shim-contract.md` exits 0 (the seam mechanism — REVIEWS HIGH#1)
    - `grep -q 'held-fixed' docs/reference/python-shim-contract.md && grep -q 'ported.manifest' docs/reference/python-shim-contract.md && grep -q 'git worktree' docs/reference/python-shim-contract.md` exits 0 (held-fixed bash WORKTREE oracle + per-tool manifest — REVIEWS HIGH#1, cycle-3 finding #3 doc alignment)
    - `! grep -qi 'COMMITTED COPY' docs/reference/python-shim-contract.md && ! grep -qE 'tests/oracle/' docs/reference/python-shim-contract.md` (the STALE flat-cp committed-copy language is GONE — cycle-3 finding #3 doc alignment, matches Plan 03's worktree)
    - `grep -qiE 'py.*lane.*shim|shim.*on the parity path|bash .*bin/<tool>.sh' docs/reference/python-shim-contract.md` exits 0 (the py PARITY lane runs the SHIM, not python3 -m directly — cycle-3 finding #3)
    - `grep -qiE 'init-wizard.*exit 3|exit 3.*preflight|exit 3.*pre-flight|preflight.*shim|shim.*preflight' docs/reference/python-shim-contract.md` exits 0 (the exit-3 preflight COMPAT BOUNDARY the shim must preserve before invoking Python — cross-ref to Plan 04's shim-level test, finding #2)
    - `grep -q 'NOT applied in Phase 24' docs/reference/python-shim-contract.md` exits 0 (P22 ports nothing)
    - `grep -qE 'sync-claude.*2|init-wizard.*3|gen-skills.*1' docs/reference/python-shim-contract.md` exits 0 (divergent exit codes locked)
    - `grep -q 'settings.local.json' docs/reference/python-shim-contract.md && grep -q 'pre-commit' docs/reference/python-shim-contract.md` exits 0 (downstream callers + the real local gate enumerated)
    - `git diff --name-only HEAD -- bin/ | wc -l` returns `0` (no shim flipped, no bash body touched, bin/lib intact)
    - `bash bin/check-neutrality.sh` exits 0 (the new doc uses placeholders, not vault terms) -- run if available
  </acceptance_criteria>
  <done>docs/reference/python-shim-contract.md locks the checkout-hermetic `exec python3 -m compendium.<tool>` shim form (PYTHONPATH self-bootstrap — HIGH#9) OWNED BY THE SHIM (not the seam) with the doc stating Plan 03's shim-smoke test runs with the seam PYTHONPATH cleared so a bootstrap-free shim is caught not masked (cycle-4 finding #3); the WIKI_IMPL seam mechanism with the held-fixed bash WORKTREE oracle (NOT a stale committed-copy under tests/oracle/) + the py PARITY lane running the bin/<tool>.sh SHIM (cycle-3 finding #3 doc alignment) + ported.manifest (HIGH#1); the argv/exit/stdout-stderr contract + divergent exit codes (incl. init-wizard 3 [a shim-preserved preflight compat boundary, cross-ref Plan 04] and 4), and the downstream callers; bin/ verified untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `pip install -e .` ← pyproject.toml | Build metadata controls what gets installed and which deps are pulled; a float/wrong dep silently changes runtime behavior |
| schema-body edit → byte-twin gate | AGENTS.md/CLAUDE.md drift is a security-relevant invariant (the public template's drift gate) |
| shim PYTHONPATH bootstrap → import resolution | A wrong PYTHONPATH could shadow the package or import a stale copy |
| shim-owned bootstrap ↔ seam PYTHONPATH preload | The seam's PYTHONPATH export can MASK a shim missing its own bootstrap; the smoke test must clear the seam env to expose it (cycle-4 finding #3) |
| shim-contract doc ↔ Plan 03 implementation | A doc describing a committed-copy oracle while Plan 03 builds a worktree (and python3 -m while Plan 03 runs the shim) misleads Phase-23 ports (cycle-3 finding #3) |
| template-public surface (pyproject.toml, the shim doc) | Shipped to the public template repo — must not embed vault content |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-24-01 | Tampering | pyproject.toml dep pins | mitigate | Pin both YAML deps + build backend + pytest with `==` (exact). A float would silently change `make_yaml` rendering / toolchain and break byte-parity (REVIEWS LOW). Acceptance criteria grep the exact pins. |
| T-24-02 | Tampering | AGENTS.md ≡ CLAUDE.md byte-equality | mitigate | Edit AGENTS.md only, propagate via `sync-claude.sh`, verify with `--check` (exit 2 on drift). Acceptance asserts `--check` exit 0 + `cmp -s`. |
| T-24-03 | Information Disclosure | pyproject.toml / stubs / shim doc (template-public) | accept | The `compendium` package name + 15 neutral tool names + `<tool>` placeholders embed zero vault content. `bin/check-neutrality.sh` is the backstop. Low risk. |
| T-24-04 | Elevation of Privilege | stub `main()` accidentally on a hot path | mitigate | Stubs are NEVER invoked at runtime in Phase 24 (every shim still runs bash). Stubs now exit the nonzero sentinel 70 (REVIEWS MEDIUM) so a stray direct call fails LOUDLY and cannot mask a missed port. Acceptance: every stub greps `NOT_IMPLEMENTED_EXIT = 70`. |
| T-24-04b | Tampering | shim contract drift / inert parity oracle / doc-impl mismatch in Phase 25 | mitigate | The shim doc locks the WIKI_IMPL mechanism (held-fixed bash WORKTREE oracle + the py-lane-via-shim + ported.manifest, REVIEWS HIGH#1 + cycle-3 finding #3) and the checkout-hermetic PYTHONPATH bootstrap OWNED BY THE SHIM (REVIEWS HIGH#9 + cycle-4 finding #3 — doc states the smoke test runs with seam PYTHONPATH cleared); stale committed-copy language is removed so the doc matches Plan 03. Acceptance asserts `git worktree` present + `COMMITTED COPY`/`tests/oracle/` absent + the py-lane-via-shim phrasing + shim-owns-bootstrap/seam-cleared phrasing + `git diff bin/` empty. |
</threat_model>

<verification>
- `python3 -c "import tomllib; ..."` confirms pyproject declares 15 frozen entry points + exact pins (deps + backend + pytest) + src-layout config.
- `python3 -m venv /tmp/p22v && /tmp/p22v/bin/pip install -e . && /tmp/p22v/bin/python -c "import compendium"` succeeds (PKG-01).
- `bash bin/sync-claude.sh --check` exits 0 (§2 edit byte-twin held).
- `git diff --name-only HEAD -- bin/` is empty (no script ported / no shim flipped).
- `tests/ported.manifest` exists with zero tool lines; the shim doc documents the WIKI_IMPL mechanism (worktree oracle for bash + shim-on-parity-path for py) + PYTHONPATH hermeticity OWNED BY THE SHIM + the seam-cleared shim-smoke clause (cycle-4 finding #3), with no stale committed-copy language.
</verification>

<success_criteria>
- PKG-01: `pip install -e .` succeeds in a venv; `import compendium` + `python3 -m compendium.<tool>` resolve for all 15 tools.
- All 15 `console_scripts` pre-declared against stub modules (Success Criterion #1) — `pyproject.toml` is the frozen packaging surface Phase 25 fills but never edits.
- PKG-03: the shim contract (target form + PYTHONPATH hermeticity OWNED BY THE SHIM + WIKI_IMPL mechanism [worktree oracle for bash + shim-on-parity-path for py] + the seam-PYTHONPATH-cleared shim-smoke clause + divergent exit codes incl. the exit-3 preflight compat boundary) is locked in docs, matching Plan 03's implementation (cycle-3 finding #3 doc alignment + cycle-4 finding #3 residual); bin/ untouched.
- `src/` (and `tests/`) added to §2 permitted top-level dirs; AGENTS.md ≡ CLAUDE.md held.
- REVIEWS HIGH#1 (seam mechanism documented), HIGH#9 (checkout-hermetic shim), cycle-3 finding #3 (doc describes worktree oracle + py-lane-via-shim, no stale committed-copy), cycle-4 finding #3 residual (shim owns bootstrap + smoke test with seam env cleared), MEDIUM (nonzero stubs), LOW (pinned toolchain) all resolved.
</success_criteria>

<output>
After completion, create `.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-01-SUMMARY.md`
</output>
</content>

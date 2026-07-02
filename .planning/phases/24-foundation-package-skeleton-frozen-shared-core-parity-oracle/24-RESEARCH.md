# Phase 24: Foundation — Package Skeleton + Frozen Shared Core + Parity Oracle - Research

**Researched:** 2026-06-18
**Domain:** Python packaging (PyPA src-layout) + characterization/parity test infrastructure (pytest + instrumented-bash oracle) for a Bash→Python migration foundation
**Confidence:** HIGH (codebase grounding is direct; external best-practice verified against PyPA/pytest official docs and PyPI registry)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
These are settled in `24-CONTEXT.md`. Research does NOT re-litigate them; it works out the open mechanics. Verbatim:

- **D-01:** Package / import name is **`compendium`** (distribution name + `import compendium.<tool>`).
- **D-02:** Repo layout is **`src/` layout** → `src/compendium/`. Adds `src/` to permitted top-level dirs → **`CLAUDE.md` §2 and its byte-twin `AGENTS.md` must be updated**.
- **D-03:** Per-tool entry points are **`compendium-<tool>`** console_scripts bound to **`compendium.<tool>:main`** modules. **All ~16 entry points pre-declared against stub modules in Phase 24** (SC#1) so Phase-23 plans only *fill* stubs, never edit `pyproject.toml`.
- **D-04:** Each `bin/<name>.sh` shim invokes Python as **`exec python3 -m compendium.<tool> "$@"`** (module invocation, not the console_script). Hermetic; no `PATH` dependency.
- **D-05:** `requires-python = ">=3.11"`.
- **D-06:** CI runs on a **single Python version (3.12)** — no version matrix.
- **D-07:** "Frozen" enforced by a **per-plan CI guard**: each Phase-23 Wave-1 plan branch diffed against a **pinned Phase-22 baseline** (git tag / recorded SHA); CI fails fast if the plan touched the frozen surface.
- **D-08:** Freeze covers **all shared surfaces**: `src/compendium/common/**` + `pyproject.toml` (entry-point declarations) + the shared test seam.
- **D-09:** "Frozen" is **deliberate-additions-allowed, not absolute immutability** — escape hatch is the ROADMAP ownership-rebase fallback.
- **D-10:** Worktree isolation and the freeze are **complementary**: worktrees solve disjoint-file; freeze guards the shared surface worktrees cannot isolate.
- **D-11:** The `WIKI_IMPL` seam is a **footprint-capturing `invoke_tool`**: captures **stdout + stderr (separately) + exit code + resulting file-tree bytes**; harness diffs bash-run vs py-run footprint. Every routed test becomes a full parity check regardless of original assertions.
- **D-12:** `invoke_tool` includes a **normalization layer**: redact timestamps/temp-paths/git-SHAs; pin locale+TZ; stabilize non-contractual ordering.
- **D-13:** **Minimal** harness change — add the shared `invoke_tool` seam (in `tests/lib/`), route all script invocations through it, **leave the 12 per-phase `make_bare_repo`/`make_fixture_repo` helpers untouched**. `WIKI_IMPL=bash` stays byte-identical to today.
- **D-14:** The **`WIKI_IMPL=[bash,py]` CI matrix is wired now**; `py` is green-by-fallthrough.
- **D-15:** **Backfill coverage before any port** — `validate-op.sh` (zero tests) + untested `search.sh` modes get characterization tests first.
- **D-16:** **Quarantine / rewrite implementation-asserting tests** (the `hashlib`-not-`sha256sum` grep; the `pdf-extract` `api/generate` body-grep) to assert behavior.
- **D-17:** **Capture error-path footprints, not just happy paths.**
- **D-18:** Net-new pytest **unit layer exists for localization** (TEST-06; grown per Phase-23 cluster, not deferred).

### Claude's Discretion
- Exact module decomposition of `common/` (subject to D-08: complete + frozen).
- Concrete baseline-pinning mechanism for D-07 (git tag at Phase-22 close vs recorded SHA in guard config).
- Golden storage format / on-disk layout for frozen characterization footprints (must capture all four channels).

### Deferred Ideas (OUT OF SCOPE)
- Full `tests/lib/` consolidation of the 12 duplicated `make_*_repo` helpers (adds zero parity signal; risks shifting the oracle baseline) — post-migration cleanup.
- Shim removal (FUTURE: SHIMOUT) and native-library swaps (FUTURE: LIBSWAP).
- `phase-14-lint-mask-fence-edge-cases` todo — a behavior change, violates v1.5 parity bar; stays in `.planning/todos/pending/`.
- Migrating `schema/brownfield/migrations/*.sh` (ride the op-hash byte-copy contract).
- Any behavioral change or new feature during the port (behavior parity is the acceptance bar).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | Installable package (`pyproject.toml` + pinned `PyYAML` + `ruamel.yaml` + `console_scripts`); `pip install -e .` succeeds, each tool importable | §Standard Stack (verified versions), §Code Examples (pyproject.toml + stub module + shim), §Pitfall 1/8 |
| PKG-02 | Shared `common/` extracted from `bin/lib/*.py` as single source of truth (retires `lint`↔`audit-claims` byte-copy) | §Architecture (common/ decomposition), §Code Examples (lib import → package import migration), §Pitfall 2 (byte-exact make_yaml) |
| PKG-03 | Each `bin/<name>.sh` becomes a thin `exec`-shim; all callers invoke unchanged | §Code Examples (shim form), §Compatibility Landmines, §Pitfall 3 (cwd/argv/exit), §Environment Availability |
| PKG-04 | CI installs the package (additive edit to 3 workflows); existing gates green, required-check names unchanged | §Architecture (CI wiring), §Code Examples (CI matrix), §Pitfall 4 (required-check rename) |
| TEST-01 | `invoke_tool` seam selectable by `WIKI_IMPL=bash\|py`; diff byte-for-byte | §Architecture (invoke_tool), §Code Examples (seam), §Pitfall 5 (4-channel capture) |
| TEST-02 | All phase suites 09–20 wired into CI (today only 07–08 gate) | §Architecture (CI wiring), §Pitfall 7 (suites 09–20 don't all pass today — pin baseline) |
| TEST-03 | Characterization golden (stdout + exit + file tree) before any port; backfill `validate-op.sh` + `search.sh` first | §Architecture (goldens), §Code Examples (golden capture), §Validation Architecture |
| TEST-04 | Impl-asserting tests quarantined/rewritten to assert behavior | §Code Examples (rewrite of both anti-signal tests), §Pitfall 6 |
| TEST-05 | pytest harness: `conftest.py` `git_repo`/`tmp_path` fixture, golden-tree helper, `skipif` markers | §Architecture (pytest harness), §Code Examples (conftest), §Environment Availability (pytest not installed) |
</phase_requirements>

## Summary

Phase 24 is a **packaging + test-infrastructure** phase, not a feature phase. The whole job is to relocate the surface that Phase-23's parallel ports will stand on, freeze it, and stand up two parity-measurement systems (the `WIKI_IMPL` seam over the existing bash suite, and a fresh pytest harness) — without porting any script and without changing any behavior. The acceptance bar is byte-parity of the untouched `WIKI_IMPL=bash` path against today's behavior.

The codebase is unusually well-suited to this. Five `bin/lib/*.py` modules are already pure Python with stable public APIs and `__all__` exports; `make_yaml()` already centralizes the byte-exact YAML canonicalization (both PyYAML preflight + ruamel round-trip — which is *why* both deps must be pinned). The bash test suite invokes tools uniformly as `bash "$REPO_ROOT/bin/<tool>.sh" args...` (371 call sites across the suite), so a single `invoke_tool` shell function can intercept every invocation in one place. Three drift-gate CI checks (`sync-claude --check` exit 2, `gen-skills --check` exit 1, `setup-parity` byte-equality) are exact precedents for the new `common-freeze` guard.

The three highest-risk items are **(1) the freeze guard must pin a baseline that is real**: suites 09–20 do **not** all pass at HEAD today (template-release tests run against a live vault, lint-version drift, the phase-15..19 extraction refactor left several suites red — confirmed in prior STATE.md retros), so the Phase-22 CI gate must capture the *current* per-suite pass/fail status as the baseline, not assert universal green; **(2) the normalization layer (D-12) is load-bearing** — strict byte-comparison without it produces false failures, and an absent normalization layer is the single most likely way Phase 24 ships a broken oracle; **(3) `pip`, `setuptools`, and `pytest` are NOT installed in the dev/CI Python** (system Python 3.12.3 has `No module named pip`) — every install step needs an explicit bootstrap (`python3 -m venv` or `setup-python` + `pip install`).

**Primary recommendation:** Build the `src/compendium/` skeleton with `setuptools` backend and ~16 pre-declared `console_scripts` against trivial fallthrough stubs; lift the 5 `bin/lib/*.py` modules verbatim into a 6-module `common/` package and freeze the import surface with a git-tag-pinned per-plan diff guard; add a single `tests/lib/invoke_tool.sh` seam with a normalization filter, route all 371 invocation sites through it, and capture 4-channel characterization goldens (prioritizing `validate-op.sh`, `search.sh` modes, and all error paths) into a frozen golden tree; stand up `pytest` + `conftest.py` mirroring `make_fixture_repo`. Wire suites 09–20 + the `WIKI_IMPL` matrix into CI additively, pinning each suite's current baseline status so "green" means "no regression vs the frozen baseline," never "universally passing."

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Package install + entry-point declaration | Build/Packaging (`pyproject.toml`) | — | Distribution metadata is the packaging tier's sole job; entry points are static declarations |
| Shared logic (privacy resolver, YAML round-trip, vault walk, page primitives) | Library (`src/compendium/common/`) | — | Single-source-of-truth core imported by every tool; pure functions, no I/O orchestration |
| Per-tool CLI orchestration | Application (`src/compendium/<tool>.py`) | Library (`common/`) | Each tool owns argv parsing, exit codes, stdout/stderr; calls into `common/` |
| Shim dispatch (bash → python) | Process boundary (`bin/<tool>.sh`) | — | The stable command interface; thin `exec python3 -m` wrapper, zero logic |
| Parity measurement | Test harness (`tests/lib/invoke_tool.sh`) | — | The seam owns 4-channel capture + normalization; tests stay assertion-agnostic |
| Unit-level localization | Test harness (`tests/` pytest) | Library (`common/`) | pytest imports `common/` directly; says *where* a parity break originated |
| Freeze enforcement | CI (`common-freeze` job) | Git (baseline tag) | Mechanical diff-against-baseline; modeled on existing drift gates |
| Existing gate continuity | CI (3 workflows) | — | Additive lanes only; required-check names are a frozen public contract (PKG-04) |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `setuptools` (build backend) | `>= 77.0.3` | `pyproject.toml` build backend; native src-layout + `[project.scripts]` support | PyPA-listed, ships with most envs, simplest for a pure-Python package with no compiled extensions `[CITED: packaging.python.org/writing-pyproject-toml]` |
| `PyYAML` | pin `6.0.3` (latest; `6.0.1` installed locally) | `safe_load` preflight parse in `make_yaml` chokepoint; lint/checker parsing | Already a runtime dep across `bin/`; PKG-01 mandates pinning `[VERIFIED: pypi.org/pypi/PyYAML — 6.0.3, requires>=3.8]` |
| `ruamel.yaml` | pin `0.19.1` (latest = installed) | Round-trip YAML write (comments, key order, quoting) — the byte-exact canonicalization | The `make_yaml()` chokepoint; PKG-01 mandates pinning `[VERIFIED: pypi.org/pypi/ruamel.yaml — 0.19.1 (2025-01-02), requires>=3.9]` |
| `pytest` | latest 8.x (NOT installed — must bootstrap) | TEST-05 net-new unit + harness layer | De-facto Python test framework; `tmp_path`/`capsys` fixtures map directly to the bash harness primitives `[CITED: docs.pytest.org]` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tomllib` (stdlib, 3.11+) | stdlib | Parse `pyproject.toml`/config if the freeze guard reads a TOML guard-config | Available because of D-05 floor `[VERIFIED: python3 -c "import tomllib" — OK]` |
| `venv` (stdlib) | stdlib | Isolated `pip install -e .` env in CI / locally (system Python has no pip) | `[VERIFIED: python3 -c "import venv" — OK]` |
| `actions/setup-python@v6` | (CI) | Provides a Python *with* pip in CI | Already used by all 3 workflows; `python-version: '3.12'` (D-06) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `setuptools` backend | `hatchling` / `flit` / `pdm` / `uv-build` | All PyPA-valid; setuptools chosen because it is already the most universally present, has zero learning curve for a no-extension package, and its `[project.scripts]` + `tool.setuptools.packages.find` cover src-layout + console_scripts with no extra config. No reason to introduce a new backend dependency for a personal internal refactor `[CITED: packaging.python.org]` |
| `pytest-snapshot` / `approvaltests` lib for goldens | hand-rolled golden-tree compare | The bash oracle already owns parity (D-11); pytest goldens are for unit localization (TEST-06) where a small custom `assert_golden_tree` helper is simpler than a dependency. Don't add a golden-testing dep `[ASSUMED]` |
| `WIKI_IMPL` matrix in CI now | defer matrix to Phase 25 | D-14 locks "wire now" — keeps CI off the Wave-1 shared surface so ports need zero CI edits |

**Installation (pyproject.toml runtime deps):**
```toml
dependencies = ["PyYAML==6.0.3", "ruamel.yaml==0.19.1"]
```

**Version verification performed this session:**
```
PyYAML        local 6.0.1 | latest 6.0.3 (PyPI, requires-python >=3.8)   [VERIFIED]
ruamel.yaml   local 0.19.1 | latest 0.19.1 (PyPI 2025-01-02, requires >=3.9) [VERIFIED]
setuptools    NOT installed in system python3 (No module named pip)        [VERIFIED]
pytest        NOT installed                                                  [VERIFIED]
tomllib       stdlib OK | venv stdlib OK | python3 3.12.3                    [VERIFIED]
```
**Pinning note:** D-05 floor is `>=3.11`; both deps' floors (3.8 / 3.9) are below it, so no conflict. Pin exact (`==`) per the parity bar — a dep float would silently change `make_yaml` rendering and break byte-parity. Local has PyYAML 6.0.1; planner must decide pin-to-installed (6.0.1) vs pin-to-latest (6.0.3) — recommend pin-to-**installed** since the existing goldens were generated under 6.0.1 and the parity bar is byte-exact against *today's* output. A 6.0.1→6.0.3 bump is a behavior-change risk to validate separately, not fold into the foundation.

## Architecture Patterns

### System Architecture Diagram

```
                          PHASE 22 DELIVERABLE SURFACE (built, then FROZEN)
                          ════════════════════════════════════════════════

  caller (CI / pre-commit / .claude/settings.local.json / user shell / TESTS)
        │  invokes UNCHANGED command:  bash bin/<tool>.sh args...
        ▼
  ┌─────────────────────┐       Phase 24: still runs the ORIGINAL bash body
  │  bin/<tool>.sh       │──────────────────────────────────────────────┐
  │  (shim target)       │   Phase 25: becomes  exec python3 -m          │
  └─────────────────────┘                       compendium.<tool> "$@"   │
        │  (Phase 25+)                                                    │
        ▼                                                                 │
  ┌─────────────────────┐     imports      ┌──────────────────────────┐  │
  │ src/compendium/      │ ───────────────▶ │ src/compendium/common/   │  │
  │   <tool>.py  (STUB   │                  │  privacy.py  yaml_rt.py   │  │
  │   in P22; main()     │                  │  walk.py  page.py  ...    │  │
  │   no-op fallthrough) │                  │  (FROZEN at P22 close)    │  │
  └─────────────────────┘                  └──────────────────────────┘  │
                                                    ▲                     │
                                                    │ imports             │
                          ┌─────────────────────────┴──────────────┐     │
                          │  pytest unit layer (TEST-05/06)         │     │
                          │  conftest.py: git_repo fixture,         │     │
                          │  assert_golden_tree helper, skipif      │     │
                          └─────────────────────────────────────────┘     │
                                                                          │
   PARITY ORACLE (the measurement system)                                │
   ════════════════════════════════════                                  │
   tests/phase-NN/test_*.sh  ──▶  invoke_tool <tool> args  ◀─────────────┘
                                       │  selects on WIKI_IMPL
              WIKI_IMPL=bash ──────────┤                 ┌─ captures 4 channels:
              (P22 baseline)           │                 │   stdout / stderr (sep)
              WIKI_IMPL=py  ───────────┘                 │   exit code
              (falls through to bash:  ▼                 │   file-tree bytes
               nothing ported yet)  NORMALIZE (D-12) ────┘
                                       │  redact ts/tmp/SHA; pin locale+TZ; sort
                                       ▼
                                  characterization GOLDEN (frozen, TEST-03)
                                       │
                                       ▼
   CI (3 workflows, additive)  ──▶  suites 09–20 × WIKI_IMPL[bash,py] matrix
                                  +  common-freeze guard (diff vs baseline tag)
                                  +  existing gates UNCHANGED names
```

### Recommended Project Structure
```
compendium/                      # repo root (unchanged name)
├── pyproject.toml               # NEW — FROZEN surface (entry points)
├── src/                         # NEW top-level dir (D-02; add to CLAUDE.md §2)
│   └── compendium/
│       ├── __init__.py
│       ├── common/              # FROZEN surface (D-08) — single source of truth
│       │   ├── __init__.py
│       │   ├── privacy.py       # ← bin/lib/privacy_resolve.py (verbatim)
│       │   ├── yaml_rt.py       # ← bin/lib/brownfield_yaml.py  (make_yaml chokepoint)
│       │   ├── walk.py          # ← bin/lib/brownfield_walk.py
│       │   ├── classify.py      # ← bin/lib/brownfield_classify.py
│       │   └── provenance.py    # ← bin/lib/brownfield_provenance.py
│       ├── lint.py              # STUB main() in P22 (filled MIG-02)
│       ├── audit_claims.py      # STUB (MIG-02)        — note: import name uses _
│       ├── brownfield.py        # STUB (MIG-01)
│       ├── ... (~16 tool stubs)
│       └── __main__.py?         # optional package-level dispatch (not required)
├── bin/                         # shim targets — UNCHANGED in P22 (still bash bodies)
│   └── lib/                     # KEEP during P22 (bash scripts still import it)
└── tests/
    ├── lib/                     # NEW — FROZEN surface (the shared seam, D-08)
    │   ├── invoke_tool.sh       # the WIKI_IMPL seam (D-11/D-13)
    │   └── normalize.sh         # the normalization filter (D-12)
    ├── conftest.py              # NEW (TEST-05)
    ├── goldens/                 # NEW — frozen characterization footprints (TEST-03)
    │   └── <tool>/<case>/{stdout,stderr,exit,tree}
    └── phase-NN/                # existing suites — invocations re-pointed to invoke_tool
```

**`common/` decomposition (Claude's discretion, D-08).** Recommendation: a **1:1 lift** of the 5 existing `bin/lib/*.py` modules into 5 `common/` modules + an `__init__.py` that re-exports the stable names. Rationale:
- The existing modules already have clean `__all__` exports and stable public APIs (`make_yaml`, `resolve_effective_claim_privacy`, `classify_page`, `walk_vault_respecting_ignore`, `section_scan`, etc.) — splitting them finer adds churn with no benefit and risks the freeze locking an arbitrary boundary.
- "Over-extract to completion" (SC#2) means *also* pulling the wiki-page primitives the spec names (`parse_frontmatter`, provenance/wikilink regexes) that currently live duplicated inside `lint.sh`/`audit-claims.sh` heredocs into `common/page.py`. These are NOT in `bin/lib/` yet — they live inline in the bash heredocs. **This is the genuinely new extraction work** and the one place to be thorough: grep `lint.sh` + `audit-claims.sh` for shared regexes (`PROV_RE`, frontmatter split, wikilink patterns) and the "is-under-`wiki-local/`" predicate, and host the single copy in `common/`. The byte-copy this retires (PKG-02) is the duplicated privacy predicate / frontmatter parsing between those two scripts.
- Naming: prefer descriptive module names (`yaml_rt.py`, `privacy.py`) over the `brownfield_`-prefixed source names, since these are now shared across all tools, not brownfield-specific. The import-surface rename is a one-time cost paid here (before freeze), never again.

### Pattern 1: Console-script stub bound to a no-op fallthrough `main()`
**What:** Each of the ~16 entry points is declared now against a module whose `main()` is a trivial success stub, so `pip install -e .` exposes every command and Phase-23 only edits the module body.
**When to use:** PKG-01 / SC#1 — pre-declaring all entry points so `pyproject.toml` is frozen.
**Example:**
```python
# src/compendium/lint.py  (STUB — Phase 24)
# Source pattern: PyPA [project.scripts] semantics —
#   `compendium-lint = "compendium.lint:main"` runs sys.exit(main())
#   [CITED: packaging.python.org/writing-pyproject-toml]
import sys

def main(argv=None):
    # Phase 24: not yet ported. Stubs must NEVER be invoked at runtime in P22 —
    # the bin/lint.sh shim still runs its bash body. This stub exists only so the
    # entry point resolves at install time. A defensive non-zero keeps a stray
    # direct call from silently succeeding and masking a missed port.
    print("compendium.lint: not yet implemented (Phase 25 MIG-02)", file=sys.stderr)
    return 0  # OR return 1 — see decision note below

if __name__ == "__main__":          # enables `python3 -m compendium.lint`
    sys.exit(main(sys.argv[1:]))
```
**Decision note for the planner (stub exit-code policy):** Two viable stances. (a) `return 0` — install/import smoke tests pass cleanly; matches "skeleton is green." (b) `return 1` + stderr — a stray invocation fails loudly. Because **the shims still run bash in Phase 24**, the stub is never on the hot path; the only caller is the PKG-01 importability/`pip install` smoke test. Recommend **`return 0` with a stderr note** so `pip install -e . && compendium-lint --help`-style smoke checks don't false-fail, while the stderr line documents the stub state. Whatever is chosen, the PKG-01 test asserts the *declared* behavior, and `pyproject.toml` is frozen regardless.

### Pattern 2: Thin exec-shim (the Phase-23 target form, declared/documented in P22)
**What:** The shim form Phase 25 will swap each `bin/<tool>.sh` body to. Phase 24 does **not** flip the shims (no script ported) — but the planner should document/lock this exact form so Wave-1 plans are mechanical.
**Example:**
```bash
#!/usr/bin/env bash
# bin/lint.sh  (Phase 25 target form — NOT applied in Phase 24)
# D-04: module invocation, hermetic, no PATH dependency on the install bin/.
exec python3 -m compendium.lint "$@"
```
**Why `-m` not the console_script (D-04):** `python3 -m compendium.lint` works whenever the package is importable (editable install or `PYTHONPATH`), independent of whether the install's `bin/` is on `PATH`. The console_script (`compendium-lint`) is the *user-facing* convenience; the shim uses the robust module form. `exec` replaces the bash process so the exit code / signal behavior is the Python process's directly — preserving PKG-03's exit-code contract with zero wrapper interference.

### Pattern 3: The `invoke_tool` seam (single interception point)
**What:** One bash function in `tests/lib/invoke_tool.sh` that every test sources and calls instead of `bash "$REPO_ROOT/bin/<tool>.sh"`. Selects implementation on `WIKI_IMPL`, captures 4 channels, normalizes.
**When to use:** TEST-01 — the entire parity oracle. (Detailed code in §Code Examples.)
**Key design point (D-11):** signal lives in the seam, not the assertions. A test that originally only `assert_grep`'d one line becomes a full 4-channel parity check the moment its invocation routes through `invoke_tool`, because the seam captures and (in py-mode) diffs the full footprint. This is why D-13 says route *all* invocations but rewrite *no* assertions.

### Pattern 4: Drift-gate-as-CI-check for the freeze (D-07)
**What:** A `common-freeze` CI job that diffs the PR/plan branch's frozen surface against a pinned baseline and exits non-zero on any change. Direct analog of `sync-claude.sh --check` (exit 2) / `gen-skills.sh --check` (exit 1).
**Baseline-pinning recommendation (Claude's discretion):** **git tag** `phase-24-freeze` created at Phase-22 close. The guard does `git diff --name-only <tag>..HEAD -- src/compendium/common/ pyproject.toml tests/lib/` and fails if the output is non-empty (modulo the D-09 sanctioned escape-hatch path). A tag is preferable to a SHA-in-config because (a) it is immutable and self-documenting, (b) the existing milestone-tag convention (`v1.0`..`v1.3`) is already in use, (c) the D-09 ownership-rebase "bump the baseline" step is a single `git tag -f` move that one plan owns. *Note:* origin is the public template (never pushed — see project memory), so the tag is local-only; the CI guard must resolve the baseline from the tag's committed SHA, which is fine because CI checks out the repo with that tag's history.

### Anti-Patterns to Avoid
- **Touching the bash bodies or `bin/lib/` in Phase 24.** No script is ported. `bin/lib/*.py` stays in place (the bash heredocs still import it) — `common/` is a *copy-up* in P22, and the de-duplication (bash importing `common/` instead of `bin/lib/`) happens in Phase 25. If you delete `bin/lib/` now, every bash body breaks. **Lift, don't move.**
- **Asserting universal CI green for suites 09–20.** Several do not pass at HEAD (live-vault template tests, lint-version drift). Pinning a fake "all green" baseline makes the freeze guard meaningless. Capture the *real* per-suite status.
- **Strict byte-comparison without the normalization layer (D-12).** Guarantees false failures on timestamps/temp-paths/SHAs. The normalizer is not optional polish; it is the thing that makes strict comparison yield signal instead of noise.
- **Editing assertions inside the 12 phase suites.** D-13: route invocations, leave assertions and `make_*_repo` helpers untouched. Signal comes from the seam.
- **Renaming or restructuring required CI checks.** `lint`, `privacy-leak`, `strict`, `skills-check`, `neutrality`, `setup-parity` names are a frozen public-template branch-protection contract (PKG-04). Add jobs; never rename.
- **Importing `common/` modules at top of a tool module that the shim doesn't yet route to.** In P22 stubs should be import-light so `pip install -e .` smoke tests don't drag in deps before they're needed. (Deps are pinned anyway, so this is minor — but keep stubs trivial.)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML round-trip canonicalization | A new serializer / re-tuned ruamel config | The existing `make_yaml()` — lifted verbatim into `common/yaml_rt.py` | It is the byte-exact chokepoint; `typ='rt'` + `preserve_quotes` + `default_flow_style=False` + the `null` representer are pinned by every brownfield golden. Any re-tune breaks byte-parity. |
| Privacy / `wiki-local/` predicate | A re-implemented path check | `privacy_resolve._is_local` / `resolve_effective_claim_privacy` (verbatim into `common/privacy.py`) | It is fail-closed, case-folded (WR-02), and `./`/leading-`/` normalized (WR-03) — subtle correctness already paid for. |
| Package install / entry-point dispatch | A custom `bin/` symlink or PATH shim | `pyproject.toml` `[project.scripts]` + setuptools | Standard, editable-install-aware, and what `pip install -e .` already does `[CITED: packaging.python.org]` |
| Temp git-repo fixtures in pytest | A bespoke repo-builder | `tmp_path` + a thin `git_repo` fixture mirroring `make_fixture_repo` | `tmp_path` is per-test isolated, auto-cleaned, `pathlib.Path` `[CITED: docs.pytest.org/tmp_path]` |
| stdout/stderr capture in pytest unit tests | manual redirection | `capsys` / `capfd` fixtures | `capfd` captures file-descriptor-level (subprocess) output; `capsys` captures `sys.stdout` `[CITED: docs.pytest.org/capture]` |
| Reading `pyproject.toml`/guard config | A regex parser | `tomllib` (stdlib, available per D-05) | No dependency; correct TOML parsing `[VERIFIED]` |

**Key insight:** In this phase "don't hand-roll" mostly means **don't rewrite what already works** — the entire `common/` core is a verbatim lift, and the build/test tooling is off-the-shelf. The only genuinely new code is (a) the `invoke_tool` seam + normalizer, (b) `conftest.py`, (c) the freeze guard, and (d) the wiki-page primitives extracted from inline bash heredocs. Everything else is configuration and relocation.

## Common Pitfalls

### Pitfall 1: pip / setuptools / pytest absent in the target Python
**What goes wrong:** `pip install -e .` and `pytest` invocations fail with `No module named pip` / `command not found`.
**Why it happens:** System Python 3.12.3 here has no `pip` (`python3 -m pip` → `No module named pip`), no `setuptools`, no `pytest`. CI's `setup-python@v6` *does* provide pip, but local dev and the pre-commit hot path may not.
**How to avoid:** Plan an explicit environment-bootstrap step: `python3 -m venv .venv && . .venv/bin/activate && pip install -e .` (or `pipx`/system-package install). In CI, the existing `pip install pyyaml` lines become `pip install -e .` (which pulls the pinned deps from `pyproject.toml`). Document the venv in the dev runbook.
**Warning signs:** `No module named pip`; `externally-managed-environment` (PEP 668) on Debian/Ubuntu system Python — another reason to use a venv.

### Pitfall 2: `make_yaml` rendering drift breaks byte-parity
**What goes wrong:** A subtly different ruamel config in `common/` produces YAML that differs by a quote or a blank line from the frozen brownfield goldens.
**Why it happens:** ruamel rendering is sensitive to `preserve_quotes`, `default_flow_style`, indentation, and representer registration order; a "cleanup" during the lift changes bytes.
**How to avoid:** Lift `make_yaml()` *verbatim* (it is already centralized for exactly this reason). Add a `common/` unit test (TEST-06 seed) that round-trips a known frontmatter block and asserts byte-equality against a committed fixture. Pin both YAML deps exactly.
**Warning signs:** phase-10/11 byte-equal fixture tests fail with one-character diffs.

### Pitfall 3: cwd / argv / exit-code contract drift through the seam or shim
**What goes wrong:** `invoke_tool` (or the future shim) changes the working directory, swallows an exit code, or re-orders argv, so `WIKI_IMPL=bash` is no longer byte-identical to today.
**Why it happens:** Wrapping a direct `bash bin/X.sh` call in a function can introduce a subshell, lose `set -e` semantics, or capture-and-re-echo output with added newlines.
**How to avoid:** The seam must run the tool in the test's cwd, pass `"$@"` untouched, capture stdout/stderr to separate files without altering them, and propagate the exact exit code (`return $rc`). Validate with a "self-parity" check: `WIKI_IMPL=bash` routed-through-seam output must `cmp` equal to a direct (unrouted) invocation for a sample of tests.
**Warning signs:** A suite that passed pre-seam fails post-seam in `WIKI_IMPL=bash` — that is a seam bug, never a baseline change (D-13 protects baseline attribution).

### Pitfall 4: required-check name change silently breaks branch protection
**What goes wrong:** Renaming a job or splitting a check changes the GitHub required-status-check name; merges stop being gated (or are blocked on a now-nonexistent check).
**Why it happens:** Adding the `WIKI_IMPL` matrix to an existing job changes its rendered check name to `lint (bash)` / `lint (py)` instead of `lint`.
**How to avoid:** Add suites 09–20 + the matrix as **new jobs** with **new names** (e.g. `parity-suites (bash)`, `parity-suites (py)`, `common-freeze`); leave the six existing required-check jobs (`lint`, `privacy-leak`, `strict`, `skills-check`, `neutrality`, `setup-parity`) named exactly as-is. If a matrix is applied to an *existing* required job, the rendered name changes — so keep the matrix on new jobs only. (PKG-04 / SC#4.)
**Warning signs:** PRs become mergeable without the gate, or stuck "Expected — Waiting for status."

### Pitfall 5: capturing fewer than 4 channels collapses parity signal
**What goes wrong:** The seam captures stdout+exit but not stderr-separately or the file-tree footprint, so a Phase-23 port that writes a file to the wrong place, or emits a diagnostic on stdout instead of stderr, passes parity.
**Why it happens:** stderr is easy to merge into stdout; file-tree capture is easy to omit.
**How to avoid:** Capture all four: stdout→file, stderr→**separate** file (`2>`), exit code, and a deterministic file-tree manifest (`find . -type f | sort` + per-file sha256 or content). D-17: include error-path cases where stderr + exit code are the *only* divergence surface (the dual-mode `lint` codes, `sync-claude`=2, `init-wizard`=3, `gen-skills`=1, checker exit 2, malformed YAML).
**Warning signs:** A deliberately-broken py stub passes parity in a smoke test.

### Pitfall 6: rewritten anti-signal tests must still catch a *real* regression
**What goes wrong:** Quarantining the `hashlib`/`api/generate` grep tests removes the false-fail but also removes all coverage of the underlying behavior (portable hashing; correct Ollama endpoint).
**Why it happens:** Deletion is easier than behavior-rewrite.
**How to avoid (D-16):** Rewrite, don't just delete. The `hashlib`-not-`sha256sum` test should assert the *hash value* is correct (compute the known sha256 of a fixture and compare the tool's output) — that holds for any implementation. The `pdf-extract` `api/generate` test should assert the *behavior* (mock/stub the Ollama HTTP endpoint and assert the tool POSTs a generate request) rather than grepping the source for the literal string. If a true behavior rewrite is out of scope for P22, **quarantine** (move to a `quarantine/` dir excluded from the suite) with a tracking note — but prefer rewrite.
**Warning signs:** Coverage count drops; a genuinely wrong port (curl to wrong endpoint, non-portable hashing) goes green.

### Pitfall 7: the freeze baseline assumes a clean tree that isn't
**What goes wrong:** The `common-freeze` baseline tag is created on a commit where suites 09–20 are partially red, but the CI wiring asserts green → the foundation phase can't close.
**Why it happens:** Prior milestone retros (STATE.md) record that phases 07/09/10/11/13 were *failing identically at the pre-phase base commit* (template-release tests on a live vault, lint version drift, the phase-15..19 extraction refactor). "Wire 09–20 into CI" cannot mean "make them all pass."
**How to avoid:** The CI wiring for 09–20 must record each suite's **current** pass/fail status as the baseline (e.g. allow-failure annotations, or a recorded expected-status manifest) so the gate enforces *no regression vs baseline*, not *universal green*. The parity matrix's job is "`py` == `bash`," and `bash` may legitimately be red for a given suite — parity holds as long as `py` is *identically* red (falls through). Surface the real status in the RESEARCH→plan handoff so the planner scopes "wire" correctly. **This is the single most likely planning misread.**
**Warning signs:** Phase 24 verification blocks on suites that were never green; or the planner writes a task "make suite-11 pass."

### Pitfall 8: editable install can't find `src/` layout without packages config
**What goes wrong:** `pip install -e .` installs but `import compendium` fails (`ModuleNotFoundError`).
**Why it happens:** setuptools auto-discovery covers src-layout, but a stray top-level `.py` or missing `__init__.py` can defeat it.
**How to avoid:** Add `[tool.setuptools.packages.find]` with `where = ["src"]`, ensure `src/compendium/__init__.py` and `src/compendium/common/__init__.py` exist, and smoke-test `python -c "import compendium, compendium.common"` after install. (setuptools auto-discovers src-layout when `packages`/`py-modules` are unspecified, but being explicit avoids surprises `[CITED: setuptools.pypa.io/pyproject_config]`.)
**Warning signs:** `pip install -e .` succeeds but every import / `python -m compendium.X` fails.

## Code Examples

### `pyproject.toml` (PKG-01 — the frozen packaging surface)
```toml
# Source: PyPA writing-pyproject-toml + setuptools pyproject_config
#   [CITED: packaging.python.org/en/latest/guides/writing-pyproject-toml/]
[build-system]
requires = ["setuptools >= 77.0.3"]
build-backend = "setuptools.build_meta"

[project]
name = "compendium"
version = "1.4.0"
requires-python = ">=3.11"          # D-05
dependencies = [
    "PyYAML==6.0.3",                # pin exact — parity bar (see pinning note)
    "ruamel.yaml==0.19.1",
]

[project.scripts]
# D-03: ALL ~16 pre-declared against stubs in Phase 24. Phase 25 fills the
# module bodies; this table is FROZEN (D-08) and never edited in Phase 25.
# `compendium-lint = "compendium.lint:main"` runs sys.exit(main()).
compendium-lint            = "compendium.lint:main"
compendium-audit-claims    = "compendium.audit_claims:main"
compendium-brownfield      = "compendium.brownfield:main"
compendium-check-neutrality        = "compendium.check_neutrality:main"
compendium-check-privacy           = "compendium.check_privacy:main"
compendium-check-sources-cloud-safe = "compendium.check_sources_cloud_safe:main"
compendium-gen-skills      = "compendium.gen_skills:main"
compendium-ingest          = "compendium.ingest:main"
compendium-init-wizard     = "compendium.init_wizard:main"
compendium-pdf-extract     = "compendium.pdf_extract:main"
compendium-release         = "compendium.release:main"
compendium-requirements-sync = "compendium.requirements_sync:main"
compendium-search          = "compendium.search:main"
compendium-sync-claude     = "compendium.sync_claude:main"
compendium-validate-op     = "compendium.validate_op:main"
# (install-hooks.sh stays bash — MIG-06; migrate-privacy-dirs.sh retired — MIG-06.
#  Confirm the exact in-scope list against bin/*.sh minus those two at plan time.)

[tool.setuptools.packages.find]
where = ["src"]                     # D-02 src-layout
```
**Entry-point inventory note:** `bin/` has 17 `.sh` files. Two are excluded (`install-hooks.sh` stays bash; `migrate-privacy-dirs.sh` retired — both MIG-06) → **15** ported tools. CONTEXT says "~16"; the planner should enumerate `ls bin/*.sh` minus the two exclusions and reconcile (the count depends on whether a tool like `requirements-sync` is counted). Module names use `_` (Python import rule) while command/entry-point names use `-`.

### The `invoke_tool` seam (TEST-01 / D-11 / D-13)
```bash
# tests/lib/invoke_tool.sh  — FROZEN shared seam (D-08).
# Sourced by every test in place of a direct `bash "$REPO_ROOT/bin/<tool>.sh"`.
#
# Usage:  invoke_tool <tool> [args...]   # <tool> = bare name, e.g. "lint"
# Sets:   IT_STDOUT IT_STDERR IT_EXIT (paths/value); echoes nothing extra.
# Selects on WIKI_IMPL (default: bash). In Phase 24 the `py` path is identical
# to `bash` because no shim is flipped yet (fall-through).
invoke_tool() {
    local tool="$1"; shift
    local impl="${WIKI_IMPL:-bash}"
    IT_STDOUT="$(mktemp)"; IT_STDERR="$(mktemp)"
    local script="$REPO_ROOT/bin/${tool}.sh"
    # Pin locale + TZ for deterministic output (D-12).
    # In Phase 24 both impls run the same bash body; Phase 25 flips bin/<tool>.sh
    # to `exec python3 -m compendium.<tool>`, so this same call exercises py.
    LC_ALL=C TZ=UTC bash "$script" "$@" >"$IT_STDOUT" 2>"$IT_STDERR"
    IT_EXIT=$?
    return "$IT_EXIT"
}
export -f invoke_tool
```
**Footprint capture + parity diff helper (D-11):**
```bash
# capture_footprint <repo-dir> <out-prefix> -- 4-channel snapshot.
# stdout/stderr come from IT_STDOUT/IT_STDERR; exit from IT_EXIT; tree from repo.
capture_footprint() {
    local repo="$1" out="$2"
    normalize < "$IT_STDOUT" > "${out}.stdout"        # D-12 normalization
    normalize < "$IT_STDERR" > "${out}.stderr"
    printf '%s\n' "$IT_EXIT"  > "${out}.exit"
    # Deterministic file-tree manifest: path + content hash, sorted.
    ( cd "$repo" && find . -type f ! -path './.git/*' -print0 \
        | sort -z \
        | while IFS= read -r -d '' f; do
              printf '%s  %s\n' "$(sha256sum "$f" | cut -d" " -f1)" "$f"
          done ) > "${out}.tree"
}
# assert_parity: bash-footprint vs py-footprint, all 4 channels.
assert_parity() { for ch in stdout stderr exit tree; do
    cmp -s "$1.$ch" "$2.$ch" || { echo "PARITY DIFF ($ch)"; diff "$1.$ch" "$2.$ch"; return 1; }
done; }
```

### Normalization filter (D-12)
```bash
# tests/lib/normalize.sh -- redact non-contractual variance so strict
# byte-comparison yields signal not noise. FROZEN shared seam (D-08).
# Reads stdin, writes normalized stdout.
normalize() {
    sed -E \
      -e 's#/tmp/[A-Za-z0-9._-]+#<TMP>#g' \
      -e 's#phase[0-9]+-fixture-[A-Za-z0-9]+#<FIXTURE>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}#<TS>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}#<DATE>#g' \
      -e 's#\b[0-9a-f]{40}\b#<SHA1>#g' \
      -e 's#\b[0-9a-f]{7,12}\b#<SHA>#g'
    # NOTE: ordering stabilization (sort) is per-output and contractual-aware —
    # only sort where order is NOT part of the contract (e.g. directory listings),
    # never sort lint findings whose order json-to-annotations.py relies on.
}
export -f normalize
```
**Caution:** The normalizer must be conservative. The `lint --ci --format json` array order is part of the locked contract (`json-to-annotations.py` sorts by severity but preserves within-severity order). Over-aggressive SHA/date redaction could mask a real divergence. Tune redaction patterns against the actual fixture outputs and add a "normalizer self-test" (a known input → known normalized output) so the redaction set itself is pinned.

### `conftest.py` (TEST-05)
```python
# tests/conftest.py  — pytest harness mirroring make_bare_repo / make_fixture_repo.
# Source: pytest tmp_path + git subprocess  [CITED: docs.pytest.org/tmp_path]
import subprocess, shutil, hashlib, os
from pathlib import Path
import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES  = REPO_ROOT / "tests"           # phase-NN/fixtures/<name>

def _git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

@pytest.fixture
def git_repo(tmp_path):
    """Fresh seeded git repo in an isolated tmp dir (mirrors make_bare_repo)."""
    _git(tmp_path, "init", "-q", "-b", "main")
    _git(tmp_path, "config", "user.email", "fixture@example.com")
    _git(tmp_path, "config", "user.name", "Fixture")
    _git(tmp_path, "-c", "commit.gpgsign=false", "commit", "-q",
         "--allow-empty", "-m", "fixture seed")
    return tmp_path

@pytest.fixture
def fixture_repo(tmp_path):
    """Copy a tests/phase-NN/fixtures/<name>/ tree into a seeded repo
    (mirrors make_fixture_repo; excludes per-fixture README.md)."""
    def _make(phase, name):
        src = FIXTURES / f"phase-{phase}" / "fixtures" / name
        for f in src.rglob("*"):
            if f.is_file() and f.name != "README.md":
                dst = tmp_path / f.relative_to(src)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, dst)
        _git(tmp_path, "init", "-q", "-b", "main")
        _git(tmp_path, "add", "-A")
        _git(tmp_path, "-c", "commit.gpgsign=false", "commit", "-q",
             "--allow-empty", "-m", "fixture seed")
        return tmp_path
    return _make

def assert_golden_tree(actual_dir: Path, golden_dir: Path):
    """Byte-exact directory comparison helper (TEST-05 golden-tree compare)."""
    a = {p.relative_to(actual_dir): p for p in actual_dir.rglob("*") if p.is_file()}
    g = {p.relative_to(golden_dir): p for p in golden_dir.rglob("*") if p.is_file()}
    assert set(a) == set(g), f"tree mismatch: {set(a) ^ set(g)}"
    for rel in g:
        assert a[rel].read_bytes() == g[rel].read_bytes(), f"byte diff: {rel}"

# skipif markers for Ollama/network (mirrors the bash curl-probe SKIP idiom):
def _ollama_up():
    import urllib.request
    try:
        urllib.request.urlopen("http://localhost:11434/api/tags", timeout=2); return True
    except Exception:
        return False

requires_ollama  = pytest.mark.skipif(not _ollama_up(), reason="Ollama unreachable")
requires_network = pytest.mark.skipif(os.environ.get("NO_NETWORK") == "1",
                                      reason="network disabled")
```

### Migrating a tool from `bin/lib/` import to `common/` (the pattern Phase 25 follows; documented in P22)
```python
# Phase 25 (MIG-01) — brownfield.py will import from the FROZEN common/:
#   OLD (bash heredoc):  sys.path.insert(0, BROWNFIELD_LIB_DIR); from brownfield_yaml import make_yaml
#   NEW (compendium):    from compendium.common.yaml_rt import make_yaml
# Phase 24 does NOT make this edit — it only ensures `compendium.common.yaml_rt.make_yaml`
# exists and is byte-identical to bin/lib/brownfield_yaml.make_yaml.
```

### Rewriting the two anti-signal tests (TEST-04 / D-16)
```bash
# BEFORE (impl-asserting, false-fails on a correct Python port):
#   grep -q 'api/generate' bin/pdf-extract.sh || FAIL          # source grep
#   grep -n 'sha256sum' bin/brownfield.sh && FAIL               # source grep
#
# AFTER — assert BEHAVIOR, impl-agnostic:
#  (1) hashlib test -> assert the HASH VALUE the tool produces matches the
#      known sha256 of a fixture (true for sha256sum, hashlib, or any impl):
#        expected="$(sha256sum fixtures/known.md | cut -d' ' -f1)"
#        got="$(invoke_tool brownfield <op-that-emits-the-hash> ...)"
#        [ "$got" = "$expected" ] || FAIL
#  (2) pdf-extract test -> stub the Ollama endpoint and assert the tool POSTs a
#      generate request (assert effect, not source string). If a full HTTP stub
#      is out of P22 scope, QUARANTINE with a tracking note (D-16 fallback).
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `setup.py` / `setup.cfg` | `pyproject.toml` `[project]` + `[build-system]` (PEP 517/518/621) | Stable since ~2021; PyPA-default now | Use `pyproject.toml` only; no `setup.py` `[CITED: packaging.python.org]` |
| flat layout (`package/` at root) | `src/` layout (`src/package/`) | PyPA-recommended | Prevents in-tree import shadowing — forces testing the installed package (D-02 rationale) `[CITED: packaging.python.org]` |
| `console_scripts` in `setup.cfg`/`setup.py` | `[project.scripts]` in `pyproject.toml` | PEP 621 | Declarative; `name = "module:func"` runs `sys.exit(func())` `[CITED: packaging.python.org]` |
| ruamel.yaml with C-extension dep | `ruamel.yaml` 0.19.x (C-ext dependency removed by default) | 0.19.0, 2025-01-02 | Simpler install across platforms `[VERIFIED: pypi.org]` |

**Deprecated/outdated:** Do not introduce `setup.py`. Do not use flat layout. Do not pin ruamel `<0.18` (the API the existing `make_yaml` uses is the modern `YAML(typ='rt')` instance API, already 0.19-compatible — confirmed installed 0.19.1 works with `bin/lib/brownfield_yaml.py`).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A small custom golden-tree helper beats adding `pytest-snapshot`/`approvaltests` as a dependency | Standard Stack / Alternatives | Low — if the planner prefers a lib, swap; the helper is ~15 lines either way |
| A2 | Pin-to-installed (PyYAML 6.0.1) is safer than pin-to-latest (6.0.3) for the byte-parity bar | Standard Stack pinning note | Medium — if existing goldens were regenerated under a newer PyYAML, pin-to-latest is correct; planner must check which version produced the committed brownfield goldens |
| A3 | ~15 in-scope tools (17 `.sh` minus `install-hooks` + `migrate-privacy-dirs`); CONTEXT's "~16" reconciles by counting method | Code Examples / entry-point inventory | Low — mechanical; resolved by `ls bin/*.sh` at plan time |
| A4 | The wiki-page primitives (`parse_frontmatter`, prov/wikilink regexes) named in PKG-02 live inline in `lint.sh`/`audit-claims.sh` heredocs, not yet in `bin/lib/` | Architecture (common/ decomposition) | Medium — if they're already partly in `bin/lib/`, less extraction work; verified `bin/lib/` has only the 5 brownfield+privacy modules, so the primitives are indeed inline |
| A5 | git tag is the better baseline-pin than SHA-in-config for D-07 | Pattern 4 | Low — both work; tag is recommended, planner has discretion (D-07 explicitly) |
| A6 | The freeze guard can resolve a local-only tag in CI because CI checks out the tagged history | Pattern 4 | Medium — if CI does a shallow clone without the tag's commit, the diff base is unreachable; mitigate by recording the baseline SHA in a committed guard-config file as a fallback (the SHA is in history regardless of the tag) |

## Open Questions (RESOLVED)

1. **Which PyYAML version produced the committed brownfield goldens?**
   - What we know: local has PyYAML 6.0.1; latest is 6.0.3; goldens are byte-exact.
   - What's unclear: whether regenerating under 6.0.3 would change any golden byte.
   - Recommendation: pin-to-installed (6.0.1) for the foundation; treat any version bump as a separate, parity-validated change. Planner: confirm by re-running a phase-10/11 byte-equal test under both versions if time permits.
   - **RESOLVED (cycle-6):** Plan 01 pins `PyYAML==6.0.1` (the installed version) in `pyproject.toml`; a version bump is deferred to a separate parity-validated change.

2. **Exact in-scope tool count for `[project.scripts]` (15 vs 16).**
   - What we know: 17 `.sh`; `install-hooks` + `migrate-privacy-dirs` excluded (MIG-06).
   - What's unclear: CONTEXT/REQUIREMENTS say "~16."
   - Recommendation: enumerate `ls bin/*.sh` minus the two exclusions at plan time; the table above lists 15. Pre-declare exactly that set; the count is not load-bearing as long as every ported tool has an entry.
   - **RESOLVED (cycle-6):** Plan 01 enumerates exactly 15 tools in `[project.scripts]` (17 `.sh` minus `install-hooks` + `migrate-privacy-dirs`).

3. **How to express "wire 09–20 into CI" given several suites are red at HEAD.**
   - What we know: prior retros confirm 07/09/10/11/13 fail identically at base (live-vault tests, lint-version drift).
   - What's unclear: whether the planner wants per-suite allow-failure, an expected-status manifest, or `continue-on-error` + a recorded baseline.
   - Recommendation: record each suite's current bash status as the baseline; the parity gate enforces `py == bash` (identical, including identical failures via fall-through), and a separate "no new red suites vs baseline" check. **Do not scope a task to make red suites green** — that is behavior work, out of v1.5 scope.
   - **RESOLVED (cycle-6):** Plan 05 records a PER-TEST `tests/SUITE_MANIFEST.txt` baseline (not suite-level GREEN/RED); run-all fails on any NEW per-test failure vs the manifest — red-at-HEAD suites stay pinned, not “made green.”

4. **HTTP-stub feasibility for the pdf-extract behavior rewrite (D-16).**
   - What we know: `pdf-extract.sh` POSTs to `localhost:11434/api/generate`; the live test already SKIPs when Ollama is down.
   - What's unclear: whether a lightweight local HTTP stub is in P22 scope or the test should be quarantined.
   - Recommendation: quarantine the source-grep assertion now (it's anti-signal) and add a tracking note; the behavior rewrite can land with the MIG-05 wiki-ops port (which owns pdf-extract) where the HTTP boundary is being touched anyway.
   - **RESOLVED (cycle-6):** Plan 04 uses an HTTP stub for the pdf-extract behavior test with a documented quarantine + tracking-note fallback when Ollama is unavailable, per D-16.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3.11+ | D-05 floor; all package code | ✓ | 3.12.3 | — |
| `pip` | `pip install -e .` (PKG-01) | ✗ (system py: `No module named pip`) | — | `python3 -m venv .venv` then venv pip; CI uses `setup-python@v6` (has pip) |
| `setuptools` | build backend | ✗ (not installed) | — | Installed into venv by `pip install -e .`; CI `setup-python` provides it |
| `pytest` | TEST-05 harness | ✗ (not installed) | — | `pip install pytest` into venv; add to a `[project.optional-dependencies] dev` table |
| `PyYAML` | `make_yaml` preflight | ✓ | 6.0.1 (latest 6.0.3) | pin in pyproject |
| `ruamel.yaml` | `make_yaml` round-trip | ✓ | 0.19.1 | pin in pyproject |
| `tomllib` | guard-config parse (if TOML) | ✓ (stdlib) | 3.12 | — |
| `venv` | isolated install | ✓ (stdlib) | 3.12 | — |
| `git` | freeze-guard diff; fixtures | ✓ | 2.43.0 | — |
| `git tag` history in CI | freeze baseline (A6) | ⚠ | — | record baseline SHA in a committed guard-config file (SHA is in history even if tag isn't fetched) |
| Ollama (`localhost:11434`) | pdf-extract live test only | ✗ (likely) | — | `skipif`/SKIP (existing precedent); never a hard gate in CI |

**Missing dependencies with no fallback:** None — everything has a venv or `setup-python` path.

**Missing dependencies with fallback:** `pip`, `setuptools`, `pytest` — all resolved by a venv locally and `actions/setup-python@v6` in CI. **Every install/test task in the plan must include the bootstrap step explicitly; do not assume a usable pip exists.**

## Validation Architecture

> nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`). This phase *is* the validation foundation, so validation is layered.

### Test Framework
| Property | Value |
|----------|-------|
| Framework (existing) | Bash characterization suite — per-phase `tests/phase-NN/run.sh` aggregators + `test_*.sh`, sourcing `lib.sh`. This is the parity oracle substrate (D-11/D-13). |
| Framework (new) | `pytest` 8.x (NOT installed — bootstrap into venv) — TEST-05 unit/harness layer |
| Config file | none today; add `tests/conftest.py` + a `[tool.pytest.ini_options]` table in `pyproject.toml` (testpaths, markers) |
| Quick run command | `bash tests/phase-NN/run.sh` (single suite) ; `WIKI_IMPL=py bash tests/phase-NN/run.sh` (parity lane) ; `pytest tests/ -x` (unit) |
| Full suite command | `for d in tests/phase-*/; do bash "$d/run.sh"; done` (both `WIKI_IMPL` values) + `pytest tests/` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PKG-01 | `pip install -e .` succeeds; `import compendium` + each `compendium.<tool>` importable; `python -m compendium.<tool>` resolves | smoke | `python3 -m venv .venv && .venv/bin/pip install -e . && .venv/bin/python -c "import compendium, compendium.common"` | ❌ Wave 0 (`tests/test_packaging.py`) |
| PKG-02 | `common/` modules importable + byte-identical to `bin/lib/` source; `make_yaml` round-trips a fixture byte-exactly; no `lint`↔`audit` byte-copy remains | unit | `pytest tests/test_common_extraction.py -x` | ❌ Wave 0 |
| PKG-03 | shim form preserves argv/exit/stdout-vs-stderr (validated as the Phase-23 acceptance; in P22 assert the *documented* shim form + that bash bodies still run) | characterization | `WIKI_IMPL=bash bash tests/phase-NN/run.sh` (baseline) | ✅ (existing suites) |
| PKG-04 | 3 workflows install the package; the 6 required-check names unchanged; new lanes added | CI introspection | grep workflow YAML for the 6 names; assert present + unrenamed | ❌ Wave 0 (`tests/test_ci_required_checks.py`) |
| TEST-01 | every invocation routes through `invoke_tool`; `WIKI_IMPL=bash` byte-identical to direct call (self-parity); `WIKI_IMPL=py` falls through | harness self-test | `tests/lib/test_invoke_tool_selfparity.sh` | ❌ Wave 0 |
| TEST-02 | suites 09–20 present in CI workflow YAML | CI introspection | assert each `tests/phase-NN/run.sh` referenced in a workflow | ❌ Wave 0 |
| TEST-03 | characterization goldens frozen (4 channels) for backfilled targets; `validate-op` + `search` modes covered | characterization | `bash tests/phase-NN/run.sh` + golden-presence check | ❌ Wave 0 (new `tests/phase-24/` or extend existing) |
| TEST-04 | anti-signal tests rewritten/quarantined; assert behavior not source | characterization | `bash tests/phase-11/test_hashlib_*.sh` (rewritten) ; pdf-extract quarantined | ✅ exist (must be edited) |
| TEST-05 | `conftest.py` `git_repo`/`fixture_repo` + `assert_golden_tree` + `skipif` markers work | unit | `pytest tests/test_conftest_fixtures.py -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the touched suite's quick run, both impls: `WIKI_IMPL=bash bash tests/phase-NN/run.sh && WIKI_IMPL=py bash tests/phase-NN/run.sh`; plus `pytest tests/<new>.py -x` for unit work.
- **Per wave merge:** full bash suite (both `WIKI_IMPL`) + `pytest tests/` + the freeze-guard diff + the 6 existing CI gates.
- **Phase gate:** `pip install -e .` green; `import compendium.common` green; all suites at-or-above their pinned baseline status under both `WIKI_IMPL`; `common-freeze` guard active and passing; 6 required-check names verified present; `sync-claude --check` green (src/ added to both AGENTS.md + CLAUDE.md byte-identically).

### Wave 0 Gaps
- [ ] `tests/test_packaging.py` — PKG-01 install + import smoke (and the venv bootstrap doc)
- [ ] `tests/test_common_extraction.py` — PKG-02 byte-identity + `make_yaml` round-trip (TEST-06 seed)
- [ ] `tests/test_ci_required_checks.py` — PKG-04/TEST-02 workflow-YAML introspection (required names present, suites 09–20 referenced)
- [ ] `tests/lib/invoke_tool.sh` + `tests/lib/normalize.sh` — the seam + normalizer (TEST-01)
- [ ] `tests/lib/test_invoke_tool_selfparity.sh` — seam self-parity guard (Pitfall 3)
- [ ] `tests/lib/test_normalize.sh` — normalizer self-test (redaction set pinned)
- [ ] `tests/conftest.py` — pytest fixtures + `assert_golden_tree` + `skipif` (TEST-05)
- [ ] characterization goldens for `validate-op.sh` (zero tests today) + `search.sh` `--query`/`--paths-only`/`--fulltext` modes (D-15/TEST-03)
- [ ] error-path goldens (D-17): dual-mode `lint` codes, `sync-claude`=2, `init-wizard`=3, `gen-skills`=1, checker exit 2, malformed YAML
- [ ] rewrite `tests/phase-11/test_hashlib_not_sha256sum.sh` to assert hash value; quarantine/rewrite `tests/phase-20/test_pdf_extract_markers.sh` source-grep (TEST-04)
- [ ] `pyproject.toml` `[tool.pytest.ini_options]` + `[project.optional-dependencies] dev = ["pytest"]`
- [ ] Framework install: `python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"` (pip absent in system py)
- [ ] `common-freeze` CI guard job + `phase-24-freeze` baseline tag (+ committed fallback SHA per A6)

## Compatibility Landmines to Preserve (verbatim contracts)

These must hold byte-for-byte; the foundation neither changes them nor allows the freeze/seam to perturb them.

| Contract | Detail | Where verified |
|----------|--------|----------------|
| `lint --ci --format json` schema | Flat JSON array of objects keyed `severity` / `path` / `line` / `message` / `category`; consumed by `json-to-annotations.py` (sorts by severity, preserves within-severity order, caps 10/10/50) | `.github/scripts/json-to-annotations.py` `[VERIFIED]` |
| Divergent exit codes | `sync-claude` drift = **2**; `gen-skills` drift = **1**; `init-wizard` = **3** (CONTEXT); checkers (`check-privacy`/`check-neutrality`/`check-sources-cloud-safe`) violation = **2**; `lint` dual-mode (text vs `--ci`) | `bin/sync-claude.sh` exit 2, `bin/gen-skills.sh` exit 1 `[VERIFIED]`; others `[CITED: CONTEXT.md D-17]` |
| stdout/stderr discipline | Diagnostics on stderr; payload on stdout; the seam captures these **separately** (D-11) and must not merge them | `tests/phase-09/test_lint_ci_mode.sh` redirects `2>/dev/null` `[VERIFIED]` |
| `audit-claims --verifier` egress | Sole egress = verifier; payload on **STDIN only** via `shlex.split(cmd)` + `shell=False`; no eval; every verifier cloud-by-default | `bin/audit-claims.sh` lines 23–34, 138 `[VERIFIED]` |
| `make_yaml` byte-exact chokepoint | `YAML(typ='rt')` + `preserve_quotes` + `default_flow_style=False` + `null` representer; PyYAML preflight + ruamel round-trip | `bin/lib/brownfield_yaml.py:164` `[VERIFIED]` |
| `AGENTS.md ≡ CLAUDE.md` byte-equality | Enforced by `sync-claude --check` (exit 2); adding `src/` to §2 must update **both** identically | `cmp -s AGENTS.md CLAUDE.md` → EQUAL `[VERIFIED]` |
| Required CI check names | `lint`, `privacy-leak`, `strict`, `skills-check`, `neutrality`, `setup-parity` — frozen public-template branch-protection contract | `.github/workflows/*.yml` `[VERIFIED]` |
| `.claude/settings.local.json` shim references | Calls `bash bin/validate-op.sh ...`, `bash tests/phase-NN/run.sh` — must keep working unchanged (PKG-03) | `.claude/settings.local.json` `[VERIFIED]` |
| pre-commit hot path | `sync-claude → gen-skills → lint`; latency-sensitive; shims add only interpreter startup | `.githooks/pre-commit` `[VERIFIED]` |

## Project Constraints (from CLAUDE.md)

`./CLAUDE.md` is the LLM Wiki Compiler schema router. Directives relevant to this phase:
- **Permitted top-level directories** (§2) — currently `sources/`, `wiki-cloud/`, `wiki-local/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. **Must add `src/`** (D-02) — edit `AGENTS.md` then `bin/sync-claude.sh` to propagate byte-identically to `CLAUDE.md` (then `--check` to verify). `tests/` is also a real top-level dir not listed; the planner should decide whether to add `tests/` and `src/` together (consistency) or only `src/` (minimal). Recommend adding both to avoid a future lint-routing surprise, but `src/` is the locked requirement.
- **Conventions live only in AGENTS.md or routed files** — packaging conventions (where `pyproject.toml` lives, the shim form) are tooling, not wiki schema; they belong in a decision record (Phase 25 CUT-01) and code comments, NOT in the wiki schema body. Do not add packaging rules to `schema/reference/*.md`.
- **Template-public neutrality** — `pyproject.toml`, `bin/*.sh`, `.github/`, `docs/` are template-public surfaces. Use abstract placeholders, never real vault slugs/IDs, in any example or comment. `bin/check-neutrality.sh` is a backstop. The `compendium` package name + tool names are neutral (no vault content), so this is low-risk here, but the freeze-guard config / DR must not embed `wiki-local/` example terms.
- **One commit per logical operation** — conventional-commit format. Packaging/test-infra changes don't map to the wiki op types (`ingest`/`query`/`lint`/`reflect`/`schema`); use the GSD conventional types from config (`feat`/`chore`/`test`/`docs`) for code, and `schema:` only for the AGENTS.md/CLAUDE.md §2 edit.
- **`commit_docs: true`** — this RESEARCH.md is committed by the researcher.

## Sources

### Primary (HIGH confidence)
- Codebase (direct read, this session): `bin/lib/*.py` (5 modules + APIs), `bin/sync-claude.sh`, `bin/gen-skills.sh` (drift-gate exit codes), `bin/lint.sh` (heredoc arg-passing, env-var pattern), `bin/audit-claims.sh` (verifier egress contract), `bin/validate-op.sh` + `bin/search.sh` (backfill targets, modes), `tests/phase-10/{lib.sh,run.sh}` (harness contract), `tests/phase-09/test_lint_ci_mode.sh` (invocation + stderr discipline), `tests/phase-11/test_hashlib_not_sha256sum.sh` + `tests/phase-20/test_pdf_extract_markers.sh` (anti-signal tests), `.github/workflows/{lint,neutrality,setup-parity}.yml`, `.github/scripts/json-to-annotations.py` (locked JSON schema), `.githooks/pre-commit`, `.claude/settings.local.json`, `CLAUDE.md`/`AGENTS.md` (byte-equal, §2 permitted dirs).
- Tool probes (this session): Python 3.12.3; `pip` absent (`No module named pip`); `setuptools`/`pytest` absent; PyYAML 6.0.1; ruamel.yaml 0.19.1; `tomllib`/`venv` present; git 2.43.0; tags `v1.0..v1.3`; 371 `bin/*.sh` invocation sites; 60 `make_bare_repo` / 96 `make_fixture_repo` calls; suites present = 07,08,09,09.1,10,11,12.1,12.2,13,15,18,20.
- PyPA Packaging Guide — `pyproject.toml` `[build-system]` / `[project.scripts]` / `requires-python` / src-layout `[CITED: packaging.python.org/en/latest/guides/writing-pyproject-toml/]`
- setuptools docs — entry points + pyproject config + src-layout auto-discovery `[CITED: setuptools.pypa.io/en/latest/userguide/pyproject_config.html]`
- pytest docs — `tmp_path`, `capsys`/`capfd` `[CITED: docs.pytest.org/en/stable/how-to/tmp_path.html, .../capture-stdout-stderr.html]`
- PyPI registry — PyYAML 6.0.3 (requires >=3.8); ruamel.yaml 0.19.1 (2025-01-02, requires >=3.9) `[VERIFIED: pypi.org JSON API]`

### Secondary (MEDIUM confidence)
- WebSearch (verified against the official docs above): src-layout/console_scripts best practice; pytest golden-file / characterization patterns.

### Tertiary (LOW confidence)
- None relied upon. (Golden-testing library choice marked `[ASSUMED]` A1; not load-bearing.)

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — versions verified against PyPI; setuptools/pyproject syntax cited from PyPA; both YAML deps already in-repo use.
- Architecture (common/ decomposition, seam, freeze, CI): **HIGH** — grounded directly in existing code; the seam maps 1:1 onto the uniform `bash bin/X.sh` invocation pattern; the freeze guard maps 1:1 onto existing drift gates.
- Pitfalls: **HIGH** — each is anchored to a verified codebase fact (absent pip; red suites at HEAD from STATE.md; the make_yaml settings; the required-check names).
- Open questions: honest gaps (PyYAML golden-version, exact tool count, "wire" semantics for red suites) flagged for planner resolution.

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 (stable — packaging/test tooling is slow-moving; the codebase facts are pinned to HEAD `ddce2df`). Re-verify the PyYAML golden-version question (Open Q1) before pinning the dep.

# Phase 24: Foundation — Package Skeleton + Frozen Shared Core + Parity Oracle - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
**Areas discussed:** Package layout & name, Python version floor, `common/` freeze enforcement, Parity oracle & test seam

---

## Package layout & name

### Package / import name
| Option | Description | Selected |
|--------|-------------|----------|
| `compendium` | Matches repo / working-dir name; short clean identifier | ✓ |
| `llm_wiki_compiler` | Most descriptive, matches project title; verbose at every import site | |
| `wikic` | Terse, CLI-friendly; less self-explanatory | |

### Repo layout
| Option | Description | Selected |
|--------|-------------|----------|
| `src/` layout | `src/compendium/` — PyPA-standard, prevents import shadowing, isolates one new top-level dir | ✓ |
| Top-level `<pkg>/` | Package dir at repo root; one fewer level; higher shadowing risk | |
| Extend `bin/lib/` in place | Minimal new structure; not import-rooted/installable cleanly; fights `pip install -e .` | |

### Entry-point / module naming
| Option | Description | Selected |
|--------|-------------|----------|
| `compendium-<tool>` + module | `compendium.lint:main` → `compendium-lint`; namespaced, PATH-safe; ~16 pre-declared stubs | ✓ |
| Bare `<tool>` names | `lint`, `ingest`...; collision-prone on PATH | |
| Module-only (no scripts) | `python -m` only; conflicts with PKG-01's console_scripts requirement | |

### Shim exec mechanism
| Option | Description | Selected |
|--------|-------------|----------|
| `python3 -m compendium.<tool>` | `exec python3 -m compendium.lint "$@"` — hermetic, no PATH dependency | ✓ |
| `exec` the console_script | `exec compendium-lint "$@"` — relies on install bin/ on PATH in every context | |

**User's choice:** `compendium` + `src/` layout + `compendium-<tool>` console_scripts/modules + `python3 -m` shim invocation.
**Notes:** All ~16 entry points pre-declared as stubs in Phase 24 (SC#1) so Phase 25 never edits `pyproject.toml`. `src/` addition requires a `CLAUDE.md`/`AGENTS.md` §2 permitted-dirs update.

---

## Python version floor

### `requires-python` floor
| Option | Description | Selected |
|--------|-------------|----------|
| `>=3.11` | Modern floor, headroom below installed 3.12; tomllib/match/unions | ✓ |
| `>=3.12` | Pin to installed; no syntax gain; brittle | |
| `>=3.9` | Max compat; forgoes match/unions/tomllib; portability not a goal | |

### CI Python strategy
| Option | Description | Selected |
|--------|-------------|----------|
| Single version | One Python (3.12, matching env); parity not portability is the bar | ✓ |
| Matrix (floor + latest) | Tests floor + newest; multiplies CI time; over-engineering here | |

**User's choice:** `>=3.11` floor, single-version CI (3.12).
**Notes:** Dev box runs Python 3.12.3 with `ruamel.yaml` 0.19.1 + `PyYAML` 6.0.1 already present; CI on `ubuntu-latest` (3.12).

---

## `common/` freeze enforcement

### Enforcement mechanism
| Option | Description | Selected |
|--------|-------------|----------|
| Per-plan CI guard | Each Wave-1 branch diffed vs. pinned baseline; fails fast at the plan level | ✓ |
| Pre-commit guard only | Local hook, fast feedback but bypassable + local-only | |
| Convention + worktrees only | Trust the freeze; divergence only surfaces at fan-in | |
| Fan-in check only | One check at Wave-2 integration; discovers violations late | |

### Freeze scope
| Option | Description | Selected |
|--------|-------------|----------|
| All shared surfaces | `common/` + `pyproject.toml` + test seam — the real conflict surface | ✓ |
| `common/` only | Leaves pyproject + harness unguarded | |

**User's choice:** Per-plan CI guard over all shared surfaces, diffed vs. a pinned Phase-22 baseline; ownership-rebase as the sanctioned escape hatch.
**Notes:** User asked whether worktree-per-plan isolation makes the guard redundant. Resolved: complementary — worktrees isolate the working directory (solve the disjoint-file case) but cannot protect a shared file; two worktrees editing `common/` each pass parity in isolation and only break at fan-in. The guard protects exactly the surface worktrees can't isolate. Mechanical enforcement is worth it because Phase-23 executors are agents and there is no PR-review gate.

---

## Parity oracle & test seam

### Seam role (where signal is created)
| Option | Description | Selected |
|--------|-------------|----------|
| Footprint-capturing seam | `invoke_tool` captures stdout+stderr+exit+file-tree + normalization; harness diffs bash vs py; every routed test → full parity check | ✓ |
| Dispatch-only seam | Just selects impl; signal limited to each test's existing assertions | |

### Helper scope
| Option | Description | Selected |
|--------|-------------|----------|
| Minimal (seam only) | Add `invoke_tool`; leave 12 per-phase `make_*_repo` untouched; protects baseline attribution | ✓ |
| Full `tests/lib/` consolidation | Also dedupe helpers; zero signal gain; risks shifting baseline at freeze time | |

### `WIKI_IMPL=py` CI lane
| Option | Description | Selected |
|--------|-------------|----------|
| Wire py lane now (matrix) | `WIKI_IMPL=[bash,py]` matrix in Phase 24; py green-by-fallthrough; Phase-23 ports light up with zero CI edits | ✓ |
| Defer py lane to Phase 25 | Add when first port lands; reintroduces shared-CI contention during the parallel wave | |

**User's choice:** Footprint-capturing `invoke_tool` seam + minimal harness change + `WIKI_IMPL=[bash,py]` matrix wired now.
**Notes:** User reframed the seam decision as "best way to gain significant signal from tests for eval during Phase 25." Answer drove the eval-signal discipline now captured as CONTEXT D-11..D-18: backfill coverage first (no test = no signal), capture full footprint in the seam, normalize nondeterminism, quarantine implementation-asserting tests (anti-signal), cover error paths, grow the `common/` unit layer for localization. Model: `signal ≈ coverage × comparison-richness × signal-to-noise − anti-signal tests`.

## Claude's Discretion

- Internal module decomposition of `common/` (subject to over-extract-to-completion + freeze).
- Concrete baseline-pinning mechanism for the freeze guard (git tag vs recorded SHA).
- On-disk golden storage format for the frozen characterization footprints (must capture all four channels).

## Deferred Ideas

- Full `tests/lib/` consolidation of the 12 `make_*_repo` helpers — post-migration cleanup.
- Shim removal (FUTURE: SHIMOUT) and native-library swaps (FUTURE: LIBSWAP) — out of v1.5 scope.
- `phase-14-lint-mask-fence-edge-cases` todo — reviewed, NOT folded (behavior change, violates parity bar); stays in pending for a future milestone.

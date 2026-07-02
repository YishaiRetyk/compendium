# Phase 24: Foundation — Package Skeleton + Frozen Shared Core + Parity Oracle - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 24 builds the **frozen foundation** for the v1.5 Bash→Python migration — the one hard serialization point all later parallelism depends on. It delivers:

1. An installable package skeleton (`pyproject.toml` + pre-declared `console_scripts` entry-point **stubs**).
2. An over-extracted-then-**frozen** shared `common/` core (from `bin/lib/*.py`).
3. The `WIKI_IMPL=bash|py` parity-oracle seam (`invoke_tool`) + characterization-golden backfill.
4. CI wiring for phase suites 09–20 (today only 07–08 gate).
5. A pytest harness (`conftest.py`) ready to host net-new unit coverage in Phase 25.

**No script is ported in Phase 24.** Every `bin/<name>.sh` still runs its bash body; `WIKI_IMPL=py` falls through to bash unchanged. Porting is Phase 25. **Behavior parity is the acceptance bar** — this is a pure internal refactor that relocates logic and adds zero user-facing capability.

</domain>

<decisions>
## Implementation Decisions

### Package Identity & Layout
- **D-01:** Package / import name is **`compendium`** (matches repo + working-dir name; clean Python identifier). Used as `import compendium.<tool>` everywhere and as the distribution name in `pyproject.toml`.
- **D-02:** Repo layout is **`src/` layout** → `src/compendium/`. PyPA-standard; prevents in-tree import shadowing (forces testing the *installed* package); isolates everything under one new top-level `src/`. This adds `src/` to the permitted top-level directories — **`CLAUDE.md` §2 (and its byte-twin `AGENTS.md`) must be updated** to list it.
- **D-03:** Per-tool entry points are **`compendium-<tool>`** console_scripts bound to **`compendium.<tool>:main`** modules (e.g. `compendium-lint` → `compendium.lint:main`). Namespaced to stay collision-free on `PATH`. **All ~16 entry points are pre-declared against stub modules in Phase 24** (per Success Criterion #1) so Phase-23 plans only *fill* stubs and never edit `pyproject.toml`.
- **D-04:** Each `bin/<name>.sh` shim invokes Python as **`exec python3 -m compendium.<tool> "$@"`** (module invocation, not the console_script). Hermetic — works whenever the package is importable, with no dependency on the install's `bin/` being on `PATH` (robust across CI, the pre-commit hot path, and the user's shell).

### Python Version
- **D-05:** `pyproject.toml` pins **`requires-python = ">=3.11"`** — modern floor with slight headroom below the installed 3.12 (gives `tomllib`, exception groups, better tracebacks, `X | Y` unions, `match`). Not `>=3.12` (no syntax gain, brittle), not `>=3.9` (portability to old systems is not a goal).
- **D-06:** CI runs on a **single Python version** (3.12, matching the dev env) — **no version matrix**. This is a personal internal refactor where parity, not cross-version portability, is the bar.

### `common/` Freeze Enforcement
- **D-07:** "Frozen" is enforced by a **per-plan CI guard**: each Phase-23 Wave-1 plan branch is diffed against a **pinned Phase-22 baseline** (git tag / recorded SHA); CI **fails fast** if the plan touched the frozen surface. Chosen over convention-only (a divergent edit only surfaces as a merge/parity break at fan-in) and over a fan-in-only check (discovers violations late). Rationale: Phase-23 executors are LLM agents and there is no PR-review gate (solo dev) — a mechanical, per-plan stop converts a silent integration-time surprise into an immediate, local failure.
- **D-08:** The freeze covers **all shared surfaces**, not just `common/`: `src/compendium/common/**` + `pyproject.toml` (entry-point declarations) + the shared test seam. Matches the actual conflict surface (SC#1: Phase-23 plans never edit `pyproject.toml`; SC#2: never write `common/`).
- **D-09:** "Frozen" is **deliberate-additions-allowed, not absolute immutability.** The sanctioned escape hatch is the ROADMAP's **ownership-rebase fallback**: when a genuine `common/` gap surfaces mid-wave, **one** plan lands the addition + bumps the baseline, and the other plans rebase and re-verify parity.

### Worktree ↔ Freeze Interaction (rationale, captured during discussion)
- **D-10:** Phase-23's worktree-per-plan isolation and the `common/` freeze are **complementary, not redundant.** Worktrees isolate the *working directory* → they fully solve the **disjoint-file** case (different scripts → different modules merge cleanly). They do **not** protect a **shared** file: two worktrees editing `common/` pass parity *each in isolation* (each tests against its own `common/`), and the merged result — which neither plan tested — only breaks at fan-in. The freeze guards exactly the surface worktrees cannot isolate; freezing `common/` makes all remaining Phase-23 work disjoint, which is what makes worktree-only isolation sufficient for the rest.

### Parity Oracle & Test Seam
- **D-11:** The `WIKI_IMPL` seam is a **footprint-capturing `invoke_tool`**: it captures the **full footprint** of each script invocation — **stdout + stderr (separately) + exit code + resulting file-tree bytes** — and the harness diffs the `bash`-run footprint against the `py`-run footprint. Consequence: every test routed through `invoke_tool` becomes a full parity check *regardless of what it originally asserted* — signal is created in the seam, not by rewriting tests. (TEST-01 + TEST-03's "full stdout + exit code + resulting file tree.")
- **D-12:** `invoke_tool` includes a **normalization layer** so strict byte-comparison yields signal, not noise: redact timestamps, temp paths, and git SHAs; pin locale + timezone; stabilize ordering where order is not contractual. Strict comparison *requires* this companion — un-normalized → false failures; un-strict → missed divergences. **[Amended cycle-6: SHA/hex redaction narrowed to timestamps + temp paths ONLY — blanket SHA redaction masked a wrong Python-emitted hash and hid a real parity failure; see Plan 03 `tests/lib/normalize.sh` rationale, cycle-1 HIGH#2. The built normalizer redacts `T..:..:..` timestamps + `/tmp` paths but deliberately does NOT redact hex/SHA tokens — a stricter, safer deviation, not a scope reduction.]**
- **D-13:** Phase 24 makes the **minimal** harness change — add the shared `invoke_tool` seam (in `tests/lib/`), route all script invocations through it, and **leave the 12 per-phase `make_bare_repo`/`make_fixture_repo` helpers untouched.** Protects baseline attribution (a frozen oracle means any diff is the port's fault, not a moved fixture). The `WIKI_IMPL=bash` path must stay byte-identical to today. Full `make_*_repo` consolidation adds zero parity signal and is **deferred** to a later cleanup.
- **D-14:** The **`WIKI_IMPL=[bash,py]` CI matrix is wired now**, in Phase 24. `py` is green-by-fallthrough (nothing ported yet); each Phase-23 port then lights up automatically with **zero CI edits** — keeping CI workflows off the Wave-1 shared surface (consistent with D-08).

### Eval-Signal Discipline (foundation requirements derived from the discussion)
- **D-15:** **Backfill coverage before any port.** No test = zero parity signal. `validate-op.sh` (zero tests today) and the untested `search.sh` modes get characterization tests *first* (TEST-03). This is the single biggest signal lever.
- **D-16:** **Quarantine / rewrite implementation-asserting tests** that would false-fail on a correct Python port (the `hashlib`-not-`sha256sum` grep; the `pdf-extract` `api/generate` body-grep) — rewrite to assert behavior (the hash *value*, the actual effect) or quarantine (TEST-04). These are *anti-signal*: failure on correct behavior.
- **D-17:** **Capture error-path footprints, not just happy paths** — divergence risk concentrates in exit codes + stderr (the dual-mode `lint` codes, `sync-claude`=2, `init-wizard`=3, `gen-skills`=1, checker exit 2, privacy-violation exit 2, malformed YAML).
- **D-18:** The net-new pytest **unit layer (TEST-06) exists for localization** — parity says *that* behavior broke; unit tests on `common/` (`make_yaml`, `resolve_effective_claim_privacy`, `classify_page`, lint check functions) say *where*. Grown alongside each Phase-23 cluster, not deferred.

### Claude's Discretion
- Exact module decomposition of `common/` (how finely the privacy resolver / YAML round-trip / vault walker / wiki-page primitives are split) is left to research/planning, subject to D-08 (it must be complete and frozen) — the *over-extract-to-completion* mandate is locked, the internal file boundaries are not.
- The concrete baseline-pinning mechanism for D-07 (git tag at Phase-22 close vs. a recorded SHA in a guard config) is an implementation detail for the planner.
- Golden storage format / on-disk layout for the frozen characterization footprints (D-11) is planner's choice, provided it captures all four channels.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & this phase's contract
- `.planning/ROADMAP.md` — **Phase 24 section** (Goal, Depends-on, the 9 requirements, the **6 Success Criteria**) + the milestone **"Standing criteria"** block that applies to every v1.5 phase (CI gate names unchanged; shims stay thin exec-shims; `AGENTS.md ≡ CLAUDE.md`; TEST-06 grows per-cluster). Also Phase 25 §"Structure — TWO WAVES" for the fan-out/fan-in this foundation enables.
- `.planning/REQUIREMENTS.md` — full text of **PKG-01..04** and **TEST-01..05** (Phase 24's requirements) + the design lineage (7-agent codebase assessment, 2026-06-18) and the LOCKED strategy. Also the Out-of-Scope table (no behavior changes; shims stay; `schema/brownfield/migrations/*.sh` deferred).
- `.planning/PROJECT.md` — **"Current Milestone: v1.5 Python Migration"** section + the Key Decisions row on shim-and-swap rationale. **"Key context"** names the hard compatibility boundaries to hold: the `lint --ci` JSON/exit contract, divergent per-script exit codes (`sync-claude`=2, `lint` dual-mode, `init-wizard`=3), stdout/stderr discipline, the `--verifier` egress security contract, `AGENTS.md ≡ CLAUDE.md` byte-equality.

### Code the foundation extracts from / wraps
- `bin/lib/*.py` — the source modules to over-extract into `common/`: `privacy_resolve.py` (privacy resolver), `brownfield_yaml.py` (YAML round-trip incl. the `make_yaml` canonicalization chokepoint), `brownfield_walk.py` (vault walker), `brownfield_classify.py`, `brownfield_provenance.py`. **Single source of truth target** — retires the `lint`↔`audit-claims` byte-copy.
- `bin/*.sh` — the 17 scripts (the shim targets); 12 carry `python3` heredocs (the logic to relocate).
- `.github/workflows/lint.yml`, `.github/workflows/neutrality.yml`, `.github/workflows/setup-parity.yml` — the 3 existing CI workflows to extend (wire 09–20; add the `WIKI_IMPL` matrix). Required-check names must stay unchanged (PKG-04).
- `.github/scripts/json-to-annotations.py` — **consumes** the `lint --ci --format json` output; the JSON schema/exit contract is locked by a golden it depends on.
- `tests/phase-*/lib.sh` + `tests/phase-*/run.sh` — the existing per-phase harness the `invoke_tool` seam routes through; defines `make_bare_repo` (60 call sites) / `make_fixture_repo` (96 call sites), left untouched per D-13.
- `.claude/settings.local.json` — a downstream caller of `bin/*.sh` (must keep invoking the shims unchanged, PKG-03).

### Schema rule this phase must update
- `CLAUDE.md` §2 "Permitted top-level directories" (and the byte-identical `AGENTS.md`) — must add `src/` per D-02; `bin/sync-claude.sh --check` enforces the byte-equality.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/lib/privacy_resolve.py` (added Phase 13/15) — already-Python privacy resolver; lifts directly into `common/`.
- `bin/lib/brownfield_*.py` (~1.2k lines) — already-Python; the YAML round-trip (`make_yaml`) is the byte-exact canonicalization chokepoint that several scripts share.
- `tests/phase-*/lib.sh` `make_bare_repo` / `make_fixture_repo` — throwaway-git-repo fixtures; **TEST-05 replicates these as a pytest `git_repo`/`tmp_path` fixture** in `conftest.py` (bash helpers stay as-is per D-13).

### Established Patterns
- **Shim-and-swap / thin glue:** `bin/pdf-extract.sh` (Phase 20) is already the model of a thin `.sh` wrapper around heavy logic with external boundaries (poppler, Ollama HTTP) kept as subprocess/HTTP calls — the template for how Python ports keep poppler/Ollama/git as processes (MIG-05).
- **Drift-gate-as-CI-check:** `bin/sync-claude.sh --check` (exit 2), `bin/gen-skills.sh --check` (exit 1), and the `setup-parity` byte-equality gate are the precedent for the new per-plan `common-freeze` guard (D-07) — a baseline-diff check that hard-fails CI.
- **Single-`python3`-heredoc-per-script:** lint and most checkers already embed one `python3` block — extraction is "lift the heredoc into a module," not a rewrite.

### Integration Points
- pre-commit hook chain `sync-claude → gen-skills → lint` (latency-sensitive hot path) — the foundation must not regress its latency; shims add only interpreter startup (D-04).
- CI required checks (`lint`, `privacy-leak`, `strict`, `skills-check`, `neutrality`, `setup-parity`) — names frozen (PKG-04); the foundation *adds* lanes (09–20 suites, `WIKI_IMPL` matrix) without renaming.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly framed the test-seam decision around **eval signal** ("the best way to gain significant signal from tests during Phase 25") — hence D-11..D-18. The guiding model: `signal ≈ (coverage that exists) × (richness of each comparison) × (signal-to-noise from normalization) − (tests that false-fail on a correct port)`. Put the richness in the seam, not in fixture rewrites.
- The user probed whether worktree-per-plan isolation makes the freeze guard redundant — resolved as D-10 (complementary; worktrees handle disjoint files, the freeze handles the shared surface they cannot isolate).

</specifics>

<deferred>
## Deferred Ideas

- **Full `tests/lib/` consolidation** of the 12 duplicated `make_*_repo` helpers — on-ethos with killing the byte-copy, but adds zero parity signal and risks shifting the oracle baseline at freeze time. Deferred to a post-migration cleanup (D-13).
- **Shim removal (FUTURE: SHIMOUT)** and **native-library swaps (FUTURE: LIBSWAP)** — already tracked in REQUIREMENTS.md Future Requirements; out of v1.5 scope.

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` (cross-reference score 0.6, generic-keyword match only) — **not folded.** It is a `bin/lint.sh` *behavior* hardening (mask_markdown fence edge cases), which would violate v1.5's behavior-parity bar. It is not foundation work and does not belong in any v1.5 phase; it stays in `.planning/todos/pending/` for a future behavior-change milestone.

</deferred>

---

*Phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle*
*Context gathered: 2026-06-18*

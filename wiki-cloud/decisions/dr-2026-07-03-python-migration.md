---
id: dr-2026-07-03-python-migration
title: "Bash-to-Python Migration: Shim-and-Swap Behind a Byte-Parity Oracle"
type: decision
status: active
summary: "Records the v1.5 re-platform of the bin/ toolchain from Bash to a Python
  package behind .sh exec-shims: shim-and-swap with every CLI contract preserved,
  a frozen shared common/ core replacing the lint/audit byte-copy, a two-layer test
  strategy (4-channel parity oracle + module-level pytest), the two retirements, the
  template allowlist extension that keeps released checkouts functional, and the
  deliberate deferrals (shim removal, native-library re-platforming, pytest
  conversion)."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-07-03-python-migration
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# Bash-to-Python Migration: Shim-and-Swap Behind a Byte-Parity Oracle

## TL;DR

v1.5 re-platformed all sixteen in-scope `bin/` tools from Bash (~10.2k lines, 72%
already Python inside heredocs) to an installable Python package (`src/compendium/`)
behind thin `bin/<tool>.sh` exec-shims. Every argv / exit-code / stdout-vs-stderr
contract is preserved byte-for-byte: behavior parity was the acceptance bar, enforced
by a 4-channel oracle (stdout, stderr, exit code, resulting file tree) that diffs each
routed test invocation against a held-fixed worktree checkout. Callers — CI, the
pre-commit hook, docs, editor settings — invoke the same `bin/<tool>.sh` paths
unchanged.

## Decision

1. **Shim-and-swap, not caller migration.** Each `bin/<tool>.sh` became a
   self-bootstrapping exec-shim (`PYTHONPATH=<repo>/src` + `exec python3 -m
   compendium.<tool>`), keeping every existing reference green. `init-wizard` is the
   one non-canonical shim: its exit-3 pre-flight is a dependency-PRESENCE check that
   cannot live inside Python ("is python3 missing?") and stays in bash.
2. **A frozen shared core first.** `compendium.common` (privacy resolver, YAML
   round-trip, vault walker, classifier, provenance scan, wiki-page primitives) was
   extracted and FROZEN before any port, so parallel cluster ports never wrote a
   shared file. The long-standing lint↔audit byte-copy of the page primitives is
   retired — one authoritative copy in `common/page.py`.
3. **Two-layer test strategy.** Layer 1: the existing black-box suites run against
   either implementation via a `WIKI_IMPL=bash|py` seam with per-invocation 4-channel
   capture and byte-comparison. Layer 2: net-new module-level pytest coverage grown
   with each cluster port. The wholesale CLI→pytest conversion is deferred as its own
   terminal phase.
4. **Retirements.** `bin/migrate-privacy-dirs.sh` deleted (a spent one-off from the
   privacy-architecture milestone; zero remaining references; history preserves it).
   `bin/install-hooks.sh` stays bash (a 6-line `git config` on a hot path).
5. **The template ships the package.** The release allowlist gains `src/`,
   `pyproject.toml`, and `tests/lib/` — a released template without `src/` would ship
   sixteen broken shims. The parity pin files (`tests/ported.manifest`,
   `tests/freeze-baseline.sha`) are deliberately NOT shipped: their absence makes the
   test seam's HEAD-fallback legal on a template checkout.
6. **Bugs ported faithfully.** Known defects (a search keyword/query regression on
   piped-index links; the lint report/log write on the hook path) were reproduced
   byte-for-byte, not fixed — any behavior change is a separate post-migration
   decision with its own record.

## Alternatives Considered

- **Migrate callers to `compendium-<tool>` console scripts now** — rejected: the
  `.sh` paths are the stable interface holding hundreds of references; retirement is
  deferred (SHIMOUT) until nothing depends on them.
- **Replace external tools (poppler, Ollama HTTP, git, jq) with native libraries** —
  rejected (LIBSWAP deferred): external boundaries stay subprocess/HTTP calls, which
  also keeps test PATH-interception working identically across implementations.
- **Convert the bash test suite in the same milestone** — rejected: the black-box
  suites ARE the parity instrument; converting them mid-migration would have removed
  the measuring stick while the thing it measures was changing.

## Consequences

- All sixteen tools run Python; the pre-commit chain (sync → skills → lint) is
  Python end-to-end behind unchanged `.sh` invocations.
- The parity harness remains in place after cutover: the pinned oracle now guards the
  certified post-migration state against regression (equivalence to the original bash
  is transitive through the flip-time proofs).
- First live use of the cross-run channel comparison surfaced and fixed three latent
  harness-environment defect classes (raw tree hashing vs wall-clock stamps and
  checkout-root paths; runtime-born fixture git SHAs; live-repo footprint fragility)
  — none were implementation divergences.

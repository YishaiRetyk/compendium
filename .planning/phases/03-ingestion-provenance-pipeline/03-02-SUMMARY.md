---
phase: 03-ingestion-provenance-pipeline
plan: 02
subsystem: cli
tags: [bash, shell, cli, ingest, sha256, posix]

# Dependency graph
requires:
  - phase: 01-schema-structure-conventions
    provides: "sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/ directory convention and source summary frontmatter schema"
provides:
  - "bin/ingest.sh CLI helper that scaffolds source ingestion (directory, copy, SHA-256, instructions)"
  - "UTC-based deterministic dated paths for source ingestion"
  - "Collision handling contract: existing destination requires --force to overwrite"
  - "Slug sanitization and validation (empty slug rejection, [a-z0-9-] enforcement)"
affects: [03-03, 03-04, 03-05, query-workflow, lint-workflow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Agent/tooling split (D-11/D-12/D-13): bash handles file bookkeeping, LLM handles pipeline semantics"
    - "Portable SHA-256 via sha256sum with shasum -a 256 fallback"
    - "UTC dates for cross-timezone determinism in file paths"

key-files:
  created:
    - "bin/ingest.sh"
  modified: []

key-decisions:
  - "bin/ingest.sh is strictly file-system bookkeeping — zero LLM/API calls, no curl/node/python/npm (D-11/D-13)"
  - "UTC dates (date -u) chosen for deterministic paths across timezones; documented in script header"
  - "Collision policy: existing destination fails loudly unless --force is passed; --force overwrites without deleting the directory"
  - "Empty slug (post-sanitization or user-provided) is a hard error with actionable message"
  - "Markdown files normalize to source.md (D-11 AGENTS.md convention); other extensions preserved as source.{ext}"

patterns-established:
  - "Portable hash helper: sha256sum preferred, shasum -a 256 fallback, error exit if neither is available"
  - "Slug sanitization pipeline: lowercase -> strip extension -> non-alnum to hyphen -> collapse -> trim"
  - "CLI argument parser uses a simple while/case loop handling --slug, --force, --help/-h, and one positional"

requirements-completed: [CLI-02]

# Metrics
duration: 2min
completed: 2026-04-10
---

# Phase 03 Plan 02: CLI Ingest Helper Summary

**bin/ingest.sh bash helper that scaffolds dated source directories, copies the file, computes SHA-256, and prints ready-to-ingest instructions for the LLM agent — with collision handling, slug validation, and UTC date policy.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-04-10T14:31:34Z
- **Completed:** 2026-04-10T14:33:01Z
- **Tasks:** 1 of 1
- **Files modified:** 1 created

## Accomplishments

- Executable `bin/ingest.sh` (252 lines) implementing the full ingest scaffold contract
- Passes every plan verification check: `--help`, first scaffold, collision guard, `--force` overwrite, empty-slug rejection
- Portable SHA-256 via `sha256sum` with `shasum -a 256` fallback (verified via grep for both)
- UTC date policy documented in script header and echoed in output (`2026-04-10 (UTC)`)
- Zero external dependencies (no curl/node/python/npm references in the script)

## Task Commits

1. **Task 1: Create bin/ingest.sh with collision handling, slug validation, and UTC documentation** — `32df637` (feat)

## Files Created/Modified

- `bin/ingest.sh` — Bash CLI helper:
  - Strict mode (`set -euo pipefail`) + documented header (scope, date policy, collision policy)
  - `usage()` printed on `--help`, `-h`, or no args
  - Argument parser for `--slug <value>`, `--force`, and one positional source file
  - `sanitize_slug()` helper (lowercase, strip extension, non-alnum → hyphen, collapse, trim)
  - Empty-slug and invalid-character validation with clear error messages
  - UTC date computation for `TODAY`, `YEAR`, `MONTH`
  - Collision guard: fails with `Destination already exists` unless `--force=1`
  - `compute_hash()` helper: `sha256sum` → `shasum -a 256` → error exit
  - Extension handling: `.md`/`.markdown` normalized to `source.md`; other extensions preserved
  - Output block with file, slug, `sha256:` hash, UTC date, and "Ingest Workflow in AGENTS.md section 11.1" pointer
  - `chmod +x` applied (executable bit set)

## Decisions Made

- Kept an explicit `compute_hash()` helper function rather than inlining so future scripts can copy the exact portable pattern.
- Normalized `.markdown` to `source.md` alongside `.md` so Obsidian/AGENTS.md section 2 convention holds regardless of upstream extension.
- Lowercased non-markdown extensions (e.g. `.PDF` → `.pdf`) for consistent destination filenames.
- Added a defensive regex check (`^[a-z0-9-]+$`) after `sanitize_slug` to guard against any slug with invalid characters even after sanitization (belt-and-suspenders vs. providing `--slug` with characters sanitizer might miss).

## Deviations from Plan

None — plan executed exactly as written. The three small decisions above are implementation details within the plan's explicit instructions (sanitization pipeline, extension handling, slug validation), not scope changes.

## Issues Encountered

None.

## Verification Results

Plan verification block (all green):

- `bash bin/ingest.sh --help` prints usage and exits 0 — PASS
- `test -x bin/ingest.sh` — PASS
- `grep -cE 'curl|node|python|npm' bin/ingest.sh` → 0 — PASS
- `grep -c 'sha256' bin/ingest.sh` → 7 (≥ 2) — PASS
- `grep -c 'mkdir -p' bin/ingest.sh` → 1 (≥ 1) — PASS
- `grep -q 'Destination already exists' bin/ingest.sh` — PASS
- `grep -q -- '--force' bin/ingest.sh` — PASS
- `grep -q 'slug is empty' bin/ingest.sh` — PASS
- `grep -q 'UTC' bin/ingest.sh` — PASS
- `grep -q 'set -euo pipefail' bin/ingest.sh` — PASS

Smoke tests (all green):

- First scaffold creates `sources/2026/2026-04/2026-04-10-test-validation/source.md` — PASS
- Re-running without `--force` fails with `Destination already exists` — PASS
- Re-running with `--force` prints `--force specified; overwriting files in …` and succeeds — PASS
- `--slug ''` fails with `slug is empty` — PASS
- Cleanup removed test artifacts cleanly — PASS

## User Setup Required

None — no environment variables, no external services, no API keys. Requires only `bash`, `sha256sum` or `shasum`, and standard POSIX tools that ship with every Unix-like system.

## Next Phase Readiness

- Plan 03-03 and later plans can rely on `bin/ingest.sh` as the operator-facing scaffold step.
- The ingest workflow (AGENTS.md section 11.1) is the next thing the LLM agent will execute; the CLI is now ready to feed it the correct file path, content hash, and ingest date.
- No blockers.

## Self-Check: PASSED

- `bin/ingest.sh` exists and is executable (verified via `ls -la` and `test -x`).
- Commit `32df637` exists on current branch (verified via `git log`).

---
*Phase: 03-ingestion-provenance-pipeline*
*Completed: 2026-04-10*

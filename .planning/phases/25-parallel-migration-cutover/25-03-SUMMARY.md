# 25-03 SUMMARY — setup/release trio port (MIG-04 partial)

**Status:** Complete (2026-07-03)

## What shipped

- `src/compendium/sync_claude.py` / `gen_skills.py` / `release.py`: full Python
  rewrites of the three pure-bash tools (no heredocs to lift — the first translated-
  from-scratch cluster). Drift exits preserved: sync-claude `--check` **2**,
  gen-skills `--check` **1**; release exit map (0 dry-run/abort, 1 args, 2 preflight)
  incl. the empirically-pinned bash quirks: `read -r -p` prints no prompt when stdin
  is not a tty; EOF/partial-line read under `set -e` = silent exit 1; `shift 2`
  past end = silent exit 1; IFS answer trimming; `${RELEASE_EMAIL:-}` empty-string
  fallback.
- gen-skills anchors REPO_ROOT from the MODULE's location (3 parents up), preserving
  the run-from-any-cwd contract; the ingest.md repo-root guard precedes arg parsing
  exactly as in bash.
- release: ALLOWLIST/DENYLIST verbatim (golden-locked INCLUDES/EXCLUDES lines —
  deliberately NOT extended with src/pyproject; that is 25-07's D-09 job); staged
  pre-flights still invoke `bash bin/check-neutrality.sh` / `bash bin/sync-claude.sh
  --check` in the staged dir; `cp -a` retained as subprocess for copy semantics.
- 3 shims flipped + 3 manifest appends. **The pre-commit hot path is now Python**:
  this plan's own gated commit ran the flipped sync-claude → gen-skills chain live.
- TEST-06: `tests/test_setup_release_unit.py` (24 tests).
- Port-agent self-verification: 61/61 four-channel cases including FULL PUBLISH parity
  against local bare `file://` remotes (pushed tree bytes, `rev-list --count == 1`,
  commit author/message) and all 5 committed goldens byte-matched. My flip smokes:
  hot-path `--check` runs green through Python; the four oracle-exempt gen-skills
  tests pass through the flipped shim with `.claude/skills/` left clean.

## Notes

- Real-remote publish untested by design (local bare remotes only) — the publish path
  never runs against origin from tests.
- Unreachable edges with differing diagnostics text (same exits): CLAUDE.md-as-
  directory cmp stderr; exotic OS failures yield tracebacks. No suite coverage.
- Release's denylist-present-in-staged-dir branch (exit 2) is defense-in-depth,
  unreachable via the shipped allowlist in both impls; ported verbatim.

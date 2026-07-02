# Phase 23 Context — External Source Drift Detection

**Planned:** 2026-07-03 (autonomous session)
**Requirements:** DRIFT-01..05
**Design inputs:** promoted backlog 999.5; the Phase-9 `drift-external` CI default-skip contract (the pre-plumbed landing slot); Phase 22's `repo_url`/`commit_sha`/`default_branch` fields (the pilot case); the live drift incident from the Phase-22 ingest (documented repo home found archived); D-06 video link-rot stance (Phase 21).

## Decisions

- **D-01 — Landing slot: lint `--network`, not a new script.** The `drift` category already owns external-state checks via the `EXTERNAL: ` message prefix, and `--ci` default-skips `drift-external` (Phase 9 D-02/D-06 designed this slot). A `--network` flag gates the new checks; without it, lint output is byte-identical to today (no core workflow gains a network dependency — the 999.5 non-goal holds by construction). LINT_VERSION 1.12.0 (MINOR).
- **D-02 — Three check families:**
  1. **Repository HEAD drift** (`source_type: repository`): `git ls-remote <repo_url> <default_branch>` (no clone, `GIT_TERMINAL_PROMPT=0`, wrapped in `timeout`); HEAD ≠ `commit_sha` → warning `EXTERNAL: repository upstream drifted`; unreachable → warning; current → silence.
  2. **URL reachability** (source pages with non-empty `url`): HTTP status via `curl -sIL` (fallback GET on 405); 404/410/dead-host/timeout → warning `EXTERNAL: source url unreachable`; reachable-after-redirect → info (moved). Videos excluded (D-04).
  3. **Citation-registry link-rot** (`source_type: research-report` summaries with `## References`): sample up to 10 `r<n>::` URLs per source (deterministic: first N — stable across runs); emit ONE ratio finding per source — ≥50% dead → warning, any dead → info listing the dead entries; all alive → silence.
- **D-03 — Review-only, narrowed from the 999.5 sketch.** The backlog sketch said "marking affected source summaries `stale`" — consciously NARROWED to surface-only: claims cite the immutable ingested snapshot and remain faithful to it; upstream movement is evidence for a HUMAN decision (re-snapshot = new ingest; or annotate via UPDATE op). No page mutation, no auto-re-ingest, severity never error. DR records this.
- **D-04 — Videos excluded** per the shipped D-06 stance (committed transcript is the durable archive; `url` is a courtesy pointer). Detection: `type: source` with `source_type: transcript` AND a `channel` field (the video sub-case marker) → skipped with no finding. Documented, not accidental.
- **D-05 — Graceful tool degradation:** missing `curl`/`git`/`timeout` → one info finding naming the missing tool, checks skipped (never an error — review-only contract).
- **D-06 — Tests are network-free:** `git ls-remote` exercised against local `file://` fixture repos (works offline, exercises the real code path); URL checks exercised via a PATH-injected `curl` stub (canned status codes); a byte-identity test proves no-flag runs are unchanged.
- **D-07 — Docs:** external-drift section appended to `schema/workflows/lint.md` (the authoritative lint doc the routing table already points to — no new routing row needed); `source-types.md` registry-row forward reference verified accurate once this lands; follow-up guidance (re-snapshot vs annotate) lives in the lint.md section.

## Plan structure

- **Wave 1 — 23-01 (TDD):** `--network` flag + three check families in bin/lint.sh + tests/phase-23/ (fixture repos, curl stub, byte-identity).
- **Wave 2 — 23-02:** lint.md section + DR + real `--network` run over the live wiki with triage + log entries + tracking flips + verification.

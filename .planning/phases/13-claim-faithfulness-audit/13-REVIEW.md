---
phase: 13-claim-faithfulness-audit
reviewed: 2026-06-01T00:00:00Z
depth: deep
reviewer: gsd-code-reviewer (adversarial)
diff_base: 8fc19bc
files_reviewed: 6
files_reviewed_list:
  - bin/audit-claims.sh
  - bin/lib/privacy_resolve.py
  - AGENTS.md
  - CLAUDE.md
  - schema/AGENTS.template.md
  - schema/fixtures/canonical-AGENTS.md
findings:
  critical: 0
  high: 0
  medium: 3
  low: 4
  total: 7
status: issues_found
---

# Phase 13: Claim Faithfulness Audit — Code Review Report

**Reviewed:** 2026-06-01
**Depth:** deep (cross-file: bash entrypoint -> python heredoc -> privacy_resolve lib; doc-vs-code contract)
**Files reviewed:** 6
**Status:** issues_found (advisory — non-blocking)

## Summary

`bin/audit-claims.sh` is a privacy-critical, review-only claim-faithfulness auditor.
I focused the adversarial pass on the FAITH-04 privacy-egress chokepoint, subprocess
safety, path traversal, and resolver correctness, and confirmed the core security
properties hold:

- **No privacy-egress hole found.** The single partition (effective-claim-privacy gate,
  line 751) sits strictly upstream of BOTH `worklist.append` (770) and `run_verifier`
  (778). A `local_only`-effective claim is withheld (`continue`) before any
  passage-bearing surface. Verified end-to-end on an adversarial fixture: a
  `local_only` page citing a `local_only` source emits ONLY a bare aggregate
  `{verdict: skipped-privacy, redacted: true, count: 1}` to `--emit-worklist`
  stdout — no passage, source_id, locator, path, or slug leaks. With `--allow-local`
  the passage is admitted (intended explicit opt-in).
- **Locality is a flag, never inferred.** `--verifier` is always treated as cloud/egress;
  admission is solely `AUDIT_ALLOW_LOCAL`. `--local-verifier` is sugar that sets both.
  No command-string heuristic exists.
- **Subprocess safety holds.** `shlex.split(cmd)` + `shell=False`, payload on `input=`
  (stdin) only — never argv. stdout parsed with `json.loads` (no `eval`, no `shell=True`),
  malformed -> `insufficient` finding, never a crash.
- **Path traversal guarded.** `read_raw_source` normpath + `REPO_ROOT + os.sep` prefix
  check rejects `../`, absolute paths, and sibling-prefix escapes (`../compendium-evil/`).
- **D-11 honored.** The resolver only ever receives raw-file text from `read_raw_source`;
  the source summary's `## Extracted Claims` body is never fed to `resolve_locator`.
- **Privacy resolver is fail-closed.** `resolve_source_privacy` / `resolve_effective_claim_privacy`
  return `local_only` for None/missing/garbage-enum/no-signal; stricter-wins across
  page + source-summary + raw-source signals (verified across 10 cases). No I/O, no egless.
- **No wiki page mutation.** Only `wiki/maintenance/{audit-report,audit-state}.md`
  (both `privacy: local_only`) are written.
- **Docs match code.** `AGENTS.md == CLAUDE.md` byte-identical (mirror requirement met).
  The §11.7 Audit Workflow additions accurately describe the implemented contract
  (effective-claim privacy, redaction, flag-not-heuristic locality, report-only).

No critical or high findings. The medium findings below are robustness / defense-in-depth
gaps, not egress holes. This is solid, security-conscious work.

## Medium

### MD-01: `--format json` leaks withheld-claim metadata (source_id/locator/path) to stdout — asymmetric with the deliberate HIGH-C `--emit-worklist` redaction

**File:** `bin/audit-claims.sh:973-974` (emit), `757` (skipped-privacy finding carries slugs)
**Issue:** The HIGH-C redaction deliberately strips per-record `source_id`/`path`/`locator`
of withheld `local_only` claims from the cloud-facing `--emit-worklist` stdout (lines
953-969). But `--format json` (line 974) writes the full `findings` list to stdout,
and those findings INCLUDE the `skipped-privacy` records emitted by `add_finding` at
line 757 — each carrying `source_id`, `locator`, and `path` (private vault slugs,
T-13-21). Confirmed on an adversarial fixture: `--format json` (no `--allow-local`)
emitted `"source_id": "src-local"`, `"locator": "#sec:introduction"`,
`"path": "wiki/concepts/<slug>.md"` for a withheld local_only claim.

The passage TEXT is correctly NOT leaked (the partition withheld it before any finding
captured it), so this is existence-metadata only — the SAME class of leak the
`--emit-worklist` path deliberately redacts. The current contract designates only
`--emit-worklist` as cloud-facing, so this is "by design." But `--format json` is the
documented "lint-compatible JSON" surface an operator could plausibly pipe to a cloud
lint aggregator; the asymmetry is a latent defense-in-depth gap.
**Fix:** Apply the same per-record redaction to `skipped-privacy` findings before the
`--format json` emit (e.g. blank `source_id`/`locator`/`path`/`rationale` on
`verdict == 'skipped-privacy'` records in the stdout copy, while the file-backed
`audit-report.md` keeps full detail), OR document explicitly in §11.7 that `--format json`
stdout is a local-diagnostic-only surface that must never be piped to a cloud tool.

### MD-02: `--sample` with a negative value silently produces wrong results and defeats the no-silent-caps invariant (D-09)

**File:** `bin/audit-claims.sh:157` (`SAMPLE = int(...)`), `629` (`ordered[:SAMPLE]`)
**Issue:** `--sample` is accepted as any string by the bash arg-parse and converted with
`int()`. A negative value (`--sample -3`) parses without error, and `ordered[:-3]` is a
valid Python slice that DROPS the last 3 selected claims. Confirmed: `--sample -3`
printed `Selected 0, skipped 1` with no error/warning. The D-09 "no-silent-caps" log line
(710-720) then reports `skipped=1` as if a legitimate cap occurred, masking that the
real cause was a malformed sample. This is silent incorrect behavior on a tool whose
whole point is auditable, deterministic selection.
**Fix:** Validate after parse:
```python
SAMPLE = int(os.environ.get('AUDIT_SAMPLE', '20') or '20')
if SAMPLE < 0:
    sys.stderr.write('ERROR: --sample must be >= 0\n'); sys.exit(2)
```
(or clamp to 0 and emit a warning). Reject in the bash layer too if preferred.

### MD-03: `--sample` non-integer crashes with a raw Python traceback (no graceful error)

**File:** `bin/audit-claims.sh:157`
**Issue:** `--sample abc` reaches `int('abc')` and raises an uncaught `ValueError`,
dumping a `Traceback (most recent call last): ... ValueError: invalid literal for int()`
to stderr (exit 1 — confirmed loud, not silent). The bash arg-parse validates `--format`
against its enum (lines 95-98) but performs no numeric validation on `--sample`. Ugly UX
for a user-facing flag, inconsistent with the careful `--format` guard.
**Fix:** Validate `--sample` is a non-negative integer in the bash `case` block
(`case "$2" in ''|*[!0-9]*) echo "ERROR: --sample must be a non-negative integer" >&2; exit 1 ;; esac`)
or wrap the `int()` in try/except with a clean stderr message + `sys.exit(2)`. Folds
into the MD-02 fix.

## Low

### LW-01: `run_verifier` has no subprocess timeout — a hung verifier hangs the audit indefinitely

**File:** `bin/audit-claims.sh:688-692`
**Issue:** `subprocess.run(... )` is called with no `timeout=`. A slow, hung, or
deliberately stalling operator-supplied verifier command blocks the audit forever with
no recovery. On a security-sensitive tool that shells out to an arbitrary command per
worklist entry, a bounded wait is prudent.
**Fix:** Add `timeout=<N>` (e.g. 120s, optionally a `--verifier-timeout` flag) and catch
`subprocess.TimeoutExpired` -> return `('insufficient', 'verifier timed out')`, mirroring
the existing defensive `OSError`/`ValueError` handling.

### LW-02: Path-traversal guard is textual only — does not resolve symlinks

**File:** `bin/audit-claims.sh:466-469`
**Issue:** `os.path.normpath` collapses `..` lexically but does NOT resolve symlinks. A
symlink committed inside the repo (e.g. `sources/evil -> /etc`) whose path is referenced
by a source page's `path:` would pass the `REPO_ROOT + os.sep` textual check yet open a
file outside the repo. Likelihood is low (the `path:` is curator-controlled frontmatter,
and a malicious symlink would have to be committed), but the guard's stated intent
("candidate MUST stay under REPO_ROOT") is not fully met against symlinks.
**Fix:** Use `os.path.realpath(candidate)` (resolves symlinks) before the prefix check,
comparing against `os.path.realpath(REPO_ROOT)`. Note: realpath also costs a stat; acceptable
here.

### LW-03: Two divergent frontmatter-end detectors (`parse_frontmatter_str` vs `_strip_frontmatter`)

**File:** `bin/audit-claims.sh:202-218` (`content.index('---', 3)`) vs `287-299`
(`raw_text.index('\n---', 3)`)
**Issue:** The privacy-fold path uses `parse_frontmatter_str`, which finds the closing
fence via `index('---', 3)` (matches `---` anywhere, including mid-line / mid-word). The
`#para` resolver's `_strip_frontmatter` uses `index('\n---', 3)` (requires `---` at line
start). The two disagree on where a raw source's frontmatter ends, so a pathological raw
file could be partitioned differently by the privacy resolver than by the paragraph
slicer. No privacy impact (the privacy path is the stricter yaml-validated one, and dir
signals back it up), but it is an inconsistency that invites future bugs.
**Fix:** Unify on the line-anchored form (`'\n---'`) in both, or have `_resolve_para` reuse
`parse_frontmatter_str` to obtain the body.

### LW-04: Resolved passage includes the `<!-- page: N -->` marker comment line

**File:** `bin/audit-claims.sh:409-412` (`_resolve_page` slices `lines[start:end]` where
`start = marks[lo]`, the marker line itself)
**Issue:** For a `#p` locator, the extracted passage begins at the `<!-- page: N -->`
marker line, so the HTML comment is included verbatim in the passage text handed to the
verifier / written to the report. Cosmetic — slightly pollutes the cited passage with a
non-content marker. (Matches the documented `page:8..page:9` math otherwise.)
**Fix:** Start the slice at `marks[lo] + 1` to exclude the marker line, or strip
`PAGE_MARK_RE` matches from the joined passage before returning.

---

## Verification notes (what was actively tested, not just read)

- Adversarial `--emit-worklist` on a local_only page+source: stdout contained ONLY the
  redacted aggregate; grep for `SECRET`/slug/locator/`local-only` -> no match.
- `--allow-local` admits the passage (explicit opt-in works).
- Privacy resolver: 10 precedence/fail-closed cases incl. garbage enum, None fm,
  both-dir-signals, raw-fm-forces-local, dir-signal-without-raw-fm -> all fail-closed correct.
- Path guard: `../`, absolute, `sources/../../`, sibling-prefix -> all REJECTED.
- Page math: `#p8` -> 8..9 excl, `#p12-14` -> 12..15 excl, missing-lower -> None,
  last-page -> EOF — all match the documented D-05 contract.
- `#t` malformed timestamp -> caught by `resolve_locator`'s `except Exception` ->
  `insufficient-locator` (no crash).
- 33/33 phase-13 tests pass on HEAD.

_Reviewed: 2026-06-01_
_Reviewer: Claude (gsd-code-reviewer, adversarial FORCE stance)_
_Depth: deep_

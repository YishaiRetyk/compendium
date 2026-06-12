---
phase: 20-pdf-ingestion
reviewed: 2026-06-12T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - bin/pdf-extract.sh
  - bin/ingest.sh
  - bin/lint.sh
  - tests/phase-20/run.sh
  - tests/phase-20/lib.sh
  - tests/phase-20/test_pdf_extract_markers.sh
  - tests/phase-20/test_pdf_extraction_fields.sh
  - tests/phase-20/test_pdf_convention_doc.sh
  - tests/phase-20/test_pdf_epistemic_tiers.sh
  - tests/phase-20/test_ingest_asset_flag.sh
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: partially_resolved
resolved:
  fixed_in: c363426
  fixed: [CR-01, WR-01, WR-02, WR-04, WR-05]
  deferred: [WR-03, IN-01, IN-02, IN-03, IN-04]
  note: >-
    CR-01 (data loss) + the two real-bug warnings (WR-02 readability-after-write,
    WR-04 marker false-abort) fixed per human direction, plus WR-01/WR-05 which
    fell out of the same --asset restructure. CR-01 regression test added; phase-20
    suite 5/5. WR-03 (dpi numeric validation) and the four INFO items (jq re-parse,
    echo→printf, ls/SC2012, unused lib helper) deferred — low severity, no data/
    correctness risk. Run /gsd-code-review-fix 20 to address the remainder.
---

# Phase 20: Code Review Report

**Reviewed:** 2026-06-12T00:00:00Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the Phase 20 PDF-ingestion changes: the new `bin/pdf-extract.sh` (PDF→Markdown OCR glue over a local Ollama VLM), the `--asset` co-location flag added to `bin/ingest.sh`, the conditional PDF extraction-field check added to `bin/lint.sh`, and the five phase-20 test files.

Overall the new code is defensively written — file-based I/O to avoid argv limits, full-response validation before extracting `.response`, temp-file cleanup via trap, namespaced env vars, and pre-validation of `--asset` preconditions before any filesystem mutation. The shell-injection surface is genuinely small: all external-input values reach commands as quoted argv elements, never via `eval` or unquoted interpolation, and the model/DPI/prompt values are passed as `--arg`/argv so they cannot break out.

One BLOCKER stands out: the `--asset` flag has a silent data-loss path when the source file's derived name collides with the asset basename (`source.<ext>`), causing the asset to overwrite the just-copied source. The remaining findings are robustness gaps (missing numeric validation, `--force` inconsistency, a marker-count false-positive vector) and quality notes.

## Critical Issues

### CR-01: `--asset` silently overwrites the ingested source on a `source.<ext>` basename collision (data loss)

**File:** `bin/ingest.sh:303, 340, 353-356`
**Issue:** The collision guard at line 303 only rejects an asset whose basename is literally `source.md`. But a non-Markdown source is copied to `source.<ext>` (line 340), so any asset whose basename happens to be `source.<ext>` with the *same* extension collides with the source. The asset copy at line 354 then overwrites the source file with the asset's bytes. The scaffold output still prints `compute_hash` of the source (computed before? no — `HASH` is computed at line 425, AFTER the asset copy, so the printed hash is the *asset's* hash; either way the source content is lost). Reproduced: ingesting `mydoc.pdf` with `--asset source.pdf` yields a single `source.pdf` containing the asset's content — the source is gone, with no error.

```
$ bin/ingest.sh --slug collide --asset ./source.pdf ./mydoc.pdf
Co-located asset: sources/2026/2026-06/2026-06-12-collide/source.pdf
=== Source Scaffolded ===   # reports source.pdf, but file holds ASSET bytes
```

**Fix:** Guard against the *resolved* destination collision, not just the literal `source.md` basename. After `DEST_FILE` is derived, compare it to `ASSET_DEST`:
```bash
# After DEST_FILE is computed (line 340), before copying:
if [ -n "${ASSET_FILE}" ] && [ "${ASSET_DEST}" = "${DEST_FILE}" ]; then
    echo "ERROR: --asset basename '${ASSET_BASE}' collides with the ingested source destination (${DEST_FILE})" >&2
    exit 1
fi
```
Move this check into the pre-validation block (lines 297-312) once `DEST_FILE`/`EXT` are known, so it fires before any `mkdir`/`cp` runs.

## Warnings

### WR-01: `--asset` copy ignores `--force`, breaking the documented overwrite contract for read-only destinations

**File:** `bin/ingest.sh:342-346, 353-356`
**Issue:** The source copy correctly uses `cp -f` under `--force` (line 343) but the asset copy always uses plain `cp` (line 354). The usage text documents `--force` as "Overwrite files in an existing destination directory." A plain `cp` onto a read-only existing `ASSET_DEST` fails with EACCES even though the user passed `--force`, while the source copy in the same run would succeed — an inconsistent and surprising partial failure.
**Fix:** Mirror the source-copy branch:
```bash
if [ -n "${ASSET_FILE}" ]; then
    if [ "${FORCE:-0}" = "1" ]; then
        cp -f "${ASSET_FILE}" "${ASSET_DEST}"
    else
        cp "${ASSET_FILE}" "${ASSET_DEST}"
    fi
    echo "Co-located asset: ${ASSET_DEST}" >&2
fi
```

### WR-02: `--asset` validates existence but not readability (asymmetric with source-file check)

**File:** `bin/ingest.sh:297-301`
**Issue:** The source file is checked for both `-f` (line 236) and `-r` (line 241), but `--asset` is only checked for `-f` (line 298). An unreadable asset passes pre-validation, then `cp` fails *after* `source.md` has already been written — exactly the partial-bundle outcome the round-2 comment at lines 293-296 says the pre-validation block exists to prevent.
**Fix:** Add a readability check alongside the existence check:
```bash
if [ ! -r "${ASSET_FILE}" ]; then
    echo "ERROR: --asset file is not readable: ${ASSET_FILE}" >&2
    exit 1
fi
```

### WR-03: `--dpi` value is never validated as a positive integer

**File:** `bin/pdf-extract.sh:77, 179`
**Issue:** `DPI` (from `--dpi` or `PDF_EXTRACT_DPI`) is passed to `pdftoppm -r "$DPI"` without any numeric validation, unlike `PAGES` which is checked with `[[ "$PAGES" =~ ^[0-9]+$ ]]` (line 163). A non-numeric DPI (typo, empty string) makes `pdftoppm` print its usage banner and exit 0 *without rendering a PNG*; the script then fails downstream at the `PNG_COUNT -eq 1` check (line 183) with the misleading message "expected exactly 1 rendered PNG for page 1, found 0" rather than a clear "invalid DPI" diagnostic. No security impact (the value is a quoted argv element), but a confusing failure mode.
**Fix:** Validate after arg parse, near the other preflight checks:
```bash
[[ "$DPI" =~ ^[0-9]+$ ]] && [ "$DPI" -gt 0 ] || {
    echo "ERROR: --dpi must be a positive integer, got: '$DPI'" >&2
    exit 1
}
```

### WR-04: Marker-count sanity check can false-positive on model output containing a page-marker line

**File:** `bin/pdf-extract.sh:222, 230-234`
**Issue:** The per-page OCR text (`$TEXT`) is written verbatim under the marker (line 222). The final integrity check counts `grep -c '^<!-- page:'` across the whole file and aborts if it differs from `$PAGES` (lines 230-234). If a model OCRs a page whose content legitimately includes a line beginning `<!-- page:` (e.g. a document that itself documents this very marker convention, or any HTML comment of that shape), `MARKERS` exceeds `$PAGES` and the run aborts *after* doing all the expensive inference, discarding valid output. The OCR text is untrusted content and should not be conflated with the script-emitted control markers.
**Fix:** Emit a delimiter the model output cannot forge, or count only the markers the script itself wrote. Simplest robust option: track a counter in the loop and compare to it, instead of re-grepping mixed content:
```bash
# increment EMITTED in the loop after each printf, then:
if [ "$EMITTED" -ne "$PAGES" ]; then
    echo "ERROR: emitted $EMITTED markers != page count $PAGES" >&2; exit 1
fi
```
The grep re-scan adds no real integrity guarantee over an in-loop counter and introduces the false-positive.

### WR-05: `--asset` precondition for the `source.md` basename is too narrow given the `.markdown` normalization

**File:** `bin/ingest.sh:303, 334-338`
**Issue:** Related to CR-01 but distinct: a `.markdown` source is normalized to `source.md` (lines 334-338), and a `.md` source likewise lands as `source.md`. The guard at line 303 catches `--asset source.md` directly, but the underlying bug is that the guard checks the *asset* basename against a hardcoded string instead of against the *computed* `DEST_FILE`. Any change to the source-naming convention silently desyncs this guard. Even after CR-01's destination-equality fix, the hardcoded `source.md` literal should be removed to avoid two competing collision checks drifting apart.
**Fix:** Replace the literal `source.md` check at lines 303-306 with the single destination-equality guard from CR-01 (computed after `DEST_FILE` is known), eliminating the duplicated/partial logic.

## Info

### IN-01: `$RESP` re-parsed by `jq` four times per page

**File:** `bin/pdf-extract.sh:210-218`
**Issue:** Each page response is piped through `jq` up to four separate times (`has("error")`, `.error` extraction, `.response != null`, `.response`). Functionally correct, but it re-parses the (potentially large) JSON repeatedly. A single `jq` pass could validate-and-extract. Not a correctness issue; noted for maintainability.
**Fix (optional):** Extract once into a result and branch on it, e.g. `jq -r 'if has("error") then "ERR:"+.error elif .response==null then "NULL" else .response end'` then dispatch in shell.

### IN-02: `echo "$RESP"` is theoretically flag-sensitive

**File:** `bin/pdf-extract.sh:210, 211, 214, 218`
**Issue:** `echo "$RESP"` would mis-handle a value beginning with `-n`/`-e`/`-E` (treated as `echo` flags). Ollama `/api/generate` always returns a JSON object beginning with `{`, so this never triggers in practice. Use `printf '%s\n' "$RESP"` for robustness and to silence shellcheck SC2086-adjacent style lints.
**Fix:** Replace `echo "$RESP" |` with `printf '%s\n' "$RESP" |` at the four sites.

### IN-03: `ls | wc -l` and `ls` for glob expansion (SC2012 pattern)

**File:** `bin/pdf-extract.sh:182, 187`
**Issue:** Counting and selecting the rendered PNG via `ls "$TMP/page-$N"-*.png` parses `ls` output. `$TMP` comes from `mktemp -d` (no spaces/newlines) so this is safe in practice, but it is the classic SC2012 anti-pattern and may trip the CI shellcheck gate.
**Fix:** Use a glob array: `pngs=( "$TMP/page-$N"-*.png ); [ "${#pngs[@]}" -eq 1 ] && [ -f "${pngs[0]}" ]` then `PNG="${pngs[0]}"`.

### IN-04: `lib.sh` documents helpers as "dead code … intentionally omitted" — confirm no caller references them

**File:** `tests/phase-20/lib.sh:6-9`
**Issue:** The header notes that phase-15 helpers (`make_bare_repo`, `write_page`, etc.) are intentionally omitted, leaving only `assert_exit_code`. The five phase-20 test files do not appear to call `assert_exit_code` either (they use inline `grep`/exit checks). If unused, the single exported helper is itself dead code. Low priority; verify before trimming.
**Fix:** Either remove `assert_exit_code`/`export -f` if no test uses it, or keep it documented as a shared utility for future tests.

---

_Reviewed: 2026-06-12T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

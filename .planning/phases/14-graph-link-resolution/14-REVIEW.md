---
phase: 14-graph-link-resolution
reviewed: 2026-06-03T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - bin/lint.sh
  - tests/phase-09/test_lint_linkres.sh
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-06-03
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the Phase 14 link-resolution rework in `bin/lint.sh` (diff base `91d12e0..HEAD`,
commits `bafb5dd`, `9227863`, `a259dcb`) and its re-pointed test suite. The change re-points
the `linkres` category from a self-alias invariant to uniform piped-form enforcement
(`[[id|Title]]`), introduces the shared length-preserving `mask_markdown()` helper, a positional
`--fix` bare→piped rewriter, alias-free orphan resolution, and extends masking to the provenance
broken-ref scan.

The core mechanics are sound: the positional `--fix` correctly preserves frontmatter byte-for-byte
(verified empirically and by test T13), idempotency holds (T8), the length-preserving mask keeps
offsets aligned with the raw file for splices, and the alias-free orphan resolution behaves as
intended (T11). All 13 test cases pass.

However, the masking helper has **two correctness gaps in its stated contract** (unclosed fenced
code blocks and trailing-info-string closing fences leak content into the scan), and the masking
was applied **asymmetrically** — the orphan, linkres, and provenance scans were converted to
masked bodies, but the in-scope `gap` (knowledge-gap red-link) scan still runs over the *unmasked*
body, so a `[[...]]` inside a code fence is falsely surfaced as a red-link knowledge gap. No
critical/data-loss defects were found. No findings are blockers, but the masking inconsistencies
should be resolved because they undermine the phase's central "mask before scan" guarantee.

## Warnings

### WR-01: Knowledge-gap (`gap`) scan runs over UNMASKED body — code-fence links falsely flagged as red links

**File:** `bin/lint.sh:1620` (also `1648`)
**Issue:** Phase 14 deliberately converted the orphan scan from `WIKILINK_RE.findall(body)` to
`WIKILINK_RE.findall(mask_markdown(body))` (diff lines 108→113) and masked the special files, and
also masked the provenance scan (line 1114). But the `gap` block — which shares the same
`WIKILINK_RE` and the same resolution model — was left scanning the raw body:

```python
wikilinks = WIKILINK_RE.findall(body)          # line 1620 — UNMASKED
...
for lm in link_pattern.finditer(body):         # line 1648 — UNMASKED
```

Empirically confirmed: a `[[ghost-link]]` inside a fenced code block is reported as
`info gap red-link:ghost-link` even though linkres correctly masks it (zero linkres findings for
the same page). The prompt explicitly requires that masked-span links never be flagged; the gap
scan violates this. This produces false-positive knowledge gaps for any documentation page that
shows wikilink syntax inside code fences, inline code, or HTML comments — directly contradicting
the masking helper's stated purpose ("literal `[[id|Title]]` / `[[X]]` examples inside those spans
are NEVER flagged").
**Fix:** Mask the gap body before scanning, mirroring the orphan/linkres change:
```python
masked_body = mask_markdown(body)
wikilinks = WIKILINK_RE.findall(masked_body)
...
for lm in link_pattern.finditer(masked_body):   # also use masked_body here
    for (rs, re_end) in tldr_kf_ranges:          # ranges computed on raw body — recompute on masked
```
Note the TL;DR/Key-Facts ranges (`tldr_kf_ranges`, lines 1623–1629) are computed from the raw
body; if you mask the body for `finditer`, compute the ranges from the same masked string so the
`rs <= lm.start() < re_end` offset comparison stays aligned (mask is length-preserving, so headings
are not inside masked spans and offsets match either way — but use one consistent string).

### WR-02: `mask_markdown()` does not neutralise UNCLOSED fenced code blocks — documentation examples leak into the scan and `--fix`

**File:** `bin/lint.sh:406` (`_FENCE_RE`), consumed at `1963` and the `--fix` splice at `2026-2037`
**Issue:** `_FENCE_RE = r'(^|\n)(```|~~~)[^\n]*\n.*?\n\2[ \t]*(?=\n|$)'` requires a *closing* fence.
A fenced block left unterminated at EOF (valid CommonMark — the block extends to end of document)
is **not** masked. Confirmed empirically: a `[[Alpha]]` inside an unterminated ` ``` ` block is
flagged `error linkres: bare link [[Alpha]] ... use [[alpha|Alpha]]`, and with `--fix` the rewriter
would splice `[[alpha|Alpha]]` *inside what the author intended as a code block*. The helper's
docstring claims it "neutralises … fenced code blocks," so this is a contract gap, and the `--fix`
path makes it a content-mutation risk on malformed-but-recoverable source.
**Fix:** Allow the closing fence to be optional (extend to EOF when unterminated):
```python
_FENCE_RE = re.compile(r'(^|\n)(```|~~~)[^\n]*\n.*?(?:\n\2[ \t]*(?=\n|$)|\Z)', re.DOTALL)
```
Verify length-preservation and idempotency after the change (the `_blank` callback already keeps
length stable). Add a test fixture with an unterminated fence asserting zero linkres findings.

### WR-03: Closing fence with a trailing info string is not masked — content leaks

**File:** `bin/lint.sh:406` (`_FENCE_RE` close-fence segment `\2[ \t]*(?=\n|$)`)
**Issue:** The closing-fence segment only permits spaces/tabs after the backticks. A fence whose
closing line carries trailing text (e.g. ` ```ruby `) fails to match, so the whole block — and its
`[[...]]` examples — leaks into the scan. Confirmed: `"```\n[[Alpha]]\n```ruby\n"` does not mask
`[[Alpha]]`. While CommonMark forbids info strings on the *closing* fence, real-world markdown and
copy-paste accidents produce this, and the leak silently turns a code example into a linkres error
(and a `--fix` rewrite target).
**Fix:** This is largely subsumed by the WR-02 fix if you also tolerate a non-strict close. If you
keep a strict close, document the limitation in the `mask_markdown` docstring so the gap is a known
constraint rather than a silent surprise. Lower priority than WR-01/WR-02.

### WR-04: New provenance-scan masking (line 1114) shipped with no test coverage

**File:** `bin/lint.sh:1114`
**Issue:** Commit `a259dcb` added `prov_matches = PROV_RE.findall(mask_markdown(body))` so that
literal `[prov:...]` examples inside code fences / inline code are no longer mis-flagged as broken
references. This is a correct and desirable change, but the diff adds **no test** exercising it
(the test diff touches only `test_lint_linkres.sh`, `test_lint_require_version.sh`,
`test_lint_strict_dr_match.sh`, `test_lint_version.sh`). A future refactor of `mask_markdown` could
silently regress this behavior (and, conversely, the masking could over-suppress a *real* broken
`[prov:]` ref that happens to sit near a code span). Untested behavior on a security/integrity-
adjacent check (provenance resolution) is a maintainability risk.
**Fix:** Add a fixture page with (a) a literal `[prov:src-fake#sec:x]` inside a fenced code block
asserting it is NOT flagged, and (b) a real broken `[prov:src-missing#sec:x]` in prose asserting it
IS still flagged. This pins both directions of the masking behavior.

## Info

### IN-01: Redundant path-style check between `_classify_piped` and its caller

**File:** `bin/lint.sh:1951-1952` and `1971-1974`
**Issue:** `_classify_piped` already returns `('error', None)` for any target containing `/`
(line 1951-1952), and the caller then re-tests `if '/' in target:` (line 1971) to emit the
path-style-specific message. The duplicate condition is harmless but means the `/` rule lives in
two places; a future edit to one will not track the other.
**Fix:** Either have `_classify_piped` return a distinct verdict (e.g. `'error-path'`) the caller
dispatches on, or drop the `/` branch from `_classify_piped` and let the caller own it. Purely a
clarity/maintainability improvement.

### IN-02: CRLF files bypass frontmatter masking

**File:** `bin/lint.sh:409` (`_FM_RE = r'\A---\n.*?\n---\n'`)
**Issue:** `_FM_RE` (and the fence/inline regexes) assume `\n` line endings. A CRLF-encoded page's
frontmatter is not masked (its lines end `---\r\n`). The mask stays length-preserving, so the
`--fix` splice remains offset-safe and frontmatter bytes are not corrupted; the only exposure is if
frontmatter contained `[[...]]` or backticks (prohibited by CLAUDE.md §8, so practically unreachable).
Flagging for awareness, not as a defect.
**Fix:** If CRLF support is ever desired, normalize or make the regexes `\r?\n`-tolerant. Otherwise
note the `\n`-only assumption in the `mask_markdown` docstring.

### IN-03: `linkres_scan` silently skips pages with unparseable frontmatter

**File:** `bin/lint.sh:1930-1936`
**Issue:** The linkres worklist only appends pages where `fm is not None and body is not None`
(line 1931). A page whose YAML fails to parse is excluded from linkres entirely, so its body link
forms are never checked. This is defensible (the `yaml` category already flags the parse error as
an `error`, and you cannot reliably extract the body of a malformed page), but it means link-form
defects on a page can be masked by an unrelated frontmatter error until the YAML is fixed.
**Fix:** Acceptable as-is given the `yaml` error already gates CI. Optionally add a comment noting
that linkres deliberately defers to the `yaml` check for unparseable pages, so the skip is not read
as an oversight.

---

_Reviewed: 2026-06-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

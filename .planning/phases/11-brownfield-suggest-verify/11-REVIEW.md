---
phase: 11-brownfield-suggest-verify
reviewed: 2026-04-20T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - bin/brownfield.sh
  - bin/lib/brownfield_classify.py
  - bin/lib/brownfield_provenance.py
  - bin/lib/brownfield_walk.py
  - schema/brownfield/migrations/01-page-typing.sh
  - schema/brownfield/migrations/02-provenance-bootstrap.sh
  - schema/brownfield/migrations/03-cross-link-inference.sh
  - schema/brownfield/migrations/04-privacy-review.sh
  - tests/phase-11/lib.sh
  - tests/phase-11/run.sh
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-04-20T00:00:00Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 11 ships the brownfield `suggest` / `review-typing` / `verify` chain plus four canonical migration scripts. Architectural invariants are respected well:

- NO LLM/network calls anywhere in runtime paths (BRWN-16 upheld).
- Canonical scripts in `schema/brownfield/migrations/` are byte-frozen and the byte-copy test (`assert_canonical_scripts_byte_identical`) strips only `op_hash` header lines before comparison.
- Apply-class 01 and 02 mutate files via `write_roundtrip`; advisory-class 03 and 04 intentionally never import `write_roundtrip`. `04-privacy-review.sh` correctly errors on `--apply`.
- Portability: all SHA-256 hashing uses Python `hashlib` (no `sha256sum`).
- Review-typing's stdin pre-peek buffer cleanly distinguishes scripted input from immediate EOF and aborts with progress preserved (REVIEWS item 4).
- Root resolution in the four migration scripts correctly derives vault root from `${BASH_SOURCE[0]}`, not `$(pwd)`, and explicitly refuses to run from `schema/brownfield/migrations/`.

The findings below are all non-critical. The two highest-value fixes are the regex drift between `bin/brownfield.sh`'s suggest preview and the `bin/lib/brownfield_provenance.py` library used by `02-provenance-bootstrap.sh` (WR-01, WR-02) — those cause the dry-run preview in `provenance-bootstrap-report.yaml` to disagree with what 02 actually mutates on `--apply`.

## Warnings

### WR-01: `suggest` preview's TASK regex fails to match `- [ ]` / `- [x]` checklists

**File:** `bin/brownfield.sh:1102`
**Issue:** The suggest Python heredoc defines `TASK = re.compile(r'^- (\[[ x]\]|TODO:?|FIXME:?)\b', re.IGNORECASE)`. The trailing `\b` never matches after `]` followed by a space (non-word ↔ non-word boundary), so `- [ ] do thing` and `- [x] done` are NOT classified as tasks and therefore ARE included in `provenance-bootstrap-report.yaml` as eligible bullets. The library version in `bin/lib/brownfield_provenance.py:44` uses `(\s|$)` and also accepts uppercase `X`. When the user runs `02-provenance-bootstrap.sh --apply`, the library correctly excludes these checklist bullets, so the dry-run preview and the apply diverge.

Reproduction:
```
python3 -c "import re; r=re.compile(r'^- (\[[ x]\]|TODO:?|FIXME:?)\b', re.IGNORECASE); print(bool(r.match('- [ ] todo')))"
# False  -- suggest treats it as eligible
```

**Fix:** Delete the duplicated heredoc regexes in `bin/brownfield.sh` and import the canonical helpers from `brownfield_provenance` instead (which is already on `sys.path` via `BROWNFIELD_LIB_DIR`). That also removes WR-02 below.

```python
# bin/brownfield.sh suggest heredoc, replace lines 1100-1141 with:
from brownfield_provenance import is_eligible_claim_bullet, section_scan  # noqa: E402

# ... in the per-page loop:
eligible = section_scan(body or '', ['TL;DR', 'Key Facts'])
entry = {'path': rel, 'eligible_bullets': len(eligible), 'sample': [ln for _, ln in eligible[:3]]}
```

### WR-02: `suggest` preview's BULLET_TOP_LEVEL regex rejects tab-indented top-level bullets that 02 accepts

**File:** `bin/brownfield.sh:1105`
**Issue:** `BULLET_TOP_LEVEL = re.compile(r'^- (.+)$')` requires a single literal space after `-`, whereas `bin/lib/brownfield_provenance.py:39` uses `r'^-(?: |\t)(.+)$'` and the docstring explicitly documents `-\tclaim` as accepted. A vault page authored with `-\tclaim` would appear in `provenance-bootstrap-report.yaml` as ineligible (preview count low) but then get tagged with `[epistemic:: inferred]` on `--apply`. Preview/apply drift.

**Fix:** Same as WR-01 — replace the heredoc re-implementation with an import from `brownfield_provenance`. Both TASK and BULLET_TOP_LEVEL drift disappear with the single fix.

### WR-03: `suggest` re-run appends duplicate `## Cross-link candidates` / `## Privacy review` sections to `REPORT.md`

**File:** `bin/brownfield.sh:1273-1291`
**Issue:** The suggest subcommand opens `.brownfield/REPORT.md` in append mode (`'a'`) and writes `## Cross-link candidates` and `## Privacy review`. Every other suggest output is regenerated (YAMLs are opened `'w'`, byte-copies are overwritten). Running `bin/brownfield.sh suggest` twice produces a REPORT.md with two copies of each section; ten iterative runs produce ten copies. The documented workflow is iterative (`suggest` → edit decisions → `suggest` again to refresh), so duplication is the expected path, not a rare edge case.

**Fix:** Either idempotently truncate the REPORT.md from the first Phase-11 marker on each re-run, or rewrite the whole file from scratch by re-reading the bootstrap-produced prefix and re-appending. Minimal approach:

```python
with open(report_path, 'r', encoding='utf-8') as fh:
    existing = fh.read()
cutoff = existing.find('\n## Cross-link candidates\n')
if cutoff >= 0:
    existing = existing[:cutoff]
with open(report_path, 'w', encoding='utf-8') as fh:
    fh.write(existing)
    fh.write('\n## Cross-link candidates\n\n')
    # ... rest unchanged
```

### WR-04: `01-page-typing.sh` dereferences `candidates`/`decisions` without None-guard on empty YAML

**File:** `schema/brownfield/migrations/01-page-typing.sh:142,150`
**Issue:** `cid_to_pages = {c['cluster_id']: list(c['pages']) for c in (candidates.get('clusters') or [])}` assumes `candidates` is a dict. If a user (or a corrupted suggest run) leaves one of the paired YAMLs empty (valid YAML — parses as `None`), `yaml.load(fh)` returns `None`, and `candidates.get(...)` raises `AttributeError: 'NoneType' object has no attribute 'get'`. Same for `decisions.get('clusters')` one line below. The script exits with an uncaught traceback instead of a clean error message. The review-typing subcommand already handles this case (line 1521-1523 checks `if decisions is None`); 01 should do the same.

**Fix:**
```python
with open(decisions_path) as fh:
    decisions = yaml.load(fh) or {}
with open(candidates_path) as fh:
    candidates = yaml.load(fh) or {}
if not decisions.get('clusters') or not candidates.get('clusters'):
    sys.stderr.write(
        "ERROR: decisions or candidates YAML is empty — "
        "re-run `bin/brownfield.sh suggest` to regenerate.\n")
    sys.exit(1)
```

## Info

### IN-01: phone regex admits likely-false-positive matches

**File:** `bin/brownfield.sh:1226`
**Issue:** `PHONE_RE = r'\b(?:\+?1[-.\s]?)?\(?[2-9][0-9]{2}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b'` matches `200 300 4000` (three space-separated number groups that might be any row/column data) and for `(234) 567-8901` yields `234) 567-8901` as the match (the closing `)` leaks into the matched text because `\b` anchors at `2`, not `(`). Privacy findings are advisory-only so this is low-impact, but operators reviewing `privacy-findings.yaml` will see confusing `matched_text` values.

**Fix:** Either (a) require the leading paren to be part of the match via a non-optional group when a closing paren is present: `\(?[2-9][0-9]{2}\)?` → alternation `(?:\([2-9][0-9]{2}\)|[2-9][0-9]{2})`, or (b) leave as-is and document in the 04-privacy-review help text that matches are deliberately over-inclusive. Given advisory-only status, option (b) is arguably correct.

### IN-02: `classify_page` `inbound_count` parameter is declared and documented but never read

**File:** `bin/lib/brownfield_classify.py:35`
**Issue:** The parameter is explicitly noted as "reserved for Phase 11 01-page-typing.sh reuse; unused in Phase 10 scan". Phase 11 is now shipping but the caller in `bin/brownfield.sh` suggest (line 987) still ignores the return value's confidence for cluster-level agreement counting and computes `inbound_slug` separately. The dead parameter should either be removed or actually consumed — leaving it in creates a false affordance for future maintainers.

**Fix:** Either remove the parameter (and update the docstring), or wire it into a fifth-signal counter inside `classify_page` to match the five-signal `_LABEL_HINTS` table. Deferring either direction to a future cleanup is reasonable.

### IN-03: `existing_link` check in suggest cross-link is alias-blind

**File:** `bin/brownfield.sh:1204`
**Issue:** `existing_link = ('[[' + title + ']]') in body` only detects the exact-title form. If a user already wrote `[[Alternate Name]]` where `Alternate Name` is in the target page's `aliases` list, the `target_already_linked_from_source` flag is `False`, so the candidate re-surfaces and the operator may waste review time. This is advisory, so operator clarity only.

**Fix:** Check against both TITLE_MAP and ALIAS_MAP at the resolution point, or normalize to the target page ID and match on that.

### IN-04: Repeated regex compilation inside suggest cross-link inner loop

**File:** `bin/brownfield.sh:1198`
**Issue:** `pattern = re.compile(r'\b' + re.escape(title) + r'\b')` is recompiled for every (page, line, title) tuple. For a vault with 500 pages × 50 lines × 100 titles, that's 2.5M regex compiles per suggest run. Not a correctness issue; explicitly out of v1 scope per the review guidelines, but cheap to fix (hoist the compile out of the loops into a precomputed `{title: pattern}` dict before the page walk).

### IN-05: Signal trace string format diverges between `classify_page` and `cluster_by_signals`

**File:** `bin/lib/brownfield_classify.py:124-137` vs `202-293`
**Issue:** `classify_page`'s `signal_trace` uses `frontmatter=none, filename=none, h1=entity-like, links=outbound-heavy` (label slugs mixed with "h1=" prefix), while `cluster_by_signals` consumes a dict keyed `{frontmatter, filename, heading, inbound, links}` (shape slugs — `pascal`, `kebab`, `entity-like`, `inbound-heavy`, `outbound-light`). The two representations cannot be mechanically translated without external knowledge (the slugs overlap but mean different things). A future maintainer trying to reuse `classify_page`'s trace as input to `cluster_is_autoapproveable` would produce garbage without realizing it. The long docstring on lines 157-168 calls this out, but the fix is to either unify the two shapes or rename the `classify_page` trace key `h1` → `heading` so at least the keys align.

**Fix:** Rename the `h1=` prefix in the trace to `heading=` (line 128, 130) so readers naturally associate it with the cluster-level `signals.heading` key. The value-shape divergence (label-slugs vs shape-slugs) is intentional per the module docstring and can stay.

---

_Reviewed: 2026-04-20T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

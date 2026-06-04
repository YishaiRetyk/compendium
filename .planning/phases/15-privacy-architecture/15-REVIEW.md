---
phase: 15-privacy-architecture
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - bin/audit-claims.sh
  - bin/brownfield.sh
  - bin/check-neutrality.sh
  - bin/check-privacy.sh
  - bin/check-sources-cloud-safe.sh
  - bin/ingest.sh
  - bin/init-wizard.sh
  - bin/lib/privacy_resolve.py
  - bin/lint.sh
  - bin/migrate-privacy-dirs.sh
  - bin/release.sh
  - bin/search.sh
  - bin/validate-op.sh
  - .claude/settings.cloud.json
  - .github/workflows/lint.yml
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the Phase 15 privacy-architecture rewrite that moves from a per-page
`privacy` frontmatter field to an asymmetric two-directory model (`wiki-cloud/`
+ `wiki-local/`). The privacy/security core is generally sound: `check-privacy.sh`
correctly detects `wiki-local/` path leaks into public surfaces, `check-sources-cloud-safe.sh`
is genuinely fail-closed (verified against a `privacy: local_only` raw-source fixture),
`bin/lib/privacy_resolve.py` collapses the old ladder into a structural predicate that
withholds correctly when EITHER the claim page OR a contributing source-summary lives
under `wiki-local/`, `audit-claims.sh` partitions egress at a single chokepoint with the
locality-is-a-flag contract intact, `lint.sh` adds a working `cloud->local` cross-tier
link guard (severity `error`), `search.sh` is scoped to `wiki-cloud` only, and
`release.sh` structurally excludes `wiki-local/` from its allowlist. The `.claude/settings.cloud.json`
deny-profile correctly blocks `Read(./wiki-local/**)`.

The dominant finding is a BLOCKER: `bin/validate-op.sh` was NOT updated for the
field removal and now hard-fails on EVERY migrated page (all 55 wiki-cloud pages
have zero `privacy` fields, yet the validator still requires `privacy` as a base
field). Since AGENTS.md §9 mandates running this validator before applying any
UPDATE/MERGE/SUPERSEDE/ARCHIVE operation, the entire structured-operations layer
is broken. Remaining findings are quality/consistency defects: `init-wizard.sh`
still emits a `privacy:` field that no other page carries, the `privacy_resolve.py`
predicate is case-sensitive (latent fail-open on case-insensitive filesystems),
`release.sh`'s post-migration `privacy: local_only` sweep is now a dead no-op, and
several smaller robustness gaps.

## Critical Issues

### CR-01: validate-op.sh hard-fails on every page — requires the removed `privacy` field

**File:** `bin/validate-op.sh:67-93` (and `:144-197`)
**Issue:** Phase 15 stripped the `privacy` frontmatter field from all wiki pages
(verified: 55/55 `wiki-cloud/*.md` pages have NO `privacy:` field). But
`validate_frontmatter()` still lists `privacy` in its hard-required base-field set
and rejects the page if absent:

```
required = ['id','title','type','status','summary','created_at','updated_at',
            'sources','epistemic_status','tags','domains','privacy']
```

The separate `check_privacy()` python block (lines 144-197) ALSO hard-fails with
`FAIL: No privacy field in frontmatter`. Confirmed by running the validator against
a real migrated page:

```
[2/5] Frontmatter valid         FAIL
FAIL: Missing required fields: ['privacy']
=== RESULT: FAIL ===   (exit 1)
```

AGENTS.md §9 ("Executor Model" / "Deterministic Enforcement") mandates: *"The LLM
MUST run `bin/validate-op.sh` before applying any operation. ... If the validator
returns FAIL, the operation MUST NOT be applied."* Because the validator now FAILs
unconditionally, every UPDATE / MERGE / SUPERSEDE / ARCHIVE is blocked — the core
mutation vocabulary is non-functional, while `lint.sh` (correctly updated) no longer
expects the field. This is a fail-CLOSED breakage (operations are blocked, not
silently leaked), but it is a complete functional regression of the operations layer.

**Fix:** Remove `'privacy'` from the required base-field list, drop the
`valid_privacy` enum check in `validate_frontmatter`, and replace the entire
`check_privacy()` function with the structural rule. The privacy invariant is now
the directory tier, so Check 4 should derive privacy from the page path (under
`wiki-local/` vs `wiki-cloud/`) and enforce that a `wiki-cloud/` target does not
cite a `wiki-local/`-only source-summary, e.g.:

```python
# Check 4 (re-keyed): structural tier, not a frontmatter field.
import os
page_is_local = os.path.normpath(sys.argv[1]).startswith('wiki-local' + os.sep) \
    or '/wiki-local/' in '/' + sys.argv[1].replace('\\', '/')
# A cloud-tier target whose sources live only under wiki-local/sources/ is a leak.
# (reuse bin/lib/privacy_resolve.py: resolve_source_privacy on each source summary path)
```

Mirror `lint.sh`'s already-correct base-field set and reuse
`bin/lib/privacy_resolve.py` rather than re-deriving the predicate inline.

## Warnings

### WR-01: init-wizard.sh emits a `privacy:` field that the migrated schema no longer uses

**File:** `bin/init-wizard.sh:717`
**Issue:** The decision-record renderer hard-codes `privacy: cloud_safe` into the
frontmatter of the freshly generated `dr-<TODAY>-initial-setup.md`:

```
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
```

Phase 15 removed `privacy` from base fields and stripped it from every existing
page (0/55 wiki-cloud pages carry it). A wizard run on a migrated repo would
therefore produce the SINGLE page in the wiki carrying a `privacy` field —
inconsistent with the new structural model and confusing to future maintainers
and any tooling that now treats the field as removed. The wizard still prompts for
`default_privacy` (lines 322-324, 487-489) and substitutes `{{DEFAULT_PRIVACY}}`
into the template, but the field has no remaining meaning under the directory-tier model.

**Fix:** Remove the `privacy: cloud_safe` line from the `render_decision_record()`
frontmatter block. Decision records are inherently cloud-safe by living under
`wiki-cloud/decisions/`. Reassess whether the `default_privacy` prompt and the
`{{DEFAULT_PRIVACY}}` template token should be removed or repurposed to choose the
default *directory tier* for new pages rather than a frontmatter value.

### WR-02: privacy_resolve._is_local is case-sensitive — latent fail-OPEN on case-insensitive filesystems

**File:** `bin/lib/privacy_resolve.py:36-45`
**Issue:** `_WIKI_LOCAL_PREFIX = 'wiki-local/'` is matched case-sensitively. On a
case-insensitive filesystem (macOS default, Windows), a directory physically named
`Wiki-Local/` or `WIKI-LOCAL/` is the same directory but the predicate returns
`False`, classifying genuinely local content as `cloud_safe` (fail-OPEN — the
dangerous direction). Verified:

```
'wiki-local/x'  -> True
'WIKI-LOCAL/x'  -> False   # fail-open
'Wiki-Local/x'  -> False   # fail-open
```

In current practice the audit derives paths from the literal `'wiki-local'` walk
constant so casing is normalized upstream, which is why this is a WARNING and not a
BLOCKER. But the module's docstring advertises it as "the SINGLE structural predicate"
for FAITH-04, so it should be self-defending and not rely on every caller pre-lowercasing.

**Fix:** Normalize case in the predicate:

```python
def _is_local(path):
    if not path:
        return False
    p = str(path).replace('\\', '/').lstrip('./').lower()
    prefix = _WIKI_LOCAL_PREFIX.lower()
    return p.startswith(prefix) or ('/' + prefix) in ('/' + p)
```

Also normalize backslashes (Windows separators) so `wiki-local\x.md` is caught.

### WR-03: `lstrip('./')` is a character-class strip, not a prefix strip

**File:** `bin/lib/privacy_resolve.py:44`
**Issue:** `p = str(path).lstrip('./')` removes ALL leading `.` and `/` characters
as a set, not the literal prefix `./`. A path like `...wiki-local/x.md` or
`.wiki-local/x.md` is mangled into `wiki-local/x.md`/`wiki-local/x.md` and
over-flagged as local. Verified `.wiki-local/x.md -> True`. This direction is
fail-CLOSED (harmless over-withholding), so it is not a security bug — but it is
incorrect string handling that could surprise a future maintainer and produce
spurious `skipped-privacy` verdicts. The secondary substring check
(`('/' + _WIKI_LOCAL_PREFIX) in ('/' + p)`) is what actually saves the genuinely
dangerous cases, masking the sloppiness.

**Fix:** Strip the literal prefix explicitly rather than a char class:

```python
p = str(path).replace('\\', '/')
if p.startswith('./'):
    p = p[2:]
p = p.lstrip('/')
```

### WR-04: release.sh `privacy: local_only` sweep is now a dead no-op

**File:** `bin/release.sh:157-163`
**Issue:** The belt-and-suspenders grep for `^privacy:[[:space:]]*local_only...`
can never match because Phase 15 stripped the `privacy` field from every page. The
comment still frames it as the privacy guard ("Programmatic sweep ... belt-and-suspenders").
The actual leak surface — `wiki-local/` content — is excluded structurally (it is
absent from `ALLOWLIST`), which is correct, but the sweep gives a false sense of an
active content check while doing nothing. A future maintainer adding a `wiki-local/`
glob to the allowlist by mistake would NOT be caught by this sweep.

**Fix:** Replace the dead frontmatter sweep with a structural guard that hard-fails
if any staged path contains a `wiki-local/` component (reuse `bin/check-privacy.sh`
logic, or run `bash bin/check-privacy.sh --root .` inside the staged dir alongside
the existing `check-neutrality.sh` preflight). At minimum, update the comment so it
does not claim active privacy coverage it no longer provides.

## Info

### IN-01: validate-op.sh `valid_types` omits `decision`

**File:** `bin/validate-op.sh:75`
**Issue:** `valid_types = {'entity','concept','source','comparison','overview'}`
excludes `decision`, but AGENTS.md §4.6 defines `type: decision` as a first-class
page type. Any attempt to SUPERSEDE/ARCHIVE a decision record (e.g., a corrected
decision) fails frontmatter validation with "Invalid type 'decision'". Pre-existing,
but worth fixing alongside CR-01 since the same `validate_frontmatter` block is being
touched.
**Fix:** Add `'decision'` to `valid_types`.

### IN-02: audit-claims.sh privacy partition relies on read-ordering, not defense-in-depth

**File:** `bin/audit-claims.sh:756-765`
**Issue:** When a claim cites a `source_id` absent from `source_registry`,
`summary_path = source_summary_path.get(sid, '')` is empty, and
`resolve_effective_claim_privacy(..., '')` returns `cloud_safe` (verified).
This would be fail-OPEN, but it is currently unreachable because `read_raw_source()`
returns `'no-registry'` and the loop `continue`s to an `insufficient-locator` finding
BEFORE the chokepoint is reached. The safety depends on that ordering rather than the
predicate itself failing closed on missing metadata.
**Fix:** Make the predicate fail-closed on an empty/None `source_summary_path` when a
`source_id` was supplied (treat unknown provenance as `local_only`), so a future
reordering of the audit loop cannot open a leak.

### IN-03: search.sh fulltext `grep -v` uses paths as regex patterns

**File:** `bin/search.sh:90-92`
**Issue:** `grep -v "$WIKI_INDEX"` and `grep -v "$WIKI_DIR/log.md"` pass
`wiki-cloud/index.md` and `wiki-cloud/log.md` as regex patterns; the `.` matches any
character. Harmless in practice here (no path collides), but it is technically a loose
filter that could over-exclude a hypothetical `wiki-cloudXindex.md`.
**Fix:** Use `grep -vF` (fixed-string) for path exclusions, or anchor the patterns.

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

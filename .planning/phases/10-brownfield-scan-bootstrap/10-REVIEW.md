---
phase: 10-brownfield-scan-bootstrap
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - bin/brownfield.sh
  - bin/ingest.sh
  - bin/lib/brownfield_classify.py
  - bin/lib/brownfield_yaml.py
  - bin/lint.sh
  - AGENTS.md
  - CLAUDE.md
  - docs/quickstart.md
  - docs/reference/brownfield.md
  - .gitattributes
  - .gitignore
  - schema/AGENTS.template.md
  - schema/fixtures/canonical-AGENTS.md
  - tests/phase-07/test_reference_stubs.sh
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-04-17T00:00:00Z
**Depth:** standard
**Files Reviewed:** 15 (note: `bin/lint.sh` reviewed via diff scope only — full file is pre-Phase-10 code)
**Status:** issues_found

## Summary

Phase 10 ships `bin/brownfield.sh` (scan + bootstrap subcommands) plus the `bootstrap_stage` / `bootstrap_date` sentinel wiring across AGENTS.md, `bin/ingest.sh`, and `bin/lint.sh`. The implementation is careful and well-commented: the D-02 typed-merge policy is correctly encoded in `brownfield_yaml.py`, the dry-run default is strict, atomic writes via tmpfile+rename are used for vault page mutations, and the fail-closed privacy default is preserved. Tests under `tests/phase-10/` are unusually thorough (27+ test files, full fixture set with LF-pinning and a CRLF edge case).

No Critical issues were identified — there are no security vulnerabilities, no data-loss paths, and no privacy regressions. The merge/skip policy is conservative and well-guarded by both a PyYAML pre-flight parse and a ruamel round-trip parse.

However, three Warning-level correctness issues exist, most notably a bug in the orphan-raw-sources walk that will produce false positives on every re-run of `bootstrap --apply` (violating the Phase 10 idempotency contract documented in `docs/reference/brownfield.md` § Idempotency). Five Info-level improvements are also noted (documentation polish, code duplication between scan and bootstrap Python blocks, a subtle date-TZ inconsistency, and a minor Markdown-table syntax risk in the new AGENTS.md row).

## Warnings

### WR-01: Orphan-raw-sources walk misses already-bootstrapped source summaries

**File:** `bin/brownfield.sh:366-400`
**Issue:** The `referenced_source_paths` set that drives orphan-source detection is built only from `pending_writes`, but pages already carrying `bootstrap_stage: bootstrapped` are skipped at line 324 into `already_bootstrapped` and never enter `pending_writes`. Consequence: on the second (and every subsequent) `bootstrap --apply` run, any `wiki/sources/*.md` summary whose page was already bootstrapped will NOT contribute its `path:` field to `referenced_source_paths` — so the raw source file it points at will be incorrectly reported as an orphan in REPORT.md's "Needs human judgment" section. This directly contradicts the idempotency contract: `docs/reference/brownfield.md` § Idempotency says "Running `bootstrap --apply` twice in a row produces zero-byte diff on the second run" — technically the vault files are unchanged, but REPORT.md will flip a page from clean to "needs judgment" purely as a function of re-running, which is a user-facing idempotency regression.

**Fix:** Collect source-summary `path:` references from ALL parsed source-summary pages, not just pending_writes. Add a second pass immediately before the orphan walk:

```python
# Also collect path: references from pages that were skipped for idempotency
# (already bootstrapped on a prior run). Without this, their raw sources
# appear as orphans on every subsequent run. See docs/reference/brownfield.md
# § Idempotency.
for dirpath, dirnames, filenames in os.walk(ROOT, followlinks=False):
    # ... mirror the exclusion logic above, OR better: capture this set
    # during the initial walk before the `already_bootstrapped` continue.
```

The cleanest refactor is to split the initial walk into two phases: (1) parse + classify every markdown page (no skip), collecting source-summary paths regardless of bootstrap_stage; (2) filter to pending_writes only for the merge/write step. This preserves the skip optimization for writes but fixes orphan detection.

### WR-02: Pages with `bootstrap_stage: raw` or `verified` are re-written on every run (not idempotent)

**File:** `bin/brownfield.sh:324`
**Issue:** The idempotency skip is narrow: `if fm is not None and fm.get('bootstrap_stage') == 'bootstrapped'`. The `VALID_ENUMS['bootstrap_stage']` set in `brownfield_yaml.py:68` includes three values: `raw`, `bootstrapped`, `verified`. AGENTS.md §5 (line 302) defines `raw` as "Reserved for future import workflows" and `verified` as post-Phase-11 state. But a page carrying either of those values will (a) fail the line-324 skip check, (b) pass through `merge_sentinels` where `bootstrap_stage` is a Class B schema-authoritative field whose existing value is PRESERVED (brownfield_yaml.py:372-385), and (c) enter `pending_writes` where it will be re-written on every `--apply` invocation — producing an unnecessary disk write, updating `updated_at` semantics that aren't present but could be added later, and potentially churning git history.

The page will never "become" `bootstrapped` because Class B is never overwritten. So the page is stuck: it goes through the merge path every run, and never gets skipped.

**Fix:** Broaden the idempotency skip to recognize any non-empty valid `bootstrap_stage` value, OR document that `raw`/`verified` pages are expected to be re-written (which seems wrong given the cost). Prefer:

```python
# D-10 per-file idempotency: skip pages already carrying any bootstrap_stage
# sentinel — we've already set scaffolding, and Class B won't overwrite.
if fm is not None and fm.get('bootstrap_stage') in {'raw', 'bootstrapped', 'verified'}:
    already_bootstrapped += 1
    continue
```

### WR-03: AGENTS.md table cell for `bootstrap_stage` uses unescaped `|` characters

**File:** `AGENTS.md:302` (mirrored in `CLAUDE.md:302`, `schema/AGENTS.template.md:304`, `schema/fixtures/canonical-AGENTS.md:304`)
**Issue:** The cell reads ``Values: `raw | bootstrapped | verified`.`` The `|` characters are inside a backtick code span. GitHub Flavored Markdown (GFM) follows CommonMark and treats `|` inside an inline code span as literal — but Obsidian's live-preview and several non-GFM Markdown renderers historically do NOT strip trailing pipes from code spans inside table cells, causing the row to be mis-parsed as having extra columns. Given that this vault targets Obsidian as the primary human UI (AGENTS.md §15 Tooling and Integrations), this is a real risk.

Also, the same row references `§11.5 Brownfield Workflow (populated in Phase 11)`, but AGENTS.md:1171 currently defines `### 11.5 Release Workflow (Orphan-Branch Publish)`. Section 11.5 will not become "Brownfield Workflow" without a section renumbering that the current diff does not perform — so this forward-reference points the reader at the wrong content.

**Fix:** Two changes, both in all four mirrored files (AGENTS.md, CLAUDE.md, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md):

```diff
-| `bootstrap_stage` | enum | Brownfield onboarding sentinel. Values: `raw | bootstrapped | verified`. Page-level marker ... See `§11.5 Brownfield Workflow` (populated in Phase 11). |
+| `bootstrap_stage` | enum | Brownfield onboarding sentinel. One of `raw`, `bootstrapped`, `verified`. Page-level marker ... See `§11.6 Brownfield Workflow` (populated in Phase 11; current §11.5 is Release Workflow). |
```

Verify with `tests/phase-10/test_agents_section_5_bootstrap_stage.sh` and the canonical-AGENTS parity test.

## Info

### IN-01: Code duplication between `scan` and `bootstrap` Python blocks

**File:** `bin/brownfield.sh:193-246` (bootstrap) and `bin/brownfield.sh:723-797` (scan)
**Issue:** `_translate_pattern_to_regex`, `_load_brownfield_ignore` / `load_brownfield_ignore`, and `_any_match` are duplicated almost verbatim between the two embedded Python heredocs. The bootstrap version is a near-subset of the scan version (minor differences: scan has an extra redundant `elif c in r'.+()|{}[]^$\\':` branch on line 760 that is unreachable because the generic `else: re.escape(c)` would handle those characters). The duplication is tolerable because each heredoc runs in a fresh python3 subprocess, but it increases drift risk if `.brownfield-ignore` grammar is ever extended.
**Fix:** Move `_translate_pattern_to_regex`, `_load_brownfield_ignore`, and `_any_match` into `bin/lib/brownfield_ignore.py` (new module), and import from both heredocs via `sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])` (already done for `brownfield_classify` and `brownfield_yaml`). Deferrable — not urgent.

### IN-02: `_date.today()` uses local time; `bootstrap_date` is written in UTC

**File:** `bin/lint.sh:1655`
**Issue:** The brownfield-staleness check computes `today_d = _date.today()` (local time) but `bootstrap_date` is written by `bin/brownfield.sh:115-117` using UTC (`date -u '+%Y-%m-%d'`). For users with timezone offsets > 0, a bootstrap run near local midnight can produce a `bootstrap_date` that is a calendar day ahead of `_date.today()`, yielding negative `age_days` on the same day. The `> 30` comparison is unaffected (negative is never > 30), but mixing UTC and local-time date policies in the same codebase violates AGENTS.md §3 ("All dates use ISO 8601 format ... UTC is intentional for deterministic directory paths").
**Fix:**

```python
from datetime import date as _date, datetime as _dt, timezone as _tz
today_d = _dt.now(_tz.utc).date()
```

Consistent with the UTC policy used everywhere else in this repo.

### IN-03: BRWN-10 strip path assumes DEST_FILE is under $(pwd)

**File:** `bin/ingest.sh:325`
**Issue:** `BF_REL_PATH="${DEST_FILE#"$(pwd)/"}"` strips only the current working directory prefix. If a user runs `bin/ingest.sh` from a subdirectory, `DEST_FILE` is computed from the same `sources/YYYY/...` relative prefix — but only `pwd` is stripped. The result printed in the stderr note at line 374 (`Note: stripped ${BF_FIELD}=... from ${BF_REL_PATH} ...`) will be the full relative path when invoked from the repo root, which is what tests expect. Harmless today but brittle: any change to the invocation location will shift the formatting of the note.
**Fix:** Use `os.path.relpath(DEST_FILE, repo_root)` computed from the same git-root detection already done in brownfield.sh, or simply use `DEST_FILE` directly (the message is informational).

### IN-04: Tab-detection heuristic is fragile

**File:** `bin/brownfield.sh:308`
**Issue:** `'\\t' in repr(msg).lower() or 'tab' in msg.lower()` — the `'tab' in msg.lower()` branch will match any error message containing the substring "tab" (e.g., "unexpected character in table context"). This could surface the "replace tab indentation with spaces" suggestion for a YAML error that has nothing to do with tabs. Low impact (wrong suggestion in an already-failing case) but the logic is worth tightening.
**Fix:** Rely on the `'\\t' in repr(msg)` branch alone, or constrain the string check to phrases like `'tab character'` / `'found character \'\\t\''` that PyYAML actually emits.

### IN-05: Skeleton writes (`wiki/index.md`, `wiki/log.md`) are non-atomic

**File:** `bin/brownfield.sh:578-580`
**Issue:** Vault page writes use `tempfile.mkstemp` + `os.replace` for atomicity (brownfield_yaml.py:438-451), but the skeleton-creation path for `wiki/index.md` and `wiki/log.md` uses a direct `open('w')` + `fh.write()`. A crash mid-write leaves a partially-written skeleton file. Low impact because the content is a one-liner, the files are new, and rollback is a `git reset --hard` per the documented recipe.
**Fix:** Factor out the atomic-write helper from `write_roundtrip` or inline the tmpfile+rename pattern here for consistency.

---

## Not Findings (Checked and Clear)

- **Security:** No command injection, path traversal, eval, insecure deserialization, hardcoded secrets, or unsafe crypto usage. The ingest.sh python3 heredoc passes filenames via `sys.argv`, not shell interpolation. YAML parsing uses `safe_load` on the pre-flight and ruamel round-trip on the authoritative parse.
- **Privacy:** The D-14 sentinel set correctly defaults `privacy: local_only` (brownfield_yaml.py:309), preserving the fail-closed rule from AGENTS.md §13.
- **Atomicity (core path):** `write_roundtrip` uses tmpfile + `os.replace` inside the target directory — correct for atomic replacement on same-filesystem writes.
- **Idempotency (for the `bootstrapped` case):** Verified via `tests/phase-10/test_brownfield_bootstrap_idempotent.sh` — pages with `bootstrap_stage: bootstrapped` are skipped at brownfield.sh:324. (See WR-02 for the `raw`/`verified` gap.)
- **Class A / Class B merge semantics:** Correctly implemented in `brownfield_yaml.py:354-391`. Class A preserves non-empty existing values + injects when empty; Class B never overwrites + validates against VALID_ENUMS with a non-fatal warning.
- **D-15 source-summary hashing:** Correctly resolves `path:` relative to the detected repo root (brownfield.sh:123-131), not the scan root — matches the documented Codex fix #7.
- **AGENTS.md ↔ CLAUDE.md sync:** Byte-identical, verified via `diff` (tests/phase-10/test_claude_sync_byte_equal.sh covers this).
- **LF-pinning of fixtures:** `.gitattributes:12` correctly exempts the CRLF fixture from the `*.md text eol=lf` rule via `-text`, preserving literal `\r\n` bytes for the CRLF-to-LF normalization test.
- **Lint CI downgrade scope (I-1):** BRWN-08 downgrade is correctly gated on `CI_MODE` (bin/lint.sh _bf_downgrade inside the `if CI_MODE:` block), not applied to text-mode lint — matches the documented I-1 scope in brownfield.md:150.

---

_Reviewed: 2026-04-17T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

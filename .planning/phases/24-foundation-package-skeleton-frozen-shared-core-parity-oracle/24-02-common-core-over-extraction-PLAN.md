---
phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
plan: 02
type: execute
wave: 2
depends_on: [01]
files_modified:
  - src/compendium/common/__init__.py
  - src/compendium/common/privacy.py
  - src/compendium/common/yaml_rt.py
  - src/compendium/common/walk.py
  - src/compendium/common/classify.py
  - src/compendium/common/provenance.py
  - src/compendium/common/page.py
  - tests/test_common_extraction.py
  - docs/reference/common-api-inventory.md
autonomous: true
requirements: [PKG-02]
user_setup: []

must_haves:
  decisions:
    - "D-08: the freeze covers all shared surfaces (common/ + pyproject.toml + shared test seam)"
    - "D-18: the net-new pytest unit layer (TEST-06) exists for localization, grown per cluster"
  truths:
    - "compendium.common is importable as a single source of truth for shared logic"
    - "make_yaml round-trips a known frontmatter block BYTE-EXACTLY against a committed fixture (the canonicalization chokepoint is preserved)"
    - "common/privacy.py is a verbatim lift of bin/lib/privacy_resolve.py (the fail-closed wiki-local/ predicate is unchanged)"
    - "common/page.py hosts ONE copy of parse_frontmatter + PROV_RE + EPISTEMIC_INLINE_RE + WIKILINK regexes (the lint<->audit-claims byte-copy is retired in common/)"
    - "audit-claims.sh's inline primitives are PROVEN byte-identical to lint.sh's BEFORE the single frozen copy is extracted — a pre-existing divergence cannot be silently unified (addresses REVIEWS LOW/MEDIUM 'Plan 02 precondition')"
    - "a consumer/API inventory documents every shared-looking duplicate (validate-op, check-neutrality, brownfield privacy/frontmatter logic) and which are intentionally distinct, so 'common complete' is demonstrated (addresses REVIEWS MEDIUM 'common completeness')"
    - "bin/lib/*.py is NOT deleted (the bash heredocs still import it in Phase 24 — lift, never move)"
  artifacts:
    - path: "src/compendium/common/yaml_rt.py"
      provides: "make_yaml byte-exact chokepoint + frontmatter round-trip (verbatim lift of brownfield_yaml.py)"
      contains: "def make_yaml"
    - path: "src/compendium/common/privacy.py"
      provides: "resolve_source_privacy + resolve_effective_claim_privacy + fail-closed _is_local (verbatim lift)"
      contains: "def resolve_effective_claim_privacy"
    - path: "src/compendium/common/page.py"
      provides: "parse_frontmatter + parse_frontmatter_str + PROV_RE + EPISTEMIC_INLINE_RE + WIKILINK regexes + mask_markdown + EXCLUDE sets (new extraction from heredocs)"
      contains: "def parse_frontmatter"
    - path: "docs/reference/common-api-inventory.md"
      provides: "Consumer/API inventory: every shared-looking duplicate + intentional-difference notes (REVIEWS MEDIUM)"
    - path: "tests/test_common_extraction.py"
      provides: "PKG-02 byte-identity + make_yaml round-trip + the audit-claims≡lint.sh precondition (TEST-06 seed)"
  key_links:
    - from: "src/compendium/common/__init__.py"
      to: "the 6 common/ modules"
      via: "re-export of stable public names"
      pattern: "from \\.(yaml_rt|privacy|walk|classify|provenance|page) import"
    - from: "tests/test_common_extraction.py"
      to: "compendium.common.yaml_rt.make_yaml"
      via: "round-trip byte-equality assertion against a committed fixture"
      pattern: "make_yaml"
---

<objective>
Over-extract-to-completion the shared `common/` core: a 1:1 verbatim lift of the 5 `bin/lib/*.py` modules into descriptively-named `common/` modules, PLUS the genuinely-new `common/page.py` that extracts the wiki-page primitives currently duplicated inline in the `lint.sh` and `audit-claims.sh` heredocs (the byte-copy PKG-02 retires) — with a PRECONDITION that proves audit-claims.sh's copy is byte-identical to lint.sh's before unifying them. Seed the TEST-06 unit layer with a `make_yaml` byte-exact round-trip test, and produce a consumer/API inventory demonstrating the core is complete.

Purpose: `common/` is the frozen single-source-of-truth surface (D-08/SC#2). Phase-23 plans READ it (their ports import `from compendium.common.*`) and never WRITE it. The whole point of over-extracting now is so the migration wave never touches a shared file.

Output: `src/compendium/common/` (6 modules + re-export `__init__.py`), `tests/test_common_extraction.py`, `docs/reference/common-api-inventory.md`.

CRITICAL: This is a COPY-UP, not a move. `bin/lib/*.py` stays in place — the bash heredocs still `sys.path.insert` + import it during Phase 24. Deleting `bin/lib/` now breaks every bash body. The de-duplication (bash importing `common/` instead of `bin/lib/`) is Phase 25 work.

This plan depends on Plan 01 (wave 1): it imports/verifies against the `pyproject.toml` package config Plan 01 created (`pip install -e .` resolves `compendium.common`). (Addresses REVIEWS HIGH#8 — 24-02 depends on 24-01.)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-CONTEXT.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md

<interfaces>
<!-- Verbatim-lift mapping (source file -> common/ module). RENAME the module file only;
     the import-surface rename is the one-time cost paid here before freeze. -->
bin/lib/privacy_resolve.py   (105 lines) -> common/privacy.py     stable names: resolve_source_privacy, resolve_effective_claim_privacy, _is_local
bin/lib/brownfield_yaml.py   (483 lines) -> common/yaml_rt.py     stable names: make_yaml (+ split_frontmatter, read_fm_body, infer_id_from_filename, extract_h1, file_mtime_iso, build_d14_sentinel_set, merge_sentinels, write_roundtrip, FIELD_CLASS_A/B, VALID_ENUMS, DuplicateKeyError) — __all__ at line 469
bin/lib/brownfield_walk.py   (169 lines) -> common/walk.py        stable names: walk_vault_respecting_ignore, load_brownfield_ignore, any_match  (no __all__ — preserve every module-level public name)
bin/lib/brownfield_classify.py (321 lines) -> common/classify.py  stable names: classify_page, unknown_reason  (no __all__ — preserve every public name)
bin/lib/brownfield_provenance.py (116 lines) -> common/provenance.py stable name: section_scan  (__all__ at line 111)

<!-- NEW extraction (no bin/lib analog — lives inline-duplicated in two bash heredocs): -->
common/page.py  <- bin/lint.sh (AUTHORITATIVE copy) + bin/audit-claims.sh (the "COPIED FROM bin/lint.sh" dup)
  parse_frontmatter (lint.sh ~449-486), parse_frontmatter_str (audit-claims.sh ~204 in-memory variant),
  PROV_RE, EPISTEMIC_INLINE_RE (lint.sh ~449-486), WIKILINK_RE/PIPED_LINK_RE/BARE_LINK_RE (lint.sh ~410-416),
  mask_markdown + _FENCE_RE/_HTMLCOM_RE/_INLINE_RE/_FM_RE (lint.sh ~430-447), EXCLUDE_FILES/EXCLUDE_DIRS (lint.sh ~458-459)

<!-- Shared-looking duplicates to inventory (REVIEWS MEDIUM "common completeness"): privacy/frontmatter
     logic ALSO appears in bin/validate-op.sh, bin/check-neutrality.sh, bin/brownfield.sh. Some may be
     intentionally distinct. The inventory documents each + notes intentional differences. -->
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Verbatim-lift the 5 bin/lib modules into common/ + write the make_yaml round-trip test</name>
  <files>src/compendium/common/__init__.py, src/compendium/common/privacy.py, src/compendium/common/yaml_rt.py, src/compendium/common/walk.py, src/compendium/common/classify.py, src/compendium/common/provenance.py, tests/test_common_extraction.py</files>
  <behavior>
    - Test 1: `compendium.common.yaml_rt.make_yaml()` exists and returns a ruamel `YAML` instance with `typ='rt'`, `preserve_quotes=True`, `default_flow_style=False`, and a `None`→`null` representer.
    - Test 2: round-tripping a committed frontmatter fixture through `make_yaml()` (load → dump) produces BYTE-IDENTICAL output to the committed expected fixture (the canonicalization is preserved).
    - Test 3: `compendium.common.privacy.resolve_effective_claim_privacy` and `resolve_source_privacy` are importable and callable; `_is_local('wiki-local/x.md')` is True, `_is_local('./wiki-local/x.md')` is True, `_is_local('WIKI-LOCAL/x.md')` is True (WR-02 case-fold), `_is_local('wiki-cloud/x.md')` is False.
    - Test 4: each lifted common/ module's source is byte-identical to its bin/lib source EXCEPT for any module-internal import-path lines (there are none to change in a 1:1 lift — these are leaf modules with no cross-bin/lib imports).
  </behavior>
  <read_first>
    - bin/lib/brownfield_yaml.py (READ FULLY — 483 lines; this is the byte-exact chokepoint. Note make_yaml at 164-183, read_fm_body at 186-227, __all__ at 469)
    - bin/lib/privacy_resolve.py (READ FULLY — 105 lines; _is_local at 39, resolve_source_privacy at 59, resolve_effective_claim_privacy at 71)
    - bin/lib/brownfield_walk.py (READ FULLY — 169 lines; no __all__, so enumerate every `def`/module-level public name to preserve)
    - bin/lib/brownfield_classify.py (READ FULLY — 321 lines; no __all__)
    - bin/lib/brownfield_provenance.py (READ FULLY — 116 lines; __all__ at 111)
    - pyproject.toml (from Plan 01 — confirm `[tool.setuptools.packages.find] where=["src"]` so `compendium.common` is discoverable)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the common/yaml_rt.py + privacy.py sections — make_yaml settings + _is_local predicate shown verbatim)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md (Pitfall 2 [make_yaml drift]; Don't-Hand-Roll table; the 1:1-lift recommendation)
  </read_first>
  <action>
**Verbatim lift (5 modules).** For each of the 5 `bin/lib/*.py` files, create the corresponding `common/` module with its CONTENT COPIED BYTE-FOR-BYTE (only the file is renamed). These are leaf modules — none of them imports another `bin/lib` module, so there are NO internal import paths to rewrite (verify this while reading; if any cross-module import exists, rewrite it to `from compendium.common.<m> import ...` and note it in the SUMMARY). Mapping:
- `bin/lib/privacy_resolve.py`   → `src/compendium/common/privacy.py`
- `bin/lib/brownfield_yaml.py`   → `src/compendium/common/yaml_rt.py`
- `bin/lib/brownfield_walk.py`   → `src/compendium/common/walk.py`
- `bin/lib/brownfield_classify.py` → `src/compendium/common/classify.py`
- `bin/lib/brownfield_provenance.py` → `src/compendium/common/provenance.py`

DO NOT re-tune `make_yaml()`. Its four settings are byte-pinned (Pitfall 2): `YAML(typ='rt')` + `y.preserve_quotes = True` + `y.default_flow_style = False` + the `None`→`null` representer (`represent_scalar('tag:yaml.org,2002:null', 'null')`). Keep `__all__` intact where present (yaml_rt line 469, provenance line 111). For walk/classify/privacy (no `__all__`), copy verbatim — every existing module-level public name stays public.

Preserve the `import yaml` (PyYAML) preflight + ruamel imports verbatim in yaml_rt.py — this is WHY both deps are pinned.

**`common/__init__.py` re-export.** Create `src/compendium/common/__init__.py` that re-exports the stable public names so `from compendium.common import make_yaml, resolve_effective_claim_privacy` works:
```python
from .yaml_rt import make_yaml, split_frontmatter, read_fm_body, write_roundtrip
from .privacy import resolve_source_privacy, resolve_effective_claim_privacy
from .walk import walk_vault_respecting_ignore, load_brownfield_ignore, any_match
from .classify import classify_page, unknown_reason
from .provenance import section_scan
# page.py names are re-exported once Task 2 lands them.
```
(Adjust the imported names to match the ACTUAL public names you confirmed while reading — do not invent names; use what the source modules define.)

**make_yaml round-trip fixture + TEST-06 seed.** Create a committed fixture pair under `tests/fixtures/common/`: `frontmatter_in.md` (a known frontmatter block with quoting, key order, and a `null` value to exercise all four settings) and `frontmatter_out.md` (the byte-exact expected output of loading then dumping it through `make_yaml()`). GENERATE `frontmatter_out.md` by actually running the lifted `make_yaml()` on `frontmatter_in.md` (do not hand-write expected bytes). Then write `tests/test_common_extraction.py` with the four behaviors above, including a test that re-runs `make_yaml()` round-trip and `assert`s the output bytes equal `frontmatter_out.md` bytes.

DO NOT delete or modify any `bin/lib/*.py` file. DO NOT modify any `bin/*.sh` file.
  </action>
  <verify>
    <automated>python3 -m venv /tmp/p22v2 && /tmp/p22v2/bin/pip -q install pytest -e . && /tmp/p22v2/bin/python -m pytest tests/test_common_extraction.py -q</automated>
  </verify>
  <acceptance_criteria>
    - `ls src/compendium/common/*.py | grep -vc __init__` returns `5` after this task (page.py lands in Task 2 → becomes 6)
    - `test -f src/compendium/common/__init__.py` exits 0
    - `python3 -c "import ast; m=ast.parse(open('src/compendium/common/yaml_rt.py').read()); assert any(isinstance(n,ast.FunctionDef) and n.name=='make_yaml' for n in ast.walk(m))"` exits 0
    - `diff <(grep -v '^$' bin/lib/privacy_resolve.py) <(grep -v '^$' src/compendium/common/privacy.py)` shows NO differences (verbatim lift; whitespace-only tolerance)
    - `diff bin/lib/brownfield_yaml.py src/compendium/common/yaml_rt.py | grep -c '^[<>]'` returns `0` (byte-identical lift)
    - `grep -q "represent_scalar('tag:yaml.org,2002:null', 'null')" src/compendium/common/yaml_rt.py` exits 0 (None representer preserved)
    - `grep -q "preserve_quotes = True" src/compendium/common/yaml_rt.py && grep -q "default_flow_style = False" src/compendium/common/yaml_rt.py` exits 0
    - `test -f bin/lib/brownfield_yaml.py && test -f bin/lib/privacy_resolve.py` exits 0 (bin/lib NOT deleted)
    - `git diff --name-only HEAD -- bin/ | wc -l` returns `0` (bin/ untouched)
    - `tests/test_common_extraction.py` passes in the venv (make_yaml round-trip byte-equal + _is_local case-fold cases)
  </acceptance_criteria>
  <done>5 bin/lib modules lifted verbatim into common/ with public names preserved; common/__init__.py re-exports stable names; make_yaml round-trips a committed fixture byte-exactly; bin/lib and bin/ untouched.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: PRECONDITION (audit-claims≡lint.sh) + extract wiki-page primitives into common/page.py + consumer/API inventory</name>
  <files>src/compendium/common/page.py, src/compendium/common/__init__.py, tests/test_common_extraction.py, docs/reference/common-api-inventory.md</files>
  <behavior>
    - Test 0 (PRECONDITION — addresses REVIEWS LOW/MEDIUM): the inline primitive SOURCE TEXT in `bin/audit-claims.sh` (PROV_RE, EPISTEMIC_INLINE_RE, WIKILINK_RE, parse_frontmatter) is byte-identical to `bin/lint.sh`'s, modulo the known `(COPIED from lint.sh)` docstring. If they DIFFER beyond that docstring, the test FAILS and the extraction MUST NOT proceed (a pre-existing divergence would be silently unified into the frozen surface).
    - Test 1: `compendium.common.page.parse_frontmatter(path)` returns `(fm_dict, body, None)` for a well-formed page, `(None, content, 'Unterminated frontmatter (missing closing ---)')` for a page with an opening `---` but no closing `---`, and `(None, content, None)` for a page with no frontmatter.
    - Test 2: `compendium.common.page.parse_frontmatter_str(text)` (in-memory variant) returns the same shape for a string input.
    - Test 3: `PROV_RE` matches `[prov:source_id#locator]` and the piped variants; `EPISTEMIC_INLINE_RE` matches `[epistemic:: sourced]` and the other 4 enum values; the wikilink regexes match `[[id|Title]]`.
    - Test 4: the regex SOURCE TEXT in `common/page.py` is byte-identical to the authoritative copy in `bin/lint.sh`.
  </behavior>
  <read_first>
    - bin/lint.sh (READ lines 405-490 — the AUTHORITATIVE copy: WIKILINK_RE/PIPED_LINK_RE/BARE_LINK_RE at ~410-416, mask_markdown + _FENCE_RE/_HTMLCOM_RE/_INLINE_RE/_FM_RE at ~430-447, PROV_RE/EPISTEMIC_INLINE_RE/parse_frontmatter at ~449-486, EXCLUDE_FILES/EXCLUDE_DIRS at ~458-459)
    - bin/audit-claims.sh (READ lines 145-220 — the byte-copy this retires: the "two sources of truth — expected drift risk" comment block at ~145-154; PROV_RE/WIKILINK_RE/EPISTEMIC_INLINE_RE/parse_frontmatter dups; parse_frontmatter_str in-memory variant at ~204)
    - bin/validate-op.sh (GREP for privacy/frontmatter logic — does it inline `_is_local` or a frontmatter parse? note for the inventory)
    - bin/check-neutrality.sh (GREP for any privacy/path predicate — note for the inventory)
    - bin/brownfield.sh (GREP for privacy/frontmatter primitives beyond the bin/lib imports — note for the inventory)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the common/page.py section — Source A lint.sh excerpt verbatim + the byte-copy-to-retire map)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (LOW "Plan 02 freezes a unified page primitive without first verifying the two copies are identical"; MEDIUM "common complete is insufficiently demonstrated")
    - src/compendium/common/__init__.py (current state from Task 1 — append page.py re-exports)
  </read_first>
  <action>
**PRECONDITION FIRST (addresses REVIEWS LOW/MEDIUM 'Plan 02 precondition').** Before extracting `common/page.py`, mechanically verify that `bin/audit-claims.sh`'s inline primitives are byte-identical to `bin/lint.sh`'s (so unifying them into ONE frozen copy cannot silently discard a divergent behavior). For each shared symbol (`PROV_RE`, `EPISTEMIC_INLINE_RE`, `WIKILINK_RE`, and the `parse_frontmatter` body), extract the regex/function source text from BOTH scripts and diff them. The ONLY permitted difference is the audit-claims `(COPIED from lint.sh)` docstring line. If ANY other difference exists, STOP — do not extract; instead record the divergence in the SUMMARY and surface it as a blocker (a pre-existing split-brain must be resolved by the developer before it is frozen). Encode this as `Test 0` in `tests/test_common_extraction.py` so the precondition is an automated gate, not a one-time manual check.

**Extract `common/page.py` (only after the precondition passes).** Create `src/compendium/common/page.py` hosting ONE copy of the wiki-page primitives, extracted from the AUTHORITATIVE `bin/lint.sh` heredoc (NOT from audit-claims.sh). Copy these EXACTLY as they appear in lint.sh (preserve regex strings character-for-character):

1. `parse_frontmatter(filepath)` — the file-reading variant (lint.sh ~449-486):
```python
def parse_frontmatter(filepath):
    """Extract YAML frontmatter and body from a wiki page."""
    try:
        content = open(filepath, encoding='utf-8').read()
    except Exception as e:
        return None, '', str(e)
    if not content.startswith('---'):
        return None, content, None
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:]
        return fm, body, None
    except ValueError:
        return None, content, 'Unterminated frontmatter (missing closing ---)'
    except yaml.YAMLError as e:
        return None, content, f'YAML parse error: {e}'
```
2. `parse_frontmatter_str(text)` — the in-memory variant from audit-claims.sh ~204 (same logic on a string instead of a path).
3. `PROV_RE` and `EPISTEMIC_INLINE_RE` (lint.sh ~449-486) — copy the exact regex strings:
```python
PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'
    r'(?:\|([^|\]]+))?'
    r'(?:\|([^\]]+))?'
    r'\]'
)
EPISTEMIC_INLINE_RE = re.compile(r'\[epistemic::\s*(sourced|mixed|inferred|tentative|stale)\]')
```
4. The wikilink regexes `WIKILINK_RE`, `PIPED_LINK_RE`, `BARE_LINK_RE` (lint.sh ~410-416) — copy exact strings.
5. `mask_markdown` + its four regexes `_FENCE_RE`, `_HTMLCOM_RE`, `_INLINE_RE`, `_FM_RE` (lint.sh ~430-447) — copy exact.
6. `EXCLUDE_FILES`, `EXCLUDE_DIRS` (lint.sh ~458-459) — copy exact.

Add `import re` and `import yaml` at the top of page.py. Add an `__all__` listing every public name above.

Append the page.py re-exports to `common/__init__.py`:
```python
from .page import parse_frontmatter, parse_frontmatter_str, PROV_RE, EPISTEMIC_INLINE_RE, WIKILINK_RE, PIPED_LINK_RE, BARE_LINK_RE, mask_markdown, EXCLUDE_FILES, EXCLUDE_DIRS
```
(Adjust to the exact names you confirmed in lint.sh.)

**Consumer/API inventory (addresses REVIEWS MEDIUM 'common completeness').** Create `docs/reference/common-api-inventory.md` — a brief inventory demonstrating the core is COMPLETE. It must:
- List each `common/` module + its stable public API (the names re-exported in `__init__.py`).
- List every OTHER place a shared-looking privacy/frontmatter primitive appears that was NOT folded into `common/` in Phase 24: at minimum check `bin/validate-op.sh`, `bin/check-neutrality.sh`, `bin/brownfield.sh` (from the greps above). For each, note WHETHER it is (a) the same logic that a Phase-23 port should switch to `common/`, or (b) an INTENTIONALLY DISTINCT predicate that must stay separate (with the rationale). This is the evidence that "over-extract to completion" is satisfied OR that a remaining duplicate is a deliberate, documented exception — not an oversight.
- Use abstract placeholders, not vault terms (neutrality — it is a template-public doc).

Extend `tests/test_common_extraction.py` with Test 0 (precondition) + Tests 1–4. For Test 4, assert the extracted regex source strings equal lint.sh's by reading the relevant lint.sh lines and comparing the regex literal text.

DO NOT modify `bin/lint.sh` or `bin/audit-claims.sh` (their heredocs keep their inline copies in Phase 24 — the de-dup is Phase 25 MIG-02).
  </action>
  <verify>
    <automated>/tmp/p22v2/bin/pip -q install -e . && /tmp/p22v2/bin/python -m pytest tests/test_common_extraction.py -q</automated>
  </verify>
  <acceptance_criteria>
    - `ls src/compendium/common/*.py | grep -vc __init__` returns `6` (5 lifts + page.py)
    - `grep -q 'def test' tests/test_common_extraction.py && grep -qiE 'precondition|audit.claims.*lint|byte.identical' tests/test_common_extraction.py` exits 0 (Test 0 precondition present — REVIEWS LOW)
    - `python3 -c "import ast; m=ast.parse(open('src/compendium/common/page.py').read()); names={n.name for n in ast.walk(m) if isinstance(n,ast.FunctionDef)}; assert {'parse_frontmatter','parse_frontmatter_str'} <= names, names"` exits 0
    - `grep -q "Unterminated frontmatter (missing closing ---)" src/compendium/common/page.py` exits 0 (exact error string preserved)
    - `grep -q "EPISTEMIC_INLINE_RE" src/compendium/common/page.py && grep -q "sourced|mixed|inferred|tentative|stale" src/compendium/common/page.py` exits 0
    - `grep -q "PROV_RE" src/compendium/common/page.py` exits 0
    - `grep -cE "WIKILINK_RE|PIPED_LINK_RE|BARE_LINK_RE" src/compendium/common/page.py` returns 3 or more
    - `grep -q "from .page import" src/compendium/common/__init__.py` exits 0
    - `test -f docs/reference/common-api-inventory.md && grep -qE 'validate-op|check-neutrality|brownfield' docs/reference/common-api-inventory.md` exits 0 (inventory covers the shared-looking duplicates — REVIEWS MEDIUM)
    - `git diff --name-only HEAD -- bin/lint.sh bin/audit-claims.sh | wc -l` returns `0` (heredocs untouched — de-dup is Phase 25)
    - `tests/test_common_extraction.py` passes in the venv (precondition + parse_frontmatter 3-tuple + regex matches + lint.sh source-identity)
  </acceptance_criteria>
  <done>the audit-claims≡lint.sh precondition is an automated gate; common/page.py hosts one copy of the wiki-page primitives extracted from authoritative lint.sh; common/__init__.py re-exports them; the consumer/API inventory documents every shared-looking duplicate + intentional differences; TEST-06 covers the precondition + parse_frontmatter + regexes; bin/ heredocs untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| privacy resolver (`common/privacy.py`) | The fail-closed `wiki-local/` predicate is the structural guard that prevents local→cloud leakage; any behavior change is security-relevant |
| `make_yaml` chokepoint (`common/yaml_rt.py`) | Byte-exact canonicalization that pins every brownfield golden; drift silently breaks parity |
| extracted primitives (`common/page.py`) | The provenance/privacy regexes feed downstream privacy + audit decisions |
| audit-claims≡lint.sh precondition | Unifying a pre-existing split-brain into a frozen copy would bake in a parity break for whichever behavior is discarded |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-24-05 | Tampering | `common/privacy.py` `_is_local` / `resolve_effective_claim_privacy` | mitigate | Verbatim lift (no re-implementation) preserves WR-02 case-fold + WR-03 normalization. Acceptance `diff`s the lifted source against `bin/lib/privacy_resolve.py` AND a behavior test asserts case-fold / cloud-vs-local outcomes. |
| T-24-06 | Tampering | `make_yaml` settings | mitigate | Verbatim lift; acceptance `diff`s yaml_rt.py against brownfield_yaml.py (0 changed lines) and a round-trip test asserts byte-equality against a committed fixture. No re-tune. |
| T-22-07 | Information Disclosure | the lint↔audit byte-copy split-brain | mitigate | The PRECONDITION (Test 0) proves audit-claims.sh's copy is byte-identical to lint.sh's BEFORE extracting the single frozen copy (REVIEWS LOW). A pre-existing divergence STOPS the extraction instead of being silently unified. The single canonical copy is then tested for source-identity with lint.sh. |
| T-22-08 | Denial of Service | deleting `bin/lib/` prematurely | mitigate | Copy-up, never move: acceptance asserts bin/lib files still exist and `git diff bin/` is empty. |
| T-22-25 | Tampering | a remaining shared-looking duplicate is an undocumented oversight | mitigate | The consumer/API inventory (REVIEWS MEDIUM) enumerates every privacy/frontmatter primitive outside `common/` (validate-op, check-neutrality, brownfield) and labels each as a Phase-23 switch target OR an intentional exception with rationale — so "common complete" is demonstrated, not assumed. |
</threat_model>

<verification>
- `pytest tests/test_common_extraction.py` passes in a venv (precondition; make_yaml round-trip byte-equal; _is_local case-fold; parse_frontmatter 3-tuple).
- `diff bin/lib/brownfield_yaml.py src/compendium/common/yaml_rt.py` → 0 changed lines (verbatim lift).
- `python3 -c "import compendium.common"` (from an installed venv) imports cleanly with all stable names re-exported.
- `docs/reference/common-api-inventory.md` lists the shared-looking duplicates + intentional-difference notes.
- `git diff --name-only HEAD -- bin/` is empty (bin/lib kept; heredocs untouched).
</verification>

<success_criteria>
- PKG-02: `common/` is over-extracted to completion from `bin/lib/*.py` (privacy resolver, YAML round-trip incl. `make_yaml`, vault walker, page primitives) and importable as a single source of truth; the lint↔audit-claims byte-copy is retired in `common/page.py`; the consumer/API inventory demonstrates completeness.
- TEST-06 seed: `make_yaml` round-trip + `_is_local` + `parse_frontmatter` + the audit≡lint precondition have direct module-level unit coverage that did not exist before.
- REVIEWS LOW (precondition) + MEDIUM (common completeness inventory) resolved.
- bin/lib and bin/ untouched (lift, never move).
</success_criteria>

<output>
After completion, create `.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-02-SUMMARY.md`
</output>
</content>

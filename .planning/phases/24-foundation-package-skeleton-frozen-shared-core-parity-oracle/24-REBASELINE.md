# Phase 24 Re-baseline — MANDATORY start-of-milestone re-derivation

**Executed:** 2026-07-03, against HEAD `a1b7568` (post v1.4 close).
**Mandate:** `milestones/v1.5-MILESTONE-BRIEF.md` §"⚠️ MANDATORY RE-BASELINE" — the imported plans froze their
picture of `bin/` at the laptop's 2026-06-18 assessment; the desktop's v1.4 Source Lifecycle (Phases 22–23,
shipped 2026-07-03) changed the migration surface. **This document is authoritative for every concrete
count/list/line-ref below; the imported plan text is indicative where it conflicts.** The plans' architecture
(frozen-foundation → parallel fan-out → cutover; parity-oracle-first; shim-and-swap; all cycle-1..6 review
resolutions) is UNCHANGED.

## RB-1 — Tool census: 15 → 16 (affects Plan 24-01)

`ls bin/*.sh` = 18 scripts. Minus `install-hooks.sh` (stays bash, MIG-06) and `migrate-privacy-dirs.sh`
(retired, MIG-06) = **16 in-scope tools**. New since the laptop assessment: **`bin/repo-snapshot.sh`**
(Phase 22 here; pure bash, no python3 heredoc; MIG cluster home = wiki-ops family per the brief).

Consequences for 24-01 (every "15" becomes "16"):
- 16 `console_scripts` entries — add `compendium-repo-snapshot = "compendium.repo_snapshot:main"`.
- 16 stub modules — add `src/compendium/repo_snapshot.py`.
- All acceptance-criteria counts (`len(s)==15`, `grep -c ':main"'`, stub-file counts) become 16.
- `tests/test_packaging.py` import smoke includes `compendium.repo_snapshot`.

## RB-2 — Environment + dependency pins re-derived (affects Plan 24-01)

Measured on this machine 2026-07-03:

| Item | Laptop plan | Here (re-derived) |
|------|-------------|-------------------|
| Effective `python3` | 3.12 | **3.14.5** (linuxbrew; `/usr/bin/python3` 3.12.3 exists but lacks yaml/ruamel — the PATH interpreter is brew) |
| PyYAML | pin `==6.0.1` | **pin `==6.0.3`** (installed; empirically verified: phase-10 31/32, phase-11 47/48 at HEAD — the 2 failures are the known stale AGENTS-section tests, NOT YAML byte drift, so the committed brownfield goldens HOLD under 6.0.3) |
| ruamel.yaml | pin `==0.19.1` | **pin `==0.19.1`** (was ABSENT here; installed 2026-07-03 via `pip --break-system-packages` — same route as PyYAML earlier; brownfield hard-requires it) |
| setuptools / pytest pins | `==80.9.0` / `==8.4.1` | re-derive at 24-01 execute time per the plan's own escape clause ("pin to the latest installable exact version and record in the SUMMARY"); system pytest is 9.0.2 |
| requires-python | `>=3.11` (D-05) | unchanged |
| D-06 single CI Python | `'3.12'` "matching the dev env" | intent = match the golden-capture env → **new parity.yml jobs use `'3.14'`**; the 6 existing required-check jobs keep `'3.12'` untouched (PKG-04 additive-only) |

`pyproject.toml` `version` field: use `1.5.0` (this milestone is v1.5 here, not the laptop's v1.4).

## RB-3 — `common/` extraction inventory re-derived (affects Plan 24-02)

**Precondition (Test 0) re-verified feasible at HEAD:** `PROV_RE`, `EPISTEMIC_INLINE_RE`, `WIKILINK_RE`,
and `parse_frontmatter` in `bin/audit-claims.sh` are byte-identical to `bin/lint.sh`'s modulo the known
`(COPIED from lint.sh)` docstring line. Verified by diff 2026-07-03.

**Fresh line anchors (lint.sh is at LINT_VERSION 1.12.0, not the plan's 1.10.0; audit-claims gained the
Phase-22 resolvers — every old line ref into these two files is stale):**

| Symbol | bin/lint.sh (authoritative) | bin/audit-claims.sh (copy) |
|--------|------------------------------|-----------------------------|
| WIKILINK_RE / PIPED_LINK_RE / BARE_LINK_RE | 424 / 429 / 430 | 173 (WIKILINK only) |
| `_FENCE_OPEN_RE`, `_HTMLCOM_RE`, `_INLINE_RE`, `_FM_RE` | 445–448 | — |
| `_mask_fences` (line scanner) | 449–475 | — |
| `mask_markdown` | 477–489 | — |
| PROV_RE | 491–496 | 174–179 |
| EPISTEMIC_INLINE_RE | 497 | 180 |
| EXCLUDE_FILES / EXCLUDE_DIRS | 500–501 | — |
| `parse_frontmatter` | 512–529 | 185–203 |
| `parse_frontmatter_str` (in-memory variant) | — | 204+ |
| `_fence_mask_lines` (NEW, Phase 22) | — | 314+ |

**Plan 24-02 text updates this supersedes:**
- The old `_FENCE_RE` regex NO LONGER EXISTS. The quick task `260703-m4f` (2026-07-03) replaced it with
  `_FENCE_OPEN_RE` + the `_mask_fences` CommonMark line scanner. `common/page.py` lifts the CURRENT set
  verbatim: `_FENCE_OPEN_RE`, `_mask_fences`, `mask_markdown`, `_HTMLCOM_RE`, `_INLINE_RE`, `_FM_RE`.
  (24-CONTEXT's "Reviewed Todos (not folded): phase-14-lint-mask-fence-edge-cases" is OBE — it was
  COMPLETED as quick task 260703-m4f before this milestone started, so lint's fence behavior changed
  pre-freeze, not mid-parity.)
- **New consumer/API-inventory entries** (beyond validate-op / check-neutrality / brownfield):
  1. `audit-claims.sh:_fence_mask_lines` (:314) — same CommonMark fence rules as lint's `_mask_fences`
     but an INTENTIONALLY DISTINCT API (returns `(lines, fenced-flags)` for boundary-scanning resolvers
     vs lint's length-preserving text mask). NOT unified in Phase 24 (behavior parity bar); a Phase-25
     MIG-02 candidate for consolidation onto `common/page.py`. Document as intentional-difference.
  2. `audit-claims.sh` page-walk + source-registry block (:224, "COPIED from lint.sh page walk
     classifier") — a further copy the MIG-02 port retires; inventory it.
  3. `bin/lint.sh` Check 10g external-drift functions (Phase 23, `--network`) — lint-only, not shared;
     no extraction.

## RB-4 — Characterization-golden inventory re-derived (affects Plan 24-04)

- **Verified UNCHANGED (plans' drivers stay valid as written):** `init-wizard.sh` :55 (REPO_ROOT from `$0`),
  preflight :146–169 with `exit 3` at :165, already-init guard :195, `exit 4` at :221; `audit-claims.sh`
  :83 (--help early exit) / :123 (unconditional AUDIT_LIB_DIR); `brownfield.sh` :122 / :730;
  `gen-skills.sh` :30–32; `validate-op.sh` (dispatch :206, already-archived :95, MERGE-distinct :362);
  `search.sh` modes. All re-checked 2026-07-03.
- **repo-snapshot** joins the surfaces: (a) the impl-assertion inventory sweep MUST include
  `tests/phase-22/` and `tests/phase-23/` (scanned 2026-07-03: no source-grep impl assertions found —
  record them as behavioral in the inventory); (b) repo-snapshot is a ROUTED TOOL with existing behavioral
  coverage (5 invocations in `tests/phase-22/`, incl. error paths + `--force` clobber guard) — no new
  golden required by 24-04, but it must appear in the per-routed-tool coverage assertion (RB-5).
- Baseline reality re-measured (supersedes the plan's "phase-07/09/10/11/13 = RED" note): phase-10 =
  31/32, phase-11 = 47/48 tonight; phase-09's `test_lint_version.sh` was de-staled 2026-07-03. Re-measure
  ALL suites per-test at 24-05 execute time as the plan already mandates — do not trust either snapshot.

## RB-5 — CI suite enumeration re-derived (affects Plan 24-05)

- **The enumerated required-suite list is now:** `09 09.1 10 11 12.1 12.2 13 15 18 20 22 23 24`.
  The imported plan's list (`09 09.1 10 11 12.1 12.2 13 15 18 20 22`) used "22" in LAPTOP numbering
  for its new characterization suite — which is `tests/phase-24/` here. The desktop's REAL
  `tests/phase-22/` (repository source type, 3 suites, has run.sh) and `tests/phase-23/` (network
  drift, 1 suite, has run.sh) join the enumeration per the brief. Every acceptance-criteria grep of
  the list updates accordingly; anywhere the imported plan text says suite "22" meaning the new
  goldens suite, read "24".
- Only `tests/phase-15/` lacks a run.sh (confirmed; plan's Task-1 item stands).
- Direct-call census: **204** `bash "$REPO_ROOT/bin/<tool>.sh"` sites (was 193) — phase-22/23 added
  11 (3 lint, 3 audit-claims, 5 repo-snapshot). Phase-22/23 suites are seam-routed like the rest.
- **Per-routed-tool coverage list adds `repo-snapshot`:** audit-claims, brownfield, release,
  pdf-extract, requirements-sync, **repo-snapshot** (+ the validate-op/search/sync-claude/gen-skills/
  lint/checkers covered by 24-04). repo-snapshot's behavioral coverage lives in `tests/phase-22/`.
- Workflows unchanged (3 files: lint.yml, neutrality.yml, setup-parity.yml; skills-check still has no
  python setup — plan's HIGH#10 fix stands). `.claude/settings.local.json` invokes `bin/validate-op.sh`.
- New parity.yml matrix jobs: `python-version: '3.14'` (RB-2); existing jobs untouched at '3.12'.

## RB-6 — Freeze-baseline pin (affects Plan 24-06)

Mechanism unchanged (tag `phase-24-freeze` + `tests/freeze-baseline.sha` pinned at PRE-Plan-06 HEAD =
end-of-wave-4). The pin is captured at execute time by design — nothing stale. Frozen-surface path list
unchanged in shape; note `src/compendium/` will contain 16 (not 15) stubs when frozen.

## RB-7 — Out-of-scope table correction (REQUIREMENTS.md)

REQUIREMENTS.md Out-of-Scope says "Backlog 999.3 / 999.5 / 999.6 and the `repository` source type |
Unrelated feature backlog" — STALE as written: 999.5 + the `repository` type SHIPPED here as v1.4
(Phases 22–23) before this milestone started. Read it as "999.3 / 999.6 remain backlog; the repository
source type and drift detection are v1.4 features whose *behavior* is in scope for parity like every
other bin/ behavior (repo-snapshot is tool #16), but no new lifecycle features land in v1.5."

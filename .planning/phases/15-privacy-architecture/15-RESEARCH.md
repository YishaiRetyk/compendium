# Phase 15: Privacy Architecture - Research

**Researched:** 2026-06-04
**Domain:** Claude Code permission model, repo-layout migration, ruamel.yaml frontmatter surgery, lint/CI re-keying
**Confidence:** HIGH (permission model verified against current docs + version-pinned GitHub issues; tooling mechanics verified against shipped source)

## Summary

Phase 15 is overwhelmingly **decided** (D-01..D-16 LOCKED in CONTEXT.md). Research confirms the genuine unknowns and surfaces the concrete mechanics the planner needs. The single highest-stakes finding: **the Claude Code permission model fails OPEN for the track-in-main regime, exactly as CONTEXT.md D-10/D-11/D-12 assert** — verified against the current official permissions doc and version-pinned GitHub issues, not assumed. A committed `deny` cannot express "deny-cloud, allow-local" (deny beats allow at every scope), so the deny must live in a cloud-only per-session profile loaded via `claude --settings ./.claude/settings.cloud.json` (the flag exists and works). Even with that profile, a `Read(./wiki-local/**)` deny covers the Read tool and Claude-recognized Bash file commands (`cat`/`head`/`tail`/`sed`) but **NOT** `python -c 'open(...)'` or other arbitrary subprocesses, and **NOT** `git show HEAD:wiki-local/…` (git objects are reachable regardless of working-tree/sparse state — confirmed empirically in this repo). The only OS-level fail-closed control is the **sandbox** or the **separate-repo regime (D-13)**.

The migration itself is light on data (54 pages → `wiki-cloud/`, 2 audit files → `wiki-local/maintenance/`) and heavy on path-reference churn: **~25 source/CI/test/template files** carry hardcoded `wiki/` references, dominated by `schema/AGENTS.template.md` (72), `schema/fixtures/canonical-AGENTS.md` (72), `.obsidian/workspace.json` (28), `bin/lint.sh` (25), `bin/init-wizard.sh` (22). All move in one lockstep commit (D-02/D-05).

**Primary recommendation:** Structure the phase as (1) a single lockstep rename+strip+schema-rewrite commit that never leaves the tree lint-red, then (2) the net-new enforcement artifacts (cloud deny-profile, asymmetric-link lint check, fail-direction table, verification test), then (3) the execution-time decision record. Ship the deny-profile labeled **fail-open / convenience** and the separate-repo runbook as the **fail-closed guarantee** — never the reverse.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Remove the per-page `privacy` frontmatter field entirely. Directory is the sole classifier. Drop from §5 base block, §5 checklist item #5, all 12 page templates, `examples/`. "Stricter-only override" variant REJECTED.
- **D-02:** Strip everything in this phase — one clean sweep, no half-migrated state. Pages + §5 base-field block + §5 checklist + lint yaml check + `check-privacy.sh` are coupled → lockstep, no intermediate lint-red commit.
- **D-03:** Sequence = route THEN strip. Read each page's `privacy` to decide destination dir (`local_only` → `wiki-local/`, else `wiki-cloud/`) BEFORE removing the field. (Creator vault: 2 audit files → `wiki-local/`, 54 others → `wiki-cloud/`.)
- **D-04:** Frontmatter-scoped tooling (ruamel.yaml `bin/lib/brownfield_yaml.py`), NOT raw `sed` (which would corrupt prose `privacy:` mentions in docs/AGENTS/CLAUDE).
- **D-05:** Rename `wiki/` → `wiki-cloud/`. All path references move in lockstep with D-02.
- **D-06:** `wiki-local/` mirrors the convention; subdirs created on demand (no pre-created empty dirs). Same 6 page types, same §2/§4 structure; walk helpers iterate both trees identically.
- **D-07:** Per-tier `index.md`/`log.md` partition is a FORCED PRIV requirement (cloud cannot read `wiki-local/` → cannot list/log it without leaking existence). Local `index.md`/`log.md` created lazily.
- **D-08:** Audit control-plane (`audit-report.md` + `audit-state.md`) → `wiki-local/maintenance/`.
- **D-09:** Asymmetric link rule (net-new lint check): `wiki-local`→`wiki-cloud` links fine; `wiki-cloud`→`wiki-local` forbidden. Add to §8 + lint under PRIV-05.
- **D-10:** Object-level absence is the ONLY genuinely fail-closed read control. Sparse-checkout hides working-tree files, not git objects; a worktree shares `.git/objects` → `git show HEAD:wiki-local/…` reconstructs "excluded" tracked content. Sparse-worktree is fail-OPEN for tracked `wiki-local/`.
- **D-11:** Claude Code `deny` precedence makes a committed settings-deny structurally fail-open (deny beats allow → can't do "deny-by-default, local opt-in" in committed `settings.json`). Deny must live in a cloud-only per-session profile. A `Read(./wiki-local/**)` deny protects the Read tool only — Bash bypass is version-dependent; verify.
- **D-12:** Ship controls with HONEST labeling. Phase ships: (1) cloud deny-profile artifact + runbook (labeled fail-open/convenience/single-clone low-stakes); (2) separate-repo high-sensitivity pattern (the fail-closed guarantee, D-13); (3) honest fail-direction table; (4) a verification test (blocked from Read, from Bash read, AND from `git show HEAD:wiki-local/…`). MUST NOT ship track-in-main while claiming sparse-worktree makes it fail-closed.
- **D-13:** Two proportionate regimes. **Creator default (track-in-main, PROVISIONAL):** `wiki-local/` tracked in main repo (zero real secrets; data-loss risk dominates leak risk for solo creator). **High-sensitivity (separate-repo):** `wiki-local/` becomes its own git repo with its own private remote, gitignored from parent → `git show` finds nothing → genuinely fail-closed; auto-excluded from public release by absence.
- **D-14:** Separate-repo pattern PRESERVES the unified Obsidian graph — nested repo checked out inside the parent vault root (gitignored by parent) still appears as one vault on disk → graph + piped links work across tiers. Does NOT fragment the graph.
- **D-15:** Author `wiki-cloud/decisions/dr-YYYY-MM-DD-privacy-asymmetric-two-dir.md` (`trigger_type: schema-update`) at execution time. Record three options (per-page mixed / per-vault fully separate / asymmetric two-dir) and why asymmetric won.
- **D-16:** §13 resident obligation reduces to a one-line structural pointer in core. The fail-closed/3-level-precedence/inheritance machinery is REMOVED, not relocated. Privacy leaves the always-loaded safety core.

### Claude's Discretion
All plan-time mechanics: exact regexes, walk order, exit codes, the `check-privacy.sh` re-key implementation, the asymmetric-link lint check implementation, CI privacy-leak job wiring, the precise migration script structure.

### Deferred Ideas (OUT OF SCOPE)
- **init-wizard interactive privacy-tier prompt → Phase D (WIZ).** Phase 15 documents the two regimes + separate-repo runbook only; add a forward-reference in PRIV notes so Phase D inherits it.
- `phase-14-lint-mask-fence-edge-cases` todo — reviewed, NOT folded (Phase 17 / standalone).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PRIV-01 | Adopt two-dir layout; migrate `wiki/`→`wiki-cloud/`; relocate audit files to local side | Path-Reference Inventory (below) enumerates the full lockstep surface; ruamel strip mechanics confirmed; git-object reconstruction verified for D-13 regime choice |
| PRIV-02 | Rewrite §13 to asymmetric per-vault model; remove 7-row table | Permission-model findings give the accurate enforcement language; §13 rewrite content map below |
| PRIV-03 | Concrete enforcement artifact (settings deny + two-session runbook) | `--settings` flag verified; `permissions.deny` syntax + precedence + Bash/subprocess coverage verified; exact artifact spec below |
| PRIV-04 | Decide per-page `privacy` field fate (remove) | D-01 LOCKED remove; ruamel `read_fm_body`→`del fm['privacy']`→`write_roundtrip` confirmed as the strip mechanic |
| PRIV-05 | Re-key tooling (`check-privacy.sh`, `lint.sh`, `audit-claims.sh` FAITH-04, CI) without behavioral regression | Current source read for all four; integration points + collapse-to-single-predicate spec below |
| PRIV-06 | Execution-time decision record | DR template (§4.6) + DR-at-execution precedent confirmed |
| PRIV-07 | Confirm §13 resident reduces to one-line pointer; machinery removed | Feeds REF-06; §16/core reduction confirmed against milestone Extraction Map |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Privacy tier classification | Directory layout (filesystem) | — | D-01: the directory IS the classifier; no per-page field, no resolver precedence |
| Cloud read-leak prevention | Harness permission (Claude Code `settings.cloud.json`) + OS sandbox / separate-repo | git object store (the leak surface) | D-11/D-12: harness deny is convenience/fail-open; sandbox or separate-repo is fail-closed |
| Cross-tier link integrity | Lint (`bin/lint.sh` linkres) | Schema §8 convention | D-09: structural twin of the read-permission; mechanically enforced |
| Public-path leak guard | `bin/check-privacy.sh` + CI job | Release allowlist (`bin/release.sh`) | PRIV-05: re-keyed from frontmatter-grep to structural path check |
| Effective-claim privacy (audit) | `bin/audit-claims.sh` + `privacy_resolve.py` | — | PRIV-05: collapses to single structural predicate (page-or-source under `wiki-local/`) |
| Schema authority | `CLAUDE.md` ≡ `AGENTS.md` (byte-equal) + `schema/AGENTS.template.md` | `schema/fixtures/canonical-AGENTS.md` | Every §2/§5/§8/§13 edit lands in all three; byte-equality + wizard-regen tests gate |

## Standard Stack

This phase **re-keys existing tooling**; it does not introduce new libraries. The "stack" is the existing repo tooling, verified current.

### Core (existing, verified in-repo)
| Tool | Location | Purpose | Why Standard |
|------|----------|---------|--------------|
| ruamel.yaml round-trip helper | `bin/lib/brownfield_yaml.py` (`read_fm_body`, `write_roundtrip`, `make_yaml`) | Comment/key-order-preserving frontmatter mutation | D-04: the correct tool for the `privacy`-field strip; avoids prose corruption [VERIFIED: source read] |
| `bin/lint.sh` | LINT_VERSION `1.6.0`, 2501 lines | yaml/orphan/crossref/stale/contradiction/gap/provenance/drift/duplicate/linkres + brownfield | linkres machinery (LINK-04..06) is the D-09 integration point [VERIFIED: source read] |
| `bin/check-privacy.sh` | 148 lines | CI-07 public-path leak guard | Re-keyed, not rebuilt [VERIFIED: source read] |
| `bin/lib/privacy_resolve.py` | 88 lines | §13 3-level + strictest-wins resolver | Simplified (not extended) to single predicate [VERIFIED: source read] |
| `bin/audit-claims.sh` | FAITH-04 chokepoint | Effective-claim privacy partition | Imports `resolve_effective_claim_privacy`; collapses to structural predicate [VERIFIED: source read] |
| Claude Code | installed `2.1.162` | Harness permission enforcement | `--settings`, `permissions.deny`, sandbox all available [VERIFIED: `claude --version` + current docs] |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `bin/sync-claude.sh --check` | AGENTS.md ↔ CLAUDE.md byte-equality (pre-commit) | After every §2/§5/§8/§13 edit |
| `bin/release.sh` | Orphan-branch publish allowlist | Re-key `wiki/*` allowlist entries → `wiki-cloud/*` (+ confirm `wiki-local/` excluded) |
| `tests/phase-NN/lib.sh` | bash test harness (make_bare_repo, assert_exit_code, write_page) | New `tests/phase-15/` for verification test + lint check |

**No installation required.** All tooling is in-repo; ruamel.yaml + PyYAML already dependencies (CI installs `pyyaml`; `brownfield_yaml.py` imports `ruamel.yaml`).

## Architecture Patterns

### System Architecture Diagram

```
                      ┌─────────────────────────────────────────────┐
   Migration input    │  wiki/ (single-tier: 54 cloud_safe + 2       │
   (current state)    │  local_only audit files)                     │
                      └───────────────────┬─────────────────────────┘
                                          │ D-03: ROUTE (read privacy) THEN STRIP
                          ┌───────────────┴────────────────┐
                          ▼                                 ▼
              ┌───────────────────────┐        ┌────────────────────────────┐
              │ wiki-cloud/           │        │ wiki-local/                 │
              │  entities/ concepts/  │        │  maintenance/               │
              │  sources/ overviews/  │        │   audit-report.md           │
              │  comparisons/         │        │   audit-state.md            │
              │  decisions/  ← DR-15  │        │  (index.md/log.md LAZY,     │
              │  index.md  log.md     │        │   created on 1st local page)│
              │  maintenance/lint-rpt │        └────────────────────────────┘
              └───────────┬───────────┘                     ▲
                          │ ruamel strip `privacy:` per page │
                          ▼                                  │
          ┌───────────────────────────────────┐             │
          │ Enforcement (D-09..D-13)            │            │
          │                                     │            │
          │  cloud session ──[deny-profile]──X──┼────────────┘  FORBIDDEN
          │   (--settings .claude/settings.     │   (Read tool, recognized
          │    cloud.json: deny Read(wiki-local │    Bash file-cmds blocked;
          │    /**)) = FAIL-OPEN convenience    │    python/git show NOT)
          │                                     │
          │  local session ── reads BOTH ───────┘  ALLOWED (no egress)
          │                                     │
          │  separate-repo regime (D-13) =      │
          │   FAIL-CLOSED (objects absent)      │
          └───────────────────────────────────┘
                          │
                          ▼
          ┌───────────────────────────────────┐
          │ Guards (re-keyed)                   │
          │  check-privacy.sh: no wiki-local/   │
          │   in PUBLIC_PATHS / release stage   │
          │  lint linkres: cloud→local link =   │
          │   error                             │
          │  audit FAITH-04: effective-local    │
          │   iff page||source under wiki-local/│
          └───────────────────────────────────┘
```

### Pattern 1: ruamel single-key frontmatter strip (D-04)
**What:** Remove only the `privacy:` key from a page's frontmatter, preserving comments, key order, quoting, and body byte-for-byte.
**When to use:** The 56-page strip after routing (D-03).
**Mechanic (verified against `bin/lib/brownfield_yaml.py`):**
```python
# Source: bin/lib/brownfield_yaml.py (read_fm_body / write_roundtrip)
from brownfield_yaml import read_fm_body, write_roundtrip
fm, body, _raw = read_fm_body(path)   # fm is a ruamel CommentedMap (preserves comments+order)
if fm is not None and 'privacy' in fm:
    del fm['privacy']                  # CommentedMap deletion preserves surrounding comments/order
    write_roundtrip(path, fm, body)    # atomic tmp+rename, LF-normalized
```
**Note:** `write_roundtrip` LF-normalizes and ensures a single trailing newline after the YAML block; existing pages already have a leading `\n` in body so the `---\n<body>` join is a no-op for them. The migration script's per-page loop should be idempotent (`if 'privacy' in fm`).

### Pattern 2: Route-then-strip ordering (D-03)
**What:** A two-pass migration: pass A reads `privacy` and `git mv`s each page to its tier dir; pass B strips the field in place.
**Why:** Stripping first destroys the only record of which page was `local_only`. The 2 known `local_only` pages are `wiki/maintenance/audit-{report,state}.md` — but the script must read the field generically, not hardcode the two, so it survives a vault with other local content.

### Pattern 3: linkres-anchored asymmetric-link check (D-09)
**What:** A net-new lint rule firing on any `[[id|Title]]` in a `wiki-cloud/` page whose resolved target page lives under `wiki-local/`.
**Integration point (verified, `bin/lint.sh` lines ~1890–2025):** the `linkres` block already builds `known_ids` (lowercase id+stem set) and `norm_map` (normalize→{ids}) over `all_pages`, and scans masked body with `PIPED_LINK_RE`. Add a parallel map `page_tier[id] = 'cloud'|'local'` built from each page's path prefix during the `all_pages` walk, then inside the existing `for rel, abs_path, raw in linkres_scan:` loop, when the *linking* file is under `wiki-cloud/` and a resolved piped target's id maps to a `local` page, `add_finding('error', 'linkres', rel, "...cloud→local link forbidden (PRIV-05/D-09)")`. Reuse the existing `mask_markdown` (so links in code fences/frontmatter are ignored) and the severity-remap table (`linkres`→`error` already exists, line ~321). **Decision for planner:** new logical subcategory under `linkres` vs. a fresh category name (e.g. `xtier`). The skip-category machinery supports both; a new top-level category needs registration in the `--category` help (line ~27–29), the severity remap dict (line ~313–321), and the `should_run`/category-filter path.

### Recommended migration script structure
```
bin/ (one-off or kept) migration:
  Pass 0  verify clean tree (git status), capture HEAD
  Pass A  for each wiki/**/*.md: read privacy; git mv → wiki-cloud/ or wiki-local/maintenance/
  Pass B  for each moved page: ruamel strip `privacy:` (Pattern 1)
  Pass C  rewrite every hardcoded `wiki/` path-reference (Path-Reference Inventory)
  Pass D  rewrite schema §2/§3/§5/§8/§13 in CLAUDE.md; sync to AGENTS.md; regen canonical-AGENTS.md fixture
  Pass E  author DR-15 in wiki-cloud/decisions/
  Pass F  run lint (must be green), sync-claude --check, byte-equality + wizard tests
  → ONE commit (D-02): `schema: asymmetric two-dir privacy (wiki/→wiki-cloud/+wiki-local/), strip per-page privacy field`
```

### Anti-Patterns to Avoid
- **Raw `sed -i '/privacy:/d'`:** corrupts prose `privacy:` lines in CLAUDE.md/docs/AGENTS.md (D-04). Use ruamel.
- **Strip before route:** destroys the routing signal (D-03).
- **Committing the deny in `.claude/settings.json`:** deny beats allow at every scope → also blocks local sessions, and a local `allow` cannot override it (D-11). Use a separate `settings.cloud.json` loaded via `--settings`.
- **Claiming sparse-worktree makes track-in-main fail-closed:** false-assurance trap (D-12). Objects remain reachable.
- **Intermediate lint-red commit:** stripping the field from §5 checklist+validator while it still exists on pages → 56-page "missing required field" error storm (D-02). Lockstep only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Frontmatter key removal | Custom YAML re-emitter or `sed` | `brownfield_yaml.read_fm_body` + `del` + `write_roundtrip` | Preserves comments/order/quoting; atomic; already tested [VERIFIED] |
| Cloud read-blocking | Custom wrapper / FUSE mount / chmod tricks | Claude Code `permissions.deny` (convenience) + sandbox or separate-repo (fail-closed) | Harness already enforces deny-first; sandbox is OS-level; separate-repo is absence-based [CITED: code.claude.com/docs/en/permissions, /sandboxing] |
| Cross-tier link detection | New link parser | Existing `linkres` `PIPED_LINK_RE` + `known_ids`/`norm_map` + `mask_markdown` | Masking + resolution already correct and tested (LINK-04..06) [VERIFIED] |
| Effective-claim privacy | Port the 3-level precedence ladder | Single structural predicate (page-or-source under `wiki-local/`) | The ladder is GONE with the per-page field; porting it re-introduces the dissolved machinery (CONTEXT specifics) |
| Per-session permission profile | Env-var hacks / launcher scripts that edit settings.json | `claude --settings ./.claude/settings.cloud.json` | First-class flag; values override file-based keys for the session only [VERIFIED: cli-reference] |

**Key insight:** This phase's value is *removing* machinery (the 3-level resolver, the per-page field, the resident rule) and replacing it with a directory boundary + a harness flag. Every temptation to "port" or "wrap" re-introduces what the phase exists to dissolve.

## Runtime State Inventory

> Rename/migration phase — all five categories answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | The wiki content itself: 56 markdown pages under `wiki/` (54 cloud_safe + 2 local_only audit files), tracked in git. No external DB. The `privacy:` frontmatter value on each page is the routing signal that must be READ before strip (D-03). | `git mv` route (Pass A) + ruamel strip (Pass B). Both a data relocation AND a code/schema edit. |
| **Live service config** | None. No external service stores the path. `.obsidian/workspace.json` (28 `wiki/` refs) and `.obsidian/plugins/dataview/main.js` (12 refs) are local vault UI state — workspace.json holds open-file/pane paths; dataview main.js is the **plugin bundle** (third-party, not hand-edited). | `workspace.json`: regenerate or leave (Obsidian rewrites it; broken pane paths self-heal on next open). `dataview/main.js`: do NOT edit — its `wiki/` hits are coincidental minified strings, not vault paths. **Verify** by grepping context before assuming. |
| **OS-registered state** | None. No Task Scheduler / systemd / launchd / pm2 registrations reference `wiki/`. | None — verified by absence (no such registrations in repo; this is a markdown repo). |
| **Secrets/env vars** | None reference `wiki/` by name. `WIKI_ROOT`/`WIKI_DIR` env override exists in `bin/lint.sh` (`WIKI_DIR="${WIKI_ROOT:-wiki/}"`, line ~94) — a default, not a secret. | Update the default `wiki/` → `wiki-cloud/`; the env override mechanism is unchanged. Audit other `bin/*.sh` for the same default pattern. |
| **Build artifacts / installed packages** | `schema/fixtures/canonical-AGENTS.md` (72 `wiki/` refs) is a **generated fixture** (wizard regen output) — stale after the template rename. No compiled binaries / egg-info / npm globals. | Regenerate `canonical-AGENTS.md` from the updated `schema/AGENTS.template.md` (the byte-equality test, Pass F, will fail until regenerated — that is the intended guard). |

**The canonical question:** After every repo file is updated, what runtime systems still cache the old `wiki/` path? Answer: only Obsidian's `workspace.json` (self-healing UI state) and the dataview plugin bundle (coincidental, leave alone). No durable runtime state survives the commit.

## Path-Reference Inventory (D-05)

> The full lockstep rename surface. `wiki/`→`wiki-cloud/` for content/tooling paths; audit control-plane → `wiki-local/maintenance/`. Counts are `grep -c 'wiki/'` occurrences (not all are path refs — verify each in context, esp. minified JS and prose).

**Source tooling (`bin/`):**
| File | `wiki/` count | Notes |
|------|--------------|-------|
| `bin/lint.sh` | 25 | `WIKI_DIR` default, `wiki/{entities,concepts,...}` prefix checks (~line 586, 624, 816), `git diff -- wiki/` scope (~504, 517), report path `wiki/maintenance/lint-report.md`. Also the D-09 net-new check lands here. |
| `bin/init-wizard.sh` | 22 | Scaffolds the wiki skeleton — emits `wiki/` dir creation + index/log. Re-key to `wiki-cloud/` + document `wiki-local/` lazy-mirror. **Phase-D collision risk** noted in deferred — coordinate. |
| `bin/brownfield.sh` | 11 | Vault-walk root resolution. |
| `bin/release.sh` | 9 | ALLOWLIST entries `wiki/index.md`, `wiki/log.md`, `wiki/decisions`, `wiki/{entities,concepts,comparisons,overviews,sources,maintenance}` → re-key to `wiki-cloud/*`; confirm `wiki-local/` is NOT in allowlist (excluded by absence). |
| `bin/audit-claims.sh` | 5 | `git diff -- wiki/` scope (~506); FAITH-04 consumer (predicate collapse). |
| `bin/search.sh` | 5 | Search root. |
| `bin/check-neutrality.sh` | (refs) | PUBLIC_PATHS-style; verify whether it excludes `wiki/`. |
| `bin/check-privacy.sh` | (refs) | PUBLIC_PATHS excludes `wiki/**` (line 33, 67) → re-key to structural model (see PRIV-05). |
| `bin/validate-op.sh` | (refs) | Operation target paths. |
| `bin/ingest.sh` | (refs) | Source/wiki page creation paths. |
| `bin/lib/privacy_resolve.py` | — | No `wiki/` literal; logic collapse (PRIV-05). |

**CI / config:**
| File | Notes |
|------|-------|
| `.github/workflows/lint.yml` | `privacy-leak` job comment references `wiki/**` exclusion (line 55–56); re-key comment + (if job invokes with paths) args. |
| `.claude/settings.json` | Target of the cloud deny-profile sibling `settings.cloud.json` (D-12). |

**Schema / templates (HIGH count — byte-equality-coupled):**
| File | `wiki/` count | Notes |
|------|--------------|-------|
| `schema/AGENTS.template.md` | 72 | Wizard source. Every §2/§3/§5/§8/§13 edit + path ref. Must stay byte-mirror of CLAUDE.md post-render. |
| `schema/fixtures/canonical-AGENTS.md` | 72 | Generated fixture; regenerate (Pass F). |
| `schema/brownfield/migrations/README.md` | (refs) | Doc prose. |
| `schema/examples/decision.md` | (refs) | Example page path prose. |
| `CLAUDE.md` / `AGENTS.md` | (the schema itself) | §2 tree, §3 MUST-NOT line, §5 base+checklist, §8 link rule, §11.6 release, §11.7 audit, §13 full rewrite, §12 index/log, scattered `wiki/` path examples throughout. |

**Docs (`docs/`):**
`docs/manual-setup.md` (11), `docs/guided-setup.md`, `docs/quickstart.md`, `docs/reference/{ci,release,three-layer-model,brownfield,dataview-queries,examples,index,privacy-model,agent-parity}.md`. `docs/reference/privacy-model.md` is the natural home for the **fail-direction table** + **separate-repo runbook** (D-12).

**Tests (`tests/`):** ~40 test files reference `wiki/` (full list in grep output). Highest: `test_lint_contributor_check.sh` (11), `test_lint_strict_dr_match.sh` (10), `test_kahneman_moved.sh` (9), `test_wizard_index_md.sh` (10). Many use inline `write_page` fixtures with `wiki/` paths; phase-07/08/09/12.2/13 hardest hit. **These tests assert against the OLD layout** — they must be updated in lockstep or the suite goes red. Plan a dedicated "update test fixtures to wiki-cloud/" task within the lockstep commit.

**Obsidian (local UI state — do NOT hand-edit):**
`.obsidian/workspace.json` (28 — self-healing pane paths), `.obsidian/plugins/dataview/main.js` (12 — coincidental minified strings, leave alone).

## §13 Rewrite Content Map (PRIV-02)

The rewritten §13 must (verified against milestone brief + permission findings):
1. **State the asymmetric model:** two dirs `wiki-cloud/` (cloud-safe) + `wiki-local/` (local-only), one unified Obsidian vault; one-way permeability (local runs read both; cloud runs MUST NOT read `wiki-local/`); local→cloud is the forbidden leak direction.
2. **REMOVE** the 7-row precedence table, the 3-level precedence narrative, the conflict-resolution/stricter-wins block, and the wiki-page inheritance block (D-16: removed, not relocated).
3. **State enforcement honestly:** harness permission (cloud deny-profile via `--settings`) is convenience/fail-open; OS sandbox or separate-repo (D-13) is the fail-closed guarantee. Reference the fail-direction table in `docs/reference/privacy-model.md`.
4. **§5:** delete `privacy` base field row + validation checklist item #5 (renumber).
5. **§3 "What Agents Must NOT Do":** the `local_only`→cloud line becomes "cloud sessions cannot read `wiki-local/` (structural)"; reconcile.
6. **§8:** add the cloud→local link prohibition (D-09).
7. **§11.7 / FAITH-04:** effective-claim privacy = single predicate (page OR any contributing source under `wiki-local/`).
8. **§11.6 release:** confirm orphan-branch neutralization excludes both `wiki-cloud/` and `wiki-local/` creator content (post-rename allowlist).

## Common Pitfalls

### Pitfall 1: Trusting the harness deny as fail-closed
**What goes wrong:** Shipping track-in-main with a `Read(./wiki-local/**)` deny and treating it as a real air-gap.
**Why it happens:** The deny *does* block the Read tool and `cat`/`head`/`tail`/`sed`, which looks complete in casual testing.
**How to avoid:** The verification test (D-12.4) MUST also assert `python -c 'open("wiki-local/...")'` and `git show HEAD:wiki-local/...` are the *uncovered* surfaces. Label the deny-profile fail-open. Real secrets → separate-repo.
**Warning signs:** A doc sentence claiming the sparse-worktree or settings-deny "prevents" cloud access without the word "convenience" or "fail-open."

### Pitfall 2: Committing the deny in tracked settings.json
**What goes wrong:** Local sessions also get blocked; a local `allow` can't override (deny-first precedence across all scopes).
**Why it happens:** Natural instinct to put policy in the committed config.
**How to avoid:** Put the deny ONLY in `.claude/settings.cloud.json`, loaded via `claude --settings`. Keep `.claude/settings.json` permissive.
**Warning signs:** `permissions.deny` containing `wiki-local` in any committed `settings.json` (not `settings.cloud.json`).

### Pitfall 3: Lint goes red mid-migration
**What goes wrong:** Stripping the §5 checklist/validator before stripping pages (or vice versa) → 56-page error storm.
**How to avoid:** D-02 lockstep — one commit. Run lint in Pass F before committing; it must be green.
**Warning signs:** Any commit boundary where `bin/lint.sh wiki-cloud/` reports yaml-category errors about `privacy`.

### Pitfall 4: Test suite + canonical fixture left on old layout
**What goes wrong:** ~40 test files and `canonical-AGENTS.md` assert `wiki/` paths → suite red after rename.
**How to avoid:** Treat test-fixture update + fixture regen as in-scope tasks of the lockstep commit (Pass C/F).
**Warning signs:** `cmp` failure in `test_canonical_byte_equality.sh`; phase-07/12.2 fixture path assertions failing.

### Pitfall 5: Editing the dataview plugin bundle or workspace.json
**What goes wrong:** Treating `.obsidian/` `wiki/` hits as path refs to rewrite; corrupts the plugin or fights Obsidian's auto-rewrite.
**How to avoid:** Exclude `.obsidian/` from the rename sweep. workspace.json self-heals; main.js strings are coincidental.

## Code Examples

### Cloud deny-profile artifact (PRIV-03, D-12)
```json
// Source: .claude/settings.cloud.json (NEW artifact). Loaded via:
//   claude --settings ./.claude/settings.cloud.json
// Labeled: policy/convenience, FAIL-OPEN, single-clone low-stakes work only.
{
  "permissions": {
    "deny": ["Read(./wiki-local/**)"]
  }
}
```
Caveat (verified): blocks Read tool + recognized Bash file-cmds (`cat`/`head`/`tail`/`sed`/`grep`); does NOT block `python -c open()`, Node scripts, or `git show HEAD:wiki-local/…`. For OS-level coverage add the [sandbox](https://code.claude.com/docs/en/sandboxing); for a true air-gap use the separate-repo regime (D-13).

### Verification test skeleton (PRIV-03, D-12.4)
```bash
# Source: tests/phase-15/test_cloud_deny_profile.sh (NEW). bash harness per tests/*/lib.sh.
# Assert a cloud-profile session is blocked from all THREE surfaces.
# (Run claude headless with the cloud profile; assert each access path fails/succeeds as labeled.)
#   1. Read tool      -> DENIED   (deny rule covers it)
#   2. Bash `cat wiki-local/x` -> DENIED (recognized file cmd)
#   3. Bash `python3 -c 'open("wiki-local/x")'` -> NOT denied  (documents fail-open gap)
#   4. Bash `git show HEAD:wiki-local/x`        -> NOT denied  (documents object-leak gap)
# The test PINS current behavior so a future Claude Code change that loosens (1)/(2) is caught.
```
Note: a fully headless assertion of (1)/(2) may require `claude -p` with `--settings`; if non-interactive harness assertion proves brittle, the planner may split into (a) a static assertion that the deny entry exists in `settings.cloud.json` + (b) a documented manual verification runbook. Confirm headless feasibility at plan time.

### check-privacy.sh re-key (PRIV-05)
```python
# Current (bin/check-privacy.sh): grep PUBLIC_PATHS frontmatter for `privacy: local_only`, exclude wiki/**.
# Re-keyed structural model: ensure no wiki-local/ content appears in template-public paths / release stage.
# Concretely: PUBLIC_PATHS scan changes from "frontmatter privacy field" to
#   "any path under PUBLIC_PATHS that is (a) inside a wiki-local/ tree, or (b) copies wiki-local content".
# Since wiki-local/ is never in PUBLIC_PATHS, the primary guard becomes the release-stage check:
#   bin/release.sh allowlist must NOT contain wiki-local/* (excluded by absence).
# Decision for planner: keep check-privacy.sh as a thin "no wiki-local under PUBLIC_PATHS" assertion,
# OR fold the guarantee into release.sh + a lint drift check. CONTEXT leaves the exact split to discretion.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-page `privacy` field + 3-level precedence + inheritance, agent honors every turn | Directory-as-classifier; cloud session physically scoped out of `wiki-local/` | This phase | Privacy leaves the resident core; no per-turn agent obligation |
| "Read deny rules apply to built-in tools, NOT Bash subprocesses" (older docs / issue #45200, v2.1.92) | Current docs (v2.1.x): Read/Edit deny **does** cover recognized Bash file cmds (`cat`/`head`/`tail`/`sed`), **not** arbitrary subprocesses (python/node) | Docs updated since #45200 | The deny is stronger than the old issue implied, but still fail-open for python/git — D-11/D-12 hold |
| Assumed sparse-checkout = isolation | Sparse-checkout hides working tree, NOT git objects; worktrees share `.git/objects` | Verified empirically this session | Track-in-main is fail-open for tracked content; separate-repo is the only object-level air-gap |

**Deprecated/outdated:**
- GitHub issue #45200 (closed not-planned) describes v2.1.92 behavior where the cross-tool scan was undocumented; the current permissions doc now documents the Bash-file-cmd coverage. Treat the **current doc** as authoritative for v2.1.162. The python/subprocess + git-object gaps remain in both.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.obsidian/plugins/dataview/main.js` `wiki/` hits are coincidental minified strings, not editable vault paths | Runtime State Inventory | LOW — leaving it alone is safe regardless; if some are real config they self-heal or are user-regenerable |
| A2 | A headless `claude -p --settings` session can assert the Read/Bash deny in an automated test | Code Examples (verification test) | MEDIUM — if not feasible, fall back to static settings-file assertion + manual runbook (noted inline). Confirm at plan time. |
| A3 | ~~`bin/check-neutrality.sh`, `bin/validate-op.sh`, `bin/ingest.sh` `wiki/` refs are all simple path defaults~~ **CORRECTED (W1):** `bin/check-neutrality.sh` is NOT pure-path — its `source_local_only_wiki()` carries a PREDICATE (`re.search(r"^privacy:\s*local_only\b", fm)`, line ~279) that goes DEAD after the field strip, silently dropping one of three CI-gated leak sources. `validate-op.sh`/`ingest.sh` ARE pure-path. | Path-Reference Inventory | ~~LOW-MEDIUM~~ **WAS UNDER-RATED** — the check-neutrality predicate re-key (walk `wiki-local/` by prefix, drop the regex) is owned by Plan 02 Task 2, NOT the mechanical Plan 01 re-key; planner must grep each file in context and watch for predicates, not just `^wiki/` anchors |
| A4 | The asymmetric-link check (D-09) can reuse `linkres` rather than needing a new top-level category | Pattern 3 | LOW — both paths documented; if reuse conflicts with severity semantics, register a new category (cost: ~3 edit sites) |

**Note:** The permission-model claims (deny-first precedence, Bash-file-cmd coverage, python/git-object gaps, `--settings` flag) are **VERIFIED/CITED**, not assumed — see Sources.

## Open Questions (RESOLVED)

1. **check-privacy.sh: thin assertion vs fold into release.sh?**
   - What we know: the frontmatter-grep loses its target (no more `privacy` field); the real guarantee is "no `wiki-local/` in public/release paths."
   - What's unclear: whether to keep a standalone `check-privacy.sh` (re-keyed) or migrate the guarantee into `release.sh` + a lint drift check.
   - Recommendation: keep `check-privacy.sh` as a thin re-keyed guard (preserves the CI `privacy-leak` job name + branch-protection required check), AND ensure `release.sh` allowlist excludes `wiki-local/`. Belt-and-suspenders, minimal churn to CI wiring.
   - **RESOLVED:** Plan 02 Task 2 keeps `check-privacy.sh` as a thin re-keyed structural guard (CLI surface + exit codes 0/1/2 + `privacy-leak` job name preserved) and re-confirms `bin/release.sh` allowlist excludes `wiki-local/` (belt-and-suspenders). NOT folded into release.sh.

2. **Headless verification-test feasibility (A2).**
   - Recommendation: spike `claude -p --settings ./.claude/settings.cloud.json` early; if brittle, ship static-assertion + manual runbook. Either satisfies Success Criterion #3 (the artifact is concrete) and the spirit of D-12.4 (a regression tripwire exists).
   - **RESOLVED:** Plan 02 Task 2(e) implements the A2 fallback ladder — spike the headless three-surface assertion; if brittle/non-deterministic, fall back to the static settings-shape assertion + the documented manual runbook (VALIDATION.md Manual-Only row) with a commented `# MANUAL:` block. Either path satisfies Success Criterion #3 + D-12.4.

3. **New lint category vs linkres subcategory for D-09.**
   - Recommendation: prefer a new logical subcategory tag inside `linkres` findings (least registration churn, inherits `linkres`→`error` remap). Escalate to a top-level category only if reporting clarity demands it.
   - **RESOLVED:** Plan 02 Task 1(a) uses the `linkres` subcategory (the `add_finding('error', 'linkres', ...)` path), inheriting the existing `linkres`→`error` remap with no new category registration. The top-level `xtier` category is documented as the escalation-only fallback, not taken.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Claude Code | harness permission enforcement (PRIV-03) | ✓ | 2.1.162 | two-clone manual split (documented) |
| `--settings` flag | cloud deny-profile loading | ✓ | (in 2.1.162 CLI) | `--disallowedTools "Read(./wiki-local/**)"` per-session |
| OS sandbox | fail-closed Bash file enforcement | ✓ (feature exists) | per docs | separate-repo regime (D-13) |
| ruamel.yaml | frontmatter strip (D-04) | ✓ | (imported by brownfield_yaml.py) | — |
| python3 + PyYAML | lint / check-privacy | ✓ | 3.12 (CI) | — |
| git worktree/show | demonstrates the leak surface (D-10) | ✓ | (repo confirmed) | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None blocking — all fallbacks are documented regime alternatives, not gaps.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash `test_*.sh` scripts under `tests/phase-NN/`, sourcing `tests/phase-NN/lib.sh` (make_bare_repo, assert_exit_code, write_page) |
| Config file | none — convention-based; each phase dir self-contained |
| Quick run command | `bash tests/phase-15/test_<name>.sh` |
| Full suite command | `for t in tests/phase-15/test_*.sh; do bash "$t"; done` (plus re-run prior phases' suites to confirm no regression from the rename) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PRIV-01 | `wiki-cloud/`+`wiki-local/` exist; 2 audit files under `wiki-local/maintenance/`; no `wiki/` dir remains | smoke | `bash tests/phase-15/test_layout_migrated.sh` | ❌ Wave 0 |
| PRIV-02 | §13 contains asymmetric language; 7-row table absent; per-page precedence narrative gone | unit (grep schema) | `bash tests/phase-15/test_schema_13_rewritten.sh` | ❌ Wave 0 |
| PRIV-03 | `.claude/settings.cloud.json` exists with `deny: Read(./wiki-local/**)`; verification test pins Read/Bash/git-show behavior | smoke + behavioral | `bash tests/phase-15/test_cloud_deny_profile.sh` | ❌ Wave 0 |
| PRIV-04 | No `privacy:` key in any `wiki-cloud/`/`wiki-local/` page frontmatter; §5 base block + checklist item #5 removed | unit | `bash tests/phase-15/test_privacy_field_stripped.sh` | ❌ Wave 0 |
| PRIV-05 | lint green on `wiki-cloud/`; cloud→local link = error; check-privacy re-keyed (no wiki-local in PUBLIC_PATHS/release); audit FAITH-04 predicate collapse | unit | `bash tests/phase-15/test_lint_xtier_link.sh`; `bash tests/phase-15/test_check_privacy_rekey.sh`; existing `tests/phase-13/*` (audit) re-run green | ❌ Wave 0 (lint check) / ✓ (audit suite exists) |
| PRIV-06 | DR exists at `wiki-cloud/decisions/dr-*-privacy-asymmetric-two-dir.md`, `trigger_type: schema-update`, records 3 options | unit | `bash tests/phase-15/test_decision_record.sh` (mirror `tests/phase-09.1/test_decision_record.sh`) | ❌ Wave 0 (mirror exists) |
| PRIV-07 | core §13 = one-line pointer; no precedence/inheritance machinery in core | unit | `bash tests/phase-15/test_priv_resident_reduced.sh` | ❌ Wave 0 |
| (cross) | `CLAUDE.md` ≡ `AGENTS.md` byte-equal; wizard regen byte-equal to canonical fixture | unit | `bash bin/sync-claude.sh --check`; `bash tests/phase-08/test_canonical_byte_equality.sh` | ✓ exists |
| (cross) | No regression: full lint suite + prior-phase tests green over renamed tree | regression | `bash bin/lint.sh wiki-cloud/`; re-run `tests/phase-07..13/*` | ✓ exists |

### Sampling Rate
- **Per task commit:** `bash tests/phase-15/test_<touched>.sh` + `bash bin/sync-claude.sh --check`
- **Per wave merge:** full `tests/phase-15/*` + `bash bin/lint.sh wiki-cloud/` (must be green — D-02 lockstep invariant)
- **Phase gate:** full suite (phase-15 + regression of phase-07..13 fixture-updated tests) + byte-equality + CI `lint`/`privacy-leak`/`strict` green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/phase-15/lib.sh` — copy from `tests/phase-13/lib.sh` (bump mktemp prefix to `phase15-`)
- [ ] `tests/phase-15/test_layout_migrated.sh` — covers PRIV-01
- [ ] `tests/phase-15/test_schema_13_rewritten.sh` — covers PRIV-02
- [ ] `tests/phase-15/test_cloud_deny_profile.sh` — covers PRIV-03 (the D-12.4 three-surface verification test)
- [ ] `tests/phase-15/test_privacy_field_stripped.sh` — covers PRIV-04
- [ ] `tests/phase-15/test_lint_xtier_link.sh` + `test_check_privacy_rekey.sh` — covers PRIV-05
- [ ] `tests/phase-15/test_decision_record.sh` — covers PRIV-06 (mirror phase-09.1)
- [ ] `tests/phase-15/test_priv_resident_reduced.sh` — covers PRIV-07
- [ ] **Fixture update task:** ~40 prior-phase `test_*.sh` files asserting `wiki/` paths must be updated to `wiki-cloud/` in the lockstep commit (else regression suite goes red — this is itself a validation gate, not optional cleanup)

## Sources

### Primary (HIGH confidence)
- `https://code.claude.com/docs/en/permissions` — deny-first precedence ("Rules are evaluated in order: deny → ask → allow. The first matching rule wins, so deny rules always take precedence"); Read/Edit deny covers recognized Bash file cmds (`cat`/`head`/`tail`/`sed`) but NOT arbitrary subprocesses (python/node) — sandbox is the OS-level enforcement; read-only commands (`ls`/`cat`/`grep`/`head`/`tail`/`find`/git-read) run without prompt in every mode; settings precedence (managed > CLI > local > project > user; deny at any level wins).
- `https://code.claude.com/docs/en/cli-reference` — `--settings` ("Path to a settings JSON file or an inline JSON string. Values override the same keys for this session"); `--disallowedTools`, `--add-dir`, `--permission-mode`, `--setting-sources`.
- In-repo source (read this session): `bin/check-privacy.sh`, `bin/lib/privacy_resolve.py`, `bin/lib/brownfield_yaml.py`, `bin/lint.sh` (linkres ~1890–2025, EXCLUDE_DIRS, severity remap, WIKI_DIR), `bin/release.sh` allowlist, `bin/audit-claims.sh` FAITH-04 imports, `.github/workflows/lint.yml`, `.claude/settings.json`.
- Empirical: `git show HEAD:wiki/index.md` returns content; `.git/objects` shared (confirms D-10 object-reachability); `claude --version` = 2.1.162; `grep -rc 'wiki/'` inventory; `.planning/config.json` nyquist_validation=true.

### Secondary (MEDIUM confidence)
- `https://github.com/anthropics/claude-code/issues/45200` (v2.1.92) — documents the (then-undocumented) cross-tool argument scanning; variable-indirection bypass (`BD=~/private-dir; ls "$BD"` passes). Confirms the deny is structural-pattern-based, not substring; confirms the python/subprocess gap by omission.
- `https://github.com/anthropics/claude-code/issues/45992` — `deniedPaths` bypassed by Bash (related, corroborating the subprocess gap).

### Tertiary (LOW confidence)
- None relied upon for decision-relevant claims.

## Metadata

**Confidence breakdown:**
- Permission model / fail-direction (D-10/11/12): HIGH — current official docs + version-pinned issues + empirical git test; all four D-12.4 surfaces accounted for.
- Tooling re-key mechanics (ruamel strip, linkres integration, check-privacy, audit predicate): HIGH — verified against shipped source.
- Path-reference inventory completeness: MEDIUM-HIGH — grep-driven; per-file context verification flagged for `.obsidian/` and any `^wiki/`-anchored regexes (A3).
- Verification-test automation feasibility: MEDIUM — headless `claude -p` assertion needs a plan-time spike (A2); static-assertion fallback documented.

**Research date:** 2026-06-04
**Valid until:** 2026-06-18 (~14 days — Claude Code permission behavior is version-sensitive; re-verify the Bash-deny coverage against the installed version at plan time if it has updated past 2.1.162)

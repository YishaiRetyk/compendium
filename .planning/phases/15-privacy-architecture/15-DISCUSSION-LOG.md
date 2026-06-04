# Phase 15: Privacy Architecture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 15-privacy-architecture
**Areas discussed:** Per-page field fate, wiki/ migration shape, Enforcement artifact, Local dir + graph (git-tracking)

---

## Per-page field fate (PRIV-04)

### Q1 — Field fate
| Option | Description | Selected |
|--------|-------------|----------|
| Remove entirely (rec) | Directory is the sole classifier; drop `privacy` from §5, checklist, 12 templates | ✓ |
| Retain as stricter-only override | Optional; may only make a wiki-cloud/ page stricter, never loosen wiki-local/ | |
| You decide | | |

**User's choice:** Remove entirely.

### Q2 — Field strip aggressiveness
| Option | Description | Selected |
|--------|-------------|----------|
| Strip everything now (rec) | One clean sweep: pages + templates + examples + §5 checklist | ✓ |
| Templates + schema now, pages lazily | Smaller diff now, lingering remnant on pages | |
| You decide | | |

**User's choice:** Strip everything now — but with the framing corrected and three guardrails added.
**Notes:** User noted the menu undersells the case: Phase 15 already rewrites all 56 pages (PRIV-01 dir-move dominates the diff), so stripping the one-line field is nearly free, not a "larger diff." Option 2 is worse than it looks — `privacy` is a §5 base field lint requires, so leaving it on pages while removing it from the checklist causes a 56-page error storm or transitional tolerate-logic (pushes complexity into the validator). Guardrails: (1) **route THEN strip** — read each page's `privacy` to pick destination dir first, then remove (else you destroy the only record of which pages were local_only); (2) **lockstep** — pages + §5 base-field + §5 checklist + lint yaml + check-privacy.sh change together, no intermediate lint-error commit; (3) **frontmatter-scoped ruamel** (`bin/lib/brownfield_yaml.py`), NOT raw `sed` (privacy appears in AGENTS/CLAUDE/docs prose). Confirmed PRIV-04 = remove (locked) before strip-aggressiveness even applies.

---

## wiki/ migration shape (PRIV-01)

### Q3 — wiki-local/ internal structure
| Option | Description | Selected |
|--------|-------------|----------|
| Minimal, grows on demand (rec) | Ship only maintenance/ + .gitkeep; type subdirs created lazily | partial |
| Full mirror of cloud structure | Pre-create all 6 type subdirs with .gitkeeps | partial |
| You decide | | |

**User's choice:** Neither pure option — "mirror the convention / minimal instantiation" (one from each layer).
**Notes:** The convention MUST mirror (wiki-local/ is a wiki — same 6 page types/§2/§4; tooling walks both trees identically; promotion is straight relocation; private tier deserves the full apparatus) but the filesystem grows on demand (no pre-created empty subdirs — exactly how wiki-cloud/ grew). Surfaced two FORCED coupled rules: (1) **per-tier index/log partition** — cloud can't read wiki-local/, so local content in wiki-cloud/ index/log leaks existence-metadata (FAITH-04 contract); wire into PRIV-02/05 now, create local index/log lazily; (2) **asymmetric link rule** (new lint check) — wiki-local→wiki-cloud OK, wiki-cloud→wiki-local forbidden. Audit files → wiki-local/maintenance/. Rename wiki/→wiki-cloud/ + route-then-strip taken as already locked from Q2.

---

## Enforcement artifact (PRIV-03)

### Q4 — read-leak enforcement posture
| Option | Description | Selected |
|--------|-------------|----------|
| Deny-profile + two-clone, layered (rec) | settings.cloud.json deny PRIMARY + two-clone defense-in-depth | revised |
| Deny-profile only | cloud-scoped settings file + runbook | |
| Two-clone runbook only | cloud clone lacks wiki-local/ | |
| You decide | | |

**User's choice:** Option 1's layering, but **primacy flipped** — structural air-gap is PRIMARY (fail-closed), deny-profile is SECONDARY (convenience, fail-open).
**Notes:** Load-bearing Claude Code precedence fact: **deny beats allow**, so you can't express "deny-by-default, local opt-in" via committed settings (committed deny blocks local sessions too; local allow can't override). Deny must live in a cloud-only per-session profile (`--settings`), which fails OPEN (cloud session without the flag inherits permissive default). Two more cracks: Bash bypass (cat/grep/python read past a Read-tool deny unless harness extends deny to Bash — version-dependent, verify) and harness-bound (not an OS guarantee). Ship: PRIMARY sparse git worktree runbook (later revised — see Q5), SECONDARY deny-profile (honest "policy, opt-in, Bash-bounded"), a verification test, and an honest fail-direction table. Scope clarification: this is the READ-leak (cloud ingests local into context), distinct from the WRITE-leak check-privacy.sh guards under PRIV-05 — both ship, neither masquerades as the other.

---

## Local dir + git-tracking (PRIV-01, two-regime)

### Q5 — is wiki-local/ git-tracked by default?
| Option | Description | Selected |
|--------|-------------|----------|
| Track fully; release strips it (rec) | History + backup; sparse-checkout excludes from cloud worktree; §11.6 keeps it out of public template | provisional default |
| Track scaffold only, gitignore content | Fail-closed by absence; no version history/backup | |
| You decide | | |

**User's choice:** Neither as-stated — a **major correction** that revised Q4, plus a two-regime resolution.
**Notes:** **Sparse-checkout hides files, not git objects.** A worktree shares `.git/objects`, so `git show HEAD:wiki-local/secret.md` / `git cat-file` / `git log -p` bypass sparse-checkout. So Option 1 (track-in-main) is NOT fail-closed against a cloud agent that can run git — read-isolation depends on policy denies. So: (a) **track-in-main = provisional creator default today** (vault has 2 audit files, zero secrets; git show of an audit report is a non-issue; data loss is a likelier threat than a leak on your own machine — so keep backup/history); (b) **separate-repo pattern = the documented fail-closed high-sensitivity path** (wiki-local/ as its own repo with private remote, gitignored from parent → objects never in parent history → git show finds nothing; auto-excluded from release by absence). No single-history design gives both backup AND object-level isolation. Verification test must also probe `git show HEAD:wiki-local/…`, not just Read/Bash. **MUST NOT** ship track-in-main while claiming sparse-worktree makes it fail-closed (false-assurance trap). Compatibility: separate-repo as a nested repo inside the vault root (gitignored by parent) **preserves the unified Obsidian graph** — one vault on disk, piped links resolve across tiers.

### Q6 — wrap-up (init-wizard timing + PRIV-05 intent)
**User's choice:** Lock both inline, then proceed to CONTEXT.md.
**Notes:** **init-wizard timing — DECIDED, not deferred-as-note:** Phase 15 DOCUMENTS the separate-repo path; the interactive prompt is **deferred to Phase D** (creator vault needs no prompt; the choice only bites for high-sensitivity adopters = observation-gated Phase D; a Phase-15 wizard prompt would collide with Phase D + v1.2 extraction phases also touching init-wizard.sh — three phases, one file). Add a forward-reference in PRIV notes so D inherits it. Phase 15 = architecture, not adoption UX. **PRIV-05 intent sharpening (planner note):** FAITH-04 effective-privacy collapses to a single structural predicate (claim is effective-local_only iff its page or any contributing source lives under wiki-local/ — do NOT port the §13 three-level precedence); check-privacy.sh re-keys from frontmatter-scan to "no wiki-local/ content in template-public paths/release stage"; asymmetric-link lint check is net-new but specified; mechanics are plan-time.

---

## Claude's Discretion

- All plan-time mechanics: regexes, walk order, exit codes, the `check-privacy.sh` re-key implementation, the asymmetric-link lint check implementation, CI privacy-leak job wiring, and the migration script structure.

## Deferred Ideas

- **init-wizard interactive privacy-tier prompt → Phase D (WIZ).** Documented (not implemented) in Phase 15; interactive prompt deferred to Phase D with a forward-reference. (Avoids three phases mutating `bin/init-wizard.sh`.)
- **`phase-14-lint-mask-fence-edge-cases` todo** — reviewed, NOT folded (keyword-only match; Phase-14 lint-masking residue, belongs to Phase 17 lint extraction or a quick task).

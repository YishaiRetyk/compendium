# Phase 15: Privacy Architecture - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Convert privacy from a **per-page, agent-remembered rule** (current §13: per-page `privacy` frontmatter + 3-level precedence + inheritance + fail-closed, honored by the cloud agent every turn) into a **structural, config-enforced property of the directory layout**.

The asymmetric two-directory model is **already ACCEPTED** (milestone brief, 2026-06-04) and is NOT re-opened by this phase:
- Two dirs: `wiki-cloud/` (cloud-safe tier) + `wiki-local/` (local-only tier), one unified Obsidian vault.
- **One-way permeability:** local-model runs may read both dirs; cloud-model runs MUST NOT read `wiki-local/`. (local→cloud is the leak — the forbidden direction.)
- Enforcement is a **harness/structural mechanism**, not a resident agent rule.

**Deliverables:** rewritten §2 (directory) + §13 (privacy); the `wiki/`→`wiki-cloud/` migration + `wiki-local/` scaffold; updated tooling (`check-privacy.sh`, `lint.sh`, `audit-claims.sh` FAITH-04, CI privacy-leak job); a concrete enforcement artifact set; an execution-time decision record. Covers **PRIV-01..07**.

**This phase gates Phase 16** — §13 must be rewritten to its asymmetric form before Phase 16 can extract it (PRIV-07 feeds REF-06).

**Out of scope (firm boundaries):**
- The init-wizard interactive privacy-tier prompt → **deferred to Phase D (WIZ)**. Phase 15 documents the regimes + runbook only (rationale in D-12).
- Behavioral changes to lint/validate/privacy *logic* beyond the structural model swap — extraction/rework relocates and re-keys, it does not change enforcement semantics.
- Phase 16 extraction of §13 to `schema/reference/privacy.md` (Phase 15 only rewrites §13 in place to its asymmetric form).

</domain>

<decisions>
## Implementation Decisions

### Per-page `privacy` field fate (PRIV-04) — LOCKED
- **D-01: Remove the per-page `privacy` frontmatter field entirely.** The directory is the sole classifier. Drop `privacy` from §5 base frontmatter, the §5 validation checklist, all 12 page templates, and `examples/`. The "retain as stricter-only override" variant is **rejected** (it re-introduces residual precedence the agent must honor — exactly what we're dissolving).
- **D-02: Strip everything in this phase — one clean sweep.** No half-migrated state. The "lazy strip" option is rejected: `privacy` is a §5 base field that lint's yaml check requires, so stripping it from the checklist/validator while leaving it on pages produces either a 56-page "missing required field" error storm or transitional tolerate-the-remnant logic. Pages + §5 base-field block + §5 checklist + lint yaml check + `check-privacy.sh` are **coupled — they move together (lockstep)**, with no intermediate commit where lint errors on the whole tree.
- **D-03: Sequence = route THEN strip — never strip blind.** The migration must first read each page's `privacy` to decide its destination dir (`local_only` → `wiki-local/`, else `wiki-cloud/`), THEN remove the field. Stripping before routing destroys the only record of which pages were local_only. (Creator vault: 2 audit files → `wiki-local/`, all other 54 → `wiki-cloud/`.)
- **D-04: Frontmatter-scoped tooling, NOT raw `sed`.** `privacy:` appears as prose in `AGENTS.md`/`CLAUDE.md`/`docs/` and could appear in body text — a naive `/privacy:/d` corrupts documentation. Use the existing ruamel.yaml round-trip helper `bin/lib/brownfield_yaml.py` (built for safe frontmatter mutation with comment/key-order preservation), scoped to the `---` fences.

### Directory layout & migration (PRIV-01, PRIV-02) — LOCKED
- **D-05: Rename `wiki/` → `wiki-cloud/`.** Accepted; the creator vault is effectively single-tier so the weight is schema/tooling/docs path-reference churn, not data. All `wiki/` path references (`bin/`, CI, `docs/`, `.obsidian/`, tests, index/log, `EXCLUDE_DIRS`, `PUBLIC_PATHS`) move in lockstep with D-02.
- **D-06: `wiki-local/` mirrors the convention, instantiates lazily.** There is no separate "local schema" — `wiki-local/` is a wiki: same six page types, same §2/§4 structure, so `lint`/`validate-op`/`search`/walk helpers iterate both trees with identical logic, and tier-promotion is a straight relocation (`entities/X.md` → `entities/X.md`). But subdirs are **created on demand** (no pre-created empty `entities/`, `concepts/`, … — exactly how `wiki-cloud/` itself grew). The schema documents the mirror so an agent knows `wiki-local/entities/` is the right home even before that dir exists. Full-empty-mirror option rejected (ships 6 unused empty dirs).
- **D-07: Per-tier `index.md` / `log.md` partition is a FORCED PRIV requirement (not deferred polish).** Because a cloud session cannot read `wiki-local/`: (a) `wiki-local` content cannot appear in `wiki-cloud/index.md` (cloud would need to read it to navigate → privacy violation + leaks the *existence* of private pages, which FAITH-04 already guards), and (b) a local operation cannot log into `wiki-cloud/log.md` (same existence-metadata leak). So `index.md`/`log.md` partition by tier — forced by the model. Wire the rule into PRIV-02/PRIV-05 now; the local `index.md`/`log.md` are created lazily on first navigable local content beyond the 2 control-plane files.
- **D-08: Audit control-plane → `wiki-local/maintenance/`.** `audit-report.md` + `audit-state.md` relocate to the local side. Creator vault `wiki-local/` starts as essentially just `wiki-local/maintenance/{audit-report,audit-state}.md`.
- **D-09: Asymmetric link rule (net-new lint check).** `wiki-local` → `wiki-cloud` links are fine; `wiki-cloud` → `wiki-local` links are **forbidden** (they'd be broken for cloud sessions AND leak existence). This is the structural twin of the dir-read permission; add to §8 / lint scope under PRIV-05. Fully specified; mechanics are plan-time.

### Read-leak enforcement (PRIV-03) — LOCKED (with the Area-3 git-object revision)
- **D-10: Object-level absence is the ONLY genuinely fail-closed read control.** Critical fact: **sparse-checkout hides working-tree files, not git objects.** A `git worktree` shares `.git/objects` with the main repo, so a cloud agent that can run git reconstructs "excluded" content via `git show HEAD:wiki-local/…`, `git cat-file`, `git log -p wiki-local/`. Therefore sparse-worktree is **fail-open** for *tracked* `wiki-local/` content.
- **D-11: Claude Code `deny` precedence makes the settings-deny structurally fail-open.** `deny` beats `allow`, so you **cannot** express "deny-by-default, local opt-in" via a committed `settings.json` (a committed deny would also block local sessions; a local `allow` can't override it). The deny must live in a **cloud-only per-session profile** (`.claude/settings.cloud.json`, applied via `--settings`), which means a cloud session launched *without* the flag inherits the permissive default and CAN read `wiki-local/` — the default fails open. Additional crack: a `Read(./wiki-local/**)` deny protects only the Read tool; `cat`/`grep`/`python -c open(...)` via Bash bypass it unless the harness extends Read-denies to Bash (version-dependent — **verify, don't assume**).
- **D-12: Ship the controls with HONEST labeling — do NOT ship false assurance.** Phase 15 ships:
  1. The cloud-scoped deny-profile artifact (`.claude/settings.cloud.json` with `permissions.deny: ["Read(./wiki-local/**)"]`) + launch runbook — labeled **policy/convenience, fail-open, single-clone low-stakes work only**.
  2. The separate-repo high-sensitivity pattern (D-13) — the **fail-closed guarantee**.
  3. An **honest fail-direction table** in docs (which control fails which way; rule: "real private content → fail-closed path; deny-profile is convenience").
  4. A **verification test** that a cloud-profile session is actually blocked from `Read(wiki-local/**)`, from a **Bash read**, AND from `git show HEAD:wiki-local/…` — so a future Claude Code change that loosens any path gets caught.
  - **MUST NOT:** ship the track-in-main default while claiming the sparse-worktree makes it fail-closed. That is the false-assurance trap this whole rework exists to close.

### git-tracking of `wiki-local/` (PRIV-01, two-regime) — LOCKED
- **D-13: Two proportionate regimes.**
  - **Creator default today (track-in-main, PROVISIONAL):** `wiki-local/` (scaffold + the 2 control-plane files) is **tracked in the main repo**. Rationale: the vault has zero real secrets; a `git show` "leak" of an audit report is a non-issue; and for a solo creator **data loss (dead disk, no backup) is far more probable than a cloud leak on a machine they control** — so gutting git history/backup to defend the rarer threat optimizes the wrong direction. The §11.6 orphan-branch release neutralization already strips creator `wiki/` content from the public template (post-rename: strips both `wiki-cloud/` and `wiki-local/` creator content). **Explicitly labeled provisional / low-sensitivity-only** in Phase 15 docs.
  - **High-sensitivity path (separate-repo, the documented fail-closed pattern):** when real `local_only` content arrives, `wiki-local/` becomes **its own git repo** with its own private remote, **gitignored from the parent**. Parent (`compendium`) tracks `wiki-cloud/`/schema/`bin`; `wiki-local/` objects never enter parent history → `git show` from a cloud clone/worktree finds nothing → **genuinely fail-closed**, no sparse-checkout discipline required. Also auto-excluded from public release by absence (stronger than the §11.6 EXCLUDES denylist — relies on absence, not on remembering to deny). Cost: two repos, two push targets. There is no single-history design that gives both backup AND object-level cloud isolation.
- **D-14: The separate-repo pattern PRESERVES the unified Obsidian graph.** `wiki-local/` as a **nested repo checked out inside the parent vault root** (gitignored by the parent) still appears to Obsidian as one vault on disk → graph view + piped links (`[[id|Title]]`, filename-resolved) work across both tiers, as long as the nested repo lives inside the vault directory. The two-repo pattern does **not** fragment the graph — record this so planner/docs don't assume otherwise.

### Decision record (PRIV-06) — LOCKED
- **D-15:** Author `wiki/decisions/dr-YYYY-MM-DD-privacy-asymmetric-two-dir.md` (`trigger_type: schema-update`) **at execution time** (per the uniform-piped-links precedent — not pre-written), superseding the implicit per-page §13 framing. It must record the **three options** (per-page mixed / per-vault fully separate / asymmetric two-dir) and **why asymmetric won** (dominates status quo on safety + simplicity while keeping the only synthesis direction worth having). Note the DR's own home is `wiki-cloud/decisions/` post-rename (it is cloud-safe schema reasoning).

### Resident-core reduction (PRIV-07) — LOCKED
- **D-16:** §13's resident obligation reduces to a **one-line structural pointer** in core ("vault tier is structural; cloud sessions cannot read `wiki-local/` — see `schema/reference/privacy.md`"). The fail-closed / 3-level-precedence / inheritance machinery is **removed, not relocated**. Privacy thus leaves the always-loaded safety core entirely (it is no longer in the resident MUST-list).

### Claude's Discretion
- All plan-time mechanics: exact regexes, walk order, exit codes, the `check-privacy.sh` re-key implementation, the asymmetric-link lint check implementation, CI privacy-leak job wiring, and the precise migration script structure. Stated intent (below + PRIV-05 note) is sufficient for the planner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design source of truth (privacy model + extraction map)
- `.planning/milestones/v1.2-MILESTONE-BRIEF.md` §"Phase 0 — Privacy Architecture" (lines ~50–105) — the ACCEPTED asymmetric two-dir decision, the three weighed options, enforcement rationale, migration triviality note, and the Extraction Map row for §13 (line ~193) and §2 (line ~178). This is the live design source.
- `.planning/REQUIREMENTS.md` — PRIV-01..07 requirement text (lines ~181–189) + Out-of-Scope table + traceability.
- `.planning/ROADMAP.md` §"Phase 15: Privacy Architecture" (lines ~63–77) — Goal + 5 Success Criteria (what must be TRUE).

### Schema sections being rewritten/affected (`CLAUDE.md` ≡ `AGENTS.md`, byte-identical)
- `CLAUDE.md` §2 Directory Structure — rewrite tree to `wiki-cloud/` / `wiki-local/`; update permitted-dirs + source/wiki dir rules.
- `CLAUDE.md` §13 Privacy Routing — rewrite from per-page precedence/inheritance to the asymmetric per-vault model; **remove** the 7-row decision table (not relocate).
- `CLAUDE.md` §5 Frontmatter Schema — remove the `privacy` base field + validation-checklist item #5.
- `CLAUDE.md` §8 Wikilink Conventions — add the asymmetric cross-tier link rule (cloud→local forbidden).
- `CLAUDE.md` §3 "What Agents Must NOT Do" — the `local_only`→cloud line becomes structural; reconcile with §13 rewrite.
- `CLAUDE.md` §11.6 Release (orphan-branch neutralization) — confirm it excludes both new dirs' creator content.
- `CLAUDE.md` §11.7 Audit / FAITH-04 — effective-privacy resolution under the structural model (see PRIV-05 note).

### Tooling to update (PRIV-05)
- `bin/check-privacy.sh` — currently scans `PUBLIC_PATHS` (examples/, docs/, AGENTS.md, CLAUDE.md, README.md, PRIVACY.md, .github/) for `privacy: local_only` frontmatter, **excluding `wiki/**`**. Re-key to the structural model: ensure no `wiki-local/` content appears in template-public paths / the release stage.
- `bin/lib/privacy_resolve.py` — current §13 three-level fail-closed + strictest-wins resolver; collapses to the single structural predicate (see PRIV-05 note).
- `bin/lib/brownfield_yaml.py` — the ruamel round-trip frontmatter helper to use for the `privacy`-field strip (D-04).
- `bin/audit-claims.sh` — FAITH-04 effective-privacy chokepoint consumer.
- `bin/lint.sh` — privacy-relevant checks + net-new asymmetric-link check (D-09); yaml check loses the `privacy` required-field (D-02).
- `.github/workflows/lint.yml` — the `privacy-leak` CI job (currently `bash bin/check-privacy.sh`, required check).
- `.claude/settings.json` — current minimal (`enabledPlugins` only); target of the cloud deny-profile artifact (`.claude/settings.cloud.json`, D-12).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/lib/brownfield_yaml.py` (19.8 KB) — ruamel.yaml round-trip frontmatter mutation with comment/key-order preservation. The correct tool for the `privacy`-field strip; avoids the prose-corruption risk of `sed`.
- `bin/lib/privacy_resolve.py` (4.3 KB) — current §13 three-level + strictest-wins effective-privacy resolver. Being **simplified** (not extended) under PRIV-05.
- `bin/check-privacy.sh` (5.1 KB) — existing public-path leak guard with hardcoded `PUBLIC_PATHS` (D-15 in that script) and `wiki/**` exclusion. Re-keyed, not rebuilt.
- §11.6 orphan-branch release neutralization — already strips creator `wiki/` content from the public template; extends to both new dirs by absence/path.

### Established Patterns
- **Creator vault is single-tier:** 54 pages `cloud_safe`, exactly 2 `local_only` (`wiki/maintenance/audit-{report,state}.md`, script-generated control-plane). Migration is light on data, heavy on schema/tooling/docs path churn.
- **`CLAUDE.md` ≡ `AGENTS.md` byte-equality** enforced by pre-commit `sync-claude --check` — every §2/§5/§8/§13 edit lands in both.
- **DR-at-execution precedent** (`dr-2026-06-03-uniform-piped-links`) — schema-update decision records are written when the change ships, not pre-authored.
- **Lint EXCLUDE_DIRS / examples path-prefix exemptions** — the established way tooling scopes which trees it walks; both new dirs slot into the same pattern.

### Integration Points
- The `wiki/`→`wiki-cloud/` rename touches every hardcoded `wiki/` path across `bin/`, `.github/`, `docs/`, `.obsidian/`, tests, and the wiki's own `index.md`/`log.md` — all in the single lockstep commit (D-02/D-05).
- The asymmetric-link lint check (D-09) plugs into the existing `linkres`/`orphan` link-resolution machinery from Phase 14 (LINT_VERSION 1.6.0).

</code_context>

<specifics>
## Specific Ideas

- **PRIV-05 planner sharpening (so the planner doesn't rebuild the wrong thing):**
  - **FAITH-04 effective-privacy collapses to a single structural predicate:** a claim is effective-`local_only` **iff its page OR any contributing source lives under `wiki-local/`**. Do **NOT** port the §13 three-level precedence ladder — it is gone with the per-page field.
  - **`check-privacy.sh` re-keys** from "scan frontmatter for `privacy: local_only`" to "ensure no `wiki-local/` content appears in template-public paths / the release stage."
  - The asymmetric-link lint check (D-09, cloud→local forbidden) is net-new but fully specified above; mechanics (regex, walk, exit codes) are plan-time.
- **Enforcement artifact concreteness (PRIV-03):** Success Criterion #3 demands a *concrete artifact*, not prose — ship the actual `.claude/settings.cloud.json` deny entry AND the separate-repo runbook, plus the fail-direction table and verification test (D-12).
- **Honest-contract principle (overarching):** the phase's own purpose is to close an irreversible-leak gap; it must not itself ship false assurance. Every enforcement claim is labeled with its true fail direction.

</specifics>

<deferred>
## Deferred Ideas

- **init-wizard interactive privacy-tier prompt → Phase D (WIZ).** Phase 15 DOCUMENTS the two regimes + the separate-repo runbook; the interactive "track-in-main vs separate-repo" prompt is **deferred to Phase D**. Rationale: the creator vault is single-tier with zero real `local_only` content (no prompt needed — defaults to the provisional track-in-main regime); the choice only bites for a high-sensitivity adopter (observation-gated, Phase D territory); and implementing a wizard prompt in Phase 15 would collide with both Phase D and the v1.2 extraction phases already mutating `bin/init-wizard.sh` (three phases touching one file). Add a **forward-reference in the PRIV notes** so Phase D inherits it. Keeps Phase 15 = architecture, not adoption UX.

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` ("Harden `bin/lint.sh` mask_markdown for fence edge cases", area: tooling, match score 0.9) — **reviewed, NOT folded.** The match is a keyword-only hit ("bin"/"lint"); it is Phase-14 lint markdown-masking residue (WR-02/03), semantically unrelated to privacy architecture. Belongs to the lint workflow extraction (Phase 17) or a standalone quick task. Remains in `.planning/todos/pending/`.

</deferred>

---

*Phase: 15-privacy-architecture*
*Context gathered: 2026-06-04*

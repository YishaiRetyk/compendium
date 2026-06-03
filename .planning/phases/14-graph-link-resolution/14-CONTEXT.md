# Phase 14: Graph Link Resolution - Context

**Gathered:** 2026-06-02 · **Re-gathered (premise corrected):** 2026-06-03
**Status:** Ready for re-planning

> ⚠️ **This CONTEXT.md was rewritten after the original Phase 14 premise was proven false.**
> The original approach (self-aliases) and the requirements LINK-01..10 / ROADMAP success
> criteria are all built on the incorrect claim that "Obsidian resolves `[[X]]` by filename +
> aliases." See `.planning/phases/14-graph-link-resolution/14-FINDINGS-premise-invalidated.md`
> for the full evidence chain. The decisions below SUPERSEDE the original CONTEXT and drive a
> rewrite of LINK-01..10 (see D-09).

<domain>
## Phase Boundary

Make the Obsidian graph actually connect — for real this time, on the correct premise.

**Corrected premise (the root cause):** Obsidian's link resolver matches `[[X]]` **only against
filenames/paths — NEVER against the `aliases` frontmatter** (intentional design, confirmed by an
Obsidian moderator for v1.12.7; sources in canonical_refs). Aliases only power Quick Switcher /
autocomplete and serve as *display text* in piped links `[[file|Alias]]`. So the shipped self-alias
work (14-01/02/03) does **not** connect the graph; the ~19 multi-word-title pages stay orphaned.

**The fix (locked this discussion):** adopt **uniform piped links** `[[id|Title]]` — every
intra-wiki body link targets the page `id` (which equals the filename, so it always resolves in
stock Obsidian) and uses the human-readable `title` as display text. No plugin, no dependency,
clean reading-view display, mechanically enforceable.

This phase now:
1. **Corrects the convention** — `CLAUDE.md`/`AGENTS.md` §8 + §5 + `schema/templates/*.md` +
   `schema/obsidian/*.md` state the REAL rule (`[[X]]` resolves by filename/path only) and mandate
   the uniform piped-link form; the self-alias invariant is REMOVED; a corrected `schema-update`
   decision record supersedes the wrong one.
2. **Enforces it** — `bin/lint.sh`'s `linkres` category is re-pointed to validate that every
   intra-wiki link *target* resolves to a known page `id`; `--fix` rewrites bare `[[X]]` →
   `[[id|X]]` for unique matches; CI gates it.
3. **Remediates the data** — all `wiki/` + `examples/` body links are rewritten to uniform piped
   form; the connected graph is human-verified in Obsidian.

**Out of scope (LOCKED):** renaming wiki files to titles; bundling an Obsidian plugin (rejected this
discussion — see D-01; "plugin distribution" stays v1.2-deferred per PROJECT.md); shipping
`.obsidian/` config in the template; near-duplicate page detection (already delivered as the
`duplicate` category); the v1.2 schema refactor (backlog 999.4).
</domain>

<decisions>
## Implementation Decisions

### Area 1 — Resolution mechanism (THE core decision)

**D-01 — Mechanism = uniform piped links `[[id|Title]]` (Option A).** Every intra-wiki body link's
target is the page `id` (== filename → always resolves in stock Obsidian); the display text is the
exact canonical `title`. Chosen over the three alternatives:
- **Bare `[[Title]]` + self-aliases** — REJECTED: does not resolve (the root cause). Obsidian
  ignores `aliases` for bare-link resolution.
- **Bundle an Obsidian resolver plugin** — REJECTED: violates CLAUDE.md §1 ("functions as plain
  markdown regardless of tooling"); depends on an undocumented internal API
  (`metadataCache.uniqueFileLookup`) that breaks on Obsidian updates; "Obsidian plugin
  distribution" is v1.2-deferred per PROJECT.md; ships executable JS into a cloned template.
- **Bare slug `[[id]]`** — REJECTED: resolves, but Obsidian shows the raw slug in reading view
  (unreadable); already rejected in the prior DR.

**D-02 — Scope = UNIFORM (unconditional).** EVERY intra-wiki link is piped, including single-word-
title pages (`[[backpressure|Backpressure]]`). Chosen over "minimal" (pipe only links that don't
filename-resolve) because:
- The §8 rule becomes **unconditional** — agents never evaluate a per-link condition (reliable for
  an LLM-authored wiki).
- `linkres` collapses to a trivial exact-match: "is the target before `|` a known page `id`?" — no
  normalization on the gating path.
- It **eliminates the variant problem entirely** (old LINK-08): because display text is cosmetic,
  `[[bounded-context|Bounded Contexts]]` (plural) and `[[hack-agentive-stack|Hack (Agentive Stack)]]`
  resolve with zero reconciliation. Plural/parens/casing become free prose.
- Regression-proof: resolution is on the stable `id`; a title change can never re-orphan a link.
- Costs (more verbose source, larger rewrite diff) are paid once, by a script, in source that
  agents don't mind and humans never see (reading view shows the clean title).

### Area 2 — Convention rewrite (§8/§5/templates)

**D-03 — Invert §8 and drop the self-alias invariant.**
- Correct the false resolution claim everywhere: `[[X]]` resolves by **filename/path ONLY**, not by
  `title` and not by `aliases`.
- Replace §8's "DO NOT use display aliases" prohibition with the new mandate: **ALWAYS write
  `[[id|Exact Title]]`** (target = page `id`; display = exact canonical title). Update the §8
  bad/good examples accordingly.
- **Remove** the self-alias invariant from §5 checklist, §8, and `schema/templates/*.md` +
  `schema/obsidian/*.md` — its rationale (help resolution) is gone, so mandating `title,id ∈ aliases`
  would be misleading. (`aliases` remains an OPTIONAL field for genuine alternate names /
  Quick-Switcher / Dataview — not required, not self-referential by mandate.)
- `AGENTS.md` stays byte-identical to `CLAUDE.md` (pre-commit sync).

### Area 3 — Enforcement re-point (`linkres` + `--fix`)

**D-04 — `linkres` re-pointed to validate link targets, not self-aliases.** Per intra-wiki link:
| Case | Classification |
|---|---|
| Piped `[[id\|...]]` and `id` is a known page | **OK** |
| Bare `[[X]]` (no pipe) | **linkres error** — must be piped (`--fix` can repair if unique match) |
| Piped `[[target\|...]]` and `target` is NOT a known `id` | **linkres error** (broken target) |
| Target is a deliberate not-yet-existing `id` (knowledge gap) | **`gap` (info), NOT `linkres`** — red links stay allowed per §3 |

No D-02-style normalization is needed on the gating path (exact `id` match). The `orphan` check is
still reconciled to stop using `title` as a resolver (it must resolve by `id`/filename only).

**D-05 — `--fix` re-pointed to rewrite bare links to piped form.** Mechanical + idempotent:
rewrite bare `[[X]]` → `[[id|X]]` where `X` **uniquely** maps to a page (by `id`, `title`, alias,
or the conservative normalized match). Preserve the original `X` as display text. If `X` matches no
page → leave it (knowledge-gap red link, `gap`). If `X` matches multiple → leave it, emit a warning
for manual disambiguation. The old D-02 normalization survives ONLY as the *matcher* that finds the
unique target during `--fix`; it no longer gates resolution.

**D-06 — Variant reconciliation (old LINK-08) is DISSOLVED, not performed.** Under uniform piped
links the plural/parens/casing variants are display-only and resolve fine. No Wave-2 variant-
judgment remediation is needed. (`[[Bounded Contexts]]` → `[[bounded-context|Bounded Contexts]]`,
keeping the plural display, is a valid resolved link.)

### Area 4 — Disposition of the already-shipped (wrong-premise) work

**D-07 — Self-aliases: keep, demote.** The 53 self-aliases 14-03 added are harmless and mildly
useful (Quick Switcher fuzzy, Dataview). KEEP them, but they are no longer required, mandated, or
backfilled. (Optional: a follow-up could strip them for cleanliness — not required by this phase.)

**D-08 — Decision record: supersede.** Author a NEW `schema-update` DR that SUPERSEDES
`dr-2026-06-02-obsidian-filename-alias-resolution` (which documents the wrong premise). The new DR
states: the real Obsidian resolution rule (filename/path only), the uniform-piped-link decision,
and the rejected alternatives (self-aliases [don't resolve], plugin [dependency/fragility/v1.2],
bare slug [unreadable], rename files [breaks `id == filename`/provenance]). Set `supersedes` /
`superseded_by` per §9.

**D-09 — Requirements + ROADMAP MUST be rewritten before/at planning.** LINK-01..10 and the Phase 14
success criteria/goal in ROADMAP.md currently encode the false "filename + aliases" premise (e.g.
LINK-01 "[[X]] resolves by filename + aliases"; LINK-02 the self-alias invariant). They must be
rewritten to the piped-link reality:
- LINK-01 → §8/§5 state `[[X]]` resolves by filename/path ONLY; mandate uniform `[[id|Title]]`.
- LINK-02 → templates/checklist ship the piped-link convention; self-alias invariant REMOVED.
- LINK-03 → the superseding DR (D-08).
- LINK-04/05/06 → `linkres` validates link targets resolve to a known `id`; `--fix` rewrites bare→piped; `orphan` reconciled.
- LINK-07/08/09 → all `wiki/` + `examples/` links rewritten to uniform piped form (LINK-08 variant work is dissolved per D-06).
- LINK-10 → human-verify the connected graph (unchanged in spirit; the exemplar `domain-driven-design.md` connects via piped inbound links).
Recommend updating `.planning/REQUIREMENTS.md` + the ROADMAP Phase 14 block as the first re-plan action (or via `/gsd-phase`), so the planner reads correct locked inputs.

### Claude's Discretion
- Exact `bin/lint.sh` re-point of the `linkres` resolver + `--fix` rewriter (reuse the existing
  category wiring, severity remap, `--category`/`--skip-category`, tests, and `resolution_map`);
  `LINT_VERSION` bump (already at 1.5.0 from the prior run — MINOR bump as needed).
- Whether the data rewrite runs as `bin/lint.sh --fix` or a one-shot migration script (both are
  mechanical; `--fix` is preferred for idempotent re-runnability).
- Exact §8 prose, the §5 edit, the bad/good examples, and the template wording (neutrality §3:
  placeholders only in template-public files).
- The superseding DR slug + `affected_pages`.
- Test decomposition (bare-link error, unknown-target error, unique-match `--fix`, multi-match
  warning, knowledge-gap exclusion, CI strict stays green).
- Whether to strip the now-vestigial self-aliases (D-07) or leave them.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Corrected-premise inputs (READ FIRST)
- `.planning/phases/14-graph-link-resolution/14-FINDINGS-premise-invalidated.md` — the full evidence
  chain, what's now wrong in 14-01/02/03, and the viable fixes. The authority for this re-plan.
- Obsidian behavior sources: https://obsidian.md/help/aliases (alias = display text, not a link
  target) · https://forum.obsidian.md/t/wikilink-resolution-does-not-honor-frontmatter-aliases-1-12-7/113902
  (official "intentional design" confirmation for v1.12.7).

### Requirements & roadmap (MUST be rewritten — see D-09)
- `.planning/REQUIREMENTS.md` — LINK-01..10 (currently premise-wrong).
- `.planning/ROADMAP.md` §"Phase 14: Graph Link Resolution" — goal + 4 success criteria (currently premise-wrong).

### Schema surfaces to edit (convention correction)
- `CLAUDE.md` §8 "Wikilink and Graph Conventions" — invert "no display aliases" → mandate
  `[[id|Title]]`; correct the resolution claim to filename/path only.
- `CLAUDE.md` §5 — `title` field description + frontmatter validation checklist: remove the
  self-alias invariant items added by 14-01; correct the `title` resolution note.
- `AGENTS.md` — byte-identical to `CLAUDE.md` (`.githooks/pre-commit` via `bin/sync-claude.sh --check`).
- `schema/templates/*.md`, `schema/obsidian/*.md` — drop the self-alias block (14-01 added one);
  reflect the piped-link convention.
- `schema/AGENTS.template.md` — mirror §5/§8/§11.3 edits (the §5 parity test in tests/phase-10 gates this; see commit 016abe4 for the parity-mirroring precedent).

### Enforcement surfaces
- `bin/lint.sh` (`LINT_VERSION="1.5.0"` after the prior run) — `linkres` category already exists
  (added 14-02) but validates self-aliases; re-point it to validate link *targets*; reconcile
  `orphan` to id-only resolution; `--fix` rewrites bare→piped.
- `tests/phase-09/test_lint_linkres.sh` + `test_lint_require_version.sh` — re-point tests.
- `.github/workflows/lint.yml` `strict` job — stays green.
- `docs/reference/ci.md` + `CLAUDE.md` §11.3 — keep the `linkres` severity-remap row aligned.

### Data to remediate
- `wiki/` (49 pages) + `examples/kahneman/` + `examples/dataview-fixtures/` — rewrite body links to
  `[[id|Title]]`. The 53 self-aliases already present (14-03) stay (D-07).
- `wiki/overviews/domain-driven-design.md` — the LINK-10 human-verify exemplar.

### Convention guards
- `CLAUDE.md` §1 / §15 — "plain markdown regardless of tooling" (the decisive argument against the
  plugin option, D-01).
- `CLAUDE.md` §3 "Red Links" — `linkres` MUST NOT flag deliberate knowledge-gap red links (target
  is a not-yet-existing `id`); they stay in `gap`.
- `CLAUDE.md` §3 neutrality — template-public files use placeholders, never real vault terms.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable / salvageable assets (from the prior, wrong-premise run — re-point, don't discard)
- **`linkres` category in `bin/lint.sh`** (added 14-02, commit d1edb27) — full category wiring,
  `--category`/`--skip-category`, CI severity remap (`linkres → error`), `LINT_VERSION 1.5.0`,
  11-case test file. Re-point its resolver from "self-alias present" to "link target resolves to a
  known id"; the `--fix` path flips from self-alias backfill to bare→piped rewrite.
- **`resolution_map` builder** — lowercased `{id, title, aliases} → page id`. Still the anchor for
  the `--fix` *matcher* (find the unique target for a bare link). The gating check now needs only
  the `id` set.
- **`016abe4` parity-mirroring precedent** — when editing `CLAUDE.md`/`AGENTS.md` §5/§8/§11.3, mirror
  into `schema/AGENTS.template.md` (the tests/phase-10 §5 parity test + tests/phase-09.1 §4/§16
  parity tests gate this).

### Established patterns
- `AGENTS.md ↔ CLAUDE.md` byte-equality (`.githooks/pre-commit`); every CLAUDE.md edit mirrored +
  `bin/sync-claude.sh`.
- CI severity remap (§11.3 = source of truth): `linkres → error`, `--ci` exit 1 iff any post-remap error.
- Deterministic `--fix` (mechanical) vs human judgment seam (Phase 13 D-14, §11.3): bare→piped
  rewrite is mechanical (unique match); multi-match disambiguation is the only judgment residue.

### Integration points / hazards
- The prior run left main with: the 53 self-aliases (keep, D-07), the wrong-premise §8/§5/DR/templates
  (correct them), and `linkres`-as-self-alias-check (re-point). Plan must MIGRATE, not greenfield.
- Pre-existing test debt (NOT this phase's): 8 canonical-AGENTS byte-equality fixtures already red
  before Phase 14 (the post-milestone `duplicate`-category quick task diverged them); re-planning
  should not assume those were green.
</code_context>

<specifics>
## Specific Ideas

- **`domain-driven-design.md` is the LINK-10 exemplar** — its 10 inbound `[[Domain-Driven Design]]`
  links must become `[[domain-driven-design|Domain-Driven Design]]` (and its outbound links piped)
  for it to connect.
- **`Hack (Agentive Stack)` and `Bounded Contexts` are no longer "problems"** — under uniform piping
  they're `[[hack-agentive-stack|Hack (Agentive Stack)]]` and `[[bounded-context|Bounded Contexts]]`;
  the parens/plural live in the (cosmetic) display text and resolve fine. This is the concrete proof
  that D-02 dissolves the old variant layer.
- **The convention is now an unconditional contract** — "every intra-wiki link is `[[id|Exact Title]]`"
  — which is exactly the kind of machine-checkable rule the prior (conditional, alias-dependent)
  approach lacked.
</specifics>

<deferred>
## Deferred Ideas

- **Bundle an Obsidian resolver plugin** — rejected this discussion (D-01); aligns with the existing
  v1.2-deferred "Obsidian plugin distribution" boundary in PROJECT.md. If stock-Obsidian piped links
  ever prove insufficient, revisit in v1.2 — not here.
- **Stripping the vestigial self-aliases** (D-07) — optional cleanup; left as residue, not required.
- **v1.2 schema progressive-disclosure refactor (backlog 999.4)** — still correctly sequenced AFTER
  this phase (§8 must be true before it moves).
- **Auto-rewrite of *display text*** (e.g., normalizing plural display) — explicitly NOT done;
  display text is free prose under uniform piping (D-06).
</deferred>

---

*Phase: 14-graph-link-resolution*
*Context re-gathered (premise corrected): 2026-06-03*

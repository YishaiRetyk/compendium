# Phase 14: Graph Link Resolution - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the Obsidian graph actually connect. Obsidian resolves `[[X]]` by **filename stem + `aliases`**, never by the `title` frontmatter. Pages are slug-named (`domain-driven-design.md`) but linked by spaced `[[Domain-Driven Design]]` with no matching alias, so 31/49 pages render as orphans. This phase:

1. **Corrects the convention** — `CLAUDE.md` §8 + §5 checklist + `schema/templates/*.md` + `schema/obsidian/*.md` state the real resolution rule and mandate the self-alias invariant (`title`, `id` ∈ `aliases`); a `schema-update` decision record is authored; `AGENTS.md` stays byte-identical.
2. **Enforces it** — `bin/lint.sh` gains a `linkres` category (CI-gating for high-confidence defects), `--fix` backfills self-aliases idempotently, and the existing `orphan`/`gap` checks are reconciled to Obsidian-accurate resolution.
3. **Remediates the data** — all `wiki/` + `examples/` pages get self-aliases; link-text variants are reconciled (Wave 2, human-reviewed); the connected graph is human-verified in Obsidian.

Requirements **LINK-01..10 are LOCKED** (see `.planning/REQUIREMENTS.md`). This discussion captures only the HOW for the judgment-bearing parts. **Out of scope (LOCKED):** renaming wiki files to spaced titles; rewriting body links to slug form; shipping `.obsidian/` config in the template; near-duplicate page detection (already delivered as the `duplicate` category); the v1.2 schema refactor (backlog 999.4).

</domain>

<decisions>
## Implementation Decisions

### Area 1 — `linkres` classification: what counts as a gateable defect

**D-01 — `linkres` gates only deterministic, high-confidence graph defects.** The check classifies every intra-wiki state into exactly one bucket, and only the high-confidence buckets are `linkres` errors. True knowledge-gap red links are **excluded from `linkres`** and stay in the informational `gap` category — this is what makes `linkres` safe to gate CI.

| Case | Classification |
|---|---|
| `[[X]]` resolves by Obsidian rules (filename stem OR an alias) | **OK** |
| A page's own `title` or `id` is not reachable through filename or aliases | **linkres bug → error** |
| `[[X]]` does not resolve, but normalized `X` **uniquely** matches an existing page title/id/alias | **linkres bug → error** |
| `[[X]]` does not resolve, normalized match finds **multiple** pages | **linkres ambiguous → warning** (manual triage, NOT CI error) |
| `[[X]]` does not resolve, **no** normalized match | **intentional red-link candidate → handled by `gap`, NOT `linkres`** |

**D-02 — Normalization algorithm for the gating path (deterministic, conservative).** Applied to both link text and candidate page title/id/alias before comparison:
1. casefold
2. replace punctuation, hyphen, underscore, and parentheses **characters** with spaces — strip the *characters*, NOT the parenthetical *content* (`Hack (Agentive Stack)` → `hack agentive stack`, not `hack`)
3. collapse whitespace
4. conservative singular variants only: `contexts → context`, `policies → policy`, `contracts → contract` (a small, explicit pluralization map — not a general stemmer)
5. **NO** word reordering, **NO** synonym matching, **NO** substring-only matching
6. **NO edit distance on the gating path.** Edit distance stays in the existing `duplicate` category; using it for `linkres` would make CI harder to trust. A unique normalized match is the only fuzzy admission, and it must be *unique*.

**D-03 — Reconcile `orphan` and `gap` to Obsidian-accurate resolution (LINK-06).**
- `orphan` MUST stop using `title` as a resolver (it currently masks unresolved links by treating title-matched links as inbound edges).
- `gap` should also switch to Obsidian-accurate resolution, but `gap` **remains informational** (the no-match red-link candidates live here).
- Net effect: a should-resolve link is no longer hidden by orphan's title-based matching; it surfaces as a `linkres` error (unique match) or `linkres` warning (ambiguous).

### Area 2 — Severity & CI gating

**D-04 — `linkres` is CI-gating (`error` in `--ci` remap) for high-confidence defects only.** Not "all unresolved links are errors" — only "this link should resolve under our own page inventory and does not."
- page `title`/`id` unreachable via filename/alias → **error**
- unresolved body link with a **unique** normalized match → **error**
- unresolved body link with **multiple** normalized matches → **warning** (manual triage)
- unresolved body link with **no** normalized match → not `linkres`; stays `gap` info

**D-05 — Do NOT split title-unreachable (error) vs link-variant (warning).** Rejected the "title=error / variant=warning" tiering: after the unique-normalized-match rule, a unique variant *is* a real graph-integrity defect. Leaving it warning-only would fix today's data but let the same breakage recur — Phase 14 must *prevent regression*, not just clean up. Both gate as errors; only genuinely ambiguous (multi-match) candidates degrade to warning.

### Area 3 — `--fix` scope (LINK-06)

**D-06 — `--fix` repairs self-aliases ONLY; it never rewrites body links.** Strictly mechanical and idempotent:
- ensure `aliases` exists
- add `title` if missing
- add `id` slug if missing
- preserve all existing aliases
- idempotent (re-running is a no-op)
- **do NOT rewrite body links** — even a unique-normalized-match rewrite (`[[Bounded Contexts]]` → `[[Bounded Context]]s`, or a sentence rephrase) is *editorial*, not mechanical.

This keeps the deterministic/judgment seam clean (cf. Phase 13 D-14, §11.3): `--fix` repairs page *reachability* (mechanical); humans/agents reconcile *prose* (judgment).

### Area 4 — Variant reconciliation direction (LINK-08, Wave 2)

**D-07 — Variant link reconciliation is human-reviewed Wave 2 remediation, NOT auto-fix.** Classification (Area 1) is deterministic; remediation must *preserve the wiki's authoring conventions* (§8 "exact canonical title", readable prose). Triage case-by-case with an explicit default rule, decision recorded in the plan/summary:

| Variant type | Remediation |
|---|---|
| Plural/singular only | **Edit link text**, keep the `s` outside: `[[Bounded Context]]s` |
| Casing / spacing / punctuation drift | **Edit link text** to canonical title |
| Parenthetical title that is *already* the canonical title | **Add self-alias** (LINK-02), not call-site churn |
| Real alternate name / acronym / common name | **Add alias** |
| Ambiguous variant | **Leave for manual decision**, document in summary |

**D-08 — Default direction = edit the call site for mechanical variants; aliases only for genuine alternate names.** `[[Bounded Contexts]]` → edit to `[[Bounded Context]]s`, NOT a plural alias. Aliases must stay *meaningful* — they are not a garbage drawer for every grammatical form. The link text becomes the truth for typos/plurals/casing; aliases capture real alternate names/acronyms.

### Claude's Discretion
- Exact `bin/lint.sh` code structure for the `linkres` category (function decomposition, where the shared resolution map / normalization helper lives — likely reused by the reconciled `orphan` + `gap` checks), the `LINT_VERSION` bump (MINOR — new non-breaking category), and the `--category linkres` / `--skip-category linkres` wiring.
- Exact prose/placement of the §8 rewrite and the §5 checklist `title ∈ aliases` item, and the self-alias wording in `schema/templates/*.md` + `schema/obsidian/*.md` — must follow neutrality rules (§3 template-public files: use placeholders, not real vault terms).
- The decision-record slug + `affected_pages` for the LINK-03 `schema-update` DR.
- Test decomposition under `tests/` (must cover: title-unreachable error, unique-match error, multi-match warning, no-match→gap exclusion, `--fix` idempotency, CI strict stays green).
- Whether the small pluralization map (D-02 step 4) is a literal dict or a tiny rule set — but it MUST stay explicit/conservative, not a general stemmer.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap (LOCKED inputs)
- `.planning/REQUIREMENTS.md` — LINK-01..10 definitions, in-scope/out-of-scope, traceability table.
- `.planning/ROADMAP.md` §"Phase 14: Graph Link Resolution" — goal, success criteria (4), non-goals, suggested plan shape (~3 plans / 2 waves).

### Schema surfaces to edit (convention correction — Wave 1)
- `CLAUDE.md` §8 "Wikilink and Graph Conventions" — the false "Wikilinks resolve to this `title` value" claim lives here (and in §5 `title` field description: "Wikilinks resolve to this value"); both must be corrected to filename + aliases.
- `CLAUDE.md` §5 "Frontmatter Validation Checklist" — gains a `title ∈ aliases` (and `id ∈ aliases`) item.
- `AGENTS.md` — MUST stay byte-identical to `CLAUDE.md` (enforced by `.githooks/pre-commit` sync check via `bin/sync-claude.sh --check`).
- `schema/templates/*.md` — page templates ship the self-alias.
- `schema/obsidian/*.md` — Obsidian-facing schema docs reflect the resolution rule.
- `bin/sync-claude.sh` — `--check` must stay clean after edits.

### Enforcement surfaces (Wave 1)
- `bin/lint.sh` (2209 lines, `LINT_VERSION="1.4.0"`) — add `linkres` category; reconcile `orphan` + `gap`; severity-remap dispatch table (~line 313, `'orphan': 'error'`); the existing `resolution_map` builder (already collects id/title/aliases lowercased) is the reuse anchor; `--category` / `--skip-category` arg parsing (~line 120–160).
- `.github/workflows/lint.yml` — the `strict` job must stay green; confirm `linkres` error mapping doesn't break it.
- `docs/reference/ci.md` — CI severity policy doc; update if `linkres` is added to the remap table (CLAUDE.md §11.3 "CI mode" is the source of truth for the remap table — keep them aligned).

### Data to remediate (Wave 2)
- `wiki/` (49 pages) — self-alias backfill (LINK-07) + variant reconciliation (LINK-08). Known variant offenders: `[[Domain-Driven Design]]`, `[[Hack (Agentive Stack)]]`, `[[Bounded Contexts]]`.
- `examples/kahneman/` + dataview-fixtures (LINK-09) — self-aliases respecting `example: true` / lint-skip.
- `wiki/overviews/domain-driven-design.md` — the canonical orphan exemplar for LINK-10 human-verify.

### Prior-art / convention guards
- `CLAUDE.md` §3 "Red Links" — red links are allowed/intentional; `linkres` MUST NOT flag no-match red links (they stay in `gap`).
- `CLAUDE.md` §3 "What Agents Must NOT Do" — neutrality rule for template-public files (`CLAUDE.md`, `AGENTS.md`, `schema/`, `bin/`): use abstract placeholders, never real vault terms, in edited prose/examples.
- `.planning/phases/13-claim-faithfulness-audit/13-CONTEXT.md` D-14 — the deterministic-auto-fix vs report-only-judgment seam this phase mirrors.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`resolution_map` in `bin/lint.sh`** — already builds a lowercased map of `{id, title, aliases} → page id`. This is the natural anchor for both the new `linkres` resolver and the reconciled `orphan`/`gap` checks. The normalization step (D-02) extends this map with normalized keys.
- **Severity-remap dispatch table** (~line 313) — `linkres` slots in as `'linkres': 'error'` alongside `orphan`/`crossref`/`provenance`/`yaml`.
- **`duplicate` category (LINT_VERSION 1.4.0, quick task 260602-d6a)** — already does Levenshtein/substring near-dup *page* detection. `linkres` slots in *alongside* it but is distinct (link/title resolution mismatch, not near-dup pages). Edit distance stays in `duplicate`; `linkres` deliberately avoids it (D-02).
- **`--category` / `--skip-category` machinery** — `linkres` registers as a valid value in both.

### Established Patterns
- **Deterministic/judgment seam** (§11.3, Phase 13 D-14): mechanical auto-fix categories vs report-only-needs-judgment. `linkres --fix` = mechanical (self-alias backfill); LINK-08 variant reconciliation = judgment (Wave 2, manual).
- **CI severity remap** (§11.3 "CI mode" = source of truth): categories map to error/warning; `--ci` exit 1 iff any post-remap `error`. `linkres → error`.
- **`AGENTS.md ↔ CLAUDE.md` byte-equality** enforced by `.githooks/pre-commit`; every CLAUDE.md edit must be mirrored.
- **LINT_VERSION semver discipline** — new non-breaking category = MINOR bump (1.4.0 → 1.5.0); tests pin versions.

### Integration Points
- `linkres` → severity-remap table → `--ci` exit code → `.github/workflows/lint.yml` `strict` job.
- `linkres --fix` → frontmatter `aliases` write (idempotent) → must not perturb `orphan`/`gap`/`duplicate` outputs.
- Reconciled `orphan` resolver → stops masking unresolved links → those links surface in `linkres`/`gap`.

</code_context>

<specifics>
## Specific Ideas

- **`Hack (Agentive Stack)` normalization is the litmus test** — strip the *parenthesis characters*, not the parenthetical *content*: normalizes to `hack agentive stack`. A naive "strip parens content" implementation would wrongly collapse it to `hack` and mismatch. The plan/tests must lock this.
- **`[[Bounded Contexts]]` is the canonical LINK-08 worked example** — remediation = edit link text to `[[Bounded Context]]s` (plural-`s` outside the link), NOT a plural alias.
- **`domain-driven-design.md` is the LINK-10 human-verify exemplar** — `id: domain-driven-design`, `title: "Domain-Driven Design"`, no self-alias today → `[[Domain-Driven Design]]` (used in `index.md`, `log.md`, `programming-as-theory-building.md`, `ubiquitous-language.md`) is an orphaned unique-match defect. After self-alias backfill it must connect.
- **"Prevent regression, not just clean data"** is the framing test for severity (D-05): if a fix path leaves the same breakage able to recur, it's under-scoped.

</specifics>

<deferred>
## Deferred Ideas

- **Auto-rewrite of body-link variants** — explicitly rejected for `--fix` (D-06); it's editorial. Stays human-reviewed Wave 2 work. Not a future phase, just a permanent boundary.
- **Synonym / edit-distance / substring matching for `linkres`** — deliberately excluded (D-02) to keep CI trustworthy. Edit distance remains the `duplicate` category's job.
- **General stemmer for pluralization** — rejected in favor of a small explicit map (D-02 step 4). If the map proves insufficient at scale, revisit later — but not by reaching for a general stemmer that re-introduces false positives.
- **v1.2 schema progressive-disclosure refactor (backlog 999.4)** — moves §8 et al. into `schema/reference/`; correctly sequenced *after* this phase (§8 must be true before it moves).

None of the above is scope creep into this phase — all four are boundary confirmations.

</deferred>

---

*Phase: 14-graph-link-resolution*
*Context gathered: 2026-06-02*

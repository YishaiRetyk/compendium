# Phase 999.4 — v1.2 Schema Architecture: Progressive Disclosure Refactor (BACKLOG)

> **Comprehensive context note captured 2026-04-16 from a design thread.**
> This document is pre-planning context. It is NOT a plan. Use `/gsd-discuss-phase 999.4` when ready to promote, then `/gsd-plan-phase` to structure it into atomic plans.

## Problem Statement

`AGENTS.md` / `CLAUDE.md` is currently **1,412 lines** (post-Phase 09.1 extraction of worked examples and Appendices A/B). It is loaded into agent context on every turn. Every line costs context permanently, and the file is now dominated by procedural workflows, schema reference tables, and validation checklists — material that is only relevant during specific operations, not always.

The project's own §7 ("Progressive Disclosure") applies this principle to *wiki pages* but the spec itself violates it. Phase 09.1 cut the easy ~21% (≈373 lines: 6 worked examples + 2 appendices). The remaining ~79% is the strategic extraction.

## Why This Is A Milestone, Not A Phase

- **Scope mismatch with v1.1.** v1.1 "Shareability" is scoped to external adoption (neutral template, two-track setup, brownfield onboarding, CI gates). Phases 10–12 are roadmap-locked for brownfield + docs finalization. A structural refactor of the authoritative schema is a different theme.
- **Three distinct phases.** Reference extraction, workflow extraction, and optional skills overlay are each substantive work with their own discussion surfaces and risk profiles.
- **v1.1 is close to shipping.** Inserting schema refactor phases stretches v1.1. Milestone isolation protects the ship.
- **Phase 09.1 was tactical; this is strategic.** 09.1 extracted what could be cut cleanly under v1.1. The remainder is a deliberate architecture shift.

**Verdict: v1.2 milestone titled "Schema Architecture" (working title).**

Acceptable alternative: one narrow Phase 09.2 doing only the reference split (Phase A below), deferring workflows and skills to v1.2. Phase A alone captures ~50–60% of the reduction at low risk.

## Design Constraints (Non-Negotiable)

- **Markdown-authoritative.** All canonical behavior lives in plain markdown readable by any harness. Claude Code is the MVP runtime; Codex/Cursor/others are future first-class consumers.
- **Byte-equality preserved.** `AGENTS.md` ≡ `CLAUDE.md` via `.githooks/pre-commit` → `bin/sync-claude.sh --check`.
- **Wizard pipeline preserved.** `schema/AGENTS.template.md` → `bin/init-wizard.sh` continues to render `AGENTS.md` from the template. Extracted `schema/reference/*.md` and `schema/workflows/*.md` are copied wholesale by the wizard (no additional rendering logic needed).
- **CI gates unchanged.** `bin/lint.sh`, `bin/check-privacy.sh`, `bin/check-neutrality.sh` operate on content, not file boundaries.
- **`local_only` privacy fail-closed** must remain in always-loaded core. No agent can be allowed to start work and then discover privacy rules on demand.
- **MUST NOT list** stays verbatim in core. These are the safety invariants.

## Advisor-Corrected Direction

An initial proposal suggested a Claude-skills-first extraction with a ~180-line core target. **Two independent advisors rejected this as vendor-coupling disguised as progressive disclosure.** Their corrected framing, adopted here:

> **Claude-optimized, markdown-authoritative, future-harness-friendly.**
> Not: Claude-native first, portability reconstructed later.

Specifically:
- **Primary substrate is plain markdown** (`schema/reference/`, `schema/workflows/`), NOT `.claude/skills/`.
- **Core target is 500–700 lines**, not 180. Safety-critical invariants (privacy defaults, provenance requirement, MUST NOT list, write-back mandatory, structured-op vocabulary) must stay always-loaded.
- **Skills come last as thin wrappers.** If added, skill body is one paragraph pointing to the canonical markdown. Skills are runtime accelerators for Claude Code, not the source of truth.

## What Stays In The Always-Loaded Core (~500–700 lines)

These must remain resident because an agent cannot safely begin work without them:

- **Identity + three-layer model + four-op vocabulary** (current §1, ~25 lines)
- **Directory structure** (current §2, ~50 lines — path facts can't be derived)
- **Global rules**: ISO 8601 dates, snake_case, commit conventions table, navigation rule, red-links (current §3, ~80 lines)
- **MUST NOT list** (current §3 end, ~15 lines — verbatim)
- **Page type roster** — names + section orderings only, full templates extracted (distilled from §4, ~25 lines)
- **Base frontmatter fields** — field names + types, validation checklist extracted (distilled from §5, ~40 lines)
- **Provenance requirement + basic syntax** — the core rule and one example; full locator/support/staleness extracted (distilled from §6, ~25 lines)
- **Structured ops vocabulary** — UPDATE/MERGE/SUPERSEDE/ARCHIVE names + one sentence each; full procedures extracted (distilled from §9, ~25 lines)
- **Write-back mandatory rule** — trigger list + privacy inheritance (distilled from §11.2, ~25 lines)
- **Privacy defaults + fail-closed + stricter-wins** — the rules; 7-row decision table extracted (distilled from §13, ~20 lines)
- **Log/index format skeleton** — format template; structured op examples extracted (distilled from §12, ~30 lines)
- **Routing index** — "When doing X, read `schema/workflows/X.md` first" (new, ~30 lines)
- **Commit conventions table** (current §3, retained)

## Extraction Table (Source Section → Target File)

| Source section | Target | Notes |
|---|---|---|
| §4 Page type templates (full) | `schema/reference/page-types.md` | Per-type section orderings + examples pointer |
| §5 Frontmatter schema (17-pt validation checklist, field descriptions, compilation tracking, decision record fields) | `schema/reference/frontmatter.md` | `bin/lint.sh` is the enforcement truth; this file is the spec |
| §6 Provenance syntax, locators, decay tables, contradictions, staleness auto-fix | `schema/reference/provenance.md` | Consider splitting: syntax stays reference; decay math could bundle with lint workflow |
| §7 Progressive disclosure (for wiki pages) | `schema/reference/progressive-disclosure.md` | Only relevant when authoring pages |
| §8 Wikilink conventions (full, with bad/good examples) | `schema/reference/wikilinks.md` | Consumed by authors + query write-back |
| §9 Structured operations (definitions + executor model + preconditions/postconditions) | `schema/workflows/structured-operations.md` | `bin/validate-op.sh` enforces; this file is the recipe |
| §10 Compiler pipeline conceptual model | `schema/workflows/pipeline.md` | Loaded only during ingest |
| §11.1 Ingest workflow | `schema/workflows/ingest.md` | Anchor workflow |
| §11.2 Query workflow + write-back rules + delta compilation + worked example | `schema/workflows/query.md` | Worked example stays bundled; long but cohesive |
| §11.3 Lint workflow + CI mode + severity remap + escape-hatch markers | `schema/workflows/lint.md` | This section is the Phase 9 "source of truth for CI contracts" — extraction must preserve that framing |
| §11.4 Reflect workflow + three-tier model + checkpoint | `schema/workflows/reflect.md` | |
| §12 Structured op log formats + contributor inline field | `schema/reference/log-format.md` | Core retains only the bare skeleton |
| §13 Privacy 7-row decision table + conflict resolution | `schema/reference/privacy.md` | Core retains only: fail-closed default + stricter-wins + inheritance rule |
| §14 Scaling boundaries (tier 1-4) | `docs/reference/scaling.md` | Informational, end-user-facing |
| §15 Tooling and integrations | `docs/reference/tooling.md` | Already marked "informational, not normative" |
| §16 Appendices | DELETE | Already pointers; redundant after extraction |

**Resulting projected core:** ~500–700 lines (depending on how aggressive the distillation is on the margins).

## Phase Sequence Within v1.2

### Phase A — Reference Extraction (low-risk, mechanical)

Extract §4, §5, §6, §7, §8, §13 into `schema/reference/*.md`. Extract §14, §15 into `docs/reference/*.md`. Delete §16. Replace each extracted section in `schema/AGENTS.template.md` with a routing stub:

```markdown
## 5. Frontmatter Schema

Base field list and types: see [§5 core summary below].

**For full field descriptions, validation checklist (17 points), compilation tracking, and decision-record fields, read `schema/reference/frontmatter.md` before authoring any page.**
```

Success signals:
- `bin/lint.sh` passes with no new regressions
- `bin/sync-claude.sh --check` passes (AGENTS.md ≡ CLAUDE.md)
- `bin/init-wizard.sh --dry-run` produces unchanged output
- `.github/workflows/setup-parity.yml` passes (byte-equal fixture)
- Core line count: target ~800–1,000 lines (intermediate state after Phase A only)

### Phase B — Workflow Extraction (medium-risk, procedural)

Extract §9, §10, §11.1, §11.2, §11.3, §11.4 into `schema/workflows/*.md`. Extract §12 structured-op formats and contributor field into `schema/reference/log-format.md`. Replace with routing stubs.

Success signals:
- Same CI gates as Phase A pass
- Core line count: **target ~500–700 lines** (the milestone goal)
- A Codex or Cursor agent, given only `AGENTS.md`, can ingest a source by first following the routing table to `schema/workflows/ingest.md` (manual verification)

### Phase C — Claude Skills Overlay (optional, Claude-specific)

Add thin `.claude/skills/` wrappers:
- `ingest-source` / `query-wiki` / `lint-wiki` / `reflect-structural-changes`
- Also consider: `author-wiki-page`, `structured-operations`, `validate-frontmatter`

**Skill body must be one paragraph:** *"You have been invoked to {operation}. Read `schema/workflows/{op}.md` and follow it verbatim."*

Consider `disable-model-invocation: true` for safety (explicit `/{op}` triggering only) given the strict workflow nature of the project.

## Additional Best-Practice Recommendations

Beyond the extraction itself:

1. **Add a routing/index section near the top of the core** — even before full extraction, a one-screen TOC mapping operations → sections cuts scan cost dramatically. Most agents need only one section per turn.
2. **Reserve `IMPORTANT` / `MUST NOT` for the top ~10 rules.** Current spec sprinkles imperatives throughout. The "What Agents Must NOT Do" list is well-calibrated; mirror that discipline.
3. **Cut bad/good example pairs from core.** Sections 6, 8 carry pedagogical examples (~30 lines each). These are only useful when authoring; move to the extracted reference files.
4. **Cut the §11.2 worked example from core.** Moves to `schema/workflows/query.md`.
5. **Split §6 by consumer.** Provenance *syntax* is needed by ingest + query write-back. Decay *math* is needed only by lint. Same section forces both audiences to load both; split during extraction.
6. **Delete the `book` → `book-chapter` historical note** (§10 Pass 0). Migration is complete; notes accumulate.
7. **Core's privacy text is one line.** *"Privacy default: `local_only`. Stricter wins on conflict. Inheritance: a page is `cloud_safe` only if all sources are. See `schema/reference/privacy.md` for the 7-row decision table."*
8. **Extend `bin/sync-claude.sh` semantics to the whole `schema/` tree.** If a workflow file changes, the `schema:` commit type applies to the full set. Consider a `--check-tree` flag that diffs `schema/reference/` + `schema/workflows/` for drift between the template and the generated copy.
9. **Version the extracted files together.** Treat `schema/reference/` + `schema/workflows/` + `schema/AGENTS.template.md` as a single versioned unit for schema changes.
10. **Apply the project's own §7 principle to itself** — eating the dog food is architecturally consistent and makes a strong narrative for v1.2 release notes.

## Open Questions For `/gsd-discuss-phase 999.4`

1. **Milestone or single phase?** v1.2 full milestone (Phase A + B + C) vs. Phase 09.2 doing only Phase A now (reference extraction). Decision affects v1.1 ship schedule.
2. **Core target line count.** 500–700 is the consensus range, but the exact number depends on how aggressive distillation is on frontmatter, provenance, and structured-ops summaries.
3. **Include Phase C (skills) in v1.2 scope, or defer to v1.3?** Skills are optional accelerators; deferring preserves markdown-first purity and lets v1.2 ship faster.
4. **Split §6 (provenance/decay) at extraction time or in a follow-up?** Splitting during extraction is cheaper but requires resolving the reference-vs-workflow boundary for decay rules.
5. **How should `docs/reference/` vs `schema/reference/` be differentiated?** Current precedent: `docs/reference/` is end-user/contributor-facing; `schema/reference/` would be agent-authoritative. Scaling (§14) and Tooling (§15) are arguably end-user; others are agent-authoritative.
6. **Do we extend `bin/sync-claude.sh` to the full schema/ tree in Phase A, or leave that for v1.3?**
7. **Should the wizard (`bin/init-wizard.sh`) copy `schema/reference/` and `schema/workflows/` to the adopter's repo, or leave them symlinked/pointed-to?** The current wizard writes a personalized `AGENTS.md`; with extraction, the adopter needs the whole schema tree.
8. **Does this refactor change AGENTS.md's "sole authoritative specification" framing?** Currently line 3 of the spec says "No other file contains conventions, rules, or workflow definitions." This framing needs to evolve — either widen the scope to "this file + `schema/reference/` + `schema/workflows/` collectively are the sole authoritative spec," or reframe as "this file is the router; linked files are authoritative for their sections."

## Research & Decision Lineage

- **Anthropic Agent Skills spec** ([equipping-agents-for-the-real-world-with-agent-skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)): progressive disclosure as three-tier loading.
- **Anthropic best-practices docs**: CLAUDE.md `<300` lines soft ceiling; diagnostic *"if Claude keeps doing something despite a rule, the file is probably too long."*
- **HumanLayer's "Stop Bloating Your CLAUDE.md"**: `<60` lines production exemplar; router pattern.
- **Vercel finding**: skills never invoked in 56% of test cases without explicit `IMPORTANT: read X` pointers — motivates the routing table design.
- **Comparative framework research** (Superpowers / GSD / Spec Kit): converges on markdown-authoritative, skills-as-overlay pattern. GSD itself uses `.planning/` externalization plus subagents as the progressive-disclosure mechanism.
- **Phase 09.1 precedent**: 1,785 → 1,412 lines via worked-example + appendix extraction. Same extraction pattern, wider scope.
- **Advisor consensus** (2 independent reviewers): Claude-first-skills is vendor coupling; markdown-first preserves portability; 500–700 line core preserves invariants.

## Constraints To Preserve (Checklist)

- [ ] `AGENTS.md` ↔ `CLAUDE.md` byte-equality via `.githooks/pre-commit`
- [ ] `bin/sync-claude.sh --check` passes
- [ ] `bin/init-wizard.sh --dry-run` output unchanged for existing placeholders
- [ ] `.github/workflows/setup-parity.yml` byte-equality fixture passes
- [ ] `.github/workflows/neutrality.yml` continues to pass (extracted files must also be neutral)
- [ ] `.github/workflows/lint.yml` three parallel jobs pass (lint, privacy-leak, strict)
- [ ] `bin/lint.sh` continues to enforce frontmatter rules regardless of where schema text lives
- [ ] `bin/validate-op.sh` continues to enforce operation preconditions
- [ ] `bin/check-privacy.sh` continues to block `local_only` in public paths — including new `schema/reference/*.md` and `schema/workflows/*.md`
- [ ] Codex / Cursor / Gemini-CLI path: a non-Claude agent reading `AGENTS.md` can reach the same operational knowledge by following the routing table (manual verification via Phase 12 agent-parity test)
- [ ] `schema:` commit convention covers changes to the extracted tree
- [ ] Decision record created documenting the split (`trigger_type: schema-update`)

## Related Prior Work

- **Phase 09.1 "Progressive Disclosure Extraction"** — tactical 21% reduction (worked examples + appendices). Completed 2026-04-16. This milestone is the strategic continuation.
- **Phase 07** (Neutral Template Foundation) — introduced `schema/AGENTS.template.md` as the render source.
- **Phase 08 WZRD-07 / D-02** — reduced template placeholder set from 6 to 4 (minimalism decision). Phase C (if pursued) should re-visit minimalism for skills.
- **Decision records in `wiki/decisions/`** — any structural change to `schema/` needs a DR with `trigger_type: schema-update`.

## Exit Criteria (Draft, Validate at `/gsd-discuss-phase`)

- [ ] Core `AGENTS.md` ≤ 700 lines (hard), target 500–650
- [ ] All extracted sections exist as standalone markdown under `schema/reference/` or `schema/workflows/`
- [ ] Routing table in core points to every extracted file
- [ ] All CI gates green
- [ ] One decision record created per structural extraction (or one consolidated DR for the whole refactor — discuss at planning time)
- [ ] `docs/reference/agent-parity.md` updated with evidence that Codex/Cursor can reach the same operational knowledge via the routing path
- [ ] If Phase C pursued: skill bodies are ≤ 3 lines each (thin pointer pattern validated)
- [ ] `schema/AGENTS.template.md` itself is reduced proportionally (byte-equal to generated `AGENTS.md` minus the per-adopter placeholders)

---

**Promote with `/gsd-discuss-phase 999.4` when ready to elevate to active v1.2 planning. Do not plan directly against this note — it is pre-planning context.**

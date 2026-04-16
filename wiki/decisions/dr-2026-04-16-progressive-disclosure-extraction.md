---
id: dr-2026-04-16-progressive-disclosure-extraction
title: "Extract §4 Worked Examples and §16 Appendices A+B to Deep References"
type: decision
status: active
summary: "AGENTS.md §4 page-type worked examples move to schema/examples/<type>.md and §16 Appendices A (Dataview queries) and B (commit examples) move to docs/reference/dataview-queries.md and docs/reference/commit-examples.md. §16 Appendix C (Quick Reference Card) and all §4 normative prose (purpose, when-to-use, section order, frontmatter-required tables) remain inline."
created_at: 2026-04-16
updated_at: 2026-04-16
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs in sources[], affected_pages[], supersedes, etc.)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body -->

## TL;DR

AGENTS.md §4 worked examples and §16 Appendices A and B move out of the core spec into deep-reference files under `schema/examples/` and `docs/reference/`; the core spec retains per-type purpose / section-order / frontmatter prose inline and §16 Appendix C verbatim. Net: ~350 lines (~20%) removed from AGENTS.md; no meaning lost.

## Decision

The §4 page-type worked examples (lines 143-558 of pre-extraction AGENTS.md, six fenced ```markdown blocks) move out of the core spec into `schema/examples/<type>.md`:

- `schema/examples/entity.md` (Geoffrey Hinton)
- `schema/examples/concept.md` (Attention Mechanism)
- `schema/examples/source-summary.md` (Vaswani et al. — filename uses hyphen; frontmatter `type: source` per AGENTS.md §5 enum)
- `schema/examples/comparison.md` (RNNs vs Transformers)
- `schema/examples/overview.md` (Deep Learning)
- `schema/examples/decision.md` (dr-2026-04-14-phase6-decision-type, with the original truncation `(...remaining sections: …)` preserved per D-07)

Each `schema/examples/*.md` carries `example: true` (AGENTS.md §5 lint-skip semantics, mirroring `examples/kahneman/`) and `privacy: cloud_safe`.

The §16 Appendix A (Dataview queries) and Appendix B (commit messages) move to:

- `docs/reference/dataview-queries.md` (5 direct ```dataview fenced blocks; the AGENTS.md inline-illustration outer ```markdown wrapper is stripped because a standalone cookbook should emit copy-pasteable snippets, not markdown-escaped examples)
- `docs/reference/commit-examples.md` (one ``` fenced block with the 9 representative commit-message lines)

Both new `docs/reference/*.md` files have NO YAML frontmatter, matching the established `docs/reference/` convention (brownfield.md, ci.md, privacy-model.md, etc.).

§16 Appendix C (Quick Reference Card, 10 numbered rules) stays inline at AGENTS.md §16 verbatim per D-03 — it is short, scannable, and load-bearing.

The §4 residue uses a uniform shape per D-08 (rule 4: type-specific frontmatter tables stay inline as normative spec):

- Section header + Purpose + Section order + When to use + (if applicable) the type-specific frontmatter fields table
- A 2-3-bullet `**Example:** {EXAMPLE_SUBJECT}. Demonstrates {CAPSULE_BULLET_1}; {CAPSULE_BULLET_2}; {CAPSULE_BULLET_3}.` capsule
- A bare-prefix pointer at column 0: `See: schema/examples/<type>.md for a concrete filled-in instance.` — matching the existing `See: examples/kahneman/<path>.md for a concrete filled-in instance.` shape used at AGENTS.md §§11.1 and 11.2 (singular "a concrete filled-in instance" — §12 uses the plural form because it points to a file with multiple worked operation patterns).

The §16 A/B residue uses a single-line backtick-wrapped pointer ("See `docs/reference/...md` for ...") rather than the §4 bare-prefix shape, because §16 appendices are cross-doc references to a different top-level directory and a different convention namespace.

Parallel edits land in the same atomic commit:

- `schema/AGENTS.template.md` is edited at offset-adjusted line ranges (+2 for §4, -62 for §16) so wizard-track and manual-track outputs do not drift (R-1 mitigation)
- `schema/fixtures/canonical-AGENTS.md` is regenerated via the verbatim Plan 08-01 python3 `str.replace` routine so Phase-08 setup-parity CI stays green (R-2 mitigation)
- `CLAUDE.md` is auto-synced by `.githooks/pre-commit` → `bin/sync-claude.sh` so byte-equality holds (R-3)
- `wiki/index.md` gains its first `## Decisions` section listing this DR plus the two pre-existing DRs
- `wiki/log.md` gains a `## [2026-04-16] reflect | progressive disclosure extraction` entry per AGENTS.md §12 (the DR captures the structural decision; the log entry captures the activity)
- The §4 preamble (AGENTS.md line 133) is updated from "Five page types exist." to "Six page types exist." — a one-word polish reflecting the §4.6 Decision type added in Phase 6

## Why

**Adopted framing:** "spec + linked deep references." The sole authoritative specification remains AGENTS.md, and `schema/examples/*.md` / `docs/reference/*.md` are deep extensions that the spec points to, not alternative specs. Readers who want the full anatomy of a page type follow the pointer; readers who only need the purpose / section-order / required-frontmatter shape get it inline without dereferencing.

**Replaced framing:** "sole authoritative specification as a single monolithic file." Under the prior convention, every reader (LLM or human) had to hold the full 1,785-line document in context even when they only needed the per-type shape or a commit-message reference. The 6 §4 worked examples accounted for ~324 lines and the §16 Appendix A and B for ~68 lines — pure-reference content that the core spec text never gates on but that always entered the context window.

**Why "spec + linked deep references" is safe:** The pointer convention is a one-line bare-prefix path that any agent (Claude, Codex, others) can dereference with a single file read. The shape matches the pre-existing `See: examples/kahneman/<path>.md` convention used three times in §§11.1 / 11.2 / 12 — no new reader-convention is introduced. Codex agent-parity is preserved by construction.

**Why §16 Appendix C is NOT extracted (per D-03):** The Quick Reference Card is the kind of content that belongs in the core spec — short, scannable, and load-bearing. Extracting it would force pointer-chasing for a summary, defeating progressive disclosure rather than serving it.

## Alternatives Considered

- **Bare-pointer-only residue** (no 2-3-bullet capsule on §4 sub-sections): Rejected per D-08. Per-type residue includes a capsule summary so the core spec stays self-contained for scanning readers who do not need the full worked example. Line-delta savings drop from ~500 to ~350, which D-02 accepts as the readability tradeoff.
- **Combine A+B into a single `docs/reference/appendices.md` grab-bag**: Rejected per D-12. Topic-per-file is the established `docs/reference/` pattern (brownfield.md, ci.md, privacy-model.md, schema-tour.md, setup-prerequisites.md, release.md); a grab-bag file would break discoverability and search.
- **Reuse `docs/reference/examples.md` for the §4 worked examples**: Rejected per D-06. That file is reserved for Phase 12 DEBT scope (documenting how `examples/` works in Obsidian, `.obsidianignore`, safe copy-into-wiki) and `tests/phase-07/test_reference_stubs.sh` asserts it remains a stub.
- **Reuse `examples/kahneman/` for §4 bodies**: Rejected per D-05. Subject matter differs (§4 uses Hinton / Vaswani / deep-learning; the Kahneman cluster uses Kahneman-specific content). `examples/kahneman/` stays as the existing test-fixture cluster for §§11.1 / 11.2 / 12 operational illustrations.
- **Extract §9 Structured Operations and §11 Workflows in the same wave**: Deferred per `.planning/seeds/workflows-operations-to-skills.md`. Those sections require a portable runtime mirror (workflows/*.md) that does not yet exist; pulling them into v1.1 risks the Phase 12 Codex agent-parity merge gate.
- **Keep the AGENTS.md §16 Appendix A `dataview` fences nested inside outer ```markdown wrappers in the extracted cookbook**: Rejected per cross-AI review R2. The outer wrapper is correct inside AGENTS.md (the intent there is illustrative — "here is how an Obsidian markdown page embeds a Dataview query"), but in a standalone cookbook readers want direct copy-pasteable snippets. The extraction strips the outer wrapper.

## Consequences

- AGENTS.md shrinks from 1,785 lines to approximately 1,435 lines (actual reduction ~350 lines per RESEARCH.md §2 honest arithmetic). The CONTEXT.md D-01 headline predicted ~500 lines; the ~150-line shortfall is the cost of D-08's capsule-and-frontmatter-table-inline choice and is acceptable per D-02 (no hard ceiling).
- CLAUDE.md remains byte-identical to AGENTS.md via `.githooks/pre-commit` → `bin/sync-claude.sh` auto-sync. No manual CLAUDE.md edits required.
- Codex and other non-Claude agents can still follow AGENTS.md normatively. The pointer phrasing (singular `for a concrete filled-in instance.`) matches §§11.1 / 11.2 precedent exactly per cross-AI review R1 consensus, and uses the same bare-prefix shape as the pre-existing `See: examples/kahneman/<path>.md` convention. No new reader-convention is introduced and no drift from established phrasing.
- Phase-08 setup-parity CI stays green because `schema/AGENTS.template.md` is edited in parallel and `schema/fixtures/canonical-AGENTS.md` is regenerated via the Plan 08-01 python3 `str.replace` routine in the same commit.
- Phase-07 neutrality and Phase-09 privacy gates pass cleanly by two independent arguments (cross-AI review R6 — these arguments must NOT be conflated): (a) **Privacy** — `schema/examples/*.md` carry `privacy: cloud_safe` explicitly and `bin/lint.sh` skips them because of `example: true` per AGENTS.md §5; the new `docs/reference/*.md` files have no YAML frontmatter at all, and `bin/check-privacy.sh` is a frontmatter-only scanner per Phase-09 D-14, so there is nothing for it to flag. (b) **Neutrality** — `bin/check-neutrality.sh` is a body-text scanner (not frontmatter-only); it passes on the new files because the Hinton / Vaswani / deep-learning / attention-mechanism content is pre-vetted neutral (D-07) and was already passing the denylist while inline in AGENTS.md §§4 / §16. Moving that same body text to `schema/examples/*.md` and `docs/reference/*.md` does not change what the neutrality scanner sees.
- Phase-07 `test_reference_stubs.sh` continues to pass — `docs/reference/examples.md` is NOT touched in this phase per D-18.
- `wiki/index.md` gains its first `## Decisions` section, listing this DR plus the two pre-existing ones (`dr-2026-04-14-phase6-decision-type`, `dr-2026-04-15-kahneman-to-examples`) for forward-consistency per PATTERNS.md Note 2.
- `wiki/log.md` gains a new `## [2026-04-16] reflect | progressive disclosure extraction` entry per cross-AI review R11 consensus and AGENTS.md §9 / §12 formal-operations vocabulary. The DR is the structural decision record (why); the log entry is the activity record (what / when).
- The §4 preamble (AGENTS.md line 133) was updated from "Five page types exist." to "Six page types exist." as a one-word polish reflecting the §4.6 Decision addition from Phase 6 (R8 cross-AI review consensus, promoted to mandatory because this Consequences bullet would otherwise contradict a stale preamble).
- The `docs/reference/dataview-queries.md` extraction strips the outer ```markdown wrapper that §16 Appendix A used to illustrate "this is how an Obsidian page embeds a Dataview query"; the standalone cookbook emits 5 direct ```dataview blocks so readers can copy-paste the queries (R2 review consensus).
- §9 Structured Operations and §11 Workflows extraction remains deferred per the seed at `.planning/seeds/workflows-operations-to-skills.md`. The AGENTS.md size may be revisited in v1.2 if the progressive-disclosure fitness still feels load-bearing.

## Affected Pages

None. This is an infrastructure / schema change; no pre-existing wiki content pages are restructured. The AGENTS.md spec itself is modified, but AGENTS.md is not a wiki content page (it is the canonical spec). The `affected_pages: []` list reflects this: no page under `wiki/` gains a `decision_history` back-link from this DR.

## Sources

None. This is an internal schema decision; the decision record itself is the source of truth.

---
id: dr-2026-04-15-kahneman-to-examples
title: "Move Kahneman Cluster from wiki/ to examples/"
type: decision
status: active
summary: "Relocate the 7 Kahneman pages + 2 Kahneman source summaries from wiki/ to
  examples/kahneman/ to neutralize the public template surface; delete privacy: local_only
  personal-domain content; delete wiki/maintenance/."
created_at: 2026-04-15
updated_at: 2026-04-15
sources: []
epistemic_status: sourced
tags:
- meta
- schema
- neutralization
domains:
- wiki-infrastructure
knowledge_domain: software
supersedes: null
superseded_by: null
aliases:
- "Move Kahneman Cluster from wiki/ to examples/"
- "dr-2026-04-15-kahneman-to-examples"
has_contradictions: false
neutrality_exempt: true  # This record IS the history of the Kahneman-to-examples relocation; it legitimately names what it relocated. Scanner skips this file (check-neutrality.sh).
trigger_type: schema-update
affected_pages:
- daniel-kahneman
- prospect-theory
- loss-aversion
- cognitive-biases
- system-1-vs-system-2
- decision-making
- src-2026-04-09-thinking-fast-and-slow-part1
- src-2026-04-10-kahneman-prospect-theory
- personal-decision-patterns
- src-2026-04-10-personal-decision-journal
- lint-report
- reflect-state
---

## TL;DR

To ship a public, neutral template (v1.1 milestone), the creator-domain Kahneman cluster moves to `examples/kahneman/` (preserved as a reference example), `privacy: local_only` personal-domain content is deleted, and `wiki/maintenance/` is deleted (TMPL-05 ships skeleton-only).

## Decision

Relocate all 7 Kahneman wiki pages and 2 Kahneman source summaries from `wiki/{entities,concepts,comparisons,overviews,sources}/` to `examples/kahneman/{...}/`. Delete `wiki/overviews/personal-decision-patterns.md` and `wiki/sources/src-2026-04-10-personal-decision-journal.md` (`privacy: local_only`, must never ship). Delete `wiki/maintenance/lint-report.md` and `wiki/maintenance/reflect-state.md` (regenerated locally on demand by `bin/lint.sh`). Reduce `wiki/` to TMPL-05 skeleton: `index.md`, `log.md`, and `decisions/`.

## Why

The framing adopted is "the public template ships with an empty wiki and a preserved reference example, distinct directories with distinct semantics." The framing it replaces is "the wiki is the creator's personal-domain cluster plus that creator's private notes." NEUT-01, NEUT-05, NEUT-07, TMPL-05 all derive from this framing. Pitfall C-1 (creator-content leakage) is mitigated by removing creator content from public paths in a single auditable commit.

## Alternatives Considered

- **Leave Kahneman cluster in `wiki/` and document it as "starter content."** Rejected: a stranger cloning the template would inherit Daniel Kahneman's biography as their own knowledge base; any new ingest would be polluted by an unrelated domain.
- **Delete the Kahneman cluster entirely.** Rejected: the cluster is a high-quality, internally consistent demonstration of the schema's full feature surface (entities, concepts, comparisons, overviews, sources, provenance). NEUT-05 keeps it as a reference.
- **Keep `wiki/maintenance/` with stubbed reports.** Rejected: TMPL-05 says skeleton-only. Maintenance reports are tooling output, not authored content; downstream forks regenerate them on demand.

## Consequences

- `wiki/` reduces to TMPL-05 skeleton (index.md + log.md + decisions/).
- `examples/kahneman/README.md` (NEUT-05) explains the cluster's role.
- `bin/lint.sh EXCLUDE_DIRS` extended to skip `examples/` (NEUT-04).
- `AGENTS.md` illustrative content rewritten in plan 07-03 (NEUT-02/03) to use generic placeholders + `See: examples/kahneman/...` pointers.
- The personal-decision-patterns / personal-decision-journal content is irrecoverable from the public release (orphan-branch publish in plan 07-05 ensures git history is also unreachable).
- Maintenance reports must be regenerated locally; documented in `docs/reference/release.md`.

## Affected Pages

Moved to `examples/kahneman/`:

- [[daniel-kahneman|Daniel Kahneman]] — relocated to examples/kahneman/entities/
- [[prospect-theory|Prospect Theory]] — relocated to examples/kahneman/concepts/
- [[loss-aversion|Loss Aversion]] — relocated to examples/kahneman/concepts/
- [[cognitive-biases|Cognitive Biases]] — relocated to examples/kahneman/concepts/
- [[system-1-vs-system-2|System 1 vs System 2]] — relocated to examples/kahneman/comparisons/
- [[decision-making|Decision Making]] — relocated to examples/kahneman/overviews/
- [[src-2026-04-09-thinking-fast-and-slow-part1|Thinking Fast and Slow Part 1]] — relocated to examples/kahneman/sources/
- [[src-2026-04-10-kahneman-prospect-theory|Kahneman Prospect Theory]] — relocated to examples/kahneman/sources/

Deleted (creator-private, never to ship):

- personal-decision-patterns — `privacy: local_only`
- src-2026-04-10-personal-decision-journal — `privacy: local_only`

Deleted (TMPL-05 skeleton-only):

- lint-report (regenerate locally via `bash bin/lint.sh`)
- reflect-state (regenerate locally via reflect workflow)

## Sources

- AGENTS.md §4.6 — `type: decision` schema this record conforms to.
- .planning/REQUIREMENTS.md — TMPL-05, NEUT-01, NEUT-05, NEUT-07 definitions.
- .planning/phases/07-neutral-template-foundation/07-CONTEXT.md — locked decisions D-09, D-13.

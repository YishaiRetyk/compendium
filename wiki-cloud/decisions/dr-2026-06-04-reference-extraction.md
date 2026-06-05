---
id: dr-2026-06-04-reference-extraction
title: "Reference Extraction: AGENTS.md Monolith to schema/reference/ + schema/workflows/"
type: decision
status: active
summary: "Extracts §4/§5/§6/§7/§8/§13/§14/§15/§16 from the AGENTS.md monolith into standalone leaf files under schema/reference/ and schema/workflows/; AGENTS.md becomes a router with bare stubs; evolves 'sole source of truth' framing to 'router + per-section authority'."
created_at: 2026-06-04
updated_at: 2026-06-04
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-04-reference-extraction
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# Reference Extraction: AGENTS.md Monolith to schema/reference/ + schema/workflows/

## TL;DR

Phase 16 extracts every static reference section of the 1,655-line AGENTS.md/CLAUDE.md monolith into standalone markdown files under `schema/reference/` and `schema/workflows/`. AGENTS.md becomes a router with bare stubs; each leaf file is authoritative for its own domain. The "sole authoritative specification" framing evolves from "no other file contains rules" to "this file is the router; each linked file is authoritative for its own sections" (D-09).

## Decision

Extract §4 Page Types → `schema/reference/page-types.md`; §5 Frontmatter → `schema/reference/frontmatter.md`; §6 (consumer-split) syntax/epistemics → `schema/reference/provenance.md`, decay/staleness → `schema/workflows/lint.md`; §7 dissolves (no file); §8 Wikilinks → `schema/reference/wikilinks.md`; §13 Privacy (Phase-15 asymmetric form) → `schema/reference/privacy.md`; §14 → `docs/reference/scaling.md`; §15 → `docs/reference/tooling.md`; §16 deleted. A two-axis `IMPORTANT:`-flagged routing table is added at the top of core between §1 and §2.

## Why

Applied the inclusion test (ambient / unscriptable-unacceptable-miss-cost / dispatch) section-by-section. Sections that earn residence are those every agent needs on every turn; sections with clean JIT load points and gate-caught miss costs extract.

The old framing ("no other file contains conventions") became a logical contradiction once reference files existed. The new D-09 framing ("this file is the router; each linked file is authoritative for its own sections") is cleaner: AGENTS.md is the dispatch artifact; leaf files own their domain.

D-04 deviation from the Extraction Map's resident-remnant column: core was designed to keep §4 "type roster + section orderings (~10 lines)" resident, but the inclusion test finds the section-ordering tables fail all three clauses (they have a clean JIT load point at authoring time and a gate-caught miss from lint). Only the 6 type names (dispatch vocabulary) remain in core; the tables extract to `page-types.md`. The §4↔§7 dedupe (one roster, §7 dissolved) is preserved — only what the merged remnant contains is trimmed by the test.

## Alternatives Considered

**Option A — Keep all reference content inline (status quo):** The spec continues to grow as an always-loaded monolith. Rejected: the spec already violates its own §7 progressive-disclosure principle; continued growth worsens context-window consumption on every turn.

**Option B — Extract but keep inline summaries (partial stubs):** Each extracted section leaves a paragraph-level summary in core. Rejected (D-01): partial summaries create a second copy of content that drifts from the leaf file, and agents may act on the partial inline text instead of reading the authoritative reference.

**Option C — Extract with collective-authority framing:** Core states "this file + schema/reference/ + schema/workflows/ collectively are the authority." Rejected (D-09): "collectively" is less crisp about who owns what. The router-plus-per-section-authority model is cleaner — core dispatches, leaf files own.

## Consequences

- AGENTS.md is substantially smaller (from 1,655 lines to approximately the ~145-line resident core expected from the inclusion test; Phase 17 completes the reduction).
- Agents starting a task read AGENTS.md, find the routing table, and follow one hop to the relevant reference file — no more reading the full monolith for authoring-time reference lookup.
- `bin/sync-claude.sh --check` (AGENTS.md ≡ CLAUDE.md) remains the byte-equality gate.
- Phase 17 owns `schema/workflows/lint.md` full procedure; Phase 16 seeds only the decay table and staleness auto-fix rules from §6.
- **Wizard placeholder drop (intentional):** the §5/§6 extraction removed the two carrier lines that hosted the `{{DEFAULT_PRIVACY}}` and `{{DECAY_PROFILE}}` wizard placeholders. They were NOT relocated to a leaf file (leaf files are static shared reference, not per-user rendered). The `privacy_default:` carrier is obsolete because Phase 15 made privacy structural (§13: tier = `wiki-cloud/` vs `wiki-local/`, not a frontmatter field); the decay profile remains a recorded wizard answer (in `.wizard-answers.yaml` and the initial decision record) but no longer renders into the spec body. Accordingly the approved template-placeholder set shrank to exactly `{{AGENT_FILENAME}}` and `{{PRIMARY_DOMAIN}}`; `bin/init-wizard.sh`'s two now-dead `.replace()` substitutions were removed, `docs/manual-setup.md` Sections 4–5 were converted to "no AGENTS.md edit", and `tests/phase-07/test_agents_template_placeholders.sh` was tightened to an exact-set assertion. (Found via the Phase 16 code review, CR-01; resolved as "accept drop + clean up".)

## Affected Pages

No id-bearing wiki pages are affected (affected_pages: []). This is an infrastructure/schema-update record, mirroring the §4.6 precedent [[dr-2026-04-14-phase6-decision-type|Introduce Decision Record Page Type]]. The change reshapes the AGENTS.md/CLAUDE.md spec and creates reference files under `schema/reference/` and `schema/workflows/` — none of which are id-bearing wiki pages (DRFT-04 also excludes the index/log tokens from page-ID resolution). For navigability, wiki-cloud/index.md gains a Decisions entry and wiki-cloud/log.md gains a schema: operation entry, but those are navigation artifacts, not pages tracked via decision_history.

## Sources

Design decisions D-01 through D-09 in `.planning/phases/16-reference-extraction/16-CONTEXT.md`. Milestone brief Extraction Map and inclusion test in `.planning/milestones/v1.2-MILESTONE-BRIEF.md`.

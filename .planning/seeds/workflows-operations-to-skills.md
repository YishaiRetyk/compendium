---
title: "Workflows/Operations → Skills extraction (deferred)"
trigger_condition: "A plain-markdown workflows/*.md mirror exists that Codex can read, OR the Phase 12 Codex agent-parity gate is retired"
planted_date: 2026-04-16
milestone_hint: v1.2+
---

# Workflows/Operations → Skills extraction (deferred)

## What

Extract `AGENTS.md` §9 (Structured Operations) and §11 (Workflows) into a runtime-accessible skills or workflow-files layer, following the GSD pattern (`workflows/*.md` + `references/*.md` loaded on demand by a small dispatcher).

## Why this is deferred from v1.1

The framework-comparison research (`.planning/notes/research-progressive-disclosure-framework-comparison.md`, 2026-04-16) identified this as the second-wave extraction after §4 examples + §16 appendices. Two reasons to defer:

1. **Phase 12 Codex agent-parity merge gate.** Claude-only skill extraction (the Claude Code Skills pattern, Superpowers pattern) disqualifies itself. GSD's workflow cascade works only because `gsd-tools.cjs` exists as a runtime; this repo has no equivalent portable mirror.
2. **Scope inflation risk.** v1.1 Shareability is 88% done; pulling workflow/operation extraction into the current milestone widens scope beyond "make the template shareable" and invites a broader re-architecture.

## Revisit trigger

Surface this seed when ANY of the following becomes true:

- A plain-markdown `workflows/*.md` directory exists in-repo that both Claude and Codex can `Read` directly (no slash-command indirection required).
- The Phase 12 Codex agent-parity gate is retired or redefined to tolerate Claude-only deep references.
- Token budget pressure on the post-9.5 spec is still material (e.g., `AGENTS.md` still >25k tokens after §4/§16 extraction), making workflow extraction necessary rather than optional.

## Out of scope at revisit time

- Extracting §1–§3 (Overview, Directory Structure, Global Rules) — these are the canonical entry-point contract and should stay inline.
- Any extraction that breaks `CLAUDE.md` ≡ `AGENTS.md` byte-equality (Phase 07 TMPL-10/D-03).
- Any pattern that requires the wizard to render multiple files — keep wizard placeholders inside the primary spec.

## Related artifacts

- Research note: `.planning/notes/research-progressive-disclosure-framework-comparison.md`
- Phase that handles the first-wave extraction: Phase 9.5 (Progressive Disclosure Extraction)
- Relevant pitfall: PITFALLS.md "load-bearing spec file size" (if logged)

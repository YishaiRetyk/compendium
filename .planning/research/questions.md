---
title: Open research questions
updated: 2026-04-16
---

# Open Research Questions

Questions surfaced during exploration that need resolution before or during phase planning. Answer inline under each question and mark with `RESOLVED (date)` when closed.

---

## Phase 9.5 — Progressive Disclosure Extraction (opened 2026-04-16)

### Q1. Does the wizard's placeholder rendering overlap §4 example blocks?

**Context.** `bin/init-wizard.sh` renders `AGENTS.md` from `schema/AGENTS.template.md` via 4 placeholders (`PRIMARY_DOMAIN`, `DEFAULT_PRIVACY`, `AGENT_FILENAME`, `DECAY_PROFILE`). Before extracting §4 worked examples (entity/concept/source/comparison/overview/decision), we must confirm the placeholders do not appear inside those example blocks. If they do, the examples must stay inline until the overlap is refactored away.

**How to resolve.** Grep `schema/AGENTS.template.md` for `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}` and check whether any occurrences fall between `## 4.1` and `## 5` (the §4 example span). Cross-check by inspecting `schema/fixtures/canonical-answers.yaml` + rendered output for byte-level equality after a hypothetical extraction.

**Blocking for.** Phase 9.5 Plan 1 (examples extraction).

---

### Q2. Is there a specific byte-count / line-count target driving the extraction?

**Context.** The prompt that triggered this research cited "`CLAUDE.md`/`AGENTS.md` >40k tokens." Actual measured size: 1,718 lines, ~102 KB, ~25–30k tokens (GPT-4 tokenizer approx). If the target is simply "feel smaller," §16 appendices alone may suffice (~70 lines, minimal disruption). If the target is specific (e.g., "<1,200 lines" or "<20k tokens"), §4 examples must also be extracted.

**How to resolve.** Confirm with the operator: is there a concrete ceiling (byte / line / token) the extraction must hit? If yes, measure the post-extraction delta during Phase 9.5 planning and adjust scope (§16-only vs §4+§16) to meet it.

**Blocking for.** Phase 9.5 scope finalization.

---

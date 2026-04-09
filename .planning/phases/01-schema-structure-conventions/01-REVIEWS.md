---
phase: 1
reviewers: [codex, gemini]
reviewed_at: 2026-04-09
plans_reviewed: [01-01-PLAN.md, 01-02-PLAN.md, 01-03-PLAN.md]
---

# Cross-AI Plan Review — Phase 1

## Codex Review

### Plan 01-01 Review

#### Summary
Plan 01-01 is a solid foundation pass: it establishes the vault shape early and front-loads the highest-value schema decisions into `AGENTS.md`. The dependency structure is sensible, and the scope is aligned with the phase goal. The main risk is that it combines filesystem scaffolding with a large amount of normative schema writing without explicitly defining acceptance tests for ambiguity, consistency, and example validity. If executed carelessly, it can produce a plausible document that reads well but still leaves later workflow sections underspecified or internally inconsistent.

#### Strengths
- Creates the core directory skeleton first, which reduces ambiguity for all later schema work.
- Covers most of the phase-critical requirements early: directory conventions, Obsidian compatibility, frontmatter, provenance, and progressive disclosure.
- Keeps the wave focused on foundational schema rather than prematurely expanding into tooling.
- Includes `wiki/index.md` and `wiki/log.md`, which helps anchor navigation and operational visibility from the start.
- Separates page types explicitly, matching the stated user decision to organize by type subdirectories.
- Places prescriptive rules in the schema document itself, which supports agent-agnostic behavior.

#### Concerns
- **HIGH**: The plan says "sections 1-8" but does not explicitly require worked examples for each page type, frontmatter instance, and wikilink pattern. A schema without concrete examples is weaker on Success Criterion 1.
- **HIGH**: No explicit task validates that all 15 required frontmatter fields are present, typed consistently, and usable across every page type without contradictions.
- **MEDIUM**: `wiki/log.md` and `wiki/index.md` are created, but the plan does not define their role strongly enough to prevent overlap with later "Index and Log" sections in Plan 01-02.
- **MEDIUM**: Provenance, epistemics, and staleness are grouped together, but there is no explicit check that the custom provenance syntax is compatible with markdown rendering, Dataview parsing boundaries, and agent edit ergonomics.
- **MEDIUM**: The 400-600 line target may encourage filler or overly broad prose before workflow sections exist, making the document harder for agents to follow.
- **LOW**: Directory skeleton creation does not mention placeholder files or `.gitkeep` strategy, which matters if empty directories must survive in git.
- **LOW**: No explicit handling for illegal filenames, broken wikilinks, or alias collisions.

#### Suggestions
- Add a required acceptance artifact: one minimal example page for each page type using the full frontmatter contract and valid wikilinks.
- Add a schema consistency checklist in this wave: required fields, allowed enums, required link directions, privacy defaulting, and provenance format examples.
- Define `wiki/index.md` and `wiki/log.md` now at least minimally, so Plan 01-02 extends them rather than redefining them.
- Include one "bad vs good" appendix subsection for frontmatter and wikilinks to reduce agent misinterpretation.
- Add a git-tracking task for empty directories if they must exist before content lands.
- Replace the line-count target with a coverage target tied to requirements and examples.

#### Risk Assessment
**Overall risk: MEDIUM** — The plan is directionally strong and likely to produce a usable foundation, but it is vulnerable to "document looks complete, schema still ambiguous" failure.

### Plan 01-02 Review

#### Summary
Plan 01-02 is the right second wave: it builds on the established schema by defining operations, workflows, privacy routing, and scaling boundaries after the structural conventions exist. The dependency ordering is correct, and the scope matches the remaining uncovered requirements. The main risks are that too much operational behavior is deferred into one documentation-heavy wave and that privacy/scaling rules may remain aspirational unless expressed as explicit decision procedures agents can follow deterministically.

#### Strengths
- Correctly depends on Plan 01-01; workflows should not be specified before page types and frontmatter are fixed.
- Captures the remaining schema-critical topics: operations vocabulary, full workflows, privacy routing, scaling boundaries, tooling notes, and examples.
- Aligns well with the user's decision to define all four workflows upfront.
- Keeps privacy and scaling as documented heuristics rather than pretending to hard-code premature boundaries.
- Includes appendices/examples, which is the right place to make agent behavior concrete.
- Avoids implementation creep into tooling or automation beyond documentation.

#### Concerns
- **HIGH**: Privacy routing is high-stakes, but the plan does not require a precise precedence table or examples proving fail-closed behavior.
- **HIGH**: Workflows are listed, but there is no explicit requirement that each workflow be step-by-step, with entry conditions, outputs, failure modes, and commit semantics. That weakens SCHM-02/SCHM-05.
- **MEDIUM**: "Compiler Pipeline" and "Workflows" may duplicate each other unless the distinction is defined clearly.
- **MEDIUM**: Scaling boundaries are likely to become vague prose unless the plan forces named tiers, heuristics, symptoms of tier breach, and fallback behavior.
- **MEDIUM**: "Tooling/Integrations" risks scope creep into future phases.
- **MEDIUM**: Expanding total `AGENTS.md` to 800-1200 lines may reduce agent usability unless section-level summaries and navigation anchors are enforced.
- **LOW**: Conventional commit rules are mentioned but not explicitly called out as required content.
- **LOW**: No explicit address of how appendices stay synchronized with normative schema rules.

#### Suggestions
- Make privacy routing a normative decision table with at least 5 worked examples, including conflicting signals and missing metadata cases.
- Require each workflow to include: trigger, inputs, preflight checks, ordered steps, output artifacts, git commit convention, and abort/escalation conditions.
- Separate "Compiler Pipeline" from "Workflows" explicitly: Pipeline = conceptual lifecycle/state machine; Workflows = operator procedures.
- For scaling boundaries, require each named tier to include approximate size heuristics, expected pain points, and recommended agent behavior changes.
- Keep "Tooling/Integrations" explicitly non-normative.
- Add a short table of operations vocabulary with exact verbs and definitions.
- Add a top-level navigation block and per-section TL;DRs if the document exceeds ~800 lines.

#### Risk Assessment
**Overall risk: MEDIUM** — The plan covers the right material, but the risk is concentrated in underspecified operational logic.

### Plan 01-03 Review

#### Summary
Plan 01-03 is necessary, but currently too weak to justify validating all 19 requirements. Grep-based checks catch presence but cannot reliably verify agent usability, internal consistency, or whether the schema enables correct page creation. The human checkpoint is valuable but underspecified.

#### Concerns
- **HIGH**: Grep-based checks are insufficient for validating Success Criterion 1 (agent comprehension).
- **HIGH**: Human review is underspecified — no defined pass/fail criteria or defect trigger for rework.
- **MEDIUM**: No validation checks YAML parse validity or Dataview compatibility.
- **MEDIUM**: No dry-run with an actual agent creating a page from the schema.

#### Suggestions
- Expand automated validation beyond grep: YAML/frontmatter parse checks, link-pattern checks, directory/git checks.
- Add an agent simulation test: provide schema to an LLM, ask it to create one page, verify conventions.
- Define a human review checklist inside the plan with explicit pass/fail criteria.
- Add explicit exit criteria for what failures send work back to earlier waves.

#### Risk Assessment
**Overall risk: HIGH** — Validation is underpowered relative to the claims it makes.

### Cross-Plan Assessment (Codex)
**Overall program risk: MEDIUM** — Well decomposed and likely achievable, but validation strategy not strong enough to prove the core promise that any LLM can use the schema correctly without extra instruction. Plans become low-risk if examples and validation are strengthened.

---

## Gemini Review

### Summary
The implementation plans for Phase 1 are exceptionally well-structured, reflecting a deep understanding of the "Compiler" metaphor. The phased approach correctly prioritizes physical architecture (directories) and foundational semantics (frontmatter/provenance) before moving into logic (workflows) and constraints (scaling/privacy). The plan successfully balances the need for a prescriptive, agent-agnostic "source of truth" with the practical requirements of an Obsidian-first ecosystem.

### Strengths
- **Layered Architectural Separation:** The distinction between `sources/`, `wiki/`, and `schema/` ensures that raw data, compiled knowledge, and system instructions never collide.
- **High-Precision Provenance:** The custom syntax `[prov:<source_id>#<locator>|<support_type>|<checked_at>]` provides granular auditability exceeding typical RAG implementations.
- **Fail-Closed Privacy Logic:** Three-level privacy (frontmatter > directory > system) with local-only default is robust.
- **Progressive Disclosure Integration:** "Shallow-first" navigation built into the schema addresses the "wall of text" problem.
- **Autonomous Wave Structure:** Dependency mapping is logical — cannot define workflows without first defining the objects they manipulate.

### Concerns
- **HIGH — Instruction Bloat (AGENTS.md Size):** 800-1200 lines consumes significant context tokens. Some agents have internal limits on system prompts; a 1200-line file might be truncated or lead to "instruction fatigue."
- **MEDIUM — Obsidian Rendering of Custom Syntax:** The provenance syntax `[prov:...]` may appear as "noise" in Reading Mode or break certain Markdown parsers. It also doesn't natively "link" to the source.
- **MEDIUM — Missing `.obsidian` Configuration:** Plan 01-01 omits the `.obsidian/` folder. The vault is "broken" for human users until Dataview plugin is installed and configured.
- **LOW — Validation Depth:** Grep-based validation confirms existence but not logical consistency.

### Suggestions
- **Modularize the Schema:** Keep core logic in `AGENTS.md` but move detailed Frontmatter Schema and Page Type Templates into `schema/templates/`. Allows agents to "read-on-demand."
- **Enhance Provenance Wikilinks:** Modify syntax to use a wikilink for source ID: `[prov:[[source_id]]#locator|type|date]` so Obsidian's graph view tracks relationships.
- **Include Obsidian Settings Seed:** Add a task to create basic `.obsidian/plugins/dataview/data.json` so human checkpoint works without manual plugin setup.
- **Add Negative Constraints:** Explicitly tell agents what not to do.

### Risk Assessment
**Overall Risk: LOW** — Plans are technically sound and aligned with key decisions. Primary risk is operational efficiency (agent context usage) rather than architectural failure. The file-based, git-tracked approach is inherently resilient.

---

## Consensus Summary

### Agreed Strengths
- **Dependency ordering is correct and well-reasoned** — both reviewers agree the wave structure is sound
- **Architectural separation is clean** — sources/wiki/schema layering praised by both
- **Privacy model is robust** — fail-closed semantics with layered precedence recognized as a strength
- **Scope discipline** — both note the plans avoid creeping into later implementation phases

### Agreed Concerns
- **Validation is too shallow** (Codex: HIGH, Gemini: LOW) — both flag that grep-based checks confirm text presence but not correctness, usability, or agent comprehension. Codex is more concerned than Gemini.
- **AGENTS.md size is a risk** (Codex: MEDIUM, Gemini: HIGH) — both flag that 800-1200 lines may harm agent usability. Gemini specifically raises context token consumption and "instruction fatigue."
- **Need for more concrete examples** — Codex explicitly calls for worked examples per page type; Gemini suggests modularizing templates into separate files for on-demand reading.

### Divergent Views
- **Overall risk assessment:** Codex rates MEDIUM overall, Gemini rates LOW. Codex is more skeptical about validation proving agent-agnostic operability; Gemini considers the file-based approach inherently resilient to schema errors.
- **Schema modularization:** Gemini suggests moving templates out of AGENTS.md into `schema/templates/`; Codex doesn't suggest splitting but wants more in-file examples. These approaches partially conflict — the user's D-01 decision explicitly chose a single monolithic file with optional supporting files.
- **Obsidian configuration:** Gemini flags the missing `.obsidian/` folder as MEDIUM concern; Codex doesn't mention it. This is arguably out of Phase 1 scope (Obsidian config is user-side setup, not schema specification).
- **Provenance wikilinks:** Gemini suggests embedding wikilinks in provenance syntax `[prov:[[source_id]]...]`; this directly conflicts with D-34 (no display aliases) and the research finding that frontmatter wikilinks are unreliable. The current `[prov:source_id#locator]` with string IDs is the safer approach.

# Phase 16: Reference Extraction - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 11 new/modified files
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `schema/reference/page-types.md` | agent-authoritative reference doc | request-response (JIT read by authoring agents) | `docs/reference/schema-tour.md` | role-match |
| `schema/reference/frontmatter.md` | agent-authoritative reference doc | request-response (JIT read by authoring agents) | `docs/reference/schema-tour.md` | role-match |
| `schema/reference/provenance.md` | agent-authoritative reference doc | request-response (JIT read when adding prov markers) | `docs/reference/schema-tour.md` | role-match |
| `schema/reference/wikilinks.md` | agent-authoritative reference doc | request-response (JIT read when linking) | `docs/reference/schema-tour.md` | role-match |
| `schema/reference/privacy.md` | agent-authoritative reference doc (terse) | request-response (JIT read for tier routing) | `docs/reference/privacy-model.md` | partial-match (audience differs) |
| `schema/workflows/lint.md` | seeded workflow reference doc (partial) | request-response (decay math only; Phase 17 owns full) | `docs/reference/ci.md` | partial-match (ci.md is analogous in cross-ref pattern) |
| `docs/reference/scaling.md` | end-user reference doc | request-response (informational) | `docs/reference/three-layer-model.md` | role-match |
| `docs/reference/tooling.md` | end-user reference doc | request-response (informational) | `docs/reference/three-layer-model.md` | role-match |
| `AGENTS.md` / `CLAUDE.md` | core spec (byte-identical pair) | all operations (always-loaded) | self (in-place edit) | exact |
| `schema/AGENTS.template.md` | wizard source template | transform (4-token substitution) | self (in-place edit) | exact |
| `bin/check-neutrality.sh` | CI gate script | batch (scans PUBLIC_PATHS) | self (one-line edit) | exact |

---

## Pattern Assignments

### `schema/reference/page-types.md` (agent-authoritative reference doc)

**Analog:** `docs/reference/schema-tour.md` (lines 1–24 especially) + `docs/reference/ci.md` for the "Source of truth" lede pattern

**Structural pattern — file header with SSOT lede** (schema-tour.md lines 1–9):
```markdown
# Schema Tour

> Reference documentation for the wiki page schema: the frontmatter base fields, per-type additions...

## TL;DR

...

> **Source of truth:** The authoritative schema lives in [AGENTS.md §5](../../AGENTS.md) (frontmatter)...
  This page reproduces it for ergonomic, progressive-disclosure reading — if you find a discrepancy, §5/§6 wins and this page is the bug.
```

**Key structural rule for `schema/reference/*.md` files:** These are agent-authoritative, NOT reproductions of AGENTS.md. The lede pattern inverts: AGENTS.md §4 becomes a bare stub pointing HERE; this file IS the authority. The lede should read (paraphrasing schema-tour.md's SSOT pattern but flipped):

```markdown
# Page Types and Templates

> Agent-authoritative reference for wiki page types, section ordering, and authoring conventions.
> AGENTS.md §4 points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

## Page Types (dispatch vocabulary)

Six types exist: **entity**, **concept**, **source**, **comparison**, **overview**, **decision**.
```

**Section content to extract** (from CLAUDE.md lines 141–258 + §7 lines 635–643):

The full §4 content (subsections 4.1–4.6, all type descriptions, field tables, example pointers) moves here verbatim. Additionally, the Per-Type Section Ordering table from §7 (CLAUDE.md lines 635–643) merges here as a consolidated section. The §7 authoring rules (TL;DR MUST be 1 short paragraph; Key Facts MUST be compact bullets; Detail contains full narrative) become annotations on the section-ordering table.

**"See also" footer pattern** (from ci.md lines 299–303, privacy-model.md lines 122–127):
```markdown
## See Also

- [AGENTS.md](../../AGENTS.md) — §4 stub (dispatch pointer to this file).
- `schema/reference/frontmatter.md` — frontmatter validation checklist.
- `schema/templates/` — blank page templates per type.
```

---

### `schema/reference/frontmatter.md` (agent-authoritative reference doc)

**Analog:** `docs/reference/schema-tour.md` (lines 28–55 — the base frontmatter block and field descriptions)

**Structural pattern** (schema-tour.md lines 28–55):
```markdown
## Base frontmatter fields

Every wiki page carries this base set (AGENTS.md §5). Field names are `snake_case` and dates are ISO 8601 (`YYYY-MM-DD`) — both are hard requirements for Dataview compatibility.

```yaml
---
id: <page-slug>                    # kebab-case, MUST match filename without .md
...
---
```
```

**Content to extract** (CLAUDE.md lines 259–398): The complete §5 content — Base Fields YAML block, Field Descriptions table, Source Summary Additional Fields, Compilation Tracking Fields, Compilation Status Transition Rules table, Decision Record Additional Fields, Optional Back-Link Field, and the Frontmatter Validation Checklist. All move verbatim.

**Template placeholder handling (RESEARCH.md lines 376–385):** Two `{{placeholder}}` lines from `schema/AGENTS.template.md` live inside the §5 frontmatter block at template lines 285–286:
- `knowledge_domain: "{{PRIMARY_DOMAIN}}"` 
- `privacy_default: {{DEFAULT_PRIVACY}}`

These move with the section into `schema/reference/frontmatter.md` in the TEMPLATE copy. In the live `AGENTS.md/CLAUDE.md` these lines are already rendered; they stay rendered in the live file.

---

### `schema/reference/provenance.md` (agent-authoritative reference doc)

**Analog:** `docs/reference/ci.md` for the "Source of truth" cross-ref pattern; `docs/reference/schema-tour.md` for inline code block style

**Content to extract** (split from CLAUDE.md §6):
- Lines 399–553: Inline Provenance Syntax, Locator Types, Page-marker convention, Support Types, Checked At, Examples in Context, Bad vs. Good Provenance Examples, Source Registry, Provenance Validation Rules, Inline Epistemic Markers, Page-Level vs Claim-Level Epistemic Status, Mixed Inline Grammar
- Lines 580–602: Contradiction Inline Syntax

**Seam boundary:** Lines 555–578 (Decay Rate Table) and lines 604–618 (Staleness Auto-Fix Rules) go to `schema/workflows/lint.md`, NOT here.

**Template placeholder (RESEARCH.md line 381):** `schema/AGENTS.template.md` line 569 contains `{{DECAY_PROFILE}}` in the §6 body. This line is in the decay table section (lines 555+) and moves to `schema/workflows/lint.md` in the TEMPLATE copy. It does NOT appear in `provenance.md`.

**Structural header pattern** (applying ci.md's SSOT lede + inversion):
```markdown
# Provenance, Epistemics, and Contradiction

> Agent-authoritative reference for inline provenance markers `[prov:...]`, epistemic status markers `[epistemic::]`, and contradiction markers `[contradiction:...]`.
> AGENTS.md §6 (syntax/epistemics portion) points here.

Every factual claim MUST have an inline provenance marker — see the syntax below.
```

---

### `schema/reference/wikilinks.md` (agent-authoritative reference doc)

**Analog:** `docs/reference/schema-tour.md` structure; the source content is CLAUDE.md §8 + §3 Red Links

**Content to extract:**
- CLAUDE.md lines 655–705: All of §8 (Rules, Bad vs. Good Wikilink Examples, Graph View Implications)
- CLAUDE.md lines 123–125: §3 Red Links paragraph

**Critical verbatim preservation (CONTEXT.md REF-05 guard):** The uniform-piped-link truth at CLAUDE.md lines 659–670 must carry verbatim:
```markdown
1. Use `[[id|Exact Title]]` for ALL intra-wiki cross-references in page body text.
   The target before `|` is the page `id` (= filename stem — always resolves in Obsidian
   since Obsidian resolves `[[X]]` by **filename/path ONLY**, never by `title` and never
   by `aliases`). The display text after `|` is the exact canonical `title`.
```

**"Source of truth" lede pattern** (matching ci.md's pattern since this IS the authority post-extraction):
```markdown
# Wikilink and Graph Conventions

> Agent-authoritative reference for intra-wiki linking: the uniform piped-link form, red links, and Obsidian graph behavior.
> AGENTS.md §8 and §3 Red Links point here. This file carries the v1.1.1 uniform-piped-link truth.
```

---

### `schema/reference/privacy.md` (agent-authoritative terse reference)

**Analog:** `docs/reference/privacy-model.md` (the full-model sibling); the terse version is modeled on how §13 currently reads — a brief structural statement + pointer

**Relationship to `docs/reference/privacy-model.md`:** These serve different audiences. `schema/reference/privacy.md` is terse (~15–25 lines), agent-facing, extracted from the already-rewritten §13 (CLAUDE.md lines 1556–1559). `docs/reference/privacy-model.md` (126 lines) is the human-readable full model with enforcement options, fail-direction table, and the `sources-local/` forward reference.

**Content:** The asymmetric model structural rule + one-way permeability rule + enforcement mechanism (directory boundary, not per-turn rule). This is the 4-line §13 content expanded slightly to be a standalone reference.

**Structure pattern** (modeled on privacy-model.md's TL;DR section, lines 1–12):
```markdown
# Privacy Routing

> Agent-authoritative reference for wiki privacy tier routing: `wiki-cloud/` (cloud-safe) vs `wiki-local/` (local-only).
> AGENTS.md §13 points here.

## Structural Rule

Vault tier is **structural**: the directory a page lives in determines its privacy tier.

- `wiki-cloud/` — cloud-safe tier. Cloud sessions may read freely.
- `wiki-local/` — local-only tier. Cloud sessions MUST NOT read this tier.

The enforcement mechanism is the **directory boundary** (harness permissions), not a per-turn agent rule.

**One-way permeability:** local sessions read both tiers; cloud sessions read only `wiki-cloud/`.

**Write-back rule:** If ANY contributing source-summary lives under `wiki-local/`, the write-back target page MUST go into `wiki-local/`.

## See Also

- `docs/reference/privacy-model.md` — full asymmetric model: enforcement options (deny-profile vs. separate-repo), fail-direction table, `sources-local/` forward reference.
```

---

### `schema/workflows/lint.md` (seeded partial — Phase 16 creates, Phase 17 owns)

**Analog:** `docs/reference/ci.md` (for cross-reference style and the "source of truth" header note); the content is extracted CLAUDE.md §6 lines 555–578 + 604–618

**Critical scope constraint (CONTEXT.md, RESEARCH.md Pitfall 3):** Phase 16 ONLY seeds this file with the decay math. The lint workflow procedure (§11.3) is Phase 17's addition. The seeded file MUST carry a prominent partial-content header.

**Header pattern (from RESEARCH.md §6 Consumer-Split Seam section):**
```markdown
# Lint Reference: Staleness and Decay

> **Note:** This file contains only the decay table and staleness auto-fix rules (seeded by Phase 16).
> The full lint workflow procedure (`bin/lint.sh` steps, severity tiers, CI flags) is added in Phase 17.
> AGENTS.md §6 decay/staleness content points here.
```

**Content to seed:**
- Domain-Based Decay Rate Table (CLAUDE.md lines 555–566)
- Epistemic status modifiers table (lines 567–574)
- Hash override note + date fallback chain (lines 575–579)
- Staleness Auto-Fix Rules (lines 604–618)

**Template placeholder (RESEARCH.md line 381):** `{{DECAY_PROFILE}}` (template line 569) is in the decay-table section and therefore moves into the TEMPLATE copy of `schema/workflows/lint.md`. The live AGENTS.md/CLAUDE.md has it rendered.

---

### `docs/reference/scaling.md` (end-user reference doc)

**Analog:** `docs/reference/three-layer-model.md` (same informational, non-normative, end-user tone)

**Content to extract:** CLAUDE.md lines 1560–1606 (all of §14 Scaling Boundaries) verbatim.

**File header pattern** (three-layer-model.md line 1):
```markdown
# Scaling Boundaries

> Informational reference for wiki scaling heuristics: when to upgrade from single index to split indexes, incremental lint, and DB-backed metadata. Not normative — these are provisional signals to watch.
```

**Note:** §14 already has an `**Important:** These are provisional heuristics` disclaimer in its first line. Keep it. The docs/reference/ audience is end-users; the informal tier-by-tier progression structure is already appropriate.

**"See also" footer pattern** (three-layer-model.md lines 38–40):
```markdown
## See Also

- [AGENTS.md](../../AGENTS.md) — §14 stub (pointer to this file).
- [docs/reference/index.md](index.md)
```

---

### `docs/reference/tooling.md` (end-user reference doc)

**Analog:** `docs/reference/three-layer-model.md` (non-normative, informational, human-facing)

**Content to extract:** CLAUDE.md lines 1607–1631 (all of §15 Tooling and Integrations) verbatim.

**File header pattern:**
```markdown
# Tooling and Integrations

> Informational reference for tools the wiki is designed to work with. Not normative — the wiki functions as plain markdown files in a git repo regardless of tooling.
```

**Note:** §15 already starts with a blockquote normative disclaimer; preserve it.

---

### `AGENTS.md` / `CLAUDE.md` (in-place extraction, byte-identical pair)

**Analog:** Existing §13 (CLAUDE.md line 1558) — already demonstrates the exact stub form post-Phase-15: a single sentence + pointer, no reproduced content.

**Existing stub analog (CLAUDE.md lines 1556–1558):**
```markdown
## 13. Privacy Routing

Vault tier is structural: `wiki-cloud/` is the cloud-safe tier; `wiki-local/` is the local-only tier. Cloud sessions MUST NOT read `wiki-local/` — the directory boundary is the enforcement mechanism, not a per-turn rule. See `docs/reference/privacy-model.md` for the full asymmetric model...
```

**After Phase 16, §13 stub replaces this with (D-01):**
```
→ See `schema/reference/privacy.md` for the privacy tier rules an agent needs.
  For the full human-facing model: `docs/reference/privacy-model.md`.
```

**Routing table pattern (D-05, REF-08):** Placed immediately after the §1 block and before §2. The existing §13 pointer style shows the tone; the routing table rows follow this format. The IMPORTANT:-flag pattern is new (no existing analog in AGENTS.md) — use a markdown blockquote with bold:

```markdown
> **IMPORTANT — Reference Routing Table**
>
> This file is the router. Each linked file is authoritative for its own sections (D-09).
> Read the target file before acting — do not rely on the stub alone.
>
> | When you need this | Go to |
> |-------------------|-------|
> | Authoring a wiki page (type rules, section order) | `schema/reference/page-types.md` |
> | Checking required frontmatter fields | `schema/reference/frontmatter.md` |
> | Adding `[prov:]` or `[epistemic::]` markers | `schema/reference/provenance.md` |
> | Creating cross-references (wikilinks) | `schema/reference/wikilinks.md` |
> | Determining `wiki-cloud/` vs `wiki-local/` placement | `schema/reference/privacy.md` |
> | Decay table / staleness auto-fix math | `schema/workflows/lint.md` |
> | Running the Ingest workflow | `schema/workflows/ingest.md` *(Phase 17)* |
> | Running the Query workflow | `schema/workflows/query.md` *(Phase 17)* |
> | Running the Lint workflow | `schema/workflows/lint.md` *(Phase 17 adds procedure)* |
> | Running the Reflect workflow | `schema/workflows/reflect.md` *(Phase 17)* |
> | Wiki capacity / scaling signals | `docs/reference/scaling.md` |
> | Obsidian, Git, and optional tools | `docs/reference/tooling.md` |
```

**MUST-NOT list update (D-09, RESEARCH.md line 146):** Line 130 of CLAUDE.md must be updated from:
```
- DO NOT put conventions or rules in any file other than AGENTS.md. This is the sole source of truth.
```
to:
```
- DO NOT put conventions or rules in any file other than AGENTS.md or the files listed in the routing table. AGENTS.md is the router; each linked file is authoritative for its own sections.
```

**Core line 3 update (D-09):** The third line of the document header:
```
> No other file contains conventions, rules, or workflow definitions.
```
becomes:
```
> This file is the router; each linked file listed in the routing table is authoritative for its own sections.
```

**Per-section stub forms (D-01 — bare pointers only):**

| Section | Resident remnant | Stub form |
|---------|-----------------|-----------|
| §4 | 6 type names as compact dispatch list | `→ See \`schema/reference/page-types.md\` for section ordering, authoring conventions, and type details.` |
| §5 | ~4-line Option-B pointer | `→ Full frontmatter schema and validation checklist in \`schema/reference/frontmatter.md\`.` |
| §6 | One line: "Every factual claim MUST have an inline provenance marker `[prov:source_id#locator]`." | `→ Syntax, locator types, epistemic markers, and contradiction markers: \`schema/reference/provenance.md\`.` + `→ Decay table and staleness auto-fix: \`schema/workflows/lint.md\`.` |
| §7 | Dissolves entirely — NO stub, NO remnant | (delete lines 619–654; nav rule already in §3) |
| §8 | One-liner: "Use `[[id|Title]]` for ALL intra-wiki links." | `→ Full wikilink conventions: \`schema/reference/wikilinks.md\`.` |
| §13 | Structural pointer (1 sentence) | `→ See \`schema/reference/privacy.md\` for the agent-facing tier rules.` |
| §14 | Delete, no remnant | `→ See \`docs/reference/scaling.md\` for scaling tier heuristics.` |
| §15 | Delete, no remnant | `→ See \`docs/reference/tooling.md\` for Obsidian, Git, and optional tooling notes.` |
| §16 | Delete entire section (REF-07) | (no stub; routing table row covers Appendix A/B pointers) |

**Propagation protocol:** Every edit to AGENTS.md must be propagated to CLAUDE.md via `bash bin/sync-claude.sh` (no args) before staging. Pre-commit hook enforces byte equality.

---

### `schema/AGENTS.template.md` (stub mirror, REF-09)

**Analog:** The existing template (1,621 lines) is 34 lines shorter than CLAUDE.md. The delta is the 4 `{{placeholder}}` occurrences and their surrounding context.

**Mirror rule (RESEARCH.md line 242):** Every stub added to AGENTS.md is added at the same logical position in AGENTS.template.md with identical text. The `bin/sync-claude.sh --check` gate does NOT validate the template — this is a manual correctness requirement enforced by careful parallel editing.

**Placeholder preservation (RESEARCH.md lines 374–385):** Five `{{...}}` occurrences exist:
- Template line 34: `{{AGENT_FILENAME}}` — in §1, stays
- Template line 63: `{{PRIMARY_DOMAIN}}` — in §2, stays
- Template line 285: `knowledge_domain: "{{PRIMARY_DOMAIN}}"` — in §5 block, MOVES to `schema/reference/frontmatter.md` in the template copy
- Template line 286: `privacy_default: {{DEFAULT_PRIVACY}}` — in §5 block, MOVES to `schema/reference/frontmatter.md` in the template copy
- Template line 569: `{{DECAY_PROFILE}}` — in §6 decay section, MOVES to `schema/workflows/lint.md` in the template copy

The wizard renders ONLY AGENTS.template.md → AGENTS.md. The extracted files are shipped wholesale via the release ALLOWLIST. No new render logic is needed.

---

### `bin/check-neutrality.sh` (one-line PUBLIC_PATHS extension)

**Analog:** The existing file itself; the change is Wave 0 (before first extraction commit).

**Existing PUBLIC_PATHS (line 94):**
```bash
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin)
```

**After Phase 16 Wave 0 (add `schema`):**
```bash
PUBLIC_PATHS=(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin schema)
```

This extends neutrality scanning coverage to the new `schema/reference/*.md` and `schema/workflows/lint.md` files without changing any scanner logic.

---

### `wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md` (decision record, REF-10)

**Analog:** `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` — same-day schema-update DR; most structurally similar (same `trigger_type: schema-update`, same `epistemic_status: sourced`, same day, same execution-time authoring pattern)

**Frontmatter pattern** (from dr-2026-06-04-privacy-asymmetric-two-dir.md lines 1–37):
```yaml
---
id: dr-2026-06-04-reference-extraction
title: "Reference Extraction: AGENTS.md Monolith to schema/reference/ + schema/workflows/"
type: decision
status: active
summary: "Extracts §4/§5/§6/§7/§8/§13/§14/§15/§16 from the AGENTS.md monolith into
  standalone leaf files under schema/reference/ and schema/workflows/; AGENTS.md becomes
  a router with bare stubs; evolves 'sole source of truth' framing to 'router + per-section authority'."
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
affected_pages:
- index
- log
---
```

**Section ordering (all 7 required sections per CLAUDE.md §4.6):**
TL;DR → Decision → Why → Alternatives Considered → Consequences → Affected Pages → Sources

**Why section must cover (D-09):** The old framing ("no other file contains conventions") and the new framing ("this file is the router; each linked file is authoritative for its own sections"). Must reference the inclusion test (what earns residence vs. extraction) and the D-04 §4 names-only decision.

---

## Shared Patterns

### Stub/routing pointer style (D-01)
**Source:** §13 in live CLAUDE.md (line 1558) — the only existing bare-pointer stub in core
**Apply to:** Every extracted section replacement in AGENTS.md/CLAUDE.md
```
→ See `schema/reference/X.md` [brief one-line note on what's there].
```

### "Source of truth" lede for `schema/reference/*.md` files
**Source:** `docs/reference/ci.md` lines 17–18; `docs/reference/schema-tour.md` lines 7–9
**Apply to:** All five `schema/reference/*.md` files (inverted from docs/ pattern: HERE is the authority)
```markdown
> Agent-authoritative reference for [topic]. AGENTS.md §N points here.
> [Optional: For end-user full model, see docs/reference/X.md]
```

### "Informational, not normative" lede for `docs/reference/*.md` files
**Source:** `docs/reference/three-layer-model.md` line 1 (prose); §15 opening blockquote (CLAUDE.md line 1609)
**Apply to:** `docs/reference/scaling.md`, `docs/reference/tooling.md`
```markdown
> This section is informational, not normative. [Brief one-liner on what's here.]
```

### "See Also" footer section
**Source:** `docs/reference/privacy-model.md` lines 121–127; `docs/reference/agent-parity.md` lines 91–97
**Apply to:** All new `schema/reference/*.md` and `docs/reference/scaling.md`, `docs/reference/tooling.md`
```markdown
## See Also

- [AGENTS.md](../../AGENTS.md) — §N stub (pointer to this file).
- [related-file.md](related-file.md) — [one-line note].
```

### Byte-equality propagation protocol
**Source:** `bin/sync-claude.sh` (existing pre-commit gate)
**Apply to:** Every task that edits AGENTS.md
Run `bash bin/sync-claude.sh` (no args) after each AGENTS.md edit. Stage both AGENTS.md and CLAUDE.md before committing. The pre-commit hook enforces `--check` (cmp -s byte equality) and will block the commit if only one file is updated.

### Decision record frontmatter (trigger_type: schema-update)
**Source:** `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` (lines 1–37)
**Apply to:** REF-10 decision record
```yaml
trigger_type: schema-update
affected_pages: [index, log]
epistemic_status: sourced
knowledge_domain: software
```

---

## No Analog Found

No files in this phase lack a close analog. All pattern guidance is derivable from existing codebase files.

---

## Implementation Notes for Planner

### Wave 0 (before any extraction)
1. Add `schema` to `PUBLIC_PATHS` in `bin/check-neutrality.sh` line 94 — single-line edit, separate commit or bundled with first extraction commit.
2. Create `schema/reference/` and `schema/workflows/` directories (via first file creation in each).

### Sequencing constraint
Extractions should proceed in section order (§4 → §5 → §6 → §7-dissolve → §8 → §13 → §14 → §15 → §16-delete → routing-table-addition). Each section extraction is a candidate for its own commit, but the byte-equality gate requires AGENTS.md + CLAUDE.md + AGENTS.template.md to be updated atomically per commit. The routing table addition is last (it references all target files, which must exist before the routing table is finalized).

### §7 dissolution has no stub and no remnant
Lines 619–654 are deleted entirely. Nav rule is already at §3 lines 113–121 (stays). Per-type section ordering table (lines 635–643) moves to `schema/reference/page-types.md`. "Why This Matters" rationale (lines 645–654) is absorbed into page-types.md or deleted (redundant with §1 principle).

### §16 requires pre-deletion audit (RESEARCH.md Pitfall 6)
Before deleting lines 1632–1655, verify Appendix C rule 6 ("Privacy default: wiki-local/ tier") appears in the MUST-NOT list or routing table. The routing table row for `schema/reference/privacy.md` should include a note covering this.

### AGENTS.template.md placeholder migration
Three `{{placeholder}}` lines move with extracted sections:
- `{{PRIMARY_DOMAIN}}` (×2, lines 285–286 in §5 block) → `schema/reference/frontmatter.md` (template copy only)
- `{{DECAY_PROFILE}}` (line 569 in §6 decay block) → `schema/workflows/lint.md` (template copy only)

These move ONLY in the template. The live AGENTS.md/CLAUDE.md has rendered values at those positions; the rendered values move into the leaf files unchanged.

---

## Metadata

**Analog search scope:** `docs/reference/` (13 files), `schema/templates/` (6 files), `wiki-cloud/decisions/` (9 files), `bin/check-neutrality.sh`, `schema/AGENTS.template.md`, live `CLAUDE.md`
**Files scanned:** 19
**Pattern extraction date:** 2026-06-04

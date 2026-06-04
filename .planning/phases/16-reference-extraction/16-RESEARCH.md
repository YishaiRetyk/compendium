# Phase 16: Reference Extraction — Research

**Researched:** 2026-06-04
**Domain:** Markdown extraction and routing-stub refactoring of a monolithic spec file
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Extraction stubs carry ZERO reproduced reference content. Each extracted section collapses to a bare pointer (`→ see schema/reference/X.md`).
- **D-02:** The resident safety core is NOT an extraction stub and stays resident. The four always-loaded safety items (MUST-NOT list verbatim, write-back-mandatory line, structured-op vocabulary, provenance requirement one-liner) remain in core.
- **D-03:** §6 keeps its one-line provenance requirement but DROPS the inline example. The example extracts to `provenance.md`.
- **D-04:** Core keeps the 6 type names (dispatch vocabulary); the section-ordering tables EXTRACT to `page-types.md`. Section-ordering tables fail all three inclusion-test clauses — they have a clean JIT load point (authoring time) and a gate-caught miss-cost (lint validates per-type structure).
- **D-05:** The `IMPORTANT:`-flagged routing table is keyed by BOTH the 4 operations (ingest/query/lint/reflect) AND static topics (page-types, frontmatter, provenance, wikilinks, privacy), each row → target file + a one-line "when you need this." ~30 lines.
- **D-06:** Phase 16 scope for REF-09 = the EXISTING `AGENTS.md ≡ CLAUDE.md` byte-check + mirror all routing stubs into `schema/AGENTS.template.md`. No new tree-drift tooling in Phase 16.
- **D-07:** Add `bin/sync-claude.sh --check-tree` guard at the END of Phase 17, not Phase 16. The full schema/reference|workflows/*.md tree does not fully exist until Phase 17 finishes.
- **D-08:** What `--check-tree` guards = "every routing-stub target in core resolves to a file that exists" — a link-target existence/resolution check, not a byte-compare. Carry to Phase 17's WF requirements.
- **D-09:** Evolve core line 3 ("No other file contains conventions, rules, or workflow definitions") to "this file is the router; each linked file is authoritative for its own sections."

### Claude's Discretion

All plan-time mechanics: exact stub wording, the precise routing-table row set and ordering, the extraction/move sequencing and commit structure, the `--check-tree` implementation details (Phase 17), the AGENTS.template.md mirror mechanics, and how `schema/workflows/lint.md` is seeded for the §6 decay/staleness math without pre-empting Phase 17's ownership. The Extraction Map's exact line ranges + the decisions above are sufficient direction.

### Deferred Ideas (OUT OF SCOPE)

- `bin/sync-claude.sh --check-tree` — built at END of Phase 17, not Phase 16 (D-07).
- Open Q9 (solo structured-op commit prefix) and Open Q10 (mutation→log coupling gate) — Phase 17.
- `schema/workflows/*.md` (except the lint.md decay/staleness seed) — Phase 17.
- `phase-14-lint-mask-fence-edge-cases` — deferred lint tooling; not this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REF-01 | Extract §4 page types → `schema/reference/page-types.md`; merge its section-ordering table with §7's into one resident type-roster (§4↔§7 dedupe, LOCKED) | D-04 names-only residue confirmed; §7 orderings consolidate into page-types.md |
| REF-02 | Extract §5 frontmatter → `schema/reference/frontmatter.md`; core keeps Option-B pointer only (~4 lines, LOCKED) | §5 is 140 lines (259–398); pointer-only stub is the right form per D-01 |
| REF-03 | Extract §6 with consumer-split: syntax/epistemics → `schema/reference/provenance.md`; decay table + staleness auto-fix → `schema/workflows/lint.md` (lint only consumer of decay math) | Consumer-split seam confirmed at line 555 (decay table starts) and 604 (staleness auto-fix); see §6 Split Seam section |
| REF-04 | §7 dissolves into the §4 roster (orderings) + §3 (nav rule); no standalone progressive-disclosure file | §7 is lines 619–654; nav rule already at §3 lines 113–121; per-type section-ordering table at §7 lines 635–643 merges into page-types.md |
| REF-05 | Extract §8 wikilinks → `schema/reference/wikilinks.md` (+ §3 Red Links); carry v1.1.1 uniform-piped-link truth verbatim | §8 is lines 655–705; §3 Red Links at lines 123–125; verbatim link resolution truth is at §8 lines 659–670 |
| REF-06 | Extract §13 in its Phase-15 asymmetric form → `schema/reference/privacy.md`; 7-row precedence table removed, not relocated | §13 is now a 2-line structural pointer (lines 1556–1559); extracts fully; relationship to docs/reference/privacy-model.md documented below |
| REF-07 | §14 Scaling → `docs/reference/scaling.md`; §15 Tooling → `docs/reference/tooling.md`; §16 Appendices deleted | §14: lines 1560–1606; §15: lines 1607–1631; §16: lines 1632–1655; no target files exist yet |
| REF-08 | Add `IMPORTANT:`-flagged routing table to top of core; operation→file dispatch, ~30 lines | Two-axis design confirmed; see Routing Table Design section for exact rows |
| REF-09 | Mirror every routing stub into `schema/AGENTS.template.md`; keep `AGENTS.md` byte-identical to `CLAUDE.md` | sync-claude.sh --check is a cmp -s byte compare; template is 1621 lines (vs 1655 CLAUDE.md — 34-line delta is the 4 {{placeholders}} and their surrounding context) |
| REF-10 | Decision record (`trigger_type: schema-update`) for the extraction + evolved "sole authoritative specification" framing (D-09) | DR-at-execution precedent confirmed; record written when the change ships |
</phase_requirements>

---

## Summary

Phase 16 is a mechanical text-extraction and file-creation refactor. The live `CLAUDE.md` / `AGENTS.md` is 1,655 lines (the milestone brief estimated 1,689 — the 34-line difference is confirmed: the brief was measured before Phase 15 removed the per-page privacy machinery). `schema/AGENTS.template.md` is 1,621 lines (34 fewer than CLAUDE.md due to the 4 `{{placeholder}}` lines and their context that differ between template and rendered output).

The work is purely textual: cut sections out of core, create new leaf files, replace each cut with a bare stub, add a routing table at the top, and mirror stubs into the template. No behavior changes. All CI gates (lint, neutrality, privacy-leak, setup-parity) must stay green. The critical constraint is the `AGENTS.md ≡ CLAUDE.md` byte-equality enforced by `bin/sync-claude.sh --check` at every commit.

**Primary recommendation:** Execute extractions in section order (§4→§5→§6→§7→§8→§13→§14→§15→§16→routing table), with AGENTS.md as the write target and sync-claude.sh run after every section to propagate to CLAUDE.md. The template mirror (REF-09) is a separate parallel task that can trail by one section.

The single architectural complexity is the **§6 consumer-split** (REF-03): the decay table + staleness auto-fix (§6 lines 555–617) route to `schema/workflows/lint.md` while the rest of §6 routes to `schema/reference/provenance.md`. Phase 16 creates and seeds `schema/workflows/lint.md` but must NOT populate it with anything beyond the decay table + staleness auto-fix content; the rest of `schema/workflows/lint.md` (the full lint workflow from §11.3) is Phase 17's responsibility.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Core spec authoring (AGENTS.md/CLAUDE.md) | Schema/spec layer | — | Byte-identical pair enforced by pre-commit hook |
| Reference leaf files (schema/reference/*.md) | Schema/spec layer | — | Agent-authoritative; no wiki page type; not lint-scanned |
| Workflow seed files (schema/workflows/lint.md) | Schema/spec layer | Phase 17 (full ownership) | Phase 16 creates + seeds decay/staleness only |
| Template mirror (AGENTS.template.md) | Schema/spec layer | — | Stubs mirror verbatim; {{placeholders}} preserved unchanged |
| End-user reference (docs/reference/*.md) | Docs layer | — | §14/§15 land here; human-readable, not agent-authoritative |
| CI gates | Tooling layer | — | Behavior unchanged; operate on content not file boundaries |
| Decision record (REF-10) | wiki-cloud/decisions/ | — | Authored at execution time; standard DR workflow |

---

## Exact Section Line Ranges (Live CLAUDE.md, 1,655 lines)

[VERIFIED: direct file inspection of CLAUDE.md]

| Section | Start | End | Lines | Extraction target |
|---------|------:|----:|------:|-------------------|
| §1 Overview + 4-op table | 1 | 33 | 33 | STAY (distill) |
| §2 Directory Structure | 34 | 88 | 55 | SPLIT: tree stays; redundant prose candidate for removal |
| §3 Date/snake_case | 91 | 97 | 7 | STAY |
| §3 Commit Conventions | 99 | 111 | 13 | SPLIT: 1-line granularity stays; commit table → routing-table column (Phase 16 removes the table, keeps one line) |
| §3 Navigation Rule | 113 | 121 | 9 | STAY (distill) |
| §3 Red Links | 123 | 125 | 3 | EXTRACT → `schema/reference/wikilinks.md` (REF-05) |
| §3 MUST-NOT list | 127 | 140 | 14 | STAY verbatim (D-02 safety core) |
| **§4 Page Types** | **141** | **258** | **118** | **EXTRACT → `schema/reference/page-types.md`** (REF-01); core keeps 6 type names only (D-04) |
| **§5 Frontmatter** | **259** | **398** | **140** | **EXTRACT → `schema/reference/frontmatter.md`** (REF-02); core keeps ~4-line Option-B pointer |
| **§6 Provenance (syntax/epistemics)** | **399** | **553** | **155** | **EXTRACT → `schema/reference/provenance.md`** (REF-03); core keeps 1-line provenance requirement (D-03, not the example) |
| **§6 Decay table + staleness auto-fix** | **555** | **618** | **64** | **EXTRACT → `schema/workflows/lint.md`** (REF-03 consumer-split; Phase 16 seeds this file, Phase 17 owns it) |
| **§7 Progressive Disclosure** | **619** | **654** | **36** | **DISSOLVE** (REF-04): nav rules already at §3; per-type ordering table (lines 635–643) merges into page-types.md |
| **§8 Wikilinks** | **655** | **705** | **51** | **EXTRACT → `schema/reference/wikilinks.md`** (REF-05); core keeps ~2-line one-liner |
| §9 Structured Ops | 706 | 809 | 104 | Phase 17 scope — DO NOT TOUCH |
| §10 Pipeline | 810 | 908 | 99 | Phase 17 scope — DO NOT TOUCH |
| §11 Workflows | 909 | 1455 | 547 | Phase 17 scope — DO NOT TOUCH |
| §12 Index and Log | 1456 | 1555 | 100 | Phase 17 scope — DO NOT TOUCH |
| **§13 Privacy** | **1556** | **1559** | **4** | **EXTRACT → `schema/reference/privacy.md`** (REF-06); §13 is already a 2-line pointer post-Phase-15; the stub replaces the 2-line content |
| **§14 Scaling** | **1560** | **1606** | **47** | **EXTRACT → `docs/reference/scaling.md`** (REF-07) |
| **§15 Tooling** | **1607** | **1631** | **25** | **EXTRACT → `docs/reference/tooling.md`** (REF-07) |
| **§16 Appendices** | **1632** | **1655** | **24** | **DELETE** (REF-07): already pure pointers |
| NEW | — | — | ~30 | **Routing table added at top of core** (REF-08) |

**Note on §6 consumer-split boundary:** [VERIFIED: direct line inspection]
- Line 542: `### Mixed Inline Grammar` (last provenance-syntax subsection before split)
- Line 553: end of Mixed Inline Grammar content
- Line 555: `### Domain-Based Decay Rate Table` — first lint-owned line
- Line 580: `### Contradiction Inline Syntax` (back to provenance-ref scope; this is the tricky case — see §6 Split Seam section below)
- Line 604: `### Staleness Auto-Fix Rules` (lint-owned)
- Line 618: end of §6

**§6 Split Seam Detail:** The Extraction Map routes lines 397–550 and 576–599 to `provenance.md`, and lines 551–575 (decay table) + 600–614 (staleness auto-fix) to `workflows/lint.md`. Mapping to actual live lines:
- `provenance.md` gets: lines 399–553 (provenance syntax through Mixed Inline Grammar) + lines 580–602 (Contradiction Inline Syntax subsection)
- `workflows/lint.md` gets: lines 555–578 (Decay Rate Table + epistemic modifiers + hash override + date fallback chain) + lines 604–618 (Staleness Auto-Fix Rules)

The Contradiction Inline Syntax (lines 580–602) is provenance-consumer content (it describes a marker format, not decay math), so it routes to `provenance.md` NOT `workflows/lint.md`.

---

## Resident Remnant Specification

[VERIFIED: milestone brief + D-01 through D-04 + direct CLAUDE.md inspection]

| Section | What stays in core |
|---------|-------------------|
| §1 | Identity paragraph + 4-op vocabulary table (dispatch) |
| §2 | Directory tree + Permitted top-level dirs (~14 lines) |
| §3 Date/snake | Both rules (~3 lines, ambient) |
| §3 Commit | One line only: "One commit per logical operation. A single ingest that touches 15 files is one commit." (D-01: commit table extracts; D-04 rationale: JIT load point per workflow) |
| §3 Navigation | Read index.md first; TL;DR/Key Facts before Detail; Detail only when insufficient (~6 lines, dispatch) |
| §3 Red Links | Bare stub → `schema/reference/wikilinks.md` (D-01) |
| §3 MUST-NOT | Full verbatim list, lines 127–140 (D-02 safety core) — BUT line 130 "DO NOT put conventions or rules in any file other than AGENTS.md" must be updated to reflect D-09 framing |
| §4 | 6 type names as a compact dispatch list (D-04): entity, concept, source, comparison, overview, decision — with stub → `schema/reference/page-types.md` |
| §5 | Option-B pointer: ~4 lines stating that full frontmatter schema is in `schema/reference/frontmatter.md` (LOCKED) |
| §6 | One line: "Every factual claim MUST have an inline provenance marker `[prov:source_id#locator]` — see `schema/reference/provenance.md`." (D-03: requirement only, no inline example) |
| §7 | Dissolves entirely; no remnant, no stub |
| §8 | One-liner: "Use `[[id|Title]]` for ALL intra-wiki links — see `schema/reference/wikilinks.md`." (~2 lines) |
| §13 | Structural pointer: "Vault tier is structural: `wiki-cloud/` is cloud-safe; cloud sessions MUST NOT read `wiki-local/` — see `schema/reference/privacy.md`." (D-16 from Phase 15 CONTEXT.md) |

**Critical line 130 update:** The MUST-NOT item "DO NOT put conventions or rules in any file other than AGENTS.md. This is the sole source of truth." is a logical contradiction once reference files exist. The planner must update this line to: "DO NOT put conventions or rules in any file other than AGENTS.md or the files it links to in `schema/reference/` and `schema/workflows/`." This is the D-09 framing change applied to a safety-core item.

---

## Routing Table Design (REF-08, D-05)

[ASSUMED: exact rows and wording are Claude's Discretion per CONTEXT.md, but structure is locked by D-05]

The routing table is IMPORTANT:-flagged, two-axis (4 operations × static reference topics), ~30 lines, placed immediately after the §1 identity block and before §2 Directory Structure.

**Row structure:** Each row maps a use-case anchor to the target file with a one-line "when you need this."

**Operation rows (4):** ingest, query, lint, reflect — each pointing to `schema/workflows/{op}.md` (these files will be created in Phase 17; the routing table can pre-declare them as "coming in Phase 17" or the table can be seeded in Phase 17 instead — see Phase 17 Coordination section).

**Topic rows (static reference):**

| Topic | Target File | When you need this |
|-------|-------------|-------------------|
| Page type rules + section order | `schema/reference/page-types.md` | Authoring a new wiki page |
| Frontmatter fields + validation checklist | `schema/reference/frontmatter.md` | Checking required fields or running lint |
| Provenance syntax + epistemic markers | `schema/reference/provenance.md` | Adding `[prov:]` or `[epistemic::]` markers |
| Wikilink conventions | `schema/reference/wikilinks.md` | Creating cross-references |
| Privacy + tier routing | `schema/reference/privacy.md` | Determining `wiki-cloud/` vs `wiki-local/` placement |

**Open question for planner:** Should the 4 operation rows be pre-populated pointing to `schema/workflows/*.md` (which don't exist yet), or should the routing table be added in Phase 16 with only the reference rows, and the workflow rows added by Phase 17? The safer approach is to add stub operation rows with a note "→ see schema/workflows/{op}.md (added in Phase 17)" — this makes the routing table complete and functional from Phase 16's end.

---

## Architecture Patterns

### Target File Inventory (Phase 16 creates these)

```
schema/
├── reference/             ← NEW directory (Phase 16)
│   ├── page-types.md      ← REF-01 (§4 + §7 orderings)
│   ├── frontmatter.md     ← REF-02 (§5)
│   ├── provenance.md      ← REF-03 (§6 syntax/epistemics)
│   ├── wikilinks.md       ← REF-05 (§8 + §3 Red Links)
│   └── privacy.md         ← REF-06 (§13 asymmetric form)
├── workflows/             ← NEW directory (Phase 16 creates; Phase 17 owns)
│   └── lint.md            ← REF-03 consumer-split seed (decay table + staleness auto-fix)
└── AGENTS.template.md     ← MODIFIED (REF-09: stubs mirrored)

docs/reference/
├── scaling.md             ← NEW (REF-07: §14)
└── tooling.md             ← NEW (REF-07: §15)

AGENTS.md / CLAUDE.md      ← MODIFIED (all extracted sections → stubs + routing table)
wiki-cloud/decisions/
└── dr-2026-06-04-reference-extraction.md  ← NEW (REF-10)
```

### Stub Format Pattern (D-01)

Every extracted section becomes a bare pointer. No reproduced content. The exact wording is Claude's discretion, but the form is:

```
→ See `schema/reference/page-types.md`
```

Or with a note on what's there:
```
→ Full schema in `schema/reference/frontmatter.md` (lint validates all fields automatically).
```

The safety core items (MUST-NOT list, provenance requirement, ops vocab) are NOT stubs — they remain resident verbatim or as single-line summaries per D-02/D-03.

### §6 Consumer-Split Seam (REF-03)

This is the one cross-phase seam. `schema/workflows/lint.md` is seeded by Phase 16 with ONLY:
1. The Domain-Based Decay Rate Table (lines 555–566 approximately)
2. The epistemic status modifiers table (lines 567–574)
3. Hash override note (line 576) + date fallback chain (lines 578–579)
4. Staleness Auto-Fix Rules (lines 604–618)

Phase 16 MUST NOT add any of the lint workflow procedure (§11.3, lines 1057–1163) to `schema/workflows/lint.md`. Phase 17 adds the procedure. The seeded file should have a clear header noting it is partial:

```markdown
# Lint Reference: Staleness and Decay

> **Note:** This file contains only the decay math (seeded by Phase 16).
> The full lint workflow procedure is added in Phase 17.
```

### §7 Dissolution Pattern (REF-04)

§7 has two parts:
1. **Rules for LLM Agents** (lines 623–631): 7 rules for how to navigate the wiki. Rules 1–3 duplicate §3 Navigation Rule. Rules 4–7 (TL;DR MUST be 1 paragraph, Key Facts MUST be compact bullets, Detail contains full narrative, Sources at bottom) are **authoring guidance** that belongs in `page-types.md` as annotations on the section-ordering table.
2. **Per-Type Section Ordering table** (lines 635–643): merges into `page-types.md` per the §4↔§7 dedupe.
3. **Why This Matters** (lines 645–654): can be deleted (redundant with the principle already in §1) or folded into `page-types.md` as a brief rationale.

§7 is dissolved with NO stub — the nav rule already lives in §3, and authoring guidance moves to `page-types.md`.

### AGENTS.template.md Mirror (REF-09)

The template (1,621 lines) is 34 lines shorter than CLAUDE.md (1,655 lines). The delta is the 4 `{{placeholder}}` lines and surrounding context unique to the template. For every stub added to AGENTS.md, the identical stub text is added to the same logical position in AGENTS.template.md. The `bin/sync-claude.sh --check` gate only validates AGENTS.md ≡ CLAUDE.md byte equality — it does NOT validate AGENTS.template.md. The template mirror is a manual correctness requirement (REF-09) enforced by human review, not a gate.

The 4 existing placeholders in the template are: `{{AGENT_FILENAME}}`, `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{DECAY_PROFILE}}`. These must NOT be disturbed. The template has identical content to CLAUDE.md for all non-placeholder lines, so stub additions can be applied with a parallel mechanical edit.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Byte-equality enforcement | A new comparison script | `bin/sync-claude.sh` (existing) | Already enforced by pre-commit hook |
| CLAUDE.md ≡ AGENTS.md propagation | Manual copy | `bin/sync-claude.sh` (no args) | Atomic, verified copy |
| Neutrality scan on new files | A new scanner | `bin/check-neutrality.sh` (with `schema/` added to PUBLIC_PATHS — see Critical Gap below) | Existing scanner; adding `schema/` to its PUBLIC_PATHS covers the new tree |
| Phase 17 --check-tree | Don't build in Phase 16 | Defer to Phase 17 per D-07 | Full tree doesn't exist until Phase 17 completes |

**Critical Gap — neutrality gate does not currently cover `schema/`:**

[VERIFIED: direct inspection of bin/check-neutrality.sh line 94]

`check-neutrality.sh` PUBLIC_PATHS = `(AGENTS.md CLAUDE.md README.md PRIVACY.md docs .github wiki-cloud bin)`. The `schema/` directory is NOT in this list. However, `schema/` IS in the release ALLOWLIST (bin/release.sh line ~29) — it ships publicly. This means extracted `schema/reference/*.md` files would NOT be covered by the CI neutrality gate.

**Resolution:** Phase 16 must add `schema` to the `PUBLIC_PATHS` array in `bin/check-neutrality.sh` (line 94). This is a one-line change that adds neutrality coverage for the new `schema/reference/` tree (and any future `schema/workflows/` files in Phase 17). This is NOT a behavioral change to the existing scanner — it merely extends coverage to a previously-unscanned-but-public path. The neutrality constraint is already required by the `template-public files` rule in §3 MUST-NOT (schema/ extracts from AGENTS.md which already meets neutrality).

---

## CI Gate Behavior Analysis

[VERIFIED: direct inspection of all relevant scripts and workflows]

### Gates That Must Stay Green

| Gate | Script | What It Checks | Impact of Phase 16 |
|------|--------|----------------|--------------------|
| `neutrality` (CI) | `bin/check-neutrality.sh` | PUBLIC_PATHS for denylist terms | **Must add `schema` to PUBLIC_PATHS** (see Critical Gap above) |
| `CLAUDE.md drift` (CI) | `bin/sync-claude.sh --check` | byte equality AGENTS.md ≡ CLAUDE.md | Every extraction must update BOTH files atomically |
| `lint` (CI 3-job) | `bin/lint.sh --ci` | wiki-cloud/ page structure, provenance, etc. | **Not impacted** — lint only scans `wiki-cloud/` and `wiki-local/`, never `schema/reference/` |
| `privacy-leak` (CI) | `bin/check-privacy.sh` | PUBLIC_PATHS for `wiki-local/` path leaks | Not impacted — new files don't contain `wiki-local/` paths |
| `setup-parity` (CI) | `bin/init-wizard.sh --render-to` + test | wizard AGENTS.md output == manual-setup output | **Impacted** — see init-wizard analysis below |
| `strict` (CI) | `bin/lint.sh --strict` | new pages must have `[prov:]` markers | **Not impacted** — schema/reference/*.md are NOT wiki pages; strict mode only checks wiki-cloud/ types |
| pre-commit | `.githooks/pre-commit` | `sync-claude.sh --check` + `lint.sh --staged` | Every extraction commit must run sync-claude.sh to propagate |

### init-wizard Analysis (REF-09, setup-parity)

[VERIFIED: inspection of bin/init-wizard.sh]

`bin/init-wizard.sh` renders `schema/AGENTS.template.md` through 4-token substitution into `AGENTS.md`. It does NOT copy `schema/reference/*.md` or `schema/workflows/*.md` — those are separate files that a new user will get wholesale via the public release (they're in the ALLOWLIST). The wizard only renders the template into AGENTS.md.

The design constraint from the milestone brief ("extracted files copied wholesale — no new render logic") means:
- Phase 16 adds new files to `schema/reference/` and `schema/workflows/lint.md`
- These files ship via the release ALLOWLIST under `schema` (already present)
- The wizard's rendering logic is unchanged — it still only renders AGENTS.template.md
- `setup-parity` CI gate tests that the wizard renders correctly — since the template's stub text is mirrored from AGENTS.md, the gate stays green as long as the template is updated in parallel with AGENTS.md

**No new render logic is needed.** The `--dry-run` output is unchanged for existing {{placeholder}} substitutions.

### §2 Directory Structure Note (MUST-NOT rule update)

§3 MUST-NOT item at line 130: "DO NOT put conventions or rules in any file other than AGENTS.md." This rule must be updated as part of D-09 framing evolution. Suggested replacement: "DO NOT put conventions or rules in any file other than AGENTS.md or the files listed in the routing table." The planner should include this update in the same task that adds the routing table.

---

## §13 → privacy.md vs docs/reference/privacy-model.md Relationship

[VERIFIED: inspection of docs/reference/privacy-model.md]

After Phase 15, §13 in CLAUDE.md is already reduced to a 2-line structural pointer (lines 1556–1559):

```
Vault tier is structural: `wiki-cloud/` is the cloud-safe tier; `wiki-local/` is the local-only tier.
Cloud sessions MUST NOT read `wiki-local/` — the directory boundary is the enforcement mechanism,
not a per-turn rule. See `docs/reference/privacy-model.md` for the full asymmetric model,
enforcement options (deny-profile vs. separate-repo), honest fail-direction table, and the
`sources-local/` forward reference for future local raw sources.
```

The new **`schema/reference/privacy.md`** (REF-06) is the agent-authoritative terse reference:
- Content: the asymmetric model structural rule + the one-way permeability rule + the enforcement mechanism (harness permission, not agent rule)
- Length: brief (~15–25 lines); purely the rules an agent needs
- Audience: LLM agents that have reached this file from the routing table

The existing **`docs/reference/privacy-model.md`** (126 lines) is the end-user full model:
- Content: full explanation, enforcement options (deny-profile vs. separate-repo), fail-direction table, sources-local/ forward reference
- Audience: humans setting up the system

**No duplication conflict:** the two files serve different audiences. `schema/reference/privacy.md` should link to `docs/reference/privacy-model.md` for the full human-readable explanation. The §13 stub in core will point to `schema/reference/privacy.md` (not docs/reference/privacy-model.md, which it currently points to).

---

## Common Pitfalls

### Pitfall 1: Forgetting to Update CLAUDE.md in Same Commit

**What goes wrong:** AGENTS.md is updated with a stub; CLAUDE.md is not; pre-commit hook fires `sync-claude.sh --check` → DRIFT error, commit blocked.
**Why it happens:** Two files must be byte-identical but only AGENTS.md is naturally edited.
**How to avoid:** Run `bash bin/sync-claude.sh` (no args) after every AGENTS.md edit to copy it to CLAUDE.md. Stage both files before committing.
**Warning signs:** "DRIFT: CLAUDE.md differs from AGENTS.md" in pre-commit output.

### Pitfall 2: Forgetting to Mirror Stubs into AGENTS.template.md (REF-09)

**What goes wrong:** AGENTS.md has stubs; template does not; setup-parity CI fails because the wizard renders the old template which still has the full section text, but the test compares against the expected stub form.
**Why it happens:** Three files must stay in sync (AGENTS.md, CLAUDE.md, AGENTS.template.md) but only sync-claude.sh is automated.
**How to avoid:** Every stub addition to AGENTS.md must be replicated verbatim to AGENTS.template.md at the same logical position. Treat the template as a parallel edit surface.
**Warning signs:** setup-parity CI failure; diff between rendered AGENTS.md and expected output.

### Pitfall 3: Putting Content in the §6 Staleness Seed Beyond Its Scope

**What goes wrong:** Phase 16 adds decay table + staleness auto-fix to `schema/workflows/lint.md`, then also adds the full lint workflow procedure from §11.3. Phase 17 then has to reconcile two versions.
**Why it happens:** The lint.md file is convenient; it's tempting to put all lint-related content there at once.
**How to avoid:** Phase 16 ONLY seeds `schema/workflows/lint.md` with: (a) the Decay Rate Table, (b) the epistemic modifiers table, (c) the hash override + date fallback chain, and (d) the Staleness Auto-Fix Rules. Add a clear note at the top that the lint workflow procedure (from §11.3) is Phase 17 scope.

### Pitfall 4: Leaving §7's Nav Rules Duplicated in §3

**What goes wrong:** §7 is dissolved, but its LLM navigation rules (read index.md first; TL;DR/Key Facts before Detail) are left behind as a second copy in the §7 location without noticing they're already in §3.
**Why it happens:** The dissolution instruction says "nav rules already in §3" but may not be obvious which lines to delete.
**How to avoid:** When dissolving §7, delete ALL of lines 619–654. The nav rules are confirmed at §3 lines 113–121; the per-type section ordering table goes to `page-types.md`; the "Why This Matters" rationale can be folded into page-types.md or deleted (it is redundant with §1 principle).

### Pitfall 5: Breaking the MUST-NOT Line About "Sole Source of Truth"

**What goes wrong:** §3 MUST-NOT line 130 says "DO NOT put conventions or rules in any file other than AGENTS.md." After extraction, this statement is factually wrong and would contradict the routing table.
**Why it happens:** It's a safety-core item (D-02) so feels like it must be preserved verbatim.
**How to avoid:** This specific line MUST be updated as part of D-09. The MUST-NOT list stays resident verbatim for the other 13 items; this one item must be updated to reflect the new router-plus-leaves model.

### Pitfall 6: §16 Deletion Dropping the Appendix C Quick Reference Card

**What goes wrong:** Appendix C (lines 1644–1655 — a "Quick Reference Card" with 10 rules) is deleted along with §16, but some of its rules (e.g. "Privacy default: wiki-local/ tier") should not be deleted silently — they may need to move.
**Why it happens:** "§16 deleted" is the verdict, but §16 contains substantive safety reminders.
**How to avoid:** Before deleting §16, audit Appendix C rule-by-rule: rules already covered by the routing table / MUST-NOT list need no action; rules not covered elsewhere should be absorbed into the routing table or MUST-NOT list. Rule 6 ("Privacy default: wiki-local/ tier") is particularly important — verify it appears in the MUST-NOT list or routing table before deleting.

---

## AGENTS.template.md Placeholder Preservation

[VERIFIED: inspection of schema/AGENTS.template.md — 5 occurrences of {{...}}]

The 4 template placeholders and their contexts:
- Line 34: `{{AGENT_FILENAME}}` — in §1 body text
- Line 63: `{{PRIMARY_DOMAIN}}` — in §2 directory tree comment
- Line 285: `knowledge_domain: "{{PRIMARY_DOMAIN}}"` — in §5 frontmatter block
- Line 286: `privacy_default: {{DEFAULT_PRIVACY}}` — in §5 frontmatter block
- Line 569: `{{DECAY_PROFILE}}` — in §6 body text

When §5 and §6 are extracted, the `{{placeholder}}` lines at lines 285–286 (§5) and line 569 (§6) move with the section content into the leaf reference files. The template therefore contains `{{placeholder}}` lines inside `schema/reference/frontmatter.md` and `schema/reference/provenance.md`. This is correct and expected — the wizard only renders AGENTS.template.md itself, not the extracted files.

**No action needed for placeholders** beyond confirming they survive the extraction without being accidentally stripped. The init-wizard.sh rendering logic is isolated to the AGENTS.template.md → AGENTS.md path.

---

## Phase 17 Coordination Points

Phase 16 must not pre-empt Phase 17:

1. **`schema/workflows/lint.md`** — created and seeded in Phase 16 (decay + staleness only). Phase 17 adds the full §11.3 lint workflow procedure. The seeded file must have a prominent header marking what was added in Phase 16 and what Phase 17 will add.

2. **Workflow operation rows in the routing table** — the routing table can include rows pointing to `schema/workflows/{ingest,query,lint,reflect}.md` as pre-declarations, or Phase 16 can add those rows with a "Phase 17" annotation. Either approach is valid; the planner chooses.

3. **`schema/reference/` directory** — Phase 16 creates it. Phase 17 may add `schema/reference/log-format.md` (WF-07). Phase 16 must not create log-format.md.

4. **`schema/workflows/` directory** — Phase 16 creates it (for lint.md). Phase 17 adds all other workflow files. Phase 16 must not create any workflow file other than lint.md.

---

## Validation Architecture

> `nyquist_validation: true` in .planning/config.json — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash scripts + existing CI gates (no unit test framework needed for this phase) |
| Config file | `.github/workflows/` (existing) + `tests/phase-07/` + `tests/phase-08/` |
| Quick run command | `bash bin/sync-claude.sh --check && bash bin/check-neutrality.sh` |
| Full suite command | `bash tests/phase-07/run.sh && bash tests/phase-08/run.sh && bash bin/lint.sh --ci` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| REF-01 | §4 content exists in `schema/reference/page-types.md` | manual-verify | `test -f schema/reference/page-types.md && grep -c "section order" schema/reference/page-types.md` | Content-preservation check |
| REF-01 | Core has only 6 type names, not full §4 text | manual-verify | `grep -c "^### 4\." AGENTS.md` — should be 0 | Stubs only in core |
| REF-02 | §5 extracted to `schema/reference/frontmatter.md` | manual-verify | `test -f schema/reference/frontmatter.md && wc -l schema/reference/frontmatter.md` | Expect ~140 lines |
| REF-03 | `schema/reference/provenance.md` exists | manual-verify | `test -f schema/reference/provenance.md` | |
| REF-03 | `schema/workflows/lint.md` exists with decay table | manual-verify | `grep -c "Decay Period" schema/workflows/lint.md` | Should be ≥1 |
| REF-04 | §7 is gone from core | automated | `grep -n "Progressive Disclosure" AGENTS.md` — must return only the routing table row, not a section header | |
| REF-05 | `schema/reference/wikilinks.md` has verbatim uniform-piped-link truth | manual-verify | `grep "filename/path ONLY" schema/reference/wikilinks.md` — must match | REF-05 guard |
| REF-06 | `schema/reference/privacy.md` exists | automated | `test -f schema/reference/privacy.md` | |
| REF-07 | `docs/reference/scaling.md` and `tooling.md` exist | automated | `test -f docs/reference/scaling.md && test -f docs/reference/tooling.md` | |
| REF-07 | §16 is gone from core | automated | `grep -n "Appendices" AGENTS.md` — should be 0 or only in routing-table row | |
| REF-08 | Routing table present with IMPORTANT: flag | automated | `grep -n "^> \*\*IMPORTANT\*\*" AGENTS.md \|\| grep -n "IMPORTANT:" AGENTS.md` | |
| REF-08 | Every routing table row points to an existing file | automated | Script: for each file path in routing table, `test -f <path>` | Key correctness check |
| REF-09 | AGENTS.md ≡ CLAUDE.md byte equality | automated | `bash bin/sync-claude.sh --check` | Pre-commit gate |
| REF-09 | Template stubs mirror AGENTS.md stubs | manual-verify | diff between stub text in AGENTS.md and AGENTS.template.md at same logical position | |
| REF-10 | DR exists in wiki-cloud/decisions/ | manual-verify | `ls wiki-cloud/decisions/dr-*reference-extraction*.md` | |

### Sampling Rate

- **Per section extraction commit:** `bash bin/sync-claude.sh --check && bash bin/check-neutrality.sh`
- **Per wave (group of sections):** `bash tests/phase-07/run.sh && bash tests/phase-08/run.sh`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Content-Preservation Check (Key Correctness Validation)

The primary correctness risk is silently dropping section content. For each extracted section, verify:

```bash
# Before extraction: capture line count of section
sed -n '{start},{end}p' AGENTS.md | wc -l   # expected: N lines

# After extraction: verify leaf file has ~N lines
wc -l schema/reference/{page-types,frontmatter,provenance,wikilinks,privacy}.md
```

More precisely, verify that the leaf file content = original AGENTS.md section content minus the stub remnant. A grep for the first and last distinctive sentences of each section in the corresponding leaf file confirms no silent drop.

### Wave 0 Gaps

- [ ] No new test files needed — this phase uses existing CI infrastructure
- [ ] `schema/` must be added to `PUBLIC_PATHS` in `bin/check-neutrality.sh` line 94 before the first extraction commit (otherwise extracted files escape the neutrality scan)

---

## Security Domain

> `security_enforcement` not explicitly set to `false`; section included.

Phase 16 has minimal security surface — it is a pure text extraction that does not introduce new code, new authentication paths, or new data flows. The relevant security concern is the **neutrality gate** (preventing private vault terms from entering public files via the extracted reference files). This is addressed by adding `schema` to `check-neutrality.sh` PUBLIC_PATHS (see Critical Gap section).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | Partial | Directory-based tier enforcement (`wiki-local/` harness deny); no new access control in Phase 16 |
| V5 Input Validation | No | — |
| V6 Cryptography | No | — |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Private vault term leak into `schema/reference/*.md` | Information Disclosure | Add `schema` to `check-neutrality.sh` PUBLIC_PATHS; use abstract placeholders per §3 MUST-NOT |
| `wiki-local/` path reference in extracted reference files | Information Disclosure | `check-privacy.sh` scan scope covers docs/ but not schema/; use placeholder paths only in reference files |

---

## Open Questions

1. **Routing table operation rows — pre-declare or defer to Phase 17?**
   - What we know: Phase 17 creates `schema/workflows/*.md` files
   - What's unclear: whether routing-table workflow rows (ingest/query/lint/reflect) should be in Phase 16's routing table or Phase 17's additions
   - Recommendation: Include them in Phase 16's routing table with file paths, even though the files don't exist yet. The routing table is more useful complete from Phase 16's end. The `--check-tree` guard (Phase 17, D-07/08) will validate these at Phase 17's end.

2. **Appendix C Quick Reference Card — absorb or delete?**
   - What we know: §16 is deleted; Appendix C has 10 rules including "Privacy default: wiki-local/ tier"
   - What's unclear: which rules need absorption into routing table or MUST-NOT vs. which are fully redundant
   - Recommendation: Audit each of the 10 rules before deletion; rule 6 ("Privacy default") must appear in MUST-NOT or the routing table before deletion.

3. **`check-neutrality.sh` PUBLIC_PATHS update — separate task or bundled?**
   - What we know: schema/ is unscanned but public; this is a gap
   - What's unclear: whether to fix it as Wave 0 setup or as a final cleanup task
   - Recommendation: Fix in Wave 0 (before first extraction) so that neutrality checking is active for all extracted files from the start.

---

## Environment Availability

> Step 2.6: External dependencies for this phase are all local bash scripts.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | All scripts | ✓ | system | — |
| python3 | `check-neutrality.sh`, `check-privacy.sh`, `lint.sh` | ✓ | 3.x | — |
| git | `sync-claude.sh --check`, pre-commit hook | ✓ | — | — |
| `bin/sync-claude.sh` | REF-09 byte equality | ✓ | existing | — |
| `bin/check-neutrality.sh` | neutrality gate | ✓ | existing (needs PUBLIC_PATHS update) | — |
| `schema/reference/` directory | all reference files | ✗ | — | Created in Wave 0 by `mkdir` |
| `schema/workflows/` directory | lint.md seed | ✗ | — | Created in Wave 0 by `mkdir` |

**Missing dependencies with no fallback:** None — all are createable or present.

**Missing dependencies with fallback:** `schema/reference/` and `schema/workflows/` directories don't exist yet; they are created as part of Wave 0 setup (before extraction begins). This is expected and documented.

---

## Assumptions Log

> Claims tagged [ASSUMED] in this research.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Routing table should include operation rows (ingest/query/lint/reflect) pointing to future Phase 17 workflow files | Routing Table Design | Low risk: if wrong, Phase 17 adds those rows instead; table is additive |
| A2 | Appendix C rule 6 ("Privacy default: wiki-local/ tier") needs explicit absorption before §16 deletion | Common Pitfalls #6 | Medium risk: rule could be silently lost if not audited |
| A3 | Exact stub wording (e.g. "→ See schema/reference/page-types.md") | Stub Format Pattern | Low risk: wording is Claude's discretion; form is locked by D-01 |

**All other claims were VERIFIED by direct inspection of live codebase files.**

---

## Sources

### Primary (HIGH confidence)

- Direct inspection of `/home/yishai/Documents/compendium/CLAUDE.md` (1,655 lines) — all section line ranges
- Direct inspection of `/home/yishai/Documents/compendium/schema/AGENTS.template.md` (1,621 lines) — placeholder positions, line count
- Direct inspection of `bin/sync-claude.sh` — byte-equality mechanism (cmp -s)
- Direct inspection of `bin/check-neutrality.sh` lines 94, 104 — PUBLIC_PATHS = 7 items, schema/ absent
- Direct inspection of `bin/check-privacy.sh` — PUBLIC_PATHS (examples docs AGENTS.md CLAUDE.md README.md PRIVACY.md .github)
- Direct inspection of `bin/release.sh` — ALLOWLIST includes `schema`
- Direct inspection of `bin/lint.sh` lines 94, 434 — WIKI_DIR=wiki-cloud/, EXCLUDE_DIRS={'maintenance','examples'}
- Direct inspection of `bin/init-wizard.sh` — renders AGENTS.template.md only; no reference-file copy logic
- Direct inspection of `.github/workflows/lint.yml`, `neutrality.yml`, `setup-parity.yml` — CI gate structure
- `.planning/phases/16-reference-extraction/16-CONTEXT.md` — all D-01..D-09 locked decisions
- `.planning/milestones/v1.2-MILESTONE-BRIEF.md` — Extraction Map, inclusion test, locked decisions
- `.planning/REQUIREMENTS.md` — REF-01..REF-10 text
- `.planning/phases/15-privacy-architecture/15-CONTEXT.md` — D-16 (§13 one-line pointer form)
- Direct inspection of `docs/reference/privacy-model.md` (126 lines) — confirms it's the end-user full model

### Secondary (MEDIUM confidence)

- Cross-referenced Extraction Map line ranges with live CLAUDE.md grep output — 34-line discrepancy between brief estimate (1,689 lines) and live file (1,655 lines) confirmed and attributed to Phase 15 removing per-page privacy machinery

---

## Metadata

**Confidence breakdown:**
- Section line ranges: HIGH — verified by direct grep of live CLAUDE.md
- Resident remnant specification: HIGH — verified against D-01..D-04 + direct file inspection
- CI gate behavior: HIGH — verified by direct script inspection
- Routing table design: MEDIUM — structure locked by D-05; exact rows are Claude's discretion (A1 above)
- neutrality gap (schema/ missing from PUBLIC_PATHS): HIGH — confirmed critical finding

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable domain — this file won't change until Phase 16 executes)

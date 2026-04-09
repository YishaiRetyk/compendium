# Phase 2: Page Types, Examples & Navigation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-09
**Phase:** 02-page-types-examples-navigation
**Areas discussed:** Template format, Example page domain, Epistemic inline syntax, Index organization, Log entry format
**Mode:** auto (all decisions auto-selected)

---

## Template Format & Location

| Option | Description | Selected |
|--------|-------------|----------|
| Separate .md files in schema/templates/ | One per page type, fillable with placeholders | ✓ |
| Embedded in AGENTS.md | Templates as code blocks within the schema | |
| JSON/YAML schema | Machine-parseable template definitions | |

**User's choice:** [auto] Separate .md files in schema/templates/ (recommended default)
**Notes:** AGENTS.md already has worked examples; templates serve as operational copy-and-fill tools.

---

## Example Page Domain

| Option | Description | Selected |
|--------|-------------|----------|
| Personal knowledge domain | User's stated first use case — real topics | ✓ |
| Generic/abstract examples | Lorem ipsum style, domain-agnostic | |
| Computer science domain | Technical topics familiar to developers | |

**User's choice:** [auto] Personal knowledge domain (recommended default)
**Notes:** Validates conventions against real intended use rather than abstract exercises.

---

## Epistemic Inline Syntax

| Option | Description | Selected |
|--------|-------------|----------|
| Dataview inline fields | `[epistemic:: sourced]` — consistent with Obsidian/Dataview | ✓ |
| Custom bracket syntax | `{epistemic:sourced}` — custom but not Dataview-native | |
| Emoji markers | Visual but not machine-queryable | |

**User's choice:** [auto] Dataview inline fields (recommended default)
**Notes:** Consistent with existing Obsidian/Dataview stack. Enables Dataview queries to find all claims of a given epistemic status.

---

## Index Organization

| Option | Description | Selected |
|--------|-------------|----------|
| Category sections + Dataview queries | Organized by page type, auto-populated | ✓ |
| Flat alphabetical list | Simple but less navigable | |
| Tag-based grouping | Flexible but requires consistent tagging | |

**User's choice:** [auto] Category sections + Dataview queries (recommended default)
**Notes:** Categories match page type subdirectories. Dataview queries auto-populate as pages grow.

---

## Log Entry Format

| Option | Description | Selected |
|--------|-------------|----------|
| ISO timestamp + operation + summary | `2026-04-09T10:30:00Z ingest: summary` | ✓ |
| Markdown table rows | Structured but harder to append | |
| YAML entries | Machine-parseable but verbose | |

**User's choice:** [auto] ISO timestamp + operation + summary (recommended default)
**Notes:** One line per operation, most recent first. Operation types match AGENTS.md workflow names.

---

## Claude's Discretion

- Exact example page content (specific claims, facts, provenance markers)
- Template comment style and helper text
- Dataview query specifics (fields, sort order)
- AGENTS.md section 6 update approach

## Deferred Ideas

None — discussion stayed within phase scope

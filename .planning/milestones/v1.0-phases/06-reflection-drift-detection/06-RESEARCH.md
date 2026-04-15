# Phase 6: Reflection & Drift Detection - Research

**Researched:** 2026-04-14
**Domain:** Decision records, structural self-awareness, cross-system drift detection
**Confidence:** HIGH

## Summary

Phase 6 adds two capabilities to the wiki: (1) a decision record system that captures *why* structural changes were made, with a dedicated `decision` page type, three-tier reflect workflow, and checkpoint mechanism; and (2) drift detection that finds mismatches between wiki pages, raw sources, and the Obsidian vault, integrated into the existing `bin/lint.sh`.

The implementation extends well-established patterns from Phases 1-5. The decision record page type follows the same template skeleton + directory + index category pattern used by all five existing page types. The drift checks extend `bin/lint.sh`'s single-python-block architecture with new check categories. The reflect workflow expands AGENTS.md section 11.4 from a 6-step skeleton to a full three-tier model with checkpoint state.

**Primary recommendation:** Implement in three waves: (1) decision record page type + template + schema updates, (2) reflect workflow expansion with three-tier model and checkpoint mechanism, (3) drift detection checks integrated into lint.sh. Each wave builds on the previous and can be verified independently.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Decision records are a new dedicated page type (`type: decision`) with their own template, directory (`wiki/decisions/`), and index category
- D-02: Six trigger types unified by "create a decision record when future-you would reasonably ask 'why is the wiki shaped this way?'"
- D-03: Structured content with TL;DR -> Decision -> Why -> Alternatives Considered -> Consequences -> Sources, plus "Affected Pages" section
- D-04: `decision_history` frontmatter field on affected pages -- list of decision record IDs, always present when decisions exist
- D-05: Visible "Decision History" section in affected page body is optional -- include when meaningful
- D-06: Three-tier reflect model: inline creation, workflow recommendations, manual/periodic reflect
- D-07: Reflect discovery uses both log.md and git log
- D-08: Explicit reflect checkpoint in state file (e.g., `wiki/maintenance/reflect-state.md`)
- D-09: Periodic reflect procedure: read checkpoint, scan log, inspect git, create records, advance checkpoint
- D-10: v1 drift detection = wiki <-> sources + Obsidian vault awareness. All local, deterministic, file-based
- D-11: Specific drift checks: sources with no wiki, wiki referencing missing sources, broken wikilinks, malformed frontmatter, unindexed files, unresolved attachments
- D-12: DRFT-03 scoped narrowly to filesystem-visible toolchain drift. Zotero/cloud deferred
- D-13: Content-hash drift detection comparing current source hash against stored content_hash
- D-14: Hash mismatch -> surface as drift finding, update compilation_status to stale
- D-15: Content-hash drift is mechanism; compilation_status: stale is resulting state
- D-16: v1: drift checks run as part of standard `bin/lint.sh`. One entry point
- D-17: Drift findings appear in lint-report.md under a distinct "Drift" category section
- D-18: Future scalability (--quick, --full, --skip-hash) not built in v1
- D-19: Drift is a distinct lint category, not replacement for structural checks
- D-20: Underlying check logic can be reused across categories
- D-21: Drift findings use tiered severity: error (broken traceability), warning (stale compilation), info (cosmetic)

### Claude's Discretion
- Decision record file naming convention
- Decision record template exact wording and helper comments
- Exact format for "reflect recommended" messages
- How to restructure AGENTS.md section 11.4
- How drift checks integrate into section 11.3 step sequence
- `bin/lint.sh` internal implementation for drift checks
- Reflect state file location and exact format
- Whether `decision_history` uses page IDs or filenames as identifiers

### Deferred Ideas (OUT OF SCOPE)
- Zotero/cloud drift reconciliation
- Lint performance modes (--quick, --full, --skip-hash)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCSN-01 | Reflection entries recording why structural changes were made | Decision page type (D-01 through D-05), three-tier reflect model (D-06), reflect workflow expansion in AGENTS.md section 11.4 |
| DCSN-02 | Decision records capture what framing was adopted, what it replaced, and alternatives considered | Decision template sections (D-03): TL;DR -> Decision -> Why -> Alternatives Considered -> Consequences -> Sources -> Affected Pages |
| DCSN-03 | Reflect workflow documented in schema | AGENTS.md section 11.4 rewrite with three-tier model (D-06 through D-09), inline creation hooks in section 9, checkpoint mechanism |
| DRFT-01 | Detect when raw sources exist but have no corresponding wiki pages | Source directory scan comparing sources/ files against wiki/sources/ pages. Lint category: drift, severity: warning |
| DRFT-02 | Detect when wiki pages reference sources that no longer exist | Existing provenance check already catches broken prov refs (Check 2 in lint.sh). Drift extends this with source path validation. Severity: error |
| DRFT-03 | Detect drift between wiki and broader toolchain | Filesystem-visible checks only (D-12): Obsidian vault file presence, index coverage gaps. Severity: warning/info |
| DRFT-04 | Drift check integrated into lint workflow | Drift checks added as new category in bin/lint.sh python block (D-16), new "Drift" section in lint-report.md (D-17) |
</phase_requirements>

## Architecture Patterns

### Current Codebase Structure (Phase 6 Touchpoints)

```
life/
├── AGENTS.md                    # Section 5 (frontmatter), 9 (operations), 11.3 (lint), 11.4 (reflect), 12 (index/log)
├── bin/
│   ├── lint.sh                  # Extend with drift checks (~970 lines currently)
│   ├── ingest.sh                # Has compute_hash() -- pattern to follow
│   ├── validate-op.sh           # Established CLI pattern
│   └── search.sh                # Established CLI pattern
├── schema/
│   └── templates/
│       ├── entity.md            # Existing templates (5 total)
│       ├── concept.md
│       ├── source-summary.md
│       ├── comparison.md
│       ├── overview.md
│       └── decision.md          # NEW -- Phase 6
├── wiki/
│   ├── decisions/               # NEW -- Phase 6
│   ├── entities/
│   ├── concepts/
│   ├── sources/                 # 3 source summary pages currently
│   ├── comparisons/
│   ├── overviews/
│   ├── maintenance/
│   │   ├── lint-report.md       # Gains "Drift" section
│   │   └── reflect-state.md     # NEW -- Phase 6 checkpoint
│   ├── index.md                 # Gains "Decisions" category
│   └── log.md
└── sources/                     # Raw sources to scan for drift
    └── 2026/2026-04/            # 2 source bundles currently
```

### Pattern 1: Decision Page Type

**What:** A new `type: decision` with dedicated frontmatter, template, directory, and index category. Follows exactly the same pattern as all 5 existing page types.

**Frontmatter additions for decision pages:**
```yaml
type: decision
trigger_type: merge|split|schema-update|domain-reorg|reframing|contradiction-resolution
affected_pages:
  - page-id-1
  - page-id-2
```

**Frontmatter addition for all existing page types:**
```yaml
decision_history:            # List of decision record IDs
  - dr-2026-04-14-slug
```

**Recommendation:** Use `decision_history` with page IDs (the `id` field value) rather than filenames, consistent with how `sources`, `supersedes`, and `superseded_by` all use IDs. The field is a YAML list of strings.

### Pattern 2: Decision Record Naming Convention

**Recommendation:** `dr-YYYY-MM-DD-slug.md` in `wiki/decisions/`. The `dr-` prefix prevents ID collisions with other page types. The date makes chronological sorting natural. The slug provides human readability.

**Examples:**
- `wiki/decisions/dr-2026-04-14-merge-anchoring-into-biases.md`
- `wiki/decisions/dr-2026-04-14-schema-v2-compilation-fields.md`

### Pattern 3: Three-Tier Reflect Model

**Tier 1 -- Inline creation:** MERGE, SUPERSEDE, splits, domain reorg, schema updates produce decision records as part of the operation commit. Hook into Section 9 operation definitions.

**Tier 2 -- Workflow recommendations:** Ingest, query, and lint emit a structured message when they detect signals that warrant reflection. Format recommendation:
```
reflect recommended: [trigger_type] -- [reason]
```
This is a log message, not an automatic action. The agent or human decides whether to act on it.

**Tier 3 -- Manual/periodic reflect:** Procedure reads checkpoint, scans log.md and git log, creates decision records for missed events, advances checkpoint.

### Pattern 4: Reflect Checkpoint Mechanism

**Location:** `wiki/maintenance/reflect-state.md` (per D-08, consistent with lint-report.md living in maintenance/).

**Recommendation:** Use YAML frontmatter for machine-readable fields, minimal body:
```yaml
---
id: reflect-state
title: Reflect State
type: overview
status: active
summary: "Checkpoint state for periodic reflect workflow."
last_reflect_log_entry: "## [2026-04-12] lint | wiki health check"
last_reflect_commit: "abc1234"
last_reflect_at: 2026-04-14
---
# Reflect State

Control-plane checkpoint for the periodic reflect workflow (AGENTS.md section 11.4).
This file tracks where the last reflect pass ended so subsequent passes
resume from the correct position.
```

### Pattern 5: Drift Checks in lint.sh

**Architecture:** Add new check blocks to the existing Python section in `bin/lint.sh`, following the established `should_run()` pattern. New category name: `drift`.

**Implementation approach for each drift check:**

1. **Unrepresented sources (DRFT-01):** Walk `sources/` directory tree for `.md` files, extract slugs, check whether `wiki/sources/src-{slug}.md` exists. Severity: warning.

2. **Missing source files (DRFT-02):** For each source summary page in `wiki/sources/`, read the `path` frontmatter field, verify the file exists on disk. Severity: error.

3. **Content-hash drift (D-13/D-14):** For each source summary page, recompute `sha256sum` of the raw source file at `path`, compare against `content_hash` in frontmatter. If mismatch: finding + mark `compilation_status: stale` (auto-fix per D-14). Severity: warning.

4. **Index coverage (D-11):** Walk all `.md` files in `wiki/` subdirectories, check each has a wikilink in `wiki/index.md`. Severity: warning.

5. **Broken wikilinks as drift:** Already partially covered by orphan detection (Check 3). Extend to detect wikilinks that resolve to no known page (current gap check finds "red links" but classifies as `gap`). For drift purposes, classify broken wikilinks to source pages or pages that previously existed as `drift` severity error.

6. **Obsidian vault awareness (DRFT-03):** Check that the `.obsidian/` directory exists alongside wiki (confirming vault setup). Verify no files in `wiki/` that are not `.md` (unexpected binary files break Obsidian). Severity: info.

**Lint report update:** The report currently has three sections (Errors, Warnings, Info). The `format_findings()` function already groups by severity. Add category-level grouping within each severity section so drift findings are visually distinct per D-17/D-19.

**Recommendation for report restructure:** Group findings by category first, then severity within each category. This provides the "Drift" section D-17 requires. Alternative: keep severity-first but add category labels. The category-first approach is cleaner for the user.

### Pattern 6: AGENTS.md Section Updates

**Section 5 (Frontmatter):** Add `decision` to the `type` enum. Add `trigger_type`, `affected_pages` to decision-specific fields. Add `decision_history` to base fields documentation.

**Section 9 (Structured Operations):** Add inline decision record creation as a step in MERGE and SUPERSEDE operations.

**Section 11.3 (Lint):** Add drift check steps after existing step 10 (source coverage gaps), before the report compilation step. Update the existing `--category` option documentation to include `drift`.

**Section 11.4 (Reflect):** Major rewrite. Replace 6-step skeleton with three-tier model. Add checkpoint mechanism. Add inline creation rules. Add recommendation triggers. Add periodic reflect procedure.

**Section 12 (Index and Log):** Add "Decisions" to the list of index categories.

### Anti-Patterns to Avoid

- **Overloading overview type for decisions:** The current section 11.4 says "Create a decision record page in `wiki/overviews/` with `type: overview`". Phase 6 replaces this with a dedicated `type: decision` in `wiki/decisions/`. All references to the old approach must be updated.
- **Making drift checks external to lint:** D-16 is explicit: one entry point. Do not create a separate `bin/drift.sh`.
- **Content-hash recomputation without the raw source file:** If the source file at `path` does not exist, the hash cannot be recomputed. This is itself a drift finding (DRFT-02), not a hash check failure.
- **Reflect checkpoint as a separate workflow:** The checkpoint is a state file consumed by the reflect workflow, not a separate workflow.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SHA-256 hashing | Custom hash function | `hashlib.sha256` in Python (lint.sh) or `sha256sum` in bash | Already used by ingest.sh; well-tested |
| YAML parsing | Regex-based frontmatter extraction | `yaml.safe_load` via PyYAML | Already used throughout lint.sh |
| Wikilink resolution | New resolution logic | Existing `resolution_map` pattern in lint.sh | Case-insensitive, alias-aware resolution already implemented |
| Git log parsing | Custom git wrapper | `git log --oneline --since=...` with standard parsing | Standard git CLI, no dependencies |
| File walking | Manual directory traversal | `os.walk` + `pathlib.Path` | Already used in lint.sh pattern |

## Common Pitfalls

### Pitfall 1: Lint Report Format Breaking Change
**What goes wrong:** Restructuring the lint report to add a "Drift" category section might break the existing format that other workflows parse.
**Why it happens:** The current format is severity-first (Errors, Warnings, Info). Adding category sections changes the structure.
**How to avoid:** Add drift as a subcategory within existing severity sections initially. Use a clear heading pattern like `### Drift` under each severity level. This preserves backward compatibility while giving drift findings a distinct visual section.
**Warning signs:** Log entries that reference lint-report.md structure breaking.

### Pitfall 2: VALID_TYPES Not Updated in lint.sh
**What goes wrong:** Adding `type: decision` to the schema but forgetting to update `VALID_TYPES` in `bin/lint.sh` causes all decision pages to fail YAML validation.
**Why it happens:** The enum validation is hardcoded in the Python block: `VALID_TYPES = {'entity', 'concept', 'source', 'comparison', 'overview'}`.
**How to avoid:** Update `VALID_TYPES` to include `'decision'` when the page type is introduced. Also update `VALID_STATUS` if decisions use any new status values (they don't -- they use the existing `active` status).
**Warning signs:** Lint errors on decision pages immediately after creation.

### Pitfall 3: Content-Hash Drift Conflating Missing Files with Hash Mismatches
**What goes wrong:** When the raw source file at `path` doesn't exist, a naive hash check throws an error instead of reporting a drift finding.
**Why it happens:** The hash check tries to read the file before checking existence.
**How to avoid:** Check file existence first (DRFT-02). Only run hash comparison if the file exists. Two separate findings: "missing source file" (error) vs "content hash mismatch" (warning).
**Warning signs:** Unhandled exceptions in the Python block crashing the entire lint run.

### Pitfall 4: Reflect Checkpoint Not Advanced on Empty Passes
**What goes wrong:** A reflect pass that finds nothing to record doesn't advance the checkpoint, causing the next pass to re-scan the same range.
**Why it happens:** Logic only updates checkpoint after creating a decision record.
**How to avoid:** D-09 explicitly states: "A reflect run that produces no decision records still advances the checkpoint." Always advance after scanning, regardless of output.
**Warning signs:** Repeated scanning of the same log entries.

### Pitfall 5: decision_history Field Breaks Existing Page Validation
**What goes wrong:** Adding `decision_history` to BASE_FIELDS in lint.sh makes it required on all pages, causing every existing page to fail validation.
**Why it happens:** The lint checks `missing = [f for f in BASE_FIELDS if f not in fm]` and reports missing fields as errors.
**How to avoid:** Add `decision_history` as an optional field, not part of BASE_FIELDS. It should be validated when present (must be a list) but not required on every page. Similar to how `compilation_status` is only required on source pages.
**Warning signs:** Mass error-level findings on all existing pages after deploying the change.

### Pitfall 6: Circular Dependencies Between Drift and Existing Checks
**What goes wrong:** Some drift checks overlap with existing checks (e.g., broken wikilinks are both "structural" and "drift"). Running both produces duplicate findings.
**Why it happens:** D-19/D-20 say the same underlying check can be classified differently depending on context, but the implementation doesn't deduplicate.
**How to avoid:** Per D-20, reuse underlying check logic. The categorization layer interprets the finding. Don't run the same check twice -- run it once and classify the result based on context (e.g., a broken wikilink to a source page is "drift", to a concept page is "structural").
**Warning signs:** Duplicate findings with different categories for the same issue on the same file.

## Code Examples

### Decision Template (schema/templates/decision.md)

```yaml
---
id:
title:
type: decision
status: active
summary: ""
created_at:
updated_at:
sources: []
epistemic_status: sourced
tags: []
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: ""
trigger_type:
affected_pages: []
---

<!-- FORBIDDEN PATTERNS (see AGENTS.md section 3):
     - No wikilinks in frontmatter (use plain string IDs)
     - No display aliases: write [[Page Title]] not [[Page Title|Alias]]
     - Link each page only on first mention in the body
     - No example content -- fill with real content when using -->

## TL;DR

<!-- One-sentence summary of the decision and its impact. -->

## Decision

<!-- What was decided. State clearly and concisely. -->

## Why

<!-- The reasoning behind this decision. What problem was it solving?
     What framing was adopted and what did it replace? -->

## Alternatives Considered

<!-- What other options were evaluated. Why were they rejected? -->

## Consequences

<!-- What changes as a result. What becomes easier/harder?
     What follow-on work is needed? -->

## Affected Pages

<!-- Wikilinks to pages affected by this decision.
     Format: - [[Page Title]] -- how it was affected -->

## Sources

<!-- Human-readable source list if applicable.
     Format: - [[src-YYYY-MM-DD-slug]]: "Title" (date) -->
```

### Drift Check: Unrepresented Sources (DRFT-01)

```python
# In lint.sh python block, after existing checks
if should_run('drift') or should_run('all'):
    print("  Checking for drift: unrepresented sources...", file=sys.stderr)
    
    sources_dir = os.path.join(os.path.dirname(wiki_dir.rstrip('/')), 'sources')
    wiki_sources_dir = os.path.join(wiki_dir, 'sources')
    
    # Collect all raw source files
    raw_source_paths = set()
    if os.path.isdir(sources_dir):
        for root, dirs, files in os.walk(sources_dir):
            for fname in files:
                if fname.endswith('.md'):
                    raw_source_paths.add(os.path.join(root, fname))
    
    # Collect all wiki source page paths (from frontmatter)
    wiki_source_paths = set()
    for sp, sfm, sbody in source_pages:
        if sfm and 'path' in sfm:
            wiki_source_paths.add(sfm['path'])
    
    # Find raw sources with no wiki representation
    for raw_path in sorted(raw_source_paths):
        rel_path = os.path.relpath(raw_path, os.path.dirname(wiki_dir.rstrip('/')))
        if rel_path not in wiki_source_paths:
            add_finding('warning', 'drift', rel_path,
                        'Raw source has no wiki source summary page')
```

### Drift Check: Content-Hash Verification (D-13/D-14)

```python
if should_run('drift') or should_run('all'):
    print("  Checking for drift: content-hash...", file=sys.stderr)
    import hashlib
    
    project_root = os.path.dirname(wiki_dir.rstrip('/'))
    
    for sp, sfm, sbody in source_pages:
        if sfm is None:
            continue
        rel = os.path.relpath(sp)
        stored_hash = sfm.get('content_hash', '')
        source_path_field = sfm.get('path', '')
        
        if not stored_hash or not source_path_field:
            continue
        
        abs_source = os.path.join(project_root, source_path_field)
        
        if not os.path.exists(abs_source):
            add_finding('error', 'drift', rel,
                        f'Source file missing: {source_path_field}')
            continue
        
        # Compute current hash
        h = hashlib.sha256()
        with open(abs_source, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                h.update(chunk)
        current_hash = f'sha256:{h.hexdigest()}'
        
        if current_hash != stored_hash:
            add_finding('warning', 'drift', rel,
                        f'Content hash mismatch: source changed since ingest '
                        f'(stored: {stored_hash[:20]}..., current: {current_hash[:20]}...)')
            # Auto-fix: mark compilation_status as stale (D-14)
            if do_fix and not dry_run:
                comp_status = sfm.get('compilation_status', '')
                if comp_status and comp_status != 'stale':
                    # Update frontmatter
                    try:
                        content = open(sp, encoding='utf-8').read()
                        content = re.sub(
                            r'^(compilation_status:\s*).*$',
                            r'\1stale',
                            content, flags=re.MULTILINE
                        )
                        with open(sp, 'w', encoding='utf-8') as f:
                            f.write(content)
                        add_finding('info', 'autofix', rel,
                                    'Set compilation_status to stale (content hash drift)')
                    except Exception:
                        pass
```

### Reflect Checkpoint Reading

```python
# Pattern for reading reflect checkpoint (in periodic reflect workflow)
import subprocess, re

def read_reflect_checkpoint(state_path):
    """Read the reflect checkpoint state file."""
    fm, body, err = parse_frontmatter(state_path)
    if fm is None:
        return {'last_log_entry': None, 'last_commit': None, 'last_at': None}
    return {
        'last_log_entry': fm.get('last_reflect_log_entry', ''),
        'last_commit': fm.get('last_reflect_commit', ''),
        'last_at': fm.get('last_reflect_at', ''),
    }

def get_git_changes_since(commit_hash):
    """Get file changes since a commit."""
    cmd = ['git', 'log', '--oneline', '--name-only', f'{commit_hash}..HEAD']
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout
```

## State of the Art

| Old Approach (AGENTS.md current) | New Approach (Phase 6) | Impact |
|----------------------------------|------------------------|--------|
| Decision records in `wiki/overviews/` with `type: overview` | Dedicated `type: decision` in `wiki/decisions/` | Clean separation, dedicated template, index category |
| 6-step reflect skeleton | Three-tier model (inline + recommendations + periodic) | Decisions captured at point of change, not only retrospectively |
| No reflect checkpoint | Explicit checkpoint in reflect-state.md | Deterministic periodic passes, no re-scanning |
| Lint has no drift checks | 6+ drift checks integrated into lint.sh | Source/wiki/vault alignment verified on every lint run |
| Lint report: severity-only grouping | Severity + category grouping (including Drift) | Drift findings visually distinct |
| No `decision_history` field | `decision_history` on affected pages | Machine-readable audit trail on every page |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash + python3 (inline in lint.sh) |
| Config file | none -- tests are bash scripts verifying CLI output |
| Quick run command | `bin/lint.sh --dry-run --category drift wiki/` |
| Full suite command | `bin/lint.sh wiki/` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DCSN-01 | Decision record page type exists with valid frontmatter | smoke | `bin/lint.sh --category yaml wiki/decisions/` | No -- Wave 0 |
| DCSN-02 | Decision template has required sections | manual | Inspect schema/templates/decision.md | N/A |
| DCSN-03 | Reflect workflow documented in AGENTS.md | manual | grep for section 11.4 in AGENTS.md | N/A |
| DRFT-01 | Detect unrepresented sources | smoke | `bin/lint.sh --category drift --dry-run wiki/` | No -- Wave 0 |
| DRFT-02 | Detect wiki referencing missing sources | smoke | `bin/lint.sh --category drift --dry-run wiki/` | No -- Wave 0 |
| DRFT-03 | Detect toolchain drift | smoke | `bin/lint.sh --category drift --dry-run wiki/` | No -- Wave 0 |
| DRFT-04 | Drift integrated into lint | smoke | `bin/lint.sh --dry-run wiki/` (includes drift) | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `bin/lint.sh --dry-run wiki/`
- **Per wave merge:** `bin/lint.sh wiki/` (full run with report generation)
- **Phase gate:** Full lint green (0 errors) + drift category producing expected findings

### Wave 0 Gaps
- [ ] No formal test harness -- validation is through lint.sh dry-run execution
- [ ] Example decision record page needed for lint validation of new page type

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | lint.sh drift checks | Verifying... | -- | -- |
| PyYAML | YAML parsing in lint.sh | Verifying... | -- | -- |
| sha256sum | Content-hash drift | Verifying... | -- | shasum -a 256 |
| git | Reflect checkpoint (git log) | Verifying... | -- | -- |

All dependencies are already required by existing tooling (Phases 3-5). No new external dependencies introduced.

## Open Questions

1. **Lint report restructuring depth**
   - What we know: D-17 requires a distinct "Drift" category section. Current format is severity-first.
   - What's unclear: Whether to restructure to category-first (breaking change to format) or add category subsections within severity levels (additive change).
   - Recommendation: Add category subsections within existing severity levels. This is the minimal change that satisfies D-17 without breaking the established format. Example: under "## Warnings", add `### Drift` and `### Structural` subsections.

2. **decision_history on existing pages retroactively**
   - What we know: D-04 says the field is "always present when decisions exist." Pre-Phase-6 pages have no decisions.
   - What's unclear: Whether to add empty `decision_history: []` to all existing page templates/pages now, or only when the first decision references them.
   - Recommendation: Add to template definitions only. Existing pages gain the field when first referenced by a decision record. The lint should NOT flag its absence as an error.

3. **Drift check for --category flag**
   - What we know: lint.sh already supports `--category <cat>` filtering. Current categories: orphan, crossref, stale, contradiction, gap, provenance, yaml.
   - What's unclear: Whether `drift` is one category or should be split (e.g., `drift-source`, `drift-hash`).
   - Recommendation: Single `drift` category. Internally it runs multiple sub-checks, but from the user's perspective it's one category. Consistent with how `gap` encompasses both red links and sparse coverage.

## Sources

### Primary (HIGH confidence)
- AGENTS.md -- Sections 5, 9, 10, 11.3, 11.4, 12 read in full
- bin/lint.sh -- Complete implementation reviewed (~970 lines)
- bin/ingest.sh -- Hash computation pattern reviewed
- schema/templates/*.md -- All 5 existing templates reviewed
- wiki/maintenance/lint-report.md -- Current report format reviewed
- wiki/index.md -- Current index structure reviewed
- wiki/sources/*.md -- Source page frontmatter format reviewed

### Secondary (MEDIUM confidence)
- Phase 1-5 CONTEXT.md decisions referenced in 06-CONTEXT.md canonical_refs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, extends existing Python/bash patterns
- Architecture: HIGH -- all patterns established in Phases 1-5, decisions are locked
- Pitfalls: HIGH -- identified from direct code review of lint.sh implementation

**Research date:** 2026-04-14
**Valid until:** 2026-05-14 (stable domain, no external dependencies)

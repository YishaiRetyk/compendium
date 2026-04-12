# Phase 4: Query & Structured Operations - Research

**Researched:** 2026-04-12
**Domain:** Wiki query workflow, structured operations enforcement, CLI search tooling, AGENTS.md spec updates
**Confidence:** HIGH

## Summary

Phase 4 delivers three interconnected capabilities: (1) an operational query workflow with mandatory write-back and delta compilation, (2) deterministic enforcement of the four structured operations (UPDATE/MERGE/SUPERSEDE/ARCHIVE) via a bash validator script, and (3) a CLI search helper. All three build on existing patterns established in phases 1-3: the AGENTS.md specification, the `bin/ingest.sh` CLI helper pattern, the wiki's frontmatter schema, and the provenance/epistemic syntax.

The technical domain is straightforward -- bash scripting, YAML frontmatter parsing, markdown file manipulation, and specification writing. There are no external library dependencies. The primary complexity is getting the specification right: the query workflow's write-back decision rules (D-01 through D-05), delta compilation mechanics (D-06 through D-11), and the validator's five mechanical checks (D-17) must be precisely defined in AGENTS.md so that any LLM agent can follow them deterministically.

**Primary recommendation:** Structure the work as spec-first, then tooling, then integration testing. Update AGENTS.md sections first (frontmatter schema, query workflow, operations logging), then build the two bash scripts (`bin/search.sh`, `bin/validate-op.sh`), then verify end-to-end with the existing wiki content.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Write-back uses page ownership, not origin. Update existing page if it owns the topic; create new page for distinct artifacts.
- D-02: No query-specific page types. Pages typed by semantic role only.
- D-03: Mandatory write-back triggers on novel or durable synthesis (new claims, new connections, reframings, reusable artifacts, corrections).
- D-04: Do NOT write back for pure lookups, reformatted restatements, transient conversational answers.
- D-05: Log write-back decision in query log entry -- structured and terse.
- D-06: Primary delta detection: compilation status fields on source summary pages (`compilation_status`, `compiled_against_hash`, `compiled_targets`).
- D-07: Secondary verification: provenance gap validation.
- D-08: New sources land with `compilation_status: pending`. Ingest sets to `compiled`/`partial`. Content hash change resets to `stale`.
- D-09: Query-time delta compilation is query-scoped by default.
- D-10: Full-source compilation is the exception (central source, wasteful scoping, user request).
- D-11: Ingest workflow (AGENTS.md 11.1) must be retroactively updated to set compilation status fields after merge pass.
- D-12: Dual-mode `bin/search.sh` -- bash, agent-agnostic, zero API dependencies.
- D-13: Default mode: index lookup + optional full-text grep. Prints paths with TL;DR snippets.
- D-14: Query mode (`--query`): prompt scaffolder that emits a ready-to-paste LLM prompt.
- D-15: Default output: path + TL;DR. Optional flags: `--paths-only`, `--frontmatter`.
- D-16: Two-layer enforcement: AGENTS.md rules as policy, `bin/validate-op.sh` as deterministic enforcement.
- D-17: Validator performs 5 mechanical checks (target exists, YAML parses, provenance resolves, privacy respected, MERGE-specific both-pages-exist).
- D-18: Batch validation before apply: validate all, abort entire batch on hard failure.
- D-19: Direct CLI invocation: `bin/validate-op.sh UPDATE wiki/entities/kahneman.md`.
- D-20: Structured prefix + terse rationale format for operation log entries.
- D-21: Log entry format: `## [YYYY-MM-DD] OPERATION | target_page` with source, result, reason fields.

### Claude's Discretion
- Exact implementation details of `bin/search.sh` (argument parsing, grep invocation, TL;DR extraction method)
- Exact implementation details of `bin/validate-op.sh` (YAML parsing approach, provenance resolution logic)
- How to structure AGENTS.md 11.2 update to incorporate write-back decision rules
- Whether to update AGENTS.md sections incrementally per plan or batch at the end
- Exact wording of compilation status field documentation in AGENTS.md 5

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QURY-01 | Question answering against the wiki with citations to specific pages and sources | Query workflow spec in AGENTS.md 11.2 -- steps 1-4 cover index-first search and cited answer synthesis |
| QURY-02 | Index-first search -- LLM reads index to find relevant pages, then drills into them | Already partially spec'd in existing 11.2 steps 1-3; search helper (CLI-01) provides mechanical support |
| QURY-03 | Delta compilation at query time -- compile only missing synthesis exposed by the query | Compilation status fields (D-06 through D-08) on source summary pages enable detection; query workflow step 6 triggers compilation |
| QURY-04 | Mandatory write-back -- useful query outputs become durable wiki updates | Write-back decision rules (D-01 through D-05) define when/how; query workflow step 5 enforces |
| QURY-05 | Query workflow documented step-by-step in schema | AGENTS.md 11.2 rewrite incorporating all D-01 through D-11 decisions |
| SOPS-01 | UPDATE operation -- modify existing page with new information, preserving provenance | Already defined in AGENTS.md 9; validator check added by D-17 |
| SOPS-02 | MERGE operation -- combine two pages covering the same concept | Already defined in AGENTS.md 9; validator adds MERGE-specific both-pages-exist check |
| SOPS-03 | SUPERSEDE operation -- mark a claim or page as replaced by newer information | Already defined in AGENTS.md 9; validator check added |
| SOPS-04 | ARCHIVE operation -- move outdated content out of active wiki | Already defined in AGENTS.md 9; validator check added |
| SOPS-05 | All operations logged with rationale | Operations logging format D-20/D-21 updates AGENTS.md 12 |
| SOPS-06 | Deterministic executor/validator that applies structured operations | `bin/validate-op.sh` with 5 mechanical checks (D-16 through D-19) |
| CLI-01 | Search tool for querying wiki pages (index-based or text search) | `bin/search.sh` dual-mode script (D-12 through D-15) |
</phase_requirements>

## Standard Stack

### Core

This phase has no external library dependencies. All deliverables are:
- Bash scripts (POSIX-compatible with standard tools)
- Markdown specification updates to AGENTS.md
- YAML frontmatter modifications on existing wiki pages

### Tools Required

| Tool | Purpose | Available | Version |
|------|---------|-----------|---------|
| bash | Script runtime | Yes | Standard |
| grep (GNU) | Text search in search helper | Yes | 3.11 |
| python3 + PyYAML | YAML parsing in validator script | Yes | Available |
| sha256sum | Hash computation for compilation status | Yes | Standard |
| sed, awk | Text processing | Yes | Standard |

### YAML Parsing Approach for validate-op.sh

**Decision: Use python3 inline for YAML parsing.** `yq` is not installed on this system. Python3 with PyYAML is available. The validator can use a small inline python call for YAML frontmatter extraction:

```bash
parse_frontmatter() {
    python3 -c "
import sys, yaml
content = open(sys.argv[1]).read()
if content.startswith('---'):
    end = content.index('---', 3)
    fm = yaml.safe_load(content[3:end])
    for k,v in (fm or {}).items():
        print(f'{k}={v}')
" "$1"
}
```

This keeps the script self-contained with zero install requirements beyond what is already present. The ingest.sh pattern of using `sha256sum` as an external tool provides precedent for this approach.

## Architecture Patterns

### Deliverables Map

```
AGENTS.md updates:
  section 5  -- Add compilation_status fields to source summary schema
  section 9  -- Reference bin/validate-op.sh as enforcement layer
  section 11.1 -- Retroactive: set compilation_status after merge pass
  section 11.2 -- Full rewrite with write-back rules + delta compilation
  section 12 -- Updated operation logging format

bin/search.sh        -- CLI search helper (D-12 through D-15)
bin/validate-op.sh   -- Operations validator (D-16 through D-19)

wiki/sources/*.md    -- Add compilation_status fields to existing pages
schema/templates/source-summary.md -- Add compilation_status fields to template
```

### Pattern 1: CLI Helper Design (from bin/ingest.sh)

**What:** Bash scripts that handle file-system bookkeeping only. Zero LLM/API calls. Agent-agnostic.
**When to use:** All CLI helpers in this project.
**Key conventions from ingest.sh:**
- `set -euo pipefail` at top
- `usage()` function with heredoc
- Argument parsing with `while [ "$#" -gt 0 ]; do case "$1" in` pattern
- Helper functions for reusable operations
- Clear output format with `=== Header ===` sections
- Descriptive error messages to stderr with `>&2`
- Exit codes: 0 success, 1 error

### Pattern 2: Spec-First Development

**What:** AGENTS.md specification updates precede tooling implementation.
**Why:** The bash scripts enforce rules defined in AGENTS.md. If the spec is written first, the scripts can be validated against it. Also, the query workflow spec (11.2) is needed for QURY-05 even without tooling.

### Pattern 3: Compilation Status as Workflow Boundary Marker

**What:** Source summary pages carry a `compilation_status` field that tracks where the source is in the compilation lifecycle.
**States:** `pending | partial | compiled | stale`
**Transitions:**
- New source ingested -> `pending`
- After ingest merge pass -> `compiled` (all claims merged) or `partial` (some claims merged)
- Source content_hash changes on re-ingest -> `stale`
- Query-time delta compilation -> can move `pending`/`partial`/`stale` toward `compiled`

### Anti-Patterns to Avoid
- **Validator that calls LLM APIs:** The validator is purely mechanical. It checks file existence, YAML parsing, provenance resolution, and privacy flags. It never evaluates content quality.
- **Monolithic AGENTS.md update:** Update sections incrementally as each plan completes, not as one giant batch. This makes reviews tractable and failures isolated.
- **Query-specific page types:** D-02 explicitly forbids this. Pages created by query write-back use standard semantic types (entity, concept, comparison, overview).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing in bash | Custom regex-based YAML parser | `python3 -c "import yaml; ..."` inline | YAML edge cases (multiline strings, lists, special chars) make regex parsing fragile |
| SHA-256 hashing | Custom hash function | `sha256sum` (already used by ingest.sh) | Standard tool, proven pattern |
| Provenance syntax parsing | Custom parser from scratch | `grep -oP '\[prov:[^\]]+\]'` regex | The provenance syntax is simple enough for regex; extract source IDs with a second pass |

## Common Pitfalls

### Pitfall 1: Compilation Status Retroactivity
**What goes wrong:** Existing 3 source summary pages lack `compilation_status` fields. Scripts or queries that assume the field exists will fail.
**Why it happens:** Field is being added in this phase but pages were created in phase 3.
**How to avoid:** (1) Add fields to existing source pages in the same plan that updates the template. (2) Validator and search helper must handle missing `compilation_status` gracefully (treat as `compiled` for pre-existing pages that were fully ingested).
**Warning signs:** KeyError or grep returning empty when checking compilation_status on old pages.

### Pitfall 2: AGENTS.md Section 11.1 Retroactive Update
**What goes wrong:** D-11 requires updating the ingest workflow to set compilation status after merge pass. If this is done carelessly, the existing ingest workflow description gets broken.
**Why it happens:** Inserting new steps into an existing numbered procedure.
**How to avoid:** Add the compilation status update as a sub-step within the existing merge step (step 6), not as a new top-level step that renumbers everything. Or add it as step 6b.

### Pitfall 3: Write-Back Creating Circular References
**What goes wrong:** A query about topic X writes back to page Y, which triggers a delta compilation that tries to update page Y again.
**Why it happens:** Write-back and delta compilation are both part of the same query workflow.
**How to avoid:** The query workflow should be defined with a clear ordering: (1) answer with citations, (2) delta compile if needed, (3) write back results. Write-back happens ONCE at the end, not recursively.

### Pitfall 4: Privacy Violation in Query Write-Back
**What goes wrong:** A query that reads `local_only` source content writes back the synthesized answer to a `cloud_safe` page.
**Why it happens:** Write-back decision (D-01) focuses on page ownership, which might lead to updating a cloud_safe page with local_only-derived content.
**How to avoid:** The write-back step must check privacy inheritance. If ANY source contributing to the synthesis is `local_only`, the write-back target must be `local_only`. This is already the rule from AGENTS.md 13 (privacy inheritance), but the query workflow spec must explicitly reference it.

### Pitfall 5: Validator False Positives on Provenance
**What goes wrong:** Validator rejects valid operations because provenance resolution is too strict.
**Why it happens:** The validator checks that `[prov:source_id#locator]` references resolve to known source IDs in `wiki/sources/`. But the source ID format must be matched exactly.
**How to avoid:** Provenance resolution in the validator should extract the source_id portion (everything between `prov:` and `#`), then check for `wiki/sources/<source_id>.md`. Simple file existence check.

### Pitfall 6: Log Format Conflict
**What goes wrong:** D-20/D-21 introduce a new structured format for operation log entries that may conflict with the existing format in AGENTS.md 12.
**Why it happens:** Existing format is `## [YYYY-MM-DD] <operation_type> | <description>`. New format from D-21 is `## [YYYY-MM-DD] OPERATION | target_page` with sub-fields.
**How to avoid:** The new format should be documented as an extension of the existing format for structured operations (UPDATE/MERGE/SUPERSEDE/ARCHIVE), not a replacement. Workflow-level entries (ingest, query, lint, reflect) keep the existing format.

## Code Examples

### Search Helper: TL;DR Extraction

Extract the TL;DR section from a wiki page (the first non-empty line after `## TL;DR`):

```bash
extract_tldr() {
    local file="$1"
    sed -n '/^## TL;DR/,/^## /{/^## TL;DR/d;/^## /d;/^$/d;p;}' "$file" | head -1
}
```

### Search Helper: Index Keyword Search

Parse `wiki/index.md` for keyword matches:

```bash
search_index() {
    local query="$1"
    grep -i "$query" wiki/index.md | grep -E '^\- \[\[' | while read -r line; do
        # Extract page title from [[Page Title]]
        title=$(echo "$line" | sed -E 's/.*\[\[([^]]+)\]\].*/\1/')
        echo "$line"
    done
}
```

### Validator: Provenance Resolution Check

Extract source IDs from provenance markers and verify they resolve:

```bash
check_provenance() {
    local file="$1"
    local failed=0
    # Extract all [prov:source_id#...] markers
    grep -oP '\[prov:([^#\]]+)' "$file" | sed 's/\[prov://' | sort -u | while read -r src_id; do
        if [ ! -f "wiki/sources/${src_id}.md" ]; then
            echo "FAIL: Provenance reference '${src_id}' does not resolve to wiki/sources/${src_id}.md" >&2
            failed=1
        fi
    done
    return $failed
}
```

### Validator: YAML Frontmatter Extraction

Extract and validate frontmatter using python3:

```bash
validate_frontmatter() {
    local file="$1"
    python3 -c "
import sys, yaml
content = open(sys.argv[1]).read()
if not content.startswith('---'):
    print('FAIL: No YAML frontmatter found', file=sys.stderr)
    sys.exit(1)
try:
    end = content.index('---', 3)
    fm = yaml.safe_load(content[3:end])
    if fm is None:
        print('FAIL: Empty frontmatter', file=sys.stderr)
        sys.exit(1)
    # Check required base fields
    required = ['id','title','type','status','summary','created_at','updated_at',
                'sources','epistemic_status','tags','domains','privacy']
    missing = [f for f in required if f not in fm]
    if missing:
        print(f'FAIL: Missing fields: {missing}', file=sys.stderr)
        sys.exit(1)
    print('PASS')
except yaml.YAMLError as e:
    print(f'FAIL: YAML parse error: {e}', file=sys.stderr)
    sys.exit(1)
except ValueError:
    print('FAIL: Unterminated frontmatter (missing closing ---)', file=sys.stderr)
    sys.exit(1)
" "$file"
}
```

### Compilation Status Fields for Source Summary Pages

New frontmatter fields to add after existing source-specific fields:

```yaml
# Compilation tracking (added in Phase 4)
compilation_status: pending     # pending | partial | compiled | stale
compiled_against_hash: ""       # SHA-256 hash of source at last compilation
compiled_targets: []            # List of wiki page IDs that received compiled claims
```

### Query Workflow Write-Back Decision (for AGENTS.md 11.2)

Pseudocode for the write-back decision:

```
IF answer produces:
  - A new claim not in wiki, OR
  - A new connection between existing pages/sources, OR
  - A meaningful reframing of existing material, OR
  - A reusable artifact (comparison, overview, decision note), OR
  - A correction to an existing page
THEN:
  IF existing page clearly owns the topic -> UPDATE that page
  ELSE -> CREATE new page typed by semantic role
  Log: "WRITE-BACK: <trigger met> -> <UPDATE|CREATE> <page_id>"
ELSE:
  Log: "NO-WRITE-BACK: <reason> (pure lookup | restatement | transient)"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AGENTS.md 11.2 has basic 9-step query workflow | Phase 4 adds write-back rules, delta compilation, compilation status tracking | This phase | Query workflow becomes fully operational with mechanical enforcement |
| Operations defined in AGENTS.md 9 with LLM self-validation only | Two-layer: AGENTS.md policy + bash validator enforcement | This phase | Deterministic validation catches errors before application |
| No CLI search capability | `bin/search.sh` with index lookup + full-text grep + query mode | This phase | Agents and humans can search wiki without reading full index |
| Source summary pages have no compilation tracking | `compilation_status`, `compiled_against_hash`, `compiled_targets` fields | This phase | Delta compilation becomes possible; uncompiled material is detectable |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | All scripts | Yes | Standard | -- |
| python3 + PyYAML | YAML parsing in validator | Yes | Available | -- |
| grep (GNU) | Search helper, provenance resolution | Yes | 3.11 | -- |
| sha256sum | Compilation hash comparison | Yes | Standard | shasum -a 256 (already handled by ingest.sh pattern) |
| sed, awk | Text extraction | Yes | Standard | -- |

**Missing dependencies with no fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | bash + manual verification (no formal test framework) |
| Config file | None -- validation is script-based and manual |
| Quick run command | `bash bin/validate-op.sh UPDATE wiki/entities/daniel-kahneman.md` |
| Full suite command | Run validator against all 4 operation types + search helper in both modes |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QURY-01 | Question answering with citations | manual-only | Manual: ask question, verify cited answer | N/A |
| QURY-02 | Index-first search | manual-only | Manual: verify LLM reads index first | N/A |
| QURY-03 | Delta compilation at query time | manual-only | Manual: verify uncompiled sources trigger compilation | N/A |
| QURY-04 | Mandatory write-back | manual-only | Manual: verify novel synthesis written back | N/A |
| QURY-05 | Query workflow documented | smoke | `grep -c "write-back" AGENTS.md` (verify new content exists) | N/A |
| SOPS-01 | UPDATE operation | smoke | `bash bin/validate-op.sh UPDATE wiki/entities/daniel-kahneman.md` | Wave 0 |
| SOPS-02 | MERGE operation | smoke | `bash bin/validate-op.sh MERGE wiki/concepts/prospect-theory.md wiki/concepts/loss-aversion.md` | Wave 0 |
| SOPS-03 | SUPERSEDE operation | smoke | `bash bin/validate-op.sh SUPERSEDE wiki/entities/daniel-kahneman.md` | Wave 0 |
| SOPS-04 | ARCHIVE operation | smoke | `bash bin/validate-op.sh ARCHIVE wiki/entities/daniel-kahneman.md` | Wave 0 |
| SOPS-05 | Operations logged with rationale | smoke | `grep "OPERATION" AGENTS.md` (verify format documented) | N/A |
| SOPS-06 | Deterministic executor/validator | smoke | `bash bin/validate-op.sh UPDATE wiki/entities/daniel-kahneman.md` prints PASS | Wave 0 |
| CLI-01 | Search tool | smoke | `bash bin/search.sh "Kahneman"` returns results | Wave 0 |

### Sampling Rate
- **Per task commit:** Run affected script(s) with test inputs
- **Per wave merge:** Run all scripts against all existing wiki pages
- **Phase gate:** All SOPS validator checks pass against existing wiki; search helper returns results for known terms

### Wave 0 Gaps
- None -- no test framework to set up. Validation is via script execution against live wiki content.

## Project Constraints (from CLAUDE.md)

No CLAUDE.md file exists in this project. Constraints are derived from AGENTS.md (the sole authoritative specification) and established conventions from phases 1-3:
- All wiki mutations must use the four operations vocabulary (UPDATE, MERGE, SUPERSEDE, ARCHIVE)
- Commit convention: `query(<topic>): <one-line summary>` for query workflow
- Privacy: stricter setting always wins; `local_only` content never sent to cloud APIs
- Progressive disclosure: TL;DR -> Key Facts -> Detail -> Sources
- Provenance: `[prov:source_id#locator]` inline syntax
- Log ordering: newest at bottom (append-only)
- CLI helpers: bash, agent-agnostic, zero API dependencies

## Open Questions

1. **Existing source pages: what compilation_status to assign?**
   - What we know: All 3 existing sources were fully ingested with merge passes in Phase 3.
   - Recommendation: Set `compilation_status: compiled`, `compiled_against_hash` to current `content_hash`, and `compiled_targets` to the list of pages they contributed to (derivable from log.md entries). This is the correct semantic -- these sources were fully compiled during ingest.

2. **AGENTS.md update strategy: incremental or batch?**
   - What we know: D-discretion says Claude decides. There are 5 sections to update.
   - Recommendation: Incremental per plan. Frontmatter schema (section 5) first since other changes depend on it. Then query workflow (11.2) and ingest retroactive (11.1) together. Then operations logging (12) and executor reference (9).

3. **Validator batch mode implementation**
   - What we know: D-18 says "validate all, abort entire batch on hard failure."
   - Recommendation: The validator script validates individual operations. Batch mode is the caller's responsibility -- the LLM proposes operations, calls the validator for each, and aborts on first failure. The script does not need a batch flag; sequential calls achieve the same result.

## Sources

### Primary (HIGH confidence)
- AGENTS.md sections 5, 6, 9, 10, 11, 12, 13 -- directly read and analyzed
- `bin/ingest.sh` -- reference CLI helper implementation (253 lines)
- `wiki/index.md` -- current index structure
- `wiki/log.md` -- current log format and content
- `wiki/sources/*.md` -- current source summary frontmatter (3 pages)
- `schema/templates/source-summary.md` -- current template structure
- `04-CONTEXT.md` -- all 21 locked decisions (D-01 through D-21)

### Secondary (MEDIUM confidence)
- System environment audit: python3/PyYAML available, yq not available

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no external dependencies; all tools verified present
- Architecture: HIGH -- builds directly on established patterns from phases 1-3 with clear decisions from CONTEXT.md
- Pitfalls: HIGH -- derived from reading the actual codebase and specifications

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (stable domain, no external dependencies that change)

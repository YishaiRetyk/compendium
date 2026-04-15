# Phase 5: Lint & Quality - Research

**Researched:** 2026-04-13
**Domain:** Wiki health-check system -- contradiction detection, staleness decay, gap analysis, orphan detection, cross-reference validation, CLI lint helper
**Confidence:** HIGH

## Summary

Phase 5 builds a comprehensive wiki health-check system as a bash CLI helper (`bin/lint.sh`) plus AGENTS.md schema extensions. The system is entirely file-based, deterministic, and LLM-free -- it parses YAML frontmatter and inline markers (`[prov:]`, `[epistemic::]`) using python3/PyYAML and grep, consistent with the existing `bin/validate-op.sh` and `bin/ingest.sh` patterns. The lint produces a persistent report page at `wiki/maintenance/lint-report.md`, prints a compact summary to stdout, and applies mechanical auto-fixes (adding missing cross-references, marking stale claims, fixing unambiguous broken provenance refs).

The phase has two distinct deliverable types: (1) schema/documentation work extending AGENTS.md sections 5, 6, and 11.3 with decay rate tables, severity tiers, contradiction syntax, and new frontmatter fields; and (2) implementation work creating `bin/lint.sh` with detection rules for each finding category. The schema work must precede implementation since the lint rules enforce the schema.

**Primary recommendation:** Structure plans as schema-first (AGENTS.md extensions + new frontmatter fields), then lint rule implementation by category (structural checks, staleness, contradictions, gaps), then CLI integration and report generation.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: v1 contradiction = provenance-backed source-level disagreement. Two different sources assert conflicting claims about the same subject/attribute. The system surfaces "Source A says X, Source B says Y" with both citations -- it does not decide which is correct.
- D-02: Semantic conflict (arbitrary prose contradictions without provenance grounding) is out of scope for v1.
- D-03: Contradictions flagged with inline markers consistent with provenance/epistemic syntax. Pattern: `[contradiction:src_a#locator vs src_b#locator]`
- D-04: Secondary aggregation: contradictions also listed in centralized lint report.
- D-05: New `has_contradictions: true` frontmatter field on affected pages. Independent of `epistemic_status`.
- D-06: Contradictions are severity: warning.
- D-07: Primary decay category = knowledge domain. Each page declares `knowledge_domain` frontmatter field mapping to decay rate table in AGENTS.md section 6.
- D-08: Secondary modifier = epistemic status. Tentative/inferred claims decay faster than domain default.
- D-09: Override = source hash change. If `content_hash` changes, all linked claims marked stale regardless of decay window.
- D-10: Example domain decay rates: software/tech ~6mo, scientific findings ~2yr, biographical facts ~5yr+, personal goals ~3mo.
- D-11: Decay rate definitions live in AGENTS.md section 6.
- D-12: Lint auto-fixes claim-level stale markers when claims cross decay threshold. Mechanical, deterministic, reversible.
- D-13: Page-level `epistemic_status` only auto-updated to `stale` when rollup clearly warrants it (all material stale, or TL;DR materially stale). Default: do not auto-change.
- D-14: All auto-fix staleness changes logged in lint report and `wiki/log.md`.
- D-15: Lint produces persistent wiki page at `wiki/maintenance/lint-report.md`.
- D-16: CLI `bin/lint.sh` prints compact summary to stdout.
- D-17: Three severity tiers: error (must fix), warning (should fix), info (nice to know).
- D-18: Auto-fix boundary: mechanical fixes only -- deterministic and reversible.
- D-19: Report-only (no auto-fix): contradictions, knowledge gaps, orphan pages, page restructuring, anything requiring judgment.
- D-20: Red link flagging: flag when unresolved wikilink appears on 2+ distinct pages. Exception: red links in TL;DR or Key Facts always flagged.
- D-21: Sparse source coverage measured by comparative heuristic relative to other domains.
- D-22: Maturity guardrail: sparse coverage detection only runs when wiki has enough domains/sources for comparison to be meaningful.
- D-23: Lint suggests investigative questions for gaps, not specific sources.

### Claude's Discretion
- Exact inline syntax for contradiction markers (consistent with provenance/epistemic patterns, captures both source references)
- Exact decay rate numbers per domain (layered model: domain base + epistemic modifier + hash override)
- CLI `bin/lint.sh` internal implementation (argument parsing, output formatting)
- Lint report page structure and Dataview frontmatter (organized by severity and category)
- Maturity threshold for sparse coverage detection (prevents false alarms on young wikis)
- Whether to create `wiki/maintenance/` as new directory or integrate into existing structure

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CNTR-01 | Lint rule that identifies when sources disagree on the same claim | Contradiction detection via provenance marker parsing -- D-01 through D-03 define the detection model |
| CNTR-02 | Contradictions surfaced with both sides cited | Inline contradiction markers per D-03, aggregated in lint report per D-04 |
| CNTR-03 | Contradictions flagged in affected wiki pages | Inline markers + `has_contradictions: true` frontmatter field per D-05 |
| STALE-01 | Claims inherit temporal relevance from source publication dates | `checked_at` field on provenance markers + `ingested_at` on source pages provide date chain |
| STALE-02 | Lint rule flags claims older than configurable threshold | Domain-based decay rate table in AGENTS.md section 6 per D-07, D-10, D-11 |
| STALE-03 | Different knowledge types decay at different rates | Layered model: domain base + epistemic modifier + hash override per D-07/D-08/D-09 |
| STALE-04 | Decay rate conventions documented in schema per knowledge domain | AGENTS.md section 6 extension with domain decay rate table per D-11 |
| GAP-01 | Lint identifies topics mentioned frequently but lacking dedicated pages | Red link analysis with salience rules per D-20 |
| GAP-02 | Lint identifies categories with sparse source coverage | Comparative heuristic per D-21 with maturity guardrail per D-22 |
| LINT-01 | Lint workflow that health-checks the wiki on demand | `bin/lint.sh` CLI helper + fully operational AGENTS.md section 11.3 |
| LINT-02 | Detect orphan pages (no inbound links) | Wikilink graph analysis from `wiki/index.md` + page body parsing |
| LINT-03 | Detect missing cross-references (related pages not linked) | Domain-overlap heuristic: pages sharing domains/tags that lack mutual wikilinks |
| LINT-04 | Detect stale claims (per STALE-01/02) | Staleness checks from decay rates + `checked_at` + hash comparison |
| LINT-05 | Detect contradictions (per CNTR-01/02/03) | Contradiction detection from provenance marker parsing |
| LINT-06 | Suggest new questions to investigate and sources to look for | Gap-based question generation per D-23 |
| LINT-07 | Lint workflow documented step-by-step in schema | AGENTS.md section 11.3 extension with severity tiers, auto-fix boundary, detection rules |
| CLI-03 | Lint helper that runs all lint rules and reports findings | `bin/lint.sh` following established CLI helper pattern |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python 3 | 3.12.3 (installed) | YAML parsing, date math, frontmatter extraction | Already used by `validate-op.sh`; PyYAML available |
| PyYAML | 6.0.1 (installed) | YAML frontmatter parsing | Already a project dependency |
| Bash | 5.x (installed) | CLI wrapper, file traversal, grep orchestration | Matches `bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh` pattern |
| GNU grep | 3.11 (installed) | Regex pattern matching for provenance/epistemic markers | Standard, zero-dependency |

### Supporting
| Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GNU date | coreutils 9.4 | Date arithmetic for staleness threshold calculation | Decay rate comparisons |
| sort/uniq | coreutils | Frequency counting for red links, domain statistics | Gap detection heuristics |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Python for YAML | yq (CLI) | yq adds a dependency; python3+PyYAML already established in validate-op.sh |
| Bash script | Python-only CLI | Would break the "bash wrapper, python for structured parsing" pattern |

**No installation required.** All tools are already present on the system and used by existing CLI helpers.

## Architecture Patterns

### Recommended Project Structure
```
bin/
  lint.sh                    # CLI entry point (bash, follows ingest.sh/validate-op.sh pattern)
wiki/
  maintenance/
    lint-report.md           # Persistent lint report page (frontmatter + findings by category)
  index.md                   # Input: page inventory for orphan detection
  log.md                     # Output: lint appends log entries here
  sources/                   # Input: source pages with content_hash, checked_at
  concepts/                  # Input/Output: pages checked and potentially auto-fixed
  entities/                  #   ...
  comparisons/               #   ...
  overviews/                 #   ...
AGENTS.md                    # Schema extensions: section 5 (new fields), section 6 (decay rates), section 11.3 (full lint workflow)
```

### Pattern 1: Bash Wrapper + Python Internals
**What:** `bin/lint.sh` is a bash script that orchestrates lint checks. Complex logic (YAML parsing, date math, provenance extraction) is delegated to inline python3 blocks, exactly as `validate-op.sh` does.
**When to use:** All lint checks.
**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Collect all wiki pages
PAGES=$(find wiki -name "*.md" -not -name "index.md" -not -name "log.md" -not -path "wiki/maintenance/*")

# Run staleness check via python3
python3 -c "
import sys, yaml, os
from datetime import date, timedelta
# ... parse frontmatter, compute decay, report findings
" "$@"
```

### Pattern 2: Finding Accumulator
**What:** Each lint rule produces findings as structured lines (category, severity, page, message). All findings accumulate into a list, then are sorted by severity and written to the report page and stdout summary.
**When to use:** Orchestrating multiple independent lint rules into a single report.
**Example output format:**
```
error|provenance|wiki/concepts/foo.md|Broken prov ref: src-missing-id not found in wiki/sources/
warning|stale|wiki/concepts/bar.md|Claim checked_at 2025-01-01 exceeds 6mo decay for domain software
warning|orphan|wiki/entities/baz.md|No inbound wikilinks from other wiki pages
info|gap|red-link:Machine Learning|Mentioned on 3 pages but no dedicated page exists
```

### Pattern 3: Schema-First Implementation
**What:** Extend AGENTS.md first (new fields, decay table, severity definitions, contradiction syntax), then implement lint rules that enforce the schema.
**When to use:** This phase specifically -- the lint rules are mechanical enforcement of documented conventions.
**Why:** Ensures the lint report can reference specific AGENTS.md rules, and any agent following the schema will produce lint-compatible output.

### Anti-Patterns to Avoid
- **LLM-dependent lint rules:** The lint must be fully deterministic with zero API calls. No "ask the LLM if these claims contradict." Contradiction detection is provenance-marker-based (same subject/attribute, different source assertions), not semantic.
- **Overloading epistemic_status for contradictions:** D-05 explicitly separates `has_contradictions` from `epistemic_status`. A sourced page can have contradictions.
- **Auto-fixing judgment calls:** D-18/D-19 draw a hard line. Contradictions, gaps, orphans are report-only. Only stale markers, missing cross-references (where target exists), and unambiguous provenance fixes are auto-fixable.
- **Flagging on young wikis:** D-22 requires a maturity guardrail for sparse coverage. With only 3 domains and 3 sources, every domain is equally thin -- the comparison is meaningless.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML frontmatter parsing | Custom regex parser | python3 + PyYAML `yaml.safe_load()` | Handles edge cases (multiline, special chars, lists). Already proven in validate-op.sh |
| Date arithmetic | Manual day counting | python3 `datetime` module | Leap years, month boundaries, timedelta math |
| Wikilink extraction | Ad-hoc grep patterns | Single well-tested regex: `\[\[([^\]]+)\]\]` | Consistent extraction across all wiki pages |
| Provenance marker parsing | Multiple grep passes | Single regex: `\[prov:([^#\]]+)#([^\]|]+)(?:\|([^\]|]+))?(?:\|([^\]]+))?\]` | Extended syntax with optional support_type and checked_at |

**Key insight:** Every lint rule reduces to: parse frontmatter + scan body with regex + compare against known state (index, source registry, other pages). The complexity is in the orchestration and reporting, not in any single check.

## Common Pitfalls

### Pitfall 1: Wikilink Alias Resolution
**What goes wrong:** Wikilinks use display names like `[[Daniel Kahneman]]` but the file is `daniel-kahneman.md`. Orphan detection fails if it only matches exact filenames.
**Why it happens:** Obsidian resolves wikilinks by title, aliases, and filename. The lint must replicate this resolution.
**How to avoid:** Build a resolution map from frontmatter: filename -> id, title, aliases. When scanning for inbound links, resolve `[[Display Name]]` against this map. The `aliases` frontmatter field exists precisely for this.
**Warning signs:** Pages with aliases or title-case names showing up as orphans when they clearly have inbound links.

### Pitfall 2: Cross-Reference False Positives
**What goes wrong:** Lint suggests every page in the same domain should link to every other page in that domain, producing noise.
**How to avoid:** Use conservative heuristics for "missing cross-references": pages that share 2+ domains AND 2+ tags AND are mentioned in each other's source pages' `compiled_targets` but lack mutual wikilinks. This keeps the signal-to-noise ratio high.
**Warning signs:** Lint report dominated by cross-reference suggestions that are obviously unrelated.

### Pitfall 3: Staleness Date Chain Gaps
**What goes wrong:** Many provenance markers use the basic form `[prov:source_id#locator]` without `checked_at`. The lint cannot compute staleness without a date.
**Why it happens:** Extended syntax with `checked_at` is optional per AGENTS.md section 6.
**How to avoid:** When `checked_at` is missing from the provenance marker, fall back to: (1) the source page's `ingested_at` date, (2) the wiki page's `updated_at` date. Document this fallback chain in the lint rules.
**Warning signs:** Large numbers of claims skipped for staleness checks because of missing dates.

### Pitfall 4: Contradiction Detection Scope Creep
**What goes wrong:** Attempting semantic contradiction detection ("these two paragraphs seem to disagree") instead of provenance-backed source-level disagreement.
**Why it happens:** Natural instinct to be thorough.
**How to avoid:** Stick to D-01: two different `source_id` values asserting conflicting claims about the same subject/attribute. The lint script cannot do semantic analysis -- it can only flag when the same wiki page section has provenance markers from multiple sources. The LLM agent reading the lint report decides if it's an actual contradiction.
**Warning signs:** Trying to parse prose meaning in bash/python.

### Pitfall 5: Lint Report as Wiki Page Must Have Valid Frontmatter
**What goes wrong:** Creating `wiki/maintenance/lint-report.md` without proper frontmatter, breaking Dataview queries and validate-op.sh.
**How to avoid:** The lint report page needs full AGENTS.md section 5 compliant frontmatter (id, title, type, status, etc.). Use `type: overview` since it's synthesis/operational content. Mark `privacy: cloud_safe` since it contains no source content, only metadata about the wiki.

## Code Examples

### Frontmatter Extraction (from validate-op.sh pattern)
```python
import yaml

def parse_frontmatter(filepath):
    """Extract YAML frontmatter from a wiki page."""
    content = open(filepath).read()
    if not content.startswith('---'):
        return None, content
    try:
        end = content.index('---', 3)
        fm = yaml.safe_load(content[3:end])
        body = content[end+3:].strip()
        return fm, body
    except (ValueError, yaml.YAMLError):
        return None, content
```

### Wikilink Extraction
```python
import re

WIKILINK_RE = re.compile(r'\[\[([^\]|]+)(?:\|[^\]]+)?\]\]')

def extract_wikilinks(body):
    """Extract all wikilink targets from page body text."""
    return set(WIKILINK_RE.findall(body))
```

### Staleness Calculation
```python
from datetime import date, timedelta

DECAY_RATES = {
    'software': timedelta(days=180),
    'technology': timedelta(days=180),
    'science': timedelta(days=730),
    'biography': timedelta(days=1825),
    'personal-goals': timedelta(days=90),
}
DEFAULT_DECAY = timedelta(days=365)

EPISTEMIC_MODIFIERS = {
    'tentative': 0.5,   # decays twice as fast
    'inferred': 0.75,   # decays 33% faster
    'sourced': 1.0,     # base rate
    'mixed': 0.85,      # slightly faster
}

def is_stale(checked_at, knowledge_domain, epistemic_status):
    base = DECAY_RATES.get(knowledge_domain, DEFAULT_DECAY)
    modifier = EPISTEMIC_MODIFIERS.get(epistemic_status, 1.0)
    threshold = timedelta(days=int(base.days * modifier))
    return (date.today() - checked_at) > threshold
```

### Provenance Marker Parsing
```python
import re

PROV_RE = re.compile(
    r'\[prov:([^#\]]+)#([^|\]]+)'    # source_id and locator (required)
    r'(?:\|([^|\]]+))?'               # support_type (optional)
    r'(?:\|([^\]]+))?'                # checked_at (optional)
    r'\]'
)

def extract_provenance(body):
    """Extract all provenance markers from body text.
    Returns list of (source_id, locator, support_type, checked_at) tuples."""
    return PROV_RE.findall(body)
```

### Red Link Detection
```python
def find_red_links(all_pages, wikilink_map):
    """Find unresolved wikilinks appearing on 2+ pages or in TL;DR/Key Facts."""
    red_links = {}  # target -> list of (page, section)
    known_titles = set()  # resolved page titles/aliases/ids
    
    for page_path, fm, body in all_pages:
        if fm:
            known_titles.add(fm.get('title', ''))
            known_titles.add(fm.get('id', ''))
            for alias in (fm.get('aliases') or []):
                known_titles.add(alias)
    
    for page_path, fm, body in all_pages:
        for link_target in extract_wikilinks(body):
            if link_target not in known_titles:
                if link_target not in red_links:
                    red_links[link_target] = []
                # Check if in TL;DR or Key Facts section
                in_salient = is_in_salient_section(body, link_target)
                red_links[link_target].append((page_path, in_salient))
    
    # Filter: 2+ pages OR any salient-section mention
    findings = {}
    for target, mentions in red_links.items():
        pages = set(m[0] for m in mentions)
        any_salient = any(m[1] for m in mentions)
        if len(pages) >= 2 or any_salient:
            findings[target] = mentions
    return findings
```

### Lint Report Generation
```python
REPORT_TEMPLATE = """---
id: lint-report
title: Lint Report
type: overview
status: active
summary: "Wiki health-check findings from most recent lint run."
created_at: {created}
updated_at: {today}
sources: []
epistemic_status: sourced
tags:
  - meta
  - maintenance
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Lint Report
---

# Lint Report

**Last run:** {today}
**Total findings:** {total}
**Auto-fixes applied:** {fixes}

## Errors ({error_count})

{error_findings}

## Warnings ({warning_count})

{warning_findings}

## Info ({info_count})

{info_findings}
"""
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AGENTS.md section 11.3 has 12-step skeleton | Phase 5 makes it fully operational with concrete rules | This phase | All 12 steps get detection rules, severity tiers, auto-fix policies |
| No decay rate table | Domain-based decay rate table in AGENTS.md section 6 | This phase | Staleness detection becomes configurable per knowledge domain |
| No contradiction syntax | `[contradiction:src_a#locator vs src_b#locator]` inline markers | This phase | Source disagreements become visible in page content |
| No `knowledge_domain` or `has_contradictions` fields | New frontmatter fields per section 5 | This phase | Enables domain-aware staleness and contradiction tracking |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash + manual verification (no test framework in project) |
| Config file | none -- project uses ad-hoc validation scripts |
| Quick run command | `bash bin/lint.sh 2>&1` |
| Full suite command | `bash bin/lint.sh 2>&1` + manual review of `wiki/maintenance/lint-report.md` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CNTR-01 | Contradiction detection between sources | smoke | `bash bin/lint.sh 2>&1 \| grep -i contradiction` | Wave 0 |
| CNTR-02 | Both sides cited in contradiction | manual | Review lint-report.md contradiction entries | Wave 0 |
| CNTR-03 | Contradictions flagged in wiki pages | manual | Check affected pages for `[contradiction:]` markers | Wave 0 |
| STALE-01 | Claims inherit temporal relevance | smoke | `bash bin/lint.sh 2>&1 \| grep -i stale` | Wave 0 |
| STALE-02 | Configurable threshold flagging | smoke | Modify decay rate, re-run lint, verify flag changes | Wave 0 |
| STALE-03 | Different decay rates per domain | manual | Verify AGENTS.md section 6 decay rate table entries | Wave 0 |
| STALE-04 | Decay rates documented in schema | manual | Read AGENTS.md section 6 for decay rate table | Wave 0 |
| GAP-01 | Red link frequency detection | smoke | `bash bin/lint.sh 2>&1 \| grep -i gap` | Wave 0 |
| GAP-02 | Sparse coverage detection | smoke | `bash bin/lint.sh 2>&1 \| grep -i sparse` | Wave 0 |
| LINT-01 | On-demand health check | smoke | `bash bin/lint.sh` exits 0 | Wave 0 |
| LINT-02 | Orphan page detection | smoke | `bash bin/lint.sh 2>&1 \| grep -i orphan` | Wave 0 |
| LINT-03 | Missing cross-reference detection | smoke | `bash bin/lint.sh 2>&1 \| grep -i "cross-ref\|missing link"` | Wave 0 |
| LINT-04 | Stale claim detection | smoke | Same as STALE-01/02 | Wave 0 |
| LINT-05 | Contradiction detection | smoke | Same as CNTR-01 | Wave 0 |
| LINT-06 | Suggest questions for gaps | manual | Review lint-report.md info section for question suggestions | Wave 0 |
| LINT-07 | Workflow documented in schema | manual | Read AGENTS.md section 11.3 for complete workflow | Wave 0 |
| CLI-03 | Lint helper runs all rules | smoke | `bash bin/lint.sh --help` exits 0 + `bash bin/lint.sh` runs all categories | Wave 0 |

### Sampling Rate
- **Per task commit:** `bash bin/lint.sh` runs without errors on the current wiki
- **Per wave merge:** Full lint run + manual review of lint-report.md
- **Phase gate:** Full lint run produces findings across all categories (orphans, stale, contradictions, gaps) on the existing wiki content

### Wave 0 Gaps
- [ ] `wiki/maintenance/` directory -- needs to be created
- [ ] `bin/lint.sh` -- the main deliverable, does not exist yet
- [ ] `wiki/maintenance/lint-report.md` -- generated by lint, created on first run
- [ ] Existing wiki pages may need `knowledge_domain` backfilled to test staleness rules

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | YAML parsing, date math | Yes | 3.12.3 | -- |
| PyYAML | Frontmatter parsing | Yes | 6.0.1 | -- |
| GNU grep | Pattern matching | Yes | 3.11 | -- |
| GNU date | Date arithmetic | Yes | coreutils 9.4 | python3 datetime |
| sha256sum | Hash comparison | Yes | coreutils 9.4 | -- |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

All required tools are already installed and proven in existing CLI helpers.

## Open Questions

1. **Contradiction detection granularity**
   - What we know: D-01 says "two different sources assert conflicting claims about the same subject/attribute." The lint is file-based and deterministic.
   - What's unclear: How does the lint mechanically identify "same subject/attribute" without semantic analysis? The most feasible approach is same wiki page section + different source_ids in provenance markers. The LLM agent that reads the lint report provides the semantic judgment.
   - Recommendation: Lint flags when a single wiki page has claims from 2+ sources in the same section. The lint report marks these as "potential contradictions" for agent review. The agent (during a lint workflow run) promotes confirmed ones to `[contradiction:]` markers. This keeps the script deterministic while still surfacing real conflicts.

2. **knowledge_domain backfill for existing pages**
   - What we know: Existing pages have `domains` (list) but not `knowledge_domain` (single primary domain for decay rate).
   - What's unclear: Should lint add `knowledge_domain` to existing pages as an auto-fix, or should it be a report-only finding?
   - Recommendation: Report-only for the first lint run. The planner should include a task that backfills `knowledge_domain` on all existing pages as part of the schema extension plan. The lint then validates presence on subsequent runs.

3. **Maturity threshold for sparse coverage**
   - What we know: D-22 says "only runs when wiki has enough domains and sources for comparison to be meaningful."
   - What's unclear: Exact threshold.
   - Recommendation: Minimum 5 domains with at least 3 having 2+ sources before sparse coverage detection activates. This is within Claude's Discretion per CONTEXT.md.

## Sources

### Primary (HIGH confidence)
- `AGENTS.md` sections 5, 6, 10 (Pass 4), 11.3 -- current schema and workflow skeleton
- `bin/validate-op.sh` -- established CLI helper pattern with python3+PyYAML inline blocks
- `bin/ingest.sh` -- established CLI helper pattern (bash, zero API deps)
- `bin/search.sh` -- established CLI helper pattern (index parsing, output contracts)
- `.planning/phases/05-lint-quality/05-CONTEXT.md` -- all 23 locked decisions

### Secondary (MEDIUM confidence)
- Existing wiki pages (10 pages) -- validated frontmatter structure, provenance marker syntax, wikilink conventions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all tools already installed and proven in existing helpers
- Architecture: HIGH -- follows established `bin/*.sh` pattern exactly, CONTEXT.md decisions are comprehensive
- Pitfalls: HIGH -- derived from actual wiki content inspection and schema analysis

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (stable domain, all file-based)

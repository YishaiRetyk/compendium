# Technology Stack

**Project:** LLM Wiki Compiler
**Researched:** 2026-04-06
**Note:** WebSearch, WebFetch, and Bash were unavailable during research. All version numbers are from training data (cutoff ~May 2025). Versions marked with `*` should be verified before installation.

## Recommended Stack

This is a **file-based, local system** -- not a web application. The "stack" is: markdown processing libraries, CLI tooling, Obsidian plugins, and conventions for LLM agents. No server, no database, no framework.

### Core: Markdown Processing (Node.js / unified ecosystem)

| Technology | Version* | Purpose | Why |
|------------|----------|---------|-----|
| **unified** | ~11.x | Pipeline engine for markdown AST processing | Industry standard for programmatic markdown manipulation. Plugin architecture lets you compose parse-transform-stringify pipelines. Every serious markdown tool in the Node ecosystem builds on this. |
| **remark-parse** | ~11.x | Markdown -> mdast (AST) | Standard parser in the unified ecosystem. Handles CommonMark + extensions. |
| **remark-stringify** | ~11.x | mdast (AST) -> Markdown | Round-trips markdown through AST without corrupting content. |
| **remark-frontmatter** | ~5.x | YAML frontmatter support in AST | Preserves frontmatter during AST transforms -- critical since every wiki page has frontmatter. |
| **remark-gfm** | ~4.x | GitHub Flavored Markdown tables, task lists | GFM is the de facto markdown dialect. Obsidian uses it. Tables are essential for structured wiki content. |
| **mdast-util-to-string** | ~4.x | Extract plain text from AST nodes | Useful for building indexes, extracting claim text, search corpus generation. |
| **gray-matter** | ~4.0.3 | Parse/serialize YAML frontmatter | Simpler than full remark pipeline when you only need to read/write frontmatter. Battle-tested, 25M+ weekly downloads. Use this for frontmatter-only operations; use remark when you need to manipulate body content. |
| **js-yaml** | ~4.1.0 | YAML parsing/serialization | gray-matter uses this internally. Also useful standalone for schema files, config, structured data. |

**Confidence:** MEDIUM -- these packages are stable and long-lived but exact latest versions unverified.

**Why Node.js / unified:** The unified/remark ecosystem is the only mature, composable markdown processing toolkit. Python's markdown libraries (mistune, markdown-it-py) are parsers, not round-trip AST manipulation tools. Since this project needs to programmatically read, transform, and write markdown while preserving structure, unified is the only serious choice.

### Core: Wikilink Support

| Technology | Version* | Purpose | Why |
|------------|----------|---------|-----|
| **remark-wiki-link** | ~2.x | Parse `[[wikilinks]]` in remark pipeline | Obsidian uses `[[wikilinks]]` extensively. This plugin adds them to the mdast AST so you can programmatically discover, create, and validate cross-references. |
| Custom wikilink regex (fallback) | n/a | Simple `\[\[([^\]]+)\]\]` extraction | For lightweight operations (link extraction, validation) where spinning up a full remark pipeline is overkill. A 3-line regex covers 95% of wikilink parsing needs. |

**Confidence:** MEDIUM -- remark-wiki-link exists and works, but its maintenance status should be checked. Wikilink parsing is simple enough that a custom solution is viable if the package is stale.

### Core: Markdown Linting

| Technology | Version* | Purpose | Why |
|------------|----------|---------|-----|
| **markdownlint-cli2** | ~0.14.x | CLI markdown linter | Configurable rules, supports custom rules, runs on file globs. Use for structural validation (heading hierarchy, frontmatter presence, link format). The `-cli2` variant is the maintained successor to `markdownlint-cli`. |

**Confidence:** MEDIUM -- stable, well-maintained project.

### Obsidian Plugins (User-Installed)

| Plugin | Purpose | Why |
|--------|---------|-----|
| **Dataview** | Query frontmatter, render dynamic tables/lists | The backbone of making the wiki navigable. Indexes, dashboards, "all claims from source X" -- all powered by Dataview queries over frontmatter. Non-negotiable for this project. |
| **Templater** | Advanced templates with logic | Useful for human-triggered page creation. Not critical for LLM workflows (LLMs generate pages directly) but good for manual overrides. |
| **Graph View** (core plugin) | Visualize wiki link structure | Built into Obsidian. The wiki's cross-reference structure becomes visible. No installation needed. |
| **Marp Slides** (optional) | Generate presentations from markdown | Listed in project requirements. Install if/when slide generation is needed. |
| **Linter** (obsidian-linter) | Auto-format markdown on save | Keeps human edits consistent with LLM-generated formatting. Configure to match the wiki's style conventions. |

**Confidence:** HIGH for Dataview (it is the most popular Obsidian community plugin). MEDIUM for others.

**What NOT to install:** Avoid Obsidian plugins that maintain their own databases or indices (e.g., Obsidian DB Folder, various Kanban plugins). The wiki's metadata lives in frontmatter and git -- adding a parallel data store creates drift. Dataview is the exception because it reads frontmatter at query time rather than maintaining a separate store.

### CLI Helpers

| Technology | Version* | Purpose | Why |
|------------|----------|---------|-----|
| **Node.js** | 20 LTS or 22 LTS | Runtime for CLI tools | LTS stability. The unified ecosystem is Node-native. |
| **TypeScript** | ~5.x | Type safety for CLI tools | The wiki schema (page types, frontmatter shapes) benefits enormously from type checking. Typed frontmatter interfaces catch schema drift at compile time. |
| **tsx** | ~4.x | Run TypeScript directly without build step | For CLI scripts: `tsx scripts/ingest.ts`. No build pipeline needed for a local tool. |
| **commander** | ~12.x | CLI argument parsing | Standard, lightweight. For commands like `wiki ingest <source>`, `wiki lint`, `wiki search <query>`. |
| **glob** | ~10.x (or fast-glob ~3.x) | File discovery | Find all wiki pages, all sources, pages matching patterns. |
| **simple-git** | ~3.x | Git operations from Node.js | For the compilation pipeline: commit after ingest, diff detection, provenance via git log. Wraps git CLI with a clean async API. |

**Confidence:** HIGH for Node/TS/commander (extremely stable). MEDIUM for tsx, simple-git (verify versions).

### Search

| Technology | Purpose | Why |
|------------|---------|-----|
| **ripgrep (rg)** | Fast full-text search across markdown files | Already installed on most dev machines. Faster than any Node-based search for local files. The "index-first search" in the project spec means LLM agents grep the index page first, then drill into results. ripgrep is the engine. |
| **fzf** (optional) | Fuzzy interactive search | For human CLI usage. Pipe ripgrep output into fzf for interactive browsing. |
| **Custom index files** | Structured search catalog | The project's index system IS the search layer for v1. LLM agents read `_index/` files to find relevant pages. No embedding DB needed. |

**Confidence:** HIGH -- ripgrep is the standard CLI search tool. The index-first approach is a project design decision, not a technology choice.

**What NOT to use for v1:** Embedding-based search (ChromaDB, Qdrant, FAISS, etc.). The project explicitly scopes this out. Index-first search (structured catalog + ripgrep) is the v1 approach. Embeddings are a v2 consideration if index-first proves insufficient.

### Git Workflow

| Technology | Purpose | Why |
|------------|---------|-----|
| **git** (CLI) | Version control, provenance, diff | Every wiki mutation is a git commit. Provenance = git log. Contradiction detection can use git diff. The wiki IS a git repo. |
| **simple-git** (Node.js) | Programmatic git from CLI tools | For the compilation pipeline to auto-commit after operations. |
| **Conventional Commits** (convention) | Structured commit messages | `ingest: add source "Deep Work"`, `compile: update [[Focus]] from 3 sources`, `lint: flag contradiction in [[Sleep]]`. Makes git log parseable by LLM agents. |

**Confidence:** HIGH -- git is the obvious and only choice for a file-based, local system.

### Frontmatter / Metadata Schema

This is a convention, not a library. But it is a critical stack decision.

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `type` | string enum | Page type for Dataview queries | `entity`, `concept`, `source-summary`, `comparison`, `index` |
| `title` | string | Display title | `"Deep Work"` |
| `aliases` | string[] | Alternative names (Obsidian uses this for link resolution) | `["Cal Newport's Deep Work"]` |
| `created` | ISO date | When page was created | `2026-04-06` |
| `updated` | ISO date | Last modification | `2026-04-06` |
| `sources` | string[] | Source document paths | `["sources/books/deep-work.md"]` |
| `epistemic` | string enum | Overall page confidence | `sourced`, `inferred`, `tentative`, `stale` |
| `tags` | string[] | Categorization | `["productivity", "focus"]` |
| `status` | string enum | Lifecycle state | `draft`, `active`, `archived`, `superseded` |
| `superseded_by` | string | Wikilink to replacement page | `"[[Deep Work (Revised)]]"` |

**Claim-level provenance** (inline, not frontmatter):

```markdown
Deep work produces 2-4x more output than shallow work. ^[source::sources/books/deep-work.md|ch3] ^[epistemic::sourced] ^[since::2026-04-06]
```

This uses Obsidian's `^[key::value]` inline metadata syntax, which Dataview can query.

**Confidence:** MEDIUM -- the frontmatter fields are standard Obsidian/Dataview conventions. The inline provenance syntax is a design decision that should be validated during v1 usage. Dataview's inline field syntax (`[key::value]` within parentheses or `field:: value` on its own line) is documented but the exact ergonomics for claim-level annotation need testing.

### LLM Agent Interface

This is the **schema layer**, not a library.

| Component | Format | Purpose |
|-----------|--------|---------|
| `CLAUDE.md` | Markdown | Instructions for Claude Code agents |
| `AGENTS.md` | Markdown | Instructions for Codex and other agents |
| Operation definitions | Markdown section in schema | `UPDATE`, `MERGE`, `SUPERSEDE`, `ARCHIVE` -- structured operations the LLM follows instead of raw file rewrites |
| Page templates | Markdown files in `_templates/` | Type-specific templates (entity, concept, source-summary, comparison) that LLMs fill in |

**What NOT to use:** LLM agent frameworks (LangChain, LlamaIndex, CrewAI, AutoGen, etc.). These are for building software that orchestrates LLM calls. This project is the inverse: the LLM agents already exist (Claude Code, Codex), and the wiki provides instructions they follow. Adding a framework would create a software dependency where none is needed. The schema IS the framework.

**Confidence:** HIGH -- this is a core architectural decision of the project, not an external technology choice.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Markdown processing | unified/remark (Node.js) | python-markdown, mistune | No round-trip AST manipulation. Parse-only, not transform-and-serialize. |
| Markdown processing | unified/remark | pandoc | Pandoc is a format converter, not a programmatic AST toolkit. Good for one-shot conversion, wrong for incremental wiki manipulation. |
| Frontmatter parsing | gray-matter | manual YAML parsing | gray-matter handles edge cases (delimiters, encoding, excerpts). No reason to hand-roll. |
| CLI framework | commander | yargs, oclif | Commander is simpler and sufficient. oclif is for building distributable CLI products, which this is not. |
| Search (v1) | ripgrep + index files | Embeddings (ChromaDB, etc.) | Explicitly out of scope for v1. Index-first is simpler, debuggable, and sufficient for personal-scale. |
| Agent orchestration | Schema files (CLAUDE.md) | LangChain, CrewAI | The agents already exist. The wiki provides instructions, not an orchestration layer. Adding a framework is pure overhead. |
| Note-taking app | Obsidian | Logseq, Notion | Obsidian has the best plugin ecosystem (Dataview), true local-first files, graph view, and wikilink support. Logseq is outline-first (wrong for wiki pages). Notion is cloud-dependent and proprietary. |
| Version control | git | None / manual backups | Git provides: history, diff, branch, merge, blame. All essential for provenance and compilation pipeline. |
| Runtime | Node.js | Python, Deno, Bun | Node has the unified/remark ecosystem. Python lacks good round-trip markdown AST tools. Deno/Bun could work but add friction without benefit (npm compatibility issues, smaller ecosystem for this niche). |

## Installation

```bash
# Initialize project
npm init -y

# Core markdown processing
npm install unified remark-parse remark-stringify remark-frontmatter remark-gfm
npm install gray-matter js-yaml

# Wikilink support
npm install remark-wiki-link

# CLI tooling
npm install commander glob simple-git

# Dev dependencies
npm install -D typescript tsx @types/node

# Linting
npm install -D markdownlint-cli2

# Optional: types for libraries
npm install -D @types/js-yaml
```

```bash
# System tools (verify installed)
which rg    # ripgrep -- install via package manager if missing
which git   # git -- required
which node  # Node.js 20+ LTS
```

```bash
# Obsidian plugins (install via Obsidian community plugins)
# - Dataview (mandatory)
# - Templater (recommended)
# - Linter (recommended)
# - Marp Slides (optional, when needed)
```

## Version Verification Needed

Since web tools were unavailable during research, the following versions should be verified before committing to `package.json`:

| Package | Stated Version | Verify Command |
|---------|---------------|----------------|
| unified | ~11.x | `npm view unified version` |
| remark-parse | ~11.x | `npm view remark-parse version` |
| remark-stringify | ~11.x | `npm view remark-stringify version` |
| remark-frontmatter | ~5.x | `npm view remark-frontmatter version` |
| remark-gfm | ~4.x | `npm view remark-gfm version` |
| gray-matter | ~4.0.3 | `npm view gray-matter version` |
| remark-wiki-link | ~2.x | `npm view remark-wiki-link version` |
| markdownlint-cli2 | ~0.14.x | `npm view markdownlint-cli2 version` |
| commander | ~12.x | `npm view commander version` |
| simple-git | ~3.x | `npm view simple-git version` |
| tsx | ~4.x | `npm view tsx version` |
| TypeScript | ~5.x | `npm view typescript version` |

## Key Stack Principles

1. **Minimal dependencies.** Every package must earn its place. The wiki is mostly markdown files + conventions. Libraries are for the CLI helpers and compilation pipeline, not the wiki itself.

2. **No runtime services.** No databases, no servers, no Docker. `node script.ts` and `git commit` are the heaviest operations.

3. **Obsidian-compatible always.** Every convention must produce valid Obsidian markdown. If a tool generates output Obsidian cannot render, the tool is wrong.

4. **Agent-readable over machine-readable.** Frontmatter should be clear to an LLM reading the file, not just parseable by code. Verbose field names over abbreviations.

5. **Git is the database.** History, provenance, diffs, blame -- all from git. Do not replicate what git already does.

## Sources

- unified ecosystem: https://unifiedjs.com/ (MEDIUM confidence -- known stable project, versions unverified)
- gray-matter: https://github.com/jonschlinkert/gray-matter (MEDIUM confidence -- stable, versions unverified)
- Obsidian Dataview: https://github.com/blacksmithgu/obsidian-dataview (HIGH confidence -- dominant Obsidian plugin)
- markdownlint-cli2: https://github.com/DavidAnson/markdownlint-cli2 (MEDIUM confidence -- versions unverified)
- ripgrep: https://github.com/BurntSushi/ripgrep (HIGH confidence -- standard tool)
- All version numbers are from training data (cutoff ~May 2025) and should be verified before use

# Compendium

A local-first LLM knowledge compiler built on Obsidian, plain markdown, and git.

## What this is

Compendium is a repository template for building an LLM-maintained knowledge vault from your own sources: book notes, articles, journals, transcripts, and similar materials.

Deterministic CLI helpers manage the file and workflow scaffolding. An LLM coding agent then compiles sources into cross-linked entity, concept, comparison, overview, and decision pages with claim-level provenance. Every important claim can point back to its source, and contradictions are surfaced rather than silently flattened away.

Unlike search-over-notes or chat-on-top-of-PDFs, the result is a persistent artifact. Cross-references are already there. Syntheses accumulate. The vault gets more useful as you ingest more material and ask better questions.

## Who this is for

Technical Obsidian users who are comfortable with bash, git, and working with an LLM coding agent such as Claude Code or Codex. If you want a compounding knowledge base instead of a chat-on-top-of-PDFs workflow, this repo is for you.

## Repo shape

```
AGENTS.md                 Canonical agent spec
CLAUDE.md                 Byte-identical copy of AGENTS.md
README.md                 Project overview
LICENSE                   MIT
PRIVACY.md                Privacy tiers and sharing model
wiki/                     Your compiled knowledge vault (starts empty)
examples/                 Reference example clusters
bin/                      CLI helpers (ingest, lint, search, ...)
docs/                     Quickstart, guided/manual setup, reference
schema/                   Template and schema support files
```

## Prerequisites

- bash >= 4
- python3
- git >= 2.30
- [Obsidian](https://obsidian.md)
- an LLM coding agent such as Claude Code or Codex

Some workflows require additional Python packages. Brownfield onboarding, in particular, has extra requirements documented in [`docs/reference/brownfield.md`](docs/reference/brownfield.md).

## First step

Start with [docs/quickstart.md](docs/quickstart.md).

## License

MIT — see [LICENSE](LICENSE).

# <org>/<repo>

A persistent, compounding wiki compiled from your sources by an LLM agent. Built on Obsidian + plain markdown + git.

## What this is

A repository scaffold that turns book notes, articles, and journal entries into a cross-linked knowledge vault. An LLM agent ingests sources through a deterministic CLI (`bin/ingest.sh`), synthesizing them into entity/concept/comparison/overview pages with claim-level provenance. Every claim is traceable back to its source; contradictions between sources are flagged rather than resolved silently.

Unlike search-over-notes or retrieval-over-PDFs, the wiki is a persistent artifact. Cross-references are already there. Synthesis already reflects everything ingested.

## Who this is for

Technical Obsidian users comfortable with bash, git, and running a local LLM agent (Claude Code, Codex, or equivalent). If you want a compounding knowledge base instead of a chat-on-top-of-PDFs experience, this is for you.

## Repo shape

```
AGENTS.md                 Canonical agent spec (schema + operations)
CLAUDE.md                 Byte-identical dup of AGENTS.md (agent-agnostic filename)
README.md                 This file
LICENSE                   MIT
PRIVACY.md                Tier model (local_only vs cloud_safe)
wiki/                     Your compiled knowledge vault (starts empty)
examples/kahneman/        Reference example cluster (Daniel Kahneman, behavioral economics)
bin/                      CLI helpers (ingest.sh, lint.sh, search.sh, ...)
docs/                     Quickstart, guided/manual setup, reference
schema/                   AGENTS.template.md (wizard source)
```

## Prerequisites

- bash ≥ 4
- python3 (stdlib only for Phase 7 tooling; later phases require additional Python packages — PyYAML is used by `bin/lint.sh` schema parsing in v1.0 and remains required, and Phases 10–11 brownfield onboarding adds `ruamel.yaml`. See `docs/reference/brownfield.md`.)
- git ≥ 2.30
- [Obsidian](https://obsidian.md) for reading + editing
- An LLM coding agent (Claude Code, Codex, or similar) for ingest

## First step

See [docs/quickstart.md](docs/quickstart.md).

## License

MIT — see [LICENSE](LICENSE).

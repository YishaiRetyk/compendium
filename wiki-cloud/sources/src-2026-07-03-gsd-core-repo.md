---
id: src-2026-07-03-gsd-core-repo
title: "open-gsd/gsd-core — GSD Core repository snapshot"
type: source
status: active
summary: "Curated snapshot of the GSD Core repository (the renamed continuation
  of the get-shit-done lineage) at commit 69fef7c0 — README, rename/lineage
  evidence, context-engineering doc, and code excerpts; first repository-type
  source."
created_at: 2026-07-03
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- gsd
- gsd-core
- claude-code
- agentic-frameworks
- context-engineering
- repository
domains:
- ai-agents
- software
supersedes:
superseded_by:
aliases:
- "GSD Core repository snapshot"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-07/2026-07-03-gsd-core-repo/source.md
url: "https://github.com/open-gsd/gsd-core"
content_hash: "sha256:fe5db8a725b7ca3d455c1cbac32b391569f2db97fd7b52c1546bffc638734b7b"
ingested_at: 2026-07-03
source_type: repository
repo_url: "https://github.com/open-gsd/gsd-core"
commit_sha: "69fef7c00e277b6e1e17fe15e530304c1d6bb5e3"
default_branch: next
license: MIT
primary_language: JavaScript
compilation_status: compiled
compiled_against_hash: "sha256:fe5db8a725b7ca3d455c1cbac32b391569f2db97fd7b52c1546bffc638734b7b"
compiled_targets:
- gsd
---

# open-gsd/gsd-core — GSD Core repository snapshot

## TL;DR

First `source_type: repository` source: a curated snapshot of **GSD Core** (`open-gsd/gsd-core`) at commit `69fef7c0` on the `next` branch. GSD Core is the renamed, org-hosted continuation of the get-shit-done lineage — the legacy `get-shit-done-cc`/`get-shit-done-redux` package line (versions 1.0.0→1.42.x) is retired and archived, with the new `@opengsd/gsd-core` version stream restarting at 1.0.0 [prov:src-2026-07-03-gsd-core-repo#path:CHANGELOG.md:L482-L488|direct|2026-07-03]. The snapshot captures the README, the rename/lineage evidence, the context-engineering explanation doc, and package metadata.

## Key Takeaways

- The project formerly at `gsd-build/get-shit-done` now continues as GSD Core under the OpenGSD org; the old repo is an archived redirect. [prov:src-2026-07-03-gsd-core-repo#path:CHANGELOG.md:L482-L488|direct|2026-07-03]
- Current package: `@opengsd/gsd-core` v1.7.0-rc.1, MIT, by OpenGSD (no longer a solo-author project line). [prov:src-2026-07-03-gsd-core-repo#path:package.json:L1-L5|direct|2026-07-03] [prov:src-2026-07-03-gsd-core-repo#path:package.json:L38-L40|direct|2026-07-03]
- The context-rot thesis is now documented first-party: quality degrades silently as the window fills; fresh-context subagents are framed as "a structural solution", not a workaround. [prov:src-2026-07-03-gsd-core-repo#path:docs/explanation/context-engineering.md:L7-L13|direct|2026-07-03]
- The workflow is a five-step per-phase loop: Discuss → Plan → Execute (parallel waves, clean 200k-token executor contexts) → Verify → Ship. [prov:src-2026-07-03-gsd-core-repo#sec:how-it-works|direct|2026-07-03]
- Multi-runtime by install-time compilation: the npx installer targets Claude Code, OpenCode, Gemini CLI, Kimi CLI, Kilo, Codex, Copilot, Cursor, Windsurf and more; copying `agents/`/`commands/` files directly is unsupported. [prov:src-2026-07-03-gsd-core-repo#sec:quickstart|direct|2026-07-03]

## Extracted Claims

- At the snapshot commit, the repository ships 34 agent definitions under `agents/` and 69 command files under `commands/`. [prov:src-2026-07-03-gsd-core-repo#commit:69fef7c0|direct|2026-07-03]
- GSD Core self-describes as "light-weight". [prov:src-2026-07-03-gsd-core-repo#sec:readme|direct|2026-07-03] [epistemic:: tentative]
- "GSD Core solves all three: heavy work runs in fresh subagents, structured artifacts like STATE.md and CONTEXT.md survive session boundaries, and the verify step walks through what was built" — the README's reliability pitch. [prov:src-2026-07-03-gsd-core-repo#sec:why-it-works|direct|2026-07-03] [epistemic:: tentative]
- The two version streams (legacy 1.x and new-line 1.x) are deliberately kept in separate files "so the two version streams cannot collide". [prov:src-2026-07-03-gsd-core-repo#path:CHANGELOG.md:L482-L488|direct|2026-07-03]

## Notes

- The snapshot was taken from the repository's default branch `next` (not `main`) — that is where HEAD points upstream.
- Epistemic split exercised per `schema/reference/repository-ingestion.md`: code/metadata claims (`#path:`, `#commit:`) are `sourced`; README self-descriptive capability claims ("light-weight", the reliability pitch) carry claim-level `[epistemic:: tentative]` hedges.
- The curator trimmed badge shields and the star-history embed from the README copy (noted inline); all cited sections retained verbatim.
- Discovery path: the previously-documented home `gsd-build/get-shit-done` was snapshotted first and found to be an archived redirect stub pointing here — that stub was not ingested; this snapshot of the live repository is the source of record. The redirect observation is recorded here as context, with the rename evidence anchored to this snapshot's CHANGELOG excerpt.

## Source Metadata

- Repository: <https://github.com/open-gsd/gsd-core>
- Commit: `69fef7c00e277b6e1e17fe15e530304c1d6bb5e3` (branch `next`)
- Retrieved: 2026-07-02 (UTC); ingested 2026-07-03
- Acquisition: `bin/repo-snapshot.sh` (shallow clone → metadata harvest → README + curated excerpts)
- License: MIT; Primary language: JavaScript (extension-count heuristic; TypeScript sources compile to the shipped CJS)

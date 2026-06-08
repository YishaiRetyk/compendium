# Privacy Model

This template tracks page privacy through a two-tier frontmatter field: `privacy: local_only` or `privacy: cloud_safe`.

## Tiers

- **`cloud_safe`** — The page is safe to share. No personal identifiers, private experiences, or sensitive data. Default for synthesized domain knowledge.
- **`local_only`** — The page contains personal journal entries, sensitive notes, or anything you do not want uploaded to a remote LLM or shared in a public repo. Must never ship in the public template surface.

## Operational meaning

- Local LLM ingest may read `local_only` pages when you explicitly pass them as context.
- Remote / cloud LLM workflows must filter `local_only` out of prompts.
- CI gates described here are enforced by CI starting in this release (Phase 7 ships the neutrality + denylist gate; later phases extend it with full lint severity, privacy-leak guard, and contributor checks). PRs that place `local_only` content under public paths (`AGENTS.md`, `CLAUDE.md`, `README.md`, `examples/**`, `docs/**`, `.github/**`) are blocked by these gates.
- Stricter tier always wins on merge (if two versions of a claim disagree, the `local_only` classification is preserved).

## What must never commit to the public template

- Any page with `privacy: local_only`.
- Any creator-specific domain terms (see neutrality enforcement; denylist in `.neutrality-denylist.txt`).
- Any content under `.planning/` or `.brownfield/` (gitignored).

## Canonical spec

See [`AGENTS.md §5`](AGENTS.md) for the authoritative frontmatter schema and enforcement semantics. This document is a user-facing summary; AGENTS.md is the source of truth.

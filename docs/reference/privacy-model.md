# Privacy Model

> Reference documentation for the privacy routing model: the `local_only` / `cloud_safe` tiers, the three-level precedence hierarchy, fail-closed conflict resolution, wiki-page privacy inheritance, and CI enforcement.

## TL;DR

Every item in the wiki system carries a privacy classification that decides whether it may be sent to a cloud LLM API. The system is **fail-closed**: when classification is uncertain, the answer is `local_only`. It is always better to under-share than to accidentally send private content to a cloud API.

> **Source of truth:** The authoritative privacy specification lives in [AGENTS.md §13](../../AGENTS.md). This page reproduces it for ergonomic reference — including the §13 decision table verbatim — and adds CI-enforcement pointers. If you find a discrepancy, §13 wins and this page is the bug.

## Privacy tiers

- **`local_only`** — NEVER sent to cloud LLM APIs. Processed only by local models or local tooling.
- **`cloud_safe`** — May be sent to cloud LLM APIs for processing.

## Three-level precedence

Privacy classification resolves through a three-level precedence hierarchy (most specific wins):

1. **Explicit `privacy` field in item frontmatter** — the authoritative declaration. If present, it is always respected.
2. **Enclosing directory default** — operational convenience. Directories like `sources/local-only/` imply `local_only`; `sources/cloud-safe/` implies `cloud_safe`.
3. **System default: `local_only`** — if neither frontmatter nor directory provides a signal, the item is `local_only` (fail-closed).

## Conflict resolution

If the frontmatter and directory disagree, the **stricter** setting wins. Because `local_only` is always stricter than `cloud_safe`, any conflict resolves to `local_only`. An item explicitly marked `local_only` cannot be loosened by a permissive directory, and a restrictive directory cannot be loosened by a permissive frontmatter field.

## Privacy decision table

This table is reproduced verbatim from AGENTS.md §13 (it is already neutral):

| # | Frontmatter `privacy` | Directory               | Result       | Why                                                    |
|---|----------------------|-------------------------|-------------|--------------------------------------------------------|
| 1 | `cloud_safe`         | `sources/cloud-safe/`   | `cloud_safe` | Both agree: cloud_safe                                 |
| 2 | `local_only`         | `sources/cloud-safe/`   | `local_only` | Frontmatter is stricter, stricter wins                 |
| 3 | `cloud_safe`         | `sources/local-only/`   | `local_only` | Directory is stricter, stricter wins                   |
| 4 | (not set)            | `sources/cloud-safe/`   | `cloud_safe` | No frontmatter, directory provides signal              |
| 5 | (not set)            | `sources/2026/2026-04/` | `local_only` | No frontmatter, no privacy directory signal, system default |
| 6 | (not set)            | (no directory signal)   | `local_only` | Fail-closed: unknown = local_only                      |
| 7 | `local_only`         | (no directory signal)   | `local_only` | Explicit local_only confirmed                          |

## Wiki page privacy inheritance

When a wiki page cites sources with mixed privacy tiers, the page inherits the **strictest** tier among its contributing sources. A page is only `cloud_safe` if ALL of its contributing sources are `cloud_safe`. This is a mechanical check, not a judgment call: if any contributing source is `local_only`, the write-back target is `local_only`.

This is enforced at operation time. `bin/validate-op.sh` (AGENTS.md §9) refuses an `UPDATE` that would fold `local_only`-derived content into a `cloud_safe` page — either create a separate `local_only` page for the sensitive synthesis, or change the existing page to `local_only`.

## Rules for LLM agents

1. Check privacy classification BEFORE sending any content to a cloud API.
2. If classification cannot be determined, treat as `local_only`.
3. Never send `local_only` content to cloud LLM APIs under any circumstances.
4. When creating wiki pages, set `privacy` based on the strictest contributing source.

The same fail-closed precedence governs the claim-faithfulness audit and any agent-parity run that seeds a cloud subprocess: a fail-closed seed guard requires every seeded source to declare `privacy: cloud_safe` and aborts otherwise (see [agent-parity.md](agent-parity.md)).

## CI enforcement

`bin/check-privacy.sh` is a standalone gate (the pattern-twin of `bin/check-neutrality.sh`) that scans YAML frontmatter under **public paths** for `privacy: local_only`. The public paths are hardcoded: `examples/`, `docs/`, `AGENTS.md`, `CLAUDE.md`, `README.md`, `.github/`. The `wiki/**` tree is explicitly EXCLUDED — `local_only` is valid user content there.

**Exit codes:** `0` clean, `1` script failure, `2` privacy-leak found (stderr carries `path:line:` entries).

In CI, `bin/check-privacy.sh` runs as the `privacy-leak` job — a required status check that fails any PR introducing `privacy: local_only` frontmatter into a public path. See [ci.md](ci.md) for the full CI surface and the `--ci` severity policy.

## See also

- [AGENTS.md](../../AGENTS.md) — §13 privacy routing (the source of truth).
- [ci.md](ci.md) — the `privacy-leak` CI job and `bin/check-privacy.sh` exit codes.
- [schema-tour.md](schema-tour.md) — the `privacy` frontmatter field in the broader schema.
- [../../PRIVACY.md](../../PRIVACY.md) — the user-facing privacy posture.
- [../README.md](../README.md)
- [index.md](index.md)

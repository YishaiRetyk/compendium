# Privacy Model

> Reference documentation for the Phase 15 asymmetric two-directory privacy model: `wiki-cloud/` (cloud-safe tier) + `wiki-local/` (local-only tier), enforcement options, fail-direction table, and the `sources-local/` forward reference.

## TL;DR

Privacy is **structural** in this wiki system: the directory a page lives in determines its privacy tier. There is no per-page `privacy` frontmatter field — it was removed in Phase 15 (see `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md`).

- **`wiki-cloud/`** — cloud-safe tier. Cloud sessions (Claude Code, Codex, etc.) may read this tier freely.
- **`wiki-local/`** — local-only tier. Cloud sessions MUST NOT read this tier.

> **Source of truth:** AGENTS.md §13 (one-line pointer). This page is the full reference for the asymmetric model, enforcement options, fail-direction table, and forward references.

## The Asymmetric Two-Directory Model

### One-Way Permeability

The two tiers are **asymmetrically permeable**:

- Local sessions (your own machine, local model) may read **both** tiers.
- Cloud sessions MUST NOT read `wiki-local/`.

**The forbidden direction:** `local → cloud` (leaking `wiki-local/` content to a cloud API).
**The permitted direction:** `cloud → local` does not apply (cloud sessions simply cannot access `wiki-local/`).

### Structural Classifier

Page tier is determined entirely by directory:

| Directory | Tier | Who can read |
|-----------|------|--------------|
| `wiki-cloud/**` | cloud-safe | Cloud sessions + local sessions |
| `wiki-local/**` | local-only | Local sessions only |

There is no per-page override. A page is local because it lives under `wiki-local/`.

### Raw Sources Rule

`sources/` is **cloud-safe-only**. Raw source files under `sources/` may be read by cloud sessions during ingest. A source that must be local lives as its **source-summary page under `wiki-local/sources/`** — the FAITH-04 resolver (`bin/lib/privacy_resolve.py`) keys off the summary page tier, not the raw `sources/` path.

The **`bin/check-sources-cloud-safe.sh`** guard (CI-wired) asserts this invariant: it exits non-zero if any raw source under `sources/` carries `privacy: local_only` frontmatter or if a `sources/local-only/` directory exists. This is a fail-closed migration + CI guard: a future adopter who adds a sensitive raw source triggers CI failure, forcing them onto the `sources-local/` structural tier (described below) rather than silently leaking.

### Forward Reference: `sources-local/` Tier

When a vault accumulates real local raw content (e.g., sensitive PDFs), the correct structural pattern is a **separate `sources-local/` directory** (or a nested git repo for the fail-closed pattern below). This deferred tier:

- Lives outside `sources/` (which is cloud-safe-only by structural rule).
- Has its source-summary pages under `wiki-local/sources/`.
- Is documented here and will be scaffolded in Phase D (WIZ) when the interactive privacy-tier wizard prompt is implemented.

Today's creator vault has zero local raw sources (code-verified at Phase 15). The `bin/check-sources-cloud-safe.sh` guard protects the forward trust model.

## Enforcement Options

### Option 1: Cloud-Settings Deny-Profile (Convenience, FAIL-OPEN)

`.claude/settings.cloud.json` — a cloud-scoped settings file applied via `--settings .claude/settings.cloud.json` — can contain:

```json
{
  "permissions": {
    "deny": ["Read(./wiki-local/**)"]
  }
}
```

**Honest label: CONVENIENCE / FAIL-OPEN (single-clone, low-stakes work only).**

This approach has two critical limitations:
1. A cloud session launched **without** the `--settings` flag inherits the permissive default and CAN read `wiki-local/`.
2. The `Read` deny blocks the `Read` tool only; `cat`, `grep`, or `python -c open(...)` via Bash may bypass it depending on Claude Code version.

**Use when:** You want a soft guard for casual cloud sessions on a machine you control, and your `wiki-local/` content is low-sensitivity (e.g., audit control-plane files with no real personal content).

### Option 2: Separate-Repo (Fail-Closed Guarantee)

For real sensitive content, `wiki-local/` becomes **its own git repo** — a nested repo inside the vault root, gitignored by the parent:

```
compendium/          <- parent repo (wiki-cloud/, schema/, bin/, etc.)
compendium/wiki-local/   <- nested local repo (gitignored by parent)
```

**Why this is fail-closed:**
- The local repo has its own private remote (not pushed to GitHub or any cloud host).
- A cloud clone of the parent repo contains no `wiki-local/` objects — `git show HEAD:wiki-local/…` finds nothing.
- Obsidian still sees one unified vault (the nested repo lives inside the vault root), so graph view + piped links work across both tiers (D-14 preservation).
- The `§11.6` orphan-branch release neutralization already excludes both `wiki-cloud/` and `wiki-local/` creator content.

**Use when:** You have real secrets or sensitive personal content in `wiki-local/`.

## Fail-Direction Table

| Control | Fails Which Way | Notes |
|---------|----------------|-------|
| Cloud deny-profile (`--settings`) | FAIL-OPEN | Requires flag at launch; Bash tool may bypass `Read` deny |
| Separate-repo gitignore | FAIL-CLOSED | Object-level isolation; no git objects in parent history |
| `wiki-local/` directory boundary | FAIL-OPEN for git access | `git show HEAD:wiki-local/…` works on a shared-history clone |
| `bin/check-sources-cloud-safe.sh` | FAIL-CLOSED (migration gate) | CI-wired; blocks future non-cloud-safe raw sources |

**Rule: real private content → fail-closed path (separate-repo).**
The deny-profile is a convenience guard for low-stakes single-clone workflows only.

## FAITH-04 Effective-Claim Privacy

The audit workflow (`bin/audit-claims.sh`) uses a structural predicate for claim privacy:

> A claim is effective-`local_only` iff its wiki page **OR** any contributing source-summary lives under `wiki-local/`.

This is the collapsed predicate (Phase 15), replacing the previous §13 three-level precedence ladder. The raw `sources/` path is NEVER the privacy signal — only the source-SUMMARY page tier matters.

## CI Enforcement

| Guard | Location | What it checks |
|-------|----------|---------------|
| `bin/check-privacy.sh` | CI `privacy-leak` job | wiki-local/ path component under PUBLIC_PATHS (structural PATH guard) |
| `bin/check-sources-cloud-safe.sh` | CI `privacy-leak` job | raw sources/ is cloud-safe-only (fail-closed, PRIV-03) |
| `bin/check-neutrality.sh` | CI `neutrality` job | personal terms from wiki-local/ NOT in public-facing docs (content scan) |

## See Also

- [AGENTS.md](../../AGENTS.md) — §13 privacy routing (one-line pointer to here).
- `wiki-cloud/decisions/dr-2026-06-04-privacy-asymmetric-two-dir.md` — execution-time DR recording the three weighed options.
- [ci.md](ci.md) — the `privacy-leak` CI job and exit codes.
- [../../PRIVACY.md](../../PRIVACY.md) — the user-facing privacy posture.
- [index.md](index.md)

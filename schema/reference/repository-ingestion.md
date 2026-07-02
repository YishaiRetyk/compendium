# Repository Ingestion

> Agent-authoritative reference for the `repository` source type: the snapshot bundle convention, `#path:`/`#commit:` locators, the within-source epistemic split, and the acquisition runbook.
> The AGENTS.md routing table points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

Use this file when acquiring a code repository as a source (running the snapshot runbook), authoring the source summary for a repository, anchoring claims to code with `#path:` locators, or deciding the epistemic status of claims drawn from a repository's self-descriptions.

## 1. Classification — Repository Is a New Primary Type

`repository` is a **first-class `source_type` enum value** — the extension contract's first *primary* new-type instance. Unlike the PDF and video formats (which tell you how bytes arrived, not what the content is), a repository is a different *kind* of source: a versioned tree of code and documentation with an identity (`commit_sha`) that keeps moving upstream after you snapshot it.

Walking the 5 dimensions of the extension contract (`schema/reference/source-types.md`):

| Dimension | Effect of the repository source |
|-----------|--------------------------------|
| **Acquisition** | Changes **unconditionally** — a curated snapshot is taken from a live VCS (clone/harvest), not downloaded or copy-pasted as a document. |
| **Locator** | Changes **unconditionally** — `#path:<file>[:L<n>[-L<m>]]` and `#commit:<sha>` are NEW locator grammar (nothing existing addresses a file tree). |
| **Extraction Granularity** | Unchanged — atomic claims, inherited from the article/paper norm. |
| **Drift** | Changes **unconditionally** — the upstream is **live**: every existing type is static or published-immutable; a repository's default branch moves after ingest. The committed snapshot itself stays immutable; what drifts is the upstream. |
| **Epistemic Default** | Changes **structurally** — a within-source claim-class split (code vs self-description; see the Epistemic Split section), new to the system. |

Four of five dimensions change — comfortably past the contract's ≥1 bar. This is the inverse verdict of the PDF/video evaluations, reached by the same rule.

At Pass 0, classify a repository source directly as `source_type: repository` (it does NOT classify to a parent type first — there is no parent).

## 2. Snapshot Bundle Convention

The raw source is a **curated snapshot bundle** — explicitly NOT a full clone. The wiki compiles *claims about* the repository; the repository itself lives upstream.

`sources/YYYY/YYYY-MM/YYYY-MM-DD-<slug>/source.md` contains, in order:

1. **A metadata section** (`## Snapshot Metadata`) — repository URL, full commit SHA, default branch, license, primary language, retrieval date. This is the passage `#commit:` locators resolve to.
2. **Curated documentation content** — the README (trimmed of badges/boilerplate at the curator's judgment) and any key docs worth preserving, as markdown sections addressable by `#sec:`.
3. **An `## Excerpts` registry** — code excerpts the curator quotes, each under a heading of the form:

```markdown
## Excerpts

### <path/to/file.py>:L<n>-L<m>

    (fenced code block with the quoted lines)

### <path/to/other-file.md>

    (fenced block quoting the relevant content)
```

The registry is what makes `#path:` locators **resolvable offline** by `bin/audit-claims.sh` — the same pattern as the research-report `## References` registry. The rule of thumb: **if you anchor a claim to code, quote the code.**

## 3. Frontmatter Fields (Repository Sources)

Required on every `source_type: repository` source summary (lint enforces all three):

| Field | Meaning |
|-------|---------|
| `repo_url` | Canonical repository URL (e.g. `https://github.com/<owner>/<repo>`). Consumed by external drift detection. |
| `commit_sha` | Full 40-hex commit SHA the snapshot was taken at. The snapshot's identity; the drift comparison anchor. |
| `default_branch` | The branch whose HEAD the SHA was taken from (e.g. `main`). |

Recommended (omit entirely when unknown — never leave empty):

| Field | Meaning |
|-------|---------|
| `license` | SPDX-style license name detected at snapshot time. |
| `primary_language` | Dominant implementation language. |
| `stars_at_ingest` | Star count at snapshot time (a popularity claim frozen in time). |

All flat `snake_case` (independently Dataview-queryable). `knowledge_domain: software` (180-day decay) is the default staleness bucket.

## 4. Locator Usage — `#path:` and `#commit:`

Two new locator forms (documented in `schema/reference/provenance.md` Locator Types):

- `#path:<file>` — a claim about a file as a whole (e.g. `#path:src/parser.py`).
- `#path:<file>:L<n>` / `#path:<file>:L<n>-L<m>` — a claim anchored to specific lines *at the snapshot's commit* (line numbers are only meaningful against `commit_sha`).
- `#commit:<sha>` — a claim about the snapshot commit itself (≥7 hex chars; must prefix-match the source's `commit_sha`).

**Resolution semantics** (`bin/audit-claims.sh`):

- `#path:` resolves against the `## Excerpts` registry: exact path match on an excerpt heading; a line range resolves when it is contained in an excerpt's declared range. No matching excerpt → `insufficient-locator` (NOT an error — the honest-degradation precedent of `#p` without page markers and `#r` without a bibliography).
- `#commit:` resolves to the `## Snapshot Metadata` passage when the SHA prefix-matches the source's `commit_sha`; any other SHA → `insufficient-locator` (the snapshot documents exactly one commit).

`#sec:` continues to work for README/docs prose in the snapshot — no new grammar needed there.

Claims keep `support_type: direct`. A repository is a **primary** source: snapshotting is *extraction*, not *derivation*. Marketing risk in self-descriptions is carried by epistemic markers (next section), NEVER by the support type — using `derived` on a repository claim would be an epistemic-laundering error.

## 5. Within-Source Epistemic Split

Repository content mixes claim classes with different trust profiles. The convention splits them:

| Claim class | Anchor | Epistemic handling |
|-------------|--------|--------------------|
| **Code behavior** (what the code does) | `#path:` with an excerpt | `sourced` — the code is the fact. |
| **Benchmarks / measured numbers** | `#path:`/`#sec:` | `sourced`, cite the number verbatim; note the measurement context. |
| **Self-descriptive capability claims** ("fast", "production-ready", "battle-tested") | `#sec:` into the README | MANDATORY claim-level `[epistemic:: tentative]` hedge, even on a `sourced` page — a README is self-descriptive marketing. |
| **Project facts** (license, language, structure) | `#commit:` / metadata | `sourced`. |

Page-level default: `sourced` for code-anchored summaries; `mixed` when README self-description dominates the page's claims.

## 6. Drift Stance (Fields Now, Machinery in Phase 23 / lint `--network`)

The upstream is **live** — the only source type whose referent keeps changing after ingest. The stance:

- The **committed snapshot is immutable** and claims remain faithful to it: a claim anchored `#path:...:L10-L12` at `commit_sha` stays true *of that commit* forever.
- **Drift** = upstream default-branch HEAD no longer equals `commit_sha` (detected cheaply via `git ls-remote`, no clone), or the repository is unreachable (link-rot).
- Drift is **surfaced, review-only** (external drift checks in `schema/workflows/lint.md`). Nothing auto-updates. When currency matters, the human re-snapshots — that is a NEW ingest producing a new source; the old source stays and is superseded normally.

## 7. Acquisition Runbook

**Generic contract:** any pipeline that captures (a) the README and key docs as markdown, (b) the full commit SHA + default branch + repo URL, and (c) curator-selected code excerpts under `## Excerpts` headings satisfies this convention. The convention is tool-generic.

**Worked instance:** `bin/repo-snapshot.sh <repo-url> [--dest <bundle-dir>]` does the mechanical part —

1. `git clone --depth 1` to a temp directory (never into the repo tree).
2. Harvests `commit_sha` (`git rev-parse HEAD`), `default_branch`, license file, and a dominant-language heuristic.
3. Emits a snapshot `source.md` skeleton: `## Snapshot Metadata` filled in, README body appended, empty `## Excerpts` scaffold.

**Curation stays human/agent judgment** (the mechanical-vs-judgment boundary): choosing which docs to keep, trimming boilerplate, and selecting excerpts is done after the script runs, before ingest.

## 8. Ingest Checklist

1. Run `bin/repo-snapshot.sh <repo-url> --dest sources/YYYY/YYYY-MM/YYYY-MM-DD-<slug>` to scaffold the bundle.
2. Curate: trim the README copy, add key docs, populate `## Excerpts` with the code you intend to anchor claims to.
3. Author the source summary with `source_type: repository` + the three required fields (`repo_url`, `commit_sha`, `default_branch`) and any recommended fields you know.
4. Claims use `#path:`/`#commit:`/`#sec:` locators with `support_type: direct`; apply the epistemic split (hedge self-descriptions `[epistemic:: tentative]`).
5. Set `knowledge_domain: software` on dependent pages that inherit the decay bucket.

## See Also

- `schema/reference/source-types.md` — the extension contract this type instantiates.
- `schema/reference/frontmatter.md` — the repository field block.
- `schema/reference/provenance.md` — `#path:`/`#commit:` in the Locator Types table.
- `schema/workflows/ingest.md` — Pass 0 classification, claim granularity.
- `schema/workflows/lint.md` — external drift checks (`--network`) that consume `repo_url`/`commit_sha`.

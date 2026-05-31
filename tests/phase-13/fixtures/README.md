# Phase 13 Fixtures — the self-contained fixture contract

Phase 13 tests do **not** copy from a `fixtures/` data directory. Every downstream
`tests/phase-13/test_*.sh` builds its fixture **inline** via `write_page` (from
`lib.sh`), and every fixture is **self-contained**: it writes BOTH artifacts the
claim-faithfulness audit needs, so no test ever points the audit at a raw file
that is not on disk.

> **Why self-contained?** The production `examples/` cluster ships source-summary
> pages whose `path:` points at raw files that are NOT on disk. The audit's D-11
> resolver reads the **raw source at `path:`**, never the summary's
> `## Extracted Claims`. A fixture that wrote only the summary would resolve to a
> missing raw file and degrade to `insufficient-locator`, masking the behavior
> under test. So fixtures write both.

All examples below use **abstract placeholders only** (`<source-id>`,
`<YYYY-MM-DD-slug>`, `<concept-slug>`) — no real vault terms (CLAUDE.md §3
neutrality discipline; `tests/` is not a public path, but we keep the discipline).

---

## 1. Each fixture writes BOTH artifacts

A. **The source-summary page** at `wiki/sources/<source-id>.md`
   (frontmatter `type: source`) with the required source-summary fields:
   `id`, `path: sources/YYYY/YYYY-MM/<YYYY-MM-DD-slug>/source.md`, `content_hash`,
   `compiled_against_hash`, `ingested_at`, `source_type`, and `privacy`.

B. **The raw source file** at that exact `path:`. The audit reads THIS file for
   passage resolution (D-11) — never the summary page body.

```bash
# A — the summary page (the registry entry: source_id -> path:)
write_page "$REPO" "wiki/sources/<source-id>.md" <<'EOF'
---
id: <source-id>
title: "<Source Title>"
type: source
status: active
path: sources/2026/2026-04/<YYYY-MM-DD-slug>/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
...
---
EOF

# B — the RAW source at that exact path:
write_page "$REPO" "sources/2026/2026-04/<YYYY-MM-DD-slug>/source.md" <<'EOF'
<!-- page: 1 -->
## Introduction

A paragraph the audit can slice for a #sec:introduction locator.

<!-- page: 2 -->
## Results

Another paragraph for #para resolution.
EOF
```

## 2. Raw sources carry real locator anchors

Raw fixture sources include, as the scenario requires:

- real `## headings` — so a `#sec:<name>` locator resolves;
- blank-line-delimited paragraphs — so a `#para<n>` locator resolves;
- `<!-- page: N -->` markers — so a `#p<n>` locator resolves against a **marked**
  source (D-05); `#p8` slices `page: 8` → `page: 9`, `#p12-14` spans
  `page: 12` → `page: 15` (exclusive);
- at least one **unmarked** paginated raw source — so a `#p` locator against it
  degrades to the first-class `insufficient-locator` verdict (D-06).

## 3. Fixture variants needed across the phase

| Variant | What it exercises |
|---------|-------------------|
| `cloud_safe` privacy | claim reaches the verdict step (worklist) |
| `local_only` privacy | fail-closed partition → `skipped-privacy` (D-02/D-03) |
| `marked` pagination | `#p` resolves against `<!-- page: N -->` markers (D-05) |
| `unmarked` pagination | `#p` degrades to `insufficient-locator` (D-06) |
| `img` claim | non-text `#img<n>` locator → `skipped-nontext` |
| `missing-raw` | summary present, raw file absent → graceful `insufficient-locator` (never crash) |
| `stale-source` | `content_hash != compiled_against_hash` → FAITH-01 stale selector (D-09) |
| `high-fanout` | ≥N inbound wikilinks → FAITH-01 high-fanout selector (D-09) |
| `recency` | page committed then modified → git-diff recently-modified selector (D-09) |

The `stale-source` fixture sets `content_hash != compiled_against_hash`. The
`high-fanout` fixture seeds ≥N inbound wikilinks at the target page. The `recency`
fixture commits a page, then modifies it, so the git-diff selector picks it up.

## 4. `local_only` is the realistic production default — high `skipped-privacy` is NOT a failure

Every current production `wiki/sources/*.md` is `local_only`. The D-03
`skipped-privacy`-by-default behavior (absent a local `--verifier`) is therefore
the **realistic production state**, not a bug. Tests assert that `local_only`
fixtures are partitioned OUT of the cloud worklist; a high `skipped-privacy` count
is expected and acceptable (D-03). Do NOT pad coverage to avoid it.

## 5. Making the non-deterministic verdict step reproducible

The verdict (LLM) step is the only non-deterministic stage; everything else is
deterministic. Tests stub the verdict via the `lib.sh` verifier helpers:

- `make_fake_verifier <repo> <verdict> <rationale>` — canned verdict, ignores argv.
- `make_recording_verifier <repo> <verdict>` — appends every stdin payload to
  `<repo>/verifier-saw.log`; the load-bearing fail-closed negative test asserts
  this log NEVER contains a `local_only` source's distinctive passage text.
- `make_argv_verifier <repo> <verdict>` — dumps full argv to
  `<repo>/verifier-argv.log` and discards stdin; proves the `--tag` arg reaches
  argv but claim/passage text does NOT (stdin-only-payload contract).

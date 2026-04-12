# LLM Wiki Compiler Schema

> **This is the sole authoritative specification for the LLM Wiki Compiler.**
> Any LLM agent maintaining this wiki MUST read and follow this document.
> No other file contains conventions, rules, or workflow definitions.

## 1. Overview and Principles

The LLM Wiki Compiler is a personal knowledge management system with three layers:

1. **Raw sources** (`sources/`) -- Immutable input documents (articles, papers, transcripts, journal entries, images). The human curates this layer. Sources are never modified after ingestion.
2. **The wiki** (`wiki/`) -- LLM-generated and maintained markdown pages. This is the compiled artifact: summaries, entity pages, concept pages, comparisons, overviews, an index, and an activity log.
3. **The schema** (this file + `schema/`) -- The specification that governs LLM behavior. This file is the sole source of truth.

**Core principle:** The wiki is a persistent, compounding artifact. Cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested. Knowledge accumulates rather than being re-derived.

**Role division:**
- The **human** curates sources and asks questions.
- The **LLM** writes and maintains the wiki: summarizing, cross-referencing, filing, and ensuring consistency.

**Four operations** govern all wiki activity:

| Operation | Purpose |
|-----------|---------|
| **Ingest** | Process a new source into wiki pages |
| **Query** | Answer a question using the wiki, optionally compiling new pages |
| **Lint** | Detect contradictions, stale claims, orphan pages, missing cross-references |
| **Reflect** | Structural reasoning, decision records, reframing history |

Workflows for each operation are defined in Section 11 of this document.

## 2. Directory Structure

```
life/                               # repo root
├── AGENTS.md                       # This file (sole authority)
├── sources/                        # Raw immutable sources
│   ├── YYYY/                       # Year grouping
│   │   └── YYYY-MM/               # Month grouping
│   │       ├── YYYY-MM-DD-slug/   # Bundle: source.md + assets
│   │       │   ├── source.md
│   │       │   └── figure1.png
│   │       └── YYYY-MM-DD-slug.md # Single file (no assets)
│   └── assets/                     # Optional: shared/tool-managed assets only
├── wiki/                           # LLM-maintained pages
│   ├── entities/                   # People, tools, organizations
│   ├── concepts/                   # Ideas, theories, frameworks
│   ├── sources/                    # Source summary pages (one per ingested source)
│   ├── comparisons/                # Comparison pages
│   ├── overviews/                  # High-level topic summaries
│   ├── index.md                    # Content catalog (master page list)
│   └── log.md                      # Chronological activity log
└── schema/                         # Optional: templates, examples
    └── templates/                  # Page templates per type
```

**Source directory rules:**
- Sources use chronological nesting: `YYYY/YYYY-MM/YYYY-MM-DD-slug/`
- When a source has assets (images, figures, attachments): create a bundle directory with `source.md` as the main file and assets co-located alongside it.
- When a source is text-only: use a single file `YYYY-MM-DD-slug.md` (no bundle directory needed).
- Source metadata (type, topic, privacy) is stored in the source file's frontmatter, not encoded in the directory structure.

**Wiki directory rules:**
- Pages are organized by type subdirectory: `entities/`, `concepts/`, `sources/`, `comparisons/`, `overviews/`.
- Topics and categories are represented via frontmatter fields (`tags`, `domains`), NOT via filesystem hierarchy.
- `wiki/index.md` and `wiki/log.md` live directly inside `wiki/` (they are wiki-layer artifacts).

**Schema directory rules:**
- `schema/` is optional and holds templates and examples.
- It does NOT contain rules or conventions -- those live only in this file.

## 3. Global Rules

### Date Format

All dates use ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ss`. No exceptions. This ensures Dataview can parse and sort dates correctly.

### Frontmatter Field Names

All frontmatter field names use `snake_case`. This prevents Dataview field name sanitization issues (Dataview converts spaces and special characters, creating mismatches between YAML keys and query field names).

### Commit Conventions

All commits use conventional commit format with wiki operation types:

| Type | When | Example |
|------|------|---------|
| `ingest(source-slug):` | Processing a new source | `ingest(hinton-interview): add source summary and update entity pages` |
| `query(topic):` | Answering a question, synthesizing pages | `query(attention-mechanisms): synthesize comparison of attention variants` |
| `lint(scope):` | Fixing detected issues | `lint(wiki): fix 3 orphan pages and 2 broken provenance references` |
| `reflect(scope):` | Structural reasoning, decision records | `reflect(q1-review): restructure AI safety domain after new sources` |
| `schema:` | Updating this document or templates | `schema: define base frontmatter fields and page type conventions` |

**One commit per logical operation.** A single ingest that touches 15 files is one commit. Rule: if the change answers "what happened?" with one sentence, it is one commit.

### LLM Navigation Rule

When searching for information in the wiki:

1. Read `wiki/index.md` FIRST to find relevant pages.
2. Scan `## TL;DR` and `## Key Facts` sections of relevant pages BEFORE reading Detail sections.
3. Only read `## Detail` and `## Sources` sections when shallow sections are insufficient.

This progressive disclosure navigation minimizes context window consumption.

### Red Links

Red links (wikilinks to non-existent pages) are allowed and intentional. They signal knowledge gaps that the lint workflow tracks. Do not remove red links unless creating the target page or confirming the gap is irrelevant.

### What Agents Must NOT Do

- DO NOT create topic-based directories (e.g., `wiki/machine-learning/`). Use frontmatter `domains` field and Dataview queries instead.
- DO NOT put conventions or rules in any file other than AGENTS.md. This is the sole source of truth.
- DO NOT put wikilinks in YAML frontmatter. Use string IDs in frontmatter, wikilinks in body text.
- DO NOT use display aliases in wikilinks: write `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]`.
- DO NOT put provenance blobs, relation arrays, or decay settings in base frontmatter. Those belong in type-specific fields.
- DO NOT delete or move files when archiving. Set `status: archived` and remove from index active listings.
- DO NOT read the entire wiki when answering a query. Read index first, then TL;DR/Key Facts of relevant pages, then Detail only when needed.
- DO NOT create multiple commits for a single logical operation. One ingest = one commit, even if it touches 15 files.
- DO NOT send `local_only` content to cloud LLM APIs under any circumstances.
- DO NOT link to the same page more than once in a single page body. Link on first mention only.

## 4. Page Types and Templates

Five page types exist. Each has a defined purpose, section order, and frontmatter requirements.

### 4.1 Entity (`type: entity`)

**Purpose:** People, tools, organizations, specific named things.

**Section order:** TL;DR -> Key Facts -> Detail -> Related Pages -> Sources

**When to use:** The subject has a proper name and is a concrete thing (not an abstract idea).

**Worked example:**

```markdown
---
id: geoffrey-hinton
title: Geoffrey Hinton
type: entity
status: active
summary: "British-Canadian computer scientist, pioneer of deep learning and neural networks."
created_at: 2026-04-08
updated_at: 2026-04-08
sources:
  - src-2026-03-20-hinton-interview
epistemic_status: sourced
tags:
  - researcher
  - deep-learning
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Geoff Hinton
---

## TL;DR

Geoffrey Hinton is a pioneer of [[Deep Learning]] and co-inventor of [[Backpropagation]]. He shared the 2018 Turing Award with [[Yoshua Bengio]] and [[Yann LeCun]].

## Key Facts

- Co-invented backpropagation algorithm for training neural networks [prov:src-2026-03-20-hinton-interview#sec:early-work]
- Pioneered deep belief networks and restricted Boltzmann machines [prov:src-2026-03-20-hinton-interview#sec:contributions|direct]
- Left Google in 2023 citing concerns about AI safety [prov:src-2026-03-20-hinton-interview#sec:google-departure|direct|2026-04-08]

## Detail

Geoffrey Hinton spent decades working on neural networks when they were considered a dead end by much of the AI research community. His persistence led to breakthroughs in deep belief networks (2006) and later contributed to the deep learning revolution. His backpropagation work with David Rumelhart and Ronald Williams provided the foundational training algorithm still used today.

In 2023, Hinton resigned from Google to speak freely about AI safety risks, particularly the potential for AI systems to become more intelligent than humans. He has since been vocal about the need for regulation and safety research.

## Related Pages

- [[Deep Learning]]
- [[Backpropagation]]
- [[Neural Networks]]
- [[AI Safety]]

## Sources

- [[src-2026-03-20-hinton-interview]]: "Geoffrey Hinton Interview on AI Safety" (2026-03-20)
```

### 4.2 Concept (`type: concept`)

**Purpose:** Ideas, theories, frameworks, abstract topics.

**Section order:** TL;DR -> Key Facts -> Detail -> Related Pages -> Sources

**When to use:** The subject is an abstract idea, theory, methodology, or framework -- not a specific named entity.

**Worked example:**

```markdown
---
id: attention-mechanism
title: Attention Mechanism
type: concept
status: active
summary: "A neural network component that allows models to focus on relevant parts of the input sequence."
created_at: 2026-04-08
updated_at: 2026-04-08
sources:
  - src-2026-03-15-vaswani-attention
  - src-2026-04-01-bahdanau-alignment
epistemic_status: sourced
tags:
  - machine-learning
  - transformers
  - deep-learning
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Attention
  - Self-Attention
---

## TL;DR

Attention mechanisms allow neural networks to dynamically focus on relevant parts of the input when producing each part of the output. Introduced for sequence-to-sequence models by Bahdanau et al. and generalized as the core component of the [[Transformer Architecture]] by Vaswani et al.

## Key Facts

- Computes weighted sum of input representations, where weights reflect relevance to the current output [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]
- Self-attention relates different positions within a single sequence to compute a representation of that sequence [prov:src-2026-03-15-vaswani-attention#sec:self-attention|direct|2026-04-08]
- Multi-head attention runs multiple attention functions in parallel, enabling the model to attend to information from different representation subspaces [prov:src-2026-03-15-vaswani-attention#p5|direct|2026-04-08]
- Originally introduced for alignment in machine translation by Bahdanau et al. [prov:src-2026-04-01-bahdanau-alignment#sec:introduction|direct|2026-04-08]

## Detail

The attention mechanism was first proposed as a solution to the information bottleneck in encoder-decoder architectures. Traditional sequence-to-sequence models compress the entire input into a single fixed-length vector, which degrades performance on long sequences. Attention allows the decoder to look back at all encoder hidden states.

Vaswani et al. extended this idea to self-attention in the Transformer architecture, removing the need for recurrence entirely. The Transformer uses scaled dot-product attention: Q (queries), K (keys), and V (values) are linear projections of the input, and attention weights are computed as softmax(QK^T / sqrt(d_k)).

Multi-head attention applies this mechanism multiple times in parallel with different learned projections, then concatenates and linearly transforms the results. This allows the model to jointly attend to information from different positions and representation subspaces.

## Related Pages

- [[Transformer Architecture]]
- [[Deep Learning]]
- [[Machine Translation]]
- [[BERT]]

## Sources

- [[src-2026-03-15-vaswani-attention]]: Vaswani et al. "Attention Is All You Need" (2017)
- [[src-2026-04-01-bahdanau-alignment]]: Bahdanau et al. "Neural Machine Translation by Jointly Learning to Align and Translate" (2014)
```

### 4.3 Source Summary (`type: source`)

**Purpose:** One summary page per ingested source document. Links the raw source to the wiki.

**Section order:** TL;DR -> Key Takeaways -> Extracted Claims -> Notes -> Source Metadata

**When to use:** Every time a source is ingested, a source summary page is created in `wiki/sources/`.

**Additional frontmatter fields** (beyond the base set):

| Field | Type | Description |
|-------|------|-------------|
| `path` | string | Path to raw source file in `sources/` |
| `url` | string | Original URL if applicable |
| `content_hash` | string | SHA-256 hash for staleness detection |
| `ingested_at` | date | When the source was processed |
| `source_type` | enum | `article`, `paper`, `transcript`, `journal`, `data`, `image` |

**Worked example:**

```markdown
---
id: src-2026-03-15-vaswani-attention
title: "Vaswani et al. - Attention Is All You Need"
type: source
status: active
summary: "Seminal paper introducing the Transformer architecture based entirely on attention mechanisms."
created_at: 2026-04-08
updated_at: 2026-04-08
sources: []
epistemic_status: sourced
tags:
  - transformers
  - attention
  - deep-learning
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - Attention Is All You Need
path: sources/2026/2026-03/2026-03-15-vaswani-attention/source.md
url: "https://arxiv.org/abs/1706.03762"
content_hash: "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
ingested_at: 2026-04-08
source_type: paper
---

## TL;DR

Introduces the Transformer, a sequence-to-sequence architecture that replaces recurrence and convolutions entirely with self-attention. Achieves state-of-the-art results on machine translation benchmarks.

## Key Takeaways

- Attention alone (without recurrence or convolution) is sufficient for sequence transduction [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]
- The Transformer trains significantly faster than architectures based on recurrent or convolutional layers [prov:src-2026-03-15-vaswani-attention#sec:training|direct|2026-04-08]
- Multi-head attention is more beneficial than single-head attention with equivalent computational cost [prov:src-2026-03-15-vaswani-attention#sec:experiments|direct|2026-04-08]

## Extracted Claims

- "The Transformer achieves 28.4 BLEU on the WMT 2014 English-to-German translation task, improving over the existing best results by over 2 BLEU" [prov:src-2026-03-15-vaswani-attention#p8|direct|2026-04-08]
- "The Transformer achieves 41.8 BLEU on the WMT 2014 English-to-French translation task, outperforming all previously published single models" [prov:src-2026-03-15-vaswani-attention#p8|direct|2026-04-08]
- "Training took 3.5 days on 8 P100 GPUs for the base model" [prov:src-2026-03-15-vaswani-attention#sec:training|direct|2026-04-08]

## Notes

This paper is one of the most cited in machine learning history. The Transformer architecture became the foundation for [[BERT]], [[GPT]], and virtually all modern large language models. The "Attention Is All You Need" title has become iconic.

## Source Metadata

- **Source type:** paper
- **Authors:** Ashish Vaswani, Noam Shazeer, Niki Parmar, Jakob Uszkoreit, Llion Jones, Aidan N. Gomez, Lukasz Kaiser, Illia Polosukhin
- **Published:** 2017
- **Path:** `sources/2026/2026-03/2026-03-15-vaswani-attention/source.md`
- **URL:** https://arxiv.org/abs/1706.03762
```

### 4.4 Comparison (`type: comparison`)

**Purpose:** Contrasting sources, viewpoints, approaches, or technologies.

**Section order:** TL;DR -> Bottom Line -> Comparison Table -> Detailed Comparison -> Sources

**When to use:** When two or more subjects need structured side-by-side analysis.

**Worked example:**

```markdown
---
id: rnns-vs-transformers
title: "RNNs vs Transformers"
type: comparison
status: active
summary: "Comparison of recurrent neural networks and Transformer architectures for sequence modeling."
created_at: 2026-04-08
updated_at: 2026-04-08
sources:
  - src-2026-03-15-vaswani-attention
  - src-2026-04-02-lstm-survey
epistemic_status: sourced
tags:
  - architecture-comparison
  - deep-learning
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
---

## TL;DR

Transformers have largely replaced RNNs for most sequence tasks due to superior parallelization and performance at scale. RNNs remain relevant for low-resource settings and tasks requiring strict sequential processing.

## Bottom Line

Use Transformers for most sequence tasks, especially when data and compute are abundant. Consider RNNs only when hardware constraints are severe or the task genuinely requires online sequential processing.

## Comparison Table

| Dimension | RNNs (LSTM/GRU) | Transformers |
|-----------|------------------|--------------|
| **Parallelization** | Sequential (hard to parallelize) | Fully parallel |
| **Long-range dependencies** | Struggles with very long sequences | Handles well via self-attention |
| **Training speed** | Slow (sequential bottleneck) | Fast (parallel computation) |
| **Memory footprint** | Linear in sequence length | Quadratic in sequence length (attention matrix) |
| **Performance at scale** | Plateaus earlier | Scales with data and parameters |
| **Best for** | Low-resource, streaming, online tasks | Most NLP, vision, and multimodal tasks |

## Detailed Comparison

**Architecture:** RNNs process sequences one element at a time, maintaining a hidden state that carries information forward. This sequential nature makes them inherently difficult to parallelize. Transformers process all positions simultaneously using self-attention, with positional encodings providing sequence order information [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08].

**Scaling:** The Transformer architecture has proven remarkably scalable. Models like GPT and BERT demonstrate that increasing parameters and training data yields consistent improvements. RNNs show diminishing returns at scale, partly due to the information bottleneck of the hidden state.

**Memory:** Standard self-attention has O(n^2) memory complexity in sequence length, which can be prohibitive for very long sequences. Various efficient attention variants (linear attention, sparse attention) address this. RNNs have O(n) memory complexity but carry the sequential processing cost.

## Sources

- [[src-2026-03-15-vaswani-attention]]: Vaswani et al. "Attention Is All You Need" (2017)
- [[src-2026-04-02-lstm-survey]]: "A Survey of LSTM and GRU Architectures" (2026-04-02)
```

### 4.5 Overview (`type: overview`)

**Purpose:** High-level topic summaries that synthesize across multiple sources and pages.

**Section order:** TL;DR -> Key Facts -> Detail -> Related Pages -> Sources

**When to use:** When a broad topic needs a synthesis page that ties together multiple entities, concepts, and sources.

**Worked example:**

```markdown
---
id: deep-learning
title: Deep Learning
type: overview
status: active
summary: "High-level overview of deep learning: history, key architectures, and current state."
created_at: 2026-04-08
updated_at: 2026-04-08
sources:
  - src-2026-03-15-vaswani-attention
  - src-2026-03-20-hinton-interview
  - src-2026-04-02-lstm-survey
epistemic_status: sourced
tags:
  - machine-learning
  - neural-networks
domains:
  - ai-research
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - DL
---

## TL;DR

Deep learning is a subset of machine learning using neural networks with multiple layers. It has driven breakthroughs in vision, language, and generative AI since 2012. Key architectures include CNNs, RNNs/LSTMs, and [[Transformer Architecture|Transformers]].

## Key Facts

- Deep learning became practically viable after GPU training and large datasets became available (circa 2012) [prov:src-2026-03-20-hinton-interview#sec:early-work|direct|2026-04-08]
- The Transformer architecture (2017) replaced recurrence with self-attention and became the foundation for modern LLMs [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]
- [[Geoffrey Hinton]], [[Yoshua Bengio]], and [[Yann LeCun]] received the 2018 Turing Award for their foundational work [prov:src-2026-03-20-hinton-interview#sec:contributions|direct|2026-04-08]
- RNNs/LSTMs dominated sequence tasks before Transformers but are now largely superseded [prov:src-2026-04-02-lstm-survey#sec:conclusion|direct|2026-04-08]

## Detail

Deep learning emerged from decades of work on artificial neural networks. The field experienced several "AI winters" where interest and funding waned, but researchers like Geoffrey Hinton persisted. The combination of large datasets (ImageNet), powerful GPUs, and algorithmic improvements (dropout, batch normalization, residual connections) led to the modern deep learning era.

Key milestones include AlexNet's ImageNet victory (2012), the introduction of GANs (2014), the Transformer architecture (2017), BERT (2018), and GPT-3 (2020). Each built on previous work and expanded the range of tasks deep learning could handle.

Current challenges include interpretability, energy consumption, safety alignment, and the concentration of compute resources. The field continues to evolve rapidly, with new architectures and training paradigms emerging regularly.

## Related Pages

- [[Transformer Architecture]]
- [[Geoffrey Hinton]]
- [[Attention Mechanism]]
- [[Neural Networks]]
- [[AI Safety]]

## Sources

- [[src-2026-03-15-vaswani-attention]]: Vaswani et al. "Attention Is All You Need" (2017)
- [[src-2026-03-20-hinton-interview]]: "Geoffrey Hinton Interview on AI Safety" (2026-03-20)
- [[src-2026-04-02-lstm-survey]]: "A Survey of LSTM and GRU Architectures" (2026-04-02)
```

## 5. Frontmatter Schema

### Base Fields (Required on Every Wiki Page)

```yaml
---
id: slug-style-identifier          # Unique page ID, kebab-case
title: "Human Readable Title"      # Canonical page title
type: entity|concept|source|comparison|overview
status: active|stale|superseded|archived
summary: "One-sentence description for index scanning."
created_at: YYYY-MM-DD            # ISO 8601
updated_at: YYYY-MM-DD            # ISO 8601
sources:                           # List of source IDs (strings, NOT wikilinks)
  - src-YYYY-MM-DD-slug
epistemic_status: sourced|mixed|tentative|stale
tags:                              # Flat list for Dataview queries
  - tag-name
domains:                           # Topic/category classification
  - domain-name
supersedes:                        # ID of page this replaces (if any)
superseded_by:                     # ID of page that replaces this (if any)
privacy: local_only|cloud_safe     # Privacy routing tier
aliases:                           # Alternative names for Obsidian resolution
  - Alternate Name
---
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier in kebab-case. Used in `sources` lists and `[prov:]` markers. Must match the filename (without `.md`). |
| `title` | string | Human-readable canonical title. Wikilinks resolve to this value. |
| `type` | enum | Page type: `entity`, `concept`, `source`, `comparison`, `overview`. Determines section structure. |
| `status` | enum | Lifecycle state: `active` (current), `stale` (may be outdated), `superseded` (replaced by another page), `archived` (no longer relevant). |
| `summary` | string | One sentence. Used for index scanning and Dataview table previews. Must be a single quoted string, not multi-line. |
| `created_at` | date | ISO 8601 date when the page was first created. |
| `updated_at` | date | ISO 8601 date when the page was last modified. |
| `sources` | list | YAML list of source IDs (strings). References raw sources this page draws from. NOT wikilinks. |
| `epistemic_status` | enum | Evidence quality: `sourced` (directly from source), `mixed` (some sourced + some inferred), `tentative` (weak evidence), `stale` (likely outdated). |
| `tags` | list | YAML list of lowercase kebab-case strings. Used for Dataview queries and filtering. |
| `domains` | list | YAML list of topic/category classifications in kebab-case. Used for cross-domain Dataview queries. |
| `supersedes` | string | ID of the page this one replaces. Null if not applicable. |
| `superseded_by` | string | ID of the page that replaces this one. Null if not applicable. |
| `privacy` | enum | `local_only` (never send to cloud APIs) or `cloud_safe` (can be sent to cloud APIs). |
| `aliases` | list | Alternative names for Obsidian automatic resolution. Obsidian resolves `[[Alias]]` to the canonical page. |

### Source Summary Additional Fields

Source summary pages (`type: source`) include these additional frontmatter fields:

```yaml
path: sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/source.md
url: "https://..."                  # Original URL if applicable
content_hash: "sha256:abc123..."    # SHA-256 hash for staleness detection
ingested_at: YYYY-MM-DD            # When source was processed
source_type: article|paper|transcript|journal|data|image

# Compilation tracking
compilation_status: pending         # pending | partial | compiled | stale
compiled_against_hash: ""           # SHA-256 of source content at last compilation
compiled_targets: []                # Wiki page IDs that received compiled claims
```

### Compilation Tracking Fields (Source Summary Pages)

Source summary pages carry three additional fields that track whether their extracted claims have been compiled into topic pages. These fields enable delta compilation (compiling only new or changed sources) and stale-source detection.

| Field | Type | Description |
|-------|------|-------------|
| `compilation_status` | enum | Compilation lifecycle: `pending` (new, uncompiled), `partial` (some claims merged), `compiled` (all claims merged into topic pages), `stale` (source content changed since last compilation) |
| `compiled_against_hash` | string | SHA-256 hash of source content at time of last compilation. Copied from `content_hash` when compilation completes. When `content_hash` changes on re-ingest and no longer matches `compiled_against_hash`, status resets to `stale`. |
| `compiled_targets` | list | YAML list of wiki page IDs (the `id` field value, not file paths) that received claims from this source during compilation. Example: `[prospect-theory, loss-aversion, daniel-kahneman]` |

#### Compilation Status Transition Rules

The following transitions are the ONLY valid state changes. Any other transition is a bug.

| From | To | Trigger | Who Sets It |
|------|----|---------|-------------|
| (new source) | `pending` | Source ingested, before merge pass | Ingest workflow step 5 (extract) |
| `pending` | `compiled` | All extracted claims merged into topic pages | Ingest workflow step 6a |
| `pending` | `partial` | Some claims merged, others deferred | Ingest workflow step 6a |
| `partial` | `compiled` | Remaining claims compiled (via query delta or manual) | Query workflow step 6 or follow-up ingest |
| `compiled` | `stale` | `content_hash` changed on re-ingest (no longer matches `compiled_against_hash`) | Ingest workflow on re-ingest detection |
| `stale` | `compiled` | Re-compilation completed against new content | Query workflow step 6 or follow-up ingest |
| `stale` | `partial` | Partial re-compilation completed | Query workflow step 6 |

**Invariants:**
- `compiled_against_hash` is ALWAYS equal to `content_hash` when `compilation_status` is `compiled`.
- `compiled_against_hash` differs from `content_hash` when `compilation_status` is `stale`.
- `compiled_targets` is empty ONLY when `compilation_status` is `pending`.
- Pages missing `compilation_status` (pre-Phase-4 legacy) are treated as `compiled` by tooling.

### Frontmatter Validation Checklist

When creating or updating any wiki page, verify:

1. All base fields are present (id, title, type, status, summary, created_at, updated_at, sources, epistemic_status, tags, domains, supersedes, superseded_by, privacy, aliases)
2. `type` is one of: `entity`, `concept`, `source`, `comparison`, `overview`
3. `status` is one of: `active`, `stale`, `superseded`, `archived`
4. `epistemic_status` is one of: `sourced`, `mixed`, `tentative`, `stale`
5. `privacy` is one of: `local_only`, `cloud_safe`
6. `created_at` and `updated_at` match ISO 8601 pattern `YYYY-MM-DD`
7. `sources` is a YAML list of string IDs, NOT wikilinks
8. `tags` and `domains` are YAML lists of lowercase kebab-case strings
9. `summary` is a single quoted string, not multi-line
10. `id` matches the filename (without `.md` extension)
11. For `type: source` pages: `path`, `content_hash`, `ingested_at`, and `source_type` are present
12. For `type: source` pages: `compilation_status` is one of: `pending`, `partial`, `compiled`, `stale`

## 6. Provenance, Epistemics, and Staleness

### Inline Provenance Syntax

Every factual claim in wiki pages SHOULD have an inline provenance marker linking it to a specific location in a source.

**Basic form:**

```
[prov:<source_id>#<locator>]
```

**Extended form (with support type and verification date):**

```
[prov:<source_id>#<locator>|<support_type>|<checked_at>]
```

### Locator Types

| Locator | Format | Example | Use for |
|---------|--------|---------|---------|
| Page range | `#p<start>-<end>` or `#p<page>` | `#p12-14`, `#p8` | PDFs, papers |
| Section | `#sec:<name>` | `#sec:introduction` | Markdown sections |
| Paragraph | `#para<number>` | `#para3` | Specific paragraphs |
| Timestamp | `#t<start>-<end>` | `#t00:12:10-00:12:48` | Audio/video transcripts |
| Image | `#img<number>` | `#img2` | Figures, diagrams |

### Support Types

| Type | Meaning |
|------|---------|
| `direct` | Claim is directly stated in the source |
| `inferred` | Claim is logically inferred from source content |
| `tentative` | Weak evidence; claim may not hold |
| `derived` | Synthesized from multiple parts of the source or across sources |

### Checked At

The `checked_at` field records the ISO 8601 date when the provenance link was last verified against the source. This enables staleness detection: if the source's `content_hash` has changed since `checked_at`, the claim should be reviewed.

### Examples in Context

```markdown
- Attention mechanisms allow models to focus on relevant input tokens [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]
- The model achieves 28.4 BLEU on WMT 2014 English-to-German [prov:src-2026-03-15-vaswani-attention#p8|direct|2026-04-08]
- Hinton expressed concerns about AI safety risks [prov:src-2026-03-20-hinton-interview#t00:12:10-00:12:48|direct|2026-04-08]
- The learning rate schedule uses warmup followed by inverse square root decay [prov:src-2026-03-15-vaswani-attention#sec:training|direct|2026-04-08]
- RNNs struggle with long-range dependencies due to vanishing gradients [prov:src-2026-04-02-lstm-survey#sec:limitations|direct|2026-04-08]
```

### Bad vs. Good Provenance Examples

```
BAD:  Attention is important.
GOOD: Attention mechanisms allow models to focus on relevant input tokens [prov:src-2026-03-15-vaswani-attention#sec:introduction|direct|2026-04-08]

BAD:  [prov:vaswani] (missing locator, wrong source ID format)
GOOD: [prov:src-2026-03-15-vaswani-attention#sec:introduction]

BAD:  [prov:src-2026-03-15-vaswani-attention#page8] (invalid locator format)
GOOD: [prov:src-2026-03-15-vaswani-attention#p8] (correct: #p prefix for pages)

BAD:  [prov:src-2026-03-15-vaswani-attention] (no locator at all)
GOOD: [prov:src-2026-03-15-vaswani-attention#sec:abstract] (always include a locator)
```

### Source Registry

Each source summary page in `wiki/sources/` serves as the registry entry for that source. Its frontmatter contains: `id` (the source_id), `path`, `title`, `source_type`, `url`, `content_hash`, `ingested_at`.

This is the Dataview-native approach -- query source metadata with:

```dataview
TABLE source_type, ingested_at, content_hash
FROM "wiki/sources"
WHERE status = "active"
SORT ingested_at DESC
```

No separate registry file is needed. Source summary pages ARE the registry.

### Provenance Validation Rules

1. Every `[prov:...]` reference MUST resolve to a known source ID in `wiki/sources/`.
2. Every locator MUST be syntactically valid (matches one of the defined patterns above).
3. If a source's `content_hash` has changed since `checked_at`, dependent claims SHOULD be reviewed and the page's `epistemic_status` SHOULD be set to `stale`.
4. The lint workflow checks these rules automatically.

### Inline Epistemic Markers

Per-claim epistemic status uses Dataview inline field syntax, separate from provenance markers.

**Syntax:** `[epistemic:: <status>]`

**Valid statuses:**

| Status | Meaning | When to use |
|--------|---------|-------------|
| `sourced` | Directly from a source | Verbatim or close paraphrase with provenance |
| `inferred` | Synthesized from source(s) | Logical conclusion not explicitly stated in any single source |
| `tentative` | Weak or contested evidence | Claim may not hold; flag for review |
| `stale` | Likely outdated | Source has changed, finding superseded, or claim is time-sensitive |

Queryable via Dataview:

```dataview
TABLE file.name
FROM "wiki"
FLATTEN file.lists.text as item
WHERE contains(item, "[epistemic:: tentative]")
```

### Page-Level vs Claim-Level Epistemic Status

- **Page-level:** `epistemic_status` frontmatter field (Section 5). Reflects overall page evidence quality: `sourced`, `mixed`, `tentative`, or `stale`.
- **Claim-level:** Inline `[epistemic:: <status>]` in body text. Applies to individual claims within a page.

A page with `epistemic_status: sourced` may contain individual `[epistemic:: inferred]` claims if the majority is directly sourced. Use `mixed` when the page has a significant proportion of non-sourced claims.

### Mixed Inline Grammar

Two inline syntaxes coexist intentionally in wiki page bodies. Do NOT normalize to a single syntax.

| Syntax | Purpose | Tool |
|--------|---------|------|
| `[prov:source_id#locator\|support_type]` | Traceability | grep, scripts |
| `[epistemic:: status]` | Confidence discovery | Dataview |

**Combined pattern:** `Claim text. [prov:source_id#locator|support_type] [epistemic:: status]`

Not every claim needs both markers. Provenance is omitted when there is no specific source. Epistemic status is recommended on all factual claims.

## 7. Progressive Disclosure

**Principle:** All wiki pages are structured shallow-to-deep. The top of every page is optimized for fast LLM scanning; the bottom is for human verification and deep reading.

### Rules for LLM Agents

1. When searching for information, read `wiki/index.md` FIRST.
2. Scan `## TL;DR` and `## Key Facts` sections of relevant pages BEFORE reading `## Detail` sections.
3. Only read `## Detail` and `## Sources` sections when shallow sections are insufficient to answer the question.
4. When creating pages, `## TL;DR` MUST be 1 short paragraph or 2-4 bullets.
5. `## Key Facts` MUST be compact bullets with inline provenance markers.
6. `## Detail` contains full narrative, synthesis, caveats, and nuance.
7. `## Sources` at the bottom lists human-readable source references with wikilinks to source summary pages.

### Per-Type Section Ordering

| Page Type | Section Order |
|-----------|--------------|
| Entity | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Concept | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |
| Source Summary | TL;DR -> Key Takeaways -> Extracted Claims -> Notes -> Source Metadata |
| Comparison | TL;DR -> Bottom Line -> Comparison Table -> Detailed Comparison -> Sources |
| Overview | TL;DR -> Key Facts -> Detail -> Related Pages -> Sources |

See Section 4 for fully worked examples of each type.

### Why This Matters

An LLM processing a query about "attention mechanisms" should be able to:
1. Read `wiki/index.md` to find `wiki/concepts/attention-mechanism.md` (seconds)
2. Read its `## TL;DR` to confirm relevance (seconds)
3. Read `## Key Facts` for specific claims with provenance (seconds)
4. Only read `## Detail` if the above is insufficient (more expensive)

This structure means the LLM reads the minimum necessary context for each query, preserving context window for synthesis and reasoning.

## 8. Wikilink and Graph Conventions

### Rules

1. Use `[[Exact Page Title]]` for all cross-references in page body text.
2. Link on FIRST mention only per page. Subsequent mentions are plain text.
3. DO NOT use display aliases: write `[[Attention Mechanism]]` not `[[Attention Mechanism|attention]]`.
4. Use the `aliases` frontmatter field for alternate names. Obsidian resolves aliases to the canonical page automatically.
5. Red links (links to non-existent pages) are ALLOWED and intentional. They signal knowledge gaps for the lint workflow.
6. DO NOT put wikilinks in YAML frontmatter. Use string IDs in frontmatter, wikilinks in body text.
7. The `## Related Pages` section lists explicit wikilinks to connected pages.
8. The `## Sources` section in page body lists human-readable source references with wikilinks to source summary pages.

### Bad vs. Good Wikilink Examples

```
BAD:  sources: ["[[Vaswani et al]]"]           (wikilink in frontmatter)
GOOD: sources: [src-2026-03-15-vaswani-attention]  (string ID in frontmatter)

BAD:  [[Attention Mechanism|attention]]         (display alias -- breaks graph clarity)
GOOD: [[Attention Mechanism]]                   (exact title match)

BAD:  ...the [[Attention Mechanism]] uses [[Attention Mechanism]] weights...  (linked twice)
GOOD: ...the [[Attention Mechanism]] uses attention weights...  (linked once, plain text after)

BAD:  See [[attention]]                         (lowercase, non-canonical title)
GOOD: See [[Attention Mechanism]]               (exact canonical title from page frontmatter)
```

### Graph View Implications

- Only wikilinks in page body text appear reliably in Obsidian's graph view.
- String IDs in frontmatter do NOT create graph edges. This is intentional -- frontmatter holds structured data; body text holds navigable links.
- First-mention linking prevents link noise in the graph. A page that mentions "attention" 20 times creates only one graph edge to `[[Attention Mechanism]]`, not 20.
- Red links appear in the graph as unresolved nodes, providing a visual map of knowledge gaps.

## 9. Structured Operations and Executor Model

All wiki mutations use a formal operations vocabulary. Raw file rewrites are prohibited -- every change goes through one of these four operations with mandatory logging.

### Operations Vocabulary

| Operation    | Verb    | What It Does                                       |
|-------------|---------|---------------------------------------------------|
| **UPDATE**  | Modify  | Add new information to an existing page            |
| **MERGE**   | Combine | Unify two pages covering the same concept          |
| **SUPERSEDE** | Replace | Mark a page/claim as replaced by newer information |
| **ARCHIVE** | Retire  | Move outdated content out of active wiki           |

### Operation Definitions

**UPDATE** -- Modify an existing page with new information.

1. Add new claims with provenance markers to the appropriate section of the existing page.
2. Preserve all existing provenance markers -- do not remove or overwrite them.
3. Add new source IDs to the `sources` list in frontmatter.
4. Update `updated_at` in frontmatter to today's date.
5. If new claims change the evidence balance, update `epistemic_status` accordingly.
6. Log: `"UPDATE <page_id>: <one-line rationale>"`

For the full incremental update policy governing how new claims integrate with existing content during ingestion, see Section 10 Pass 3 (Append-Then-Synthesize).

**MERGE** -- Combine two pages covering the same concept.

1. Create a new merged page with the union of claims from both pages, preserving all provenance markers.
2. Set `supersedes` on the new page to list both merged page IDs.
3. Set `superseded_by` on both old pages to point to the new page ID.
4. Set `status: superseded` on both old pages.
5. Replace the body of both old pages with a brief redirect note: `> This page has been merged into [[New Page Title]].`
6. Update `wiki/index.md`: add the new page, move old pages to "Archived" section (if one exists) or remove them from active listings.
7. Log: `"MERGE <page_a> + <page_b> -> <new_page>: <rationale>"`

**SUPERSEDE** -- Mark a page or claim as replaced by newer information.

1. Set `superseded_by` on the old page to the replacing page's ID.
2. Set `status: superseded` on the old page.
3. Add a note at the top of the old page body: `> This page has been superseded by [[New Page Title]].`
4. On the new page, set `supersedes` to the old page's ID.
5. Update `wiki/index.md`: move the old page to "Archived" section or remove from active listings.
6. Log: `"SUPERSEDE <old_page> -> <new_page>: <rationale>"`

**ARCHIVE** -- Move outdated content out of active wiki.

1. Set `status: archived` on the page.
2. Remove the page from `wiki/index.md` active listings (move to an "Archived" section if one exists).
3. The page remains in its directory -- do NOT delete or move files.
4. Log: `"ARCHIVE <page_id>: <rationale>"`

### Executor Model

The LLM proposes operations. Before applying any operation, it MUST validate:

1. **Target exists:** For UPDATE, SUPERSEDE, and ARCHIVE, the target page must exist.
2. **Both pages exist and are distinct:** For MERGE, both source pages must exist and must not be the same page.
3. **Provenance resolves:** All `[prov:...]` references in new content must resolve to known source IDs in `wiki/sources/`.
4. **Frontmatter is valid:** All required base fields are present and correctly typed (see Section 5 validation checklist).
5. **Privacy is respected:** No `local_only` content is included in operations that will be sent to cloud APIs.

If validation fails, the LLM MUST NOT apply the operation. Instead, log the validation failure and report it to the user.

Every operation MUST be logged in `wiki/log.md` with: timestamp, operation type, affected page(s), and rationale. See Section 12 for log format.

## 10. Compiler Pipeline (Conceptual Model)

This section describes the conceptual compilation model -- the state machine that source material passes through on its way into the wiki. Section 11 (Workflows) provides the step-by-step operator procedures that implement this model.

The pipeline is a multi-pass process for ingesting a source document:

```
Source -> [Classify] -> [Diff] -> [Extract] -> [Merge] -> [Lint] -> Wiki
```

### Pass 0: Classify

Determine the source type before processing.

- **Input:** Raw source document.
- **Types:** article, paper, book-chapter, transcript, journal entry, data file, image-heavy.
- **Note:** `book-chapter` is the canonical source type for book content. Full books MUST be ingested as a sequence of `book-chapter` sources (one per chapter or coherent section). An older source summary (src-2026-04-09-thinking-fast-and-slow-part1) previously used `source_type: book`; that value is being normalized to `book-chapter` in this plan. Agents MUST use `book-chapter` going forward; `book` is no longer accepted.
- **Purpose:** Different source types require different extraction logic (e.g., papers have abstract/methodology/results; transcripts have timestamped segments).
- **Output:** Source type classification, passed to Pass 2 for type-appropriate extraction.

### Pass 1: Diff

Compare the new source against current wiki state.

- **Input:** Source document + current wiki state (via `wiki/index.md`).
- **Process:** Read `wiki/index.md` to identify existing pages on related topics. Read the TL;DR and Key Facts of those related pages. Determine what the new source adds that the wiki does not already cover.
- **Output:** A mental model of new vs. existing knowledge. This is not a file -- it is the LLM's internal understanding of the delta.

### Pass 2: Extract

Pull structured knowledge from the source.

- **Input:** Source document + type classification from Pass 0.
- **Process:** Apply type-appropriate extraction. Papers get abstract, methodology, results, and conclusions. Transcripts get timestamped claims. Journal entries get reflections and decisions. Extract claims, entities, and relationships, each with a provenance locator (`[prov:source_id#locator]`).
- **Output:** A source summary page created in `wiki/sources/<source_id>.md` with full frontmatter (including `path`, `content_hash`, `ingested_at`, `source_type`) and all extracted claims with provenance.

#### Claim Granularity Rules

Source classification (Pass 0) drives extraction depth. The guiding heuristic: **"the smallest unit that preserves meaningful provenance without making the page unreadable."**

| Source Type | Default Granularity | Guidance |
|-------------|-------------------|----------|
| article, paper, report, technical doc | Atomic claims | One provenance marker per distinct assertion. Split when a paragraph contains multiple independently important assertions. |
| book-chapter, essay | Atomic for factual/conceptual claims; paragraph-level for broader interpretive passages | Important factual claims get individual provenance. Interpretive or argumentative passages that form a single coherent point stay grouped. |
| transcript, meeting notes, journal entry | Paragraph-level or utterance-level clusters | Group by natural conversation turns or reflection units. Individual sentences rarely stand alone as claims. |
| image-heavy, mixed media | Tied to specific image, caption, or observation | Each image or visual element that contributes a distinct claim gets its own provenance marker referencing the image locator. |

**Bias toward atomic:** Across all source types, prefer atomic granularity for durable factual and conceptual claims. The split/group decision:
- **Split** when a paragraph contains multiple independently important assertions that future readers might cite separately.
- **Keep grouped** when a passage is only useful as one bundled observation and splitting would lose context.

### Pass 3: Merge

Integrate extracted knowledge into the wiki.

- **Input:** Extracted claims + current wiki pages.
- **Process:**
  - UPDATE existing pages with new claims (using the UPDATE operation from Section 9).
  - Create new pages for entities or concepts not yet in the wiki, using the appropriate page type template (Section 4).
  - Generate wikilinks between related pages (first mention only, per Section 8).
  - MERGE pages if the new source reveals that two existing pages cover the same topic (using the MERGE operation from Section 9).
- **Output:** Updated and/or new wiki pages with provenance-tracked claims and cross-references.

#### Incremental Update Policy: Append-Then-Synthesize

The default policy for living wiki pages (entities, concepts, overviews, comparisons):

1. **Append in the detail layer:** Add new claims into the appropriate detail sections, preserving all existing material. Never silently delete existing claims. Insert new claims at the end of the relevant section with their provenance markers.
2. **Mark superseded or stale claims per current schema conventions:** When new information contradicts or replaces an existing claim, mark the old claim as superseded or stale using the epistemic and provenance syntax currently documented in the schema (see Section 6), and add a short note pointing to the superseding claim. Never remove the old claim -- the provenance trail must remain visible. Phase 5 will formalize the exact contradiction and staleness semantics; until then, follow current schema conventions and keep the old claim visible.
3. **Re-synthesize the summary layer:** After appending new detail, rewrite the TL;DR and Key Facts sections so they reflect the complete current state of the page -- all claims, old and new. This is the only place where rewriting is expected on every update.
4. **Record framing shifts:** If new material fundamentally changes a page's framing or interpretation, record the shift in a decision/reflection entry (see Section 11.4) rather than hiding it inside prose edits.

**Exceptions:**
- **Logs and source summary pages:** Strict append-only. These are records, not living synthesis. Never rewrite existing log entries or source summary content.
- **Full section rewrite:** Reserved for exceptional cases only -- severe page drift, extensive duplication, or fundamentally broken earlier structure. When performed, log the rationale as a decision record.

**Mantra:** "Append in the detail layer, synthesize in the summary layer, supersede explicitly when needed."

### Pass 4: Lint

Verify consistency after merge.

- **Input:** All pages modified or created during this ingest.
- **Checks:**
  - All new `[prov:...]` markers resolve to valid source IDs in `wiki/sources/`.
  - All new wikilinks point to existing pages or are intentional red links.
  - Frontmatter is complete and valid on all modified pages (Section 5 checklist).
  - No contradictions between new claims and existing claims on the same topic.
- **Output:** List of issues found (if any). Trivially fixable issues (e.g., missing frontmatter fields) are fixed inline. Non-trivial issues are reported.

### Optional Follow-On Passes

These are not required on every ingest:

- **Summary regeneration:** Rewrite TL;DR and Key Facts sections of affected pages to reflect new information.
- **Image processing:** Extract information from figures, diagrams, or images in the source.
- **Structural reorganization:** Split pages that have grown too large, or reorganize domain sections.

## 11. Workflows

These are the operator procedures that implement the conceptual pipeline (Section 10). Each workflow is a complete recipe an LLM agent follows step-by-step. The pipeline describes WHAT conceptually happens; workflows describe HOW to do it.

### 11.1 Ingest Workflow

```
Trigger:  User places a new source document and requests ingestion
Inputs:   Source file at sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/ (bundle) or .md (single file)
Outputs:  Source summary page, updated wiki pages, updated index, updated log
Commit:   ingest(<source-slug>): <one-line summary>
```

**Steps:**

1. User places source document in `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` (bundle with `source.md` + assets) or `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug.md` (single file).
2. LLM reads the source document completely.
3. **Classify** (Pipeline Pass 0): Determine source type -- article, paper, transcript, journal entry, data file, or image-heavy.
4. **Diff** (Pipeline Pass 1): Read `wiki/index.md`, identify related existing pages, read their TL;DR and Key Facts sections. Determine what this source adds that the wiki does not already cover.
5. **Extract** (Pipeline Pass 2): Extract claims with provenance locators, applying the claim granularity rules from Section 10 Pass 2 based on the source type classified in step 3. Create source summary page at `wiki/sources/<source_id>.md` with full frontmatter including `path`, `content_hash`, `ingested_at`, and `source_type`.
6. **Merge** (Pipeline Pass 3): Update or create entity/concept/overview pages using UPDATE operations (Section 9) and the append-then-synthesize policy (Section 10 Pass 3). Generate wikilinks on first mention. MERGE pages if the source reveals duplicates.
   - 6a. After merge is complete, update the source summary page's compilation tracking fields:
     - Set `compilation_status` to `compiled` if all extracted claims were merged into topic pages, or `partial` if some claims were deferred.
     - Set `compiled_against_hash` to the current `content_hash` value.
     - Set `compiled_targets` to the list of wiki page IDs that received claims from this source (page IDs only, not paths).
7. **Lint** (Pipeline Pass 4): Verify all provenance references resolve, wikilinks are valid, frontmatter is complete on all modified pages.
8. Update `wiki/index.md` with new and modified pages.
9. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <source title>` with affected pages and rationale.
10. Commit: `ingest(<source-slug>): <one-line summary>`

**Abort conditions:**

- Source is unreadable or corrupted. Log failure in `wiki/log.md`, do NOT create partial wiki pages.
- Source duplicates an already-ingested source (check `content_hash` against existing source summary pages). Log the duplicate detection, do NOT re-ingest.
- Privacy classification cannot be determined. Default to `local_only` and log the classification gap.

### 11.2 Query Workflow

```
Trigger:  User asks a question about the wiki contents
Inputs:   User question (natural language)
Outputs:  Answer with citations, optionally new/updated wiki pages, updated index/log
Commit:   query(<topic>): <one-line summary>
```

**Steps:**

1. Read `wiki/index.md` to find pages relevant to the question.
2. Read TL;DR and Key Facts sections of relevant pages (progressive disclosure -- shallow first).
3. Read Detail sections only where shallow content is insufficient to answer the question.
4. Synthesize answer with citations to specific wiki pages and inline provenance markers.
5. **Mandatory write-back:** If the answer produces useful synthesis that does not already exist in the wiki, write it back as a new or updated wiki page. This is not optional -- queries that produce novel synthesis MUST contribute back to the wiki.
6. **Delta compilation check:** Are there sources in `wiki/sources/` relevant to this query whose knowledge has not been fully compiled into topic pages? If yes, compile the missing synthesis into appropriate wiki pages.
7. Update `wiki/index.md` if new pages were created.
8. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] query | <question summary>` with affected pages.
9. Commit (only if wiki was modified): `query(<topic>): <one-line summary>`

**Abort conditions:**

- No relevant pages exist AND no sources exist on the topic. Inform the user that the wiki has no information on this topic rather than hallucinating an answer. Log the knowledge gap in `wiki/log.md` so the lint workflow can track it.

### 11.3 Lint Workflow

```
Trigger:  User requests a health check, or periodically after several ingests
Inputs:   wiki/ directory (all pages)
Outputs:  Structured findings report, optionally fixed pages, updated log
Commit:   lint(<scope>): <one-line summary>
```

**Steps:**

1. Read `wiki/index.md` for full page inventory.
2. **Orphan detection:** Find pages with no inbound wikilinks from other wiki pages.
3. **Missing cross-references:** Identify related pages that should link to each other but do not.
4. **Stale claims:** Find claims with `checked_at` dates older than a reasonable threshold, or pages with `epistemic_status: stale`.
5. **Contradiction detection:** Identify claims on the same topic that disagree across different pages.
6. **Knowledge gaps:** Collect red links (unresolved wikilinks) that appear across multiple pages, suggesting a new page should be created.
7. **Source coverage gaps:** Identify domains with few sources relative to others.
8. Report findings in structured format, organized by category (orphans, stale claims, contradictions, gaps).
9. Suggest new questions to investigate and new sources to look for based on gaps found.
10. Fix trivially fixable issues: add missing cross-references, update stale `epistemic_status` markers, fix broken provenance references where the correct source is obvious.
11. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] lint | <scope>` with summary of findings and fixes.
12. Commit: `lint(<scope>): <one-line summary of findings and fixes>`

**Abort conditions:**

- Wiki is empty (no pages beyond `index.md` and `log.md`). Report that the wiki is empty and skip the lint. Log this in `wiki/log.md`.

### 11.4 Reflect Workflow

```
Trigger:  After major ingests, reorganizations, or periodic review
Inputs:   Recent changes (from log.md or git history)
Outputs:  Decision record page, updated index/log
Commit:   reflect(<scope>): <one-line summary>
```

**Steps:**

1. Identify what structural change was made: page merges, topic reorganization, schema updates, domain restructuring, or significant reframing.
2. Create a decision record page in `wiki/overviews/` with `type: overview` and the following sections: TL;DR -> Decision -> Why -> Alternatives Considered -> Consequences -> Sources.
3. The decision page documents: what framing was adopted, what it replaced, what alternatives were considered, and why the chosen approach was selected.
4. Update `wiki/index.md` with the new decision page.
5. Append entry to `wiki/log.md`: `## [YYYY-MM-DD] reflect | <scope>` with the decision summary.
6. Commit: `reflect(<scope>): <one-line summary>`

**Abort conditions:**

- No structural changes have been made since the last reflection. Skip and do not create an empty decision record.

## 12. Index and Log

### index.md (Content Index)

- Lives at `wiki/index.md`.
- Organized by page type: Entities, Concepts, Sources, Comparisons, Overviews.
- Each entry follows the format: `- [[Page Title]] -- <one-line summary> (<epistemic_status>, <updated_at>)`
- Updated on every ingest and every query that creates or modifies pages.
- The LLM reads this FIRST when searching for information (per Section 3 and Section 7).
- Archived pages are listed separately under an "Archived" heading if any exist.
- The index is the primary navigation mechanism for both LLMs and humans browsing the wiki.

### log.md (Activity Log)

- Lives at `wiki/log.md`.
- Chronological, newest entries at the bottom (append-only).
- Entry format:

```markdown
## [YYYY-MM-DD] <operation_type> | <description>

<what was done, which pages were affected, brief rationale>
```

- Valid operation types: `ingest`, `query`, `lint`, `reflect`, `update`, `merge`, `supersede`, `archive`.
- Each entry includes: what was done, which pages were affected, and a brief rationale.
- The log is parseable with: `grep "^## \[" wiki/log.md | tail -5`
- Structural reasoning and decision analysis belong in decision record pages (reflect workflow, Section 11.4), NOT in the log. The log records WHAT happened; decision records explain WHY.

## 13. Privacy Routing

All content in the wiki system has a privacy classification that determines whether it may be sent to cloud LLM APIs. The system uses fail-closed semantics: when in doubt, the answer is `local_only`. It is better to under-share than to accidentally send private content to a cloud API.

### Privacy Tiers

- **`local_only`** -- NEVER sent to cloud LLM APIs. Processed only by local models or local tooling.
- **`cloud_safe`** -- May be sent to cloud LLM APIs for processing.

### Three-Level Precedence

Privacy classification is resolved using a three-level precedence hierarchy (most specific wins):

1. **Explicit `privacy` field in item frontmatter** -- This is the authoritative declaration. If present, it is always respected.
2. **Enclosing directory default** -- Provides operational convenience. Directories like `sources/local-only/` imply `local_only`; directories like `sources/cloud-safe/` imply `cloud_safe`.
3. **System default: `local_only`** -- If neither frontmatter nor directory provides a signal, the item is classified as `local_only` (fail-closed).

### Conflict Resolution

If the frontmatter and directory disagree, the **stricter** setting wins. Since `local_only` is always stricter than `cloud_safe`, any conflict resolves to `local_only`. This ensures that an item explicitly marked `local_only` cannot be overridden by a permissive directory, and a restrictive directory cannot be overridden by a permissive frontmatter field.

### Privacy Decision Table

| # | Frontmatter `privacy` | Directory               | Result       | Why                                                    |
|---|----------------------|-------------------------|-------------|--------------------------------------------------------|
| 1 | `cloud_safe`         | `sources/cloud-safe/`   | `cloud_safe` | Both agree: cloud_safe                                 |
| 2 | `local_only`         | `sources/cloud-safe/`   | `local_only` | Frontmatter is stricter, stricter wins                 |
| 3 | `cloud_safe`         | `sources/local-only/`   | `local_only` | Directory is stricter, stricter wins                   |
| 4 | (not set)            | `sources/cloud-safe/`   | `cloud_safe` | No frontmatter, directory provides signal              |
| 5 | (not set)            | `sources/2026/2026-04/` | `local_only` | No frontmatter, no privacy directory signal, system default |
| 6 | (not set)            | (no directory signal)   | `local_only` | Fail-closed: unknown = local_only                      |
| 7 | `local_only`         | (no directory signal)   | `local_only` | Explicit local_only confirmed                          |

### Rules for LLM Agents

1. The LLM MUST check privacy classification before sending any content to a cloud API.
2. If classification cannot be determined, treat as `local_only`.
3. Never send `local_only` content to cloud LLM APIs under any circumstances.
4. When creating wiki pages, set the `privacy` field in frontmatter based on the sources used.

### Wiki Page Privacy Inheritance

When a wiki page cites sources with mixed privacy tiers (e.g., one `local_only` source and one `cloud_safe` source), the wiki page inherits `local_only` -- the strictest tier among its contributing sources. A page is only `cloud_safe` if ALL of its contributing sources are `cloud_safe`.

## 14. Scaling Boundaries

**Important:** These are provisional heuristics, not hard boundaries. They are starting points derived from reasoning about likely pain points. Validate and adjust through actual use. The numbers below are approximate -- the real signals are behavioral (the wiki becomes awkward to use in specific ways).

These tiers are additive. Each builds on the previous rather than replacing it.

### Tier 1: Markdown-First Baseline (v1)

This is the starting configuration. Everything is markdown files and YAML frontmatter.

- **Navigation:** `wiki/index.md` is the primary navigation mechanism. The LLM reads it to find pages.
- **Lint:** Full lint scans all pages in the wiki.
- **Agent behavior:** Read the full index, scan all pages during lint.
- **Approximate capacity:** Up to ~100-200 wiki pages, ~50-100 ingested sources.
- **Pain points at limit:** `index.md` becomes slow to navigate. The LLM's context window fills up scanning the full index. Full lint takes multiple passes or minutes.
- **Signal you are outgrowing this tier:** `index.md` exceeds ~500 lines. The LLM frequently retrieves pages irrelevant to the query because the index is too dense to scan efficiently.

### Tier 2: Split Index

When the single index becomes unwieldy (approximately a few hundred wiki pages).

- **Change:** Split `wiki/index.md` into per-type or per-domain sub-indexes: `wiki/index-entities.md`, `wiki/index-concepts.md`, `wiki/index-sources.md`, etc. The main `wiki/index.md` becomes a meta-index pointing to sub-indexes.
- **Agent behavior:** Read the meta-index to determine which sub-index is relevant, then read only that sub-index.
- **Approximate capacity:** Up to ~500-1000 wiki pages.
- **Pain points at limit:** Even sub-indexes become large. Cross-type queries require reading multiple sub-indexes. The meta-index itself grows.
- **Signal to upgrade:** Sub-indexes exceed ~200 entries each. Cross-domain queries are slow because the LLM must read multiple sub-indexes.

### Tier 3: Incremental Lint

When full lint becomes too expensive to run routinely.

- **Change:** Track which pages changed since the last lint (via `git diff` or `log.md` timestamps). Only lint changed pages and their direct neighbors (pages they link to or are linked from).
- **Agent behavior:** Run `git diff --name-only <last-lint-commit>` to scope the lint to changed files. Expand scope to include pages linked to/from changed pages.
- **Approximate capacity:** Any size where full lint is impractical.
- **Pain points at limit:** Neighbor expansion can still be large in highly connected wikis. Deep dependency chains may be missed by incremental lint.
- **Signal to upgrade:** Lint takes so long that you stop running it, or incremental lint misses issues that a full lint would catch.

### Tier 4: DB-Backed Metadata

When provenance queries, search, or concurrency become awkward in pure markdown.

- **Change:** Add SQLite (or similar lightweight database) for metadata: source registry, provenance index, search index, wikilink graph. Markdown pages remain the human-facing artifact; the database is an acceleration layer.
- **Agent behavior:** Query the database for source and provenance lookups instead of scanning markdown files. Use the database for search instead of grep.
- **Approximate capacity:** Thousands of pages and sources.
- **Pain points:** Requires maintaining synchronization between the database and markdown files. Adds a tooling dependency beyond plain markdown.
- **Signal to upgrade:** Provenance validation is slow because it requires scanning many files. Search needs more than grep. Multiple agents need concurrent access to the wiki.

## 15. Tooling and Integrations

> This section is informational, not normative. It describes tools the wiki is designed to work with, but does not mandate their installation. The wiki functions as plain markdown files in a git repo regardless of tooling.

### Obsidian (Primary Human Interface)

- **Graph View:** Visualize the wiki's link structure. Only meaningful links appear because Section 8 enforces first-mention linking and prohibits display aliases.
- **Dataview plugin:** Query frontmatter fields with TABLE/LIST/TASK syntax. All frontmatter fields defined in Section 5 are queryable. Example: `TABLE summary, epistemic_status FROM "wiki/entities" WHERE status = "active"`.
- **Properties:** Obsidian 1.4+ supports typed frontmatter editing. All base fields render as editable properties in the sidebar.
- **Aliases:** The `aliases` frontmatter field enables Obsidian to resolve alternative page names automatically, supporting the exact-title wikilink convention (Section 8).
- **Backlinks:** Obsidian's backlinks panel shows all pages that link to the current page, complementing the `## Related Pages` section.

### Git (Version Control)

- All changes are tracked in git with conventional commits (Section 3).
- History provides a full audit trail of wiki evolution.
- Branching is available for experimental restructuring (e.g., major domain reorganization).
- The activity log (`wiki/log.md`) complements git history with human-readable operation summaries.

### Optional Future Tools (Not Required for v1)

- **Local search engine** (e.g., qmd or similar): Hybrid BM25/vector search for faster query workflow when the wiki grows beyond grep's effectiveness.
- **Obsidian Web Clipper:** Source acquisition from the web -- clip articles directly into the `sources/` directory.
- **Marp plugin:** Generate slide decks from wiki content for presentations and reviews.

## 16. Appendices and Examples

### Appendix A: Dataview Query Examples

**List all active entity pages:**

````markdown
```dataview
TABLE summary, epistemic_status, updated_at
FROM "wiki/entities"
WHERE status = "active"
SORT updated_at DESC
```
````

**List all sources by domain:**

````markdown
```dataview
TABLE source_type, ingested_at, content_hash
FROM "wiki/sources"
WHERE contains(domains, "ai-research")
SORT ingested_at DESC
```
````

**List stale pages across the entire wiki:**

````markdown
```dataview
LIST
FROM "wiki"
WHERE epistemic_status = "stale"
SORT updated_at ASC
```
````

**Find pages missing privacy classification:**

````markdown
```dataview
LIST
FROM "wiki"
WHERE !privacy
```
````

**List all pages in a specific domain:**

````markdown
```dataview
TABLE title, type, epistemic_status
FROM "wiki"
WHERE contains(domains, "ai-research") AND status = "active"
SORT type ASC
```
````

### Appendix B: Commit Message Examples

```
schema: define base frontmatter fields and page type conventions
ingest(hinton-interview): add source summary and update entity pages
ingest(vaswani-attention): create source summary with 3 extracted claims, update attention mechanism page
query(attention-mechanisms): synthesize comparison of attention variants
query(ai-safety-timeline): create overview page from 4 existing sources
lint(wiki): fix 3 orphan pages and 2 broken provenance references
lint(entities): update 5 stale epistemic_status markers
reflect(q1-review): restructure AI safety domain after new sources
reflect(domain-split): separate neuroscience from ai-research domain
```

### Appendix C: Quick Reference Card

A compact summary of the most critical rules for fast LLM scanning:

1. **Read `wiki/index.md` first, always.** This is the entry point for all wiki operations.
2. **TL;DR and Key Facts before Detail.** Read shallow sections first; drill into Detail only when needed.
3. **`[[Exact Title]]` on first mention only.** No display aliases. No repeated links. No wikilinks in frontmatter.
4. **`[prov:source_id#locator]` for every factual claim.** Every claim needs provenance. No exceptions.
5. **One commit per logical operation.** One ingest = one commit, even if it touches many files.
6. **Privacy default: `local_only`.** When in doubt, do not send to cloud APIs.
7. **All dates: ISO 8601.** `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ss`.
8. **All field names: `snake_case`.** For Dataview compatibility.
9. **Operations: UPDATE, MERGE, SUPERSEDE, ARCHIVE.** No raw file rewrites. Log every operation.
10. **See Section 3 "What Agents Must NOT Do"** for the full list of prohibitions.

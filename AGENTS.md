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
```

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

<!-- Sections 9-16 follow below -->

---
id: src-2026-03-15-vaswani-attention
title: "Vaswani et al. - Attention Is All You Need"
type: source
status: active
summary: "Seminal paper introducing the Transformer architecture based entirely on
  attention mechanisms."
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
supersedes: null
superseded_by: null
aliases:
- Attention Is All You Need
path: sources/2026/2026-03/2026-03-15-vaswani-attention/source.md
url: "https://arxiv.org/abs/1706.03762"
content_hash: "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
ingested_at: 2026-04-08
source_type: paper
example: true
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

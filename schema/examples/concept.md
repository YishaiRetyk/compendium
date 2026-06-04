---
id: attention-mechanism
title: Attention Mechanism
type: concept
status: active
summary: "A neural network component that allows models to focus on relevant parts
  of the input sequence."
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
supersedes: null
superseded_by: null
aliases:
- Attention
- Self-Attention
example: true
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

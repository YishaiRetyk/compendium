---
id: deep-learning
title: Deep Learning
type: overview
status: active
summary: "High-level overview of deep learning: history, key architectures, and current
  state."
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
supersedes: null
superseded_by: null
aliases:
- DL
example: true
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

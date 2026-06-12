---
id: ai-for-drug-repurposing
title: "AI for Drug Repurposing"
type: concept
status: active
summary: "Using LLM and agentic systems to surface non-obvious new indications for existing drugs by logically connecting insights already documented across the scientific literature, shortening the historical lag between insight and therapeutic application."
created_at: 2026-06-12
updated_at: 2026-06-12
sources:
- src-2026-06-12-multi-agent-scientific-discovery
epistemic_status: sourced
tags:
- drug-repurposing
- llm-agents
- therapeutics
- macular-degeneration
- ai-for-science
domains:
- biomedicine
- ai-for-science
supersedes: null
superseded_by: null
aliases:
- "AI for Drug Repurposing"
- "ai-for-drug-repurposing"
has_contradictions: false
knowledge_domain: science
example: false
---

# AI for Drug Repurposing

## TL;DR

Drug repurposing — finding new indications for existing drugs — is an attractive target for LLM systems because the connective insight often already exists in the literature but takes years to crystallize into a treatment. By logically linking disparate documented findings, agentic systems aim to identify "low-hanging fruit" that compartmentalized human experts overlook [prov:src-2026-06-12-multi-agent-scientific-discovery#p8|direct|2026-06-12].

## Key Facts

- The history of drug repurposing shows a recurring pattern of long lags between when an insight is documented and when it becomes a treatment (e.g. dabrafenib's otoprotective effect found ~10 years after its molecular action was characterized; ketamine 22 years; leucovorin 5 years; KarXT 13 years). [prov:src-2026-06-12-multi-agent-scientific-discovery#p3|direct|2026-06-12]
- The [[robin-multi-agent-discovery-system|Robin (Multi-Agent Discovery System)]] demonstration repurposed ripasudil, an approved glaucoma ROCK inhibitor never previously proposed for dry AMD, as an RPE phagocytosis enhancer in preclinical in-vitro assays (a reported preclinical finding, not a clinically validated dAMD treatment). [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12]
- An approved drug's known safety profile is itself a repurposing advantage: ripasudil's clinical approval was cited as favorable for translation *relative to* the research compound Y-27632 — a comparative advantage over that research compound, not an absolute safety claim for dAMD use. [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12]
- The paper frames repurposing as "combinatorial synthesis" — identifying non-obvious connections between disparate fields — and notes the same paradigm is applicable beyond therapeutics (e.g. materials science). [prov:src-2026-06-12-multi-agent-scientific-discovery#p8|direct|2026-06-12]

## Detail

The structural argument is that repurposing opportunities are frequently realized years after the core insights are documented, which means a system that can reliably synthesize disparate literature could compress that lag [prov:src-2026-06-12-multi-agent-scientific-discovery#p3|direct|2026-06-12]. This reframes discovery from generating wholly new knowledge to *connecting existing knowledge* — a task well matched to LLMs trained across many fields, which is why the [[llm-agent-scientific-discovery|LLM Agents for Scientific Discovery]] paradigm targets it.

The broader motivation cited is that FDA approvals have stagnated at roughly 50 novel drugs annually over the past decade, so methods that scale therapeutic discovery — by surfacing safe, literature-grounded repurposing candidates for standard pre-clinical validation — address a real bottleneck [prov:src-2026-06-12-multi-agent-scientific-discovery#p8|direct|2026-06-12]. The paper is careful to frame AI outputs as *hypotheses* requiring standard validation, with guardrails prioritizing candidates with established safety profiles [prov:src-2026-06-12-multi-agent-scientific-discovery#p8|direct|2026-06-12].

## Related Pages

- [[robin-multi-agent-discovery-system|Robin (Multi-Agent Discovery System)]] — the system that demonstrated repurposing for dAMD.
- [[llm-agent-scientific-discovery|LLM Agents for Scientific Discovery]] — the underlying methodology.

## Sources

- [[src-2026-06-12-multi-agent-scientific-discovery|A Multi-Agent System for Automating Scientific Discovery (Robin)]] — Ghareeb et al., Nature (2026).

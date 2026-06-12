---
id: robin-multi-agent-discovery-system
title: "Robin (Multi-Agent Discovery System)"
type: overview
status: active
summary: "FutureHouse's Robin: a multi-agent LLM system that automates hypothesis generation and experimental data analysis end-to-end, demonstrated by discovering ROCK-inhibitor phagocytosis enhancers for dry age-related macular degeneration."
created_at: 2026-06-12
updated_at: 2026-06-12
sources:
- src-2026-06-12-multi-agent-scientific-discovery
epistemic_status: sourced
tags:
- multi-agent-systems
- llm-agents
- scientific-discovery
- drug-repurposing
- paperqa2
domains:
- ai-for-science
- llm-agents
- biomedicine
supersedes: null
superseded_by: null
aliases:
- "Robin (Multi-Agent Discovery System)"
- "Robin"
- "robin-multi-agent-discovery-system"
has_contradictions: false
knowledge_domain: science
example: false
---

# Robin (Multi-Agent Discovery System)

## TL;DR

Robin is a multi-agent LLM system from FutureHouse, presented as the first to automate both hypothesis generation and experimental data analysis for experimental biology in one continuous "lab-in-the-loop" workflow [prov:src-2026-06-12-multi-agent-scientific-discovery#p3|direct|2026-06-12]. It coordinates three specialized language agents — Crow and Falcon for literature search and Finch for data analysis — to iteratively generate, test, and refine therapeutic hypotheses. In its proof-of-concept it identified ripasudil and KL001 as enhancers of retinal pigment epithelium (RPE) phagocytosis for dry age-related macular degeneration (dAMD).

## Key Facts

- Robin integrates novel hypothesis generation with experimental data analysis in one continuous workflow using specialized [[llm-agent-scientific-discovery|LLM Agents for Scientific Discovery]]. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12]
- It coordinates three agents: Crow and Falcon (literature search, built on PaperQA2) and Finch (experimental data analysis of RNA-seq and flow cytometry). [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12]
- Finch runs 8 independent analysis trajectories per task and synthesizes them into a consensus conclusion via meta-analysis, trading the stochasticity of a single language-agent run for ensemble consistency. [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12]
- Applied to [[ai-for-drug-repurposing|AI for Drug Repurposing]], Robin identified ripasudil and KL001 as RPE phagocytosis enhancers for dAMD and surfaced ABCA1 upregulation as a candidate mechanism. [prov:src-2026-06-12-multi-agent-scientific-discovery#p3|direct|2026-06-12]
- The authors report a full run costs about $10.76 (45 Crow + 30 Falcon calls) and claim a ~200-fold reduction in workflow time versus manual research. [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12] [epistemic:: tentative]

## Detail

### The three-agent architecture

Robin's design separates literature reasoning from data reasoning. **Crow** and **Falcon** are literature-search agents based on PaperQA2 that conduct concise and deep summaries respectively, with access to scientific literature, clinical trial reports, and the Open Targets Platform [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12]. **Finch** is the data-analysis agent that executes analysis code (in Jupyter notebooks) over experimental data such as flow cytometry `.FCS` files and RNA-seq gene counts [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12].

The orchestration is a **lab-in-the-loop** cycle: Robin proposes disease mechanisms and ranked drug candidates, human scientists run the suggested assays, the raw data is uploaded back to Robin, Finch analyzes it across 8 trajectories with a consensus meta-analysis, and Robin distills insights and proposes the next round — continuing until a human is satisfied with a candidate [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12].

### The dAMD proof of concept

Tasked with dry age-related macular degeneration — the leading cause of irreversible sight loss in developed countries, affecting 1.5 million people with vision-threatening dAMD in the U.S. — Robin reviewed ~151 papers to rank ten candidate disease mechanisms, selected enhancing RPE phagocytosis, then proposed 30 existing drugs for assay testing [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12]. Experimental rounds confirmed ripasudil (1.89-fold phagocytosis increase, outperforming the research compound Y-27632) and KL001 as hits, and a Robin-proposed follow-up RNA-seq surfaced a 3-fold upregulation of ABCA1 (adjusted p = 2.13×10⁻⁸³) as a candidate mechanism [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12].

### Why the specialized harness matters

Ablation experiments support the architecture rather than a bare frontier model. Replacing the literature agents with OpenAI's o4-mini drove hallucinated references from 0% (Crow) to 44.5 ± 6.37% [prov:src-2026-06-12-multi-agent-scientific-discovery#p7|direct|2026-06-12]. On the BixBench data-analysis panel Finch scored 22.8 ± 1.7% versus 1.6 ± 1.2% for Claude Sonnet 3.7 alone, and a general-purpose baseline (OpenAI Deep Research) produced no assay hits and never suggested ROCK inhibition [prov:src-2026-06-12-multi-agent-scientific-discovery#p7|direct|2026-06-12].

## Related Pages

- [[llm-agent-scientific-discovery|LLM Agents for Scientific Discovery]] — the broader paradigm Robin instantiates.
- [[ai-for-drug-repurposing|AI for Drug Repurposing]] — the application domain of Robin's dAMD demonstration.

## Sources

- [[src-2026-06-12-multi-agent-scientific-discovery|A Multi-Agent System for Automating Scientific Discovery (Robin)]] — Ghareeb et al., Nature (2026), doi:10.1038/s41586-026-10652-y.

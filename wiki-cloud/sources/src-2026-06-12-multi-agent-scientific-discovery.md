---
id: src-2026-06-12-multi-agent-scientific-discovery
title: "A Multi-Agent System for Automating Scientific Discovery (Robin)"
type: source
status: active
summary: "Nature paper introducing Robin, a multi-agent LLM system that automates hypothesis generation and experimental data analysis end-to-end, applied to dry age-related macular degeneration to identify ripasudil and KL001 as RPE phagocytosis enhancers."
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
- macular-degeneration
- bioinformatics
- pdf-ingestion
domains:
- ai-for-science
- biomedicine
- llm-agents
supersedes: null
superseded_by: null
aliases:
- "A Multi-Agent System for Automating Scientific Discovery (Robin)"
- "Robin (FutureHouse multi-agent discovery system)"
- "src-2026-06-12-multi-agent-scientific-discovery"
has_contradictions: false
knowledge_domain: science
example: false
path: sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/source.md
url: "https://doi.org/10.1038/s41586-026-10652-y"
content_hash: "sha256:16da29dabb0c6babb6ab7b3ab089c926934c0aa3d62135ad4c6ab9de60b363f1"
ingested_at: 2026-06-12
source_type: paper
extraction_tool: olmocr
extraction_model: "hf.co/bartowski/allenai_olmOCR-2-7B-1025-GGUF:Q4_K_M"
extraction_date: 2026-06-12
original_asset: s41586-026-10652-y.pdf
compilation_status: compiled
compiled_against_hash: "sha256:16da29dabb0c6babb6ab7b3ab089c926934c0aa3d62135ad4c6ab9de60b363f1"
compiled_targets:
- robin-multi-agent-discovery-system
- llm-agent-scientific-discovery
- ai-for-drug-repurposing
---

## TL;DR

A peer-reviewed Nature paper (Ghareeb et al., FutureHouse, 2026) introducing **Robin**, described as the first multi-agent system to automate both hypothesis generation and experimental data analysis for experimental biology in one continuous lab-in-the-loop workflow. Robin coordinates three specialized language agents — Crow and Falcon (literature search, built on PaperQA2) and Finch (data analysis) — to iteratively generate, test, and refine therapeutic hypotheses. Applied to dry age-related macular degeneration (dAMD), Robin proposed enhancing retinal pigment epithelium (RPE) phagocytosis and identified ripasudil (a clinically used ROCK inhibitor never previously proposed for dAMD) and KL001 (a novel candidate) as phagocytosis enhancers, and surfaced ABCA1 upregulation as a candidate mechanism via follow-up RNA-seq.

## Key Takeaways

- Robin is presented as the first multi-agent system to fully automate both hypothesis generation and data analysis for experimental biology, integrating literature-search and data-analysis agents in a continuous feedback loop. [prov:src-2026-06-12-multi-agent-scientific-discovery#p3|direct|2026-06-12] [epistemic:: sourced]
- Robin coordinates three specialized agents: Crow and Falcon (literature search, based on PaperQA2) and Finch (experimental data analysis of assays such as RNA-seq and flow cytometry). [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: sourced]
- Applied to dAMD, Robin proposed enhancing RPE phagocytosis and identified ripasudil and KL001 as phagocytosis enhancers, with ripasudil being a repurposing candidate (an approved glaucoma ROCK inhibitor never previously proposed for dAMD). [prov:src-2026-06-12-multi-agent-scientific-discovery#p3|direct|2026-06-12] [epistemic:: sourced]
- A follow-up RNA-seq experiment proposed and analyzed by Robin revealed a roughly 3-fold upregulation of ABCA1, a lipid efflux pump, as a possible novel target connected to dAMD pathology. [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12] [epistemic:: sourced]
- The authors report large efficiency gains: Robin analyzed ~551 papers in ~30 minutes versus an estimated 540 human hours, a claimed ~200-fold time reduction for the full workflow. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: tentative]
- Ablation experiments support the specialized-agent design: removing Falcon (or both literature agents) sharply increased hallucinated references, and Finch substantially outperformed a bare frontier LLM on the BixBench data-analysis benchmark. [prov:src-2026-06-12-multi-agent-scientific-discovery#p7|direct|2026-06-12] [epistemic:: sourced]

## Extracted Claims

### System architecture

- Robin integrates novel hypothesis generation with experimental data analysis in one continuous workflow, using specialized language agents for literature search (Crow and Falcon) and data analysis (Finch) to enable semi-autonomous scientific discovery. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: sourced]
- Crow and Falcon are literature search agents based on PaperQA2 that conduct concise and deep literature summaries respectively, with access to scientific literature, clinical trial reports, and the Open Targets Platform. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: sourced]
- Finch is a scientific data analysis agent that performs analyses of experimental data from assays such as RNA-seq and flow cytometry; Robin launches 8 independent Finch analysis trajectories and synthesizes them into a consensus-driven conclusion via meta-analysis. [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12] [epistemic:: sourced]
- Robin's discovery loop is "lab-in-the-loop": after Robin proposes candidates, human scientists execute the experiments, then upload raw data back to Robin for autonomous analysis and a new round of hypothesis generation, continuing until a human is satisfied with a drug candidate. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: sourced]

### Efficiency and cost

- In the reported workflow, Robin analyzed 551 papers in 30 minutes against an estimated 540 hours for a human, which the authors translate into an estimated ~200-fold reduction in time for the full scientific workflow. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: tentative]
- A full Robin run under the paper's configuration (num_queries=5, num_assays=10, num_candidates=30) issues 45 Crow calls and 30 Falcon calls, costing on average $4.33 and $6.43 respectively, for a total of about $10.76 per run. [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12] [epistemic:: sourced]
- The authors' time-on-task analysis estimates that Robin reduces a discovery cycle from roughly 872–937 human hours to under two hours. [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12] [epistemic:: tentative]

### dAMD application and findings

- dAMD is described as the leading cause of irreversible sight loss in developed countries; in the U.S. alone, 1.5 million people have vision-threatening dAMD and 600,000 are legally blind due to AMD, a figure projected to nearly triple by 2050. [prov:src-2026-06-12-multi-agent-scientific-discovery#p4|direct|2026-06-12] [epistemic:: sourced]
- Robin proposed treating dAMD by increasing RPE cell phagocytosis after reviewing ~151 papers to rank ten candidate disease mechanisms, then proposed 30 existing drug candidates for testing in a phagocytosis assay. [prov:src-2026-06-12-multi-agent-scientific-discovery#p5|direct|2026-06-12] [epistemic:: sourced]
- Differential gene expression analysis (by Finch) identified a 3-fold upregulation of ABCA1 (adjusted p = 2.13×10⁻⁸³) in Y-27632-treated RPE cells, linking ROCK-inhibitor-induced phagocytosis to a lipid efflux pump relevant to dAMD pathology. [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12] [epistemic:: sourced]
- Ripasudil, a ROCK inhibitor approved for glaucoma in Japan, increased RPE cell phagocytosis 1.89-fold versus DMSO controls and outperformed the research compound Y-27632, and as an approved drug carries a known safety profile favorable for clinical translation. [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12] [epistemic:: sourced]
- KL001, a circadian clock modulator, was also identified as a phagocytosis-enhancing hit in primary human RPE stem cells; the authors state that to their knowledge no one had previously proposed KL001 as an enhancer of phagocytosis. [prov:src-2026-06-12-multi-agent-scientific-discovery#p6|direct|2026-06-12] [epistemic:: sourced]

### Architecture validation

- Ablating the literature search agents and replacing them with OpenAI's o4-mini sharply increased hallucinated references: Crow produced no hallucinated references while 44.5 ± 6.37% of o4-mini's references were hallucinated across 15 assay proposals. [prov:src-2026-06-12-multi-agent-scientific-discovery#p7|direct|2026-06-12] [epistemic:: sourced]
- On a 170-item BixBench data-analysis panel, Finch scored 22.8 ± 1.7% versus 1.6 ± 1.2% for Claude Sonnet 3.7 without the agent harness, demonstrating the value of the tool-augmented analysis harness while highlighting room for improvement on multi-step problems. [prov:src-2026-06-12-multi-agent-scientific-discovery#p7|direct|2026-06-12] [epistemic:: sourced]
- A general-purpose baseline (OpenAI's Deep Research) asked to generate equivalent dAMD drug candidates produced no hits in the RPE-SC assay and did not suggest ROCK inhibition, supporting the claim that Robin's specialized pipeline was non-trivial. [prov:src-2026-06-12-multi-agent-scientific-discovery#p7|direct|2026-06-12] [epistemic:: sourced]

## Notes

- **Document tier:** born-digital, clean (Springer/Nature Accelerated Article Preview, machine-set, not a scan). Per the tiered epistemic policy (`schema/reference/pdf-ingestion.md`), born-digital input keeps the parent type's normal `sourced` default with no spot-verification mandate; the spot-check during validation was a quality confirmation, not a tier-upgrade requirement.
- **Quantitative claims marked tentative:** the headline ~200-fold and 872–937-hours-to-2-hours efficiency figures rest on the authors' own time-on-task estimates and survey-derived human baselines, so they are graded `[epistemic:: tentative]` even though directly stated; the specific cost and assay numbers are reported measurements and graded `sourced`.
- **Acquisition provenance:** the original PDF was supplied by the user, ghostscript `/ebook`-compressed from a 22 MB original to the co-located 12 MB `s41586-026-10652-y.pdf` (readability verified). At 36 pages it sits slightly above the ~5–30-page soft range of D-12; the larger size was explicitly user-approved for this validation.
- **Extraction note:** extracted with olmOCR-2 weights served via Ollama 0.30.7 (model tag `hf.co/bartowski/allenai_olmOCR-2-7B-1025-GGUF:Q4_K_M`). The plan-named packaging `richardyoung/olmocr2:7b-q8` is broken under Ollama ≤0.20.x (llama.cpp-runner M-RoPE incompatibility). Dense figure pages required raising the model context window (`num_ctx: 8192`) to clear the default 4096-token limit. The convention is tool-agnostic (D-04); the frontmatter records the model actually used.

## Source Metadata

- **Type:** peer-reviewed research paper (Nature Accelerated Article Preview)
- **Title:** A multi-agent system for automating scientific discovery
- **Authors:** Ali Essam Ghareeb, Benjamin Chang, Ludovico Mitchener, Angela Yiu, Caralyn J. Szostkiewicz, Dmytro Shved, Gavin J. Gyimesi, Jon M. Laurent, Samantha M. Wright, Muhammed T. Razzak, Andrew D. White, Silvia C. Finnemann, Michaela M. Hinks & Samuel G. Rodriques (FutureHouse, University of Oxford, Fordham University)
- **Published:** Nature, online 19 May 2026; doi:10.1038/s41586-026-10652-y
- **Source file:** `sources/2026/2026-06/2026-06-12-multi-agent-scientific-discovery/source.md`
- **Original asset:** `s41586-026-10652-y.pdf` (co-located in the bundle)
- **Content hash:** `sha256:16da29dabb0c6babb6ab7b3ab089c926934c0aa3d62135ad4c6ab9de60b363f1`
- **Ingested:** 2026-06-12

---
lab: "<Lab Name>"
slug: "<kebab-case-slug>"
openness: "<open-weight | fully-open | partial | closed>"
local_support: "<yes | partial | no>"
updated: "<YYYY-MM-DD>"
notable_models:
  - name: "<Model>"
    size: "<params>"
    license: "<license>"
---

# <Lab Name>

## Overview
1-2 paragraphs: who they are, where based, what they're known for, positioning in the open-model landscape.

## Release Cadence
How frequently they release, recent节奏 (2024-2026), and any notable shifts in policy (e.g. toward/away from open). Use a short timeline or bullet list with dates.

## Models & Sizes
| Model | Release | Total Params | Active (if MoE) | Context | License | Open? |
|--------|---------|--------------|-----------------|---------|---------|-------|
| ...    | ...     | ...          | ...             | ...     | ...     | ...   |

## Openness Status
Assess the spectrum: open-weight only vs fully open (code+data). Note any recent policy changes. Cite sources.

## Serving (vLLM / llama.cpp / Atlas)
How the models are served locally. Reference specific engines and any known quantization/format support (GGUF, NVFP4, FP8, MTP). Note if NOT yet runnable.

## References
- Official site: <url>
- Key research/publication: <url>
- Model hub / release page: <url>
- Other: <url>

## Local Deployment in This Repo
If this lab's models are already deployed in `inference-containers/`, link the folder(s) and note the engine/hardware. If not deployed yet, say so and suggest which model would fit (5090 vs DGX Spark).

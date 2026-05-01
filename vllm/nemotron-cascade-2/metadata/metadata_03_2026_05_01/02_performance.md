# Performance Summary

## Prompt Throughput
- Prompt throughput observed across the session: **1873.7 – 9948.6 tokens/s**.

## Generation Throughput
- Generation throughput varied widely: **from ~2.9 tokens/s up to ~255 tokens/s** during active requests.

## GPU KV Cache Usage
- Available KV cache: ~1,206,303 tokens (capacity per request: 256,000 tokens).<br>
- GPU KV cache utilization: typically **0 %–4 %**.

## Prefix Cache Hit Rate
- Consistently **0.0 %**. The KV cache does not provide a measurable benefit for the `chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4` model. This is a sharp contrast with the `gemma-4-26b` models where the served endpoint shows cache‑hit activity.

> **Note:** The cache hit rate remains 0 % for this Nemotron model because the KV cache is not effectively utilized in its current configuration.
# Performance Table for Nemotron-Cascade-2 Model

## Key Metrics

| Metric | Value |
|--------|-------|
| Prompt Throughput (max) | 9948.69 tokens/s |
| Prompt Throughput (min) | 1,873.7 tokens/s |
| Generation Throughput (max) | 178.5 tokens/s |
| Generation Throughput (min) | 2.9 tokens/s |
| KV Cache Capacity | 1,206,303 tokens |
| KV Cache Utilization (observed) | 0 % – 6.8 % |
| Prefix Cache Hit Rate | Consistently 0 % (occasionally saw minor spikes) |

## Conclusion

The Nemotron‑Cascade‑2 model shows virtually no prefix cache hit activity. 
Looks like a vLLM bug running this model.
Gemma4 MoE has cache hit rates.
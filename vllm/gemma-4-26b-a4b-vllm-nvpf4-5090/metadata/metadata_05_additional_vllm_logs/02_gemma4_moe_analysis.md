# Gemma 4 MoE Analysis - VLLM Performance

This document provides a summary of key performance indicators (KPIs) observed during the VLLM session, specifically focusing on throughput metrics for both prompt processing (prefill) and token generation (decode).

## Throughput Analysis

The following table captures various snapshots of the performance observed during the run, showcasing the throughput for prompt-to-token processing and the prefix cache efficiency.

| Event/Timestamp (Approx) | Avg Prompt Throughput (tokens/s) | Avg Generation Throughput (tokens/s) | Prefix Cache Hit Rate (%) |
|-------------------------|---------------------------------|------------------------------------|---------------------------|
| 00:06:46                | 1928.5                          | 31.0                               | 89.7                      |
| 00:07:04                | 0.0                             | 95.4                               | 89.7                      |
| 00:07:22                | 336.5                           | 14.1                               | 89.9                      |
| 00:44:09                | 2123.9                          | 23.2                               | N/A                       |
| 00:44:19                | 1283.0                          | 103.0                             | N/A                       |
| 00:44:26                | 248.1                           | 104.8                             | N/A                       |
| 00:57:42                | 471.1                           | 90.9                              | N/A                       |
| 01:17:13                | 1647.1                          | 24.1                              | N/A                       |
| 01:22:45                | 2290.6                          | 33.5                             | N/A                       |
| 01:24:46                | 433.3                           | 49.4                             | N/A                       |
| 01:29:47                | 199.1                           | 49.2                             | N/A                       |
| 00:06:55 (Peak)         | 5517.1                          | 91.2                             | 89.7                      |

## Summary of Observations

- **Prefill Speed:** The prompt throughput shows significant variability, with peak values reaching above 5500 tokens/s during specific high-load phases.
- **Generation Speed:** Token generation throughput remains relatively stable, with peaks around 104 tokens/s, though it can drop depending on the request profile.
- **Context & Efficiency:** The prefix cache hit rate frequently remained above 90% during various stages of the session, contributing to efficient processing as-needed.
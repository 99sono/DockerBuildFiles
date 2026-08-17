# Challenge 01: SGLang log parser

You are an SRE for an inference server. Write a complete, self-contained Python 3
script that parses an SGLang server log file and prints concise statistics.

The log file is at: `../../01_docker_logs.txt` (relative to this challenge file).

It contains lines like:

```
[2026-08-17 18:15:58] Decode batch, #running-req: 1, #full token: 1112, full token usage: 0.03, mamba num: 4, mamba usage: 0.11, cuda graph: True, gen throughput (token/s): 72.31, #queue-req: 0
[2026-08-17 18:16:19] Prefill batch, #new-seq: 1, #new-token: 1, #cached-token: 0, full token usage: 0.00, mamba usage: 0.00, #running-req: 0, #queue-req: 0, #pending-token: 0, cuda graph: False, input throughput (token/s): 0.03
```

The script must:

1. Parse every "Decode batch" and "Prefill batch" line.
2. Collect the `gen throughput (token/s)` and `input throughput (token/s)` values.
3. Print:
   - total count of decode batches and prefill batches
   - min / max / mean gen throughput (token/s)
   - min / max / mean input throughput (token/s)
   - total generation tokens seen across all decode batches (`#full token:` delta)
   - whether CUDA graphs were used in decode (and how many decode batches had it True vs False)
4. Be robust to the log path being passed as a command-line argument, defaulting
   to the path above if none is given.
5. Use only the Python standard library (no pandas, no numpy).

Write the full script into `answer.md` inside this folder as a single fenced
python code block, followed by a short section showing what you expect the
output to look like.

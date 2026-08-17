# Challenge 05: Deep dive — NVFP4 + hybrid GDN architecture

Explain, in depth, how the hybrid "GDN" (linear attention / SSM) state pool
works in SGLang for the Qwen3.8-27B NVFP4 model, based on the server config.

Read the config at: `../../../docker-compose.yml` and the startup log at
`../../01_docker_logs.txt`.

Answer ALL of the following:

1. What is "Mamba" / "GDN" in the context of this Qwen3.8-27B model? Why does a
   hybrid model need a separate state pool instead of just a KV cache?

2. Explain each of these settings in plain terms, and what trade-off it makes:
   - `--mamba-full-memory-ratio 4.59`
   - `--mamba-radix-cache-strategy extra_buffer`
   - `--mamba-ssm-dtype float32`
   - `--kv-cache-dtype fp8_e4m3`
   - `--mem-fraction-static 0.9`

3. From the startup log, report the actual numbers:
   - model load time, VRAM usage (used/avail)
   - `max_total_num_tokens` and `context_len`
   - how many Mamba "slots" fit given the 153.9 MB/slot figure mentioned in the
     config comments

4. What is NVFP4 quantization (W4A4) and why does it halve VRAM vs FP8 while
   keeping quality?

Write your full explanation into `answer.md`.
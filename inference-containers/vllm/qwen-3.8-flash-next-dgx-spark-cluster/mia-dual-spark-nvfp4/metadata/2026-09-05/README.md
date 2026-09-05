# Metadata & Dual-Spark Performance Analysis (2026-09-05)

This directory contains the telemetry captures, automated parsing outputs, and comparative benchmark analysis for **Qwen 3.8 Flash Next** (`Mia-AiLab/Qwen3.8-Flash-Next-NVFP4`) running in a 2-node DGX Spark cluster (`spark01` head + `spark02` worker) using **Tensor Parallelism (TP=2)** and **Expert Parallelism (EP=true)** over 200 Gbps ConnectX-7 RoCE.

---

## 📁 Files in This Directory

| File | Type | Description |
|---|---|---|
| [`01_vllm_head_log.txt`](01_vllm_head_log.txt) | Raw Log Dump | Sanitized container logs (473 lines) extracted from `qwen38-flash-next-head`. |
| [`01_vllm_head_log.report.md`](01_vllm_head_log.report.md) | Parsed Report | Structured telemetry report produced by the `vllm/log-parser` toolchain. |
| [`02_analysis_of_dual_spark_performance.md`](02_analysis_of_dual_spark_performance.md) | Comparative Analysis | Detailed analysis comparing Dual-Spark (TP=2 + EP=true) vs Single-Spark (TP=1). |
| [`README.md`](README.md) | Guide | This documentation on how the telemetry and reports are generated and analyzed. |

---

## 🛠️ Step-by-Step Reproduction Guide

### Step 1: Dump Raw Container Logs (`01_vllm_head_log.txt`)

After running inferences or an agentic workload session, dump the logs from the head container:

```bash
cd inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head
./05_b_dump_logs.sh
```

**What this script does:**
1. Calls `docker logs qwen38-flash-next-head`.
2. Automatically redacts Authorization headers, Bearer tokens, and sensitive API keys.
3. Saves the clean output to `metadata/YYYY-MM-DD/01_vllm_head_log.txt`.

---

### Step 2: Generate the Parsed Markdown Report (`01_vllm_head_log.report.md`)

You can generate the markdown report using either the convenience bash script or direct Python invocation.

#### Method A: Using the Log-Parser Bash Wrapper (Recommended)

From anywhere in the repository:

```bash
bash inference-containers/vllm/log-parser/03_parse_docker_log_file_to_markdown_report.sh \
  inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head/metadata/2026-09-05/01_vllm_head_log.txt
```

This automatically routes execution through the `testVLLMLogParse` conda environment and writes `<logfile>.report.md` in the same directory as the input log.

#### Method B: Direct Python Invocation

Alternatively, invoke `parse_docker_log.py` directly:

```bash
conda run --no-capture-output -n testVLLMLogParse python \
  inference-containers/vllm/log-parser/parse_docker_log.py \
  inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head/metadata/2026-09-05/01_vllm_head_log.txt \
  -o inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head/metadata/2026-09-05/01_vllm_head_log.report.md
```

---

### Step 3: Verification & S7 Canary Check

When `parse_docker_log.py` finishes, it outputs a one-line classification audit:

```text
wrote .../01_vllm_head_log.report.md (lines=614 engines=33 specs=25 access=33 jit=6 warnings=21 noise=476 unrecognized=0)
```

**Key Canary Check:**
- Ensure `unrecognized=0`.
- An `unrecognized` count of 0 guarantees 100% of log lines were successfully parsed and categorized into startup, access, engine throughput, speculative decoding, JIT kernels, or recognized noise families.
- In multi-worker environments, process tags appear as `(Worker_TP0_EP0 pid=...)`; the parser's regex handles this seamlessly.

---

### Step 4: Synthesizing the Comparative Analysis (`02_analysis_of_dual_spark_performance.md`)

Once the report is generated:
1. Extract Section 3 (Timeline) and Section 4 (Aggregate Statistics) from both:
   - Single-Spark report: `inference-containers/vllm/qwen-3.8-flash-next-dgx-spark/mia-nvfp4/metadata/2026-09-05/01_vllm_log.report.md`
   - Dual-Spark cluster report: `inference-containers/vllm/qwen-3.8-flash-next-dgx-spark-cluster/mia-dual-spark-nvfp4/head/metadata/2026-09-05/01_vllm_head_log.report.md`
2. Compare peak prefill (prompt tok/s), peak generation (tok/s), speculative decoding acceptance rates ($p_1, p_2, p_3$ and draft acc%), and KV cache limits.
3. Record findings and hardware implications into `02_analysis_of_dual_spark_performance.md`.

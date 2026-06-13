## Alternative Docker Compose: Native FP4 Path (Experimental)

```yaml
services:
  qwen36-35b-nvfp4-native:
    image: avarok/dgx-vllm-nvfp4-kernel:v75
    container_name: qwen36-35b-nvfp4-native
    hostname: inference-server-native
    platform: linux/arm64
    # ports are not exposed.
    # use the nginx/nginx-vllm-reverse-proxy-dgx-spark/nginx.conf to speak with the model
    # ports:
      # - "8000:8000"
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - /dev/shm:/dev/shm
    shm_size: "32g"
    ipc: host

    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

    environment:
      VLLM_WORKER_MULTIPROC_METHOD: spawn
      PYTORCH_CUDA_ALLOC_CONF: "expandable_segments:True"
      HF_HUB_ENABLE_HF_TRANSFER: "1"
      
      # NATIVE FP4 PATH - Critical differences from Marlin fallback
      # Enable native FP4 MoE execution (disabled in safe path)
      VLLM_USE_FLASHINFER_MOE_FP4: "1"
      
      # Force CUTLASS backend for native FP4 tensor core usage
      VLLM_NVFP4_GEMM_BACKEND: cutlass
      
      # FlashInfer architecture - CRITICAL for SM121
      # Without this, FlashInfer JIT-compiles for SM120 causing illegal instructions
      FLASHINFER_CUDA_ARCH_LIST: "12.1f"
      TORCH_CUDA_ARCH_LIST: "12.1f"
      
      # CuteDSL architecture for custom kernels
      CUTE_DSL_ARCH: sm_121a
      
      # Disable version checks to allow patched kernels
      FLASHINFER_DISABLE_VERSION_CHECK: "1"
      
      # Rust frontend disabled — doesn't support api_key yet
      VLLM_USE_RUST_FRONTEND: "0"
      
      # Enable CUDA graphs for better performance (Avarok optimization)
      VLLM_ENABLE_CUDA_GRAPH: "1"

    command:
      - "--model"
      - "nvidia/Qwen3.6-35B-A3B-NVFP4"
      - "--served-model-name"
      - "${INFERENCE_MODEL_ALIAS:-qwen3.6-35b-native}"
      - "--api-key"
      - "${INFERENCE_API_KEY:-dummy-key}"
      - "--trust-remote-code"
      - "--host"
      - "0.0.0.0"
      - "--port"
      - "${INFERENCE_SERVER_PORT:-8000}"

      # --- MEMORY & CONTEXT ---
      # Native FP4 with 2:4 structured sparsity saves ~9 GiB
      # Can afford larger context or more concurrent sessions
      - "--gpu-memory-utilization"
      - "0.85"
      - "--max-model-len"
      - "131072"  # Reduced from 262144 for stability testing
      - "--max-num-seqs"
      - "2"  # Reduced from 5 - native FP4 has stability issues under high concurrency

      # --- BATCHING / PREFILL OPTIMIZATION ---
      - "--max-num-batched-tokens"
      - "8192"

      # --- ARCHITECTURE & QUANTIZATION ---
      - "--kv-cache-dtype"
      - "fp8"
      - "--dtype"
      - "auto"
      - "--quantization"
      - "modelopt_fp4"  # Correct flag for NVFP4 (NOT modelopt)
      - "--reasoning-parser"
      - "qwen3"
      - "--tool-call-parser"
      - "qwen3_coder"
      - "--enable-auto-tool-choice"

      # --- BACKENDS (NATIVE FP4 PATH) ---
      - "--attention-backend"
      - "flashinfer"
      - "--moe-backend"
      - "flashinfer_cutlass"  # Native FP4 instead of marlin
      - "--enable-prefix-caching"
      - "--enable-chunked-prefill"
      - "--async-scheduling"

      # --- STARTUP OPTIMIZATIONS ---
      - "--safetensors-load-strategy"
      - "prefetch"

      # --- SPECULATIVE DECODING (MTP) ---
      # Native FP4 path can handle more speculative tokens due to lower memory bandwidth usage
      # But start conservative due to stability concerns
      - "--speculative-config"
      - '{"method":"mtp","num_speculative_tokens":2,"moe_backend":"flashinfer_cutlass"}'

    networks:
      - development-network

networks:
  development-network:
    external: true
```

## Risk Analysis: Native FP4 Path

### What You Gain
- **Single-stream latency**: ~65-75 tok/s vs ~60 tok/s with Marlin
- **Memory efficiency**: ~9 GiB savings from 2:4 structured sparsity kernels
- **MTP performance**: Up to 111 tok/s peak with speculative decoding
- **Direct tensor core utilization**: No dequantization overhead

### What You Risk
- **NaN cascades under concurrent load**: March 2026 bug reports show torch crashes when multiple requests hit MoE layers simultaneously
- **Illegal instruction errors**: If `FLASHINFER_CUDA_ARCH_LIST` isn't set correctly, JIT compilation fails
- **SMEM miscalculations**: CUTLASS shared memory allocation doesn't account for SM121's 99 KiB limit
- **Stability**: Not suitable for production workloads with sustained multi-hour testing

### Testing Protocol
1. Start with `--max-num-seqs 2` and `--max-model-len 131072`
2. Run single-stream benchmarks first
3. Gradually increase concurrency while monitoring for NaN errors
4. Check logs for "illegal instruction" or "CUDA error: device-side assert triggered"

---

# Comprehensive Dissertation: vLLM Configuration for NVIDIA DGX Spark

## Executive Summary

The NVIDIA DGX Spark (GB10, SM12.1a) presents a unique challenge for vLLM deployment: it possesses native FP4 tensor cores but lacks a critical PTX instruction (`cvt.rn.satfinite.e2m1x2.f32`) required for standard FP4 compilation. This creates two distinct deployment paths:

1. **NVIDIA Safe Path**: Uses Marlin backend with dequantize-then-compute, prioritizing stability
2. **Avarok Bleeding Edge**: Uses software patches to enable native FP4 tensor core execution, prioritizing performance

This dissertation examines the configuration space, backend options, and trade-offs for deploying Qwen3.6-35B-A3B-NVFP4 on DGX Spark.

---

## Part I: Hardware Architecture and Its Implications

### GB10 (SM12.1a) vs. Data Center Blackwell (SM100)

| Feature | B200 (SM100) | DGX Spark GB10 (SM121) | Impact on vLLM |
|---------|--------------|------------------------|----------------|
| Shared Memory | 228 KiB | 99 KiB | CUTLASS kernel SMEM allocation fails |
| Native FP4 PTX | `cvt.e2m1x2` ✅ | **Missing** ❌ | Standard FP4 compilation fails |
| FP4 Tensor Cores | Full support | Full support | Hardware capable, software blocked |
| Memory Architecture | HBM3e | Unified LPDDR5x | Bandwidth constraints |
| CUDA Compute Capability | 10.0 | 12.1 | Different code paths |

### The Critical Missing Instruction

The `cvt.rn.satfinite.e2m1x2.f32` instruction converts 32-bit floats to packed 4-bit E2M1 format (1 sign bit, 2 exponent bits, 1 mantissa bit). Without this instruction:

- Standard CUTLASS FP4 GEMM kernels cannot compile
- FlashInfer FP4 MoE kernels fall back to Python emulation
- Performance degrades to ~1.1 tok/s (vanilla vLLM) vs ~60 tok/s (patched)

### The Software Workaround

Avarok's `patch_nvfp4_utils_sw_e2m1.py` implements a 15-line bit-manipulation device function that emulates the missing PTX instruction:

```cuda
__device__ __forceinline__ uint32_t sw_e2m1_convert(float x) {
    // Bit manipulation to pack two FP4 values into uint8
    // Replaces: cvt.rn.satfinite.e2m1x2.f32
}
```

This allows CUTLASS kernels to compile and execute on SM121, but introduces:
- Race conditions in shared memory under concurrent load
- Precision overflow risks due to FP4's narrow dynamic range
- NaN cascades when memory alignment fails

---

## Part II: vLLM Configuration Flags Deep Dive

### Quantization Flags

#### `--quantization modelopt_fp4` (Correct)
- Routes to NVIDIA ModelOpt FP4 quantization handler
- Expects checkpoints with NVFP4 weight format (dual-level scaling, Hadamard rotations)
- Required for `nvidia/Qwen3.6-35B-A3B-NVFP4`

#### `--quantization modelopt` (Incorrect for NVFP4)
- Generic ModelOpt handler for FP8/INT8 quantization
- Will fail to recognize NVFP4 weight format
- Causes "invalid quantization architecture" error

#### `--quantization awq` (Alternative)
- AWQ (Activation-aware Weight Quantization) INT4 format
- Community quants available (e.g., `cyankiwi/Qwen3.5-35B-A3B-AWQ-4bit`)
- Better vLLM kernel support, but lower quality than NVFP4

### Memory and Context Flags

#### `--gpu-memory-utilization 0.85`
- Reserves 85% of unified memory for vLLM
- DGX Spark has 128GB unified memory (CPU+GPU shared)
- Conservative value prevents OOM during KV cache allocation

#### `--max-model-len 262144` vs `131072`
- **Safe path (Marlin)**: Can handle 262K context due to stable memory management
- **Native FP4 path**: Reduce to 131K during testing due to SMEM pressure

#### `--max-num-seqs 5` vs `2`
- **Safe path**: 5 concurrent sequences stable at ~189 tok/s
- **Native FP4 path**: Start with 2 due to NaN cascade risk under concurrency

### Backend Selection Flags

#### `--attention-backend flashinfer`
- Uses FlashInfer attention kernels optimized for Blackwell
- Alternatives: `triton_attn`, `flash_attn`
- FlashInfer preferred for DGX Spark due to SM121-specific optimizations

#### `--moe-backend marlin` vs `flashinfer_cutlass`
- **Marlin**: Dequantizes FP4→BF16 on-the-fly, uses BF16 tensor cores
- **FlashInfer CUTLASS**: Uses native FP4 tensor cores directly (requires patches)

### Speculative Decoding Flags

#### `--speculative-config '{"method":"mtp","num_speculative_tokens":2}'`
- MTP (Multi-Token Prediction) uses model's own draft head
- **Safe path**: 2-3 tokens, `moe_backend: triton`
- **Native FP4 path**: Can attempt 3 tokens, `moe_backend: flashinfer_cutlass`

---

## Part III: Attention Backends

### FLASHINFER (Recommended for DGX Spark)

**Architecture**: Custom CUDA kernels with SM121-specific optimizations

**Strengths**:
- Native support for FP8 KV cache
- FlashInfer CuteDSL fused attention for SM12x
- PageAttention v2 implementation
- Prefix caching support

**Weaknesses**:
- JIT compilation hangs if `FLASHINFER_CUDA_ARCH_LIST` not set to `12.1f`
- Some FP4 kernels missing PTX instructions

**Performance**: Best-in-class for DGX Spark when properly configured

**Configuration**:
```yaml
environment:
  VLLM_ATTENTION_BACKEND: FLASHINFER
  FLASHINFER_CUDA_ARCH_LIST: "12.1f"
```

### TRITON_ATTN

**Architecture**: OpenAI Triton kernels (Python-based GPU programming)

**Strengths**:
- Easier to debug and modify
- No JIT compilation issues
- Good fallback when FlashInfer fails

**Weaknesses**:
- 10-15% slower than FlashInfer on Blackwell
- Less optimized for SM121 memory hierarchy

**When to use**: Debugging, or when FlashInfer causes illegal instruction errors

### FLASH_ATTN (FlashAttention-2)

**Architecture**: Tri Dao's FlashAttention implementation

**Strengths**:
- Battle-tested, widely used
- Good general-purpose performance

**Weaknesses**:
- Not optimized for SM121
- Missing DGX Spark-specific optimizations
- No FP8 KV cache support in older versions

**When to use**: Compatibility testing, or if FlashInfer/TRITON both fail

---

## Part IV: MoE Backends

### Marlin (Safe Path - NVIDIA Recommended)

**Architecture**: W4A16 dequantize-then-GEMV kernel

**Execution Pipeline**:
```
[NVFP4 Weights] → [Dequantize to BF16] → [BF16 Tensor Cores]
```

**Strengths**:
- Rock-solid stability under concurrent load
- No NaN cascades
- Officially supported by NVIDIA
- ~189 tok/s at 4 concurrent requests

**Weaknesses**:
- Doesn't use native FP4 tensor cores
- Higher memory bandwidth usage (dequantization overhead)
- Single-stream latency ~60 tok/s

**When to use**: Production workloads, multi-hour sustained testing, high-concurrency batch jobs

**Configuration**:
```yaml
environment:
  VLLM_USE_FLASHINFER_MOE_FP4: "0"
command:
  - "--moe-backend"
  - "marlin"
```

### FlashInfer CUTLASS (Bleeding Edge - Avarok Path)

**Architecture**: Native FP4 tensor core execution with software E2M1 patch

**Execution Pipeline**:
```
[NVFP4 Weights] → [Software E2M1 Conversion] → [Native FP4 Tensor Cores]
```

**Strengths**:
- Direct FP4 tensor core utilization
- ~65-75 tok/s single-stream (10-20% faster than Marlin)
- ~9 GiB memory savings from 2:4 structured sparsity
- Up to 111 tok/s with MTP speculative decoding

**Weaknesses**:
- NaN cascades under concurrent load (March 2026 bug)
- Illegal instruction errors if not patched correctly
- SMEM miscalculations on SM121
- Not suitable for production

**When to use**: Latency-sensitive interactive applications, benchmarking, research

**Configuration**:
```yaml
environment:
  VLLM_USE_FLASHINFER_MOE_FP4: "1"
  VLLM_NVFP4_GEMM_BACKEND: cutlass
  FLASHINFER_CUDA_ARCH_LIST: "12.1f"
command:
  - "--moe-backend"
  - "flashinfer_cutlass"
```

### FlashInfer TRTLLM

**Architecture**: TensorRT-LLM optimized MoE kernels

**Strengths**:
- Highly optimized for data center Blackwell (SM100)
- Excellent throughput on B200/H100

**Weaknesses**:
- Not optimized for SM121
- May fall back to emulation on DGX Spark
- Limited documentation for Spark deployment

**When to use**: If you have a data center Blackwell GPU, not recommended for DGX Spark

### TRITON (Unquantized)

**Architecture**: OpenAI Triton MoE kernels

**Strengths**:
- Easy to debug
- No quantization-specific issues
- Good fallback option

**Weaknesses**:
- 20-30% slower than Marlin/CUTLASS
- Doesn't leverage FP4 quantization benefits
- Higher memory usage

**When to use**: Debugging MoE routing issues, or when other backends fail

**Note**: Your logs show `Using TRITON Unquantized MoE backend` - this suggests vLLM fell back to unquantized execution, which is suboptimal. Check your `--quantization` flag.

### BATCHED_TRITON

**Architecture**: Batched variant of TRITON MoE for better throughput

**Strengths**:
- Better batching efficiency than standard TRITON
- Good for high-concurrency workloads

**Weaknesses**:
- Still unquantized (no FP4 benefits)
- Not optimized for SM121

**When to use**: High-concurrency workloads where TRITON is the only working backend

---

## Part V: Environment Variables Deep Dive

### Critical for DGX Spark

#### `CUTE_DSL_ARCH=sm_121a`
- Tells CuteDSL (CUDA Template DSL) to compile for SM12.1a
- Without this, kernels compile for SM12.0 and may use missing PTX instructions
- **Mandatory** for all DGX Spark deployments

#### `FLASHINFER_CUDA_ARCH_LIST=12.1f`
- Forces FlashInfer JIT compilation for SM12.1f (FP4 variant)
- Without this, FlashInfer defaults to SM12.0, causing illegal instruction errors
- **Critical** for native FP4 path

#### `VLLM_USE_FLASHINFER_MOE_FP4=0` vs `1`
- `0`: Disables native FP4 MoE, forces Marlin fallback (safe path)
- `1`: Enables native FP4 MoE execution (bleeding edge path)

#### `VLLM_NVFP4_GEMM_BACKEND=cutlass` vs `marlin`
- `cutlass`: Uses CUTLASS FP4 GEMM kernels (requires patches)
- `marlin`: Uses Marlin dequantize-then-compute (stable)

### Performance Tuning

#### `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`
- Enables PyTorch's expandable memory segments
- Reduces memory fragmentation during long-running inference
- Recommended for all deployments

#### `VLLM_ENABLE_CUDA_GRAPH=1`
- Enables CUDA graphs for kernel launch optimization
- Reduces CPU overhead for repeated kernel launches
- Avarok optimization, not in NVIDIA's official recommendations

#### `VLLM_GC_DISABLE=1`
- Disables Python garbage collection during inference
- Reduces latency spikes from GC pauses
- Use with caution - may increase memory usage

---

## Part VI: Deployment Decision Framework

### Choose NVIDIA Safe Path (Marlin) When:
- ✅ Production workloads requiring 24/7 stability
- ✅ Multi-hour sustained testing
- ✅ High-concurrency batch jobs (4+ concurrent requests)
- ✅ Enterprise compliance requirements
- ✅ No tolerance for NaN crashes or illegal instruction errors

**Expected Performance**:
- Single-stream: ~60 tok/s
- 4 concurrent: ~189 tok/s
- Stability: Rock-solid
- Memory: Baseline

### Choose Avarok Bleeding Edge (Native FP4) When:
- ✅ Latency-sensitive interactive applications
- ✅ Single-stream performance is critical
- ✅ Willing to accept stability risks
- ✅ Running benchmarks or research
- ✅ Can tolerate occasional crashes

**Expected Performance**:
- Single-stream: ~65-75 tok/s
- Peak with MTP: ~111 tok/s
- Stability: Risk of NaN cascades
- Memory: ~9 GiB savings

### Testing Protocol for Native FP4 Path

1. **Phase 1: Single-Stream Baseline**
   ```yaml
   --max-num-seqs 1
   --max-model-len 65536
   ```
   Run for 1 hour, monitor for crashes

2. **Phase 2: Low Concurrency**
   ```yaml
   --max-num-seqs 2
   --max-model-len 131072
   ```
   Run for 4 hours, check for NaN errors

3. **Phase 3: Production-Like Load**
   ```yaml
   --max-num-seqs 4
   --max-model-len 262144
   ```
   Only if Phases 1-2 pass

---

## Part VII: Troubleshooting Common Issues

### Illegal Instruction (SIGILL) Core Dump

**Symptoms**:
```
Illegal instruction (core dumped)
```

**Cause**: FlashInfer JIT-compiled kernels for SM12.0 instead of SM12.1

**Fix**:
```yaml
environment:
  FLASHINFER_CUDA_ARCH_LIST: "12.1f"
  CUTE_DSL_ARCH: sm_121a
```

### NaN Hidden States Under Load

**Symptoms**:
```
RuntimeError: CUDA error: device-side assert triggered
NaN detected in hidden states
```

**Cause**: Race conditions in CUTLASS SMEM allocation under concurrent load

**Fix**:
- Reduce `--max-num-seqs` to 2
- Reduce `--max-model-len` to 131072
- Fall back to Marlin backend if issue persists

### Invalid Quantization Architecture

**Symptoms**:
```
ValueError: Invalid quantization architecture: modelopt
```

**Cause**: Using `--quantization modelopt` instead of `modelopt_fp4`

**Fix**:
```yaml
command:
  - "--quantization"
  - "modelopt_fp4"
```

### Out of Memory (OOM) During KV Cache Allocation

**Symptoms**:
```
torch.cuda.OutOfMemoryError: CUDA out of memory
```

**Cause**: `--gpu-memory-utilization` too high, or context length too large

**Fix**:
- Reduce `--gpu-memory-utilization` to 0.75
- Reduce `--max-model-len` to 131072
- Reduce `--max-num-seqs`

### MTP Speculative Decoding Fails

**Symptoms**:
```
WARNING: MTP speculative decoding disabled due to backend incompatibility
```

**Cause**: MTP backend mismatch with MoE backend

**Fix**:
```yaml
command:
  - "--speculative-config"
  - '{"method":"mtp","num_speculative_tokens":2,"moe_backend":"flashinfer_cutlass"}'
```

---

## Part VIII: Performance Benchmarking Methodology

### Single-Stream Latency Test

```bash
# Generate 1000 tokens, measure time-to-first-token (TTFT) and tokens/second
curl -X POST "http://localhost:8000/v1/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "qwen3.6-35b",
    "prompt": "Write a 1000-word essay on artificial intelligence.",
    "max_tokens": 1000,
    "temperature": 0.7
  }'
```

### Multi-Request Throughput Test

```python
import asyncio
import aiohttp
import time

async def generate_request(session, i):
    async with session.post(
        "http://localhost:8000/v1/completions",
        json={
            "model": "qwen3.6-35b",
            "prompt": f"Request {i}: Explain quantum computing.",
            "max_tokens": 500
        }
    ) as resp:
        return await resp.json()

async def main():
    async with aiohttp.ClientSession() as session:
        tasks = [generate_request(session, i) for i in range(10)]
        start = time.time()
        results = await asyncio.gather(*tasks)
        elapsed = time.time() - start
        print(f"10 requests in {elapsed:.2f}s = {10/elapsed:.2f} req/s")

asyncio.run(main())
```

### Context Length Scaling Test

```bash
# Test with increasing context lengths
for LEN in 8192 16384 32768 65536 131072 262144; do
  echo "Testing max-model-len=$LEN"
  curl -X POST "http://localhost:8000/v1/completions" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"qwen3.6-35b\",
      \"prompt\": \"$(python -c "print('A' * $LEN)")",
      \"max_tokens\": 100
    }"
done
```

---

## Part IX: Conclusion and Recommendations

### For Production Deployment

**Use NVIDIA Safe Path**:
- Image: `vllm/vllm-openai:nightly` or official NVIDIA container
- Backend: `--moe-backend marlin`
- Environment: `VLLM_USE_FLASHINFER_MOE_FP4=0`
- Concurrency: 4-5 concurrent requests
- Context: 262144 tokens

**Expected Performance**: ~189 tok/s at 4 concurrent requests, rock-solid stability

### For Research and Development

**Test Avarok Bleeding Edge**:
- Image: `avarok/dgx-vllm-nvfp4-kernel:v75`
- Backend: `--moe-backend flashinfer_cutlass`
- Environment: `VLLM_USE_FLASHINFER_MOE_FP4=1`, `FLASHINFER_CUDA_ARCH_LIST=12.1f`
- Concurrency: Start with 2, increase cautiously
- Context: Start with 131072, increase if stable

**Expected Performance**: ~65-75 tok/s single-stream, up to 111 tok/s with MTP, risk of NaN cascades

### Final Recommendation

Given your current setup achieving ~189 tok/s at 4 concurrent requests with the Marlin backend, **stick with the NVIDIA safe path for production workloads**. The stability and official support outweigh the 10-20% single-stream performance gains from native FP4.

However, if you're developing latency-sensitive interactive applications where single-stream TTFT is critical, **test the Avarok path in a non-production environment** using the phased testing protocol outlined above.

The DGX Spark's unified memory architecture and SM12.1a quirks make it a unique platform that requires careful configuration. Both paths have their place - the key is matching the deployment strategy to your workload requirements.

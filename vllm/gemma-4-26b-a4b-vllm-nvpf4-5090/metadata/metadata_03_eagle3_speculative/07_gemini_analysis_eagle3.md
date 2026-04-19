# Gemini 3 Analysis: Speculative EAGLE-3 Support for Gemma-4

### 1. The Root Cause: Structured CLI Migration
The `unrecognized arguments` error is a result of vLLM's transition to **Structured Configurations**. In the current `nightly` build, advanced features like speculative decoding have been moved under the `--speculative-config` namespace. The previous flat flags (e.g., `--speculative-model`) are no longer recognized by the `serve` parser.

**The Fix:** Use dot-notation for nested JSON keys:
- `--speculative-config.model RedHatAI/gemma-4-26B-A4B-it-speculator.eagle3`
- `--speculative-config.num_speculative_tokens 3`

### 2. The Architectural Hurdle: Heterogeneous Head Dimensions
Gemma-4 is a complex model with **head_dim=256** and **global_head_dim=512**. 
- **The Conflict:** Your logs show vLLM forcing the `TRITON_ATTN` backend to handle these dimensions safely. 
- **The Speculator Gap:** EAGLE-3 is an architectural speculator that needs to stay "in-sync" with the attention kernels. In the current `nightly`, the high-speed `FLASHINFER` backend is often required for EAGLE, but it is being blocked by Gemma-4's head dimension requirement.

### 3. VRAM Constraint Audit
- **Weights:** ~13.5 GB (Base) + ~1 GB (Speculator).
- **KV Cache (96K):** ~9.5 GB.
- **Speculative Overhead:** ~1-2 GB for lookahead slots and draft states.
- **Total:** ~25.5 GB.
At **0.80 utilization (25.6 GB)**, you are at the absolute limit. Any attempt to run EAGLE-3 with a 96K context will likely require dropping utilization to **0.85** or reducing context to **64K** to prevent a "Warmup Phase" crash.

### Verdict
The current configuration is failing because of **CLI syntax** (Structured Config) and potentially an **Attention Backend conflict** (Triton vs. FlashInfer for heterogeneous heads). 

**Recommendation:** Try the Structured CLI syntax first. If it still crashes, it confirms that the Triton Attention forced by Gemma-4 is currently incompatible with the EAGLE-3 implementation in this `nightly` build.

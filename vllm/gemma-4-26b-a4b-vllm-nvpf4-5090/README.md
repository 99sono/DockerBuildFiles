# Gemma 4 26B-A4B - RTX 5090 High-Context Setup

This setup is optimized for the **RTX 5090 (32GB VRAM)** using the stable **vLLM v0.19.1+** engine. It represents the successful pivot from the "Blue Whale" (Qwen 3.6 35B) to the high-performance Gemma 4 architecture.

## The VRAM Recovery
After hitting a physical VRAM dead-end with Qwen 3.6, this project reclaimed its capabilities by switching to **Gemma 4 26B-A4B**.
- **Static Tax Reduced:** The weight footprint dropped from 22GB to ~13GB, reclaiming 9GB of VRAM.
- **Context Breakthrough:** This reduction allowed the context window to expand from an unusable 8K to a **stable 96K (98,304 tokens)** while maintaining a strict **80% VRAM utilization limit**.
- **Engine:** Powered by vLLM **v0.19.1+** for native Gemma 4 MoE support and stable Blackwell SM 12.0 kernel acceleration.

## Hardware Optimization
- **Native FP4:** Uses `NVFP4` weights + activations via Red Hat AI.
- **Blackwell Path:** Leveraging `flashinfer_cutlass` for maximum throughput on the 5090 (estimated 250+ tokens/sec).
- **Stability:** Strict 20% headroom (0.80 utilization) ensures the host OS and WSL2 remain responsive.

## Quick Start
1. **Prepare Host Environment:**
   ```bash
   chmod +x *.sh
   ./00_a_pull_vllm_image.sh
   ./00_b_create_conda_env.sh
   ./00_c_install_packages.sh
   ```
2. **Pre-download Model:**
   ```bash
   ./00_d_pre_download_model.sh
   ```
3. **Launch Server:**
   ```bash
   ./01_up.sh
   ```

## Testing
Verify the 96K context capacity and reasoning performance:
```bash
conda activate testVllmGemma
python 04_test_vllm_curl.py
```

## API Access
- **Endpoint:** `http://localhost:8000/v1`
- **Model Name:** `gemma-4-26b-it-nvfp4`
- **Reasoning:** Native `<thought>` block parsing enabled.

## Connecting Cline to vLLM

To connect your local **Cline** extension to your **vLLM** server (Gemma-4-26B), you need to change the **API Provider** in your settings.

Currently, your screenshot shows you are using the "Ollama" provider. While vLLM is OpenAI-compatible, Cline has a specific **"OpenAI Compatible"** provider setting that works best for vLLM's endpoint.

### Suggested Settings:

1.  **API Provider**: Change this to **`OpenAI Compatible`**.
2.  **Base URL**: Set this to **`http://localhost:8000/v1`**.
    * *Note: vLLM usually expects the `/v1` suffix for the OpenAI-compatible routes.*
3.  **API Key**: You **MUST** enter a dummy value (e.g., `vllm-token`). Leaving this field empty will cause authentication errors in Cline.
4.  **Model ID**: Enter the model name exactly as it appears in your logs: **`gemma-4-26b-it-nvfp4`**.
5.  **Model Context Window**: Keep it at **`98304`** to match your vLLM configuration.

---

### Why this is better than the "Ollama" provider:
* **Protocol**: vLLM implements the `/v1/chat/completions` endpoint. The Ollama provider in Cline specifically looks for Ollama’s own API format (port 11434).
* **Tool Calling**: The "OpenAI Compatible" mode allows Cline to use the specialized `gemma4` reasoning and tool parsers you set up in your Docker command.

### Troubleshooting Tip:
If Cline still says "Unable to fetch models," it is because vLLM does not always broadcast its model list in a way every extension expects. Since you know the ID is `gemma-4-26b-it-nvfp4`, simply typing it into the **Model ID** field manually after selecting **OpenAI Compatible** will bypass the fetch error and allow you to start chatting.

# Nemotron-Cascade-2-30B-A3B-NVFP4 (vLLM)

This directory contains a configured environment to run the [Nemotron-Cascade-2-30B-A3B-NVFP4](https://huggingface.co/chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4) model using [vLLM](https://github.com/vllm-project/vllm).

## Overview

This setup leverages vLLM's ability to run high-performance inference. It utilizes **TurboQuant** for the KV cache to optimize memory usage and performance.

## Configuration

The main configuration is located in `docker-compose.yml`.

### Docker Compose Options

- `HF_MODEL`: The HuggingFace model path.
- `--kv-cache-dtype turbo`: Enables TurboQuant quantization for the KV cache. This is recommended for balancing memory footprint and performance.
- `--max-model-len`: Sets the maximum sequence length (context window). The default is `32768`.

### KV Cache Sizing Strategies

The KV cache size is determined by the `max-model-len` parameter.

- **Small (Default)**: `32768` (32k). Generally fits on most modern high-end GPUs.
- **Large/Experimental**: `262144` (256k).
  - *Warning*: Setting a 256k context length requires substantial GPU VRAM. It may cause Out-Of-Memory (OOM) errors on consumer-grade GPUs, including the RTX 5090, depending on hardware constraints and quantization settings.

## Official vLLM Command

The container executes the following command internally:

```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4 \
  --kv-cache-dtype turbo \
  --max-model-len 32768 \
  --trust-remote-code
```

## Testing

Use the provided `04_test_vllm_curl.sh` script to test the model. You can modify `test/test_file_01_prompt.md` to change your input prompts and observe performance under different context lengths.

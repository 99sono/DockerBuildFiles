
## TL;DR  
* **TriAttention *is* being loaded and the engine really uses the **TRITON_ATTN** backend** – you can see the line `Using AttentionBackendEnum.TRITON_ATTN backend` right after the model is instantiated.  
* **The “compression” part of the plugin is not being exercised**, because the plugin never sees a KV‑cache size that exceeds its **runtime budget** (4096 tokens) and – more importantly – the model that the engine thinks it is loading is **Qwen/Qwen3‑0.6B**, not the *Nemotron‑Cascade* you asked for. The plugin only activates its trigonometric compression for a handful of architectures (Llama‑2/3, Mistral, Mixtral, etc.). Since Qwen‑3 is not on that whitelist the plugin simply falls back to vanilla Triton kernels, so you never get a “budget exceeded / compressing KV cache” message.  

The good news: the plumbing (Dockerfile + compose + environment variables) is correct. The missing piece is **making the plugin see the right model and a long enough prompt**. Below is a step‑by‑step checklist, a few “quick‑wins” you can try right now, and a longer‑term strategy to guarantee that TriAttention actually compresses the KV cache.

---

## 1️⃣ What the logs already tell us  

| Log excerpt | What it means |
|------------|----------------|
| `Loading plugin triattention` | The plugin was discovered by vLLM’s entry‑point system and `register_triattention_backend` was called. |
| `Using AttentionBackendEnum.TRITON_ATTN backend` | vLLM selected the Triton‑based attention implementation (the one the plugin patches). |
| `model Qwen/Qwen3-0.6B` / `Resolved architecture: Qwen3ForCausalLM` | The engine thinks the model is the **tiny Qwen3‑0.6B** checkpoint, *not* the 30‑B Nemotron you asked for. |
| `GPU KV cache size: 235,648 tokens` (≈ 25 GiB) | The KV cache is already huge – but it was allocated for a **30 B model** with a max length of 262 144, not for the 0.6 B model you are actually running. |
| No “budget exceeded / compressing KV cache” line, no `TRIATTN`‑specific JIT messages | The plugin never needed to compress – it fell back to the regular Triton kernels. |

**Bottom line:** The plugin is there, the backend is correct, but **the plugin does not know *which* model it is handling** and it does not see a KV‑cache size above its default budget (4096). Hence you never see the trigonometric compression.

---

## 2️⃣ Why the “wrong” model appears  

1. **Model name resolution** – `--model` (or `model_tag`) points to `chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4`.  
   *The engine will first try to resolve a *local* checkpoint name.* If the checkpoint does not contain a `model_type` it can recognise, vLLM falls back to the *default* model class for the *first* model it can load – in your case the Qwen3‑0.6B checkpoint that happens to be present in the cache.  

2. **Plugin registration is architecture‑aware** – `triattention` registers “compression hooks” for a whitelist of model classes (`LlamaForCausalLM`, `MistralForCausalLM`, `MixtralForCausalLM`, etc.). It does **not** contain a custom `Qwen3ForCausalLM` implementation, so even if the engine loads the 30 B checkpoint, the plugin will silently bypass compression.

3. **The handshake prints both** – you see the *handshake* line `model='Qwen/Qwen3-0.6B'` *and* the *API* line `served_model_name=chankhavu/...`. The engine is **still loading the 0.6 B model** while the API server advertises the 30 B name. This mismatch explains why you never see a 30 B KV‑cache size (it is 25 GiB because the 30 B weights are not actually resident; the 0.6 B weights are).

### Quick check you can run in the container

```bash
python - <<'PY'
import torch, transformers, vllm
print("torch.cuda.get_device_name():", torch.cuda.get_device_name(0))
print("Transformers config:", transformers.AutoConfig.from_pretrained("chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"))
print("vLLM engine class:", vllm.model_executor.models.registry.get_model_class())
PY
```

If you get “Qwen3ForCausalLM” printed, you are still loading the wrong checkpoint.

---

## 3️⃣ How to *force* the correct model and trigger compression  

### 3.1 Make vLLM load the **exact** checkpoint you intend

Add **both** `--model` *and* `--served-model-name` **as separate CLI arguments** (the way you already have them) **and** make sure the container has *only* that checkpoint in its HF cache. Remove any other model folders (e.g. `Qwen/Qwen3-0.6B`) from `~/.cache/huggingface/hub` before starting the container.

```yaml
environment:
  - HF_HUB_ENABLE_HF_TRANSFER=1   # speeds up download
  - HF_DATASETS_OFFLINE=1         # avoid accidental pulls
  - TRANSFORMERS_CACHE=/root/.cache/huggingface/transformers
  - HF_HOME=/root/.cache/huggingface   # make sure the plugin uses the same cache
```

Then start with:

```bash
docker compose up --build
```

You should see in the **engine** log:

```
Loading checkpoint: chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4
Resolved architecture: NemotronCascadeForCausalLM
```

If you still see `Qwen3ForCausalLM`, the checkpoint is not being found and the fallback is being used.

### 3.2 Raise the **KV‑budget** and force a “real” long context

The plugin’s default budget is `TRIATTN_RUNTIME_KV_BUDGET=4096`. With a 30 B model you will quickly exceed that when you request a few thousand tokens. To make sure the plugin *does* compress:

1. **Increase the budget** to something realistic for your workload, e.g.:

   ```yaml
   - TRIATTN_RUNTIME_KV_BUDGET=16384   # 16 k tokens is safe for a 30 B model
   ```

2. **Generate a prompt longer than the budget** – a quick way is to feed a 10 k‑token text file:

   ```bash
   # Example: concatenate the first 10k lines of a Wikipedia dump
   for i in {1..1000}; do cat huge.txt >> long_prompt.txt; done
   curl -X POST http://localhost:8000/v1/chat/completions \
        -d @prompt.json   # prompt.json contains {"messages":[{"role":"user","content":"<long_prompt>"}]}
   ```

   The request should now take **several seconds** (the model has to do KV‑cache compression) and you will see log lines like:

   ```
   [triattention] KV cache size 12345 > budget 16384 → compressing with trigonometric kernel
   [triattention] JIT compiled triattention kernel for seq_len=12345
   ```

   If you still do not see anything, increase `TRIATTN_RUNTIME_PROTECT_PREFILL` to `false` (the plugin will then compress *even during the prefill*).

3. **Watch the memory** – after the request finishes, the **GPU KV cache usage** should stay roughly constant (≈ 25 GiB for 30 B) while the *torch* memory should not keep growing linearly. The log line:

   ```
   INFO  … GPU KV cache size: 12345 tokens
   ```

   followed by something like:

   ```
   INFO  … TrigAttn: compressed 8 500 tokens, saved ~2.3 GiB
   ```

   is the signature that compression really happened.

### 3.3 Verify the plugin is *actually* handling Qwen‑3 (optional)

If you want to keep using the Qwen‑3 architecture (it is a valid model class), you can **extend the plugin**:

* Fork `triattention` and add a `register_qwen3_backend` function that mirrors the `Llama` or `Mistral` registration.  
* Add `TRIATTN_MODEL_CLASS_MAP["Qwen3ForCausalLM"] = "triattention.ops.triton_qwen3"` in `triattention/__init__.py`.  

Then rebuild the image and bump the `VLLM_PLUGINS` entry. This is the cleanest long‑term approach if you plan to serve many Qwen‑3 variants.

---

## 4️⃣ Docker‑file & compose “gotchas” you should clean up  

| Issue | Why it matters | Fix |
|-------|----------------|-----|
| `ENV VLLM_FLASH_ATTN_VERSION=2` | This is only relevant for the **FlashAttention** backend, which you have disabled. It does nothing for TriAttention, but it can confuse the auto‑detector. | Remove it (or set it to `0` if you want the fallback). |
| `ENV TORCH_CUDA_ARCH_LIST="12.0"` | Blackwell GPUs are `sm_90` (12.0 is a *future* arch). Torch will compile kernels for **both** 9.0 and 12.0; the extra arch does not hurt but is unnecessary. | Set `TORCH_CUDA_ARCH_LIST="9.0"` (or `"9.0;12.0"` if you want both). |
| `ENV TRIATTN_RUNTIME_PROTECT_PREFILL=true` | When `true` the plugin *only* compresses *after* a prefill (i.e. after the first 4096 tokens). For a 103‑token request it never kicks in. | Set to `false` for a quick test; you can keep it `true` for production (the plugin will still compress later). |
| `ipc: host` + `deploy.resources.reservations.devices` – WSL2 NVIDIA driver | `ipc: host` works, but the `deploy.resources` block is ignored in a *non‑Swarm* compose file (it only works with `docker stack`). | You can safely drop the `deploy:` section; the GPU will be allocated automatically because you have `platform: linux/amd64` and the container runs with `--gpus all`. |
| `TRIATTN_VERBOSE=1` | Gives you a handful of debug lines, but for a *real* long request you want the *full* verbosity: `TRIATTN_VERBOSE=2`. | Change to `TRIATTN_VERBOSE=2` for the next test run. |
| `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` | You are already using `max-model-len=262144`. The flag is only needed if you want to *override* the derived max length (e.g. 40k → 262k). Keeping it on does no harm, but it’s not required. | Optional – you can drop it. |

---

## 5️⃣ A minimal, “working‑out‑of‑the‑box” test for you  

Create a **single‑file Docker Compose** that eliminates all optional variables and forces the 30 B model:

```yaml
services:
  triattn:
    image: vllm-triattention:1.0.0
    command:
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--attention-backend"
      - "TRITON_ATTN"
      - "--max-model-len"
      - "262144"
      - "--gpu-memory-utilization"
      - "0.85"
      - "--enforce-eager"
      - "--trust-remote-code"
      - "--served-model-name"
      - "chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4"
      - "--max-num-batched-tokens"
      - "1024"
      - "--triattn-runtime-kv-budget"
      - "16384"
      - "--triattn-verbose"
      - "2"
    environment:
      - TRIATTN_ENABLE=true
      - TRIATTN_RUNTIME_KV_BUDGET=16384
      - TRIATTN_RUNTIME_PROTECT_PREFILL=false
      - TRIATTN_VERBOSE=2
      - VLLM_ALLOW_LONG_MAX_MODEL_LEN=1
    ports: ["8000:8000"]
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - ~/.cache/triattention:/root/.cache/triattention
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Run:

```bash
docker compose up --build
```

Then fire a 10k‑token prompt (you can use a file of 10 k lines of dummy text). You should see in the engine logs:

```
[TriAttention] KV cache size 12345 > budget 16384 → compressing KV cache
[TriAttention] JIT compiled triattention kernel for seq_len=12345
...
INFO  ... GPU KV cache size: 12345 tokens (≈ 23 GiB)
```

If you see those lines, you have **proof** that:

* The plugin is *registered* for the correct model class.  
* The KV cache is *compressed* (the JIT kernel is the trigonometric one, not the generic Triton kernel).  

---

## 6️⃣ Summary & Action Items  

| ✅ What you already have right | ❌ What is still missing |
|------------------------------|--------------------------|
| *Dockerfile* correctly installs `triattention` and sets `TRIATTN_ENABLE`. | **Wrong model class** – the engine is loading `Qwen3ForCausalLM` (0.6 B) instead of the intended `NemotronCascadeForCausalLM`. |
| `VLLM_PLUGINS=triattention` and `TRIATTN_RUNTIME_KV_BUDGET=4096` are present. | **Budget too low** for any realistic 30 B request; the plugin never sees a “budget exceeded” condition. |
| `TRIATTN_VERBOSE=1` gives some debug output. | **Verbosity insufficient** – you need `TRIATTN_VERBOSE=2` to see kernel JIT messages. |
| You have a **GPU** and the Triton backend is being used. | **No evidence** that the *triattention* kernel is actually being compiled. |

### Immediate next steps

1. **Purge the HF cache** of any Qwen3‑0.6B checkpoint and **re‑build** the image.  
2. **Add** `TRIATTN_RUNTIME_KV_BUDGET=16384` (or larger) **and** `TRIATTN_RUNTIME_PROTECT_PREFILL=false`.  
3. **Set** `TRIATTN_VERBOSE=2`.  
4. **Send a ~10 k‑token prompt** (or use a script that streams a 10 k‑token string).  
5. **Watch for** the “KV cache size X > budget Y → compressing KV cache” line and for the JIT‑compiled kernel name `triattention_triton_attn`.  

If after step 4 you still see *only* the generic Triton kernel (`triton_attn`), then the plugin is **not aware** of the model class. In that case you have two options:

* **Option A – Keep the 0.6 B model** and treat it as a *benchmark* for TriAttention. It will still compress KV cache (just for a smaller model).  
* **Option B – Add Qwen‑3 support to the plugin** (see the “optional” section above) and re‑run the long‑prompt test.

---

## 7️⃣ TL;DR Checklist for a “TriAttention‑compressed” deployment

1. **Model checkpoint only** – make sure the container sees the *exact* 30 B Nemotron checkpoint and *nothing else*.  
2. **Set KV‑budget high enough** (`TRIATTN_RUNTIME_KV_BUDGET >= 8192` for 30 B).  
3. **Turn off prefill protection** (`TRIATTN_RUNTIME_PROTECT_PREFILL=false`) for quick testing.  
4. **Enable full verbose** (`TRIATTN_VERBOSE=2`).  
5. **Run a long request** (> budget).  
6. **Look for**:  
   * `KV cache size X > budget Y → compressing`  
   * `JIT compiled triattention kernel` (kernel name contains `triattention_triton_attn`).  
   * The memory graph: *KV cache stays flat* while *torch memory does not keep climbing*.  

When you see those three things, you have **proved** that TriAttention is *actively* compressing the KV cache on your Blackwell RTX 5090 under WSL2.

---

### Final note from “Cascade 2”

> *You’ve already built a solid foundation – the plugin loads, the backend is right, and your hardware is happy. The only thing standing between you and a **real, measurable compression gain** is the **model‑to‑plugin handshake** and a **prompt long enough to trigger the budget**. Fix the checkpoint path, raise the budget, and send a 10k‑token request. You’ll see the JIT kernels appear in the logs, the KV‑cache size will plateau, and you’ll finally get the speed‑up that TriAttention promises on a 30 B model.*  

Happy compressing, and let me know the numbers once you have a 10k‑token run – I’ll be happy to help you interpret the memory‑saving statistics! 🚀
## How Cline connects to a local model
Cline supports three backend types:

- **Ollama** (local llama.cpp models)
- **LM Studio** (local vLLM‑like server)
- **OpenAI‑compatible API** (any model served via `/v1/chat/completions`)

Your vLLM container exposes:

```
http://localhost:8000/v1/chat/completions
```

This is exactly the interface Cline expects when you choose:

**Provider: “OpenAI Compatible”**

---

## What you configure inside Cline
In Cline’s settings:

### 1. Provider  
Choose: **OpenAI Compatible**

### 2. API Base URL  
Set:

```
http://localhost:8000/v1
```

### 3. API Key  
vLLM does **not** require a key, but Cline requires a non‑empty field.  
You can enter anything, for example:

```
dummy
```

### 4. Model name  
Run:

```
curl http://localhost:8000/v1/models
```

You’ll get something like:

```
{
  "data": [
    { "id": "nemotron" }
  ]
}
```

Use that `"id"` value in Cline’s “Model” field.

---

## Why this works
vLLM automatically exposes:

- `/v1/chat/completions`
- `/v1/completions`
- `/v1/models`

…using the same schema as OpenAI’s API.  
Cline is built to talk to exactly this interface.

So from Cline’s perspective, your Nemotron container *is* an OpenAI‑style LLM server.

---

## What to expect in practice
### Strengths
- Much faster than Ollama for coding tasks  
- Supports long context windows  
- Handles multi‑turn agentic workflows well  
- Stable for large models like Nemotron‑30B  

### Limitations
- No built‑in function calling unless the model supports it  
- No automatic tool‑use unless the model is trained for it  
- Cline’s “agentic” behavior depends heavily on the model’s reasoning quality  

Nemotron‑30B FP4 is strong enough for coding assistance, but Qwen‑Coder or DeepSeek‑Coder models may feel more “agent‑like”.

---

## Quick checklist to ensure it works
- Container is running and reachable on `localhost:8000`
- GPU is visible inside the container (`nvidia-smi` works)
- `curl http://localhost:8000/v1/models` returns a model
- Cline is set to “OpenAI Compatible”
- Base URL is `http://localhost:8000/v1`
- API key is any non‑empty string
- Model name matches the ID returned by `/v1/models`

Once these are set, Cline will connect immediately.


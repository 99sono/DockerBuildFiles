# Multi-Agent Orchestration with OpenCode Task Sub-Agents

## Overview

OpenCode's Task tool enables a powerful pattern: a strong **orchestrator model** delegates work to specialized **sub-agents** running on different inference backends. This lets you pair a large, capable model on your local GPU (e.g., Qwen 27B on an RTX 5090) with a fast, batchable MOE model on a cluster node (e.g., Qwen 3.6 35B on DGX Spark).

The orchestrator plans, coordinates, and reviews — while the sub-agents do the heavy lifting in parallel, without overloading your local GPU.

---

## Why This Matters

Your RTX 5090 can only run **one session at a time** with a 27B model. Spawning multiple sub-requests would saturate it instantly. By delegating to a remote backend like DGX Spark (which supports concurrent batching), you get:

| Property | Local GPU (orchestrator) | Remote GPU (sub-agent) |
|---|---|---|
| Role | Planning, coordination, review | Parallel task execution |
| Concurrency | Single session | Batched sessions |
| Model | Large, capable (e.g. Qwen 27B) | Efficient MOE (e.g. Qwen 3.6 35B MoE) |

---

## Step 1 — Configure the Sub-Agent in `opencode.json`

Add an entry under `"agent"` for each sub-agent you want to use. This defines the model, description, and mode:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "local/qwen3.6-27b",
  "agent": {
    "dgx-spark": {
      "model": "dgx-spark/qwen3.6-35b",
      "description": "Lightweight mixture-of-experts model with fewer active parameters, optimized for batching multiple requests in parallel.",
      "mode": "subagent"
    }
  },
  "provider": {
    "dgx-spark": {
      "name": "DGX Spark",
      "options": {
        "baseURL": "https://spark-8ddc/v1",
        "apiKey": "dummy-key"
      },
      "models": {
        "qwen3.6-35b": {
          "name": "qwen3.6-35b",
          "limit": { "context": 100000, "output": 32768 }
        }
      }
    },
    "local": {
      "name": "local (RTX 5090)",
      "options": {
        "baseURL": "http://localhost:8000/v1",
        "apiKey": "dummy-key"
      },
      "models": {
        "qwen3.6-27b": {
          "name": "qwen3.6-27b",
          "limit": { "context": 131072, "output": 32768 }
        }
      }
    }
  }
}
```

**Key fields:**

- **`mode: "subagent"`** — Makes this agent available to the Task tool. Primary agents (`mode: "primary"`) are only for Tab-cycling in the TUI and are not spawnable.
- **`model`** — The fully qualified `provider/model-id` of the sub-agent's inference backend. This is what prevents it from inheriting your local model.
- **`description`** — Tells the orchestrator when to use this agent. The orchestrator reads this and decides if the task matches.

---

## Step 2 — Tell the Orchestrator Which Sub-Agent to Use

There are three ways to control sub-agent selection:

### A. Natural Language Instruction (simplest)

Just tell the orchestrator directly:

> "Spawn 4 parallel agents using **dgx-spark** as the sub-agent type. Each one should..."

The orchestrator will read your instruction and set `subagent_type: "dgx-spark"` in each Task tool call.

### B. Task Permissions (enforced)

If you want to **guarantee** the orchestrator can only spawn dgx-spark, add a task permission rule:

```json
{
  "agent": {
    "build": {
      "permission": {
        "task": {
          "*": "deny",
          "dgx-spark": "allow"
        }
      }
    }
  }
}
```

With this, the Task tool's description only shows `dgx-spark` as an option — all other sub-agents are hidden. Rules are evaluated in order; last matching rule wins, so put `*` first and your allow rules after.

### C. Agent Description (hint-based)

The orchestrator reads each sub-agent's `description` field and picks the best match for the task. A well-crafted description makes good choices without explicit instruction:

```json
"description": "Lightweight mixture-of-experts model, use for parallel tasks that can be batched"
```

---

## Step 3 — What Happens Under the Hood

When the orchestrator spawns sub-agents via the Task tool, it makes a structured tool call like this:

```
task(
  description = "Test subagent",
  prompt     = "Reply with just Hi I'm here — nothing else.",
  subagent_type = "dgx-spark"
)
```

Each concurrent Task call creates an independent session on the dgx-spark backend. The calls fire in parallel, and the orchestrator waits for all responses before proceeding.

### Hello World Example: 4 Parallel Sub-Agents

Here's exactly what the tool calls look like when spawning 4 agents at once:

```
task(description="Agent 1 test", prompt="Reply with just Hi, Agent 1 here!", subagent_type="dgx-spark")
task(description="Agent 2 test", prompt="Reply with just Hi, Agent 2 here!", subagent_type="dgx-spark")
task(description="Agent 3 test", prompt="Reply with just Hi, Agent 3 here!", subagent_type="dgx-spark")
task(description="Agent 4 test", prompt="Reply with just Hi, Agent 4 here!", subagent_type="dgx-spark")
```

All four calls execute in parallel on the DGX Spark backend. Each returns a result that the orchestrator reads before continuing:

```
→ Agent 1: "Hi, Agent 1 here!"
→ Agent 2: "Hi, Agent 2 here!"
→ Agent 3: "Hi, Agent 3 here!"
→ Agent 4: "Hi, Agent 4 here!"
```

---

## Inference Backend Comparison

During testing, we compared vLLM vs llama.cpp as the DGX Spark backend for concurrent sub-agent requests:

| Backend | Concurrent Requests | Result |
|---|---|---|
| **vLLM** (Qwen 3.6 35B PrismaQuant) | 4 parallel | Crashed with CUDA assertion (`indexSelectSmallIndex`) — engine died after 2/4 succeeded |
| **llama.cpp** (Qwen 3.6 35B, MTP speculation) | 4 parallel | All 4 completed successfully, ~17s total wall clock |

llama.cpp proved more resilient for batched multi-agent workloads on the Spark node. The key metrics from the llama.cpp run:

- **Slot 0** (Agent 1): 6531 tokens at 1594 tok/s prompt eval, 5.52 tok/s decode
- **Slot 1** (Agent 2): 6531 tokens at 792 tok/s prompt eval, 6.03 tok/s decode
- **Slot 2** (Agent 3): 6531 tokens at 511 tok/s prompt eval, 10.21 tok/s decode
- **Slot 3** (Agent 4): 6531 tokens at 380 tok/s prompt eval, 52.66 tok/s decode
- **Draft acceptance**: 95-100% across all slots (MTP speculation working well)

---

## Advanced: Multiple Sub-Agents with Different Specializations

You can define multiple sub-agents and let the orchestrator choose based on the task, or enforce via permissions:

```json
{
  "agent": {
    "dgx-spark-fast": {
      "model": "dgx-spark/qwen3.6-35b",
      "description": "Fast MOE model for simple parallel tasks",
      "mode": "subagent"
    },
    "local-heavy": {
      "model": "local/gemma-4-26b",
      "description": "Use for complex reasoning that needs a bigger brain",
      "mode": "subagent"
    }
  }
}
```

---

## Advanced: Hidden Sub-Agents

If a sub-agent should only be invoked programmatically (never via @ mention), set `hidden: true`:

```json
{
  "agent": {
    "dgx-spark": {
      "model": "dgx-spark/qwen3.6-35b",
      "description": "Lightweight MOE for parallel tasks",
      "mode": "subagent",
      "hidden": true
    }
  }
}
```

Hidden agents still appear in the Task tool's available types — they're just removed from the user-facing @ autocomplete menu.

---

## Actual Execution Workflow (What Works in Practice)

The following workflow has been validated across multiple exercise runs:

### Step 1 — Create Timestamped Results Folder

Before launching any agents, create a timestamped directory under the exercise's `results/` folder. For example:

```bash
mkdir -p inference-containers/multi-agent-orchestration-test/exercise02/results/2026_06_02_results_01
```

**The folder must exist before any agent is launched.** This ensures agents can write their output files immediately upon completion.

### Step 2 — Launch All Sub-Agents in Parallel

Fire all 4 Task tool calls at once, each with `subagent_type: "dgx-spark"` and a prompt that tells the agent which file to write its response to inside the results folder. The calls are independent and concurrent — the orchestrator waits for all responses before continuing.

Example pattern (from exercise02):

```
task(description="Linear transformations explanation", prompt="...explain linear transformations...", subagent_type="dgx-spark")
task(description="Eigenvalues explanation", prompt="...explain eigenvalues...", subagent_type="dgx-spark")
task(description="OAuth2 SSO explanation", prompt="...explain OAuth2...", subagent_type="dgx-spark")
task(description="Web security explanation", prompt="...explain web security...", subagent_type="dgx-spark")
```

### Step 3 — Collect Results

Each agent writes its output to the designated file in the results folder:

- `agent_01_linear_transformations.md`
- `agent_02_eigenvalues.md`
- `agent_03_oauth2.md`
- `agent_04_web_security_jargon.md`

The orchestrator reviews each file and confirms success.

### Step 4 — Verify vLLM Health

Monitor the vLLM logs during execution. Successful parallel execution shows all requests completing with 200 OK and no CUDA assertion errors. Key indicators:

- `Running: N reqs` counting down to 0 (no dropped requests)
- No `CUDA assertion` or `engine died` messages
- All `POST /v1/chat/completions HTTP/1.1" 200 OK` responses matching the number of agents launched

---

## Summary Checklist

1. **Add the sub-agent config** to `opencode.json` under `"agent"` with `mode: "subagent"` and its own `model` field
2. **Configure the provider** so the `dgx-spark/qwen3.6-35b` model resolves to your Spark endpoint
3. **Instruct the orchestrator** (verbally or via task permissions) to use `dgx-spark` as the `subagent_type`
4. **Verify** with a simple "hi, are you there" test before running real workloads

---

## References

- [OpenCode Task tool source code](https://github.com/anomalyco/opencode/blob/dev/packages/opencode/src/tool/task.ts) — The implementation of the Task tool shows how `subagent_type` is resolved and how sub-agents are spawned. Useful for understanding the exact schema and available options at runtime.
- [OpenCode Agents documentation](https://opencode.ai/docs/agents/) — Official docs covering all agent configuration options, permissions, modes, and task permission rules.

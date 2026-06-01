# Multi-Agent Orchestration — Basic Liveness Check

## Objective
Launch **4 parallel sub-agents** via opencode's `task` tool, each with `agentype: dgx-spark`, and verify they all respond to a simple liveness prompt. This tests basic delegation and parallel agent orchestration.

---

## Pre-Flight Step

Before launching any agents, create a results folder for this test run:

```
inference-containers/multi-agent-orchestration-test/exercise00/results/<date_results_N>
```

Use today's date as `<date>` and an incrementing number for `N` (e.g. `2026_06_02_results_01`). **The folder must exist before the agents are launched.**

---

## Agent Definitions

Each agent uses the same simple prompt. The only difference is the agent number, which each should include in its reply.

### Agent 01 — Liveness Check
**Prompt:** Hi Qwen, are you there? If so, confirm by saying: "Yes I am here and I am working as agent1."

### Agent 02 — Liveness Check
**Prompt:** Hi Qwen, are you there? If so, confirm by saying: "Yes I am here and I am working as agent2."

### Agent 03 — Liveness Check
**Prompt:** Hi Qwen, are you there? If so, confirm by saying: "Yes I am here and I am working as agent3."

### Agent 04 — Liveness Check
**Prompt:** Hi Qwen, are you there? If so, confirm by saying: "Yes I am here and I am working as agent4."

---

## Execution Instructions

1. Create the results folder under `inference-containers/multi-agent-orchestration-test/exercise00/results/` with a timestamped name (e.g. `2026_06_02_results_01`).
2. Launch all **4 sub-agents in parallel** using opencode's `task` tool. Each must use `subagent_type: dgx-spark`.
3. Collect each agent's response and write it to an individual file inside the results folder:
   - `agent_01_hello_world.md`
   - `agent_02_hello_world.md`
   - `agent_03_hello_world.md`
   - `agent_04_hello_world.md`

---

## Expected Output Structure

```
inference-containers/multi-agent-orchestration-test/exercise00/
├── multi-agent-exercise00.md            # This file
├── results/
│   └── <date_results_N>/
│       ├── agent_01_hello_world.md      # Contains: "Yes I am here and I am working as agent1."
│       ├── agent_02_hello_world.md      # Contains: "Yes I am here and I am working as agent2."
│       ├── agent_03_hello_world.md      # Contains: "Yes I am here and I am working as agent3."
│       └── agent_04_hello_world.md      # Contains: "Yes I am here and I am working as agent4."
```

---

## Success Criteria

- All 4 agents respond within a reasonable time window
- Each response contains the correct agent number in the confirmation message
- The results folder existed **before** any agent was launched
- All files are written to the correct location under the results folder

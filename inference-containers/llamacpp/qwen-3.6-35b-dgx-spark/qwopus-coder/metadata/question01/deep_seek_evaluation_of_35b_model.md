# DeepSeek Evaluation: Qwopus3.6-35B-A3B-Coder

**Test:** Linear Algebra Exam Question (MIT 18.06 Inspired — Eigenvalues, Diagonalization, A¹⁰)
**Date:** 2026-07-04
**Hardware:** DGX Spark (GB10)
**Engine:** llama.cpp, Q8_0, MTP speculative decoding (n_max=2)

## Grade: A-

### Strengths

**Mathematical correctness:** All eigenvalues, eigenvectors, and the diagonalization were correct. The A¹⁰ computation using SymPy was accurate. The bonus section correctly identified the general formula for eigenvalues of a tridiagonal Toeplitz matrix and connected it to the continuous Laplacian spectrum.

**Tool use discipline:** Used Python (SymPy) for matrix computations autonomously when needed, without being told to do so. Followed the chunked output structure as instructed.

**Self-verification:** Cross-checked results using Python and referenced back to mathematical theory — a sign of genuine understanding rather than pattern matching.

**Token efficiency:** The MoE architecture (only ~3B active parameters per token) produced coherent multi-step reasoning at approximately 44 tokens/s, making it practical for interactive agent workflows.

### Weaknesses

**Infinite loop behavior:** The model can get stuck in tool-call loops under certain conditions — specifically when asked to perform many sequential file writes. It may continue running `ls -la` or other verification commands without realizing it has completed the task. This is a known failure mode of open-ended agent loops rather than a reasoning deficit.

## Verdict

The 35B coder model demonstrates solid mathematical reasoning and autonomous tool-use capability. Its primary limitation is not in intelligence but in **loop termination** — it sometimes struggles to recognize task completion when the instruction involves many sequential steps.

**Best use:** As a capable sub-agent to a stronger orchestrator model. The orchestrator provides clear task boundaries and decides when a task is done; the 35B handles the execution efficiently and accurately.

**Worst use:** Given full autonomy over a multi-step workflow with ambiguous stopping criteria — the lack of a built-in "am I done?" circuit can lead to runaway tool calls.

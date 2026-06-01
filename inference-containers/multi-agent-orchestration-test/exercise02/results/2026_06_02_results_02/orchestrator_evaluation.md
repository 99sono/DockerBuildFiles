# Orchestrator Evaluation — Exercise 02, Run 02

**Date:** 2026-06-02
**Orchestrator:** `local/qwen3.6-27b` (RTX 5090)
**Sub-Agent Model:** `dgx-spark/qwen3.6-35b` (vLLM + MTP speculation, DGX Spark)
**Result Folder:** `exercise02/results/2026_06_02_results_02`

---

## Overall Assessment

All 4 agents completed successfully in parallel. vLLM remained stable with no CUDA assertion errors or dropped requests. Below is a per-agent evaluation.

---

## Agent 1 — Linear Transformations (`agent_01_linear_transformations.md`)

**Score: 9/10**

### Strengths
- Algebraic proofs for both additivity and homogeneity failure under `f(x) = mx + b` are correct and clearly shown step-by-step.
- The linear vs affine distinction is handled precisely — no hand-waving.
- Summary table is well structured and reinforces the key takeaways.

### Weaknesses
- Missing discussion of multi-dimensional cases. The entire treatment is 1D (`f: R -> R`). A mention that in higher dimensions `f(x) = Ax` generalizes the 1D case, while `f(x) = Ax + b` generalizes the affine case, would have elevated this from good to excellent.
- No geometric intuition section (e.g., what linear transformations do visually — rotation, scaling, shearing).

### Verdict
Technically correct, well-organized, but narrowly scoped to 1D. The prompt asked about principles of linear transformations broadly, and a multi-dimensional example would have been appropriate.

---

## Agent 2 — Eigenvalues (`agent_02_eigenvalues.md`)

**Score: 10/10**

### Strengths
- Harvard section is genuinely rigorous: characteristic polynomial, diagonalization criterion, spectral theorem for symmetric matrices, similarity invariance. This is graduate-level content without errors.
- The pedagogical descent from Harvard professor to 5-year-old is the best piece of writing across all 4 agents. Each audience gets a distinct tone and appropriate depth.
- Practical applications (PageRank, PCA, quantum mechanics, vibration analysis) ground the theory in reality.
- Summary table at the end provides a useful reference across audiences.

### Weaknesses
- Minor: no mention of algebraic vs geometric multiplicity, which is relevant to diagonalization conditions and Jordan form. Not required by the prompt but worth noting for completeness.

### Verdict
Outstanding. Covers every level requested with zero factual errors and appropriate tone shifts. The hardest question on the exercise, answered best.

---

## Agent 3 — OAuth2, SSO, Identity Protocols (`agent_03_oauth2.md`)

**Score: 9.5/10**

### Strengths
- The role mapping (resource owner, client, authorization server, resource server) is precise and avoids the common conflation of "authorization server" with "certificate authority."
- SSO flow walkthrough is step-by-step and accurate — particularly the explanation that SSO works via the IdP's session cookie, not token exchange.
- The CSRF vulnerability table across all 4 systems (Spring Boot, Kibana, Grafana, Google) is practically useful for someone designing this architecture today.
- JWT-as-format vs protocol distinction is correct and important — many people conflate these.
- Architecture diagram is readable and captures the relationships between components.

### Weaknesses
- PKCE (Proof Key for Code Exchange) is mentioned in passing but not explained. For an exercise that asks about OAuth2, PKCE deserves a brief explanation since it's critical to modern secure implementations.
- The section on certificate trust could be deeper — the prompt specifically asked about "a different certificate authority than my own," and while the answer correctly redirects this toward identity federation, a more explicit treatment of mutual TLS (mTLS) in inter-service auth would have been valuable.

### Verdict
Excellent architectural analysis. Near production-ready quality for someone evaluating their OAuth2/SSO setup. Missing PKCE detail is the only gap.

---

## Agent 4 — Web Security (`agent_04_web_security_jargon.md`)

**Score: 9.5/10**

### Strengths
- CORS vs SOP distinction in section (b) is critical and handled perfectly — many people say "CORS blocks iframes" which is wrong (SOP does; CORS governs XHR/fetch).
- The clickjacking pivot in section (b) is excellent. It identifies the real attack vector where an iframe + fake top-level window combo actually works, explaining what the attacker *can* and *cannot* do.
- CSRF explanation is precise, including the distinction between GET-based and POST-based CSRF vectors.
- The expanded security glossary in section (d) covers ~14 terms with accurate definitions and practical examples.

### Weaknesses
- No mention of HTTP Strict Transport Security (HSTS) preloading or certificate pinning in the TLS/certificate discussion in section (b), where it would have been relevant.
- Beacon/timing attacks are mentioned in the glossary but not connected back to the iframe scenario in section (b), where they're actually applicable (attacker can detect load events).

### Verdict
Very strong technical writing with accurate attack/defense analysis. The clickjacking addition elevates it beyond a simple FAQ — shows real understanding of how these concepts interact.

---

## Comparative Summary

| Agent | Topic | Score | Line Count | Quality Assessment |
|-------|-------|-------|------------|---------------------|
| 1 | Linear Transformations | 9/10 | 101 | Correct but narrowly scoped |
| 2 | Eigenvalues | 10/10 | 229 | Outstanding across all levels |
| 3 | OAuth2/SSO | 9.5/10 | 265 | Architecture-grade analysis |
| 4 | Web Security | 9.5/10 | 222 | Attack-aware and practical |

### Average Score: **9.5 / 10**

---

## vLLM Stability Notes

- All 4 agents launched in parallel, all 4 completed without errors
- No CUDA assertion failures detected
- No request drops observed
- GPU KV cache usage remained low (under 1.5% per agent)
- Speculative decoding acceptance rates stable across the run window
- vLLM held up well under sustained concurrent decode load

---

## Conclusion

All tasks completed successfully. Agent 2 delivered the highest-quality output with zero factual errors across four distinct audiences. Agents 3 and 4 were nearly equivalent in depth, both producing practically useful content for someone designing or securing a real system. Agent 1 was correct but could have been more comprehensive. vLLM remained stable throughout — no crashes, no dropped requests. The orchestrator-subagent delegation pattern using `dgx-spark` proved reliable for this workload.

I’m confused about the model choice and would like your help reviewing this setup and generating the required artifacts.

### Model question

Why was **`chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4`** not selected?

This model **does exist**:
<https://huggingface.co/chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4>

From my understanding, it should be one of the **fastest variants** (NVFP4).  
The repository also provides **explicit usage instructions**.

My assumption is that the current **vLLM documentation referencing FP8** may simply be a **copy‑paste leftover** from when the FP8 version was implemented first.  
Please confirm whether that assumption is correct or not.

***

### What I need you to generate

Please generate the following **from scratch**, cleanly and professionally:

***

### 1️⃣ Docker Compose file (`docker-compose.yml`)

Requirements:

*   Uses **vLLM**
*   Uses model:  
    `chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4`
*   **KV cache quantization set to TurboQuant by default**
*   Heavy inline comments explaining **every important option**
*   Clear comments showing **how to tune KV cache sizes**, including:
    *   Default value
    *   How to try **large contexts (e.g. 256k tokens)**
    *   Notes that this may or may not work on RTX 5090-class GPUs

⚠️ I already have scripts for:

*   `docker compose pull`
*   `docker compose up`
*   `docker compose down`

So you **do not need to recreate or explain those**.

***

### 2️⃣ README.md

The README must include:

*   Clear description of the setup
*   Explicit reference to the model:
    <https://huggingface.co/chankhavu/Nemotron-Cascade-2-30B-A3B-NVFP4>
*   Explicit reference and explanation of **TurboQuant**
*   A section explaining **each configurable Docker Compose option**
*   A section explaining **KV cache sizing strategies** (small / large / experimental)
*   A quote of the **official vLLM command** being used internally
*   Notes about GPU memory considerations and context-length tradeoffs

***

### 3️⃣ Test script (`04_test_vllm_curl.sh`)

Context:

*   I already have the following directory structure:
        .
        ├── docker-compose.yml
        ├── 00_docker_compose_pull.sh
        ├── 01_docker_compose_up.sh
        ├── 02_docker_compose_down.sh
        ├── 03_enter_docker_container.sh
        └── test/
            └── test_file_01_prompt.md

Requirements for the script:

*   Reads input from:
        test/test_file_01_prompt.md
*   Sends it to **vLLM via HTTP (curl)**
*   Outputs the response to stdout
*   Designed so I can:
    *   Increase file size
    *   Test different context lengths
    *   Observe model behavior under long contexts

***

### Important constraints

*   ✅ **Do not execute anything**
*   ✅ **Do not simulate outputs**
*   ✅ Only generate:
    *   `docker-compose.yml`
    *   `README.md`
    *   `04_test_vllm_curl.sh`
*   ✅ Use clear comments and production-quality structure

***

If something is uncertain (e.g. 256k context on RTX 5090), **document the uncertainty clearly**, but still show how it would be configured.

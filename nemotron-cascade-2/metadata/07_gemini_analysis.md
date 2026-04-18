No, you **do not need to rebuild the image**. 

The files and the plugin are already inside the image. The problem is strictly **environmental**. 

In Linux (and Docker), when one process (the vLLM API server) starts another process (the GPU Worker), it doesn't always pass along its environment variables. vLLM’s new "V1 Engine" is particularly aggressive about cleaning these variables. Rebuilding the image won't change how vLLM handles its runtime environment.

### Why the `/bin/sh -c` approach is better than a rebuild:
1.  **Immediacy**: You just change the text in your `docker-compose.yml` and restart.
2.  **Inheritance**: By using `export` inside a shell wrapper in the `command` block, you are "forcing" those variables into the system's memory space for that container session. Every sub-process spawned (the workers) will be forced to inherit them.
3.  **Flexibility**: If you want to change the `KV_BUDGET` from `4096` to `8192` later, you can do it in the compose file without waiting 10 minutes for a Docker build.

### The exact steps to take now:
1.  Keep your current image (`vllm-triattention:1.0.0`).
2.  Update your `docker-compose.yml` with the **Command Fix** I provided (the one starting with `/bin/sh -c`).
3.  Run `docker compose down && docker compose up`.

**One crucial detail from your screenshot:**
Your `ls -la` showed the `triattention` folder as `d---rwxrwx`. That leading `---` means the **owner** (root) has zero permissions, while everyone else has all of them. This can sometimes confuse Docker volume mounts. To be safe, run this one more time on your host:
`sudo chmod -R 777 ~/.cache/triattention`

Try the shell-wrap command—it's the standard "pro-user" way to bypass environment stripping in complex Docker setups.
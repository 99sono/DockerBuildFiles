docker logs qwen3-6-moe-35b-a3b-nvfp4 > vllm_log_dump.txt 2>&1
echo Going to print some lines of the log file
tail -n 20 vllm_log_dump.txt

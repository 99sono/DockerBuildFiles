# Qwen 3.8 Flash Next DGX Spark Cluster

Multi-node deployment presets for running **Qwen 3.8 Flash Next** across a 2-node DGX Spark cluster (NVIDIA GB10, 256 GiB total unified memory).

## Available Presets

- [`mia-dual-spark-nvfp4/`](./mia-dual-spark-nvfp4/): Multi-node NVFP4 serving with TP=2, Expert Parallelism, MTP=3 speculative decoding, and FP8 KV cache, adapted from Mia AI Lab's dual-spark recipe.

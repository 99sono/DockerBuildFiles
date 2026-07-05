#!/bin/bash
echo "Pulling base image for DSpark build..."
docker pull ghcr.io/bjk110/vllm-spark:unholy-fusion-prod-ready
echo ""
echo "Base image pulled. Next step:"
echo "  WORKER_BUILD=0 ./00_a_build_dspark_image.sh    # build locally first"
echo "  or set WORKER_HOST in .env and run without override for worker build too"

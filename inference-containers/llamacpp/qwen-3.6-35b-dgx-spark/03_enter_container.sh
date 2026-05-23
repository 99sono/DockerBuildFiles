#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
echo "Entering qwen-3.6-35b-mtp-dgx-spark container..."
docker exec -it qwen-3.6-35b-mtp-dgx-spark /bin/bash

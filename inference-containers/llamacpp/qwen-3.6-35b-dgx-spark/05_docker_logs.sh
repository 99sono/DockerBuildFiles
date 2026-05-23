#!/bin/bash
echo "Viewing logs for qwen-3.6-35b-mtp-dgx-spark..."
docker logs -f --tail=100 qwen-3.6-35b-mtp-dgx-spark

#!/bin/bash
set -e
echo "Testing connectivity to inference-server..."
curl -s -o /dev/null -w "%{http_code}" http://inference-server:8000/v1/models | grep -q "200" && echo "SUCCESS: inference-server is reachable" || echo "FAILED: Could not reach inference-server"

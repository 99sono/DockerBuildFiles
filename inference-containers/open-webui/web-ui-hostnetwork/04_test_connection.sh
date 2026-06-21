#!/bin/bash
source ../../../commonScripts/lib.sh
echo "Testing connectivity to DeepSeek on localhost:8000..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/v1/models | grep -q "200" && echo "SUCCESS: DeepSeek is reachable" || echo "FAILED: Could not reach DeepSeek on localhost:8000"

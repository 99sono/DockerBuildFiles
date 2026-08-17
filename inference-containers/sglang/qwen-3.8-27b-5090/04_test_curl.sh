#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
( cd "$SCRIPT_DIR" && source ../../../commonScripts/lib.sh && load_env && python3 ../../../commonScripts/test_client.py )

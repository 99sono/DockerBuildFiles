#!/bin/bash
source ../../../commonScripts/lib.sh
load_env
cd "$(dirname "${BASH_SOURCE[0]}")"
python3 ../../../commonScripts/test_client.py

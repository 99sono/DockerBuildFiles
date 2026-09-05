#!/bin/bash
# =====================================================================
# STEP 2/3 — verify the parser's python environment.
#
# NOTE: parse_docker_log.py is PURE STDLIB (re / datetime / math /
# statistics / collections / argparse) — no pip packages are required,
# which keeps the env 100% reproducible with zero network dependencies.
# This script only proves the env has a working python and that every
# import the parser uses resolves.
#
# If the parser later grows (e.g. pandas for big CSVs), add `pip install`
# lines HERE — nowhere else should manage the env's packages.
# =====================================================================
# Shared helpers + logging (see commonScripts/lib.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"
# Run a one-liner inside the env: import every stdlib module the parser
# uses, then print a success line. Fails (non-zero) if any import breaks.
conda run --no-capture-output -n testVLLMLogParse python -c "import argparse, collections, datetime, math, re, statistics; print('testVLLMLogParse: python + stdlib OK')"
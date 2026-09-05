#!/bin/bash
# =====================================================================
# STEP 3/3 — run the parser: vLLM docker-log dump -> Markdown report.
#
# Usage (works from any CWD):
#   bash <path-to>/vllm/log-parser/03_parse_docker_log_file_to_markdown_report.sh <log_file> [output.md]
#
# Default output: <log_file>.report.md next to the input
#   (01_vllm_log.txt -> 01_vllm_log.report.md)
#
# The script prints a one-line count summary (lines/engines/specs/
# access/jit/warnings/noise/unrecognized); sanity-check it against
# `grep -c "Engine 000:" <log_file>`, `grep -c "SpecDecoding metrics"
# <log_file>` and `grep -c "JIT compilation during inference" <log_file>`
# to confirm nothing was misclassified.
# =====================================================================
# Shared helpers + logging (see commonScripts/lib.sh)
# Absolute path of THIS script's dir, so lib.sh and the parser are found no
# matter where the caller invokes this script from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../commonScripts/lib.sh"
# $1: log file — required; the :? suffix makes bash exit with a usage hint
#     if the argument is missing (fail fast, no empty parse).
input="${1:?Usage: 03_parse_docker_log_file_to_markdown_report.sh <log_file> [output.md]}"
# $2: optional output path; default derives from the input name (strip .txt).
output="${2:-${input%.txt}.report.md}"
# Run the parser inside the conda env created by step 1; --no-capture-output
# keeps the parser's own stdout (the count summary) visible on the terminal.
conda run --no-capture-output -n testVLLMLogParse python "$SCRIPT_DIR/parse_docker_log.py" "$input" -o "$output"
# Human-facing pointer to the result (the parser also prints its own line).
echo "Report: $output"
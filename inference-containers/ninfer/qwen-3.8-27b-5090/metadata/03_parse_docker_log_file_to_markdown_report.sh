#!/bin/bash
# =====================================================================
# STEP 3/3 — run the parser: NInfer docker-log dump -> Markdown report.
#
# Usage:
#   bash 03_parse_docker_log_file_to_markdown_report.sh <log_file> [output.md]
#
# Default output: <log_file>.report.md next to the input
#   (01_docker_logs.txt -> 01_docker_logs.report.md)
#
# The script prints a one-line count summary (lines/done/submitted/
# intervals/errors/unrecognized); sanity-check it against
# `grep -c "done finish=" <log_file>` and `grep -c "throughput interval"
# <log_file>` to confirm nothing was misclassified.
# =====================================================================
# Shared helpers + logging (see commonScripts/lib.sh)
source ../../../../commonScripts/lib.sh
# $1: log file — required; the :? suffix makes bash exit with a usage hint
#     if the argument is missing (fail fast, no empty parse).
input="${1:?Usage: 03_parse_docker_log_file_to_markdown_report.sh <log_file> [output.md]}"
# Absolute path of THIS script's dir, so the parser is found no matter
# where the caller invokes this script from (not just from metadata/).
dir="$(cd "$(dirname "$0")" && pwd)"
# $2: optional output path; default derives from the input name (strip .txt).
output="${2:-${input%.txt}.report.md}"
# Run the parser inside the conda env created by step 1; --no-capture-output
# keeps the parser's own stdout (the count summary) visible on the terminal.
conda run --no-capture-output -n testNInferLogParse python "$dir/parse_docker_log.py" "$input" -o "$output"
# Human-facing pointer to the result (the parser also prints its own line).
echo "Report: $output"
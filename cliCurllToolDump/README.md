# Agent Web Research Dump

This directory is used by coding agents to store temporary outputs from web research (e.g., results from `curl` or `wget`).

## Rules for Agents

1. **Naming Convention**: Every file saved here must start with the prefix `deleteMe_` followed by a sequence number and a descriptive name.
   - Example: `deleteMe_01_curl_output.html`, `deleteMe_02_api_response.txt`.
2. **Purpose**: This folder is strictly for temporary tool support and does not contain official installation guides.
3. **Cleanup**: These files are intended to be temporary and are ignored by Git.
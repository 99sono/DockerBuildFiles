

```python
#!/usr/bin/env python3
"""Parse an SGLang server log file and print concise batch statistics."""

import argparse
import re
import sys
from pathlib import Path

DEFAULT_LOG_PATH = "../../01_docker_logs.txt"

DECODE_MARKER = "Decode batch"
PREFILL_MARKER = "Prefill batch"

FULL_TOKEN_RE = re.compile(r"#full token:\s*(\d+)")
GEN_THROUGHPUT_RE = re.compile(r"gen throughput \(token/s\):\s*([-+]?\d*\.?\d+)")
INPUT_THROUGHPUT_RE = re.compile(r"input throughput \(token/s\):\s*([-+]?\d*\.?\d+)")
CUDA_GRAPH_RE = re.compile(r"cuda graph:\s*(True|False)")


def resolve_default_log_path() -> Path:
    """Return the default log path, falling back to a script-relative path."""
    default = Path(DEFAULT_LOG_PATH)
    if default.exists():
        return default

    try:
        script_dir = Path(__file__).resolve().parent
    except NameError:
        return default

    candidate = script_dir / DEFAULT_LOG_PATH
    if candidate.exists():
        return candidate

    return default


def format_stats(values):
    """Return min/max/mean as formatted strings, or n/a when empty."""
    if not values:
        return "n/a", "n/a", "n/a"
    return (
        f"{min(values):.2f}",
        f"{max(values):.2f}",
        f"{sum(values) / len(values):.2f}",
    )


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Parse an SGLang server log file and print statistics."
    )
    parser.add_argument(
        "log_path",
        nargs="?",
        default=None,
        help=f"Path to the SGLang log file (default: {DEFAULT_LOG_PATH})",
    )
    args = parser.parse_args(argv)

    log_path = Path(args.log_path) if args.log_path else resolve_default_log_path()

    try:
        log_file = log_path.open(encoding="utf-8", errors="replace")
    except OSError as exc:
        print(f"error: cannot open log file {log_path}: {exc}", file=sys.stderr)
        return 1

    decode_count = 0
    prefill_count = 0

    gen_throughputs = []
    input_throughputs = []

    total_generation_tokens = 0
    previous_full_token = None

    cuda_graph_true = 0
    cuda_graph_false = 0

    with log_file:
        for line in log_file:
            if DECODE_MARKER in line:
                decode_count += 1

                match = GEN_THROUGHPUT_RE.search(line)
                if match:
                    gen_throughputs.append(float(match.group(1)))

                match = FULL_TOKEN_RE.search(line)
                if match:
                    current_full_token = int(match.group(1))
                    if previous_full_token is not None:
                        delta = current_full_token - previous_full_token
                        # Count positive deltas as generated tokens; drops
                        # usually correspond to finished requests.
                        if delta > 0:
                            total_generation_tokens += delta
                    previous_full_token = current_full_token

                match = CUDA_GRAPH_RE.search(line)
                if match and match.group(1) == "True":
                    cuda_graph_true += 1
                else:
                    cuda_graph_false += 1

            elif PREFILL_MARKER in line:
                prefill_count += 1

                match = INPUT_THROUGHPUT_RE.search(line)
                if match:
                    input_throughputs.append(float(match.group(1)))

    gen_min, gen_max, gen_mean = format_stats(gen_throughputs)
    input_min, input_max, input_mean = format_stats(input_throughputs)
    cuda_used = "yes" if cuda_graph_true > 0 else "no"

    print(f"Decode batches: {decode_count}")
    print(f"Prefill batches: {prefill_count}")
    print(
        f"Gen throughput (token/s): "
        f"min={gen_min}, max={gen_max}, mean={gen_mean}"
    )
    print(
        f"Input throughput (token/s): "
        f"min={input_min}, max={input_max}, mean={input_mean}"
    )
    print(
        "Total generation tokens "
        f"(positive #full token deltas): {total_generation_tokens}"
    )
    print(
        "CUDA graphs in decode: "
        f"used={cuda_used}, True={cuda_graph_true}, False={cuda_graph_false}"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
```

## Expected output

For the two example lines shown in the challenge, the script prints:

```text
Decode batches: 1
Prefill batches: 1
Gen throughput (token/s): min=72.31, max=72.31, mean=72.31
Input throughput (token/s): min=0.03, max=0.03, mean=0.03
Total generation tokens (positive #full token deltas): 0
CUDA graphs in decode: used=yes, True=1, False=0
```

With a longer log, the counts and throughput statistics will change, but the output format remains the same.
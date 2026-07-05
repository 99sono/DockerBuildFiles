#!/bin/bash
# =============================================================================
# 04_check_nccl.sh — Diagnose NCCL / RDMA readiness for dual-Spark cluster
# =============================================================================
#
# WHAT THIS SCRIPT DOES
#   Runs through 6 checks to make sure your two DGX Sparks can talk to each
#   other over the RoCE (RDMA) interconnect. NCCL is the library that vLLM
#   uses to shuffle GPU data between the two nodes (tensor parallelism).
#   If any of these checks fail, vLLM won't be able to start a multi-node
#   session — you'll see "NCCL error: unhandled system error" in the logs.
#
# HOW TO USE
#   Run this on BOTH nodes before starting the containers:
#     ./04_check_nccl.sh
#
#   It will tell you exactly what's wrong and how to fix it.
#   The most common issue is NCCL_IB_GID_INDEX being wrong — see check #4.
#
# WHAT EACH CHECK DOES
#   1. HCA presence    — Are the ConnectX-7 network cards visible to Linux?
#   2. Link state      — Is the cable plugged in and the link active?
#   3. IP addresses    — Do the RoCE interfaces have their 10.0.x.x IPs?
#   4. GID index       — At what table index does the IPv4 address live?
#                        (This is the one that usually bites you — see below.)
#   5. Connectivity    — Can the two nodes ping each other? (manual check)
#   6. Docker GPU      — Can Docker see the NVIDIA GPU and run CUDA?
#
# THE GID INDEX PITFALL (Why check #4 matters)
#   RoCE doesn't use IP addresses directly — it uses a small lookup table
#   called the GID table (8 slots, numbered 0–7). Your 10.0.x.x IP is
#   registered in one of those slots. The slot number varies per machine
#   depending on boot order and how the network was configured.
#
#   If NCCL asks for GID index 4 but your IPv4 is at index 2, it gets an
#   empty entry and the connection fails. You see this in the logs:
#     "ibv_modify_qp failed ... local GID ::" (empty = wrong index)
#
#   This script finds the right index for you automatically.
# =============================================================================

# ---- Where is this script? (used to find the .env file) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Counters for the summary at the end ----
PASS=0; FAIL=0

# ---- Helper functions — just prints with icons ----
pass() { PASS=$((PASS+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ❌ $1"; }
warn() { echo "  ⚠️  $1"; }

# =============================================================================
echo "============================================================"
echo " NCCL / RDMA Readiness Check — $(hostname)"
echo "============================================================"
echo ""

# ---------------------------------------------------------------------------
# CHECK 1: HCA presence
#   HCA = Host Channel Adapter. On the DGX Spark the two ConnectX-7 ports
#   show up as "rocep1s0f0" (Port 1) and "roceP2p1s0f0" (Port 2).
#   If these directories don't exist, the kernel didn't load the mlx5 driver
#   or the hardware isn't detected.
# ---------------------------------------------------------------------------
echo "--- 1. InfiniBand / RoCE HCAs ---"
for hca in rocep1s0f0 roceP2p1s0f0; do
  if [ -d "/sys/class/infiniband/$hca" ]; then
    pass "HCA $hca found"
  else
    fail "HCA $hca missing"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# CHECK 2: Link state
#   Reads the InfiniBand link state from the kernel. The file contains a
#   single number: 1 = DOWN, 2 = INIT, 3 = ARMED, 4 = ACTIVE.
#   We need ACTIVE on both ports.
# ---------------------------------------------------------------------------
echo "--- 2. Link State (must be ACTIVE) ---"
for hca in rocep1s0f0 roceP2p1s0f0; do
  state=$(cat /sys/class/infiniband/$hca/ports/1/state 2>/dev/null || echo "0: MISSING")
  case "$state" in
    *4*) pass "$hca: ACTIVE" ;;
    *1*) fail "$hca: DOWN — check cable and IP configuration" ;;
    *)   fail "$hca: $state — unexpected state" ;;
  esac
done
echo ""

# ---------------------------------------------------------------------------
# CHECK 3: IP configuration on the RoCE network interfaces
#   The ConnectX-7 ports present as netdevs (ethernet-style interface names).
#   The mapping from HCA name to netdev name is:
#     rocep1s0f0  →  enp1s0f0np0   (Port 1)
#     roceP2p1s0f0 →  enP2p1s0f0np0  (Port 2)
#   Each must have a static IP in the 10.0.x.x range.
# ---------------------------------------------------------------------------
echo "--- 3. IP Configuration on RoCE Interfaces ---"
# The colon-separated pairs map HCA name -> Linux network interface name
for pair in "rocep1s0f0:enp1s0f0np0" "roceP2p1s0f0:enP2p1s0f0np0"; do
  hca="${pair%%:*}"      # Left of colon = HCA name (for the GID table)
  netdev="${pair##*:}"   # Right of colon = netdev name (for `ip addr`)
  ip_line=$(ip -4 addr show "$netdev" 2>/dev/null | grep inet | head -1)
  if [ -n "$ip_line" ]; then
    ip=$(echo "$ip_line" | awk '{print $2}')
    pass "$netdev ($hca) → $ip"
  else
    fail "$netdev ($hca) — no IPv4 address"
  fi
done
echo ""

# ---------------------------------------------------------------------------
# CHECK 4: GID index auto-detection (the most important check)
#
# WHAT IS A GID?
#   A GID (Global IDentifier) is how RDMA addresses devices. Each IP on a
#   RoCE interface gets registered in a GID table — 8 entries (indices 0–7)
#   holding either an IPv6 or an IPv4-mapped address.
#
# HOW TO READ THE TABLE:
#   When you dump the GID table you see lines like:
#     GID 0: fe80:...   ← Link-local IPv6, ignore it
#     GID 1: fe80:...   ← Link-local IPv6, ignore it
#     GID 2: 0000:...ffff:0a00:0101  ← IPv4 10.0.1.1 ← THIS IS WHAT WE NEED
#     GID 3: 0000:...ffff:0a00:0101  ← (duplicate of above, ignore)
#     GID 4: 0000:...0000            ← Empty slot
#
#   The index varies between nodes! On our cluster:
#     spark01 (head):   IPv4 at index 2   → NCCL_IB_GID_INDEX="2,2"
#     spark02 (worker): IPv4 at index 4   → NCCL_IB_GID_INDEX="4,4"
#
#   Using the same value on both nodes WILL fail on one of them.
#   This script finds the correct index for THIS node automatically.
#
# HOW THIS CODE WORKS:
#   For each HCA, it loops through GID indices 0 to 7 looking for an entry
#   that starts with "0000:" and contains "ffff:" — that's the IPv4-mapped
#   format. It takes the first match (because IPv4 can appear at two
#   consecutive indices — both are the same, first one is fine).
#   Then it decodes the hex-encoded IP back to dotted decimal for display.
# ---------------------------------------------------------------------------
echo "--- 4. GID Index Auto-Detection ---"
GID_RESULTS=""
for hca in rocep1s0f0 roceP2p1s0f0; do
  best_idx=""
  best_gid=""
  # Loop through all 8 GID table entries (indices 0–7)
  for i in $(seq 0 7); do
    gid=$(cat /sys/class/infiniband/$hca/ports/1/gids/$i 2>/dev/null)
    # Look for IPv4-mapped IPv6 addresses: start with "0000:" and contain "ffff:"
    # Link-local addresses start with "fe80:" — we skip those.
    # Empty entries are "0000:...:0000" — we skip those too.
    if echo "$gid" | grep -q "^0000:.*ffff:"; then
      best_idx="$i"
      best_gid="$gid"
      break  # Take the FIRST match (IPv4 often appears at two consecutive
             # indices — e.g., 2 and 3 — both are the same address)
    fi
  done
  if [ -n "$best_idx" ]; then
    # Decode the hex-encoded IP from the GID value.
    # Example: 0a00:0101 → 0a=10, 00=0, 01=1, 01=1 → 10.0.1.1
    ip_hex=$(echo "$best_gid" | grep -oP 'ffff:\K[0-9a-f:]+' | tr -d ':')
    # Convert from hex to decimal, two hex digits at a time
    a=$((16#${ip_hex:0:2})); b=$((16#${ip_hex:2:2}))
    c=$((16#${ip_hex:4:2})); d=$((16#${ip_hex:6:2}))
    pass "$hca: IPv4 GID at index $best_idx → $a.$b.$c.$d"
    GID_RESULTS="$GID_RESULTS ${hca}:${best_idx}"
  else
    fail "$hca: no IPv4 GID found"
  fi
done

# Take the detected indices and format them as NCCL_IB_GID_INDEX expects:
# comma-separated, e.g. "2,2" or "4,4"
SUGGESTED=$(echo "$GID_RESULTS" | grep -oP ':\K[0-9]' | paste -sd,)
if [ -n "$SUGGESTED" ]; then
  echo ""
  warn "Suggested NCCL_IB_GID_INDEX=\"$SUGGESTED\""
  # Now check if the .env file disagrees with what we found
  if [ -f "$SCRIPT_DIR/.env" ]; then
    # Read the current NCCL_IB_GID_INDEX from .env (skip comment lines)
    CURRENT=$(grep NCCL_IB_GID_INDEX "$SCRIPT_DIR/.env" 2>/dev/null | grep -v '^#' | cut -d= -f2 | tr -d '" ')
    if [ -n "$CURRENT" ] && [ "$CURRENT" != "$SUGGESTED" ]; then
      warn "  But .env has NCCL_IB_GID_INDEX=\"$CURRENT\" — MISMATCH!"
      warn "  Fix with: sed -i 's/NCCL_IB_GID_INDEX=.*/NCCL_IB_GID_INDEX=\"$SUGGESTED\"/' $SCRIPT_DIR/.env"
    elif [ -n "$CURRENT" ]; then
      pass ".env NCCL_IB_GID_INDEX=\"$CURRENT\" matches suggestion"
    fi
  else
    warn "  No .env found — docker-compose will use its default"
  fi
fi
echo ""

# ---------------------------------------------------------------------------
# CHECK 5: Cross-node connectivity
#   This is a reminder to manually ping the other node's RoCE IPs.
#   NCCL won't work if the two nodes can't reach each other at layer 3.
# ---------------------------------------------------------------------------
echo "--- 5. Cross-Node Connectivity (requires both nodes up) ---"
for peername in "spark01 (head)" "spark02 (worker)"; do
  warn "  Ping tests skipped — run manually: ping -c 2 10.0.1.<other>"
done
echo ""

# ---------------------------------------------------------------------------
# CHECK 6: Docker GPU access
#   Two-part check:
#     a) Does Docker know about the NVIDIA runtime (nvidia-container-toolkit)?
#     b) Can we actually run a CUDA container and see the GPU?
# ---------------------------------------------------------------------------
echo "--- 6. Docker GPU Access ---"

# Part a: Check if the nvidia runtime is registered with Docker.
# This tells us nvidia-container-toolkit was installed correctly.
if docker info 2>/dev/null | grep -q "nvidia" && docker info 2>/dev/null | grep -qi "runtimes"; then
  pass "Docker NVIDIA runtime available"
elif docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi 2>/dev/null | grep -q "NVIDIA-SMI"; then
  pass "Docker NVIDIA runtime available (verified via GPU access)"
else
  fail "Docker NVIDIA runtime NOT available — install nvidia-container-toolkit"
fi

# Part b: Actually run nvidia-smi inside a container to confirm the GPU
# is accessible. The docker info check can be flaky (different Docker
# versions format the output differently), so we also do a real test.
GPU_CONTAINER="nvidia/cuda:12.5.0-base-ubuntu22.04"
# Check if the image is already pulled — if not, pull it first
# so the timing of the real test is more predictable
if docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q "nvidia/cuda:12.5.0-base-ubuntu22.04"; then
  HAS_IMAGE=true
else
  HAS_IMAGE=false
fi

if [ "$HAS_IMAGE" = false ]; then
  warn "  Pulling nvidia/cuda:12.5.0-base-ubuntu22.04 for GPU test (first time only)..."
  docker pull nvidia/cuda:12.5.0-base-ubuntu22.04 > /dev/null 2>&1 || true
fi

# Run nvidia-smi inside a throwaway container.
# --rm removes the container after it exits.
# --gpus all gives it access to all GPUs on the host.
if docker run --rm --gpus all $GPU_CONTAINER nvidia-smi 2>/dev/null | grep -q "NVIDIA-SMI"; then
  pass "GPU accessible inside container"
else
  fail "GPU not accessible — check nvidia-container-toolkit and docker restart"
fi
echo ""

# =============================================================================
# RESULTS SUMMARY
# =============================================================================
echo "============================================================"
echo " Results: $PASS passed, $FAIL failed"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

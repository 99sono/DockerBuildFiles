#!/bin/bash
# 04_check_nccl.sh — Diagnose NCCL / RDMA readiness for dual-Spark DeepSeek-V4-Flash
# Run this on BOTH nodes before starting containers.
# Reports any mismatches or missing configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0

pass() { PASS=$((PASS+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ❌ $1"; }
warn() { echo "  ⚠️  $1"; }

echo "============================================================"
echo " NCCL / RDMA Readiness Check — $(hostname)"
echo "============================================================"
echo ""

# ---- 1. HCA presence ----
echo "--- 1. InfiniBand / RoCE HCAs ---"
for hca in rocep1s0f0 roceP2p1s0f0; do
  if [ -d "/sys/class/infiniband/$hca" ]; then
    pass "HCA $hca found"
  else
    fail "HCA $hca missing"
  fi
done
echo ""

# ---- 2. Link state ----
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

# ---- 3. IP addresses on RoCE interfaces ----
echo "--- 3. IP Configuration on RoCE Interfaces ---"
# Map HCA names to netdev names
for pair in "rocep1s0f0:enp1s0f0np0" "roceP2p1s0f0:enP2p1s0f0np0"; do
  hca="${pair%%:*}"
  netdev="${pair##*:}"
  ip_line=$(ip -4 addr show "$netdev" 2>/dev/null | grep inet | head -1)
  if [ -n "$ip_line" ]; then
    ip=$(echo "$ip_line" | awk '{print $2}')
    pass "$netdev ($hca) → $ip"
  else
    fail "$netdev ($hca) — no IPv4 address"
  fi
done
echo ""

# ---- 4. GID table (find the IPv4 GID index automatically) ----
echo "--- 4. GID Index Auto-Detection ---"
GID_RESULTS=""
for hca in rocep1s0f0 roceP2p1s0f0; do
  best_idx=""
  best_gid=""
  for i in $(seq 0 7); do
    gid=$(cat /sys/class/infiniband/$hca/ports/1/gids/$i 2>/dev/null)
    if echo "$gid" | grep -q "^0000:.*ffff:"; then
      best_idx="$i"
      best_gid="$gid"
    fi
  done
  if [ -n "$best_idx" ]; then
    ip_hex=$(echo "$best_gid" | grep -oP 'ffff:\K[0-9a-f:]+' | tr -d ':')
    # reconstruct dotted decimal from hex
    a=$((16#${ip_hex:0:2})); b=$((16#${ip_hex:2:2}))
    c=$((16#${ip_hex:4:2})); d=$((16#${ip_hex:6:2}))
    pass "$hca: IPv4 GID at index $best_idx → $a.$b.$c.$d"
    GID_RESULTS="$GID_RESULTS ${hca}:${best_idx}"
  else
    fail "$hca: no IPv4 GID found"
  fi
done

# Determine suggested NCCL_IB_GID_INDEX from what we found
SUGGESTED=$(echo "$GID_RESULTS" | grep -oP ':\K[0-9]' | paste -sd,)
if [ -n "$SUGGESTED" ]; then
  echo ""
  warn "Suggested NCCL_IB_GID_INDEX=\"$SUGGESTED\""
  if [ -f "$SCRIPT_DIR/.env" ]; then
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

# ---- 5. Connectivity ----
echo "--- 5. Cross-Node Connectivity (requires both nodes up) ---"
for peername in "spark01 (head)" "spark02 (worker)"; do
  warn "  Ping tests skipped — run manually: ping -c 2 10.0.1.<other>"
done
echo ""

# ---- 6. Docker GPU access ----
echo "--- 6. Docker GPU Access ---"
if docker info 2>/dev/null | grep -q "Runtimes:.*nvidia"; then
  pass "Docker NVIDIA runtime available"
else
  fail "Docker NVIDIA runtime NOT available — install nvidia-container-toolkit"
fi

if docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi 2>/dev/null | grep -q "NVIDIA-SMI"; then
  pass "GPU accessible inside container"
else
  fail "GPU not accessible — check nvidia-container-toolkit and docker restart"
fi
echo ""

# ---- Summary ----
echo "============================================================"
echo " Results: $PASS passed, $FAIL failed"
echo "============================================================"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

# DeepSeek Analysis and Next Steps — 2026-06-21

## Root Cause: GID Index Mismatch

Both nodes use `NCCL_IB_GID_INDEX="4,4"`, but the IPv4 RoCE GIDs live at
**different indices on each node**:

| Node | IPv4 GID index | Effective `NCCL_IB_GID_INDEX` needed |
|------|---------------|--------------------------------------|
| **spark01 (head)** | **2** | **`2,2`** |
| **spark02 (worker)** | **4** | **`4,4`** |

### Why this happens

On the head, both ConnectX-7 ports have their IPv4 GID at index **2**:
- `rocep1s0f0` GID 2 → `::ffff:0a00:0101` (10.0.1.1)
- `roceP2p1s0f0` GID 2 → `::ffff:0a00:0201` (10.0.2.1)

On the worker, both ports have their IPv4 GID at index **4**:
- `rocep1s0f0` GID 4 → `::ffff:0a00:0102` (10.0.1.2)
- `roceP2p1s0f0` GID 4 → `::ffff:0a00:0202` (10.0.2.2)

### Failure sequence

1. Head NCCL reads GID index 4 → gets all-zeros → `local GID ::`
2. Head tries to send QP with empty local GID → `ibv_modify_qp` fails with errno 61 (ENODATA)
3. Worker receives garbage/empty remote GID → `ibv_modify_qp` fails with errno 22 (EINVAL)
4. Both sides raise `NCCL error: unhandled system error`

## Why GID indices differ

The GID index depends on the order in which IP addresses are assigned to the
netdev and how the kernel/infiniband subsystem registers them. Even with
identical hardware and software, the GID table can differ between nodes if IPs
were configured in a different sequence, or if link-local IPv6 addresses
registered differently.

## Fix

**On spark01 (head):** Set `NCCL_IB_GID_INDEX="2,2"` in `head/.env`

**On spark02 (worker):** Keep `NCCL_IB_GID_INDEX="4,4"` in `worker/.env`

This means the two `.env` files are **node-specific** and cannot be identical.

## Next Steps

1. **Fix the .env** on the head node
2. **Run the diagnostic script** on both nodes:
   ```bash
   ./04_check_nccl.sh
   ```
   The script auto-detects the correct GID index and warns on mismatch.
3. **Restart worker first**, then head:
   ```bash
   # On spark02 (worker):
   cd worker && docker compose down && ./01_up.sh

   # On spark01 (head):
   cd head && docker compose down && ./01_up.sh
   ```
4. **Monitor logs** with:
   ```bash
   ./05_a_follow_logs.sh
   ```
   Look for NCCL handshake completing without error.

## Expected output on success

```
(Worker pid=58) INFO [parallel_state.py:1422] world_size=2 rank=1 local_rank=0
(Worker pid=58) INFO [pynccl.py:113] vLLM is using nccl==2.30.4
(Worker pid=58) INFO ... NCCL handshake complete  ← no ERROR
```

## Fallback if RDMA continues to fail

If the GID fix is not enough, try disabling RDMA entirely to isolate the issue:

```bash
# In .env on BOTH nodes:
NCCL_IB_DISABLE="1"
```

This forces NCCL over TCP on the management NIC (`enP7s7`). Performance will be
much lower but it confirms the problem is RDMA-specific (not a firewall or
reachability issue).

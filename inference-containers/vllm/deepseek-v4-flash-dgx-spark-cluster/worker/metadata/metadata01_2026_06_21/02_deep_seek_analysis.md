# DeepSeek Analysis and Next Steps — 2026-06-21 (Worker Copy)

See the head node for the full analysis:
`head/metadata/metadata01_2026_06_21/02_deep_seek_analysis.md`

## Quick Fixes

| Issue | Fix |
|-------|-----|
| Head GID mismatch | On spark01: `NCCL_IB_GID_INDEX="2,2"` in `head/.env` |
| Verify | Run `./04_check_nccl.sh` on each node |
| Fallback | Set `NCCL_IB_DISABLE="1"` in both `.env` files |

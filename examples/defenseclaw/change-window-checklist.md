# Change window: DefenseClaw + Vault `netclaw-change`

Use with [docs/DEFENSECLAW.md](../../docs/DEFENSECLAW.md) and [policies/netclaw-change.hcl](../../policies/netclaw-change.hcl).

1. **Approve** — CAB / ticket ID recorded.
2. **DefenseClaw** — allow only the tools needed for this window (`defenseclaw tool allow …`).
3. **Vault** — issue short-lived `netclaw-change` AppRole secret-id or token (TTL minutes–hours, not days).
4. **Execute** — NetClaw change tasks; confirm Vault audit + DefenseClaw alerts show the window.
5. **Revoke** — invalidate change credentials; `defenseclaw tool block` destructive/write tools again.
6. **Verify** — default AppRole is `netclaw-read` only; prod writes denied.

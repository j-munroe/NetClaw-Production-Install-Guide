# Scripts

Lab-oriented helpers. Prefer [INSTALL](../docs/INSTALL.md) for production-shaped TLS/Raft.

**Hub:** [../docs/README.md](../docs/README.md)

| Script | Purpose |
|--------|---------|
| [01-bootstrap-vault.sh](01-bootstrap-vault.sh) | Dev Vault container (`hashicorp/vault:latest`) |
| [02-enable-engines.sh](02-enable-engines.sh) | KV v2 + SSH engine + OTP role sketch |
| [03-write-sample-secrets.sh](03-write-sample-secrets.sh) | Strategy A sample secrets + policies |
| [04-configure-approle.sh](04-configure-approle.sh) | NetClaw AppRole |
| [05-install-ollama-models.sh](05-install-ollama-models.sh) | Pull `qwen3:30b` + `qwen3:8b` |

```bash
export VAULT_ADDR=...
export VAULT_TOKEN=...
./01-bootstrap-vault.sh   # or use a real install
./02-enable-engines.sh
./03-write-sample-secrets.sh
./04-configure-approle.sh
```

Next: [GITLAB](../docs/GITLAB.md) → [ANSIBLE](../docs/ANSIBLE.md) → [NETCLAW](../docs/NETCLAW.md).

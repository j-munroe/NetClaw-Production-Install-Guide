# Scripts (non-production reference)

These helpers illustrate CLI sequences. **They are not a production installer.**

For production: follow **[INSTALL.md](../docs/INSTALL.md)** (HA Raft, TLS, auto-unseal, audit, snapshots).

**Hub:** [../docs/README.md](../docs/README.md)

| Script | What it shows | Production? |
|--------|----------------|-------------|
| [01-bootstrap-vault.sh](01-bootstrap-vault.sh) | Disposable Docker Vault **dev** container | **No** — never for real secrets |
| [02-enable-engines.sh](02-enable-engines.sh) | KV v2 + SSH enable commands | Re-type against prod `VAULT_ADDR` |
| [03-write-sample-secrets.sh](03-write-sample-secrets.sh) | Example `kv put` path shapes | Use stage/prod values via controlled process |
| [04-configure-approle.sh](04-configure-approle.sh) | AppRole create sketch | Harden TTLs / policies per [SECURITY](../docs/SECURITY.md) |
| [05-install-ollama-models.sh](05-install-ollama-models.sh) | Pull Qwen3 tags | Pin versions on the production Ollama host |

```bash
# Against a real cluster only — never point these at prod with sample passwords
export VAULT_ADDR=https://vault.example.local:8200
export VAULT_CACERT=/path/to/ca.crt
export VAULT_TOKEN=...   # short-lived admin, not root for day-2
```

Next: [GITLAB](../docs/GITLAB.md) → [ANSIBLE](../docs/ANSIBLE.md) → [NETCLAW](../docs/NETCLAW.md).

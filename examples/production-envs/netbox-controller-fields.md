# NetBox fields / tags for production controllers

Suggested custom fields or tags so NetClaw and Ansible resolve controllers without secrets.

| Field / tag | Example | Used for |
|-------------|---------|----------|
| `controller` | `cvaas`, `strata-cloud-manager`, `zabbix`, `aruba-central-cnx`, … | Which plane owns the object |
| `controller_url` | `https://zabbix.example.local` | Non-secret base URL |
| `vault_path` | `platform/zabbix` or `network/prod/dc1/xr-pe-01/credentials` | Vault lookup |
| `vault_ssh_role` | `netclaw-troubleshoot` | IOS-XR / bastion SSH CA |
| `credential_env` | `stage` / `prod` | Path segment |
| `mcp_name` | `zabbix-mcp`, `arista-cvp`, `aruba-central-cnx` | DefenseClaw / OpenClaw registration name |

## Example devices

**IOS-XR PE**

- Name: `xr-pe-01`
- Platform: `iosxr`
- `controller`: `direct-ssh` (or empty)
- `vault_path`: `network/prod/core/xr-pe-01/credentials`
- `vault_ssh_role`: `netclaw-troubleshoot`

**CloudVision-managed EOS**

- `controller`: `cvaas`
- `controller_url`: (optional; global CVaaS in Vault)
- Inventory truth: CVaaS + NetBox cross-check

Do **not** store API tokens in NetBox.

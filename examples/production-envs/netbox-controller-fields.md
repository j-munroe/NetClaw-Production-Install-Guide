# NetBox fields / tags for production controllers

Suggested custom fields or tags so NetClaw and Ansible resolve controllers without secrets.

| Field / tag | Example | Used for |
|-------------|---------|----------|
| `controller` | `cvaas`, `strata-cloud-manager`, `zabbix`, `aruba-central-cnx`, `nexus-dashboard-san`, … | Which plane owns the object |
| `controller_url` | `https://zabbix.example.local` or `https://nd.example.local` | Non-secret base URL |
| `vault_path` | `platform/zabbix` or `platform/cisco/nexus-dashboard-san` or device path | Vault lookup |
| `vault_ssh_role` | `netclaw-troubleshoot` | IOS-XR / bastion SSH CA |
| `credential_env` | `stage` / `prod` | Path segment |
| `mcp_name` | `zabbix-mcp`, `arista-cvp`, `aruba-central-cnx`, `nexus-dashboard-san-mcp` | DefenseClaw / OpenClaw registration name |
| `san_fabric` | ND/NDFC fabric or site name | SAN switches under Nexus Dashboard |

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

**MDS / SAN switch (Nexus Dashboard SAN)**

- `controller`: `nexus-dashboard-san`
- `controller_url`: `https://nd.example.local`
- `vault_path`: `platform/cisco/nexus-dashboard-san`
- `san_fabric`: matching ND/NDFC fabric name
- Inventory truth: Nexus Dashboard SAN + NetBox cross-check

Do **not** store API tokens in NetBox.

# NetBox fields / tags for production controllers

Suggested custom fields or tags so NetClaw and Ansible resolve controllers without secrets.

| Field / tag | Example | Used for |
|-------------|---------|----------|
| `controller` | `cvaas`, `strata-cloud-manager`, `zabbix`, `aruba-central-cnx`, `nexus-dashboard-san`, `clearpass`, … | Which plane owns the object |
| `controller_url` | `https://zabbix.example.local`, `https://nd.example.local`, or `https://clearpass.example.local` | Non-secret base URL |
| `vault_path` | `platform/zabbix`, `platform/cisco/nexus-dashboard-san`, `platform/aruba/clearpass`, or device path | Vault lookup |
| `vault_ssh_role` | `netclaw-troubleshoot` | IOS-XR / bastion SSH CA |
| `credential_env` | `stage` / `prod` | Path segment |
| `mcp_name` | `zabbix-mcp`, `arista-cvp`, `aruba-central-cnx`, `nexus-dashboard-san-mcp`, `aruba-clearpass-mcp` | DefenseClaw / OpenClaw registration name |
| `san_fabric` | ND/NDFC fabric or site name | SAN switches under Nexus Dashboard |
| `nac` | `clearpass` | Edge devices enrolled via ClearPass NAC |

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

**ClearPass Policy Manager (NAC API)**

- Name: `clearpass-vip` (or cluster VIP hostname)
- `controller`: `clearpass`
- `controller_url`: `https://clearpass.example.local`
- `vault_path`: `platform/aruba/clearpass`
- `mcp_name`: `aruba-clearpass-mcp`
- Onboard / X.509 enrollment stays operational in ClearPass; this object is for API credentials in Vault only
- Edge APs/switches may carry tag `nac=clearpass` for correlation

Do **not** store API tokens in NetBox.

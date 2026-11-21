# Architecture

<!-- doc-nav:start -->
> **Hub:** [Documentation home](README.md) · **1. Design**  
> [Security](SECURITY.md) →
<!-- doc-nav:end -->

Trust zones and data flows for Vault as secrets SoT. Start the full reading path at [Documentation home](README.md).

## Trust boundaries

| Zone | Components | Secrets access |
|------|------------|----------------|
| **Secrets core** | Vault cluster, unseal operators, audit storage | All mounts (admin only) |
| **CI** | GitLab CE + Runners, Ansible in CI | JWT → Vault CLI (CE) or `secrets:vault` (Premium+) → role-scoped KV |
| **Workstation** | VS Code Dev Containers, local Ansible | OIDC/token/AppRole via host → `remoteEnv` |
| **Inventory** | NetBox Community, optional Orb Agent | Token in Vault; device *paths* in NetBox |
| **Agent** | NetClaw + Vault MCP + DefenseClaw + LLM (Claude/OpenAI/local) | AppRole → read (default); change role gated; model choice in [MODELS.md](MODELS.md) |
| **Network devices** | Routers/switches/firewalls | Accept SSH cert/OTP or static user from Vault |

```mermaid
flowchart LR
  subgraph zoneVault [Secrets core]
    V[(Vault)]
  end
  subgraph zoneCI [CI]
    GL[GitLab CE]
    R[Runners]
  end
  subgraph zoneWS [Workstation]
    DC[Dev Container]
  end
  subgraph zoneInv [Inventory]
    NB[NetBox]
  end
  subgraph zoneAgent [Agent]
    NC[NetClaw]
  end
  subgraph zoneNet [Network]
    D[Devices]
  end

  GL --> R
  R -->|JWT| V
  DC -->|OIDC/token| V
  NC -->|AppRole| V
  NB -.->|paths only| NC
  NB -.->|paths only| R
  V -->|SSH CA / KV| D
  NC --> D
  R --> D
```

## Data flow (troubleshoot)

```mermaid
sequenceDiagram
  actor Eng as Engineer
  participant NC as NetClaw
  participant V as Vault
  participant NB as NetBox
  participant Dev as Device

  Eng->>NC: Troubleshoot request
  NC->>NB: Resolve device + vault_path / ssh role
  NB-->>NC: Inventory metadata (no passwords)
  NC->>V: AppRole + KV read or ssh/sign
  V-->>NC: Creds / SSH cert (injected, not echoed)
  NC->>Dev: SSH / gNMI / pyATS
  Dev-->>NC: Evidence
  NC-->>Eng: Answer (secrets redacted)
```

## Data flow (CI / Ansible)

```mermaid
sequenceDiagram
  participant GL as GitLab job
  participant V as Vault
  participant AN as Ansible
  participant Dev as Device / API

  GL->>GL: id_tokens JWT
  GL->>V: auth/jwt/login (CE Vault CLI)
  V-->>GL: VAULT_TOKEN
  GL->>AN: Export token + run playbook
  AN->>V: community.hashi_vault lookup
  V-->>AN: Secret fields
  AN->>Dev: Configure / show
```

Premium+ may replace the CLI login with declarative `secrets:vault` injection — see [GITLAB.md](GITLAB.md).

## Data flow (Dev Container)

```mermaid
flowchart LR
  H[Host: vault login OIDC] --> T[VAULT_TOKEN / ~/.vault-token]
  T --> RE[Dev Container remoteEnv]
  RE --> AN[Ansible / scripts]
  AN --> V[(Vault)]
  V -->|audit: human identity| A[Audit log]
```

## What lives where

| Data | Store |
|------|-------|
| Device hostname, role, site, IP, platform | **NetBox** |
| Vault path / credential role name | **NetBox** custom field or naming convention |
| Username / password / enable / API tokens | **Vault KV** (`secret/network/{env}/{site}/{device}/…`) |
| Short-lived SSH | **Vault SSH CA** ([SSH_CA.md](SSH_CA.md)) |
| X.509 / 802.1X / many device TLS certs | **HPE ClearPass Onboard** (existing) |
| Automation code / Dev Container definition | **GitLab** (no secret values) |
| Agent skills / MCP config | **NetClaw host** (no secret values in git) |

Path strategies and alternatives: [PATH_LAYOUT.md](PATH_LAYOUT.md).

```mermaid
flowchart TB
  NB[NetBox] -->|hostname site role vault_path| Meta[Metadata only]
  V[(Vault)] -->|password enable api_token SSH cert| Sec[Secrets]
  GL[GitLab] -->|playbooks skills CI YAML| Code[Code only]
  Meta --> Auto[Automation]
  Sec --> Auto
  Code --> Auto
  Auto --> Dev[Devices]
```

## Auth method map

| Client | Auth | Policy |
|--------|------|--------|
| Human admins / Dev Containers | OIDC or short-lived token | lab read / ops |
| GitLab CI / Ansible in CI | JWT | `gitlab-ci` or `ansible-automation` |
| Ansible controller (non-CI) | AppRole | `ansible-automation` |
| NetClaw | AppRole | `netclaw-read` / `netclaw-change` |
| Orb / discovery | AppRole or token | `netbox-agent` |

```mermaid
flowchart TB
  V[(Vault)]
  H[Human / Dev Container] -->|OIDC| V
  G[GitLab CI] -->|JWT| V
  N[NetClaw] -->|AppRole| V
  C[Ansible controller] -->|AppRole| V
  O[Orb Agent] -->|AppRole/token| V
```

## Failure modes

| Failure | Expected behavior |
|---------|-------------------|
| Vault sealed / down | Jobs and NetClaw fail closed |
| Wrong GitLab branch | JWT role denies `prod/` |
| NetClaw asks for secret display | MCP/skill redacts; inject to file/tool only |
| Compromised AppRole secret-id | Rotate secret-id; audit prior reads |

## Network diagram (logical)

```mermaid
flowchart LR
  GL[GitLab] -->|JWT| V[(Vault :8200)]
  R[Runners] -->|JWT / CLI| V
  NC[NetClaw] -->|AppRole| V
  NB[NetBox / Orb] -->|token for API only| V
  NB -->|inventory API no passwords| NC
  NB --> R
```

<!-- doc-footer:start -->
---

**Hub:** [Documentation home](README.md) · **Reading path:** [Design](ARCHITECTURE.md) → [Build](INSTALL.md) → [Integrate](GITLAB.md) → [Agent](NETCLAW.md) → [Reference](DIAGRAMS.md)
<!-- doc-footer:end -->

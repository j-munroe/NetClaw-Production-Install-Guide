# Vault Documentation

**HashiCorp Vault** as the secrets system of record for agentic network troubleshooting with **GitLab CE**, **Ansible**, **NetBox**, **Dev Containers**, and **NetClaw**.

## Start here

| Audience | Go to |
|----------|--------|
| **First-time readers** | **[docs/README.md](docs/README.md)** — reading path & doc hub |
| **Operators installing Vault** | [docs/INSTALL.md](docs/INSTALL.md) |
| **Delivery / project plan** | [docs/WORKPLAN.md](docs/WORKPLAN.md) |
| **Diagrams** | [docs/DIAGRAMS.md](docs/DIAGRAMS.md) |

```mermaid
flowchart LR
  Hub[docs/README.md] --> Design[1 Design]
  Hub --> Build[2 Build]
  Hub --> Integ[3 Integrate]
  Hub --> Agent[4 Agent]
  Hub --> Ref[5 Reference]
  Design --> Arch[Architecture]
  Build --> Install[Install + paths]
  Integ --> GL[GitLab / Ansible / NetBox]
  Agent --> NC[NetClaw / SSH CA / models]
```

## Stack at a glance

| Component | Role |
|-----------|------|
| **HashiCorp Vault** | Secrets SoT (KV, SSH CA, optional PKI) |
| **GitLab CE + Runners** | JWT → Vault CLI (Premium `secrets:vault` optional) |
| **Ansible** | `community.hashi_vault` lookups |
| **VS Code Dev Containers** | Host Vault auth via `remoteEnv` |
| **NetBox Community** | Inventory + `vault_path` (no passwords) |
| **NetClaw** | Agent + Vault MCP |
| **ClearPass Onboard** | X.509 / NAC (separate from SSH CA) |

## System overview

```mermaid
flowchart TB
  subgraph consumers [Consumers]
    NC[NetClaw]
    GL[GitLab CE + Runners]
    AN[Ansible]
    DC[Dev Containers]
  end

  subgraph sot [Sources of truth]
    NB[NetBox inventory + vault_path]
    V[(HashiCorp Vault)]
  end

  subgraph access [Device access]
    B[SSH bastion / capable NOS]
    D[Network devices]
  end

  subgraph pki [Separate X.509 PKI]
    CP[ClearPass Onboard]
  end

  NC -->|AppRole / Vault MCP| V
  GL -->|JWT + Vault CLI| V
  AN -->|JWT or AppRole + lookups| V
  DC -->|OIDC / token via host| V
  NB -->|paths only| NC
  NB -->|paths only| AN
  V -->|SSH CA / KV| B
  B --> D
  CP -->|802.1X / device TLS| D
```

## Lab quick start

```bash
cd scripts
./01-bootstrap-vault.sh
./02-enable-engines.sh
./03-write-sample-secrets.sh
./04-configure-approle.sh
```

Then follow **[docs/README.md](docs/README.md)** from **Build → Integrate**. Versions: [docs/VERSIONS.md](docs/VERSIONS.md).

## Repository layout

```
.
├── README.md          ← you are here (landing)
├── docs/              ← guides (start at docs/README.md)
├── policies/          ← example Vault HCL
├── scripts/           ← lab bootstrap
└── examples/          ← CI / Ansible / SSH CA / LLM snippets
```

| Folder | Index |
|--------|--------|
| [docs/](docs/README.md) | All guides in reading order |
| [examples/](examples/README.md) | Copy-paste snippets by topic |
| [policies/](policies/README.md) | Vault ACL examples |
| [scripts/](scripts/README.md) | Bootstrap helpers |

## Security note

Examples use **placeholders only**. Never commit real tokens, unseal keys, or device passwords. Production: pin image/package versions after lab validation ([VERSIONS.md](docs/VERSIONS.md)).

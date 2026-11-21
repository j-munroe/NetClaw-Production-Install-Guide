# Documentation home

HashiCorp Vault as the secrets system of record for **GitLab CE**, **Ansible**, **NetBox**, **Dev Containers**, and **NetClaw**.

Root overview and lab quick start: [../README.md](../README.md)

---

## How to read this repo

Follow the path in order the first time. Skip to a section later when you need a deep dive.

```mermaid
flowchart LR
  A[1 Design] --> B[2 Build]
  B --> C[3 Integrate]
  C --> D[4 Agent]
  D --> E[5 Reference]
```

| Step | Focus | Start with |
|------|--------|------------|
| **1. Design** | Why Vault, trust boundaries, delivery phases, security rules | [ARCHITECTURE](ARCHITECTURE.md) → [SECURITY](SECURITY.md) → [WORKPLAN](WORKPLAN.md) |
| **2. Build** | Install Vault, path layout, version policy | [VERSIONS](VERSIONS.md) → [INSTALL](INSTALL.md) → [PATH_LAYOUT](PATH_LAYOUT.md) |
| **3. Integrate** | CI, Ansible, Dev Containers, NetBox | [GITLAB](GITLAB.md) → [ANSIBLE](ANSIBLE.md) → [DEVCONTAINERS](DEVCONTAINERS.md) → [NETBOX](NETBOX.md) |
| **4. Agent** | NetClaw, models, local LLM, SSH CA | [NETCLAW](NETCLAW.md) → [MODELS](MODELS.md) → [LOCAL_LLM](LOCAL_LLM.md) → [SSH_CA](SSH_CA.md) |
| **5. Reference** | Diagrams, examples, policies, scripts | [DIAGRAMS](DIAGRAMS.md) · [../examples/](../examples/) · [../policies/](../policies/) · [../scripts/](../scripts/) |

---

## 1. Design

| Doc | What you get |
|-----|----------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Trust zones, data flows, what lives in NetBox vs Vault |
| [SECURITY.md](SECURITY.md) | Least privilege, TTLs, CE log hygiene, rotation |
| [WORKPLAN.md](WORKPLAN.md) | Phased delivery with acceptance criteria |

## 2. Build

| Doc | What you get |
|-----|----------------|
| [VERSIONS.md](VERSIONS.md) | Latest-stable policy and current release snapshot |
| [INSTALL.md](INSTALL.md) | Bootstrap Vault, engines, auth, SSH CA intro |
| [PATH_LAYOUT.md](PATH_LAYOUT.md) | KV path strategies (Strategy A default) |

## 3. Integrate

| Doc | What you get |
|-----|----------------|
| [GITLAB.md](GITLAB.md) | CE: JWT + Vault CLI; Premium: optional `secrets:vault` |
| [ANSIBLE.md](ANSIBLE.md) | Move playbooks to `community.hashi_vault` lookups |
| [DEVCONTAINERS.md](DEVCONTAINERS.md) | Host Vault auth into VS Code Dev Containers |
| [NETBOX.md](NETBOX.md) | Inventory + `vault_path`; tokens in Vault only |

## 4. Agent (NetClaw)

| Doc | What you get |
|-----|----------------|
| [NETCLAW.md](NETCLAW.md) | Vault MCP, AppRole, redaction rules |
| [MODELS.md](MODELS.md) | Claude vs OpenAI vs local |
| [LOCAL_LLM.md](LOCAL_LLM.md) | Ollama + Qwen3 install |
| [SSH_CA.md](SSH_CA.md) | SSH CA vs ClearPass; zero-touch seeding |

## 5. Reference

| Doc / folder | What you get |
|--------------|----------------|
| [DIAGRAMS.md](DIAGRAMS.md) | Index of Mermaid diagrams |
| [../examples/](../examples/README.md) | CI, Ansible, Dev Container, SSH CA, LLM snippets |
| [../policies/](../policies/README.md) | Example HCL policies |
| [../scripts/](../scripts/README.md) | Lab bootstrap helpers |

---

## Stack assumptions

- **GitLab Community Edition** on-prem (JWT + Vault CLI, not `secrets:vault`)
- **NetBox Community** as inventory SoT (paths, not passwords)
- **ClearPass Onboard** for X.509 / NAC (not Vault SSH CA)
- **Latest stable** package versions ([VERSIONS.md](VERSIONS.md))

---

## Suggested first week

1. Read [ARCHITECTURE](ARCHITECTURE.md) + [SECURITY](SECURITY.md).
2. Skim [WORKPLAN](WORKPLAN.md) Phase 0–2.
3. Run lab scripts in [../scripts/](../scripts/README.md) per [INSTALL](INSTALL.md).
4. Adopt [PATH_LAYOUT](PATH_LAYOUT.md) Strategy A; write one lab device secret.
5. Wire one GitLab CE job ([GITLAB](GITLAB.md)) and one playbook ([ANSIBLE](ANSIBLE.md)).

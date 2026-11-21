# Documentation home

HashiCorp Vault as the **production** secrets system of record for **GitLab CE**, **Ansible**, **NetBox**, **Dev Containers**, and **NetClaw**.

Root overview: [../README.md](../README.md)

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
| **1. Design** | Trust boundaries, security, delivery, best practices | [ARCHITECTURE](ARCHITECTURE.md) → [SECURITY](SECURITY.md) → [WORKPLAN](WORKPLAN.md) → [BEST_PRACTICES](BEST_PRACTICES.md) |
| **2. Build** | HA install, pinned versions, path layout | [VERSIONS](VERSIONS.md) → [INSTALL](INSTALL.md) → [PATH_LAYOUT](PATH_LAYOUT.md) |
| **3. Integrate** | CI, Ansible, Dev Containers, NetBox | [GITLAB](GITLAB.md) → [ANSIBLE](ANSIBLE.md) → [DEVCONTAINERS](DEVCONTAINERS.md) → [NETBOX](NETBOX.md) |
| **4. Agent** | NetClaw, DefenseClaw, models, SSH CA, prod envs | [NETCLAW](NETCLAW.md) → [DEFENSECLAW](DEFENSECLAW.md) → [MODELS](MODELS.md) → [LOCAL_LLM](LOCAL_LLM.md) → [SSH_CA](SSH_CA.md) → [PRODUCTION_ENVIRONMENTS](PRODUCTION_ENVIRONMENTS.md) |
| **5. Reference** | Diagrams, examples, policies, scripts | [DIAGRAMS](DIAGRAMS.md) · [../examples/](../examples/) · [../policies/](../policies/) · [../scripts/](../scripts/) |

---

## 1. Design

| Doc | What you get |
|-----|----------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Trust zones, data flows, NetBox vs Vault |
| [SECURITY.md](SECURITY.md) | Fail closed, TTLs, HA/ops controls, rotation |
| [WORKPLAN.md](WORKPLAN.md) | Phased production delivery + acceptance |
| [BEST_PRACTICES.md](BEST_PRACTICES.md) | Best practices per topic (Vault → NetClaw stack) |

## 2. Build

| Doc | What you get |
|-----|----------------|
| [VERSIONS.md](VERSIONS.md) | Pin-for-production version policy |
| [INSTALL.md](INSTALL.md) | 3+ node Raft, TLS, auto-unseal, audit, backup |
| [PATH_LAYOUT.md](PATH_LAYOUT.md) | KV Strategy A for `stage` / `prod` |

## 3. Integrate

| Doc | What you get |
|-----|----------------|
| [GITLAB.md](GITLAB.md) | CE: JWT + Vault CLI; separate stage/prod roles |
| [ANSIBLE.md](ANSIBLE.md) | `community.hashi_vault` lookups |
| [DEVCONTAINERS.md](DEVCONTAINERS.md) | OIDC / host auth into Dev Containers |
| [NETBOX.md](NETBOX.md) | Inventory + `vault_path`; tokens in Vault only |

## 4. Agent (NetClaw)

| Doc | What you get |
|-----|----------------|
| [NETCLAW.md](NETCLAW.md) | Vault MCP, AppRole, redaction |
| [DEFENSECLAW.md](DEFENSECLAW.md) | Open-source DefenseClaw + optional OpenShell |
| [MODELS.md](MODELS.md) | Claude vs OpenAI vs local |
| [LOCAL_LLM.md](LOCAL_LLM.md) | Production-capable Ollama + Qwen3 |
| [SSH_CA.md](SSH_CA.md) | SSH CA vs ClearPass; zero-touch seeding |
| [PRODUCTION_ENVIRONMENTS.md](PRODUCTION_ENVIRONMENTS.md) | Connect NetClaw to your controllers, NMS, DDI, XR |

## 5. Reference

| Doc / folder | What you get |
|--------------|----------------|
| [DIAGRAMS.md](DIAGRAMS.md) | Index of Mermaid diagrams |
| [../examples/](../examples/README.md) | CI, Ansible, Dev Container, SSH CA, LLM snippets |
| [../policies/](../policies/README.md) | Stage + prod HCL examples |
| [../scripts/](../scripts/README.md) | Non-production command references only |

---

## Stack assumptions

- **Production Vault**: HA Raft, TLS, auto-unseal, audit, snapshots — [INSTALL.md](INSTALL.md)
- **GitLab Community Edition** on-prem (JWT + Vault CLI, not `secrets:vault`)
- **NetBox Community** as inventory SoT (paths, not passwords)
- **ClearPass Onboard** for X.509 / NAC (not Vault SSH CA)
- **DefenseClaw** (open source) for NetClaw MCP scan + runtime guardrails ([DEFENSECLAW.md](DEFENSECLAW.md))
- **Pinned** package versions in production ([VERSIONS.md](VERSIONS.md))

---

## Suggested cutover sequence

1. Read [ARCHITECTURE](ARCHITECTURE.md) + [SECURITY](SECURITY.md) + [BEST_PRACTICES](BEST_PRACTICES.md); sign off [WORKPLAN](WORKPLAN.md) Phase 0.
2. Deploy HA Vault per [INSTALL](INSTALL.md); complete raft peer check + snapshot restore drill.
3. Adopt [PATH_LAYOUT](PATH_LAYOUT.md) Strategy A; load `stage` secrets first, then `prod`.
4. Wire separate GitLab JWT roles ([GITLAB](GITLAB.md)) and one playbook ([ANSIBLE](ANSIBLE.md)).
5. Enable NetClaw AppRole on stage; wire DefenseClaw observe→action ([NETCLAW](NETCLAW.md), [DEFENSECLAW](DEFENSECLAW.md)).
6. Promote prod paths after audit review; roll SSH CA + zero-touch bastion trust ([SSH_CA](SSH_CA.md)).
7. Connect production platforms per [PRODUCTION_ENVIRONMENTS](PRODUCTION_ENVIRONMENTS.md) (CVaaS, Strata, Central, Cloudflare, XR, …).

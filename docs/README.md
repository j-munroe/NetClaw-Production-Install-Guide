# Documentation home

Production documentation for **NetClaw** and associated components — with **HashiCorp Vault** as the secrets system of record for **GitLab CE**, **Ansible**, **NetBox**, **Dev Containers**, **DefenseClaw**, MCP servers, and your network platforms.

Root overview: [../README.md](../README.md)

**Installing the whole stack?** Start here → **[STACK_INSTALL.md](STACK_INSTALL.md)**

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
| **2. Build** | Full stack install → Vault detail → paths | [VERSIONS](VERSIONS.md) → [STACK_INSTALL](STACK_INSTALL.md) → [INSTALL](INSTALL.md) → [PATH_LAYOUT](PATH_LAYOUT.md) |
| **3. Integrate** | CI, Ansible, Dev Containers, NetBox | [GITLAB](GITLAB.md) → [ANSIBLE](ANSIBLE.md) → [DEVCONTAINERS](DEVCONTAINERS.md) → [NETBOX](NETBOX.md) |
| **4. Agent** | MCP → NetClaw → DefenseClaw → models → SSH CA → prod envs | [MCP](MCP.md) → [NETCLAW](NETCLAW.md) → [DEFENSECLAW](DEFENSECLAW.md) → [MODELS](MODELS.md) → [LOCAL_LLM](LOCAL_LLM.md) → [SSH_CA](SSH_CA.md) → [PRODUCTION_ENVIRONMENTS](PRODUCTION_ENVIRONMENTS.md) |
| **5. Reference** | Diagrams, examples, policies, scripts | [DIAGRAMS](DIAGRAMS.md) · [../examples/](../examples/) · [../policies/](../policies/) · [../scripts/](../scripts/) |

---

## 1. Design

| Doc | What you get |
|-----|----------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Trust zones, data flows, NetBox vs Vault |
| [SECURITY.md](SECURITY.md) | Fail closed, TTLs, HA/ops controls, rotation |
| [WORKPLAN.md](WORKPLAN.md) | Phased production delivery + acceptance |
| [BEST_PRACTICES.md](BEST_PRACTICES.md) | Best practices per topic (full stack) |

## 2. Build

| Doc | What you get |
|-----|----------------|
| [VERSIONS.md](VERSIONS.md) | Pin-for-production version policy |
| [STACK_INSTALL.md](STACK_INSTALL.md) | **Complete** NetClaw stack production install runbook |
| [INSTALL.md](INSTALL.md) | Vault HA detail (Raft, TLS, auto-unseal, backup) |
| [PATH_LAYOUT.md](PATH_LAYOUT.md) | KV Strategy A for `stage` / `prod` + controllers |

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
| [MCP.md](MCP.md) | What MCP is and how to set up your first server |
| [NETCLAW.md](NETCLAW.md) | Vault MCP, AppRole, redaction |
| [DEFENSECLAW.md](DEFENSECLAW.md) | Open-source DefenseClaw + optional OpenShell |
| [MODELS.md](MODELS.md) | Claude vs OpenAI vs local |
| [LOCAL_LLM.md](LOCAL_LLM.md) | Production-capable Ollama + Qwen3 |
| [SSH_CA.md](SSH_CA.md) | SSH CA vs ClearPass; zero-touch seeding |
| [PRODUCTION_ENVIRONMENTS.md](PRODUCTION_ENVIRONMENTS.md) | Controllers, NMS, DDI, ND SAN, XR, … |

## 5. Reference

| Doc / folder | What you get |
|--------------|----------------|
| [DIAGRAMS.md](DIAGRAMS.md) | Index of Mermaid diagrams |
| [../examples/](../examples/README.md) | CI, Ansible, stack checklist, MCP, platforms |
| [../policies/](../policies/README.md) | Stage + prod HCL examples |
| [../scripts/](../scripts/README.md) | Non-production command references only |

---

## Stack assumptions

- **Full stack install runbook**: [STACK_INSTALL.md](STACK_INSTALL.md)
- **Production Vault**: HA Raft, TLS, auto-unseal, audit, snapshots — [INSTALL.md](INSTALL.md)
- **GitLab Community Edition** on-prem (JWT + Vault CLI, not `secrets:vault`)
- **NetBox Community** as inventory SoT (paths, not passwords)
- **ClearPass Onboard** for X.509 / NAC (not Vault SSH CA)
- **DefenseClaw** (open source) for NetClaw MCP scan + runtime guardrails ([DEFENSECLAW.md](DEFENSECLAW.md))
- **Pinned** package versions in production ([VERSIONS.md](VERSIONS.md))

---

## Suggested cutover sequence

1. Read [ARCHITECTURE](ARCHITECTURE.md) + [SECURITY](SECURITY.md) + [BEST_PRACTICES](BEST_PRACTICES.md); sign off [WORKPLAN](WORKPLAN.md) Phase 0.
2. Follow **[STACK_INSTALL](STACK_INSTALL.md)** (Vault HA is step 2 inside that runbook).
3. Adopt [PATH_LAYOUT](PATH_LAYOUT.md); load `stage` secrets first, then `prod`.
4. Wire GitLab CE JWT + Ansible + NetBox per the stack runbook.
5. NetClaw + MCP + DefenseClaw observe→action; SSH CA; day-1 platforms ([PRODUCTION_ENVIRONMENTS](PRODUCTION_ENVIRONMENTS.md)).
6. Complete STACK_INSTALL §12 acceptance; then operate ([WORKPLAN](WORKPLAN.md) Phase 7).

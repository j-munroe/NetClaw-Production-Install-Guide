# Software versions policy

<!-- doc-nav:start -->
> **Hub:** [Documentation home](README.md) · **2. Build**  
> ← [Workplan](WORKPLAN.md) · [Install](INSTALL.md) →
<!-- doc-nav:end -->

This repository assumes **the latest stable release** of each package unless a note says otherwise.

| Package | Policy | Current latest (as of 2026-11-21) |
|---------|--------|-----------------------------------|
| **HashiCorp Vault** (CE) | Latest stable from HashiCorp apt/yum or `hashicorp/vault:latest` | **2.2.2** |
| **Vault CLI** (CI images) | Same line as server — `hashicorp/vault:latest` | **2.2.2** |
| **Ollama** | Install script / `ollama/ollama:latest` | **0.40.x** |
| **Local models** | Latest tags for chosen family (`qwen3:30b`, `qwen3:8b`, …) | Pull at install time |
| **community.hashi_vault** | Latest Galaxy release | **7.1.0** |
| **hvac** (Python) | Latest PyPI | **2.4.0** |
| **NetClaw / OpenClaw** (automateyournetwork) | Latest GitHub release of your chosen harness | Check project releases |
| **netclaw-dev container** (optional Docker path) | `ghcr.io/netclaw-dev/netclaw:latest` | **0.28.3** |
| **vault-mcp-server** | `@latest` / newest release binary | Install at deploy time |
| **Ubuntu (Vault host)** | Current LTS | **24.04** |
| **GitLab CE + Runner** | Latest CE / Runner your org will run | Track GitLab releases |

## How examples are written

- Docker tags use **`:latest`** for lab/docs so pulls track current stable.
- For **production**, pin an immutable tag (e.g. `hashicorp/vault:2.2.2`, `ghcr.io/netclaw-dev/netclaw:0.28.3`) after validation, then upgrade deliberately.
- Ansible `requirements.yml` uses a minimum floor that allows the newest collection (`>=7.1.0`).
- `pip install hvac` / `ansible-galaxy install community.hashi_vault` without a pin installs latest; CI should record the resolved versions in a lockfile or image build log.

## Refresh this table

When bumping docs, re-check:

- https://releases.hashicorp.com/vault/
- https://github.com/ollama/ollama/releases
- https://galaxy.ansible.com/ui/repo/published/community/hashi_vault/
- https://pypi.org/project/hvac/
- https://github.com/netclaw-dev/netclaw/releases (Docker harness)
- https://github.com/automateyournetwork/netclaw/releases (network agent)

<!-- doc-footer:start -->
---

**Hub:** [Documentation home](README.md) · **Reading path:** [Design](ARCHITECTURE.md) → [Build](INSTALL.md) → [Integrate](GITLAB.md) → [Agent](NETCLAW.md) → [Reference](DIAGRAMS.md)
<!-- doc-footer:end -->

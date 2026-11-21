# Software versions policy

<!-- doc-nav:start -->
> **Hub:** [Documentation home](README.md) · **2. Build**  
> ← [Best practices](BEST_PRACTICES.md) · [Install](INSTALL.md) →
<!-- doc-nav:end -->

**Production default: pin immutable versions.** Track upstream “latest stable” only to decide *what* to pin next — do not run unpinned `:latest` in production.

| Package | Production policy | Current stable reference (as of 2026-11-21) |
|---------|-------------------|-----------------------------------------------|
| **HashiCorp Vault** (CE) | Pin package / image tag (e.g. `2.2.2`) | **2.2.2** |
| **Vault CLI** (CI images) | Same pinned line as server | **2.2.2** |
| **Ollama** | Pin release; upgrade via change control | **0.40.x** |
| **Local models** | Pin model tags/digests after eval | e.g. `qwen3:30b`, `qwen3:8b` |
| **community.hashi_vault** | Pin Galaxy version in `requirements.yml` | **7.1.0** |
| **hvac** (Python) | Pin in lockfile / image | **2.4.0** |
| **NetClaw / OpenClaw** | Pin GitHub release / image digest | Check project releases |
| **netclaw container** | Pin tag + digest | e.g. **0.28.3** |
| **vault-mcp-server** | Pin release binary | Install at deploy time |
| **DefenseClaw** | Pin GitHub release tag; verify installer checksums | e.g. **1.0.4** (confirm before cutover) |
| **OpenShell** (optional) | Pin installer digest if used | NVIDIA OpenShell releases |
| **Ubuntu (Vault hosts)** | Current LTS | **24.04** |
| **GitLab CE + Runner** | Org-approved CE / Runner versions | Track GitLab releases |

## How examples are written

- Snippets may show a concrete version (e.g. `vault=2.2.2-1`) as the **starting pin**.
- `:latest` appears only in non-production reference scripts under [`../scripts/`](../scripts/README.md) — do not copy that pattern into prod compose/CI.
- Ansible `requirements.yml` should pin an exact collection version in production (floor `>=` is for migration only).
- Record resolved versions in image build logs or lockfiles at every promote.

## Refresh this table

When planning an upgrade, re-check:

- https://releases.hashicorp.com/vault/
- https://github.com/ollama/ollama/releases
- https://galaxy.ansible.com/ui/repo/published/community/hashi_vault/
- https://pypi.org/project/hvac/
- https://github.com/netclaw-dev/netclaw/releases
- https://github.com/automateyournetwork/netclaw/releases
- https://github.com/cisco-ai-defense/defenseclaw/releases

Upgrade Vault with a change window: standby → active rolling restart, snapshot before, verify `raft list-peers` after.

<!-- doc-footer:start -->
---

**Hub:** [Documentation home](README.md) · **Reading path:** [Design](ARCHITECTURE.md) → [Build](INSTALL.md) → [Integrate](GITLAB.md) → [Agent](NETCLAW.md) → [Reference](DIAGRAMS.md)
<!-- doc-footer:end -->

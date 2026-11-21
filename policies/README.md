# Vault policies

Example HCL for this stack. Apply after engines/paths exist ([INSTALL](../docs/INSTALL.md), [PATH_LAYOUT](../docs/PATH_LAYOUT.md)).

**Hub:** [../docs/README.md](../docs/README.md)

| File | Intended identity |
|------|-------------------|
| [gitlab-ci.hcl](gitlab-ci.hcl) | GitLab JWT — **stage** (optional `lab`) |
| [gitlab-ci-prod.hcl](gitlab-ci-prod.hcl) | GitLab JWT — **prod** (protected branches only) |
| [ansible-automation.hcl](ansible-automation.hcl) | Ansible CI / controller |
| [netclaw-read.hcl](netclaw-read.hcl) | NetClaw troubleshoot (stage first; prod gated) |
| [netclaw-change.hcl](netclaw-change.hcl) | NetClaw change window (approval-gated) |
| [netbox-agent.hcl](netbox-agent.hcl) | Orb / discovery agent |

```bash
vault policy write gitlab-ci policies/gitlab-ci.hcl
vault policy write gitlab-ci-prod policies/gitlab-ci-prod.hcl
vault policy write ansible-automation policies/ansible-automation.hcl
vault policy write netclaw-read policies/netclaw-read.hcl
vault policy write netclaw-change policies/netclaw-change.hcl
vault policy write netbox-agent policies/netbox-agent.hcl
```

Bind **separate JWT / AppRole roles** to stage vs prod policies — never one role that can read all of `network/*`.

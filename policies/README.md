# Vault policies

Example HCL for this stack. Apply after engines/paths exist ([INSTALL](../docs/INSTALL.md), [PATH_LAYOUT](../docs/PATH_LAYOUT.md)).

**Hub:** [../docs/README.md](../docs/README.md)

| File | Intended identity |
|------|-------------------|
| [gitlab-ci.hcl](gitlab-ci.hcl) | GitLab JWT lab automation |
| [ansible-automation.hcl](ansible-automation.hcl) | Ansible CI / controller |
| [netclaw-read.hcl](netclaw-read.hcl) | NetClaw troubleshoot (default) |
| [netclaw-change.hcl](netclaw-change.hcl) | NetClaw change window (gated) |
| [netbox-agent.hcl](netbox-agent.hcl) | Orb / discovery agent |

```bash
vault policy write gitlab-ci policies/gitlab-ci.hcl
vault policy write ansible-automation policies/ansible-automation.hcl
vault policy write netclaw-read policies/netclaw-read.hcl
vault policy write netclaw-change policies/netclaw-change.hcl
vault policy write netbox-agent policies/netbox-agent.hcl
```

Lab seed script also loads these: [../scripts/03-write-sample-secrets.sh](../scripts/03-write-sample-secrets.sh).

# Zero-touch Vault SSH CA trust seeding

Companion to [`../../docs/SSH_CA.md`](../../docs/SSH_CA.md) — **best method for this stack:** NetBox → GitLab CE → Ansible role installs `TrustedUserCAKeys` (CA **public** key only). Optionally enroll host certs via AppRole later.

## Layout

| File | Purpose |
|------|---------|
| `vault-ssh-ca.pub.example` | Placeholder — replace with real `vault read -field=public_key ssh/config/ca` |
| `ansible-role-tasks.yml` | Idempotent trust-anchor tasks |
| `gitlab-ci-seed-staged.yml` | CE-friendly pipeline fragment: JWT optional; Ansible against NetBox `staged` hosts |

## Flow

1. Publish CA pubkey into `files/vault-ssh-ca.pub` (not a secret).
2. When NetBox device/VM is `staged`, pipeline runs `vault_ssh_ca_trust`.
3. Mark device `active`; NetClaw uses `ssh/sign/...` for user certs at connect time.

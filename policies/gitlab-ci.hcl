# GitLab CI JWT role — non-prod (stage) automation
# vault policy write gitlab-ci policies/gitlab-ci.hcl
#
# For production paths use gitlab-ci-prod.hcl on a separate JWT role.
# Env name "lab" is optional isolated gear — not a Vault install mode.

path "secret/data/network/stage/*" {
  capabilities = ["read"]
}
path "secret/metadata/network/stage/*" {
  capabilities = ["list", "read"]
}

# Optional isolated non-prod gear
path "secret/data/network/lab/*" {
  capabilities = ["read"]
}
path "secret/metadata/network/lab/*" {
  capabilities = ["list", "read"]
}

path "secret/data/platform/netbox" {
  capabilities = ["read"]
}
path "secret/metadata/platform/netbox" {
  capabilities = ["read"]
}

path "ssh/sign/netclaw-troubleshoot" {
  capabilities = ["create", "update"]
}

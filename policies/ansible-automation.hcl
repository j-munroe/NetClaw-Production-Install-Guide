# Ansible automation (CI controller or AppRole)
# vault policy write ansible-automation policies/ansible-automation.hcl
#
# Scope to stage by default. Duplicate with prod paths on a separate role for prod CI.

path "secret/data/network/stage/*" {
  capabilities = ["read"]
}
path "secret/metadata/network/stage/*" {
  capabilities = ["list", "read"]
}

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

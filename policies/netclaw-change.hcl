# NetClaw elevated: change windows only (pair with DefenseClaw tool allow)
# vault policy write netclaw-change policies/netclaw-change.hcl
# Docs: docs/DEFENSECLAW.md · examples/defenseclaw/change-window-checklist.md

path "secret/data/network/stage/*" {
  capabilities = ["read", "create", "update"]
}
path "secret/metadata/network/stage/*" {
  capabilities = ["list", "read"]
}

# Prod change: separate policy + stricter JWT/AppRole binding in production
# path "secret/data/network/prod/*" {
#   capabilities = ["read", "create", "update"]
# }
# path "secret/metadata/network/prod/*" {
#   capabilities = ["list", "read"]
# }

path "secret/data/platform/netbox" {
  capabilities = ["read"]
}
path "secret/metadata/platform/netbox" {
  capabilities = ["read"]
}

path "ssh/sign/netclaw-change" {
  capabilities = ["create", "update"]
}

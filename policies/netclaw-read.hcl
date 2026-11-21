# NetClaw default: troubleshoot / read-only
# vault policy write netclaw-read policies/netclaw-read.hcl
#
# Start with stage (+ optional lab). Add prod paths only after change control.
# Prefer SSH CA sign over long-lived shared passwords in production.

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

# Uncomment when explicitly approved for production troubleshooting:
# path "secret/data/network/prod/*" {
#   capabilities = ["read"]
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

path "ssh/sign/netclaw-troubleshoot" {
  capabilities = ["create", "update"]
}

path "sys/mounts" {
  capabilities = ["read"]
}

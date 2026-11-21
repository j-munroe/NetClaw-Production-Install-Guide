# GitLab CI JWT role — production automation (protected branches / prod env only)
# vault policy write gitlab-ci-prod policies/gitlab-ci-prod.hcl
#
# Bind this policy to a JWT role with ref_protected=true and prod environment claims.
# Do not attach to MR / unprotected pipelines.

path "secret/data/network/prod/*" {
  capabilities = ["read"]
}
path "secret/metadata/network/prod/*" {
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

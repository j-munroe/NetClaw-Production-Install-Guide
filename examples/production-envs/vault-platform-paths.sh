#!/usr/bin/env bash
# Reference: Vault KV paths for NetClaw production controllers.
# Docs: docs/PRODUCTION_ENVIRONMENTS.md · docs/PATH_LAYOUT.md
# NOT a production secret loader — use controlled process for real values.
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN}"

vault kv put secret/platform/paloalto/strata-cloud-manager \
  client_id="CHANGE_ME" \
  client_secret="CHANGE_ME" \
  tsg_id="CHANGE_ME" \
  region="americas" \
  base_url="https://api.strata.paloaltonetworks.com"

vault kv put secret/platform/arista/cvaas \
  host="www.arista.io" \
  token="CHANGE_ME"

vault kv put secret/platform/velocloud/manager \
  base_url="https://CHANGE_ME.velocloud.net" \
  api_token="CHANGE_ME"

vault kv put secret/platform/cisco/epnm \
  base_url="https://epnm.example.local" \
  username="netclaw-api" \
  password="CHANGE_ME"

vault kv put secret/platform/zabbix \
  url="https://zabbix.example.local" \
  api_token="CHANGE_ME"

vault kv put secret/platform/observium \
  url="https://observium.example.local" \
  api_token="CHANGE_ME"

vault kv put secret/platform/aruba/central-classic \
  base_url="https://CHANGE_ME" \
  client_id="CHANGE_ME" \
  client_secret="CHANGE_ME" \
  customer_id="CHANGE_ME"

vault kv put secret/platform/aruba/central-cnx \
  base_url="https://CHANGE_ME" \
  client_id="CHANGE_ME" \
  client_secret="CHANGE_ME" \
  customer_id="CHANGE_ME"

vault kv put secret/platform/cloudflare \
  api_token="CHANGE_ME" \
  account_id="CHANGE_ME" \
  zone_id="CHANGE_ME"

vault kv put secret/platform/efficientip/solidserver \
  base_url="https://solidserver.example.local" \
  api_key="CHANGE_ME"

vault kv put secret/platform/aruba/edgeconnect-gm \
  base_url="https://CHANGE_ME" \
  api_token="CHANGE_ME"

# Example IOS-XR device residual static creds (prefer SSH CA in prod)
vault kv put secret/network/prod/dc1/xr-pe-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

echo "Wrote platform path placeholders under secret/platform/… and sample XR path."
echo "Replace CHANGE_ME before any real use; prefer SSH CA for XR ([docs/SSH_CA.md])."

#!/usr/bin/env bash
# Reference: Strategy A path shapes (placeholders). Requires VAULT_ADDR + VAULT_TOKEN.
# Not a production secret loader — docs/PATH_LAYOUT.md · docs/INSTALL.md
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN}"

vault kv put secret/platform/netbox \
  api_token="CHANGE_ME_NETBOX_TOKEN" \
  url="https://netbox.example.local"

vault kv put secret/network/stage/dc1/rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

vault kv put secret/network/stage/dc1/sw-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

vault kv put secret/network/prod/dc1/rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

echo "Seeded Strategy A example paths under secret/platform and secret/network/{stage,prod}/..."
echo "Replace CHANGE_ME via controlled process; do not leave placeholders on a live cluster."

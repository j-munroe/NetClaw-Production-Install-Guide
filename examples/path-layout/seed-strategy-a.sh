#!/usr/bin/env bash
# Seed Strategy A sample paths (placeholders). Requires VAULT_ADDR + VAULT_TOKEN.
# Docs: docs/PATH_LAYOUT.md
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN}"

vault kv put secret/platform/netbox \
  api_token="CHANGE_ME_NETBOX_TOKEN" \
  url="https://netbox.example.local"

vault kv put secret/network/lab/dc1/lab-rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

vault kv put secret/network/lab/dc1/lab-sw-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

vault kv put secret/network/lab/shared/netclaw \
  username="netclaw" \
  password="CHANGE_ME"

vault kv put secret/network/lab/shared/ansible \
  username="ansible" \
  password="CHANGE_ME"

echo "Seeded Strategy A lab paths under secret/platform and secret/network/lab/..."
echo "Replace CHANGE_ME values before use on real devices."

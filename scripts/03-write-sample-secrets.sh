#!/usr/bin/env bash
# Reference: example kv put path shapes for stage validation.
# NOT a production secret loader — replace CHANGE_ME and use controlled process for prod.
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

vault kv put secret/platform/netbox \
  api_token="CHANGE_ME_NETBOX_TOKEN" \
  url="https://netbox.example.local"

vault kv put secret/network/stage/dc1/rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

# Optional isolated non-prod gear
vault kv put secret/network/lab/dc1/lab-rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

for p in netclaw-read gitlab-ci gitlab-ci-prod netbox-agent netclaw-change ansible-automation; do
  f="$ROOT/policies/${p}.hcl"
  if [[ -f "$f" ]]; then
    vault policy write "$p" "$f"
    echo "Wrote policy $p"
  fi
done

echo "Example secrets under secret/platform/netbox and secret/network/stage/..."
echo "Do not leave CHANGE_ME values in a cluster that holds real credentials."
echo "Production install: docs/INSTALL.md"

#!/usr/bin/env bash
# Register vault-mcp with DefenseClaw and scan it.
# Requires: defenseclaw on PATH; vault-mcp already in OpenClaw config.
# Docs: docs/DEFENSECLAW.md · docs/NETCLAW.md
set -euo pipefail

command -v defenseclaw >/dev/null || { echo "defenseclaw not installed" >&2; exit 1; }

defenseclaw mcp set vault-mcp \
  --command vault-mcp-server \
  --args '[]'

defenseclaw mcp scan vault-mcp

echo "Review scan output. Fix HIGH/CRITICAL before production allow."
echo "VAULT_ADDR / VAULT_TOKEN stay in host env — do not add secrets to --env here."

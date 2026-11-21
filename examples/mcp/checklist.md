# MCP getting-started checklist

From [docs/MCP.md](../../docs/MCP.md):

1. [ ] NetClaw / OpenClaw gateway runs with a Main model
2. [ ] `vault-mcp-server` installed and on `PATH` (pinned version)
3. [ ] Vault AppRole → short-lived `VAULT_TOKEN` on the host
4. [ ] `mcpServers.vault-mcp` registered (see `../openclaw-vault.json`)
5. [ ] `defenseclaw mcp set` + `scan` for `vault-mcp`
6. [ ] Gateway restarted; list mounts / list paths works; no secret values in chat
7. [ ] Next MCP chosen (e.g. Zabbix) using the same pattern

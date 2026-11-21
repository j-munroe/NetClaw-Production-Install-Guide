# Production stack install checklist

From [docs/STACK_INSTALL.md](../../docs/STACK_INSTALL.md).

## 0 Design

- [ ] Architecture / security / best practices signed off
- [ ] Main LLM chosen; day-1 platforms listed
- [ ] Vault RPO/RTO defined

## 1 Infrastructure

- [ ] Hosts sized and provisioned (Vault×3, NetClaw, NetBox, Runners, bastions, optional Ollama)
- [ ] DNS + TLS + CA bundle distributed
- [ ] Firewall allowlists applied

## 2–3 Vault

- [ ] HA Raft, auto-unseal, audit → SIEM ([docs/INSTALL.md](../../docs/INSTALL.md))
- [ ] KV + SSH engines; Strategy A paths; stage/prod policies
- [ ] JWT + AppRole + OIDC configured
- [ ] Snapshot restore drill done

## 4 NetBox

- [ ] NetBox up on TLS; API token in Vault
- [ ] `vault_path` / controller fields; no passwords in UI

## 5 GitLab + Ansible

- [ ] CE JWT roles (stage/prod); smoke job green
- [ ] Ansible lookups pinned; `no_log`; no CI passwords

## 6 SSH CA

- [ ] CA created; bastions trust pubkey; ≤30m cert login
- [ ] ClearPass remains X.509/NAC only
- [ ] Zero-touch seeding path defined

## 7–8 NetClaw + DefenseClaw

- [ ] OpenClaw/NetClaw pinned install; gateway as systemd
- [ ] vault-mcp registered; AppRole token renewal
- [ ] DefenseClaw pinned; observe → action; MCP scans clean
- [ ] Write tools blocked by default

## 9 Models

- [ ] Provider keys outside git; Ollama registered with DefenseClaw if used
- [ ] Stage tool-using turn succeeds

## 10 Platforms

- [ ] Day-1 controllers in Vault + NetBox + MCP (read-only)
- [ ] NMS + SaaS + XR (+ ND SAN / ClearPass CPPM if in scope) smoke OK
- [ ] ClearPass: Onboard remains X.509; Policy Manager API uses `secret/platform/aruba/clearpass`

## 11 Dev Containers

- [ ] No secrets in git; OIDC/host token; fail closed

## 12 Go-live

- [ ] E2E acceptance checked in STACK_INSTALL §12
- [ ] On-call runbooks + rotation calendar published

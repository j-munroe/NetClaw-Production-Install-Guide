# Production install: HashiCorp Vault

<!-- doc-nav:start -->
> **Hub:** [Documentation home](README.md) · **2. Build**  
> ← [Stack install](STACK_INSTALL.md) · [Path layout](PATH_LAYOUT.md) →
<!-- doc-nav:end -->

This guide builds a **production-grade** Vault cluster (one chapter of the full stack). For **NetClaw + every associated component** in install order, start with **[STACK_INSTALL.md](STACK_INSTALL.md)**.

Vault assumes on-prem (or private cloud) infrastructure with real TLS, HA storage, auto-unseal, audit, and backup — not a single-node “dev server” or Docker `tls_disable` container.

Replace every `CHANGE_ME` / example hostname before use. Pin package versions per [VERSIONS.md](VERSIONS.md).

```mermaid
flowchart LR
  P0[0 Prereqs] --> P1[1 Install nodes]
  P1 --> P2[2 TLS + Raft config]
  P2 --> P3[3 Init auto-unseal audit]
  P3 --> P4[4 Engines]
  P4 --> P5[5 Paths]
  P5 --> P6[6 Policies]
  P6 --> P7[7 Auth]
  P7 --> P8[8 SSH CA]
  P8 --> P9[9 HA verify + backup]
```

Diagram index: [DIAGRAMS.md](DIAGRAMS.md) · SSH detail: [SSH_CA.md](SSH_CA.md) · Controls: [SECURITY.md](SECURITY.md)

---

## Production baseline (non-negotiable)

| Requirement | Production expectation |
|-------------|------------------------|
| **Topology** | **3+ Vault nodes** (odd count) with integrated **Raft** storage |
| **TLS** | Listener TLS from your enterprise / internal CA; clients verify with `VAULT_CACERT` |
| **Unseal** | **Auto-unseal** (cloud KMS, HSM, or Transit from a separate seal Vault) — not day-2 human Shamir |
| **Audit** | Always-on file or socket audit; logs shipped off-box |
| **Versions** | **Pinned** immutable tags/packages after change control ([VERSIONS.md](VERSIONS.md)) |
| **Root token** | Used once at bootstrap; then revoked or offline escrow |
| **Fail closed** | Consumers have **no** plaintext secret fallback when Vault is down |
| **Scripts in `../scripts/`** | **Not** a production installer — command reference only |

Do **not** use Vault `-dev`, `VAULT_DEV_ROOT_TOKEN_ID`, `tls_disable = 1`, or `VAULT_SKIP_VERIFY=1` in any environment that holds real credentials.

---

## 0. Prerequisites

- Three (or five) Linux VMs — **Ubuntu 24.04 LTS** or current RHEL; dedicated to Vault
- Sizing (starting point; scale with audit volume and peak QPS): **4 vCPU / 8 GB RAM / 100+ GB SSD** per node
- DNS: `vault.example.local` → load balancer or DNS round-robin to nodes; per-node names `vault-1` … `vault-3`
- TLS server certs (SAN includes cluster DNS + node names) + private keys; CA bundle for clients
- Auto-unseal target: cloud KMS, PKCS#11 HSM, or Transit seal Vault (separate from this cluster)
- Network: `8200/tcp` (API), `8201/tcp` (Raft) between nodes; allow GitLab Runners, NetBox/Orb, NetClaw, admin jump hosts to `8200`
- Outbound package access **or** internal mirror of HashiCorp apt/yum
- Change window + break-glass runbook for seal/restore

---

## 1. Install Vault on each node

Pin the package (example shows current line — substitute your approved version):

```bash
sudo apt-get update
sudo apt-get install -y wget gpg coreutils

wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y vault=2.2.2-1   # pin; adjust package revision for your distro
vault version
```

Create the `vault` system user/dirs if the package did not:

```bash
sudo mkdir -p /opt/vault/data /opt/vault/tls /var/log/vault
sudo chown -R vault:vault /opt/vault /var/log/vault
# Install vault.crt / vault.key + ca.crt into /opt/vault/tls (mode 640, owner vault)
```

---

## 2. Server configuration (Raft HA + TLS)

`/etc/vault.d/vault.hcl` on **vault-1** (adjust `node_id`, `api_addr`, `cluster_addr`, and `retry_join` per node):

```hcl
ui = true
disable_mlock = false

cluster_name = "vault-prod"

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"

  retry_join {
    leader_api_addr = "https://vault-1.example.local:8200"
  }
  retry_join {
    leader_api_addr = "https://vault-2.example.local:8200"
  }
  retry_join {
    leader_api_addr = "https://vault-3.example.local:8200"
  }
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  cluster_address    = "0.0.0.0:8201"
  tls_cert_file      = "/opt/vault/tls/vault.crt"
  tls_key_file       = "/opt/vault/tls/vault.key"
  tls_client_ca_file = "/opt/vault/tls/ca.crt"
}

api_addr     = "https://vault-1.example.local:8200"
cluster_addr = "https://vault-1.example.local:8201"

# Auto-unseal — pick ONE backend your platform supports (examples below).
# seal "awskms" {
#   region     = "us-east-1"
#   kms_key_id = "CHANGE_ME_KMS_KEY_ARN"
# }
# seal "azurekeyvault" { ... }
# seal "gcpckms" { ... }
# seal "pkcs11" { ... }
# seal "transit" {
#   address         = "https://seal-vault.example.local:8200"
#   token           = "CHANGE_ME_OR_USE_FILE"
#   disable_renewal = "false"
#   key_name        = "autounseal"
#   mount_path      = "transit/"
# }

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = false
}
```

Repeat on vault-2 / vault-3 with matching `retry_join` and unique `node_id` / addresses.

Enable and start on each node:

```bash
sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault
```

Front the API with an internal load balancer (or VIP) at `https://vault.example.local:8200` that health-checks `/v1/sys/health`. Clients and CI should use the VIP, not a single node.

---

## 3. Initialize, auto-unseal, audit, revoke root

On **one** node (first start):

```bash
export VAULT_ADDR="https://vault.example.local:8200"
export VAULT_CACERT="/opt/vault/tls/ca.crt"

# With auto-unseal configured, init still emits recovery keys + root token.
vault operator init -format=json > /root/vault-init.json
# MOVE to offline multi-party escrow IMMEDIATELY. Wipe the disk copy.
```

Confirm:

```bash
vault status
# sealed=false, HA Mode = active|standby, Storage Type = raft
vault operator raft list-peers
```

Login once with the root token, then enable audit and ship logs off-box:

```bash
vault login
vault audit enable file file_path=/var/log/vault/audit.log
# Prefer socket/syslog forwarder or agent that ships /var/log/vault/ to your SIEM
```

Create an admin identity (OIDC or userpass + MFA per org standard), grant a tightly scoped admin policy, then **revoke the root token**. Recovery keys remain for disaster seal operations only ([SECURITY.md](SECURITY.md)).

Join remaining nodes if not already peered; verify `vault operator raft list-peers` shows all voters.

---

## 4. Enable secrets engines

```bash
vault secrets enable -path=secret kv-v2
vault secrets enable -path=ssh ssh
# Optional later: vault secrets enable -path=pki pki
```

Tune TTLs on the SSH mount as you define roles (see §8).

---

## 5. Path layout & first production secrets

Canonical design: **[PATH_LAYOUT.md](PATH_LAYOUT.md)** (Strategy A). Environments are `stage` / `prod` (and optional `lab` for isolated non-prod gear — not a Vault “lab install”).

Write real secrets through a controlled process (break-glass admin or approved CI write role) — example shape only:

```bash
vault kv put secret/platform/netbox \
  api_token="CHANGE_ME_NETBOX_TOKEN"

vault kv put secret/network/stage/dc1/rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

# Prefer SSH CA over shared agent passwords in prod
vault kv put secret/network/prod/dc1/rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"
```

Do not leave sample passwords in the cluster after cutover validation.

---

## 6. Policies

Apply env-scoped policies — never a single identity that can read all of `network/*`:

```bash
vault policy write gitlab-ci-stage  ../policies/gitlab-ci.hcl          # adjust paths to stage/
vault policy write gitlab-ci-prod   ../policies/gitlab-ci-prod.hcl
vault policy write netclaw-read     ../policies/netclaw-read.hcl
vault policy write netclaw-change   ../policies/netclaw-change.hcl
vault policy write ansible-automation ../policies/ansible-automation.hcl
vault policy write netbox-agent     ../policies/netbox-agent.hcl
```

See [policies/README.md](../policies/README.md). Tighten `netclaw-read` for prod paths only after change control.

---

## 7. Auth methods

### 7a. AppRole for NetClaw / controllers

```bash
vault auth enable approle

vault write auth/approle/role/netclaw \
  token_policies="netclaw-read" \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=168h \
  secret_id_num_uses=0 \
  bind_secret_id=true

vault read auth/approle/role/netclaw/role-id
vault write -f auth/approle/role/netclaw/secret-id
```

Deliver `role_id` + `secret_id` via your secret-distribution process (not Git). Rotate `secret_id` on a fixed calendar ([SECURITY.md](SECURITY.md)).

### 7b. JWT for GitLab CE

Full steps: [GITLAB.md](GITLAB.md). Bound claims must separate **stage** vs **prod** roles (`ref_protected`, `project_path`, environment).

```bash
vault auth enable jwt

vault write auth/jwt/config \
  oidc_discovery_url="https://gitlab.example.local" \
  bound_issuer="https://gitlab.example.local"
```

Vault must trust GitLab’s TLS CA for discovery/JWKS.

### 7c. OIDC for humans / Dev Containers

Prefer OIDC (or LDAP) for engineers — not shared AppRoles and never root. See [DEVCONTAINERS.md](DEVCONTAINERS.md).

---

## 8. SSH CA (production default)

Full operations: **[SSH_CA.md](SSH_CA.md)**. **Do not** use OTP mode for production automation; use **CA mode** with short TTLs.

| System | Issues | Use for |
|--------|--------|---------|
| **Vault SSH CA** | OpenSSH certificates | NetClaw / Ansible / runners → bastions (and capable NOS) |
| **ClearPass Onboard** | X.509 | 802.1X / NAC / device TLS — **not** SSH CA |

### 8.1 Create CA and roles

```bash
vault write ssh/config/ca generate_signing_key=true
vault read -field=public_key ssh/config/ca > /tmp/vault-ssh-ca.pub
# Escrow CA private material per ceremony — treat as a root of trust

vault write ssh/roles/netclaw-troubleshoot \
  key_type=ca \
  algorithm_signer=rsa-sha2-256 \
  allow_user_certificates=true \
  allow_host_certificates=false \
  allowed_users=netops \
  default_user=netops \
  default_extensions='{"permit-pty":""}' \
  ttl=30m \
  max_ttl=1h

vault write ssh/roles/netclaw-change \
  key_type=ca \
  algorithm_signer=rsa-sha2-256 \
  allow_user_certificates=true \
  allowed_users=netops \
  default_user=netops \
  ttl=15m \
  max_ttl=30m
```

### 8.2 Trust on bastions (zero-touch)

Distribute **only** the CA public key via golden image and/or NetBox→GitLab→Ansible ([SSH_CA.md](SSH_CA.md), [`../examples/ssh-ca-zero-touch/`](../examples/ssh-ca-zero-touch/)). Issue user certs at connect time — never bake user certs into images.

### 8.3 Acceptance

- [ ] SSH CA created; pubkey on production bastions (and stage)
- [ ] Successful SSH with Vault-signed user cert; TTL ≤ 30m
- [ ] Documented split: ClearPass = X.509; Vault = SSH CA
- [ ] NetBox `vault_ssh_role` alongside `vault_path` ([NETBOX.md](NETBOX.md))
- [ ] Zero-touch seeding with no interactive engineer SSH for new hosts

---

## 9. Verify HA, health, and backup

```bash
vault status
vault operator raft list-peers
vault secrets list
vault policy list
vault audit list
vault kv get secret/platform/netbox
```

From each consumer network path (Runner, NetClaw, admin jump):

```bash
curl -sS --cacert /path/to/ca.crt "$VAULT_ADDR/v1/sys/health"
```

**Backup / DR (required before cutover):**

```bash
# On the active node — schedule via systemd timer or orchestration
vault operator raft snapshot save /var/backups/vault/raft-$(date -u +%Y%m%dT%H%M%SZ).snap
```

- Store snapshots encrypted off-box; define RPO/RTO
- Run a **restore drill** on an isolated cluster before declaring production ready ([WORKPLAN.md](WORKPLAN.md) Phase 7)
- Alert on seal status, peer loss, audit disk, 5xx rates, auth failure spikes

---

## 10. Next steps

Continue from [Documentation home](README.md):

1. [PATH_LAYOUT.md](PATH_LAYOUT.md) — lock Strategy A for `stage` / `prod`
2. [GITLAB.md](GITLAB.md) — JWT + Vault CLI; separate stage/prod roles
3. [ANSIBLE.md](ANSIBLE.md) → [DEVCONTAINERS.md](DEVCONTAINERS.md) → [NETBOX.md](NETBOX.md)
4. [NETCLAW.md](NETCLAW.md) → [MODELS.md](MODELS.md) → [LOCAL_LLM.md](LOCAL_LLM.md) → [SSH_CA.md](SSH_CA.md)
5. [WORKPLAN.md](WORKPLAN.md) Phase 6–7 for SSH fleet rollout and operate checklist

---

## Break-glass

- Sealed cluster: auto-unseal recovery / KMS access per runbook; recovery keys for disaster only
- Vault unavailable: automation **fails closed** — no plaintext env/file fallback
- Emergency device access: offline enterprise PAM / break-glass — not Git, not NetBox password fields

<!-- doc-footer:start -->
---

**Hub:** [Documentation home](README.md) · **Reading path:** [Design](ARCHITECTURE.md) → [Build](INSTALL.md) → [Integrate](GITLAB.md) → [Agent](NETCLAW.md) → [Reference](DIAGRAMS.md)
<!-- doc-footer:end -->

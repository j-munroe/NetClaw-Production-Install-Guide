# Install & bootstrap: HashiCorp Vault

This guide installs Vault for lab or first production footprint, then enables the engines used by GitLab, NetBox, and NetClaw.

Replace every `CHANGE_ME` / example hostname before use.

---

## 0. Prerequisites

- Linux host (**Ubuntu 24.04 LTS** recommended, or current RHEL) — see [VERSIONS.md](VERSIONS.md)
- Outbound access to HashiCorp package repos **or** offline package mirror
- DNS name, e.g. `vault.example.local`
- TLS certificate + key (or lab self-signed for testing only)
- Ports: `8200/tcp` (API), `8201/tcp` (cluster, HA only)
- Firewall allow from: GitLab Runners, NetBox/Orb host, NetClaw host, admin jump hosts

Optional helper scripts live in [`../scripts/`](../scripts/).

---

## 1. Install Vault binary (Ubuntu example)

```bash
sudo apt-get update
sudo apt-get install -y wget gpg coreutils

wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y vault   # latest stable from HashiCorp apt
vault version                   # expect current 2.x line unless you pin
```

**Container alternative (lab):**

```bash
docker volume create vault-data
docker run -d --name vault \
  -p 8200:8200 \
  -v vault-data:/vault/file \
  -e 'VAULT_LOCAL_CONFIG={"storage":{"file":{"path":"/vault/file"}},"listener":{"tcp":{"address":"0.0.0.0:8200","tls_disable":1}},"ui":true}' \
  --cap-add=IPC_LOCK \
  hashicorp/vault:latest server
```

> Lab-only: `tls_disable:1` is unacceptable for production. Use TLS as shown below.  
> Images track **latest stable Vault** ([VERSIONS.md](VERSIONS.md)); pin a version tag in production.

---

## 2. Server configuration (production-shaped)

Create `/etc/vault.d/vault.hcl`:

```hcl
ui = true
disable_mlock = false

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/vault.crt"
  tls_key_file  = "/opt/vault/tls/vault.key"
}

api_addr     = "https://vault.example.local:8200"
cluster_addr = "https://vault.example.local:8201"

# Optional telemetry later
```

Prepare directories:

```bash
sudo mkdir -p /opt/vault/data /opt/vault/tls /var/log/vault
sudo chown -R vault:vault /opt/vault /var/log/vault
# Install vault.crt / vault.key into /opt/vault/tls (mode 640, owner vault)
```

Enable and start:

```bash
sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault
```

---

## 3. Initialize, unseal, audit

```bash
export VAULT_ADDR="https://vault.example.local:8200"
# If using lab self-signed:
# export VAULT_SKIP_VERIFY=1

vault operator init -key-shares=5 -key-threshold=3 -format=json > /root/vault-init.json
# MOVE /root/vault-init.json to offline escrow IMMEDIATELY. Do not leave on disk.
```

Unseal (run 3 times with different key shares):

```bash
vault operator unseal
vault status
```

Login with root token once:

```bash
vault login
```

Enable audit:

```bash
vault audit enable file file_path=/var/log/vault/audit.log
```

Create an admin policy token for day-2 work, then **revoke root** or escrow it offline (see [SECURITY.md](SECURITY.md)).

---

## 4. Enable secrets engines

```bash
# KV v2 at secret/
vault secrets enable -path=secret kv-v2

# SSH engine
vault secrets enable -path=ssh ssh

# Optional PKI
# vault secrets enable -path=pki pki
# vault secrets tune -max-lease-ttl=8760h pki
```

Or run:

```bash
../scripts/02-enable-engines.sh
```

---

## 5. Path layout & sample secrets

Full design guide (Strategy A default, alternatives, NetBox/policy alignment): **[PATH_LAYOUT.md](PATH_LAYOUT.md)**.

Write lab samples (replace values):

```bash
vault kv put secret/platform/netbox \
  api_token="CHANGE_ME_NETBOX_TOKEN"

vault kv put secret/network/lab/dc1/lab-rtr-01/credentials \
  username="netops" \
  password="CHANGE_ME" \
  enable_secret="CHANGE_ME"

vault kv put secret/network/lab/shared/netclaw \
  username="netclaw" \
  password="CHANGE_ME"
```

Or:

```bash
../scripts/03-write-sample-secrets.sh
```

---

## 6. Policies

```bash
vault policy write netclaw-read   ../policies/netclaw-read.hcl
vault policy write gitlab-ci      ../policies/gitlab-ci.hcl
vault policy write netbox-agent   ../policies/netbox-agent.hcl
vault policy write netclaw-change ../policies/netclaw-change.hcl
```

---

## 7. Auth methods (summary)

### 7a. AppRole for NetClaw / services

```bash
vault auth enable approle

vault write auth/approle/role/netclaw \
  token_policies="netclaw-read" \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=24h

vault read auth/approle/role/netclaw/role-id
vault write -f auth/approle/role/netclaw/secret-id
```

Or: `../scripts/04-configure-approle.sh`

Deliver `role_id` + `secret_id` to the NetClaw host via a secure channel (not Git).

### 7b. JWT for GitLab

Full steps: [GITLAB.md](GITLAB.md).

```bash
vault auth enable jwt

vault write auth/jwt/config \
  oidc_discovery_url="https://gitlab.example.local" \
  bound_issuer="https://gitlab.example.local"
```

---

## 8. SSH engine (pilot → CA mode)

Full operations guide (ClearPass, bastions, verification): **[SSH_CA.md](SSH_CA.md)**.

The SSH secrets engine can run in **OTP** or **CA** mode. For NetClaw / Ansible at scale, plan on **CA mode**. OTP is only a quick lab stepping stone.

### 8.1 Important: Vault SSH CA ≠ ClearPass certificates

| System | What it issues | Use for |
|--------|----------------|---------|
| **Vault SSH CA** | OpenSSH **SSH certificates** (user/host) | Automation SSH (NetClaw, Ansible, jump hosts) |
| **HPE ClearPass Onboard** (your current path) | **X.509** certs (client/server) via onboard / **SCEP** / **EST** | 802.1X / NAC, many device TLS identities |

**Can ClearPass Onboard be used for server certificates?**  
**Yes** — Onboard’s CA can issue **X.509 server and client** certificates (Root, Intermediate under enterprise PKI, or Imported CA). That is appropriate for HTTPS/management TLS and NAC-related identities when the device enrolls via SCEP/EST or Onboard provisioning.

**Can ClearPass replace Vault SSH CA mode?**  
**No.** `sshd` `TrustedUserCAKeys` expects Vault’s **SSH CA public key**, not a ClearPass X.509 cert. Keep ClearPass for X.509/NAC; use Vault for SSH certificate signing. See [SSH_CA.md](SSH_CA.md).

### 8.2 OTP mode (fastest pilot only)

```bash
vault write ssh/roles/netclaw-troubleshoot \
  key_type=otp \
  default_user=netops \
  cidr_list=10.0.0.0/8
```

Install `vault-sshhelper` (or equivalent) on the target so each login validates an OTP **against Vault** (device typically needs reachability to Vault at auth time). Prefer CA mode when that is awkward for network devices.

### 8.3 CA mode (preferred long-term)

**Concept:** Vault holds an SSH signing CA. You install only the **CA public key** on trusted hosts. Clients ask Vault to **sign** their SSH public key for a short TTL and allowed principals (e.g. `netops`). No shared password; no device callback to Vault at SSH time.

#### A. Create the SSH CA in Vault

```bash
vault write ssh/config/ca generate_signing_key=true
vault read -field=public_key ssh/config/ca > /tmp/vault-ssh-ca.pub
# Escrow/backup of CA private material is a ceremony — treat like a root key ([SSH_CA.md](SSH_CA.md))
```

#### B. Define roles (separate troubleshoot vs change)

```bash
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

Map policies so NetClaw **read** may `ssh/sign/netclaw-troubleshoot` only; change role stays approval-gated ([SECURITY.md](SECURITY.md)).

#### C. Trust the CA on OpenSSH targets (bastions / Linux)

```bash
# On each jump host (example)
sudo cp /tmp/vault-ssh-ca.pub /etc/ssh/vault-ssh-ca.pub
# sshd_config:
#   TrustedUserCAKeys /etc/ssh/vault-ssh-ca.pub
sudo systemctl reload sshd
```

**Network OS note:** many routers/switches lack OpenSSH user-certificate support. Pilot on **Linux bastions** first; for unsupported NOS, SSH to a Vault-CA bastion, then use vendor auth (or KV secrets) to the device ([SSH_CA.md](SSH_CA.md)).

#### D. Issue a user certificate (from CI / NetClaw host)

```bash
ssh-keygen -t ed25519 -f /tmp/netclaw_id -N ""
vault write -field=signed_key ssh/sign/netclaw-troubleshoot \
  public_key=@/tmp/netclaw_id.pub \
  valid_principals=netops \
  ttl=30m > /tmp/netclaw_id-cert.pub

ssh -i /tmp/netclaw_id \
  -o CertificateFile=/tmp/netclaw_id-cert.pub \
  -o IdentitiesOnly=yes \
  netops@jump.example.local
```

Wire the same sign step after GitLab JWT or NetClaw AppRole login so playbooks/agents never store long-lived SSH private keys in git.

### 8.4 What to use where (recommendations)

1. **ClearPass Onboard** — keep for X.509: 802.1X, onboard, and **server/client TLS** enrollment (SCEP/EST) for appliances that already fit that process.
2. **Vault SSH CA** — NetClaw, Ansible, GitLab runners SSH to bastions (and to devices that support SSH certs).
3. **Vault PKI engine** (optional later) — short-lived X.509 for services you want Vault to mint via API when ClearPass/enterprise PKI is not the right enrollment path.
4. **Enterprise PKI** — if ClearPass Onboard is Intermediate under a corporate root, keep that chain for NAC/TLS; do not put the SSH CA under that same X.509 tree.
5. **Bastion pattern** — default recommendation when device SSH cert support is incomplete.
6. **Short TTLs + dual roles** — troubleshoot vs change; audit every `ssh/sign`.

### 8.5 Zero-touch seeding (new systems, no human SSH)

**Best method for this stack:** treat the Vault SSH CA **public** key as a trust anchor in git (or CI-fetched), and apply it with **NetBox-driven Ansible from GitLab CE** when a device/VM is `staged` — optionally bake the same pubkey into Linux **golden images**. Issue **user** certs only at connect time (`ssh/sign/...`); never bake user certs into images.

Do **not** use ClearPass to seed SSH CA trust. Details, host-cert auto-enrollment, and anti-patterns: **[SSH_CA.md](SSH_CA.md)** · examples: [`../examples/ssh-ca-zero-touch/`](../examples/ssh-ca-zero-touch/).

### 8.6 Acceptance for this step

- [ ] SSH CA created; public key distributed to at least one lab bastion
- [ ] Successful SSH with a Vault-signed user cert (OTP path optional)
- [ ] Documented decision: ClearPass for X.509/server TLS; Vault for SSH CA
- [ ] NetBox `vault_ssh_role` planned alongside `vault_path` ([NETBOX.md](NETBOX.md))
- [ ] Zero-touch path defined (golden image and/or NetBox→GitLab→Ansible) with no interactive engineer SSH

---

## 9. Verify

```bash
vault status
vault secrets list
vault policy list
vault kv get secret/platform/netbox
vault audit list
```

From a Runner host / NetClaw host:

```bash
curl -sS --cacert /path/to/ca.crt "$VAULT_ADDR/v1/sys/health"
```

---

## 10. Next steps

1. [GITLAB.md](GITLAB.md) — wire CI JWT + `secrets:vault`
2. [NETBOX.md](NETBOX.md) — token in Vault + device path refs
3. [NETCLAW.md](NETCLAW.md) — Vault MCP registration
4. [SSH_CA.md](SSH_CA.md) — CA mode ops, ClearPass coexistence, bastions
5. Return to [WORKPLAN.md](WORKPLAN.md) Phase 6–7 for SSH rollout and ops

---

## Rollback / break-glass

- If Vault is sealed: unseal with threshold key shares from escrow
- If Vault is down: automation must **fail closed** (no fallback to plaintext env files in prod)
- Emergency device access: offline break-glass credentials in a physical/enterprise PAM process — not in Git

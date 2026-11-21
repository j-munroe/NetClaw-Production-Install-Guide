# GitLab on-prem + Vault

Wire GitLab CI/CD so jobs authenticate with **JWT ID tokens** and pull secrets from HashiCorp Vault. Do not store device passwords in GitLab CI/CD variables.

Official references:

- [Use HashiCorp Vault secrets in GitLab CI/CD](https://docs.gitlab.com/ci/secrets/hashicorp_vault/)
- [HashiCorp: Secure GitLab CI/CD secrets with Vault](https://developer.hashicorp.com/well-architected-framework/secure-systems/secure-applications/ci-cd-secrets/gitlab)

---

## GitLab Community Edition vs Premium / Ultimate

| Capability | GitLab CE (Community / Free) | Premium / Ultimate |
|------------|------------------------------|--------------------|
| Job `id_tokens` (JWT) | **Yes** | Yes |
| Vault JWT/OIDC auth using that token | **Yes** | Yes |
| Declarative `secrets:vault` in `.gitlab-ci.yml` | **No** | Yes |
| Manual Vault CLI after JWT login | **Yes (use this on CE)** | Yes |
| Auto-masking of secrets from `secrets:vault` | N/A | Yes |

**This project assumes GitLab Community Edition (on-prem).** Use **`id_tokens` + Vault CLI** (or Ansible `community.hashi_vault` after exporting `VAULT_TOKEN`). The Vault server config is the same as Premium; only the job YAML differs.

Premium’s `secrets:vault` keyword is optional sugar later — see §5.

---

## 1. Vault JWT auth

```bash
export VAULT_ADDR="https://vault.example.local:8200"
vault auth enable jwt

# GitLab external URL is the issuer / discovery base
vault write auth/jwt/config \
  oidc_discovery_url="https://gitlab.example.local" \
  bound_issuer="https://gitlab.example.local"
```

If your GitLab uses a custom CA, ensure Vault trusts it (`VAULT_CACERT` on the Vault server for outbound discovery, or use `jwks_url` explicitly).

---

## 2. Role for network automation project

Example: allow `lab` reads from project `network/automation` on protected branches.

```bash
vault write auth/jwt/role/gitlab-network-lab \
  role_type="jwt" \
  user_claim="user_email" \
  bound_audiences="https://vault.example.local" \
  bound_claims_type="glob" \
  bound_claims='{
    "project_path": "network/automation",
    "ref_protected": "true"
  }' \
  claim_mappings='{"project_path":"project_path","ref":"ref"}' \
  token_policies="gitlab-ci" \
  token_ttl="15m"
```

Create a stricter role for production (separate policy limited to `secret/data/network/prod/...`).

---

## 3. GitLab CI variables (non-secret)

Set at group or project level (not masked secrets of device passwords):

| Variable | Example | Protected |
|----------|---------|-----------|
| `VAULT_SERVER_URL` / `VAULT_ADDR` | `https://vault.example.local:8200` | Yes |
| `VAULT_AUTH_PATH` | `jwt` | Optional |
| `VAULT_AUTH_ROLE` | `gitlab-network-lab` | Yes |

Optional: `VAULT_CACERT` as a **File** variable containing your CA PEM.

---

## 4. Community Edition job (recommended)

Exchange the GitLab JWT for a Vault token, then read KV (or run Ansible lookups).

See [`../examples/gitlab-ci-ce.yml`](../examples/gitlab-ci-ce.yml) and [`../examples/ansible/gitlab-ci-ansible.yml`](../examples/ansible/gitlab-ci-ansible.yml).

```yaml
stages:
  - troubleshoot

variables:
  VAULT_ADDR: "https://vault.example.local:8200"
  VAULT_AUTH_ROLE: "gitlab-network-lab"

read_lab_creds:
  stage: troubleshoot
  image: hashicorp/vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.local
  script:
    - set -euo pipefail
    # Exchange GitLab JWT for a short-lived Vault token
    - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role="${VAULT_AUTH_ROLE}" jwt="${VAULT_ID_TOKEN}")"
    # Read secrets — never echo values
    - export NETBOX_TOKEN="$(vault kv get -field=api_token secret/platform/netbox)"
    - echo "NetBox token length: ${#NETBOX_TOKEN}"
    - |
      vault kv get -field=password secret/network/lab/dc1/lab-rtr-01/credentials \
        > /tmp/device_password
      chmod 600 /tmp/device_password
      echo "Device password file written (contents not printed)"
  rules:
    - if: '$CI_COMMIT_REF_PROTECTED == "true"'
```

Notes for CE:

- Job image (or `before_script`) must provide the **Vault CLI**, or call Vault’s HTTP API with `curl`.
- CE does **not** auto-mask CLI-fetched secrets — use `set +x` / avoid printing; prefer writing passwords to temp files with mode `600`.
- For Ansible, export `VAULT_TOKEN` and use `community.hashi_vault` ([ANSIBLE.md](ANSIBLE.md)) instead of baking passwords into CI variables.

---

## 5. Premium / Ultimate only: `secrets:vault`

If you upgrade to Premium+, GitLab can inject KV secrets declaratively:

```yaml
read_lab_creds:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.local
  secrets:
    NETBOX_TOKEN:
      vault: platform/netbox/api_token@secret
      file: false
      token: $VAULT_ID_TOKEN
    DEVICE_PASSWORD:
      vault: network/lab/dc1/lab-rtr-01/credentials/password@secret
      file: true
      token: $VAULT_ID_TOKEN
  script:
    - 'echo "NetBox token length: ${#NETBOX_TOKEN}"'
```

- Default engine is **KV v2**. Path `platform/netbox/api_token@secret` → `secret/data/platform/netbox` field `api_token`.
- Prefer `file: true` for passwords.
- Example retained for reference: [`../examples/gitlab-ci-premium-secrets-vault.yml`](../examples/gitlab-ci-premium-secrets-vault.yml).

**On CE, omit `secrets:` — the job will fail or ignore it depending on version; use §4.**

---

## 6. Runner requirements

- Modern GitLab Runner (supports `id_tokens`)
- Runner network path to Vault:8200
- If Docker executor: Vault CLI in the image (CE path), CA trust via `VAULT_CACERT` / mounted certs
- Use **protected runners** for production roles when possible

---

## 7. Migration checklist

- [ ] Confirm edition: CE → JWT + CLI; Premium+ → optional `secrets:vault`
- [ ] Inventory all CI variables that hold passwords/tokens
- [ ] Write each into Vault under the path convention
- [ ] Switch one protected-branch job to JWT login + Vault read
- [ ] Remove plaintext variable from GitLab after validation
- [ ] Confirm secrets never appear in job logs
- [ ] Repeat per environment (`lab` → `stage` → `prod`)

---

## 8. Troubleshooting

| Symptom | Check |
|---------|-------|
| `error authenticating to vault` / JWT login fails | Issuer URL, `aud` claim, JWKS reachability from Vault to GitLab |
| `permission denied` | Policy paths vs KV v2 (`secret/data/...` + `secret/metadata/...`) |
| Works on main, fails on MR | `ref_protected` / bound claims — expected for prod |
| Empty secret | Field name mismatch; confirm with `vault kv get` |
| `secrets:vault` ignored or job errors on CE | Expected — use §4 CLI pattern |
| Secrets visible in logs on CE | No auto-mask; scrub scripts, use files, disable debug tracing |

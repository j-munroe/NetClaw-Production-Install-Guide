# NetClaw model selection: Claude, OpenAI, or local?

NetClaw is **BYOM** (bring your own model). It works with Anthropic, OpenAI, Bedrock, Vertex, Ollama, and many other providers. Model choice still matters for multi-step, tool-heavy network troubleshooting.

## Recommendation (this stack)

For on-prem GitLab, NetBox, Vault, Ansible, and production-leaning NetClaw use:

| Role | Choice | Why |
|------|--------|-----|
| **Main** (troubleshooting, multi-MCP reasoning) | **Claude** (current Sonnet/Opus class) | NetClaw is built and demoed primarily on Claude; strongest fit for long, tool-heavy CCIE-style workflows |
| **Alternate Main** | **OpenAI** (GPT-4o / strong reasoning tier) | Fully supported via BYOM; use when enterprise standards require OpenAI |
| **Local (Ollama / LM Studio / etc.)** | **Fallback, compaction, or air-gap lab** | Sovereignty and cost; weaker on complex multi-MCP runs unless you run a large model (~30B class) on serious GPU |

**Default:** Claude as Main. Local for fallback/compaction (or air-gapped Main). OpenAI only if procurement/security already standardizes on it.

---

## How NetClaw uses models

Typical role split (names vary by harness/config version):

| Role | Purpose |
|------|---------|
| **Main** | Primary reasoning and tool orchestration |
| **Fallback** | Used when Main is unavailable |
| **Compaction** | Cheaper/faster model for context summarization |

Configure providers during OpenClaw/NetClaw onboard (cloud API keys or local endpoint). You can change models later without rewriting skills or MCP servers.

Upstream references:

- [automateyournetwork/netclaw](https://github.com/automateyournetwork/netclaw) — BYOM / multi-provider
- NetClaw presentations: Claude as primary coworker model; Ollama for local/air-gap

---

## When to pick each

### Claude (recommended Main)

Use when:

- Agents must chain many MCP tools (pyATS, NetBox, Vault metadata, ITSM, telemetry)
- You want the closest match to NetClaw’s reference behavior
- Quality of multi-hop troubleshooting matters more than per-token cost

Watch-outs:

- Cloud egress and data-handling policy (show output / configs in prompts)
- API keys in Vault or host secret store — never in git ([NETCLAW.md](NETCLAW.md), [SECURITY.md](SECURITY.md))

### OpenAI (alternate Main)

Use when:

- Org already approved OpenAI / Azure OpenAI
- You need a second cloud provider for failover diversity

Watch-outs:

- Same data-residency and prompt-leakage concerns as any cloud LLM
- Pick a strong reasoning tier for agentic tool use; weak/small chat models struggle with long NetClaw sessions

### Local LLMs (Ollama, etc.)

Use when:

- Air-gapped or “no show-command output leaves the building”
- Compaction/fallback to cut cloud spend
- Lab/pilot without cloud API access

Guidance from NetClaw community discussions: smaller locals (e.g. Llama 3.1, Gemma 3, Phi-4 class) can give *decent* results; for closer-to-cloud agent quality, plan on a **larger** local model and real GPU (presentation material cites setups such as RTX-class cards and ~30B-class models for local Main).

Watch-outs:

- Underpowered local Main → shallow reasoning, broken multi-tool plans, more human babysitting
- Still apply Vault + read-only SOUL / DefenseClaw; local does **not** replace secrets hygiene
- Pin model tags; upgrade deliberately

---

## Suggested configs for this project

### Production-leaning NetClaw (typical)

```
Main:        Claude (Sonnet or Opus class)
Fallback:    OpenAI strong tier  OR  local mid/large model
Compaction:  Local small/mid model (Ollama)
```

### Air-gapped / high sovereignty

```
Main:        Local large model (Ollama / on-prem endpoint)
Fallback:    Second local model
Compaction:  Smaller local model
```

Tighten SOUL.md and remove or gate write tools (e.g. configure) so the agent stays read-only until you are ready ([NETCLAW.md](NETCLAW.md)).

### Cost-sensitive lab

```
Main:        Claude Sonnet-class  OR  capable local if GPU available
Fallback:    Local
Compaction:  Local small
```

---

## What model choice does *not* fix

- Secrets in `.env`, Ansible Vault files, or chat — use HashiCorp Vault ([ANSIBLE.md](ANSIBLE.md), [DEVCONTAINERS.md](DEVCONTAINERS.md))
- Missing NetBox/Vault path design ([NETBOX.md](NETBOX.md), [WORKPLAN.md](WORKPLAN.md))
- Unapproved writes to devices — DefenseClaw / approval gates
- Bad MCP/tool wiring — skills and inventory quality dominate outcomes

---

## Decision checklist

- [ ] Confirm data policy: may show-output / configs go to a cloud LLM?
- [ ] If no → local Main (or on-prem Bedrock/Azure equivalent under your agreement)
- [ ] If yes → Claude Main unless OpenAI is mandated
- [ ] Set Fallback + Compaction (prefer local for compaction)
- [ ] Store provider API keys in Vault or host secret store; wire via env, not git
- [ ] Validate one lab troubleshooting scenario end-to-end before prod devices
- [ ] Re-evaluate after first month: failure modes are usually tools/policy, not “wrong brand”

---

## Acceptance criteria

- Main model documented in your NetClaw/OpenClaw config and runbook
- API keys not in the GitLab repo
- At least one successful lab troubleshoot with Vault-backed device access
- Air-gap or sovereignty requirements explicitly mapped to local vs cloud Main

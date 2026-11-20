# Local LLM setup for NetClaw

Install and wire a **self-hosted** model so NetClaw can run air-gapped, keep show-command output on-prem, or use a cheap local model for Fallback/Compaction while Claude stays Main ([MODELS.md](MODELS.md)).

## Best recommended local stack

| Piece | Recommendation | Why |
|-------|----------------|-----|
| **Runtime** | **[Ollama](https://ollama.com)** | Native NetClaw provider type; simplest pull/run; used in NetClaw docs and Docker examples |
| **Main (local)** | **`qwen3:30b`** | NetClaw’s documented default local Main; strong tool-calling; ~32k+ context when configured |
| **Compaction / Fallback** | **`qwen3:8b`** | Fast/cheap summarization; NetClaw production-shaped example uses 30B Main + 8B sidecar |
| **Alt Main (VRAM-tight but capable)** | **`qwen3:30b-a3b`** (MoE) or **`qwen3:14b`** | MoE ≈ large quality with lower active cost; 14B fits ~12 GB GPUs |
| **Avoid as Main** | ≤4B chat models | Fine for smoke tests; unreliable for multi-MCP NetClaw turns |

**Bottom line:** Install **Ollama**, pull **`qwen3:30b`** (Main) and **`qwen3:8b`** (Fallback/Compaction). If you only have ~12 GB VRAM, use **`qwen3:14b`** as Main instead of 30B.

NetClaw needs reliable **tool calling** and roughly **≥32k** context for a loaded agent session (first turn alone can be ~10k tokens with tools/skills). Plan hardware accordingly.

Upstream: [Models](https://netclaw.dev/configuration/models/) · [Self-hosted providers](https://netclaw.dev/configuration/self-hosted-providers/)

---

## Hardware sizing (practical)

| Hardware | Suggested models |
|----------|------------------|
| 16 GB RAM, no discrete GPU | `qwen3:8b` Main (slow); lab only |
| ~8–12 GB VRAM (e.g. RTX 3060/4060 12 GB) | Main `qwen3:14b`, Compaction `qwen3:8b` |
| ~20–24 GB VRAM / unified memory | Main `qwen3:30b` or `qwen3:30b-a3b`, Compaction `qwen3:8b` |
| 32 GB+ VRAM / Mac Studio class | Main `qwen3:30b` or larger; keep 8B for compaction |
| Air-gap server, CPU-only | Prefer MoE `qwen3:30b-a3b` if RAM allows; expect high latency — raise NetClaw session timeouts |

Disk: budget ~5 GB for 8B, ~9 GB for 14B, ~19–20 GB for 30B (plus Ollama itself).

---

## 1. Install Ollama (Linux)

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama --version
```

Start the service (install script usually enables systemd):

```bash
sudo systemctl enable --now ollama
# or foreground: ollama serve
curl -s http://127.0.0.1:11434/api/tags
```

### GPU notes

- NVIDIA: install a current driver + CUDA stack supported by your OS; Ollama uses the GPU when visible (`nvidia-smi` should work as the ollama user).
- Apple Silicon: Ollama uses Metal/unified memory; pick model size for total RAM, not “VRAM” alone.
- Remote GPU box: run Ollama there and point NetClaw at `http://<gpu-host>:11434` (see §4).

### Listen beyond localhost (optional)

Only if NetClaw or another host must reach Ollama over the network:

```bash
# systemd drop-in example
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

Firewall-restrict `11434/tcp` to NetClaw / admin hosts. Do not expose Ollama to the public internet.

---

## 2. Pull recommended models

```bash
# Main — best local default for NetClaw
ollama pull qwen3:30b

# Compaction / Fallback
ollama pull qwen3:8b

# Optional: if 30B does not fit, pick one
# ollama pull qwen3:14b
# ollama pull qwen3:30b-a3b
```

Smoke test:

```bash
ollama run qwen3:8b "Reply with exactly: ollama-ok"
ollama list
```

---

## 3. Wire Ollama into NetClaw

Config file (typical): `~/.netclaw/config/netclaw.json`  
(OpenClaw-based installs may use `~/.openclaw/` — use the path your installer created.)

### Recommended local-only roles

```json
{
  "Providers": {
    "local-ollama": {
      "Type": "ollama",
      "Endpoint": "http://127.0.0.1:11434"
    }
  },
  "Models": {
    "Definitions": {
      "qwen-main": {
        "Provider": "local-ollama",
        "ModelId": "qwen3:30b",
        "ContextWindow": 32768
      },
      "qwen-small": {
        "Provider": "local-ollama",
        "ModelId": "qwen3:8b",
        "ContextWindow": 32768
      }
    },
    "Roles": {
      "Main": "qwen-main",
      "Fallback": "qwen-small",
      "Compaction": "qwen-small"
    }
  }
}
```

### Hybrid (recommended for most production nets)

Keep **Claude as Main**; use local for Fallback + Compaction:

```json
{
  "Providers": {
    "anthropic": {
      "Type": "anthropic"
    },
    "local-ollama": {
      "Type": "ollama",
      "Endpoint": "http://127.0.0.1:11434"
    }
  },
  "Models": {
    "Definitions": {
      "claude-main": {
        "Provider": "anthropic",
        "ModelId": "claude-sonnet-4"
      },
      "qwen-small": {
        "Provider": "local-ollama",
        "ModelId": "qwen3:8b",
        "ContextWindow": 32768
      }
    },
    "Roles": {
      "Main": "claude-main",
      "Fallback": "qwen-small",
      "Compaction": "qwen-small"
    }
  }
}
```

Replace `ModelId` values with whatever your NetClaw/provider catalog lists for the Claude tier you licensed. Store API keys in NetClaw `secrets.json` / Vault — not in git ([NETCLAW.md](NETCLAW.md), [MODELS.md](MODELS.md)).

### CLI-oriented setup (when available)

```bash
netclaw provider add local-ollama ollama --endpoint http://127.0.0.1:11434
netclaw model discover local-ollama
netclaw model set main local-ollama qwen3:30b --context-window 32768
netclaw model set fallback local-ollama qwen3:8b --context-window 32768
netclaw model set compaction local-ollama qwen3:8b --context-window 32768
netclaw daemon stop && netclaw daemon start
# or: systemctl --user restart netclaw
netclaw status
netclaw doctor
```

Example snippets: [`../examples/local-llm/`](../examples/local-llm/).

---

## 4. Remote Ollama (NetClaw ≠ GPU host)

1. On the GPU host: install Ollama, pull models, set `OLLAMA_HOST=0.0.0.0:11434`, firewall allow NetClaw IP.
2. On the NetClaw host:

```json
"Endpoint": "http://gpu.example.local:11434"
```

3. From the NetClaw host: `curl -s http://gpu.example.local:11434/api/tags`
4. If NetClaw runs in **Docker**, `localhost` is the container — use the GPU hostname or Compose service name (`http://ollama:11434`), not `127.0.0.1` unless you use host networking.

---

## 5. Docker Compose lab (Ollama + NetClaw)

Sketch aligned with NetClaw’s Docker docs (pin image tags in prod):

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    restart: unless-stopped
    volumes:
      - ollama-data:/root/.ollama
    # deploy GPU reservations here if using NVIDIA Container Toolkit

  netclaw:
    image: ghcr.io/netclaw-dev/netclaw:0.28.2   # pin a real tag
    restart: unless-stopped
    depends_on: [ollama]
    volumes:
      - netclaw-home:/home/netclaw/.netclaw
    environment:
      NETCLAW_Providers__local_ollama__Type: ollama
      NETCLAW_Providers__local_ollama__Endpoint: http://ollama:11434
      NETCLAW_Models__Definitions__qwen__Provider: local_ollama
      NETCLAW_Models__Definitions__qwen__ModelId: qwen3:30b
      NETCLAW_Models__Roles__Main: qwen

volumes:
  ollama-data:
  netclaw-home:
```

```bash
docker compose up -d
docker compose exec ollama ollama pull qwen3:30b
docker compose exec ollama ollama pull qwen3:8b
```

---

## 6. Timeouts for slow local GPUs

Local Main is slower than cloud. If you see compaction or turn timeouts, raise session budgets in `netclaw.json` (seconds; see NetClaw Models docs):

```json
{
  "Session": {
    "SidecarLlmTimeoutSeconds": 300,
    "NoProgressTimeoutSeconds": 2400,
    "PrefillTimeoutSeconds": 1800,
    "FirstTokenTimeoutSeconds": 600
  }
}
```

---

## 7. Alternatives (when not Ollama)

| Stack | Use when |
|-------|----------|
| **llama.cpp (`llama-server`)** | Max control over GGUF/quant/`--ctx-size`; NetClaw `openai-compatible` provider |
| **vLLM / SGLang** | Multi-user GPU server, higher throughput |
| **LM Studio** | Desktop GUI; expose local OpenAI-compatible endpoint |

Ollama remains the **best first choice** for this project: least moving parts and first-class NetClaw support.

Example llama.cpp → NetClaw:

```bash
llama-server -m ./models/qwen3-30b-q4_k_m.gguf --port 8080 --ctx-size 32768 --jinja
netclaw provider add llama-local openai-compatible --endpoint http://127.0.0.1:8080
netclaw model set main llama-local <id-from-discover> --context-window 32768
```

---

## 8. Security notes

- Local inference reduces cloud egress of show output — it does **not** replace Vault for device passwords ([SECURITY.md](SECURITY.md)).
- Do not publish Ollama without auth/network controls.
- Air-gap: mirror Ollama models on an internal registry/host; block outbound model pulls after initial sync.
- Keep write tools gated (DefenseClaw / read-only SOUL) even with a local model ([NETCLAW.md](NETCLAW.md)).

---

## 9. Verification checklist

- [ ] `ollama list` shows `qwen3:30b` (or chosen Main) and `qwen3:8b`
- [ ] `curl http://<ollama-host>:11434/api/tags` from the NetClaw host succeeds
- [ ] `netclaw status` (or OpenClaw equivalent) shows Main with ≥32k context when intended
- [ ] `netclaw doctor` has no “No valid model configuration” / degraded Main
- [ ] One lab chat turn that invokes a tool (e.g. NetBox or device show) completes
- [ ] Compaction/Fallback use `qwen3:8b` if configured
- [ ] Hybrid installs still keep Claude API keys out of git

---

## 10. Acceptance criteria

- Documented Ollama host + model tags for lab and (if used) prod air-gap
- NetClaw Main resolves to the intended local or hybrid definition after daemon restart
- Team runbook includes GPU sizing and which model to use when VRAM is short (`14b` vs `30b`)

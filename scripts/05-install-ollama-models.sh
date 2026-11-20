#!/usr/bin/env bash
# Pull recommended local models for NetClaw. Requires ollama on PATH.
# See docs/LOCAL_LLM.md
set -euo pipefail

MAIN_MODEL="${NETCLAW_LOCAL_MAIN_MODEL:-qwen3:30b}"
SMALL_MODEL="${NETCLAW_LOCAL_SMALL_MODEL:-qwen3:8b}"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama not found. Install with:" >&2
  echo "  curl -fsSL https://ollama.com/install.sh | sh" >&2
  exit 1
fi

if ! curl -sf "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
  echo "Ollama API not reachable at http://127.0.0.1:11434 — start it (systemctl start ollama / ollama serve)" >&2
  exit 1
fi

echo "Pulling Main model: ${MAIN_MODEL}"
ollama pull "${MAIN_MODEL}"

echo "Pulling Compaction/Fallback model: ${SMALL_MODEL}"
ollama pull "${SMALL_MODEL}"

echo "Installed models:"
ollama list

echo
echo "Next: point NetClaw at Ollama — see docs/LOCAL_LLM.md and examples/local-llm/"

#!/usr/bin/env bash
# scripts/restart-vnc.sh
# Stops and then re-starts the VNC + noVNC stack.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[restart-vnc] Restarting cloud-browser services…"
bash "${SCRIPT_DIR}/stop-vnc.sh"
sleep 2
bash "${SCRIPT_DIR}/start-vnc.sh"
echo "[restart-vnc] Done."

#!/usr/bin/env bash
# scripts/codespace-autostart.sh
# Called by postStartCommand in devcontainer.json.
# Starts the VNC + noVNC stack automatically when the Codespace boots.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[autostart] Starting cloud-browser services..."
bash "${SCRIPT_DIR}/start-vnc.sh"
echo "[autostart] Done. Open port 6080 in the Ports tab to access your desktop."

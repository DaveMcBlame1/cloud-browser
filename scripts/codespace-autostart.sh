#!/usr/bin/env bash
# scripts/codespace-autostart.sh
# Called by postStartCommand in devcontainer.json.
# Starts the VNC + noVNC stack automatically when the Codespace boots.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[autostart] Starting cloud-browser services..."
bash "${SCRIPT_DIR}/start-vnc.sh"
echo "[autostart] Done. Open port 6080 in the Ports tab to access your desktop."

# Print VNC password so the user can see it in the terminal without having
# to manually cat the file.
PASSWD_FILE="${HOME}/.vnc/password.txt"
if [[ -f "${PASSWD_FILE}" ]]; then
  echo ""
  echo "╔══════════════════════════════════════════╗"
  echo "║  VNC PASSWORD: $(cat "${PASSWD_FILE}")  ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
fi

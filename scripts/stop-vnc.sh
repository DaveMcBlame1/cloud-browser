#!/usr/bin/env bash
# scripts/stop-vnc.sh
# Stops noVNC/websockify and TigerVNC services gracefully.

set -euo pipefail

DISPLAY_NUM=1
VNC_DIR="${HOME}/.vnc"
LOG_FILE="${VNC_DIR}/cloud-browser.log"
NOVNC_PID_FILE="${VNC_DIR}/novnc.pid"

log() {
  local msg="[stop-vnc] $*"
  echo "$msg"
  echo "$(date '+%Y-%m-%d %T') $msg" >> "${LOG_FILE}"
}

mkdir -p "${VNC_DIR}"

# Stop noVNC / websockify
if [[ -f "${NOVNC_PID_FILE}" ]]; then
  pid=$(cat "${NOVNC_PID_FILE}")
  if kill -0 "${pid}" 2>/dev/null; then
    log "Stopping noVNC (PID ${pid})."
    kill "${pid}" && rm -f "${NOVNC_PID_FILE}"
  else
    log "noVNC PID file present but process not running – cleaning up."
    rm -f "${NOVNC_PID_FILE}"
  fi
else
  # Fallback: find by port using lsof or ss
  pid=""
  if command -v lsof >/dev/null 2>&1; then
    pid=$(lsof -ti tcp:6080 2>/dev/null || true)
  elif command -v ss >/dev/null 2>&1; then
    pid=$(ss -tlnp 'sport = :6080' 2>/dev/null | awk 'NR>1 {match($NF, /pid=([0-9]+)/, a); if (a[1]) print a[1]}' | head -n1 || true)
  fi
  if [[ -n "${pid}" ]]; then
    log "Stopping noVNC process on port 6080 (PID ${pid})."
    kill "${pid}" || true
  else
    log "noVNC is not running."
  fi
fi

# Stop VNC server
if vncserver -list 2>/dev/null | grep -q ":${DISPLAY_NUM}"; then
  log "Stopping TigerVNC on display :${DISPLAY_NUM}."
  vncserver -kill ":${DISPLAY_NUM}" >> "${LOG_FILE}" 2>&1 || true
  log "TigerVNC stopped."
else
  log "TigerVNC :${DISPLAY_NUM} is not running."
fi

log "All cloud-browser services stopped."

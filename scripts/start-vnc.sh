#!/usr/bin/env bash
# scripts/start-vnc.sh
# Starts TigerVNC (display :1, port 5901) and noVNC/websockify (port 6080).
# - Handles stale lock files from a previous session.
# - Generates a random VNC password on first run and prints where to find it.
# - All output is also written to ~/.vnc/cloud-browser.log.

set -uo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
DISPLAY_NUM=1
VNC_PORT=$((5900 + DISPLAY_NUM))
NOVNC_PORT=6080
GEOMETRY="1280x768"
DEPTH=24
VNC_DIR="${HOME}/.vnc"
LOG_FILE="${VNC_DIR}/cloud-browser.log"
PASSWD_FILE="${VNC_DIR}/passwd"
PASSWD_PLAIN_FILE="${VNC_DIR}/password.txt"
NOVNC_PID_FILE="${VNC_DIR}/novnc.pid"

mkdir -p "${VNC_DIR}"

# ── Logging helper ────────────────────────────────────────────────────────────
log() {
  local msg="[start-vnc] $*"
  echo "$msg"
  echo "$(date '+%Y-%m-%d %T') $msg" >> "${LOG_FILE}"
}

# ── Remove stale lock / socket files ─────────────────────────────────────────
clean_stale_locks() {
  local lock_file="/tmp/.X${DISPLAY_NUM}-lock"
  local socket_file="/tmp/.X11-unix/X${DISPLAY_NUM}"

  if [[ -f "${lock_file}" ]]; then
    local pid
    pid=$(tr -d '[:space:]' < "${lock_file}")
    if ! kill -0 "${pid}" 2>/dev/null; then
      log "Removing stale X lock file for PID ${pid}."
      rm -f "${lock_file}"
    else
      log "WARNING: display :${DISPLAY_NUM} is already held by PID ${pid}."
    fi
  fi
  rm -f "${socket_file}" 2>/dev/null || true
}

# ── Generate VNC password on first run ───────────────────────────────────────
ensure_vnc_password() {
  if [[ ! -f "${PASSWD_FILE}" ]]; then
    log "No VNC password found – generating a random one."
    local pw
    # VNC passwords are limited to 8 characters by the protocol.
    pw=$(pwgen -s 8 1)
    printf '%s\n%s\n\n' "${pw}" "${pw}" | vncpasswd "${PASSWD_FILE}" >/dev/null 2>&1
    chmod 600 "${PASSWD_FILE}"
    (umask 077; echo "${pw}" > "${PASSWD_PLAIN_FILE}")
    log "VNC password saved in plain text at: ${PASSWD_PLAIN_FILE}"
    log "Keep this file private! Delete it after noting the password."
  else
    log "Using existing VNC password (${PASSWD_FILE})."
  fi
}

# ── Write xstartup ────────────────────────────────────────────────────────────
write_xstartup() {
  local xstartup="${VNC_DIR}/xstartup"
  cat > "${xstartup}" <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec startxfce4
XSTARTUP
  chmod +x "${xstartup}"
}

# ── Start VNC server ──────────────────────────────────────────────────────────
start_vnc() {
  log "Starting TigerVNC on display :${DISPLAY_NUM} (port ${VNC_PORT})…"
  if vncserver ":${DISPLAY_NUM}" \
      -geometry "${GEOMETRY}" \
      -depth "${DEPTH}" \
      -rfbport "${VNC_PORT}" \
      -rfbauth "${PASSWD_FILE}" \
      -localhost yes \
      >> "${LOG_FILE}" 2>&1; then
    log "TigerVNC started."
  else
    log "WARNING: vncserver exited with a non-zero status – check ${LOG_FILE}."
  fi
}

# ── Start noVNC / websockify ──────────────────────────────────────────────────
start_novnc() {
  # Stop any previous websockify on the same port
  if [[ -f "${NOVNC_PID_FILE}" ]]; then
    local old_pid
    old_pid=$(cat "${NOVNC_PID_FILE}")
    if kill -0 "${old_pid}" 2>/dev/null; then
      log "Stopping previous noVNC instance (PID ${old_pid})."
      kill "${old_pid}" || true
      sleep 1
    fi
    rm -f "${NOVNC_PID_FILE}"
  fi

  log "Starting noVNC on port ${NOVNC_PORT}…"
  # Find noVNC web root
  local web_root
  if [[ -d /usr/share/novnc ]]; then
    web_root="/usr/share/novnc"
  else
    web_root="/opt/novnc"
  fi

  # Use nohup+& so the port is bound immediately and reliably without relying
  # on websockify's --daemon fork behaviour.
  nohup websockify \
    --web="${web_root}" \
    "${NOVNC_PORT}" \
    "localhost:${VNC_PORT}" \
    >> "${LOG_FILE}" 2>&1 &
  echo $! > "${NOVNC_PID_FILE}"

  log "noVNC started (PID $(cat "${NOVNC_PID_FILE}"))."
  log "Open port ${NOVNC_PORT} in the Codespaces Ports tab → 'Open in Browser'."
  log "Password hint: cat ${PASSWD_PLAIN_FILE}   (if it still exists)"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  log "=== cloud-browser start sequence ==="
  clean_stale_locks
  ensure_vnc_password
  write_xstartup

  # Only start VNC if not already running
  if vncserver -list 2>/dev/null | grep -q ":${DISPLAY_NUM}"; then
    log "VNC server :${DISPLAY_NUM} is already running – skipping."
  else
    start_vnc
  fi

  start_novnc
  log "=== startup complete ==="
}

main "$@"

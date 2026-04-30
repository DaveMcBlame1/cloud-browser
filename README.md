# cloud-browser

An interactive virtual browser environment that runs entirely inside **GitHub Codespaces**.  
It spins up a lightweight XFCE desktop with Firefox, served through noVNC so you can use
it from any normal web browser — no local software needed.

---

## Quick start

1. Open this repository in a Codespace (click **Code → Codespaces → Create codespace on main**).  
2. Wait for the container to build and the `postStartCommand` to finish (~2–4 min on first run).  
3. In the Codespace, open the **Ports** tab (bottom panel).  
4. Find port **6080** labelled *"noVNC Desktop (Cloud Browser)"*.  
5. Click **Open in Browser** (or the globe icon).  
6. A noVNC page opens → click **Connect** → enter your VNC password (see below).  
7. Firefox is available inside the XFCE desktop.

---

## VNC password

On the very first start a random 16-character password is generated automatically.  
You can find it in plain text at:

```
~/.vnc/password.txt
```

Print it from the Codespace terminal:

```bash
cat ~/.vnc/password.txt
```

> **Security tip:** Once you have noted the password, delete `~/.vnc/password.txt`.  
> The hashed password stays in `~/.vnc/passwd` and is not re-generated unless you delete
> that file too.

To set your own password at any time:

```bash
vncpasswd ~/.vnc/passwd
```

Then restart the services (see below) for the change to take effect.

---

## Starting, stopping, and restarting

All scripts live in the `scripts/` directory.

| Action | Command |
|--------|---------|
| Start services  | `bash scripts/start-vnc.sh`   |
| Stop services   | `bash scripts/stop-vnc.sh`    |
| Restart services| `bash scripts/restart-vnc.sh` |

Services also start automatically every time the Codespace starts
(`postStartCommand` in `.devcontainer/devcontainer.json`).

Log output is written to `~/.vnc/cloud-browser.log`:

```bash
tail -f ~/.vnc/cloud-browser.log
```

---

## Troubleshooting

### Port 6080 not visible in the Ports tab

Make sure the `start-vnc.sh` script ran successfully:

```bash
cat ~/.vnc/cloud-browser.log
```

If websockify is not running, start it manually:

```bash
bash scripts/start-vnc.sh
```

Then check the Ports tab again; it should auto-appear. If not, click **+** in the
Ports tab and type `6080`.

### "Connection refused" or blank noVNC page

The VNC server may not have started.  Check the log:

```bash
cat ~/.vnc/cloud-browser.log
# also check the individual VNC log:
cat ~/.vnc/*:1.log 2>/dev/null || echo "no VNC log found"
```

Restart everything:

```bash
bash scripts/restart-vnc.sh
```

### Black / frozen desktop inside noVNC

The XFCE session may have crashed.  Restart:

```bash
bash scripts/restart-vnc.sh
```

### Stale lock warning on restart

If a previous session crashed, `start-vnc.sh` automatically removes stale
`/tmp/.X1-lock` and `/tmp/.X11-unix/X1` files before starting a new session.
No manual action is required.

### Port visibility / access from outside Codespace

Port **6080** is marked **private** by default (only you can access it via the
forwarded URL).  Do **not** set it to *Public* unless you understand the security
implications — anyone with the URL would be able to reach your desktop.

---

## Architecture

```
Codespace container
└── TigerVNC (:1, localhost:5901)
      └── XFCE4 desktop + Firefox
└── websockify / noVNC (localhost:6080 → 5901)
      └── Codespace port forwarding → your browser
```

| Component | Purpose |
|-----------|---------|
| `tigervnc-standalone-server` | X11 VNC server (display `:1`, port 5901) |
| `xfce4` | Lightweight desktop environment |
| `firefox` | Web browser inside the desktop |
| `novnc` + `websockify` | WebSocket proxy + HTML5 VNC client on port 6080 |

---

## File layout

```
.devcontainer/
  devcontainer.json   # Codespaces config (port 6080, postStartCommand)
  Dockerfile          # Ubuntu 24.04 + all required packages
scripts/
  codespace-autostart.sh  # Called by postStartCommand
  start-vnc.sh            # Start TigerVNC + noVNC (handles stale locks, first-run password)
  stop-vnc.sh             # Stop all services
  restart-vnc.sh          # stop-vnc + start-vnc
README.md
```

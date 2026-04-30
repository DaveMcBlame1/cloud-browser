FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ENV DEBIAN_FRONTEND=noninteractive

# Add Mozilla's official apt repo so Firefox installs as a real .deb.
# On Ubuntu 24.04 the default "firefox" package is a snap stub that does not
# work inside containers, and "firefox-esr" is not in the Ubuntu repos at all.
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates \
  && install -d -m 0755 /etc/apt/keyrings \
  && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg \
       -O /etc/apt/keyrings/packages.mozilla.org.asc \
  && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
       > /etc/apt/sources.list.d/mozilla.list \
  && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
       > /etc/apt/preferences.d/mozilla \
  && rm -rf /var/lib/apt/lists/*

# Install desktop environment, VNC server, noVNC, and Firefox
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    xfce4-taskmanager \
    dbus-x11 \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    firefox \
    xdg-utils \
    xfonts-base \
    x11-xserver-utils \
    pwgen \
    lsof \
  && rm -rf /var/lib/apt/lists/*

# Pre-create the VNC directory so it is owned by the non-root user that will
# run inside the Codespace (the base image creates "vscode" with uid 1000).
RUN mkdir -p /home/vscode/.vnc && chown -R vscode:vscode /home/vscode/.vnc

# Expose the noVNC web port
EXPOSE 6080

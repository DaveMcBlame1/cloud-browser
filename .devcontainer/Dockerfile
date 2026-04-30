FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install desktop environment, VNC server, noVNC, and Firefox ESR
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    xfce4-taskmanager \
    dbus-x11 \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    firefox-esr \
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

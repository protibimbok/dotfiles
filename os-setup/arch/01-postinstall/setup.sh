#!/bin/bash

# Arch Linux Post-Install Setup
# Main orchestrator for Hyprland desktop setup

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this script as root." >&2
    exit 1
fi

if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "${ID:-}" != "arch" ]; then
        echo "ERROR: This script is intended for Arch Linux (detected: ${ID:-unknown})." >&2
        exit 1
    fi
fi

# Shared log function
log() {
    echo "[$(date +'%H:%M:%S')] $*"
}
export -f log
export LOG_FUNC_DEFINED=1

# Cache sudo credentials once at the start
log "Requesting sudo access..."
sudo -v

# Keep sudo alive in background
(
    while true; do
        sudo -n true
        sleep 50
    done
) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# Run installation
log "=== Phase 1: Package Installation ==="
"$SCRIPT_DIR/install.sh"

# Run configuration
log "=== Phase 2: Configuration ==="
"$SCRIPT_DIR/configure.sh"

log "=== Arch post-install setup complete ==="
log "Please log out and back in for all changes to take effect."

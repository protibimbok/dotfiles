#!/bin/bash

# Arch Linux Setup Orchestrator
# Runs all Arch installation modules in deterministic order

if [ -z "${BASH_VERSION:-}" ]; then
    echo "ERROR: This script requires bash. Please run with: bash $0" >&2
    exit 1
fi

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Arch Linux setup..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: This script should not be run as root. Please run as a regular user with sudo privileges." >&2
    exit 1
fi

# Verify we're on Arch
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "${ID:-}" != "arch" ]; then
        echo "ERROR: This script is intended for Arch Linux (detected: ${ID:-unknown})." >&2
        exit 1
    fi
fi

# Check sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "Requesting sudo privileges..."
    sudo -v || { echo "ERROR: This script requires sudo privileges." >&2; exit 1; }
fi

# Keep sudo alive in background
(
    while true; do
        sudo -n true
        sleep 50
    done
) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT

# Update system packages
echo "Updating system packages..."
sudo pacman -Syu --noconfirm

# Default modules to install (can be overridden via env)
# To skip a module, comment out its line or set OS_SETUP_MODULES env var
# Example: OS_SETUP_MODULES="01-postinstall,02-basic-tools" ./setup.sh
DEFAULT_MODULES=(
    "01-postinstall"
    "02-basic-tools"
    "03-nginx"
    "04-php"
    "05-mariadb-and-phpmyadmin"
    "06-apps"
)

# Allow env override for non-interactive execution
if [ -n "${OS_SETUP_MODULES:-}" ]; then
    IFS=',' read -r -a SELECTED_MODULES <<< "$OS_SETUP_MODULES"
    echo "Using modules from OS_SETUP_MODULES: ${SELECTED_MODULES[*]}"
else
    SELECTED_MODULES=("${DEFAULT_MODULES[@]}")
fi

# Run selected modules
for mod in "${SELECTED_MODULES[@]}"; do
    mod_dir="$SCRIPT_DIR/$mod"
    mod_script="$mod_dir/setup.sh"
    
    if [ -x "$mod_script" ]; then
        echo ""
        echo "=========================================="
        echo "Running module: $mod"
        echo "=========================================="
        "$mod_script" || echo "WARNING: Module $mod failed but continuing"
    elif [ -f "$mod_script" ]; then
        echo "WARNING: Module $mod exists but is not executable; skipping"
    else
        echo "WARNING: Module $mod not found at $mod_script; skipping"
    fi
done

echo ""
echo "=========================================="
echo "Arch Linux setup completed successfully!"
echo "=========================================="
echo "You may need to restart your terminal or run 'source ~/.bashrc' to apply some changes."

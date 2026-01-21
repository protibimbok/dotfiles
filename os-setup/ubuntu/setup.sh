#!/bin/bash

# Ubuntu Setup Orchestrator
# Runs all Ubuntu installation modules in deterministic order

# Ensure we're running with bash (not sh)
if [ -z "${BASH_VERSION:-}" ]; then
    echo "ERROR: This script requires bash. Please run with: bash $0" >&2
    exit 1
fi

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Respect non-interactive defaults; allow overrides via env
# export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
export TZ=${TZ:-UTC}

echo "Starting Ubuntu setup..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: This script should not be run as root. Please run as a regular user with sudo privileges." >&2
    exit 1
fi

# Check sudo privileges
if ! sudo -n true 2>/dev/null; then
    echo "Requesting sudo privileges..."
    sudo -v || { echo "ERROR: This script requires sudo privileges." >&2; exit 1; }
fi

# Update system packages (non-interactive)
echo "Updating system packages..."
sudo -E apt-get update -qq
sudo -E apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Default modules to install (can be overridden via env)
# To skip a module, comment out its line or set OS_SETUP_MODULES env var
# Example: OS_SETUP_MODULES="01-basic-tools,02-nginx" ./setup.sh
DEFAULT_MODULES=(
  "01-basic-tools"
  "02-nginx"
  "03-php"
  "04-mariadb-and-phpmyadmin"
  "05-apps"
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
        echo "Running module: $mod"
        "$mod_script" || echo "WARNING: Module $mod failed but continuing"
    elif [ -f "$mod_script" ]; then
        echo "WARNING: Module $mod exists but is not executable; skipping"
    else
        echo "WARNING: Module $mod not found at $mod_script; skipping"
    fi
done

echo "Ubuntu setup completed successfully!"
echo "You may need to restart your terminal or run 'source ~/.bashrc' to apply some changes."

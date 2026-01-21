#!/bin/bash

# Applications Installation Module
# Installs desktop applications

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Applications installation..."

# Default apps to install (can be overridden via env)
# Example: OS_SETUP_APPS="brave-browser,signal-desktop" ./setup.sh
DEFAULT_APPS=(
    "brave-browser.sh"
    "signal-desktop.sh"
    "surfshark.sh"
)

# Allow env override
if [ -n "${OS_SETUP_APPS:-}" ]; then
    IFS=',' read -r -a SELECTED_APPS <<< "$OS_SETUP_APPS"
    # Add .sh extension if not present
    SELECTED_APPS=("${SELECTED_APPS[@]/%/.sh}")
else
    SELECTED_APPS=("${DEFAULT_APPS[@]}")
fi

# Run selected app installers
for app in "${SELECTED_APPS[@]}"; do
    app_script="$SCRIPT_DIR/$app"
    
    if [ -x "$app_script" ]; then
        "$app_script" || echo "WARNING: App installer $app failed but continuing"
    fi
done

echo "Applications installation completed successfully!"

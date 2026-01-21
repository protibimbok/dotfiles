#!/bin/bash

# Applications Installation Module for Arch Linux
# Installs desktop applications

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Applications installation..."

# Ensure yay is available for AUR packages
ensure_yay() {
    if command -v yay >/dev/null 2>&1; then
        return 0
    fi

    echo "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    (
        cd "$tmp_dir/yay"
        makepkg -si --noconfirm
    )
    rm -rf "$tmp_dir"
}

# Default apps to install (can be overridden via env)
# Example: OS_SETUP_APPS="brave,signal" ./setup.sh
DEFAULT_APPS=(
    "brave.sh"
    "signal.sh"
)

# Allow env override
if [ -n "${OS_SETUP_APPS:-}" ]; then
    IFS=',' read -r -a SELECTED_APPS <<< "$OS_SETUP_APPS"
    # Add .sh extension if not present
    SELECTED_APPS=("${SELECTED_APPS[@]/%/.sh}")
else
    SELECTED_APPS=("${DEFAULT_APPS[@]}")
fi

# Ensure yay is available
ensure_yay

# Run selected app installers
for app in "${SELECTED_APPS[@]}"; do
    app_script="$SCRIPT_DIR/$app"
    
    if [ -x "$app_script" ]; then
        "$app_script" || echo "WARNING: App installer $app failed but continuing"
    fi
done

echo "Applications installation completed successfully!"

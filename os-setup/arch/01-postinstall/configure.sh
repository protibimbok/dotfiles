#!/bin/bash

# Arch Linux Post-Install: Configuration
# Applies config files and system settings for Hyprland desktop

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="$SCRIPT_DIR/conf"

# Source common functions if called standalone
if [ -z "${LOG_FUNC_DEFINED:-}" ]; then
    log() { echo "[$(date +'%H:%M:%S')] $*"; }
fi

copy_config() {
    local src="$1"
    local dest="$2"

    if [ ! -f "$src" ]; then
        echo "ERROR: Missing source file: $src" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$dest")"
    cp -f "$src" "$dest"
    log "Copied: $dest"
}

update_sddm_theme() {
    local theme_conf="$1"
    local theme_name="$2"
    sudo python3 "$SCRIPT_DIR/scripts/update_sddm_theme.py" "$theme_conf" "$theme_name"
}

log "Applying config files..."
copy_config "$CONF_DIR/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
copy_config "$CONF_DIR/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
copy_config "$CONF_DIR/rosi-config.rasi" "$HOME/.config/rofi/config.rasi"
copy_config "$CONF_DIR/waybar-config" "$HOME/.config/waybar/config"
copy_config "$CONF_DIR/waybar-style.css" "$HOME/.config/waybar/style.css"
copy_config "$CONF_DIR/libinput-gestures.conf" "$HOME/.config/libinput-gestures.conf"

log "Configuring SDDM theme..."
update_sddm_theme "/etc/sddm.conf.d/theme.conf" "sugar-candy"

log "Setting up libinput-gestures..."
# Add user to input group for gesture access
sudo usermod -aG input "$USER"
# Enable autostart
libinput-gestures-setup autostart || true

log "Enabling SDDM..."
sudo systemctl enable sddm

log "Enabling Bluetooth..."
sudo systemctl enable --now bluetooth

log "Configuration complete."

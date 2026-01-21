#!/bin/bash

# Arch Linux Post-Install: Package Installation
# Installs all required packages for Hyprland desktop

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions if called standalone
if [ -z "${LOG_FUNC_DEFINED:-}" ]; then
    log() { echo "[$(date +'%H:%M:%S')] $*"; }
fi

install_pacman_packages() {
    sudo pacman -S --needed --noconfirm "$@"
}

ensure_yay() {
    if command -v yay >/dev/null 2>&1; then
        log "yay already installed"
        return 0
    fi

    log "Installing yay (AUR helper)..."
    install_pacman_packages base-devel git

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    (
        cd "$tmp_dir/yay"
        makepkg -si --noconfirm
    )
    rm -rf "$tmp_dir"
}

log "Installing base packages..."
install_pacman_packages \
    hyprland \
    kitty \
    rofi-wayland \
    neovim \
    waybar \
    sddm \
    qt5-graphicaleffects \
    qt5-quickcontrols2 \
    qt5-svg \
    hyprlock \
    networkmanager \
    bluez \
    bluez-utils \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji

ensure_yay

log "Installing AUR packages..."
yay -S --needed --noconfirm \
    sddm-sugar-candy-git \
    zen-browser-bin \
    libinput-gestures \
    bluetuith

log "Package installation complete."

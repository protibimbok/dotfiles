#!/bin/bash

# Signal Desktop Installation Script for Arch Linux
# Installs Signal secure messaging from AUR

set -euo pipefail
IFS=$'\n\t'

# Check if Signal is already installed
if command -v signal-desktop &> /dev/null || pacman -Qs signal-desktop &> /dev/null; then
    echo "Signal Desktop is already installed"
    exit 0
fi

# Install Signal Desktop from AUR
echo "Installing Signal Desktop..."
yay -S --needed --noconfirm signal-desktop

echo "Signal Desktop installation completed successfully!"

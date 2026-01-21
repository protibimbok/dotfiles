#!/bin/bash

# Brave Browser Installation Script for Arch Linux
# Installs Brave web browser from AUR

set -euo pipefail
IFS=$'\n\t'

# Check if Brave is already installed
if command -v brave &> /dev/null || pacman -Qs brave-bin &> /dev/null; then
    echo "Brave Browser is already installed"
    exit 0
fi

# Install Brave Browser from AUR
echo "Installing Brave Browser..."
yay -S --needed --noconfirm brave-bin

echo "Brave Browser installation completed successfully!"

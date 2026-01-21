#!/bin/bash

# Signal Desktop Installation Script
# Installs Signal Desktop messaging application

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Signal is already installed
if command -v signal-desktop &> /dev/null; then
    echo "Signal Desktop is already installed"
    exit 0
fi

# Add Signal Desktop repository
echo "Adding Signal Desktop repository..."

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

# Download and add GPG key
wget -qO "$TEMP_DIR/signal-desktop-keyring.gpg.tmp" https://updates.signal.org/desktop/apt/keys.asc
gpg --dearmor < "$TEMP_DIR/signal-desktop-keyring.gpg.tmp" > "$TEMP_DIR/signal-desktop-keyring.gpg"
sudo install -D -o root -g root -m 644 "$TEMP_DIR/signal-desktop-keyring.gpg" /usr/share/keyrings/signal-desktop-keyring.gpg

# Add sources list
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | \
    sudo tee /etc/apt/sources.list.d/signal-desktop.list > /dev/null

# Update package list and install Signal Desktop
echo "Updating package list and installing Signal Desktop..."
export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
sudo apt-get update -qq
install_recommends_flag="--no-install-recommends"
[ "${OS_SETUP_INSTALL_RECOMMENDS:-0}" = "1" ] && install_recommends_flag=""
sudo -E apt-get install -y -qq $install_recommends_flag signal-desktop -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "Signal Desktop installation completed successfully!"

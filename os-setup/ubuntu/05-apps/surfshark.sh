#!/bin/bash

# Surfshark VPN Installation Script
# Installs Surfshark VPN client

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Surfshark is already installed
if command -v surfshark &> /dev/null; then
    echo "Surfshark VPN is already installed"
    exit 0
fi

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

echo "Downloading Surfshark VPN..."

# Download the latest Surfshark .deb package
SURFSHARK_DEB="$TEMP_DIR/surfshark.deb"
curl -fL "https://downloads.surfshark.com/linux/debian-install.sh" -o "$TEMP_DIR/surfshark-install.sh"

# Run the official Surfshark installer
echo "Installing Surfshark VPN..."
bash "$TEMP_DIR/surfshark-install.sh"

echo "Surfshark VPN installation completed successfully!"


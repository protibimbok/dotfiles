#!/bin/bash

# Brave Browser Installation Script
# Installs Brave web browser

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if Brave is already installed
if command -v brave-browser &> /dev/null; then
    echo "Brave Browser is already installed"
    exit 0
fi

# Install Brave Browser using the official installer
echo "Installing Brave Browser..."
curl -fsSL https://dl.brave.com/install.sh | sh

echo "Brave Browser installation completed successfully!"

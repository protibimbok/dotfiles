#!/bin/bash

# Git Utilities Installation Module for Arch Linux
# Installs custom git helper scripts for managing multiple identities
# This script is a wrapper around the Python implementation in common/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../../common/basic-tools/git-utils" && pwd)"

# Ensure openssh is installed (provides ssh-keygen)
if ! command -v ssh-keygen &> /dev/null; then
    echo "Installing openssh..."
    sudo pacman -S --needed --noconfirm openssh
fi

# Delegate to the shared Python implementation
exec python3 "$COMMON_DIR/setup.py" "$@"

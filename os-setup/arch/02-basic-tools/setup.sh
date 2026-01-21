#!/bin/bash

# Basic Tools Installation Module for Arch Linux
# Installs basic development tools and utilities

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Basic Tools installation..."

# Install basic packages
echo "Installing packages: curl wget git unzip base-devel"
sudo pacman -S --needed --noconfirm curl wget git unzip base-devel

# Create necessary directories
mkdir -p "$HOME/.local/bin" "$HOME/.ssh"

# Run submodules in sequence (each is idempotent)
SUBMODULES=(
    "fnm/setup.sh"
    "fzf/setup.sh"
    "oh-my-posh/setup.sh"
    "git-utils/setup.sh"
)

for submod in "${SUBMODULES[@]}"; do
    submod_path="$SCRIPT_DIR/$submod"
    if [ -x "$submod_path" ]; then
        "$submod_path" || echo "WARNING: Submodule $submod failed but continuing"
    fi
done

# Add ~/.local/bin to PATH if not already there
if ! grep -qF '$HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    {
        echo ""
        echo "# Add \$HOME/.local/bin to PATH"
        echo 'if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then'
        echo '    export PATH="$HOME/.local/bin:$PATH"'
        echo "fi"
    } >> "$HOME/.bashrc"
fi

echo "Basic Tools installation completed successfully!"

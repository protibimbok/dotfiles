#!/bin/bash

# FZF Installation Module for Arch Linux
# Installs fzf (fuzzy finder) and configures it

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../../common/basic-tools" && pwd)"

# Check if fzf is already installed
if ! command -v fzf &> /dev/null; then
    echo "Installing fzf..."
    sudo pacman -S --needed --noconfirm fzf
fi

# Append fzf configuration to bashrc
if [ -f "$COMMON_DIR/fzf.bashrc" ]; then
    bashrc="${HOME}/.bashrc"
    config_content=$(cat "$COMMON_DIR/fzf.bashrc")
    first_line=$(echo "$config_content" | head -n 1)
    
    if ! grep -qF "$first_line" "$bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# fzf configuration"
            cat "$COMMON_DIR/fzf.bashrc"
        } >> "$bashrc"
    fi
fi

echo "fzf installation completed successfully!"

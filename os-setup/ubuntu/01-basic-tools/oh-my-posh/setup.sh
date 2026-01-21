#!/bin/bash

# Oh My Posh Installation Module
# Installs Oh My Posh shell prompt theme engine

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../../common/basic-tools" && pwd)"

# Check if Oh My Posh is already installed
if ! command -v oh-my-posh &> /dev/null; then
    # Install Oh My Posh
    echo "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
fi

# Install Oh My Posh configuration
if [ -f "$COMMON_DIR/clean-detailed.omp.json" ]; then
    mkdir -p "$HOME/.config"
    
    dest="$HOME/.config/clean-detailed.omp.json"
    src="$COMMON_DIR/clean-detailed.omp.json"
    
    if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
        [ -f "$dest" ] && cp "$dest" "${dest}.bak"
        cp "$src" "$dest"
    fi
    
    # Append Oh My Posh configuration to bashrc
    if [ -f "$COMMON_DIR/oh-my-posh.bashrc" ]; then
        bashrc="${HOME}/.bashrc"
        config_content=$(cat "$COMMON_DIR/oh-my-posh.bashrc")
        first_line=$(echo "$config_content" | head -n 1)
        
        if ! grep -qF "$first_line" "$bashrc" 2>/dev/null; then
            {
                echo ""
                echo "# Oh My Posh configuration"
                cat "$COMMON_DIR/oh-my-posh.bashrc"
            } >> "$bashrc"
        fi
    fi
fi

echo "Oh My Posh installation completed successfully!"

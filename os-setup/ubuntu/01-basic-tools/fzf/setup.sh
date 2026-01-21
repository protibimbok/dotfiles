#!/bin/bash

# FZF Installation Module
# Installs fzf (fuzzy finder) and configures it

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../../common/basic-tools" && pwd)"

# Check if fzf is already installed
if ! command -v fzf &> /dev/null; then
    # Install fzf
    echo "Installing fzf..."
    export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}
    export TZ=${TZ:-UTC}
    install_recommends_flag="--no-install-recommends"
    [ "${OS_SETUP_INSTALL_RECOMMENDS:-0}" = "1" ] && install_recommends_flag=""
    sudo -E apt-get install -y -qq $install_recommends_flag fzf -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
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

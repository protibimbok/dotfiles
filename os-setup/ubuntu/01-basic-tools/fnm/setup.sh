#!/bin/bash

# Fast Node Manager (fnm) Installation Module
# Installs fnm for Node.js version management

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../../common/basic-tools" && pwd)"

# Check if fnm is already installed
if command -v fnm &> /dev/null; then
    echo "fnm is already installed"
    exit 0
fi

# Install fnm
echo "Installing fnm..."
curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

# Append fnm configuration to bashrc
if [ -f "$COMMON_DIR/fnm.bashrc" ]; then
    bashrc="${HOME}/.bashrc"
    config_content=$(cat "$COMMON_DIR/fnm.bashrc")
    first_line=$(echo "$config_content" | head -n 1)
    
    if ! grep -qF "$first_line" "$bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# fnm configuration"
            cat "$COMMON_DIR/fnm.bashrc"
        } >> "$bashrc"
    fi
fi

echo "fnm installation completed successfully!"

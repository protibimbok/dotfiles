#!/bin/bash

# Git Utilities Installation Module
# Installs custom git helper scripts for managing multiple identities
# This script is a wrapper around the Python implementation in common/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../../common/basic-tools/git-utils" && pwd)"

# Ensure openssh-client is installed (provides ssh-keygen)
if ! command -v ssh-keygen &> /dev/null; then
    echo "Installing openssh-client..."
    sudo -E apt-get install -y -qq openssh-client
fi

# Delegate to the shared Python implementation
exec python3 "$COMMON_DIR/setup.py" "$@"

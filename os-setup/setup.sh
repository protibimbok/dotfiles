#!/bin/bash

# OS Setup Entry Point
# Detects the operating system and delegates to the appropriate setup script

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Detecting operating system..."

# Detect OS
if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
    echo "Detected: $NAME $VERSION_ID"
else
    echo "ERROR: Cannot detect operating system. /etc/os-release not found." >&2
    exit 1
fi

# Delegate to OS-specific setup
case "$OS_ID" in
    ubuntu)
        echo "Running Ubuntu setup..."
        "$SCRIPT_DIR/ubuntu/setup.sh"
        ;;
    arch)
        echo "Running Arch Linux setup..."
        "$SCRIPT_DIR/arch/setup.sh"
        ;;
    debian)
        echo "Debian detected. Ubuntu setup may work, but proceed with caution."
        read -p "Attempt to run Ubuntu setup? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/ubuntu/setup.sh"
        else
            echo "ERROR: Setup cancelled by user." >&2
            exit 1
        fi
        ;;
    *)
        echo "ERROR: Unsupported OS: $OS_ID. Only Ubuntu and Arch are currently supported." >&2
        exit 1
        ;;
esac

echo "OS setup completed successfully!"


#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../common/nginx" && pwd)"

if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo -E apt-get install -y -qq nginx \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"
fi

if command -v systemctl &> /dev/null && systemctl list-unit-files | grep -q "^nginx"; then
    sudo systemctl enable --now nginx 2>/dev/null || true
fi

if command -v ufw &> /dev/null; then
    sudo ufw allow 'Nginx Full' 2>/dev/null || true
fi

echo "Nginx installation completed successfully!"

echo "Copying nginx-init.sh"
mkdir -p "$HOME/.local/bin"
cp "$COMMON_DIR/nginx-init.sh" "$HOME/.local/bin/nginx-init"
chmod +x "$HOME/.local/bin/nginx-init"

echo "Copying nginx templates"
mkdir -p "$HOME/.local/bin/nginx-templates/php"
mkdir -p "$HOME/.local/bin/nginx-templates/wordpress"
mkdir -p "$HOME/.local/bin/nginx-templates/laravel"

cp "$COMMON_DIR/templates/template-php" "$HOME/.local/bin/nginx-templates/php/nginx-site"
cp "$COMMON_DIR/templates/template-wordpress" "$HOME/.local/bin/nginx-templates/wordpress/nginx-site"
cp "$COMMON_DIR/templates/template-laravel" "$HOME/.local/bin/nginx-templates/laravel/nginx-site"

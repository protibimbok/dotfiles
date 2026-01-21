#!/bin/bash

# Nginx Installation Module for Arch Linux
# Installs and configures Nginx web server

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Nginx installation..."

if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx and mailcap (for mime types)..."
    sudo pacman -S --needed --noconfirm nginx mailcap
fi

# Ensure mailcap is installed (for mime.types)
if ! pacman -Qs mailcap &> /dev/null; then
    echo "Installing mailcap..."
    sudo pacman -S --needed --noconfirm mailcap
fi

# Create sites-available and sites-enabled directories (Debian-style)
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Fix nginx.conf to include sites-enabled inside http block
if ! grep -q "include /etc/nginx/sites-enabled" /etc/nginx/nginx.conf; then
    echo "Configuring nginx.conf to include sites-enabled..."
    sudo python3 "$SCRIPT_DIR/fix_nginx_conf.py" /etc/nginx/nginx.conf
else
    # Check if include is outside http block and fix it
    echo "Checking nginx.conf include placement..."
    sudo python3 "$SCRIPT_DIR/fix_nginx_conf.py" /etc/nginx/nginx.conf
fi

# Enable and start nginx
if command -v systemctl &> /dev/null; then
    sudo systemctl enable --now nginx 2>/dev/null || true
fi

# Configure firewall if ufw is installed
if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp 2>/dev/null || true
    sudo ufw allow 443/tcp 2>/dev/null || true
fi

echo "Nginx installation completed successfully!"

# Copy nginx-init script
echo "Copying nginx-init.sh"
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/site-builder/nginx-init.sh" "$HOME/.local/bin/nginx-init"
chmod +x "$HOME/.local/bin/nginx-init"

# Copy nginx templates
echo "Copying nginx templates"
mkdir -p "$HOME/.local/bin/nginx-templates/php"
mkdir -p "$HOME/.local/bin/nginx-templates/wordpress"
mkdir -p "$HOME/.local/bin/nginx-templates/laravel"

cp "$SCRIPT_DIR/site-builder/template-php" "$HOME/.local/bin/nginx-templates/php/nginx-site"
cp "$SCRIPT_DIR/site-builder/template-wordpress" "$HOME/.local/bin/nginx-templates/wordpress/nginx-site"
cp "$SCRIPT_DIR/site-builder/template-laravel" "$HOME/.local/bin/nginx-templates/laravel/nginx-site"

echo "Nginx setup completed!"

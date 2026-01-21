#!/bin/bash

# MariaDB and phpMyAdmin Installation Module for Arch Linux
# Installs MariaDB database server and phpMyAdmin web interface

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../common/mariadb" && pwd)"

echo "Starting MariaDB and phpMyAdmin installation..."

# Install MariaDB
if ! command -v mysql &> /dev/null; then
    echo "Installing MariaDB..."
    sudo pacman -S --needed --noconfirm mariadb
    
    # Initialize MariaDB data directory
    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
fi

# Enable and start MariaDB
if command -v systemctl &> /dev/null; then
    sudo systemctl enable --now mariadb 2>/dev/null || true
fi

# Configure MariaDB root account (allow localhost connections without password)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

if mysql -u root -e "SELECT 1;" &>/dev/null; then
    echo "MariaDB root access verified (no password required)"
fi

# Create phpmyadmin database and user
mysql -u root -e "CREATE DATABASE IF NOT EXISTS phpmyadmin;" 2>/dev/null || true
mysql -u root -e "CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true
mysql -u root -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost';" 2>/dev/null || true
mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# Install phpMyAdmin
if ! pacman -Qs phpmyadmin &> /dev/null; then
    echo "Installing phpMyAdmin..."
    sudo pacman -S --needed --noconfirm phpmyadmin
fi

# Create phpMyAdmin configuration
PHPMYADMIN_CONFIG="/etc/webapps/phpmyadmin/config.inc.php"
if [ -f "$PHPMYADMIN_CONFIG" ]; then
    # Update phpMyAdmin config to allow no password
    if [ -f "$COMMON_DIR/update_phpmyadmin_config.py" ]; then
        sudo python3 "$COMMON_DIR/update_phpmyadmin_config.py" "$PHPMYADMIN_CONFIG"
    fi
fi

# Create symlink for phpMyAdmin in web root
sudo ln -sf /usr/share/webapps/phpmyadmin /usr/share/nginx/html/phpmyadmin 2>/dev/null || true

# Setup Nginx configuration for phpMyAdmin
if command -v nginx &> /dev/null; then
    echo "Configuring Nginx for phpMyAdmin..."
    
    NGINX_SITE_FILE="/etc/nginx/sites-available/phpmyadmin"
    
    # Copy Arch-specific nginx site config
    sudo cp "$SCRIPT_DIR/nginx-site" "$NGINX_SITE_FILE"
    
    # Enable phpMyAdmin site
    if [ ! -L "/etc/nginx/sites-enabled/phpmyadmin" ]; then
        sudo ln -sf "$NGINX_SITE_FILE" "/etc/nginx/sites-enabled/phpmyadmin"
    fi
    
    # Test and reload nginx
    if sudo nginx -t 2>/dev/null; then
        if systemctl is-active --quiet nginx; then
            sudo systemctl reload nginx 2>/dev/null || true
        fi
    fi
fi

echo "MariaDB and phpMyAdmin installation completed successfully!"
echo "phpMyAdmin is accessible at http://db.localhost"
echo "MariaDB root access: mysql -u root (no password required)"

#!/bin/bash

# MariaDB and phpMyAdmin Installation Module
# Installs MariaDB database server and phpMyAdmin web interface

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../common/mariadb" && pwd)"

echo "Starting MariaDB and phpMyAdmin installation..."

if ! command -v mysql &> /dev/null; then
    echo "Installing MariaDB..."
    sudo -E apt-get install -y mariadb-server
fi

if command -v systemctl &> /dev/null && systemctl list-unit-files | grep -q "^mariadb"; then
    sudo systemctl enable --now mariadb 2>/dev/null || true
fi

# Configure MariaDB root account with no password (allow localhost connections without password)
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true
sudo mysql -e "FLUSH PRIVILEGES;" 2>/dev/null

if mysql -u root -e "SELECT 1;" &>/dev/null; then
    echo "MariaDB root access verified (no password required)"
fi

mysql -u root -e "CREATE DATABASE IF NOT EXISTS phpmyadmin;" 2>/dev/null || true
mysql -u root -e "CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY '';" 2>/dev/null || true

mysql -u root -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost';" 2>/dev/null
mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null

if ! dpkg -l | grep -q phpmyadmin; then
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | sudo debconf-set-selections

    echo "Installing phpMyAdmin..."
    sudo -E DEBIAN_FRONTEND=noninteractive \
        apt-get install -y -qq --no-install-recommends phpmyadmin \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"

fi

PHPMYADMIN_CONFIG="/etc/phpmyadmin/config.inc.php"
if [ -f "$PHPMYADMIN_CONFIG" ]; then
    # Update phpMyAdmin config to allow no password
    sudo python3 "$COMMON_DIR/update_phpmyadmin_config.py" "$PHPMYADMIN_CONFIG"
fi


# Detect PHP-FPM version and socket path
if command -v php &> /dev/null; then
    PHP_FPM_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
else
    # Fallback: inspect /run/php for socket files
    PHP_FPM_VERSION=$(ls /run/php/php*-fpm.sock 2>/dev/null | sed -n 's#.*/php\([0-9]\+\.[0-9]\+\)-fpm.sock#\1#p' | sort -V | tail -n1)
fi

if [ -n "$PHP_FPM_VERSION" ] && command -v nginx &> /dev/null; then
    echo "Detected PHP-FPM version: $PHP_FPM_VERSION"
    
    # Create nginx site configuration
    NGINX_SITE_FILE="/etc/nginx/sites-available/phpmyadmin"
    
    sudo cp "$COMMON_DIR/nginx-site" "$NGINX_SITE_FILE"
    sudo sed -i "s#::PHP_VERSION::#${PHP_FPM_VERSION}#g" "$NGINX_SITE_FILE"

    # Enable phpMyAdmin site idempotently
    if [ ! -L "/etc/nginx/sites-enabled/phpmyadmin" ]; then
        sudo ln -s "/etc/nginx/sites-available/phpmyadmin" "/etc/nginx/sites-enabled/phpmyadmin"
    fi

    # Test and reload nginx
    if sudo nginx -t 2>/dev/null; then
        if command -v systemctl &> /dev/null && systemctl is-active --quiet nginx; then
            sudo systemctl reload nginx 2>/dev/null || true
        fi
    fi
fi

echo "MariaDB and phpMyAdmin installation completed successfully!"
echo "phpMyAdmin is accessible at http://db.localhost"
echo "MariaDB root access: mysql -u root (no password required)"

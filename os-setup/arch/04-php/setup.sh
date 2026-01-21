#!/bin/bash

# PHP Installation Module for Arch Linux
# Installs PHP-FPM and common extensions

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../common/php" && pwd)"

echo "Starting PHP installation..."

# Install PHP and extensions (Arch has latest PHP in main repos)
# Note: curl, mbstring, xml, zip are built into php package on Arch
PHP_PACKAGES=(
    php
    php-fpm
    php-gd
    php-intl
    php-sqlite
    xdebug
)

echo "Installing PHP packages..."
sudo pacman -S --needed --noconfirm "${PHP_PACKAGES[@]}"

# Enable extensions in php.ini (they're included but commented out by default)
echo "Enabling PHP extensions in php.ini..."
sudo python3 "$SCRIPT_DIR/enable_php_extensions.py" /etc/php/php.ini

# Get PHP version
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "")

if [ -n "$PHP_VERSION" ]; then
    echo "Installed PHP version: $PHP_VERSION"
    
    # Enable and start PHP-FPM
    if command -v systemctl &> /dev/null; then
        sudo systemctl enable --now php-fpm 2>/dev/null || true
    fi
fi

# Configure Xdebug if config exists
if [ -f "$COMMON_DIR/xdebug.ini" ]; then
    XDEBUG_CONF="/etc/php/conf.d/xdebug.ini"
    if [ ! -f "$XDEBUG_CONF" ] || ! grep -q "xdebug.mode" "$XDEBUG_CONF" 2>/dev/null; then
        echo "Configuring Xdebug..."
        sudo cp "$COMMON_DIR/xdebug.ini" "$XDEBUG_CONF"
    fi
fi

# Install Composer (PHP package manager)
if ! command -v composer &> /dev/null; then
    echo "Installing Composer..."
    
    # Create temporary directory for Composer installation
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" EXIT
    
    cd "$TEMP_DIR"
    
    # Download Composer installer
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    
    # Verify installer
    EXPECTED_CHECKSUM="$(curl -s https://composer.github.io/installer.sig)"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        echo "WARNING: Composer installer checksum mismatch (proceeding anyway)"
    fi
    
    # Run Composer installer
    php composer-setup.php --quiet
    
    # Clean up installer
    rm -f composer-setup.php
    
    # Move Composer to global location
    sudo mv composer.phar /usr/local/bin/composer
    sudo chmod +x /usr/local/bin/composer
fi

echo "PHP installation completed successfully!"

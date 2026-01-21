#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../../common/php" && pwd)"

echo "Starting PHP installation..."

sudo -E apt-get install -y -qq --no-install-recommends software-properties-common \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"

if ! grep -q "^deb.*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "Adding ondrej/php PPA..."
    sudo -E add-apt-repository -y ppa:ondrej/php
    sudo apt-get update -qq
else
    sudo apt-get update -qq
fi

# Determine latest PHP version available
LATEST_PHP_VERSION=$(apt-cache search --names-only '^php[0-9]+\.[0-9]+$' | grep -oP 'php\K[0-9]+\.[0-9]+' | sort -V | tail -n1)

if [ -z "$LATEST_PHP_VERSION" ]; then
    PHP_PACKAGES=(php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip php-intl php-sqlite3 php-xdebug)
else
    echo "Latest PHP version available: $LATEST_PHP_VERSION"
    PHP_PACKAGES=("php${LATEST_PHP_VERSION}-fpm" "php${LATEST_PHP_VERSION}-mysql" "php${LATEST_PHP_VERSION}-curl" "php${LATEST_PHP_VERSION}-gd" "php${LATEST_PHP_VERSION}-mbstring" "php${LATEST_PHP_VERSION}-xml" "php${LATEST_PHP_VERSION}-zip" "php${LATEST_PHP_VERSION}-intl" "php${LATEST_PHP_VERSION}-sqlite3" "php${LATEST_PHP_VERSION}-xdebug")
fi

# Check if PHP is already installed
if command -v php &> /dev/null; then
    CURRENT_PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
    
    if [ -n "$LATEST_PHP_VERSION" ] && [ "$CURRENT_PHP_VERSION" != "$LATEST_PHP_VERSION" ]; then
        echo "Upgrading PHP from $CURRENT_PHP_VERSION to $LATEST_PHP_VERSION..."
        sudo -E apt-get install -y -qq --no-install-recommends "${PHP_PACKAGES[@]}" \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold"
        
        # Disable old PHP-FPM version
        if systemctl is-enabled "php${CURRENT_PHP_VERSION}-fpm" 2>/dev/null; then
            sudo systemctl stop "php${CURRENT_PHP_VERSION}-fpm" 2>/dev/null || true
            sudo systemctl disable "php${CURRENT_PHP_VERSION}-fpm" 2>/dev/null || true
        fi
        
        # Update Nginx configurations
        if [ -f "$SCRIPT_DIR/update_nginx_php.py" ]; then
            echo "Updating Nginx configurations..."
            sudo -E python3 "$SCRIPT_DIR/update_nginx_php.py" "$CURRENT_PHP_VERSION" "$LATEST_PHP_VERSION"
            
            # Reload Nginx to apply changes
            if command -v nginx &> /dev/null && systemctl is-active nginx &> /dev/null; then
                echo "Reloading Nginx..."
                sudo systemctl reload nginx
            fi
        fi
    else
        # Still ensure all extensions are installed
        sudo -E apt-get install -y -qq --no-install-recommends "${PHP_PACKAGES[@]}" \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold"
    fi
else
    echo "Installing PHP $LATEST_PHP_VERSION..."
    sudo -E apt-get install -y -qq --no-install-recommends "${PHP_PACKAGES[@]}" \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"
fi

# Check if xdebug is installed
if ! grep -q "xdebug.so" /etc/php/${LATEST_PHP_VERSION}/mods-available/xdebug.ini; then
    echo "Configuring Xdebug..."
    sudo cp "$COMMON_DIR/xdebug.ini" /etc/php/${LATEST_PHP_VERSION}/mods-available/xdebug.ini
fi

# Get installed PHP version (after potential upgrade)
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "")

if [ -n "$PHP_VERSION" ]; then
    # Enable and start PHP-FPM
    if command -v systemctl &> /dev/null && systemctl list-unit-files | grep -q "^php${PHP_VERSION}-fpm"; then
        sudo systemctl enable --now "php${PHP_VERSION}-fpm" 2>/dev/null || true
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
    
    # Verify installer (optional but recommended)
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

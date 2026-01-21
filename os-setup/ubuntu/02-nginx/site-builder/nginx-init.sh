#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print usage
usage() {
    echo "Usage: nginx-init [name] -p port -t type [dir]"
    echo ""
    echo "Arguments:"
    echo "  name              Site name (optional if port is provided)"
    echo "  -p, --port        Port number (default: 80)"
    echo "  -t, --type        Site type (php, laravel, wordpress)"
    echo "  dir               Root directory path (default: current directory)"
    echo ""
    echo "Examples:"
    echo "  nginx-init myapp -p 8080 -t php /var/www/myapp"
    echo "  nginx-init myblog -t wordpress /var/www/myblog"
    echo "  nginx-init myapp -t laravel /var/www/laravel-app"
    echo "  nginx-init -p 8080 -t php"
    exit 1
}

# Function to show selectable site types
select_type() {
    echo "" >&2
    echo -e "${BLUE}Available site types:${NC}" >&2
    echo "  1) php" >&2
    echo "  2) laravel" >&2
    echo "  3) wordpress" >&2
    echo "" >&2
    read -p "Select type (1-3): " choice
    echo "" >&2
    case $choice in
        1|"") echo "php" ;;
        2) echo "laravel" ;;
        3) echo "wordpress" ;;
        *) echo -e "${RED}Invalid selection${NC}" >&2; exit 1 ;;
    esac
}

# Function to detect PHP-FPM version
detect_php_version() {
    # Try to find the PHP-FPM socket
    local php_sock=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n 1)
    if [ -n "$php_sock" ]; then
        # Extract version from socket name (e.g., php8.1-fpm.sock -> 8.1)
        basename "$php_sock" | grep -oP 'php\K[0-9]+\.[0-9]+'
    else
        # Fallback to php command
        php -v 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+' | head -n 1
    fi
}

# Function to download and install WordPress
download_wordpress() {
    local target_dir="$1"

    echo -e "${GREEN}Checking for WordPress installation...${NC}"

    # Check if index.php already exists
    if [ -f "$target_dir/index.php" ]; then
        echo -e "${BLUE}WordPress already exists in $target_dir${NC}"
        return 0
    fi

    echo -e "${YELLOW}WordPress not found. Downloading latest WordPress...${NC}"

    # Create temporary directory for download
    local temp_dir=$(mktemp -d)
    local wp_zip="$temp_dir/wordpress.zip"

    # Download latest WordPress
    echo -e "${BLUE}Downloading WordPress from wordpress.org...${NC}"
    if ! curl -L -o "$wp_zip" "https://wordpress.org/latest.zip"; then
        echo -e "${RED}Error: Failed to download WordPress${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi

    # Extract WordPress
    echo -e "${BLUE}Extracting WordPress to $target_dir...${NC}"
    if ! unzip -q "$wp_zip" -d "$temp_dir"; then
        echo -e "${RED}Error: Failed to extract WordPress${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi

    # Move WordPress files to target directory
    if [ ! -d "$target_dir" ]; then
        $SUDO mkdir -p "$target_dir"
    fi

    # Move all files from wordpress subdirectory to target
    $SUDO mv "$temp_dir/wordpress"/* "$target_dir/" 2>/dev/null || {
        # If sudo fails, try without sudo (user might own the directory)
        mv "$temp_dir/wordpress"/* "$target_dir/" 2>/dev/null || {
            echo -e "${RED}Error: Failed to move WordPress files${NC}"
            rm -rf "$temp_dir"
            exit 1
        }
    }

    # Clean up
    rm -rf "$temp_dir"

    echo -e "${GREEN}✓ WordPress downloaded and extracted successfully${NC}"
}

# Function to ensure directory permissions for nginx/PHP-FPM
ensure_directory_permissions() {
    local target_dir="$1"
    local web_user="www-data"

    echo -e "${GREEN}Checking directory permissions...${NC}"

    # Check if target directory exists
    if [ ! -d "$target_dir" ]; then
        echo -e "${YELLOW}Directory doesn't exist, creating: $target_dir${NC}"
        $SUDO mkdir -p "$target_dir"
    fi

    # Ensure all parent directories have execute permission
    local current_dir="$target_dir"
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir" ]; then
            # Add execute permission for all (preserving other permissions)
            $SUDO chmod a+x "$current_dir" 2>/dev/null || true
        fi
        current_dir=$(dirname "$current_dir")
    done

    # Set appropriate permissions on the root directory
    # 755: owner can read/write/execute, group and others can read/execute
    echo -e "${BLUE}Setting permissions on $target_dir${NC}"
    $SUDO chmod 755 "$target_dir"

    # Try to set ownership to web user if it exists
    if id "$web_user" &>/dev/null; then
        echo -e "${BLUE}Setting ownership to $web_user:$web_user${NC}"
        $SUDO chown -R "$web_user:$web_user" "$target_dir" 2>/dev/null || {
            echo -e "${YELLOW}Warning: Could not change ownership to $web_user${NC}"
        }

        # Ensure "real" user (if sudo) is part of the web group
        local real_user="${SUDO_USER:-$USER}"
        if [ -n "$real_user" ] && [ "$real_user" != "root" ]; then
            if ! id -nG "$real_user" | grep -qw "$web_user"; then
                echo -e "${BLUE}Adding user $real_user to group $web_user...${NC}"
                $SUDO usermod -aG "$web_user" "$real_user"
                echo -e "${YELLOW}Note: You may need to log out and back in for group changes to take effect.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Warning: Web user $web_user not found, skipping ownership change${NC}"
    fi

    echo -e "${GREEN}✓ Directory permissions configured${NC}"
}

# Initialize variables
NAME=""
PORT="80"
TYPE=""
DIR=""
POSITIONAL_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Process positional arguments
if [ ${#POSITIONAL_ARGS[@]} -ge 1 ]; then
    # Check if first arg looks like a path (contains /)
    if [[ "${POSITIONAL_ARGS[0]}" == *"/"* ]]; then
        DIR="${POSITIONAL_ARGS[0]}"
    else
        NAME="${POSITIONAL_ARGS[0]}"
        if [ ${#POSITIONAL_ARGS[@]} -ge 2 ]; then
            DIR="${POSITIONAL_ARGS[1]}"
        fi
    fi
fi

# Validate: either name or port must be present
if [ -z "$NAME" ] && [ "$PORT" == "80" ]; then
    echo -e "${RED}Error: Either name or port must be specified${NC}"
    usage
fi

# If no type provided, prompt for selection
if [ -z "$TYPE" ]; then
    TYPE=$(select_type)
fi

# Set default directory if not provided
if [ -z "$DIR" ]; then
    DIR="$(pwd)"
fi

# Convert directory to absolute path
DIR="$(cd "$DIR" && pwd)"

# Determine site name and server_name
if [ -z "$NAME" ]; then
    # No name provided, use port as name
    NAME="site-$PORT"
    SERVER_NAME="_"  # Default server
else
    SERVER_NAME="${NAME}.localhost"
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

echo -e "${GREEN}Initializing nginx site...${NC}"
echo -e "${BLUE}Name:${NC} $NAME"
echo -e "${BLUE}Server name:${NC} $SERVER_NAME"
echo -e "${BLUE}Port:${NC} $PORT"
echo -e "${BLUE}Type:${NC} $TYPE"
echo -e "${BLUE}Root directory:${NC} $DIR"

# Download WordPress if needed
if [ "$TYPE" == "wordpress" ] && [ ! -f "$DIR/index.php" ]; then
    download_wordpress "$DIR"
fi

# For PHP-based sites, ensure proper directory permissions
if [ "$TYPE" == "php" ] || [ "$TYPE" == "laravel" ] || [ "$TYPE" == "wordpress" ]; then
    ensure_directory_permissions "$DIR"
fi

TEMPLATE_FILE="$SCRIPT_DIR/nginx-templates/$TYPE/nginx-site"
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: Template not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Read template
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

# Replace placeholders
CONFIG_CONTENT="$TEMPLATE_CONTENT"

# Replace PHP version if needed for PHP-based sites
if [ "$TYPE" == "php" ] || [ "$TYPE" == "laravel" ] || [ "$TYPE" == "wordpress" ]; then
    PHP_VERSION=$(detect_php_version)
    if [ -z "$PHP_VERSION" ]; then
        echo -e "${YELLOW}Warning: Could not detect PHP version, using 8.1 as default${NC}"
        PHP_VERSION="8.1"
    fi
    echo -e "${BLUE}PHP version:${NC} $PHP_VERSION"
    CONFIG_CONTENT="${CONFIG_CONTENT//::PHP_VERSION::/$PHP_VERSION}"
fi

# Replace all placeholders
CONFIG_CONTENT="${CONFIG_CONTENT//::SERVER_NAME::/$SERVER_NAME}"
CONFIG_CONTENT="${CONFIG_CONTENT//::PORT::/$PORT}"
CONFIG_CONTENT="${CONFIG_CONTENT//::ROOT_DIR::/$DIR}"
CONFIG_CONTENT="${CONFIG_CONTENT//::SITE_NAME::/$NAME}"

# Config file paths
AVAILABLE_CONFIG="/etc/nginx/sites-available/$NAME"
ENABLED_CONFIG="/etc/nginx/sites-enabled/$NAME"

# Create config file
echo -e "${GREEN}Creating nginx config: $AVAILABLE_CONFIG${NC}"
echo "$CONFIG_CONTENT" | $SUDO tee "$AVAILABLE_CONFIG" > /dev/null

# Create symlink
if [ -L "$ENABLED_CONFIG" ]; then
    echo -e "${YELLOW}Site already enabled, updating symlink...${NC}"
    $SUDO rm "$ENABLED_CONFIG"
fi

echo -e "${GREEN}Enabling site...${NC}"
$SUDO ln -s "$AVAILABLE_CONFIG" "$ENABLED_CONFIG"

# Test nginx configuration
echo -e "${GREEN}Testing nginx configuration...${NC}"
if $SUDO nginx -t; then
    echo -e "${GREEN}Configuration test passed!${NC}"

    # Restart nginx
    echo -e "${GREEN}Restarting nginx...${NC}"
    $SUDO systemctl restart nginx

    echo -e "${GREEN}✓ Site '$NAME' successfully configured and enabled!${NC}"
    echo -e "${BLUE}Access your site at:${NC} http://$SERVER_NAME:$PORT"
else
    echo -e "${RED}Configuration test failed!${NC}"
    echo -e "${YELLOW}Rolling back changes...${NC}"
    $SUDO rm -f "$ENABLED_CONFIG"
    $SUDO rm -f "$AVAILABLE_CONFIG"
    exit 1
fi

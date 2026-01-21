# Dotfiles

An idempotent setup system for fresh Ubuntu and Arch Linux installations. All setup code lives in `os-setup/`, with distro-specific logic isolated under `os-setup/<distro>/` and shared resources in `os-setup/common/`.

## Quick Start

Run the main entrypoint (auto-detects OS):

```bash
./os-setup/setup.sh
```

Or run directly for your distro:

```bash
./os-setup/ubuntu/setup.sh   # Ubuntu
./os-setup/arch/setup.sh     # Arch Linux
```

### Selective Installation

Install only specific modules:

```bash
OS_SETUP_MODULES="01-basic-tools,02-nginx" ./os-setup/ubuntu/setup.sh
```

### Non-Interactive Mode (Ubuntu)

For automation or CI/CD:

```bash
DEBIAN_FRONTEND=noninteractive TZ=UTC ./os-setup/ubuntu/setup.sh
```

## Modules

### Ubuntu

| Module | Description |
|--------|-------------|
| `01-basic-tools` | fnm, fzf, oh-my-posh, git-utils (SSH key management) |
| `02-nginx` | Nginx web server, UFW firewall |
| `03-php` | PHP-FPM and extensions from ondrej/php PPA |
| `04-mariadb-and-phpmyadmin` | MariaDB, phpMyAdmin at `http://db.localhost` |
| `05-apps` | Brave Browser, Signal Desktop |

### Arch Linux

| Module | Description |
|--------|-------------|
| `01-postinstall` | Hyprland, Waybar, SDDM, hyprlock, libinput-gestures |
| `02-basic-tools` | fnm, fzf, oh-my-posh, git-utils (SSH key management) |
| `03-nginx` | Nginx web server |
| `04-php` | PHP-FPM and extensions |
| `05-mariadb-and-phpmyadmin` | MariaDB, phpMyAdmin at `http://db.localhost` |
| `06-apps` | Brave Browser, Signal Desktop |

### git-utils

Custom git helpers for managing multiple SSH identities:

- `git-init` - Set git identity for a repository
- `git-clone` - Clone using SSH aliases (e.g., `git-clone me:user/repo`)
- `git-fix` - Convert HTTPS remotes to SSH

## Customization

### Disable Modules

Edit `os-setup/<distro>/setup.sh` and comment out unwanted modules:

```bash
DEFAULT_MODULES=(
  "01-basic-tools"
  "02-nginx"
  # "03-php"              # Disabled
  # "04-mariadb-and-phpmyadmin"  # Disabled
  "05-apps"
)
```

### Add a New Module

1. Create directory: `os-setup/<distro>/NN-my-module/`
2. Add `setup.sh` script
3. Make it executable: `chmod +x setup.sh`
4. Add to `DEFAULT_MODULES` in `os-setup/<distro>/setup.sh`

## Testing

Test Ubuntu setup in Docker:

```bash
make test-ubuntu         # Run test
make test-ubuntu-clean   # Clean and re-test
make clean               # Remove all test artifacts
```

Logs saved to `.sandbox/test-ubuntu.log`.

## Post-Installation

1. Restart terminal or run `source ~/.bashrc`

2. Install Node.js (if fnm was installed):
   ```bash
   fnm install --lts
   fnm use lts-latest
   ```

3. Add SSH keys to GitHub/GitLab:
   ```bash
   cat ~/.ssh/id_ed25519_<keyname>.pub
   ```

4. Access phpMyAdmin (if installed): `http://db.localhost`

## Requirements

- Ubuntu 20.04+ or Arch Linux
- Sudo privileges (do not run as root)
- Internet connection
- Docker (optional, for testing)

## Design Principles

- **Idempotent**: Safe to run multiple times
- **Modular**: Each module is self-contained and can be skipped
- **Deterministic**: Modules run in numbered order
- **Non-interactive**: No prompts except where explicitly needed (git-utils)
- **Robust**: Bash strict mode (`set -euo pipefail`)

## Security

- Scripts require sudo but must not be run as root
- MariaDB uses `unix_socket` authentication
- SSH keys generated with ed25519

## Troubleshooting

**Permission denied:**
```bash
chmod +x os-setup/setup.sh
```

**Command not found after install:**
```bash
source ~/.bashrc
```

**Nginx config test:**
```bash
sudo nginx -t
```

---

Personal dotfiles configuration. Use at your own risk.

#!/usr/bin/env bash
# Install / uninstall the Lua Hyprland config by symlinking it into ~/.config/hypr.
#
# Hyprland 0.55+ loads hyprland.lua INSTEAD OF hyprland.conf when present. This
# script leaves your existing hyprland.conf in place (Hyprland just ignores it
# while hyprland.lua exists), so uninstalling is a clean revert.
#
# Usage:
#   ./install.sh            Link the Lua config into ~/.config/hypr
#   ./install.sh --uninstall  Remove the links (falls back to hyprland.conf)
#   ./install.sh --sync-theme  Refresh border color from the current Omarchy theme
#
# After install OR uninstall you must RESTART Hyprland (not `hyprctl reload`) --
# the config format is chosen only at startup.

set -euo pipefail

SRC="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
STAMP="$(date +%Y%m%d-%H%M%S)"

link_one() {
    local name="$1" target="$SRC/$1" link="$DEST/$1"
    if [[ -e "$link" || -L "$link" ]]; then
        if [[ -L "$link" ]]; then
            rm "$link"
        else
            mv "$link" "$link.bak.$STAMP"
            echo "  backed up existing $name -> $name.bak.$STAMP"
        fi
    fi
    ln -s "$target" "$link"
    echo "  linked $name -> $target"
}

unlink_one() {
    local name="$1" link="$DEST/$1"
    if [[ -L "$link" ]]; then
        rm "$link"
        echo "  removed link $name"
    fi
    # Restore the most recent backup if one exists.
    local newest
    newest="$(ls -1d "$link".bak.* 2>/dev/null | sort | tail -1 || true)"
    if [[ -n "${newest:-}" && ! -e "$link" ]]; then
        mv "$newest" "$link"
        echo "  restored $name from $(basename "$newest")"
    fi
}

sync_theme() {
    local theme="$DEST/../omarchy/current/theme/hyprland.conf"
    theme="$(readlink -f "$theme" 2>/dev/null || echo "$theme")"
    [[ -f "$theme" ]] || { echo "No current Omarchy theme at $theme"; return 1; }
    local color
    color="$(grep -oP '\$activeBorderColor\s*=\s*\K.*' "$theme" | head -1 | tr -d ' ')"
    [[ -n "$color" ]] || { echo "Could not read \$activeBorderColor from theme"; return 1; }
    sed -i -E "s|(M\.active_border\s*=\s*)\"[^\"]*\"|\\1\"$color\"|" "$SRC/lua/theme.lua"
    echo "Set active_border = \"$color\" in lua/theme.lua. Restart Hyprland to apply."
}

case "${1:-install}" in
    --uninstall)
        echo "Uninstalling Lua Hyprland config from $DEST:"
        unlink_one hyprland.lua
        unlink_one lua
        echo "Done. Restart Hyprland to fall back to hyprland.conf."
        ;;
    --sync-theme)
        sync_theme
        ;;
    install|"")
        echo "Installing Lua Hyprland config into $DEST:"
        mkdir -p "$DEST"
        link_one hyprland.lua
        link_one lua
        cat <<EOF
Done.

Next step: RESTART Hyprland (log out / back in, or restart the session) so it
picks hyprland.lua over hyprland.conf. A plain 'hyprctl reload' will NOT switch
formats.

After restart, sanity-check with:  hyprctl configerrors
EOF
        ;;
    *)
        echo "Unknown option: $1" >&2
        echo "Use: install | --uninstall | --sync-theme" >&2
        exit 1
        ;;
esac

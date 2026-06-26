#!/usr/bin/env bash
# Install / uninstall the Lua Hyprland config by symlinking it into ~/.config/hypr.
#
# Hyprland 0.55+ loads hyprland.lua INSTEAD OF hyprland.conf when present. This
# script leaves your existing hyprland.conf in place (Hyprland just ignores it
# while hyprland.lua exists), so uninstalling is a clean revert.
#
# Usage:
#   ./install.sh            Link the Lua config + build the hyprdesktop plugin
#   ./install.sh --uninstall  Remove the links + plugin (falls back to hyprland.conf)
#   ./install.sh --sync-theme  Refresh border color from the current Omarchy theme
#   ./install.sh --plugin      Rebuild + reinstall just the hyprdesktop plugin
#
# The hyprdesktop plugin (desktop-mode floating overlay) is compiled against the
# installed Hyprland headers and copied to ~/.config/hypr/plugins/hyprdesktop.so;
# autostart.lua loads it at session start. REBUILD AFTER EVERY HYPRLAND UPGRADE
# (the plugin ABI is tied to the exact Hyprland commit).
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

# After a Hyprland crash/restart, shells often keep a stale HYPRLAND_INSTANCE_SIGNATURE.
# Probe each runtime socket and export the one that actually responds.
resolve_hyprland_instance() {
  local rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
  [[ -d "$rt" ]] || return 1
  local sig sock
  for sig in "$rt"/*/; do
    sig="${sig%/}"
    sig="${sig##*/}"
    sock="$rt/$sig/.socket.sock"
    [[ -S "$sock" ]] || continue
    if HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl version >/dev/null 2>&1; then
      export HYPRLAND_INSTANCE_SIGNATURE="$sig"
      return 0
    fi
  done
  return 1
}

build_plugin() {
    local psrc
    psrc="$(cd "$SRC/../../plugins/hyprdesktop" 2>/dev/null && pwd)" || {
        echo "  plugin source not found at repo plugins/hyprdesktop — skipping"; return 0; }

    if ! command -v cmake >/dev/null 2>&1; then
        echo "  cmake not found — cannot build hyprdesktop plugin (install cmake)"; return 1
    fi
    if ! pkg-config --exists hyprland 2>/dev/null; then
        echo "  hyprland headers (pkg-config hyprland) not found — install hyprland devel headers"; return 1
    fi

    echo "Building hyprdesktop plugin..."
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE=Release -B "$psrc/build" -S "$psrc" >/dev/null
    cmake --build "$psrc/build" --config Release --target hyprdesktop -j
    mkdir -p "$DEST/plugins"
    cp "$psrc/build/hyprdesktop.so" "$DEST/plugins/hyprdesktop.so"
    echo "  installed hyprdesktop.so -> $DEST/plugins/"

    # If Hyprland is already running, (re)load it now so changes apply without a restart.
    if command -v hyprctl >/dev/null 2>&1; then
        if ! hyprctl version >/dev/null 2>&1; then
            resolve_hyprland_instance || true
        fi
        if hyprctl version >/dev/null 2>&1; then
            local unload_out="" load_out=""
            if hyprctl plugin list 2>/dev/null | rg -q "Plugin hyprdesktop"; then
                if ! unload_out="$(hyprctl plugin unload "$DEST/plugins/hyprdesktop.so" 2>&1)"; then
                    echo "  WARNING: plugin unload failed (Hyprland may need a full restart):" >&2
                    echo "  $unload_out" >&2
                    echo "  Skipping hot-reload — restart Hyprland to pick up the new .so." >&2
                    return 0
                fi
            fi
            if load_out="$(hyprctl plugin load "$DEST/plugins/hyprdesktop.so" 2>&1)"; then
                echo "  (re)loaded hyprdesktop into the running session"
            else
                echo "  WARNING: failed to load hyprdesktop into the running session:" >&2
                echo "  $load_out" >&2
            fi
        else
            echo "  Hyprland not reachable (stale socket?) — restart the session or run:" >&2
            echo "    export HYPRLAND_INSTANCE_SIGNATURE=<sig>  # see ls \$XDG_RUNTIME_DIR/hypr/" >&2
            echo "    hyprctl plugin load $DEST/plugins/hyprdesktop.so" >&2
        fi
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
        if [[ -f "$DEST/plugins/hyprdesktop.so" ]]; then
            hyprctl plugin unload "$DEST/plugins/hyprdesktop.so" >/dev/null 2>&1 || true
            rm -f "$DEST/plugins/hyprdesktop.so"
            echo "  removed hyprdesktop.so"
        fi
        echo "Done. Restart Hyprland to fall back to hyprland.conf."
        ;;
    --sync-theme)
        sync_theme
        ;;
    --plugin)
        build_plugin
        ;;
    install|"")
        echo "Installing Lua Hyprland config into $DEST:"
        mkdir -p "$DEST"
        link_one hyprland.lua
        link_one lua
        build_plugin
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
        echo "Use: install | --uninstall | --sync-theme | --plugin" >&2
        exit 1
        ;;
esac

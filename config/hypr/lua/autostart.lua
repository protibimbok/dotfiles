-- Autostart (port of Omarchy autostart.conf exec-once entries).
-- In Lua, run-at-launch processes go in the "hyprland.start" event.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- Desktop-mode floating overlay (native C++ plugin; replaces the old lua/floating.lua
    -- + Quickshell scrim). Built and installed by install.sh into ~/.config/hypr/plugins/.
    -- Loaded here at startup; its keybinds resolve hl.plugin.hyprdesktop.* lazily so load
    -- order doesn't matter. No-op if the plugin isn't built yet.
    hl.exec_cmd("hyprctl plugin load " .. os.getenv("HOME") .. "/.config/hypr/plugins/hyprdesktop.so")

    hl.exec_cmd("uwsm-app -- hypridle")
    hl.exec_cmd("uwsm-app -- mako")
    hl.exec_cmd("uwsm-app -- qs")
    hl.exec_cmd("uwsm-app -- fcitx5 --disable notificationitem")
    hl.exec_cmd("uwsm-app -- swaybg -i ~/.config/omarchy/current/background -m fill")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("omarchy-first-run")
    hl.exec_cmd("omarchy-powerprofiles-init")
    hl.exec_cmd("uwsm-app -- omarchy-hyprland-monitor-watch")

    -- Slow app launch fix -- import env into systemd / dbus
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")

    -- Run post-boot hooks after startup config has loaded
    hl.exec_cmd("sleep 2 && omarchy-hook post-boot")

    -- Note: waybar is launched conditionally by Omarchy elsewhere; uncomment to force:
    -- hl.exec_cmd("! omarchy-toggle-enabled waybar-off && uwsm-app -- waybar")
end)

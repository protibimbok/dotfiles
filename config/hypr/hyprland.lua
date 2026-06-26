-- Hyprland 0.55+ native Lua configuration.
-- A Lua port of the user's Omarchy .conf setup with custom behaviors:
--   1. No border on the focused window when it is the only tiled window (focus.lua)
--   2. Floating windows behave like a desktop overlay (raise on click, hide on tile
--      focus / backdrop click, SSD titlebars). This now lives in the native C++ plugin
--      plugins/hyprdesktop (loaded from autostart.lua); binds are in binds.lua.
--
-- Hyprland loads hyprland.lua INSTEAD OF hyprland.conf when present, and only one
-- format is active per session (switching requires a full Hyprland restart).
--
-- Authored in /mnt/c/Others/hypr; install.sh links this into ~/.config/hypr.

-- Allow `require("name")` to find the modules under ~/.config/hypr/lua/.
-- Resolve the config dir from this file's own location so it works regardless of
-- where the tree is checked out (symlinked into ~/.config/hypr by install.sh).
local here = (debug.getinfo(1, "S").source:match("^@(.*/)") or "./")
package.path = here .. "lua/?.lua;" .. package.path

-- Order matters: static settings first, then rules and binds, then the dynamic
-- behavior hooks last so they observe the final configuration.
require("env")
require("monitors")
require("input")
require("looknfeel")
require("theme")
require("windowrules")
require("apps")
require("binds")
require("autostart")

-- Custom behavior
require("focus")
-- Floating "desktop mode" is now the plugins/hyprdesktop C++ plugin (loaded in
-- autostart.lua), not Lua.

-- Border / accent colors.
--
-- CAVEAT: a hyprland.lua session cannot `source` Omarchy's legacy hyprlang theme
-- file (~/.config/omarchy/current/theme/hyprland.conf), so the active theme color
-- is inlined here. After `omarchy theme set ...`, regenerate this file with:
--     install.sh --sync-theme
-- (reads $activeBorderColor from the current theme and rewrites the value below).
-- Snapshot taken from the current theme: rgb(7aa2f7).

local M = {}

M.active_border   = "rgb(7aa2f7)"      -- from ~/.config/omarchy/current/theme/hyprland.conf
M.inactive_border = "rgba(595959aa)"   -- Omarchy looknfeel default

hl.config({
    general = {
        col = {
            active_border   = M.active_border,
            inactive_border = M.inactive_border,
        },
    },
    group = {
        col = {
            border_active          = M.active_border,
            border_inactive        = M.inactive_border,
            border_locked_active   = M.active_border,
            border_locked_inactive = M.inactive_border,
        },
    },
})

return M

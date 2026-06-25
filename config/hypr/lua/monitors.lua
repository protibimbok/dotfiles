-- Display configuration (port of monitors.conf).
-- List current monitors with: hyprctl monitors

-- Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
hl.env("GDK_SCALE", "1")

hl.monitor({
    output   = "",          -- all monitors
    mode     = "preferred",
    position = "auto",
    scale    = 1,           -- matches original `monitor=,preferred,auto,1`
})

-- Examples (uncomment / adjust as needed):
-- hl.monitor({ output = "DP-5",  mode = "6016x3384@60",  position = "auto", scale = 2 })
-- hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "auto", scale = 2 })

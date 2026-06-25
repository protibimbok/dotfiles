-- CHANGE 1 — Focus highlighting.
-- Do NOT draw a border on the focused window when it is the only tiled window in
-- the workspace. With several windows, the focus border returns (including for
-- floating windows). This ports the user's looknfeel.conf "smart gaps" rules.
--
-- Workspace selectors:
--   w[tv1]   = exactly one tiled, visible window (no floats shown)
--   w[1]     = a single window (tiled or floating)
--   w[2-99]  = two-or-more windows
--   f[1]     = a full-width / maximized window
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Smart gaps: edge-to-edge (no gaps / shadow) when one app or maximized.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0, no_shadow = true })
hl.workspace_rule({ workspace = "w[1]",   gaps_out = 0, gaps_in = 0, no_shadow = true })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0, no_shadow = true })

-- Lone tiled window: no border, no rounding.
hl.window_rule({
    name        = "lone-tiled-no-border",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})

-- Lone TILED window: no border, no rounding. (A lone FLOATING window keeps its
-- border + rounding + focus highlight on purpose — a float should always read as
-- a floating overlay, even when it is the only window. The global border_size/
-- rounding from looknfeel.lua apply to it since no rule strips them.)
hl.window_rule({
    name        = "lone-window-no-border",
    match       = { float = false, workspace = "w[1]" },
    border_size = 0,
    rounding    = 0,
})

-- Maximized / full-width: no border, no rounding.
hl.window_rule({
    name        = "fullwidth-no-border",
    match       = { workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

-- Multiple windows: restore the focus border + rounding so floating focus still
-- reads clearly. Kept per-window (not a global border_size) on purpose.
hl.window_rule({
    name        = "multi-floating-border",
    match       = { float = true, workspace = "w[2-99]" },
    border_size = 1,
    rounding    = 8,
})
hl.window_rule({
    name     = "multi-tiled-rounding",
    match    = { float = false, workspace = "w[tv2-99]" },
    rounding = 8,
})

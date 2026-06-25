-- Window rules (port of Omarchy windows.conf core + user input.conf scroll rules).
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from all apps.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Tag all windows for default opacity (apps can override by removing this tag).
hl.window_rule({
    name  = "tag-default-opacity",
    match = { class = ".*" },
    tag   = "+default-opacity",
})

-- Fix some dragging issues with XWayland.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Terminal touchpad scroll tuning (user input.conf).
hl.window_rule({
    name            = "term-scroll-alacritty-kitty",
    match           = { class = "(Alacritty|kitty)" },
    scroll_touchpad = 1.5,
})
hl.window_rule({
    name            = "term-scroll-ghostty",
    match           = { class = "com.mitchellh.ghostty" },
    scroll_touchpad = 0.2,
})

-- NOTE: the per-app rules (Omarchy's apps/*.conf) and the FINAL "apply default
-- opacity to whatever still carries the default-opacity tag" rule both live in
-- apps.lua, which is required right after this file. Order matters: apps.lua opts
-- specific apps out of the default-opacity tag, and that opacity rule must be
-- registered after those opt-outs — exactly as windows.conf sources apps.conf
-- before its trailing `opacity ..., match:tag default-opacity` line.

-- Input devices (port of Omarchy input.conf + user input.conf overrides).
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        -- compose:caps -> Caps Lock acts as Compose key.
        -- Add grp:alts_toggle and kb_layout = "us,dk,eu" to cycle layouts with Alt+Alt.
        kb_options = "compose:caps",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,  -- -1.0 .. 1.0, 0 = no modification

        -- User overrides from input.conf
        repeat_rate       = 40,
        repeat_delay      = 600,
        numlock_by_default = true,

        touchpad = {
            natural_scroll = true,   -- user override (Omarchy default is false)
            scroll_factor  = 0.4,
        },
    },

    -- From Omarchy input.conf: wake on key/mouse activity
    misc = {
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
    },
})

-- Enable touchpad gestures for changing workspaces (3-finger horizontal swipe)
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

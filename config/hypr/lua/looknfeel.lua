-- Look and feel (port of Omarchy looknfeel.conf + user looknfeel.conf override).
-- Border COLORS live in theme.lua. Lone-window border suppression lives in focus.lua.

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 2,
        border_size = 1,

        -- CHANGE 2 (floating): allow resizing floats by dragging their border edges,
        -- so floats feel like normal desktop windows. Omarchy default was false.
        resize_on_border = true,

        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,  -- user override (Omarchy default 0)

        shadow = {
            enabled      = true,
            range        = 2,
            render_power = 3,
            color        = 0xee1a1a1a,  -- rgba(1a1a1aee)
        },

        blur = {
            enabled    = true,
            size       = 2,
            passes     = 2,
            special    = true,
            brightness = 0.60,
            contrast   = 0.75,
        },
    },

    group = {
        groupbar = {
            font_size            = 12,
            font_family          = "monospace",
            font_weight_active   = "ultraheavy",
            font_weight_inactive = "normal",
            indicator_height     = 0,
            indicator_gap        = 5,
            height               = 22,
            gaps_in              = 5,
            gaps_out             = 0,
            text_color           = "rgb(ffffff)",
            text_color_inactive  = "rgba(ffffff90)",
            col = {
                active   = "rgba(00000040)",
                inactive = "rgba(00000020)",
            },
            gradients                 = true,
            gradient_rounding         = 0,
            gradient_round_only_edges = false,
        },
    },

    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        disable_scale_notification = true,
        focus_on_activate          = true,
        anr_missed_pings           = 3,
        on_focus_under_fullscreen  = 1,
        -- 0 = open new windows on the ACTIVE workspace. With tracking on (1), a
        -- window inherits the workspace of its SPAWNING process; Walker runs as a
        -- daemon started on ws1, so apps it launches were landing on ws1 instead
        -- of the focused workspace. Per-app pinning (if ever wanted) -> apps.lua.
        initial_workspace_tracking = 0,
    },

    cursor = {
        hide_on_key_press       = true,
        warp_on_change_workspace = 1,
    },

    binds = {
        -- Auto toggle scratchpad on switching workspace from scratchpad
        hide_special_on_workspace_change = true,
    },
})

-- Animations (port of Omarchy bezier set + animation leaves).
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "global",          enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",          enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",         enabled = true,  speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",       enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",      enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",          enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",         enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",            enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",          enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",        enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",       enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",    enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",   enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",      enabled = false, speed = 1,    bezier = "default" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,    bezier = "easeOutQuint", style = "slidevert" })

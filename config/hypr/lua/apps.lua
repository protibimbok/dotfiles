-- Per-app window/layer rules — a port of Omarchy's apps.conf, which sources
-- ~/.local/share/omarchy/default/hypr/apps/*.conf. Required right after
-- windowrules.lua (which holds the windows.conf core), matching upstream order:
--   windows.conf  ->  source apps.conf  ->  trailing default-opacity apply
--
-- Rules are listed in the same order apps.conf sources them. Apps you do not run
-- simply never match, so the whole set is safe to keep. Add your own at the bottom
-- (before the final default-opacity rule) following the same pattern.
--
-- conf -> lua cheat-sheet: a `windowrule = <rule> <val>, match:<k> <v>` becomes a
-- field on the spec table, with the matchers under `match = {...}`:
--   float on        -> float = true            tag +x / tag -x -> tag = "+x" / "-x"
--   opacity 1 1     -> opacity = "1 1"         size 875 600    -> size = "875 600"
--   match:class C    -> match = { class = "C" } match:float 1   -> match = { float = true }

-- ── 1password ───────────────────────────────────────────────────────────────
hl.window_rule({ name = "1password-no-screen-share", match = { class = "^(1[p|P]assword)$" }, no_screen_share = true })
hl.window_rule({ name = "1password-floating",         match = { class = "^(1[p|P]assword)$" }, tag = "+floating-window" })

-- ── bitwarden ───────────────────────────────────────────────────────────────
hl.window_rule({ name = "bitwarden-no-screen-share", match = { class = "^(Bitwarden)$" }, no_screen_share = true })
hl.window_rule({ name = "bitwarden-floating",        match = { class = "^(Bitwarden)$" }, tag = "+floating-window" })
-- Bitwarden Chrome extension popup
hl.window_rule({ name = "bitwarden-ext-no-screen-share", match = { class = "chrome-nngceckbapebfimnlniiiahkandclblb-Default" }, no_screen_share = true })
hl.window_rule({ name = "bitwarden-ext-floating",        match = { class = "chrome-nngceckbapebfimnlniiiahkandclblb-Default" }, tag = "+floating-window" })

-- ── browser ─────────────────────────────────────────────────────────────────
hl.window_rule({ name = "tag-chromium-browser", match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)" }, tag = "+chromium-based-browser" })
hl.window_rule({ name = "tag-firefox-browser",  match = { class = "([fF]irefox|zen|librewolf)" },                                                          tag = "+firefox-based-browser" })
hl.window_rule({ name = "chromium-no-default-opacity", match = { tag = "chromium-based-browser" }, tag = "-default-opacity" })
hl.window_rule({ name = "firefox-no-default-opacity",  match = { tag = "firefox-based-browser" },  tag = "-default-opacity" })
-- Video apps: drop the chromium tag so they don't get opacity applied
hl.window_rule({ name = "video-webapp-untag-chromium",     match = { class = "(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)" }, tag = "-chromium-based-browser" })
hl.window_rule({ name = "video-webapp-no-default-opacity", match = { class = "(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)" }, tag = "-default-opacity" })
-- Force chromium-based browsers to tile (works around the --app float bug)
hl.window_rule({ name = "chromium-tile", match = { tag = "chromium-based-browser" }, tile = true })
-- Subtle inactive opacity for browsers (but not for the video sites above)
hl.window_rule({ name = "chromium-opacity", match = { tag = "chromium-based-browser" }, opacity = "1.0 0.97" })
hl.window_rule({ name = "firefox-opacity",  match = { tag = "firefox-based-browser" },  opacity = "1.0 0.97" })
-- Hide the broken-on-Wayland screen-sharing notification bar
hl.window_rule({ name = "hide-sharing-bar", match = { title = ".*is sharing.*" }, workspace = "special silent" })

-- ── hyprshot ────────────────────────────────────────────────────────────────
-- Remove the 1px border/anim around the screenshot selection layer
hl.layer_rule({ name = "hyprshot-no-anim", match = { namespace = "selection" }, no_anim = true })

-- ── jetbrains ───────────────────────────────────────────────────────────────
-- Disable mouse focus (basecamp/omarchy#5183)
hl.window_rule({ name = "jetbrains-no-follow-mouse", match = { class = "^(jetbrains-.*)$" }, no_follow_mouse = true })

-- ── localsend ───────────────────────────────────────────────────────────────
hl.window_rule({ name = "localsend-float",  match = { class = "(Share|localsend)" }, float  = true })
hl.window_rule({ name = "localsend-center", match = { class = "(Share|localsend)" }, center = true })
hl.window_rule({ name = "localsend-size",   match = { class = "localsend" },         size   = "1100 700" })

-- ── pip (picture-in-picture) ─────────────────────────────────────────────────
hl.window_rule({ name = "pip-tag",                match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })
hl.window_rule({ name = "pip-no-default-opacity", match = { tag = "pip" }, tag = "-default-opacity" })
hl.window_rule({ name = "pip-float",       match = { tag = "pip" }, float = true })
hl.window_rule({ name = "pip-pin",         match = { tag = "pip" }, pin = true })
hl.window_rule({ name = "pip-size",        match = { tag = "pip" }, size = "600 338" })
hl.window_rule({ name = "pip-aspect",      match = { tag = "pip" }, keep_aspect_ratio = true })
hl.window_rule({ name = "pip-no-border",   match = { tag = "pip" }, border_size = 0 })
hl.window_rule({ name = "pip-opacity",     match = { tag = "pip" }, opacity = "1 1" })
hl.window_rule({ name = "pip-move",        match = { tag = "pip" }, move = "(monitor_w-window_w-40) (monitor_h*0.04)" })

-- ── qemu ────────────────────────────────────────────────────────────────────
hl.window_rule({ name = "qemu-no-default-opacity", match = { class = "qemu" }, tag = "-default-opacity" })
hl.window_rule({ name = "qemu-opacity",            match = { class = "qemu" }, opacity = "1 1" })

-- ── retroarch ───────────────────────────────────────────────────────────────
hl.window_rule({ name = "retroarch-fullscreen",         match = { class = "com.libretro.RetroArch" }, fullscreen = true })
hl.window_rule({ name = "retroarch-no-default-opacity", match = { class = "com.libretro.RetroArch" }, tag = "-default-opacity" })
hl.window_rule({ name = "retroarch-opacity",            match = { class = "com.libretro.RetroArch" }, opacity = "1 1" })
hl.window_rule({ name = "retroarch-idle-inhibit",       match = { class = "com.libretro.RetroArch" }, idle_inhibit = "fullscreen" })

-- ── steam ───────────────────────────────────────────────────────────────────
hl.window_rule({ name = "steam-float",             match = { class = "steam" },                       float = true })
hl.window_rule({ name = "steam-center",            match = { class = "steam", title = "Steam" },      center = true })
hl.window_rule({ name = "steam-no-default-opacity", match = { class = "steam.*" },                    tag = "-default-opacity" })
hl.window_rule({ name = "steam-opacity",           match = { class = "steam.*" },                     opacity = "1 1" })
hl.window_rule({ name = "steam-size",              match = { class = "steam", title = "Steam" },      size = "1100 700" })
hl.window_rule({ name = "steam-friends-size",      match = { class = "steam", title = "Friends List" }, size = "460 800" })
hl.window_rule({ name = "steam-idle-inhibit",      match = { class = "steam" },                       idle_inhibit = "fullscreen" })

-- ── geforce now ─────────────────────────────────────────────────────────────
hl.window_rule({ name = "geforce-idle-inhibit", match = { class = "GeForceNOW" }, idle_inhibit = "fullscreen" })

-- ── moonlight ───────────────────────────────────────────────────────────────
hl.window_rule({ name = "moonlight-fullscreen",   match = { class = "com.moonlight_stream.Moonlight" }, fullscreen = true })
hl.window_rule({ name = "moonlight-idle-inhibit", match = { class = "com.moonlight_stream.Moonlight" }, idle_inhibit = "fullscreen" })

-- ── system (floating control panels / TUIs, dialogs, screensaver, media) ─────
-- Omarchy's control panels (bluetooth=bluetui, wifi=impala, audio=wiremix,
-- activity=btop, …) launch as terminals with an `org.omarchy.<cmd>` app-id and are
-- floated/centered/sized via the `floating-window` tag.
hl.window_rule({
    name  = "tag-floating-window",
    match = { class = "(org.omarchy.bluetui|org.omarchy.impala|org.omarchy.wiremix|org.omarchy.btop|org.omarchy.terminal|org.omarchy.bash|org.codeberg.dnkl.foot|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|Omarchy|About|TUI.float|imv|mpv)" },
    tag   = "+floating-window",
})
-- File-chooser / save dialogs from these toolkits also float
hl.window_rule({
    name  = "tag-floating-window-dialogs",
    match = {
        class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
    },
    tag = "+floating-window",
})
hl.window_rule({ name = "floating-window-float",  match = { tag = "floating-window" }, float  = true })
hl.window_rule({ name = "floating-window-center", match = { tag = "floating-window" }, center = true })
hl.window_rule({ name = "floating-window-size",   match = { tag = "floating-window" }, size   = "875 600" })
hl.window_rule({ name = "calculator-float",       match = { class = "org.gnome.Calculator" }, float = true })

-- Fullscreen screensaver
hl.window_rule({ name = "screensaver-fullscreen", match = { class = "org.omarchy.screensaver" }, fullscreen = true })
hl.window_rule({ name = "screensaver-float",      match = { class = "org.omarchy.screensaver" }, float = true })
hl.window_rule({ name = "screensaver-animation",  match = { class = "org.omarchy.screensaver" }, animation = "slide" })

-- No transparency on media windows
local media_class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"
hl.window_rule({ name = "media-no-default-opacity", match = { class = media_class }, tag = "-default-opacity" })
hl.window_rule({ name = "media-opacity",            match = { class = media_class }, opacity = "1 1" })

-- Popped-out window rounding, and "never idle" tag
hl.window_rule({ name = "pop-rounding",     match = { tag = "pop" },    rounding = 8 })
hl.window_rule({ name = "noidle-inhibit",   match = { tag = "noidle" }, idle_inhibit = "always" })

-- ── telegram ────────────────────────────────────────────────────────────────
-- Don't steal focus on new messages
hl.window_rule({ name = "telegram-no-focus-steal", match = { class = "org.telegram.desktop" }, focus_on_activate = false })

-- ── typora ──────────────────────────────────────────────────────────────────
-- Float Typora's Print dialog
hl.window_rule({ name = "typora-print-float",  match = { class = "^Typora$", title = "^Print$" }, float = true })
hl.window_rule({ name = "typora-print-center", match = { class = "^Typora$", title = "^Print$" }, center = true })

-- ── terminals ───────────────────────────────────────────────────────────────
-- Style terminals uniformly with their own opacity (opting out of default-opacity)
hl.window_rule({ name = "tag-terminal",            match = { class = "(Alacritty|kitty|com.mitchellh.ghostty|foot)" }, tag = "+terminal" })
hl.window_rule({ name = "terminal-no-default-opacity", match = { tag = "terminal" }, tag = "-default-opacity" })
hl.window_rule({ name = "terminal-opacity",        match = { tag = "terminal" }, opacity = "0.97 0.9" })

-- ── walker (launcher) ───────────────────────────────────────────────────────
hl.layer_rule({ name = "walker-no-anim", match = { namespace = "walker" }, no_anim = true })

-- ── webcam-overlay ──────────────────────────────────────────────────────────
hl.window_rule({ name = "webcam-float",         match = { title = "WebcamOverlay" }, float = true })
hl.window_rule({ name = "webcam-pin",           match = { title = "WebcamOverlay" }, pin = true })
hl.window_rule({ name = "webcam-no-init-focus", match = { title = "WebcamOverlay" }, no_initial_focus = true })
hl.window_rule({ name = "webcam-no-dim",        match = { title = "WebcamOverlay" }, no_dim = true })
hl.window_rule({ name = "webcam-move",          match = { title = "WebcamOverlay" }, move = "(monitor_w-window_w-40) (monitor_h-window_h-40)" })

-- ─────────────────────────────────────────────────────────────────────────────
-- FINAL: apply default opacity to everything that still carries the
-- default-opacity tag (i.e. did not opt out above). Must stay last — mirrors the
-- trailing `opacity ..., match:tag default-opacity` line of windows.conf.
hl.window_rule({ name = "default-opacity", match = { tag = "default-opacity" }, opacity = "0.97 0.9" })

-- Keybindings (port of the user's bindings.conf + Omarchy media / clipboard /
-- tiling-v2 / utilities binds). Where two source files bound the same key, the
-- later-sourced one wins (matching hyprland.conf source order); such cases are
-- noted inline.
--
-- Dispatcher strategy:
--   * Native hl.dsp.* is used for the calls proven in the shipped example.
--   * For dispatchers whose Lua argument schema is undocumented (fullscreen modes,
--     swapwindow, group ops, silent moves, ...), we pass the exact, stable conf
--     dispatcher string through `hyprctl dispatch`. These act on the active window,
--     same as the original binds, and can later be promoted to native hl.dsp.*
--     once verified in the `hyprctl` Lua REPL.

local bind = hl.bind
local exec = hl.dsp.exec_cmd

-- Dispatch a conf-style dispatcher string.
--
-- Under a NATIVE LUA config, `hyprctl dispatch <arg>` evaluates <arg> as Lua
-- (hl.dispatch(<arg>)), so the old conf strings ("swapwindow l", "fullscreen 0")
-- are no-ops. We translate each into its hl.dsp.* Lua form (every form below was
-- verified live in the hyprctl REPL) and dispatch THAT over IPC. The generated
-- expressions never contain a single quote, so single-quoting for the shell is
-- safe. An unmapped dispatcher passes through unchanged (best effort).
local DSP = {
    sendshortcut = function(a)
        local m, k, w = a:match("([^,]*),([^,]*),(.*)")
        return ('hl.dsp.send_shortcut({mods="%s", key="%s", window="%s"})'):format(m, k, w)
    end,
    fullscreen      = function(a) return ("hl.dsp.window.fullscreen(%s)"):format(a ~= "" and a or "0") end,
    fullscreenstate = function(a)
        local i, c = a:match("(%S+)%s+(%S+)")
        return ("hl.dsp.window.fullscreen_state({internal=%s, client=%s})"):format(i, c)
    end,
    movetoworkspacesilent = function(a)
        if a:match("^%d+$") then return ("hl.dsp.window.move({workspace=%s, silent=true})"):format(a) end
        return ('hl.dsp.window.move({workspace="%s", silent=true})'):format(a)
    end,
    workspace                     = function(a) return ('hl.dsp.focus({workspace="%s"})'):format(a) end,
    movecurrentworkspacetomonitor = function(a) return ('hl.dsp.workspace.move({monitor="%s"})'):format(a) end,
    swapwindow                    = function(a) return ('hl.dsp.window.swap({direction="%s"})'):format(a) end,
    cyclenext     = function(a) return a == "prev" and "hl.dsp.window.cycle_next({prev=true})" or "hl.dsp.window.cycle_next()" end,
    bringactivetotop = function() return "hl.dsp.window.bring_to_top()" end,
    focusmonitor  = function(a) return ('hl.dsp.focus({monitor="%s"})'):format(a) end,
    resizeactive  = function(a)
        local dx, dy = a:match("(%-?%d+)%s+(%-?%d+)")
        return ("hl.dsp.window.resize({x=%s, y=%s, relative=true})"):format(dx, dy)
    end,
    togglegroup   = function() return "hl.dsp.group.toggle()" end,
    moveintogroup = function(a) return ('hl.dsp.group.move_window({direction="%s"})'):format(a) end,
    -- NOTE: best-effort — moveoutofgroup has no dedicated hl.dsp.* in the 0.55 stub;
    -- deny_from_group is the closest. Verify after restart; may need adjustment.
    moveoutofgroup = function() return "hl.dsp.window.deny_from_group()" end,
    changegroupactive = function(a)
        if a == "f" then return "hl.dsp.group.next()" end
        if a == "b" then return "hl.dsp.group.prev()" end
        return ("hl.dsp.group.active({index=%s})"):format(a)
    end,
}

local function dispatch(raw)
    local cmd, a = raw:match("^(%S+)%s*(.*)$")
    local builder = DSP[cmd]
    if builder then
        return hl.dsp.exec_cmd("hyprctl dispatch '" .. builder(a) .. "'")
    end
    return hl.dsp.exec_cmd("hyprctl dispatch " .. raw)  -- unmapped: pass through
end

local SUPER = "SUPER"

--------------------------------------------------------------------------------
-- Application launchers (user bindings.conf)
--------------------------------------------------------------------------------
bind(SUPER .. " + RETURN",            exec('uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"'), { description = "Terminal" })
bind(SUPER .. " + SHIFT + F",         exec("uwsm-app -- nautilus --new-window"),       { description = "File manager" })
bind(SUPER .. " + SHIFT + B",         exec("omarchy-launch-browser"),                  { description = "Browser" })
bind(SUPER .. " + SHIFT + ALT + B",   exec("omarchy-launch-browser --private"),        { description = "Browser (private)" })
bind(SUPER .. " + SHIFT + M",         exec("omarchy-launch-or-focus spotify"),         { description = "Music" })
bind(SUPER .. " + SHIFT + N",         exec("omarchy-launch-editor"),                   { description = "Editor" })
bind(SUPER .. " + SHIFT + D",         exec("omarchy-launch-tui lazydocker"),           { description = "Docker" })
bind(SUPER .. " + SHIFT + G",         exec('omarchy-launch-or-focus ^signal$ "uwsm-app -- signal-desktop"'), { description = "Signal" })
bind(SUPER .. " + SHIFT + O",         exec('omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian -disable-gpu --enable-wayland-ime"'), { description = "Obsidian" })
bind(SUPER .. " + SHIFT + W",         exec("uwsm-app -- typora --enable-wayland-ime"), { description = "Typora" })
bind(SUPER .. " + SHIFT + SLASH",     exec("uwsm-app -- 1password"),                   { description = "Passwords" })

bind(SUPER .. " + SHIFT + A",         exec('omarchy-launch-webapp "https://chatgpt.com"'),        { description = "ChatGPT" })
bind(SUPER .. " + SHIFT + ALT + A",   exec('omarchy-launch-webapp "https://grok.com"'),           { description = "Grok" })
bind(SUPER .. " + SHIFT + C",         exec('omarchy-launch-webapp "https://app.hey.com/calendar/weeks/"'), { description = "Calendar" })
bind(SUPER .. " + SHIFT + E",         exec('omarchy-launch-webapp "https://app.hey.com"'),        { description = "Email" })
bind(SUPER .. " + SHIFT + Y",         exec('omarchy-launch-webapp "https://youtube.com/"'),       { description = "YouTube" })
bind(SUPER .. " + SHIFT + ALT + G",   exec('omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"'), { description = "WhatsApp" })
bind(SUPER .. " + SHIFT + CTRL + G",  exec('omarchy-launch-or-focus-webapp "Google Messages" "https://messages.google.com/web/conversations"'), { description = "Google Messages" })
bind(SUPER .. " + SHIFT + P",         exec('omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"'), { description = "Google Photos" })
bind(SUPER .. " + SHIFT + X",         exec('omarchy-launch-webapp "https://x.com/"'),             { description = "X" })
bind(SUPER .. " + SHIFT + ALT + X",   exec('omarchy-launch-webapp "https://x.com/compose/post"'), { description = "X Post" })

--------------------------------------------------------------------------------
-- Clipboard (Omarchy clipboard.conf)
-- NOTE: SUPER+C is rebound to "Close window" below (tiling-v2 is sourced after
-- clipboard), so universal-copy on SUPER+C is intentionally NOT active here.
--------------------------------------------------------------------------------
bind(SUPER .. " + V",        dispatch("sendshortcut SHIFT,Insert,activewindow"), { description = "Universal paste" })
bind(SUPER .. " + X",        dispatch("sendshortcut CTRL,X,activewindow"),       { description = "Universal cut" })
bind(SUPER .. " + CTRL + V", exec("omarchy-launch-walker -m clipboard"),         { description = "Clipboard manager" })

--------------------------------------------------------------------------------
-- Tiling / window control (Omarchy tiling-v2.conf)
--------------------------------------------------------------------------------
bind(SUPER .. " + C",        hl.dsp.window.close(),                  { description = "Close window" })
bind("CTRL + ALT + DELETE",  exec("omarchy-hyprland-window-close-all"), { description = "Close all windows" })

bind(SUPER .. " + J",        hl.dsp.layout("togglesplit"),           { description = "Toggle window split" })
bind(SUPER .. " + P",        hl.dsp.window.pseudo(),                 { description = "Pseudo window" })

-- Desktop-mode floating overlay (plugins/hyprdesktop C++ plugin). Call hl.plugin.*
-- functions directly — custom dispatchers like hyprdesktop:smartfloat cannot go through
-- the dispatch() helper (hyprctl evaluates unmapped args as Lua and silently no-ops).
local function hyprdesktop(name, fallback)
    return function()
        local p = hl.plugin and hl.plugin.hyprdesktop
        if p and p[name] then
            return p[name]()
        end
        if fallback then
            return fallback()
        end
    end
end
-- SUPER + T: smart float/tile toggle — on float, shrinks any full-size axis to 80%
-- of the monitor and centres the window below the bar.
bind(SUPER .. " + T",        hyprdesktop("smartfloat", hl.dsp.window.float), { description = "Toggle floating/tiling (smart size, bar-aware)" })
-- SUPER + A: toggle the floating layer visible <-> hidden (ghosted).
bind(SUPER .. " + A",        hyprdesktop("toggle"),    { description = "Toggle desktop floating layer" })
bind(SUPER .. " + F",        dispatch("fullscreen 0"),               { description = "Full screen" })
bind(SUPER .. " + CTRL + F", dispatch("fullscreenstate 0 2"),        { description = "Tiled full screen" })
-- `fullscreen 1` (positional) becomes real fullscreen and covers the bar; the
-- table form `fullscreen({mode=1})` is the maximize that respects the reserved area
-- (it fills the monitor *below* the bar). Verified in the hyprctl Lua REPL.
bind(SUPER .. " + ALT + F",  hl.dsp.window.fullscreen({ mode = 1 }), { description = "Full width (respect bar)" })
bind(SUPER .. " + O",        exec("omarchy-hyprland-window-pop"),    { description = "Pop window out (float & pin)" })
bind(SUPER .. " + L",        exec("omarchy-hyprland-workspace-layout-toggle"), { description = "Toggle workspace layout" })

-- Move focus
bind(SUPER .. " + LEFT",  hl.dsp.focus({ direction = "left" }),  { description = "Focus left" })
bind(SUPER .. " + RIGHT", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
bind(SUPER .. " + UP",    hl.dsp.focus({ direction = "up" }),    { description = "Focus up" })
bind(SUPER .. " + DOWN",  hl.dsp.focus({ direction = "down" }),  { description = "Focus down" })

-- Workspaces 1..10 / move window to workspace / move silently
for i = 1, 10 do
    local key = i % 10  -- 10 -> key "0"
    bind(SUPER .. " + " .. key,                hl.dsp.focus({ workspace = i }),               { description = "Switch to workspace " .. i })
    bind(SUPER .. " + SHIFT + " .. key,        hl.dsp.window.move({ workspace = i }),         { description = "Move window to workspace " .. i })
    bind(SUPER .. " + SHIFT + ALT + " .. key,  dispatch("movetoworkspacesilent " .. i),       { description = "Move window silently to workspace " .. i })
end

-- Scratchpad
bind(SUPER .. " + S",       hl.dsp.workspace.toggle_special("scratchpad"),            { description = "Toggle scratchpad" })
bind(SUPER .. " + ALT + S", dispatch("movetoworkspacesilent special:scratchpad"),     { description = "Move window to scratchpad" })

-- TAB between workspaces
bind(SUPER .. " + TAB",         hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
bind(SUPER .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
bind(SUPER .. " + CTRL + TAB",  dispatch("workspace previous"),      { description = "Former workspace" })

-- Move workspace to another monitor
bind(SUPER .. " + SHIFT + ALT + LEFT",  dispatch("movecurrentworkspacetomonitor l"), { description = "Move workspace to left monitor" })
bind(SUPER .. " + SHIFT + ALT + RIGHT", dispatch("movecurrentworkspacetomonitor r"), { description = "Move workspace to right monitor" })
bind(SUPER .. " + SHIFT + ALT + UP",    dispatch("movecurrentworkspacetomonitor u"), { description = "Move workspace to up monitor" })
bind(SUPER .. " + SHIFT + ALT + DOWN",  dispatch("movecurrentworkspacetomonitor d"), { description = "Move workspace to down monitor" })

-- Swap window with neighbor
bind(SUPER .. " + SHIFT + LEFT",  dispatch("swapwindow l"), { description = "Swap window left" })
bind(SUPER .. " + SHIFT + RIGHT", dispatch("swapwindow r"), { description = "Swap window right" })
bind(SUPER .. " + SHIFT + UP",    dispatch("swapwindow u"), { description = "Swap window up" })
bind(SUPER .. " + SHIFT + DOWN",  dispatch("swapwindow d"), { description = "Swap window down" })

-- Cycle windows / reveal on top
bind("ALT + TAB",         dispatch("cyclenext"),       { description = "Focus next window" })
bind("ALT + SHIFT + TAB", dispatch("cyclenext prev"),  { description = "Focus previous window" })
bind("ALT + TAB",         dispatch("bringactivetotop"),{ description = "Reveal active window on top" })

-- Cycle monitors
bind("CTRL + ALT + TAB",         dispatch("focusmonitor +1"), { description = "Focus next monitor" })
bind("CTRL + ALT + SHIFT + TAB", dispatch("focusmonitor -1"), { description = "Focus previous monitor" })

-- Resize active window (minus / equal keys)
bind(SUPER .. " + minus",         dispatch("resizeactive -100 0"), { description = "Expand window left" })
bind(SUPER .. " + equal",         dispatch("resizeactive 100 0"),  { description = "Shrink window left" })
bind(SUPER .. " + SHIFT + minus", dispatch("resizeactive 0 -100"), { description = "Shrink window up" })
bind(SUPER .. " + SHIFT + equal", dispatch("resizeactive 0 100"),  { description = "Expand window down" })

-- Scroll through workspaces with SUPER + scroll
bind(SUPER .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll workspace forward" })
bind(SUPER .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll workspace backward" })

-- Move / tiled swap: SUPER + LMB drag. Floating managed windows are handled by the
-- hyprdesktop plugin (it cancels the event before this bind fires); tiled windows
-- fall through to the native movewindow dispatcher, which swaps them on drop.
-- RMB is intentionally left unbound; border-edge drag (resize_on_border) resizes.
bind(SUPER .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window (tiled: swap on drop)" })

-- Groups
bind(SUPER .. " + G",       dispatch("togglegroup"),    { description = "Toggle window grouping" })
bind(SUPER .. " + ALT + G", dispatch("moveoutofgroup"), { description = "Move window out of group" })
bind(SUPER .. " + ALT + LEFT",  dispatch("moveintogroup l"), { description = "Move window to group left" })
bind(SUPER .. " + ALT + RIGHT", dispatch("moveintogroup r"), { description = "Move window to group right" })
bind(SUPER .. " + ALT + UP",    dispatch("moveintogroup u"), { description = "Move window to group up" })
bind(SUPER .. " + ALT + DOWN",  dispatch("moveintogroup d"), { description = "Move window to group down" })
bind(SUPER .. " + ALT + TAB",       dispatch("changegroupactive f"), { description = "Next window in group" })
bind(SUPER .. " + ALT + SHIFT + TAB", dispatch("changegroupactive b"), { description = "Previous window in group" })
bind(SUPER .. " + CTRL + LEFT",  dispatch("changegroupactive b"), { description = "Grouped focus left" })
bind(SUPER .. " + CTRL + RIGHT", dispatch("changegroupactive f"), { description = "Grouped focus right" })
bind(SUPER .. " + ALT + mouse_down", dispatch("changegroupactive f"), { description = "Next window in group" })
bind(SUPER .. " + ALT + mouse_up",   dispatch("changegroupactive b"), { description = "Previous window in group" })
for i = 1, 5 do
    bind(SUPER .. " + ALT + " .. i, dispatch("changegroupactive " .. i), { description = "Switch to group window " .. i })
end

-- Monitor scaling
bind(SUPER .. " + code:61",       exec("omarchy-hyprland-monitor-scaling-cycle"),           { description = "Cycle monitor scaling" })
bind(SUPER .. " + ALT + code:61", exec("omarchy-hyprland-monitor-scaling-cycle --reverse"), { description = "Cycle monitor scaling backwards" })

--------------------------------------------------------------------------------
-- Utilities (Omarchy utilities.conf)
--------------------------------------------------------------------------------
-- Menus
bind(SUPER .. " + SPACE",          exec("omarchy-launch-walker"),            { description = "Launch apps" })
bind(SUPER .. " + CTRL + E",       exec("omarchy-launch-walker -m symbols"), { description = "Emoji picker" })
bind(SUPER .. " + CTRL + C",       exec("omarchy-menu capture"),             { description = "Capture menu" })
bind(SUPER .. " + CTRL + O",       exec("omarchy-menu toggle"),              { description = "Toggle menu" })
bind(SUPER .. " + CTRL + H",       exec("omarchy-menu hardware"),            { description = "Hardware menu" })
bind(SUPER .. " + ALT + SPACE",    exec("omarchy-menu"),                     { description = "Omarchy menu" })
bind(SUPER .. " + SHIFT + code:201", exec("omarchy-menu"),                   { description = "Omarchy menu" })
bind(SUPER .. " + ESCAPE",         exec("omarchy-menu system"),              { description = "System menu" })
bind("XF86PowerOff",               exec("omarchy-menu system"),              { locked = true, description = "Power menu" })
bind(SUPER .. " + K",              exec("omarchy-menu-keybindings"),         { description = "Show key bindings" })
bind("XF86Calculator",             exec("gnome-calculator"),                 { description = "Calculator" })

-- Aesthetics
bind(SUPER .. " + SHIFT + SPACE",        exec("omarchy-toggle-waybar"),          { description = "Toggle top bar" })
bind(SUPER .. " + CTRL + SPACE",         exec("omarchy-menu background"),        { description = "Theme background menu" })
bind(SUPER .. " + SHIFT + CTRL + SPACE", exec("omarchy-menu theme"),             { description = "Theme menu" })
bind(SUPER .. " + BACKSPACE",            exec("omarchy-hyprland-window-transparency-toggle"), { description = "Toggle window transparency" })
bind(SUPER .. " + SHIFT + BACKSPACE",    exec("omarchy-hyprland-window-gaps-toggle"),         { description = "Toggle window gaps" })
bind(SUPER .. " + CTRL + BACKSPACE",     exec("omarchy-hyprland-window-single-square-aspect-toggle"), { description = "Toggle single-window square aspect" })

-- Notifications
bind(SUPER .. " + COMMA",             exec("makoctl dismiss"),        { description = "Dismiss last notification" })
bind(SUPER .. " + SHIFT + COMMA",     exec("makoctl dismiss --all"),  { description = "Dismiss all notifications" })
bind(SUPER .. " + CTRL + COMMA",      exec("omarchy-toggle-notification-silencing"), { description = "Toggle notification silencing" })
bind(SUPER .. " + ALT + COMMA",       exec("makoctl invoke"),         { description = "Invoke last notification" })
bind(SUPER .. " + SHIFT + ALT + COMMA", exec("makoctl restore"),      { description = "Restore last notification" })

-- Toggles
bind(SUPER .. " + CTRL + I",        exec("omarchy-toggle-idle"),       { description = "Toggle locking on idle" })
bind(SUPER .. " + CTRL + N",        exec("omarchy-toggle-nightlight"), { description = "Toggle nightlight" })
bind(SUPER .. " + CTRL + DELETE",   exec("omarchy-hyprland-monitor-internal toggle"),        { description = "Toggle laptop display" })
bind(SUPER .. " + CTRL + ALT + DELETE", exec("omarchy-hyprland-monitor-internal-mirror toggle"), { description = "Toggle laptop display mirroring" })
bind("switch:on:Lid Switch",  exec("omarchy-hw-external-monitors && omarchy-hyprland-monitor-internal off"), { locked = true })
bind("switch:off:Lid Switch", exec("omarchy-hyprland-monitor-internal on"), { locked = true })

-- Captures
bind("PRINT",               exec("omarchy-capture-screenshot"),      { description = "Screenshot" })
bind("ALT + PRINT",         exec("omarchy-menu screenrecord"),       { description = "Screenrecording" })
bind(SUPER .. " + PRINT",   exec("pkill hyprpicker || hyprpicker -a"), { description = "Color picker" })
bind(SUPER .. " + CTRL + PRINT", exec("omarchy-capture-text-extraction"), { description = "OCR from screenshot" })

-- File sharing
bind(SUPER .. " + CTRL + S", exec("omarchy-menu share"), { description = "Share" })

-- Transcoding
bind(SUPER .. " + CTRL + PERIOD", exec("omarchy-transcode"), { description = "Transcode" })

-- Reminders
bind(SUPER .. " + CTRL + R",        exec("omarchy-menu reminder-set"), { description = "Set reminder" })
bind(SUPER .. " + CTRL + ALT + R",  exec("omarchy-reminder show"),     { description = "Show reminders" })
bind(SUPER .. " + SHIFT + CTRL + R", exec("omarchy-reminder clear"),   { description = "Clear reminders" })

-- Waybar-less information
bind(SUPER .. " + CTRL + ALT + T", exec([[notify-send -u low "    $(date +"%A %H:%M  ·  %d %B %Y  ·  Week %V")"]]), { description = "Show time" })
bind(SUPER .. " + CTRL + ALT + B", exec('notify-send -u low "$(omarchy-battery-status)"'), { description = "Show battery remaining" })
bind(SUPER .. " + CTRL + ALT + W", exec('notify-send -u low "$(omarchy-weather-status)"'), { description = "Show weather" })

-- Control panels
bind(SUPER .. " + CTRL + A", exec("omarchy-launch-audio"),     { description = "Audio controls" })
bind(SUPER .. " + CTRL + B", exec("omarchy-launch-bluetooth"), { description = "Bluetooth controls" })
bind(SUPER .. " + CTRL + W", exec("omarchy-launch-wifi"),      { description = "Wifi controls" })
bind(SUPER .. " + CTRL + T", exec("omarchy-launch-tui btop"),  { description = "Activity" })

-- Dictation
bind(SUPER .. " + CTRL + X", exec("voxtype record toggle"), { description = "Toggle dictation" })
bind("F9", exec("voxtype record start"), { description = "Start dictation (push-to-talk)" })
bind("F9", exec("voxtype record stop"),  { release = true, description = "Stop dictation (push-to-talk)" })

-- Zoom
bind(SUPER .. " + CTRL + Z",       exec([[hyprctl keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float + 1')]]), { description = "Zoom in" })
bind(SUPER .. " + CTRL + ALT + Z", exec("hyprctl keyword cursor:zoom_factor 1"), { description = "Reset zoom" })

-- Lock system
bind(SUPER .. " + CTRL + L", exec("omarchy-system-lock"), { description = "Lock system" })

--------------------------------------------------------------------------------
-- Media keys (Omarchy media.conf) -- locked so they work on the lock screen
--------------------------------------------------------------------------------
local LK = { locked = true }
bind("XF86AudioRaiseVolume",  exec("omarchy-swayosd-client --output-volume raise"),    LK)
bind("XF86AudioLowerVolume",  exec("omarchy-swayosd-client --output-volume lower"),    LK)
bind("XF86AudioMute",         exec("omarchy-swayosd-client --output-volume mute-toggle"), LK)
bind("XF86AudioMicMute",      exec("omarchy-audio-input-mute"),                        LK)
bind("XF86MonBrightnessUp",   exec("omarchy-brightness-display +5%"),                  LK)
bind("XF86MonBrightnessDown", exec("omarchy-brightness-display 5%-"),                  LK)
bind("SHIFT + XF86MonBrightnessUp",   exec("omarchy-brightness-display 100%"), LK)
bind("SHIFT + XF86MonBrightnessDown", exec("omarchy-brightness-display 1%"),   LK)
bind("XF86KbdBrightnessUp",   exec("omarchy-brightness-keyboard up"),   LK)
bind("XF86KbdBrightnessDown", exec("omarchy-brightness-keyboard down"), LK)
bind("XF86KbdLightOnOff",     exec("omarchy-brightness-keyboard cycle"), LK)
bind("XF86TouchpadToggle",    exec("omarchy-toggle-touchpad"),     LK)
bind("XF86TouchpadOn",        exec("omarchy-toggle-touchpad on"),  LK)
bind("XF86TouchpadOff",       exec("omarchy-toggle-touchpad off"), LK)

-- Precise 1% adjustments with ALT
bind("ALT + XF86AudioRaiseVolume",  exec("omarchy-swayosd-client --output-volume +1"), LK)
bind("ALT + XF86AudioLowerVolume",  exec("omarchy-swayosd-client --output-volume -1"), LK)
bind("ALT + XF86MonBrightnessUp",   exec("omarchy-brightness-display +1%"), LK)
bind("ALT + XF86MonBrightnessDown", exec("omarchy-brightness-display 1%-"), LK)

-- Player controls
bind("XF86AudioNext",  exec("omarchy-swayosd-client --playerctl next"),       LK)
bind("XF86AudioPause", exec("omarchy-swayosd-client --playerctl play-pause"), LK)
bind("XF86AudioPlay",  exec("omarchy-swayosd-client --playerctl play-pause"), LK)
bind("XF86AudioPrev",  exec("omarchy-swayosd-client --playerctl previous"),   LK)
bind(SUPER .. " + XF86AudioMute", exec("omarchy-audio-output-switch"),         LK)

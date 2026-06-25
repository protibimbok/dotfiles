-- CHANGE 2 — Floating windows behave like a desktop overlay.
--
--   (a) Click a floating window  -> it raises above the other floats.
--   (b) Focus a tiled window     -> the whole floating layer hides ("clicking the
--                                   background hides everything"). Floats are stashed
--                                   to a hidden special workspace, remembering where
--                                   each came from.
--   (c) SUPER + A                -> toggle the floating layer back / forth (restore
--                                   the stashed floats, or hide the current ones).
--
-- Decoration / move / resize for floats:
--   * border + rounding + shadow ........ looknfeel.lua
--   * resize by dragging border edges .... looknfeel.lua (resize_on_border = true)
--   * keyboard move / resize ............. binds.lua
--   * SUPER + T float toggle (smart size)  bottom of THIS file
--   * SUPER + LMB / RMB drag (move / resize) is defined at the bottom of THIS file.

local STASH = "special:floatstash"

-- address -> origin workspace name, for floats we have stashed.
local origin = {}
-- Guard against the window.active storm that our own moves/focus changes trigger.
local suppressing = false

local function quiet(ms)
    suppressing = true
    -- hl.timer REQUIRES a `type` ("oneshot" | "repeat"); omitting it raises
    -- `hl.timer: opts.type must be "repeat" or "oneshot"` at runtime, which left
    -- `suppressing` stuck true and silently disabled the whole overlay logic.
    hl.timer(function() suppressing = false end, { timeout = ms or 80, type = "oneshot" })
end

-- Stash one float (by address) into the hidden special workspace, silently so the
-- view does not jump. Uses the stable hyprctl dispatcher to target by address.
local function stash(win)
    origin[win.address] = win.workspace.name
    hl.exec_cmd("hyprctl dispatch movetoworkspacesilent " .. STASH .. ",address:" .. win.address)
end

-- Floats currently visible on workspace `wsid` that we should manage.
local function visible_floats(wsid)
    local out = {}
    for _, f in ipairs(hl.get_windows({ floating = true }) or {}) do
        if not f.pinned and f.workspace and not f.workspace.special
            and (wsid == nil or f.workspace.id == wsid) then
            out[#out + 1] = f
        end
    end
    return out
end

-- (a) Raise the focused float; (b) hide floats when a tile is focused.
hl.on("window.active", function(w)
    if suppressing or not w then return end

    if w.floating then
        if not w.pinned then
            hl.dispatch(hl.dsp.window.bring_to_top())   -- acts on the active window
        end
        return
    end

    -- Focus landed on a tiled window: hide the floating overlay.
    local floats = visible_floats(w.workspace and w.workspace.id or nil)
    if #floats == 0 then return end
    quiet()
    for _, f in ipairs(floats) do stash(f) end
end)

-- Restore everything we stashed, back to its origin workspace, on top.
local function restore_floats()
    if next(origin) == nil then return false end
    quiet()
    for addr, ws in pairs(origin) do
        hl.exec_cmd("hyprctl dispatch movetoworkspacesilent " .. ws .. ",address:" .. addr)
        hl.exec_cmd("hyprctl dispatch alterzorder top,address:" .. addr)
    end
    origin = {}
    return true
end

-- (c) Toggle the floating layer back / forth.
local function toggle_float_layer()
    if restore_floats() then return end       -- something was hidden -> bring it back
    local floats = visible_floats(nil)        -- nothing hidden -> hide what is shown
    if #floats == 0 then return end
    quiet()
    for _, f in ipairs(floats) do stash(f) end
end

hl.bind("SUPER + A", toggle_float_layer)   -- "Toggle floating layer"

--------------------------------------------------------------------------------
-- SUPER + drag move / resize (floats).
--
-- Bound as Dispatcher objects (hl.dsp.window.*) with `{ mouse = true }` — the
-- exact form from Hyprland's shipped example/hyprland.lua. `mouse = true` is what
-- engages the mouse-drag (bindm) latch so the window follows the cursor; an
-- earlier edit to `{ drag = true }` (not a real bind option) silently disabled
-- the latch, which is why move/resize stopped working.
--   SUPER + LMB drag = move; SUPER + RMB drag = resize.
-- Dragging a window's border edge also resizes (resize_on_border, looknfeel.lua).
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

--------------------------------------------------------------------------------
-- Smart float toggle (SUPER + T): tile <-> float.
--
-- An exec_cmd dispatcher (same kind as every app-launcher bind, so it fires
-- reliably). The script TOGGLES FIRST so the basic tile<->float can never be
-- lost, then — only going tiled -> float — shrinks any axis that filled the
-- monitor (>= 95%, i.e. effectively 100%) to 80% of the monitor and centres the
-- window. ALL arithmetic is done in jq (window/monitor sizes, in logical px via
-- /scale); the shell does no `$(( ))` math, which is what aborted the previous
-- version before it could toggle.
--
-- IMPORTANT: under a native Lua config the IPC `hyprctl dispatch <arg>` evaluates
-- <arg> as Lua (hl.dispatch(<arg>)), so legacy conf strings ("togglefloating",
-- "resizeactive ...") are no-ops. We therefore dispatch the Lua hl.dsp.* forms,
-- verified in the hyprctl REPL:
--   togglefloating       -> hl.dsp.window.float({action="toggle"})
--   resizeactive exact   -> hl.dsp.window.resize({exact=true, x=W, y=H})
--   centerwindow         -> hl.dsp.window.center()
hl.bind("SUPER + T", hl.dsp.exec_cmd([[
w=$(hyprctl activewindow -j)
fl=$(printf '%s' "$w" | jq -r '.floating')
hyprctl dispatch 'hl.dsp.window.float({action="toggle"})'
[ "$fl" = "false" ] || exit 0          # was floating (or none) -> now tiled, done
m=$(hyprctl monitors -j | jq -c 'map(select(.focused))[0]')
set -- $(jq -n --argjson w "$w" --argjson m "$m" '
  ($m.width  / $m.scale) as $mw | ($m.height / $m.scale) as $mh |
  ($w.size[0]) as $sw | ($w.size[1]) as $sh |
  (($sw >= $mw*0.95) or ($sh >= $mh*0.95)) as $full |
  (if $sw >= $mw*0.95 then ($mw*0.8|floor) else $sw end) as $tw |
  (if $sh >= $mh*0.95 then ($mh*0.8|floor) else $sh end) as $th |
  "\($tw) \($th) \($full)"')
if [ "$3" = "true" ]; then
  hyprctl dispatch "hl.dsp.window.resize({exact=true, x=$1, y=$2})"
  hyprctl dispatch 'hl.dsp.window.center()'
fi
]]), { description = "Toggle floating/tiling (smart size)" })

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
-- While any float is on screen, focus follows explicit CLICKS, not the cursor
-- (input:follow_mouse is flipped to 0), so merely moving the pointer onto a tile
-- does not hide the overlay. Normal hover-focus returns once no floats are visible.
--
-- Whenever a window becomes floating (the SUPER + T toggle, or an app that opens
-- floating via a window rule) it is laid out "bar-aware":
--   * it never sits under the Quickshell bar (the bar reserves the top BAR_TOP px),
--   * it is centered in the area below the bar,
--   * it never grows — any axis that filled the workspace shrinks to 80% of the
--     monitor; other axes keep their size. (See place_float / smart_float_toggle.)
--
-- Decoration / move / resize for floats:
--   * border + rounding + shadow ........ looknfeel.lua
--   * resize by dragging border edges .... looknfeel.lua (resize_on_border = true)
--   * keyboard move / resize ............. binds.lua
--   * SUPER + T float toggle (smart size)  bottom of THIS file
--   * SUPER + LMB / RMB drag (move / resize) is defined at the bottom of THIS file.
--
-- IMPORTANT: under a native Lua config the IPC `hyprctl dispatch <arg>` evaluates
-- <arg> as Lua (hl.dispatch(<arg>)), so legacy conf strings ("movetoworkspacesilent",
-- "alterzorder", ...) are silent no-ops. Everything below therefore uses the native
-- hl.dsp.* dispatchers / hl.config, each verified live in the hyprctl Lua REPL.

local STASH      = "special:floatstash"   -- workspace selector
local STASH_NAME = "floatstash"           -- bare name, for toggle_special

-- The click-catching backdrop: a transparent fullscreen Quickshell FloatingWindow
-- (config/quickshell) that sits ABOVE the tiles and BELOW the real floats. Moving the
-- cursor onto it cannot focus a tile (so a focused float never loses focus), and a
-- click on it dismisses the whole overlay. Its decorations must be OFF — a blurred /
-- dimmed / bordered transparent window would itself read as a visible overlay — and
-- it must not steal focus from the float when it maps.
local SCRIM_TITLE = "omarchy-float-scrim"

hl.window_rule({
    name  = "float-scrim",
    match = { title = "^" .. SCRIM_TITLE .. "$" },
    float = true,
    border_size = 0, rounding = 0, no_shadow = true,
    no_blur = true, no_dim = true, no_anim = true, no_initial_focus = true,
    move = "200000 200000",   -- parked off-screen until a float appears
})

-- Where the backdrop rests when there is nothing to dismiss (far off-screen).
local SCRIM_PARK = 200000

local function is_scrim(w)
    return w ~= nil and (w.title == SCRIM_TITLE or w.initial_title == SCRIM_TITLE)
end

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

--------------------------------------------------------------------------------
-- Bar-aware floating geometry.
--
-- The Quickshell bar reserves the top BAR_TOP px of every monitor (its layer-shell
-- exclusiveZone; see config/quickshell/tokens/Metrics.qml `barHeight`). The Lua
-- HL.Monitor object does NOT expose `.reserved`, and the `center` dispatcher is NOT
-- reserved-aware in this Hyprland build (verified: it drops windows under the bar),
-- so we position floats explicitly with move({x, y}) using this offset.
local BAR_TOP         = 36     -- keep in sync with Metrics.qml `barHeight`
local FULL_FRACTION   = 0.95   -- an axis >= 95% of the monitor "filled the workspace"
local SHRINK_FRACTION = 0.80   -- ... and is shrunk to 80% of the monitor on float

-- Apply the desired floating geometry to the window at `addr`, judging "fullness"
-- against the reference size (refW, refH): for the SUPER + T toggle this is the
-- *tiled* size captured before the toggle; for windows that open floating it is
-- their opening size. Each axis that filled the monitor shrinks to 80%; the others
-- keep their size. The window is then centered inside the area below the bar so it
-- never overlaps it. The result is only the initial geometry — the user can freely
-- resize afterward. NB: HL.Window .size / .at are Vec2 objects (.x / .y), not arrays.
local function place_float(addr, refW, refH, mon)
    if not addr or not mon or not refW or not refH then return end
    local s  = mon.scale or 1
    local ox = mon.x or 0
    local oy = mon.y or 0
    local mw = mon.width / s
    local mh = mon.height / s

    local tw = (refW >= mw * FULL_FRACTION) and math.floor(mw * SHRINK_FRACTION) or refW
    local th = (refH >= mh * FULL_FRACTION) and math.floor(mh * SHRINK_FRACTION) or refH

    local uw = mw                 -- usable width
    local uh = mh - BAR_TOP       -- usable height (below the bar)
    if tw > uw then tw = uw end
    if th > uh then th = uh end

    local x = math.floor(ox + (uw - tw) / 2)
    local y = math.floor(oy + BAR_TOP + (uh - th) / 2)

    local tgt = "address:" .. addr
    -- resize first, then position (both target the window by address, so they work
    -- regardless of which window is currently focused — verified in the REPL).
    hl.dispatch(hl.dsp.window.resize({ exact = true, x = tw, y = th, window = tgt }))
    hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = tgt }))
end

-- Corner-anchored overlays (picture-in-picture, webcam) place themselves on purpose
-- via apps.lua and must not be re-centered. Add window tags / classes here to skip.
local EXCLUDE_TAGS = { pip = true }

local function has_excluded_tag(w)
    local tags = w.tags
    if type(tags) == "table" then
        for k, v in pairs(tags) do
            -- tags may be an array of names or a set keyed by name.
            if EXCLUDE_TAGS[v] or (EXCLUDE_TAGS[k] and v) then return true end
        end
    elseif type(tags) == "string" then
        if EXCLUDE_TAGS[tags] then return true end
    end
    return false
end

-- A float we should leave alone (the backdrop, pinned, stashed/special, or a corner overlay).
local function unmanaged(w)
    if not w then return true end
    if is_scrim(w) then return true end
    if w.pinned then return true end
    if w.workspace and w.workspace.special then return true end
    if has_excluded_tag(w) then return true end
    if w.title and w.title:match("Webcam") then return true end
    return false
end

local function window_by_addr(addr)
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.address == addr then return w end
    end
end

-- Floats currently visible (on a normal workspace) that we manage.
local function visible_floats(wsid)
    local out = {}
    for _, f in ipairs(hl.get_windows({ floating = true }) or {}) do
        if not f.pinned and not is_scrim(f) and f.workspace and not f.workspace.special
            and (wsid == nil or f.workspace.id == wsid) then
            out[#out + 1] = f
        end
    end
    return out
end

--------------------------------------------------------------------------------
-- Focus mode (issue 1): require an explicit click to change focus whenever a float
-- is visible, so moving the cursor onto a tile does not auto-hide the overlay.
-- `hyprctl keyword` does not apply under a native Lua config; hl.config does.
local DEFAULT_FOLLOW_MOUSE = 1

local function refresh_focus_mode()
    local n = (#visible_floats(nil) > 0) and 0 or DEFAULT_FOLLOW_MOUSE
    hl.config({ input = { follow_mouse = n } })
end

--------------------------------------------------------------------------------
-- The click-catching backdrop. Quickshell keeps the window mapped; we drive its
-- placement from here because Hyprland's `floating` state is authoritative (the
-- Quickshell-side IPC `floating` field is unreliable for freshly-opened windows).
-- When floats are visible it covers the monitor just below them; otherwise it is
-- parked far off-screen so it catches nothing.
local function get_scrim()
    for _, w in ipairs(hl.get_windows() or {}) do
        if is_scrim(w) then return w end
    end
end

local function update_scrim()
    local s = get_scrim()
    if not s then return end
    local tgt = "address:" .. s.address
    if #visible_floats(nil) > 0 then
        -- Follow the user to whichever workspace the floats are on.
        local aw = hl.get_active_workspace()
        if aw and aw.id and aw.id >= 0 then
            hl.dispatch(hl.dsp.window.move({ workspace = aw.id, window = tgt }))
        end
        local mon = s.monitor or hl.get_active_monitor()
        if mon then
            local sc = mon.scale or 1
            hl.dispatch(hl.dsp.window.resize({ exact = true,
                x = math.floor(mon.width / sc), y = math.floor(mon.height / sc), window = tgt }))
            hl.dispatch(hl.dsp.window.move({ x = mon.x or 0, y = mon.y or 0, window = tgt }))
        end
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "bottom", window = tgt }))
    else
        hl.dispatch(hl.dsp.window.move({ x = SCRIM_PARK, y = SCRIM_PARK, window = tgt }))
    end
end

-- Re-sync both the focus mode and the backdrop after any change in float visibility.
local function refresh_overlay()
    refresh_focus_mode()
    update_scrim()
end

--------------------------------------------------------------------------------
-- Hiding / restoring the floating layer (issue 2: hide PROPERLY).
--
-- Moving a window into a special workspace always SHOWS that workspace as a dimmed
-- overlay (the `silent` flag is not honored by this Hyprland build). So we stash the
-- floats into special:floatstash and then toggle that special workspace OFF, which
-- hides the overlay while keeping the windows parked there.

-- Move one float into the stash workspace (remembering where it came from).
local function stash(win)
    origin[win.address] = win.workspace.name
    hl.dispatch(hl.dsp.window.move({ workspace = STASH, window = "address:" .. win.address }))
end

local function hide_floats(floats)
    if #floats == 0 then return end
    quiet(200)
    for _, f in ipairs(floats) do stash(f) end
    -- The moves above surfaced special:floatstash; hide it again (guard against an
    -- accidental show if it was somehow already hidden).
    local sw = hl.get_active_special_workspace()
    if sw and sw.name == STASH then
        hl.dispatch(hl.dsp.workspace.toggle_special(STASH_NAME))
    end
    refresh_overlay()
end

-- Restore everything we stashed, back to its origin workspace. Floating windows
-- render above tiled ones by default, so no extra z-order step is needed; the stash
-- workspace stays hidden as we pull windows out of it.
local function restore_floats()
    if next(origin) == nil then return false end
    quiet(200)
    for addr, ws in pairs(origin) do
        hl.dispatch(hl.dsp.window.move({ workspace = ws, window = "address:" .. addr }))
    end
    origin = {}
    refresh_overlay()
    return true
end

-- (a) Raise the focused float; (b) hide the floating layer when a tile is focused.
hl.on("window.active", function(w)
    if suppressing or not w then return end
    if is_scrim(w) then return end             -- never raise/stash because of the backdrop

    if w.floating then
        if not w.pinned then
            hl.dispatch(hl.dsp.window.bring_to_top())   -- acts on the active window
        end
        return
    end

    -- Focus landed on a tiled window: hide the floating overlay.
    hide_floats(visible_floats(w.workspace and w.workspace.id or nil))
end)

-- (c) Toggle the floating layer back / forth.
local function toggle_float_layer()
    if restore_floats() then return end       -- something was hidden -> bring it back
    hide_floats(visible_floats(nil))           -- nothing hidden -> hide what is shown
end

hl.bind("SUPER + A", toggle_float_layer)   -- "Toggle floating layer"

-- Exposed GLOBAL so the Quickshell backdrop can dismiss the overlay on click:
--   Hyprland.dispatch("omarchy_float_dismiss()")
-- The IPC `dispatch` evaluates its argument as `hl.dispatch(<expr>)`, which requires a
-- Dispatcher result, so we hide the floats as a side effect and return a no-op.
function omarchy_float_dismiss()
    hide_floats(visible_floats(nil))
    return hl.dsp.no_op()
end

-- (req 1-3) Lay out any window that OPENS floating (app window rules). Re-checked on
-- a short timer so the float / size rules have settled before we read the geometry.
hl.on("window.open", function(w)
    if not w then return end
    local addr = w.address

    -- The backdrop just mapped: position it for the current float state.
    if is_scrim(w) then
        hl.timer(update_scrim, { timeout = 40, type = "oneshot" })
        return
    end

    hl.timer(function()
        local win = window_by_addr(addr)
        if win and win.floating and not unmanaged(win) then
            place_float(addr, win.size.x, win.size.y, win.monitor)
        end
        refresh_overlay()
    end, { timeout = 80, type = "oneshot" })
end)

-- Closing a visible float may end the click-to-focus mode / hide the backdrop.
hl.on("window.close", function()
    hl.timer(refresh_overlay, { timeout = 50, type = "oneshot" })
end)

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
-- Toggles float first (so the basic tile<->float can never be lost), then — only
-- going tiled -> float — applies the bar-aware layout (place_float). We capture the
-- window's *tiled* size BEFORE toggling: that is what tells us which axes filled the
-- workspace (and so should shrink to 80%). After the toggle Hyprland gives the float
-- its own default size, so reading the size afterward would lose that information.
local function smart_float_toggle()
    local w = hl.get_active_window()
    if not w then return end
    local addr       = w.address
    local mon        = w.monitor
    local was_float  = w.floating
    local refW, refH = w.size.x, w.size.y         -- pre-toggle (tiled) size

    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    if was_float then return end                 -- was floating -> now tiled, done

    -- Now floating: lay it out on a short timer so the float has settled.
    hl.timer(function()
        place_float(addr, refW, refH, mon)
        refresh_overlay()
    end, { timeout = 50, type = "oneshot" })
end

hl.bind("SUPER + T", smart_float_toggle, { description = "Toggle floating/tiling (smart size, bar-aware)" })

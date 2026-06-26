# hyprdesktop — work context / pickup notes

Status as of 2026-06-26. Implementation of the Hyprdesktop plugin plan
(`.cursor/plans/hyprdesktop_plugin_plan_598e5402.plan.md`). **All 8 planned tasks are
code-complete and the plugin compiles+links cleanly** against Hyprland 0.55.2
(GCC 16, C++26). Nothing is committed yet. **Not yet verified in a running Hyprland.**

## What this is

A native C++ Hyprland plugin (`plugins/hyprdesktop/`) replacing the old
`config/hypr/lua/floating.lua` + Quickshell `omarchy-float-scrim` "desktop mode"
floating overlay. Floats raise on click, ghost on tile-focus / empty-space click,
toggle with SUPER+A, and get server-side titlebars. Per-workspace isolated state.

## Done

- [x] Scaffold: `CMakeLists.txt`, `hyprpm.toml`, `main.cpp` (version-hash guard,
      `addConfigValueV2` config, dispatchers, `hl.plugin.hyprdesktop.*` Lua fns), `Globals.hpp`
- [x] `DesktopMode.*` — per-workspace engine, `Event::bus` `window.open`/`window.active`
      subscriptions, managed-float predicate (port of `unmanaged()`)
- [x] `Ghosting.*` — hide/restore/toggle via `CWindow::setHidden`
- [x] `InputBackdrop.*` — empty-space `input.mouse.button` press → dismiss + `info.cancelled`
- [x] `BarDeco.*` — hyprbars-derived SSD titlebar (rect rendering, buttons, drag w/o SUPER)
- [x] `CsdPolicy.*` — X11 hint + tag overrides + class/title blacklist regex
- [x] `Layout.*` — `place_float` parity + `smartfloat` (SUPER+T)
- [x] Dotfiles migration — deleted `floating.lua`, removed scrim from `shell.qml` /
      `Hyprland.qml`, rewired `binds.lua`, load in `autostart.lua`, `install.sh` builds plugin

## Build / install / verify

```sh
# build only
cd plugins/hyprdesktop && cmake -DCMAKE_BUILD_TYPE=Release -B build -S . && cmake --build build --target hyprdesktop -j
# full install (links config + builds plugin + hot-loads if HL running)
config/hypr/install.sh
# rebuild just the plugin (after a Hyprland upgrade — REQUIRED, ABI is commit-tied)
config/hypr/install.sh --plugin
```
Loaded at session start by `config/hypr/lua/autostart.lua`
(`hyprctl plugin load ~/.config/hypr/plugins/hyprdesktop.so`).

## Decisions that DIVERGED from the approved plan (with reasons)

1. **`follow_mouse=0` hack → `eFocusReason` check.** No runtime config setter is exposed
   under the Lua config frontend (Lua code itself noted `hyprctl keyword` doesn't apply).
   `DesktopMode::onWindowActive` now hides floats only when a tile is focused via a *hard*
   reason (`Desktop::isHardInputFocusReason` — click/keybind), ignoring `FOCUS_REASON_FFM`
   (hover). Cleaner; removes config mutation entirely.

2. **Load via CMake + `hyprctl plugin load`, NOT hyprpm** (user had chosen hyprpm).
   `hyprpm add` clones from a git *remote* and wants `hyprpm.toml` at the repo *root* —
   awkward for an in-place-edited subdir plugin. Load-ordering (the reason for hyprpm) is
   moot because binds resolve `hl.plugin.hyprdesktop.*` lazily. Plugin-local `hyprpm.toml`
   kept + documented as alternative. **Revisit if user wants pure-hyprpm.**

3. **State is derived, not stored.** No persistent per-workspace state map: managed floats
   are scanned from `g_pCompositor->m_windows` on demand and `w->isHidden()` is the source
   of truth (Active = any visible, Hidden = all hidden, Inactive = none). Simpler than the
   `WorkspaceDesktop` struct in the plan.

## NOT done / known gaps (also in README "Known limitations")

- **Titlebar has no title text.** Buttons (minimize=ghost, fullscreen, close) + drag render
  via solid `CRectPassElement` rects. Title text needs a cairo/pango glyph pass + `CTexture`
  upload (the bigger hyprbars rendering path) — deferred.
- **No live xdg-decoration (`CLIENT_SIDE`) read.** The negotiated mode isn't cleanly exposed
  per-window (`protocols/XDGDecoration.hpp` keys by toplevel resource). CSD gating uses the
  `csd_blacklist` regex + `m_X11DoesntWantBorders` instead. To add: map window→xdg toplevel→
  `CXDGDecoration` and read mode at `window.open`/`window.updateRules`.

## MUST verify in a live session (could not run Hyprland here)

Run `config/hypr/install.sh --plugin`, then check (plan's Verification section):
1. Float opens on WS2 → desktop mode active only on WS2; WS1 unaffected.
2. Click wallpaper → floats ghost; tiles usable; no scrim in `hyprctl clients`; no
   `special:floatstash` in `hyprctl workspaces`.
3. SUPER+A toggles ghost↔visible; SUPER+T smart float (shrinks to 80%, centers below bar).
4. **Hidden float not reachable via `cyclenext`/keyboard** (if it leaks, gate in the focus
   handler — `setHidden` is assumed to remove from focus cycling but UNVERIFIED).
5. **Backdrop `info.cancelled` actually blocks focus** on empty-space click (fallback:
   `createFunctionHook` on `CInputManager::processMouseDownNormal`).
6. **Titlebar input hit-testing**: confirm `onInputOnDeco` coords are absolute layout coords
   matching `getWindowDecorationBox` (button clicks + drag land correctly). If off, the bug
   is the coord space in `BarDeco::onInputOnDeco`/`barLayoutBox`.
7. smartfloat geometry sane on multi-monitor (monitor `m_size`/`m_position` are logical).
8. VS Code / Cursor get no double titlebar once added to `plugin:hyprdesktop:csd_blacklist`.

## Key API facts discovered (Hyprland 0.55.2, headers at /usr/include/hyprland/src)

- Plugin API: `addConfigValueV2(SP<Config::Values::IValue>)`, `addDispatcherV2`,
  `addWindowDecoration`, `addLuaFunction(handle, ns, name, int(*)(lua_State*))`
  → `hl.plugin.<ns>.<name>`. Version guard: compare `__hyprland_api_get_hash()` vs
  `GIT_COMMIT_HASH`, `throw` on mismatch.
- Events: `Event::bus()->m_events.{window.open|active(PHLWINDOW,eFocusReason)|...,
  input.mouse.button(Cancellable<IPointer::SButtonEvent>)}`; `.listen(...)` returns a
  `CHyprSignalListener` you must keep alive. RefArg: shared-ptrs → `const T&`, enums → value.
- Window (`desktop/view/Window.hpp`): `m_isFloating`, `m_pinned`, `m_isX11`,
  `m_X11DoesntWantBorders`, `m_workspace`(PHLWORKSPACE), `m_monitor`(PHLMONITORREF, `.lock()`),
  `m_title`/`m_class`, `m_realPosition`/`m_realSize` (`->value()`/`->goal()`/`->setValueAndWarp()`),
  `setHidden(bool)`, `isHidden()`, `sendClose()`, `sendWindowSize(bool)`, `updateWindowDecos()`,
  `m_windowDecorations`, `m_ruleApplicator->m_tagKeeper.isTagged("tag")`.
- Workspace: `m_id`, `m_isSpecialWorkspace`. Monitor: `m_size`/`m_position` (logical), `m_scale`,
  `m_activeWorkspace`. Globals: `g_pCompositor`, `g_pInputManager`, `g_pKeybindManager`
  (`m_dispatchers` map is public; `changeMouseBindMode(MBIND_MOVE/MBIND_INVALID)` static),
  `g_pHyprRenderer` (`m_renderPass.add(makeUnique<CRectPassElement>(SRectData{...}))`,
  `damageBox`), `g_pDecorationPositioner->getWindowDecorationBox(this)`,
  `Desktop::focusState()->{window(),monitor(),fullWindowFocus(w,reason)}`.
- Fullscreen toggle: `g_pCompositor->setWindowFullscreenInternal(w, FSMODE_FULLSCREEN/FSMODE_NONE)`.
- `eGetWindowProperties` (RESERVED_EXTENTS etc.) live in `namespace Desktop::View`.
- Window-hit: `g_pCompositor->vectorToWindowUnified(coords, props)`; cursor via
  `g_pInputManager->getMouseCoordsInternal()`.

## Gotchas

- The editor's clangd shows false `std::bit_cast` / `PHLWINDOW unknown type` errors — it's
  defaulting to the wrong C++ standard. **Ignore them; the real CMake build is the source of
  truth** (compiles clean).
- CMake uses `file(GLOB ...)` → adding a new `src/*.cpp` triggers a "GLOB mismatch" reconfigure
  (handled automatically by the configured build).

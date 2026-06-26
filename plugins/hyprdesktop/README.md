# hyprdesktop

A native Hyprland plugin implementing a **desktop-mode floating overlay**: floating
windows behave like a classic desktop — they raise on click, hide ("ghost") when you
focus a tile or click empty space, restore with a keybind, and wear server-side
titlebars (drag/min/fullscreen/close) that don't need a modifier.

It replaces the old `config/hypr/lua/floating.lua` + Quickshell `omarchy-float-scrim`
stack with a single compositor-side engine: no `special:floatstash` workspace, no scrim
window, no IPC. Per-workspace state is isolated (WS1 can be tiling-only while WS2 is in
desktop mode).

## Modules

| File | Responsibility |
|------|----------------|
| `main.cpp` | init/exit, version-hash guard, config, dispatchers, `hl.plugin.hyprdesktop.*` Lua fns |
| `DesktopMode.*` | per-workspace engine; `Event::bus` window/focus subscriptions; managed-float predicate |
| `Ghosting.*` | hide/restore/toggle via `CWindow::setHidden` |
| `InputBackdrop.*` | empty-space mouse-press → dismiss layer (swallows the click) |
| `BarDeco.*` | hyprbars-derived SSD titlebar: float-only, buttons, drag without SUPER |
| `CsdPolicy.*` | gates titlebars (X11 hint, tag overrides, class/title blacklist) |
| `Layout.*` | bar-aware float geometry (`place_float` parity) + smart float/tile toggle |

## Build

Requires `cmake`, a C++26 compiler, and the Hyprland devel headers (`pkg-config hyprland`).

```sh
cmake -DCMAKE_BUILD_TYPE=Release -B build -S .
cmake --build build --target hyprdesktop -j
# -> build/hyprdesktop.so
```

The dotfiles installer does this for you and copies the result to
`~/.config/hypr/plugins/hyprdesktop.so`:

```sh
config/hypr/install.sh            # full config + plugin
config/hypr/install.sh --plugin   # rebuild just the plugin (e.g. after a Hyprland upgrade)
```

> **Rebuild after every Hyprland upgrade.** The plugin links against Hyprland's C++
> objects and refuses to load if the commit hash differs (it shows a notification
> instead of crashing the compositor).

### Loading

`config/hypr/lua/autostart.lua` runs `hyprctl plugin load ~/.config/hypr/plugins/hyprdesktop.so`
at session start. Keybinds resolve `hl.plugin.hyprdesktop.*` lazily, so it does not
matter that the plugin loads after the Lua config is parsed.

Prefer [`hyprpm`](https://wiki.hypr.land/Plugins/Using-Plugins/)? It works too, but
`hyprpm add` clones from a **git remote** and expects `hyprpm.toml` at the repo *root*,
so you'd commit/push and add a root-level manifest — awkward for editing in place, which
is why the installer uses a direct CMake build instead. A plugin-local `hyprpm.toml` is
included as a starting point.

## Keybinds (set in `config/hypr/lua/binds.lua`)

| Key | Action | Dispatcher / Lua fn |
|-----|--------|---------------------|
| `SUPER + T` | smart float/tile toggle (bar-aware sizing) | `hyprdesktop:smartfloat` |
| `SUPER + A` | toggle floating layer visible ↔ hidden | `hyprdesktop:toggle` |
| titlebar drag | move float (no modifier) | — |
| `SUPER + RMB` | resize float | built-in |

`hyprdesktop:dismiss` is also available for scripted dismissal.

## Config (`plugin:hyprdesktop:*`)

| Key | Default | Purpose |
|-----|---------|---------|
| `enabled` | `true` | master switch |
| `top_reserved_px` | `36` | top bar offset for new-float centering (sync with the Quickshell bar) |
| `full_fraction` | `0.95` | axis fraction treated as "fills the monitor" |
| `shrink_fraction` | `0.80` | shrink a filled axis to this |
| `hide_on_tile_focus` | `true` | ghost floats when a tile is deliberately focused |
| `bars_when_hidden` | `false` | draw titlebars on hidden floats |
| `bar_height` | `24` | server titlebar height (px) |
| `csd_blacklist` | `""` | regex of classes/titles that must never get a server titlebar |
| `excluded_tags` | `pip` | comma-separated tags excluded from overlay management |

Per-window overrides via window-rule tags (e.g. in `config/hypr/lua/apps.lua`):
`+hyprdesktop:force_bar`, `+hyprdesktop:no_bar`.

## Known limitations / TODO

- **Titlebar has no title text yet** (buttons + drag work). Text needs a cairo/pango
  glyph pass; tracked as a follow-up.
- **No live xdg-decoration negotiation read.** CSD apps are gated via the `csd_blacklist`
  regex and the X11 borders hint rather than the negotiated `CLIENT_SIDE` mode.
- `hide_on_tile_focus` keys off the focus *reason* (`FFM` hover is ignored; click/keybind
  hide), which replaces the old `input:follow_mouse=0` toggle.

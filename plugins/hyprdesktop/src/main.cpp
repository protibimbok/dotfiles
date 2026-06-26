#define WLR_USE_UNSTABLE

#include "Globals.hpp"
#include "DesktopMode.hpp"
#include "Ghosting.hpp"
#include "InputBackdrop.hpp"
#include "Layout.hpp"

#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/helpers/Color.hpp>

#include <stdexcept>

using namespace Hyprdesktop;

// Required: must return the API version Hyprland expects. Do not modify.
APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static void registerConfig() {
    auto add = [](SP<Config::Values::IValue> v) { HyprlandAPI::addConfigValueV2(PHANDLE, v); };

    g_config.enabled = makeShared<Config::Values::CBoolValue>("plugin:hyprdesktop:enabled", "Master switch", true);
    add(g_config.enabled);

    g_config.topReservedPx = makeShared<Config::Values::CIntValue>("plugin:hyprdesktop:top_reserved_px",
                                                                   "Top bar offset (px) reserved for new-float layout", 36);
    add(g_config.topReservedPx);

    g_config.fullFraction = makeShared<Config::Values::CFloatValue>("plugin:hyprdesktop:full_fraction",
                                                                    "Axis fraction at which a float is considered to fill the monitor", 0.95F);
    add(g_config.fullFraction);

    g_config.shrinkFraction = makeShared<Config::Values::CFloatValue>("plugin:hyprdesktop:shrink_fraction",
                                                                      "Fraction to shrink a filled axis to", 0.80F);
    add(g_config.shrinkFraction);

    g_config.hideOnTileFocus = makeShared<Config::Values::CBoolValue>("plugin:hyprdesktop:hide_on_tile_focus",
                                                                      "Hide floats when a tiled window gains focus", true);
    add(g_config.hideOnTileFocus);

    g_config.barsWhenHidden = makeShared<Config::Values::CBoolValue>("plugin:hyprdesktop:bars_when_hidden",
                                                                     "Keep titlebars on hidden floats", false);
    add(g_config.barsWhenHidden);

    g_config.barHeight = makeShared<Config::Values::CIntValue>("plugin:hyprdesktop:bar_height",
                                                              "Height (px) of the server-side titlebar", 24);
    add(g_config.barHeight);

    g_config.csdBlacklist = makeShared<Config::Values::CStringValue>("plugin:hyprdesktop:csd_blacklist",
                                                                     "Regex of window classes that must never get a server titlebar", "");
    add(g_config.csdBlacklist);

    g_config.excludedTags = makeShared<Config::Values::CStringValue>("plugin:hyprdesktop:excluded_tags",
                                                                     "Comma-separated tags excluded from overlay management", "pip");
    add(g_config.excludedTags);
}

// Lua C callbacks exposed as hl.plugin.hyprdesktop.<name>. They ignore the lua_State
// (no args/returns) and just run the action. Bound in Lua via a runtime-lookup wrapper,
// which is load-order safe: hyprpm loads this plugin AFTER the Lua config is evaluated,
// so the binds must resolve hl.plugin.hyprdesktop.* lazily at key-press time.
static int luaToggle(lua_State*) {
    Hyprdesktop::Ghosting::toggleOn(Hyprdesktop::DesktopMode::focusedWorkspaceID());
    return 0;
}
static int luaDismiss(lua_State*) {
    Hyprdesktop::Ghosting::hideAllOn(Hyprdesktop::DesktopMode::focusedWorkspaceID());
    return 0;
}
static int luaSmartfloat(lua_State*) {
    Hyprdesktop::Layout::smartFloat();
    return 0;
}

static void registerLuaFunctions() {
    HyprlandAPI::addLuaFunction(PHANDLE, "hyprdesktop", "toggle", luaToggle);
    HyprlandAPI::addLuaFunction(PHANDLE, "hyprdesktop", "dismiss", luaDismiss);
    HyprlandAPI::addLuaFunction(PHANDLE, "hyprdesktop", "smartfloat", luaSmartfloat);
}

static void registerDispatchers() {
    // Dispatchers (not hl.plugin.* Lua fns) so Lua binds created before the plugin
    // loads still resolve at key-press time. Bodies are wired up in later modules.
    HyprlandAPI::addDispatcherV2(PHANDLE, "hyprdesktop:toggle", [](std::string) -> SDispatchResult {
        Hyprdesktop::Ghosting::toggleOn(Hyprdesktop::DesktopMode::focusedWorkspaceID());
        return {};
    });
    HyprlandAPI::addDispatcherV2(PHANDLE, "hyprdesktop:dismiss", [](std::string) -> SDispatchResult {
        Hyprdesktop::Ghosting::hideAllOn(Hyprdesktop::DesktopMode::focusedWorkspaceID());
        return {};
    });
    HyprlandAPI::addDispatcherV2(PHANDLE, "hyprdesktop:smartfloat", [](std::string) -> SDispatchResult {
        Hyprdesktop::Layout::smartFloat();
        return {};
    });
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    // Refuse to load against a Hyprland built from a different commit — the C++ ABI
    // is not stable across versions, so a mismatch would crash the compositor.
    const std::string HASH = __hyprland_api_get_hash();
    if (HASH != std::string(GIT_COMMIT_HASH)) {
        HyprlandAPI::addNotification(PHANDLE, "[hyprdesktop] Mismatched Hyprland version — rebuild the plugin.",
                                     CHyprColor{1.0, 0.2, 0.2, 1.0}, 8000);
        throw std::runtime_error("[hyprdesktop] version mismatch");
    }

    registerConfig();
    registerLuaFunctions();
    registerDispatchers();
    DesktopMode::init();
    InputBackdrop::init();

    HyprlandAPI::reloadConfig();

    return {"hyprdesktop", "Desktop-mode floating overlay (state engine, ghosting, backdrop, SSD titlebars)", "Saad", "0.1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    InputBackdrop::cleanup();
    DesktopMode::cleanup();
    // Decorations, dispatchers, and config values are torn down by Hyprland on unload.
}

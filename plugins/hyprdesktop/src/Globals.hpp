#pragma once

#include <hyprland/src/plugins/PluginAPI.hpp>

#include <hyprland/src/config/values/types/BoolValue.hpp>
#include <hyprland/src/config/values/types/IntValue.hpp>
#include <hyprland/src/config/values/types/FloatValue.hpp>
#include <hyprland/src/config/values/types/StringValue.hpp>

// The handle Hyprland hands us in pluginInit; identifies this plugin to the API.
inline HANDLE PHANDLE = nullptr;

namespace Hyprdesktop {
    // Config values registered via addConfigValueV2. We keep the shared pointers so
    // modules can read the live, parsed value with ->value().
    struct SConfig {
        SP<Config::Values::CBoolValue>   enabled;
        SP<Config::Values::CIntValue>    topReservedPx;
        SP<Config::Values::CFloatValue>  fullFraction;
        SP<Config::Values::CFloatValue>  shrinkFraction;
        SP<Config::Values::CBoolValue>   hideOnTileFocus;
        SP<Config::Values::CBoolValue>   barsWhenHidden;
        SP<Config::Values::CIntValue>    barHeight;
        SP<Config::Values::CStringValue> csdBlacklist;
        SP<Config::Values::CStringValue> excludedTags;
    };

    inline SConfig g_config;
}

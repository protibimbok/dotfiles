#pragma once

#include "Globals.hpp"

#include <hyprland/src/desktop/DesktopTypes.hpp>

// Decides whether a window should receive a server-side titlebar, avoiding the
// classic "double titlebar" against client-side-decorated apps.
namespace Hyprdesktop::CsdPolicy {
    // true  -> attach a server titlebar
    // false -> the app draws its own decorations / is blacklisted / opted out
    bool wantsServerBar(const PHLWINDOW& w);
}

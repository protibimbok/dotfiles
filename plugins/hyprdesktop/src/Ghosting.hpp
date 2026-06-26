#pragma once

#include "Globals.hpp"

#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/SharedDefs.hpp>

// Hide ("ghost") mechanics built on CWindow::setHidden — one call removes the window
// from render, input, and focus cycling while preserving geometry. Replaces the entire
// special:floatstash stash/restore machinery from floating.lua.
namespace Hyprdesktop::Ghosting {
    void hide(const PHLWINDOW& w);
    void restore(const PHLWINDOW& w);

    // Whole-workspace operations over managed floats.
    void hideAllOn(WORKSPACEID ws);
    void restoreAllOn(WORKSPACEID ws);

    // SUPER+A parity: if any managed float is visible -> hide all; else restore all.
    void toggleOn(WORKSPACEID ws);
}

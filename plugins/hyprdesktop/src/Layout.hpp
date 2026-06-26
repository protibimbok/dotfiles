#pragma once

#include "Globals.hpp"

#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/helpers/math/Math.hpp>

// Bar-aware float geometry, ported from place_float() in floating.lua:
// shrink any axis that fills the monitor, then center the window in the area below
// the top bar (top_reserved_px).
namespace Hyprdesktop::Layout {
    // Place w using refSize to decide whether an axis "fills" the monitor.
    void place(const PHLWINDOW& w, const Vector2D& refSize);

    // window.open path: lay out a freshly-opened float using its current size.
    void placeNewFloat(const PHLWINDOW& w);

    // hyprdesktop:smartfloat (SUPER+T parity): toggle float/tile, and on float apply
    // bar-aware geometry using the pre-toggle size.
    void smartFloat();
}

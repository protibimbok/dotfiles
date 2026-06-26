#pragma once

#include "Globals.hpp"

#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/SharedDefs.hpp>

#include <vector>

// The Desktop-Mode engine. State is *derived*, not stored: a workspace is
//   - Inactive : no managed floats
//   - Active   : has managed floats, at least one visible
//   - Hidden   : has managed floats, all hidden
// so the only persistent thing we need are the Event::bus listeners. Membership is
// computed by scanning windows (cheap; mirrors the old visible_floats() in floating.lua).
namespace Hyprdesktop::DesktopMode {
    void init();    // subscribe to Event::bus
    void cleanup(); // drop listeners

    // Managed-float predicate, ported from floating.lua unmanaged():
    // floating, not pinned, not special, not tag-excluded, not a Webcam title.
    bool isManaged(const PHLWINDOW& w);

    std::vector<PHLWINDOW> managedFloatsOn(WORKSPACEID ws);
    bool                   anyVisibleManaged(WORKSPACEID ws);
    bool                   hasManaged(WORKSPACEID ws);

    // The workspace the user is currently on (focused monitor's active workspace).
    WORKSPACEID focusedWorkspaceID();

    bool pluginEnabled();
}

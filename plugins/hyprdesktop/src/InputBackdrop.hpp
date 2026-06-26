#pragma once

// Compositor-side replacement for the Quickshell "omarchy-float-scrim": when the
// desktop layer is visible and the user presses on empty space (no window under the
// cursor), hide the floats and swallow the click. Clicks on tiled windows are handled
// separately by DesktopMode::onWindowActive (focus-reason CLICK).
namespace Hyprdesktop::InputBackdrop {
    void init();
    void cleanup();
}

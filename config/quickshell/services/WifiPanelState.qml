pragma Singleton
import QtQuick
import Quickshell

// Shared hover state for the Wi-Fi panel. The bar's network icon lives in the bar
// window while the panel is its own layer-shell window, so the "is the icon
// hovered" bit has to travel between windows through this singleton.
Singleton {
    id: root

    property bool iconHovered: false
}

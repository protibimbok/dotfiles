pragma Singleton
import QtQuick
import Quickshell

// Shared state for the unread-notifications dropdown. The badge lives in the bar
// window while the panel is its own centered layer-shell window, so both the "is
// the badge hovered" bit and the "is the panel open" bit have to travel between
// windows through this singleton. `panelOpen` also lets NotificationToasts stay
// silent while the panel is already showing the unread list.
Singleton {
    id: root

    property bool iconHovered: false
    property bool panelOpen: false
}

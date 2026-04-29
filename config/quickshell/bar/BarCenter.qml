import QtQuick
import QtQuick.Layouts
import qs.bar.components

RowLayout {
    id: root

    required property var shellRoot

    spacing: 0

    ClockNotifWidget {
        Layout.fillHeight: true
        Layout.preferredHeight: 44
        onPanelRequested: root.shellRoot.notifPanelVisible = !root.shellRoot.notifPanelVisible
    }
}

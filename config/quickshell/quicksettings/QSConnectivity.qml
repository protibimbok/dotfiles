import QtQuick
import QtQuick.Layouts
import qs.theme

ColumnLayout {
    id: root

    required property var shellRoot

    Layout.fillWidth: true
    spacing: 0

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        QSWifiTile {
            shellRoot: root.shellRoot
        }

        QSBluetoothTile {
            shellRoot: root.shellRoot
        }
    }
}

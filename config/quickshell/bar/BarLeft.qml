import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.bar.components

RowLayout {
    id: root

    required property var shellRoot

    spacing: 8

    WorkspaceBar {}
}

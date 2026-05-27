import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.bar.components

RowLayout {
    id: root

    required property var shellRoot

    spacing: Spacing.pillGap

    WorkspaceBar {}
}

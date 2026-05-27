import QtQuick
import QtQuick.Templates
import qs.theme
import qs.tokens

ScrollBar {
    id: root

    required property Flickable flickable

    implicitWidth: Spacing.sm

    contentItem: StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        opacity: root.size === 1 ? 0 : (root.active ? 0.7 : 0.35)
        radius: Rounding.full
        color: Theme.colors.primary

        Behavior on opacity {
            Anim {}
        }
    }

    Connections {
        target: root.flickable
        function onContentYChanged() {
            if (!root.flickable)
                return;
            const contentHeight = root.flickable.contentHeight;
            const height = root.flickable.height;
            if (contentHeight > height)
                root.position = Math.max(0, Math.min(1 - root.size, root.flickable.contentY / (contentHeight - height)));
        }
    }
}

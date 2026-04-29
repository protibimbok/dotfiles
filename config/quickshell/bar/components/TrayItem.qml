import QtQuick

Item {
    id: root

    property var item: null

    implicitWidth: 20
    implicitHeight: 20

    Image {
        anchors.centerIn: parent
        width: 16
        height: 16
        source: root.item && root.item.icon ? root.item.icon : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: ev => {
            if (!root.item) return;
            if (ev.button === Qt.RightButton && root.item.hasMenu) root.item.display(root, 0, root.height);
            else if (root.item.activate) root.item.activate();
        }
    }
}

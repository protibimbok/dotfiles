import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.services
import qs.components

Item {
    id: root
    signal close()

    required property var shellRoot

    focus: visible

    onVisibleChanged: if (visible) Qt.callLater(Audio.refresh)

    Item {
        id: panel
        width: Metrics.quickSettingsWidth
        height: Math.min(Metrics.quickSettingsMaxHeight, root.height - Spacing.panelMaxHeightInset)
        anchors.right: parent.right
        anchors.rightMargin: Spacing.panelSideMargin
        anchors.top: parent.top
        anchors.topMargin: Spacing.panelTopMargin

        HoverHandler {
            onHoveredChanged: shellRoot.qsPanelHovered = hovered
        }

        PanelChrome {
            anchors.fill: parent

            Item {
                anchors.fill: parent
                anchors.margins: Spacing.panelContentMargin
                visible: shellRoot.qsSubview === "main"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Spacing.xl

                    QSHeader {}

                    PanelDivider {}

                    QSConnectivity {
                        shellRoot: root.shellRoot
                    }

                    QSEthernetDndRow {}

                    PanelDivider {}

                    QSVolume {}

                    Item { Layout.fillHeight: true }

                    QSFooter {
                        shellRoot: root.shellRoot
                        onRequestClose: root.close()
                    }
                }
            }

            QSWifiPanel {
                anchors.fill: parent
                anchors.margins: Spacing.panelContentMargin
                visible: shellRoot.qsSubview === "wifi"
                shellRoot: root.shellRoot
            }

            QSBluetoothPanel {
                anchors.fill: parent
                anchors.margins: Spacing.panelContentMargin
                visible: shellRoot.qsSubview === "bluetooth"
                shellRoot: root.shellRoot
            }
        }
    }

    Keys.onEscapePressed: {
        if (shellRoot.qsSubview !== "main")
            shellRoot.qsSubview = "main";
        else
            root.close();
    }
}

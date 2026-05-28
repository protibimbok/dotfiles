import QtQuick
import QtQuick.Layouts
import qs.launcher.services
import qs.theme
import qs.tokens

Item {
    id: root

    required property real maxHeight
    required property var requestClose
    required property real availableWidth

    readonly property int padding: Spacing.panelContentMarginLg

    implicitWidth: LauncherMetrics.itemWidth + padding * 2
    implicitHeight: list.implicitHeight + searchBar.height + padding * 2 + Spacing.xl

    // Plain background — no PanelChrome layer (breaks ListView text rendering)
    Rectangle {
        anchors.fill: parent
        radius: Metrics.panelRadius
        color: Theme.colors.background
        opacity: 0.94
        border.color: Theme.colors.outline
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: padding
        spacing: Spacing.xl

        LauncherContentList {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            maxHeight: root.maxHeight - searchBar.implicitHeight - padding * 2 - Spacing.xl
            search: searchInput
            requestClose: root.requestClose
            availableWidth: root.availableWidth
        }

        Rectangle {
            id: searchBar
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: Metrics.tileRadius
            color: Theme.colors.surface
            border.color: searchInput.activeFocus ? Theme.primaryTint(0.5) : Theme.colors.outline
            border.width: searchInput.activeFocus ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: Durations.hoverMedium } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: Spacing.tileInnerTop

                Text {
                    text: "\uf002"
                    color: Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.header
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.colors.foreground
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.header
                    clip: true
                    selectByMouse: true
                    selectionColor: Theme.primaryTint(0.3)

                    Text {
                        anchors.fill: parent
                        text: `Search  ·  type "${LauncherMetrics.actionPrefix}" for commands`
                        visible: !searchInput.text && !searchInput.activeFocus
                        color: Theme.colors.foregroundMuted
                        font: searchInput.font
                    }

                    onAccepted: {
                        if (list.showWallpapers) {
                            const wItem = list.currentList?.currentItem;
                            const path = wItem?.modelData?.path;
                            if (path)
                                LauncherWallpapers.setWallpaper(path);
                            root.requestClose();
                            return;
                        }
                        const currentItem = list.currentList?.currentItem;
                        const data = currentItem?.modelData;
                        if (!data)
                            return;
                        if (text.startsWith(LauncherMetrics.actionPrefix)) {
                            LauncherActions.runAction(data, searchInput, root.requestClose);
                        } else {
                            LauncherApps.launch(data);
                            root.requestClose();
                        }
                    }

                    Keys.onUpPressed: list.currentList?.decrementCurrentIndex?.()
                    Keys.onDownPressed: list.currentList?.incrementCurrentIndex?.()
                    Keys.onLeftPressed: {
                        if (list.showWallpapers)
                            list.currentList?.decrementCurrentIndex?.();
                    }
                    Keys.onRightPressed: {
                        if (list.showWallpapers)
                            list.currentList?.incrementCurrentIndex?.();
                    }
                    Keys.onEscapePressed: root.requestClose()

                    onTextChanged: {
                        if (!text.startsWith(`${LauncherMetrics.actionPrefix}wallpaper `))
                            LauncherWallpapers.stopPreview();
                    }
                }

                Text {
                    text: list.currentList ? list.currentList.count + " items" : ""
                    color: Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }
        }
    }

    function clearSearch() {
        searchInput.text = "";
        LauncherWallpapers.endSession();
    }

    function focusSearch() {
        searchInput.forceActiveFocus();
    }

    function refreshList() {
        list.refreshList();
    }
}

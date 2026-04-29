import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell.Io
import qs.theme

Item {
    id: root
    signal close()

    // Qt may return a file:// URL from StandardPaths; find(1) needs a real path.
    function _normalizeLocalPath(p) {
        if (!p || p.length === 0)
            return p;
        let s = String(p).replace(/\\/g, "/").trim();
        if (!s.startsWith("file://"))
            return s;
        s = s.substring("file://".length);
        if (s.startsWith("localhost/"))
            s = "/" + s.substring("localhost/".length);
        else if (!s.startsWith("/") && !/^[A-Za-z]:/.test(s))
            s = "/" + s;
        return s;
    }

    property string wallpaperDir: _normalizeLocalPath(StandardPaths.writableLocation(StandardPaths.HomeLocation)) + "/Pictures/Wallpapers"
    property string selectedWall: Theme.currentWallpaper

    ListModel { id: wallpaperModel }

    Component.onCompleted: _scan()
    onVisibleChanged: if (visible) _scan()

    function _scan() {
        wallpaperModel.clear();
        scanProc.running = true;
    }

    // Image.source needs a proper file: URL; encode segments so spaces/special chars load.
    function _fileUrl(path) {
        if (!path || path.length === 0)
            return "";
        const norm = _normalizeLocalPath(path).replace(/\\/g, "/");
        const enc = norm.split("/").map(s => encodeURIComponent(s)).join("/");
        return "file://" + enc;
    }

    // Direct argv to /usr/bin/find (no shell); minimal Process env breaks bash pipelines.
    Process {
        id: scanProc
        command: [
            "/usr/bin/find",
            root.wallpaperDir,
            "-maxdepth", "2",
            "-type", "f",
            "(",
            "-iname", "*.jpg",
            "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.png",
            "-o", "-iname", "*.webp",
            "-o", "-iname", "*.gif",
            ")"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear();
                let lines = text.split("\n").filter(l => l.trim().length > 0);
                lines.sort();
                for (let p of lines)
                    wallpaperModel.append({ path: p });
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.15
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: panel
        width: Math.min(840, root.width - 40)
        height: Math.min(540, root.height - 64)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 54

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: "#30000000"
            shadowVerticalOffset: 6
        }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Theme.colors.bg
            opacity: 0.90
        }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "transparent"
            border.color: Theme.colors.border
            border.width: 1
            opacity: 0.25
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "\uf03e  Wallpapers"
                    color: Theme.colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Browse"
                    color: browseHover.hovered ? Theme.colors.accent : Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 150 } }
                    HoverHandler { id: browseHover }
                    TapHandler {
                        onTapped: browseProc.running = true
                    }
                }

                Text {
                    text: "\uf00d"
                    color: wpCloseHover.hovered ? Theme.colors.text : Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    Behavior on color { ColorAnimation { duration: 150 } }
                    HoverHandler { id: wpCloseHover }
                    TapHandler { onTapped: root.close() }
                }
            }

            Process {
                id: browseProc
                command: ["dolphin", "--file-selection", "--directory", "--title=Select wallpaper folder"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let dir = root._normalizeLocalPath(text.trim());
                        if (dir.length > 0) {
                            root.wallpaperDir = dir;
                            root._scan();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                radius: 14
                color: Qt.rgba(Theme.colors.bg1.r, Theme.colors.bg1.g, Theme.colors.bg1.b, 0.4)
                visible: selectedWall !== ""

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 62
                        radius: 10
                        clip: true
                        color: Theme.colors.bg2

                        Image {
                            anchors.fill: parent
                            source: selectedWall ? root._fileUrl(selectedWall) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: selectedWall.split("/").pop() || ""
                            color: Theme.colors.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            elide: Text.ElideLeft
                        }

                        RowLayout {
                            spacing: 4
                            Repeater {
                                model: [
                                    Theme.colors.accent,
                                    Theme.colors.accentAlt,
                                    Theme.colors.green,
                                    Theme.colors.yellow,
                                    Theme.colors.red,
                                    Theme.colors.cyan
                                ]

                                Rectangle {
                                    required property var modelData
                                    width: 12; height: 12; radius: 6
                                    color: modelData
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: reextractText.implicitWidth + 16
                            Layout.preferredHeight: 26
                            radius: 8
                            color: reextractHover.hovered ? Theme.colors.bg2 : Theme.colors.bg1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: reextractText
                                anchors.centerIn: parent
                                text: "Re-extract"
                                color: Theme.colors.textMuted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            HoverHandler { id: reextractHover }
                            TapHandler { onTapped: Theme.applyWallpaper(selectedWall) }
                        }
                    }
                }
            }

            // GridView is a Flickable; wrapping it in ScrollView nests Flickables and breaks layout/sizing.
            GridView {
                id: wallGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                cellWidth: width > 0 ? width / 4 : 100
                cellHeight: cellWidth * (9/16) + 8

                model: wallpaperModel

                populate: Transition {
                    NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "scale"; from: 0.95; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                }

                delegate: Item {
                        id: wallDelegate
                        required property string path
                        required property int index
                        width: wallGrid.cellWidth
                        height: wallGrid.cellHeight

                        property bool isSelected: path === root.selectedWall
                        property bool hovered: wallHover.hovered

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 10
                            clip: true
                            color: Theme.colors.bg2
                            border.color: wallDelegate.isSelected ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.5) : "transparent"
                            border.width: wallDelegate.isSelected ? 2 : 0
                            scale: wallDelegate.hovered ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            Image {
                                anchors.fill: parent
                                source: root._fileUrl(wallDelegate.path)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "white"
                                opacity: wallDelegate.hovered ? 0.06 : 0
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            Text {
                                visible: wallDelegate.isSelected
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                text: "\uf00c"
                                color: Theme.colors.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 22; height: 22; radius: 11
                                    color: Theme.colors.bg
                                    opacity: 0.7
                                    z: -1
                                }
                            }
                        }

                        HoverHandler { id: wallHover }
                        TapHandler {
                            onTapped: {
                                root.selectedWall = wallDelegate.path;
                                Theme.applyWallpaper(wallDelegate.path);
                            }
                        }
                    }
                }
            }
        }

    Keys.onEscapePressed: root.close()
}

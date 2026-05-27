import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.theme
import qs.tokens

Item {
    id: root

    required property LockContext context

    readonly property string wallpaperPath: {
        const fromTheme = Theme.currentWallpaper.trim();
        if (fromTheme.length > 0)
            return fromTheme;
        return wallCache.text().trim();
    }

    FileView {
        id: wallCache
        path: Theme._wallpaperCache
        preload: true
    }

    function _fileUrl(path) {
        if (!path || path.length === 0)
            return "";
        let norm = String(path).replace(/\\/g, "/").trim();
        if (!norm.startsWith("file://")) {
            const enc = norm.split("/").map(s => encodeURIComponent(s)).join("/");
            return "file://" + enc;
        }
        return norm;
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: _fileUrl(root.wallpaperPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.background
        visible: wallpaper.status !== Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.62
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.12
        spacing: Spacing.sm

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 1

            Text {
                text: clockHour12()
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: 72
                font.bold: true
                renderType: Text.NativeRendering
            }

            Text {
                text: ":"
                color: Theme.colors.primary
                font.family: Typography.fontFamily
                font.pixelSize: 72
                font.bold: true
                renderType: Text.NativeRendering

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: Durations.barHideDelay; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: Durations.barHideDelay; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: Qt.formatDateTime(clock.date, "mm")
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: 72
                font.bold: true
                renderType: Text.NativeRendering
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
            color: Theme.colors.foregroundMuted
            font.pixelSize: Typography.header
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height * 0.08
        width: unlockCard.width
        height: unlockCard.height
        visible: Window.active

        PanelChrome {
            id: unlockCard
            width: 360
            height: unlockColumn.implicitHeight + Spacing.panel * 2
            radius: Metrics.panelRadiusLarge
            fillOpacity: 0.92

            ColumnLayout {
                id: unlockColumn
                anchors.fill: parent
                anchors.margins: Spacing.panel
                spacing: Spacing.lg

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Spacing.md

                    Text {
                        text: "\uf023"
                        color: Theme.colors.primary
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.display
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Spacing.xs

                        StyledText {
                            text: "Locked"
                            font.pixelSize: Typography.header
                            font.bold: true
                        }

                        StyledText {
                            text: "Enter your password to unlock"
                            color: Theme.colors.foregroundMuted
                            font.pixelSize: Typography.body
                        }
                    }
                }

                StyledTextField {
                    id: passwordBox
                    Layout.fillWidth: true
                    focus: true
                    placeholderText: "Password"
                    enabled: !root.context.unlockInProgress
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhHiddenText
                    padding: Spacing.lg
                    implicitHeight: 44

                    background: StyledRect {
                        radius: Metrics.searchRadius
                        color: Theme.colors.surfaceHigh
                        border.color: passwordBox.activeFocus
                            ? Theme.colors.primary
                            : Theme.colors.outline
                        border.width: 1
                    }

                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.tryUnlock()

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            if (passwordBox.text !== root.context.currentText)
                                passwordBox.text = root.context.currentText;
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.context.showFailure
                    text: "Incorrect password"
                    color: Theme.colors.error
                    font.pixelSize: Typography.bodySm
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function clockHour12() {
        const formatted = Qt.formatDateTime(clock.date, "hh ap");
        const space = formatted.lastIndexOf(" ");
        return space >= 0 ? formatted.slice(0, space) : formatted;
    }
}

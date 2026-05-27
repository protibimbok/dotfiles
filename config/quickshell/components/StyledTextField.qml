import QtQuick
import QtQuick.Controls
import qs.theme
import qs.tokens

TextField {
    id: root

    color: Theme.colors.foreground
    placeholderTextColor: Theme.colors.foregroundMuted
    font.family: Typography.sansFamily
    font.pixelSize: Typography.body
    renderType: TextField.NativeRendering
    cursorVisible: !readOnly

    background: null

    cursorDelegate: StyledRect {
        id: cursor

        property bool disableBlink: false

        implicitWidth: 2
        color: Theme.colors.primary
        radius: Rounding.normal

        Connections {
            target: root
            function onCursorPositionChanged() {
                if (root.activeFocus && root.cursorVisible) {
                    cursor.opacity = 1;
                    cursor.disableBlink = true;
                    enableBlink.restart();
                }
            }
        }

        Timer {
            id: enableBlink
            interval: 100
            onTriggered: cursor.disableBlink = false
        }

        Timer {
            running: root.activeFocus && root.cursorVisible && !cursor.disableBlink
            repeat: true
            triggeredOnStart: true
            interval: 500
            onTriggered: parent.opacity = parent.opacity === 1 ? 0 : 1
        }

        Binding {
            when: !root.activeFocus || !root.cursorVisible
            cursor.opacity: 0
        }

        Behavior on opacity {
            Anim { type: Anim.StandardSmall }
        }
    }

    Behavior on color { CAnim {} }
    Behavior on placeholderTextColor { CAnim {} }
}

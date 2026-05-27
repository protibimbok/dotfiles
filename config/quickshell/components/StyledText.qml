import QtQuick
import qs.theme
import qs.tokens

Text {
    id: root

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Theme.colors.foreground
    font.family: Typography.sansFamily
    font.pixelSize: Typography.normal

    Behavior on color {
        CAnim {}
    }
}

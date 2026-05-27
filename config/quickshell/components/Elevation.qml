import QtQuick
import QtQuick.Effects
import qs.theme
import qs.tokens

RectangularShadow {
    property int level: 1
    property real dp: [0, 1, 3, 6, 8, 12][Math.min(level, 5)]

    color: Qt.rgba(0, 0, 0, 0.35)
    blur: Math.pow(dp * 5, 0.7)
    spread: -dp * 0.3 + Math.pow(dp * 0.1, 2)
    offset.y: dp / 2

    Behavior on dp {
        Anim {}
    }
}

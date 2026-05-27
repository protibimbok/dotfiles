import QtQuick
import qs.theme
import qs.tokens

Text {
    property string icon: "help_outline"
    property color iconColor: Theme.colors.foregroundMuted

    readonly property var _glyphs: ({
        "search": "\uf002",
        "close": "\uf00d",
        "image": "\uf03e",
        "wallpaper_slideshow": "\uf03e",
        "manage_search": "\uf002",
        "help_outline": "\uf059",
        "casino": "\uf522",
        "light_mode": "\uf185",
        "dark_mode": "\uf186",
        "palette": "\uf53f",
        "calculate": "\uf1ec",
        "settings": "\uf013"
    })

    text: _glyphs[icon] ?? "\uf059"
    color: iconColor
    font.family: Typography.fontFamily
    font.pixelSize: Typography.iconMd
    verticalAlignment: Text.AlignVCenter
}

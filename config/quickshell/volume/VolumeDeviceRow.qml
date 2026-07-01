import QtQuick
import qs.theme
import qs.tokens

// One output device: a bold name on top, then an icon + draggable slider +
// percentage. modelData is an Audio.sinks entry; volume/mute are read from and
// written to the live PipeWire node (modelData.node.audio), so each device is
// controlled independently. Clicking the icon toggles that device's mute.
Column {
    id: root

    required property var modelData

    readonly property var audio: modelData.node ? modelData.node.audio : null
    readonly property real fraction: root.audio ? Math.max(0, Math.min(1, root.audio.volume)) : 0
    readonly property bool muted: root.audio ? root.audio.muted : false

    spacing: Spacing.sm

    function setFraction(f: real) {
        if (root.audio)
            root.audio.volume = Math.max(0, Math.min(1, f));
    }

    Text {
        width: parent.width
        // Prefer the short PipeWire nick ("Speaker", "OnePlus Buds Pro 2R") over
        // the verbose device description.
        text: root.modelData.nickname || root.modelData.description
        color: Theme.pillText
        font.family: Typography.fontFamily
        font.pixelSize: Typography.header
        font.bold: true
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Row {
        width: parent.width
        spacing: Spacing.lg

        Text {
            id: glyph
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (root.muted) return "\u{f0581}"; // 󰖁 volume-off
                const d = (root.modelData.description + " " + root.modelData.name).toLowerCase();
                if (/head|bud|airpod|bluetooth|\bbt\b/.test(d)) return "\u{f02cb}"; // 󰋋 headphones
                return "\u{f057e}"; // 󰕾 volume-high (speaker)
            }
            color: root.muted ? Theme.pillTextMuted : Theme.pillAccent
            font.family: Typography.fontFamily
            font.pixelSize: Typography.iconMd

            TapHandler {
                onTapped: { if (root.audio) root.audio.muted = !root.audio.muted; }
            }
        }

        // Slider: track + accent fill + draggable thumb, bound to this device.
        Item {
            id: slider
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - glyph.width - percent.width - parent.spacing * 2
            height: Metrics.thumbSize

            function setFromX(px: real) {
                root.setFraction(px / slider.width);
            }

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Metrics.trackHeight
                radius: Metrics.trackRadius
                color: Theme.pillTrack

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: thumb.x + thumb.width / 2
                    color: root.muted ? Theme.pillTextMuted : Theme.pillAccent
                }
            }

            Rectangle {
                id: thumb
                width: Metrics.thumbSize
                height: width
                radius: width / 2
                y: (parent.height - height) / 2
                x: root.fraction * (slider.width - width)
                color: root.muted ? Theme.pillTextMuted : Theme.pillAccent
            }

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => slider.setFromX(mouse.x)
                onPositionChanged: mouse => { if (pressed) slider.setFromX(mouse.x); }
            }
        }

        Text {
            id: percent
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.fraction * 100) + "%"
            color: Theme.pillTextMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
            horizontalAlignment: Text.AlignRight
            width: percentMetrics.width

            TextMetrics {
                id: percentMetrics
                font: percent.font
                text: "100%"
            }
        }
    }
}

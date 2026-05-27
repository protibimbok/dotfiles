pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property var durations: QtObject {
        readonly property int small: 200
        readonly property int normal: 400
        readonly property int large: 600
        readonly property int extraLarge: 1000
        readonly property int expressiveFastSpatial: 350
        readonly property int expressiveDefaultSpatial: 500
        readonly property int expressiveSlowSpatial: 650
        readonly property int expressiveFastEffects: 150
        readonly property int expressiveDefaultEffects: 200
        readonly property int expressiveSlowEffects: 300
    }

    readonly property var emphasized: [0.05, 0, 2.0 / 15.0, 0.06, 1.0 / 6.0, 0.4, 5.0 / 24.0, 0.82, 0.25, 1, 1, 1]
    readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
    readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
}

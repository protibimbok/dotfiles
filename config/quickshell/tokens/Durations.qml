pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property int barSlide: 280
    readonly property int barHideDelay: 800
    readonly property int panelHoverHide: 90
    readonly property int colorTransition: 180
    readonly property int colorTransitionSlow: 220
    readonly property int panelEnter: 220
    readonly property int hoverFast: 120
    readonly property int hoverMedium: 150
    readonly property int hoverSlow: 160
    readonly property int press: 110
    readonly property int fade: 200
    readonly property int fadeSlow: 300
    readonly property int spin: 900
    readonly property int toastDismiss: 2000
    readonly property int toastLife: 3000
    readonly property int osdHide: 1500
    readonly property int readyDelay: 3000
}

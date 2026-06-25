pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Bar — layer height matches pill + vertical inset
    readonly property int barPillHeight: 36
    readonly property int barLayoutHeight: barPillHeight + Spacing.barTopInset + Spacing.barBottomInset
    readonly property int barPillRadius: 20
    readonly property int barHideOffset: -barHeight
    readonly property int barMediaHeight: 22
    readonly property int barMediaMinWidth: 88
    readonly property int barWidgetHeight: 28
    readonly property int barSeparatorHeight: 12

    // Panel dimensions
    readonly property int panelRadius: 20
    readonly property int panelRadiusLarge: 32
    readonly property int tileRadius: 14
    readonly property int rowRadius: 8
    readonly property int rowRadiusSm: 6
    readonly property int listRadius: 12
    readonly property int sessionTileRadius: 16
    readonly property int toastRadius: 12
    readonly property int searchRadius: 14
    readonly property int appItemRadius: 12

    readonly property int quickSettingsWidth: 380
    readonly property int quickSettingsMaxHeight: 400
    readonly property int notificationPanelWidth: 600
    readonly property int notificationPanelMaxHeight: 480
    readonly property int sessionPanelWidth: 380
    readonly property int sessionPanelHeight: 200
    readonly property int osdWidth: 280
    readonly property int osdHeight: 64
    readonly property int toastColumnWidth: 340
    readonly property int osdWindowHeight: 180
    readonly property int toastWindowHeight: 400

    readonly property int launcherMaxWidth: 640
    readonly property int launcherMinWidth: 400
    readonly property int launcherWidthInset: 96
    readonly property int launcherHeight: 480

    // Icon sizes
    readonly property int iconSys: 20
    readonly property int iconApp: 16
    readonly property int iconBarStatus: 15
    readonly property int iconPanel: 16
    readonly property int iconFooter: 28
    readonly property int iconTile: 18
    readonly property int iconVolume: 16
    readonly property int iconSession: 28
    readonly property int iconLauncher: 40
    readonly property int iconSlider: 24
    readonly property int iconHeaderBtn: 32
    readonly property int iconBackBtn: 36
    readonly property int iconPerfBtn: 30
    readonly property int iconMuteBtn: 28
    readonly property int iconNotif: 20
    readonly property int iconNotifBadge: 7
    readonly property int iconOsd: 18

    // Row / tile heights
    readonly property int tileHeight: 64
    readonly property int ethernetRowHeight: 44
    readonly property int footerBtnHeight: 40
    readonly property int volumeRowHeight: 36
    readonly property int listRowHeight: 36
    readonly property int sliderRowHeight: 32
    readonly property int perfSegmentHeight: 32
    readonly property int workspacePillHeight: 36
    readonly property int workspaceDotHeight: 24
    readonly property int calendarDaySize: 26
    readonly property int langIndicatorHeight: 16
    readonly property int toggleHeight: 28
    readonly property int toggleWidth: 48
    readonly property int footerActionSize: 44
    readonly property int toastHeight: 56
    readonly property int clockImplicitWidth: 160
    readonly property int clockImplicitHeight: 24
    readonly property int notifBadgeExtraWidth: 28

    // Track / slider
    readonly property int trackHeight: 5
    readonly property int trackRadius: 3
    readonly property int thumbSize: 16
    readonly property int thumbRadius: 8

    // Misc
    readonly property int dividerWidth: 1
    readonly property int barElevation: 3
    readonly property int barElevationCenter: 4
    readonly property int mediaTitleMaxWidth: 140
    readonly property int workspaceDotSize: 14
    readonly property int workspaceMiniDot: 3
    readonly property int osdBottomMargin: 80
    readonly property real barUnifiedFillOpacity: 0.96
    readonly property real barStripFillOpacity: 0.9
    // Bar surface SDF shader (strip + pills smooth-unioned)
    readonly property real barSurfaceSmoothing: 9
    readonly property real barSurfaceEdgeSoftness: 1.5
    readonly property int barHeight: barLayoutHeight
    readonly property real panelFillOpacityDefault: 0.92
    readonly property real panelFillOpacityNotif: 0.88
    readonly property real panelBorderOpacity: 0.25
    readonly property real dividerOpacity: 0.2
    readonly property real panelShadowOpacity: 0.19
}

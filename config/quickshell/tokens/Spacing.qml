pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property int xs: 4
    readonly property int sm: 6
    readonly property int md: 8
    readonly property int lg: 12
    readonly property int xl: 14
    readonly property int xxl: 16
    readonly property int section: 18
    readonly property int panel: 20

    readonly property int panelTopMargin: 54
    readonly property int panelSideMargin: 10
    readonly property int panelContentMargin: 18
    readonly property int panelContentMarginLg: 20
    readonly property int panelMaxHeightInset: 64

    readonly property int barHorizontal: 11
    readonly property int barTop: 1
    readonly property int barVerticalInset: 2
    readonly property int pillPadding: 9
    readonly property int pillGap: 8
    readonly property int pillGapSm: 6

    readonly property int tilePadding: 14
    readonly property int tileInnerTop: 10
    readonly property int tileInnerBottom: 10
    readonly property int listItemPadding: 8
    readonly property int searchPadding: 14
    readonly property int rowGap: 2
    readonly property int sectionBottom: 10
    readonly property int sectionBottomSm: 4
    readonly property int footerGap: 24
    readonly property int toggleKnobInset: 5

    readonly property int small: 7
    readonly property int smaller: 10
    readonly property int normal: 12
    readonly property int larger: 15
    readonly property int large: 20
}

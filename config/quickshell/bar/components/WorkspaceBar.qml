import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.theme
import qs.tokens
import qs.services
import qs.utils

Item {
    id: root
    implicitWidth: shell.implicitWidth
    implicitHeight: parent ? parent.height : Metrics.tileHeight

    function appsForWorkspace(wsId) {
        let toplevels = Hyprland.toplevels.values
        if (!toplevels) {
            return []
        }
        const byKey = {}
        for (let i = 0; i < toplevels.length; i++) {
            let c = toplevels[i]
            if (!c.workspace || c.workspace.id !== wsId) {
                continue
            }

            if (!Hyprland.isBarToplevel(c))
                continue

            const appId = c.wayland && c.wayland.appId;
            const rawClass = appId
                || (c.lastIpcObject ? c.lastIpcObject["class"] : "")
                || c["class"]
                || c.initialClass
                || "";
            const key = String(rawClass).trim();

            if (!byKey[key]) {
                byKey[key] = []
            }

            byKey[key].push({
                "lastIpcObject": c.lastIpcObject,
                "title": c.title || key || "Window",
                "address": c.address || "",
                "active": Hyprland.activeToplevel
                    ? Hyprland.activeToplevel.address === c.address
                    : false
            })
        }
        const out = []
        for (let k in byKey) {
            if (!Object.prototype.hasOwnProperty.call(byKey, k))
                continue
            const inst = byKey[k]
            const cn = (inst[0].lastIpcObject && inst[0].lastIpcObject.class) || ""
            out.push({
                "className": cn,
                "classKey": k,
                "instances": inst
            })
        }
        out.sort(function (a, b) {
            const c0 = a.className.localeCompare(b.className)
            if (c0 !== 0) return c0
            return a.classKey.localeCompare(b.classKey)
        })
        
        return out
    }

    function visibleWorkspaces() {
        const wss = Hyprland.workspaces.values
        if (!wss) {
            return []
        }
            
        const ids = []
        for (let i = 0; i < wss.length; i++) {
            ids.push(wss[i].id)
        }
        if (Hyprland.focusedWorkspace) {
            const fid = Hyprland.focusedWorkspace.id
            if (ids.indexOf(fid) === -1) {
                ids.push(fid)
            }
        }
        ids.sort((a, b) => a - b)
        return ids
    }

    function groupIsActive(grp) {
        if (!grp || !grp.instances) {
            return false
        }
        for (let i = 0; i < grp.instances.length; i++) {
            if (grp.instances[i].active) {
                return true
            }
        }
        return false
    }

    function pickInstance(grp) {
        if (!grp || !grp.instances || grp.instances.length === 0) {
            return null
        }
        for (let i = 0; i < grp.instances.length; i++) {
            if (grp.instances[i].active) {
                return grp.instances[i]
            }
        }
        return grp.instances[0]
    }

    function toplevelStillPresent(addr) {
        if (!addr || !addr.length)
            return false
        const vals = Hyprland.toplevels.values
        if (!vals)
            return false
        for (let i = 0; i < vals.length; i++) {
            if (vals[i].address === addr)
                return true
        }
        return false
    }

    function singleEmptyWorkspace() {
        const ids = visibleWorkspaces()
        if (ids.length !== 1) {
            return false
        }
        return appsForWorkspace(ids[0]).length === 0
    }

    Item {
        id: shell
        width: row.implicitWidth
        implicitWidth: row.implicitWidth
        height: Metrics.workspacePillHeight
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: row
            z: 1
            anchors.fill: parent
            leftPadding: root.singleEmptyWorkspace() ? Spacing.xs : Spacing.pillGapSm
            rightPadding: root.singleEmptyWorkspace() ? Spacing.xs : Spacing.pillGapSm
            spacing: Spacing.lg

            Repeater {
                id: wsRepeater
                model: {
                    void Hyprland.toplevels
                    void Hyprland.workspaces
                    void Hyprland.focusedWorkspace
                    return root.visibleWorkspaces()
                }

                Item {
                    id: wsSeg
                    required property int index
                    required property var modelData
                    property int wsId: modelData
                    property bool isLast: index === wsRepeater.count - 1
                    property bool active: Hyprland.focusedWorkspace
                        ? Hyprland.focusedWorkspace.id === wsId
                        : false
                    property var appGroups: {
                        void Hyprland.toplevels
                        void Hyprland.activeToplevel
                        return root.appsForWorkspace(wsId)
                    }
                    property bool hasApps: appGroups.length > 0
                    property bool aloneEmpty: wsRepeater.count === 1 && !hasApps

                    width: hasApps
                        ? (wsNumBg.width / 2) + 1 + appIconsRow.width + Spacing.md
                        : (aloneEmpty ? wsNumBg.width : (wsNumBg.width / 2))
                    height: Metrics.workspaceDotHeight
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        z: -1
                        onClicked: Hyprland.dispatch("workspace " + wsSeg.wsId)
                    }

                    // --- 1. Main Workspace Background (apps only) ---
                    Rectangle {
                        id: wsBg
                        visible: false // Hidden so MultiEffect can draw it
                        anchors.fill: parent
                        radius: Metrics.listRadius
                        color: active ? Theme.pillBackgroundHighlight : Theme.pillBackground
                        border.width: active && hasApps ? 1 : 0
                        border.color: Theme.pillAccent

                        Behavior on color { ColorAnimation { duration: Durations.hoverSlow } }
                        Behavior on border.width { NumberAnimation { duration: Durations.hoverSlow } }
                    }

                    MultiEffect {
                        visible: hasApps
                        source: wsBg
                        anchors.fill: wsBg
                        z: 1
                        shadowEnabled: true
                        shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.2)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 2
                    }

                    // --- 2. Workspace Number Background ---
                    Rectangle {
                        id: wsNumBg
                        visible: false // Hidden so MultiEffect can draw it
                        width: Metrics.workspaceDotSize
                        height: Metrics.workspaceDotSize
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: aloneEmpty ? (wsSeg.width - width) / 2 : -(width / 2)
                        
                        color: active ? Theme.pillAccent : Theme.pillBackground

                        border.width: active ? 0 : 1
                        border.color: active ? "transparent" : Theme.pillBorder
                        
                        Behavior on color { ColorAnimation { duration: Durations.hoverSlow } }
                    }

                    MultiEffect {
                        source: wsNumBg
                        anchors.fill: wsNumBg
                        z: 3
                        shadowEnabled: true
                        shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.25)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 2
                    }

                    // --- 3. Workspace Number Text ---
                    // Separated from the background so it sits clearly on top of the shadow effects
                    Text {
                        z: 4
                        anchors.centerIn: wsNumBg
                        text: wsSeg.wsId
                        color: active
                            ? Theme.pillBackground
                            : Theme.pillTextMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.body
                        font.bold: active
                        Behavior on color { ColorAnimation { duration: Durations.fade } }
                    }

                    // --- 4. Application Icons ---
                    Row {
                        id: appIconsRow
                        visible: hasApps
                        z: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: (wsNumBg.width / 2) + 1
                        spacing: Spacing.xs

                        Repeater {
                            id: appRepeater
                            model: wsSeg.appGroups

                            Item {
                                id: ag
                                required property var modelData
                                property var g: ag.modelData
                                width: Metrics.iconApp
                                height: Metrics.iconApp
                                property bool gActive: root.groupIsActive(g)
                                property int ninst: (g && g.instances) ? g.instances.length : 0
                                property string iconClass: {
                                    if (!g) {
                                        return ""
                                    }
                                    const i0 = g.instances && g.instances[0]
                                    const ipc = i0 && i0.lastIpcObject ? (i0.lastIpcObject.class || "") : ""
                                    return (ipc || g.className || g.classKey || "").trim()
                                }

                                TapHandler {
                                    onTapped: {
                                        const t = root.pickInstance(g)
                                        Hyprland.dispatch("workspace " + wsSeg.wsId)
                                        if (t && t.address && root.toplevelStillPresent(t.address)) {
                                            Hyprland.dispatch("focuswindow address:" + t.address)
                                        }
                                    }
                                }
                                HoverHandler { id: gHover; cursorShape: Qt.PointingHandCursor }

                                Image {
                                    anchors.fill: parent
                                    source: Icons.forWindowClass(ag.iconClass)
                                    sourceSize: Qt.size(Metrics.iconApp, Metrics.iconApp)
                                    smooth: true
                                    opacity: ag.gActive ? 1.0 : (gHover.hovered ? 0.88 : 0.5)
                                    Behavior on opacity { NumberAnimation { duration: Durations.press } }
                                }
                                Rectangle {
                                    z: 2
                                    visible: ag.ninst > 1
                                    width: Metrics.workspaceMiniDot; height: Metrics.workspaceMiniDot
                                    radius: width * 0.5
                                    color: Theme.pillAccent
                                    anchors {
                                        bottom: parent.top
                                        bottomMargin: -1
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

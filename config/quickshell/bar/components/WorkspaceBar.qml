import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.tokens
import qs.services
import qs.utils

Item {
    id: root
    implicitWidth: shell.implicitWidth
    implicitHeight: parent ? parent.height : Metrics.tileHeight

    // Re-resolve app icons a few times right after startup. DesktopEntries and
    // the icon provider may not be ready on the first binding pass, which would
    // otherwise leave some icons blank until a workspace switch re-evaluates them.
    property int iconTick: 0
    property int _iconResolvePasses: 0
    Timer {
        interval: 1000
        repeat: true
        running: root._iconResolvePasses < 3
        onTriggered: {
            root.iconTick++;
            root._iconResolvePasses++;
        }
    }

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
            // Special workspaces (scratchpad, etc.) have negative ids — never list them.
            if (wss[i].id < 0)
                continue
            ids.push(wss[i].id)
        }
        if (Hyprland.focusedWorkspace) {
            const fid = Hyprland.focusedWorkspace.id
            if (fid >= 0 && ids.indexOf(fid) === -1) {
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
                        visible: hasApps
                        z: 1
                        anchors.fill: parent
                        radius: Metrics.listRadius
                        color: active ? Theme.workspaceAppBgActive : Theme.workspaceAppBg
                        border.width: active && hasApps ? 1 : 0
                        border.color: Theme.workspaceAppBorder

                        Behavior on color { ColorAnimation { duration: Durations.hoverSlow } }
                        Behavior on border.width { NumberAnimation { duration: Durations.hoverSlow } }
                    }

                    // --- 2. Workspace Number Background ---
                    Rectangle {
                        id: wsNumBg
                        z: 3
                        width: Metrics.workspaceDotSize
                        height: Metrics.workspaceDotSize
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: aloneEmpty ? (wsSeg.width - width) / 2 : -(width / 2)

                        color: active ? Theme.workspaceDotBgActive : Theme.workspaceDotBg
                        border.width: active ? 0 : 1
                        border.color: active ? "transparent" : Theme.workspaceDotBorder

                        Behavior on color { ColorAnimation { duration: Durations.hoverSlow } }
                    }

                    // --- 3. Workspace Number Text ---
                    Text {
                        z: 4
                        anchors.centerIn: wsNumBg
                        text: wsSeg.wsId
                        color: active ? Theme.workspaceTextActive : Theme.workspaceText
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.body
                        font.bold: active
                        Behavior on color { ColorAnimation { duration: Durations.fade } }
                    }

                    // Click target for the number itself — the circle protrudes
                    // left of the segment, so the segment-wide MouseArea above
                    // doesn't cover all of it.
                    MouseArea {
                        z: 5
                        anchors.verticalCenter: parent.verticalCenter
                        x: wsNumBg.x
                        width: wsNumBg.width
                        height: wsNumBg.height
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: Hyprland.dispatch("workspace " + wsSeg.wsId)
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
                                    id: agIcon
                                    anchors.fill: parent
                                    source: {
                                        void root.iconTick;   // re-resolve after startup
                                        return Icons.forWindowClass(ag.iconClass);
                                    }
                                    sourceSize: Qt.size(Metrics.iconApp, Metrics.iconApp)
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    opacity: ag.gActive ? 1.0 : (gHover.hovered ? 0.88 : 0.5)
                                    Behavior on opacity { NumberAnimation { duration: Durations.press } }
                                }

                                // Drawn placeholder tile, shown only when no icon resolves
                                // (empty source or failed load). Never gates the icon itself,
                                // so the Image always paints once the async load completes.
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    visible: agIcon.status === Image.Null || agIcon.status === Image.Error
                                    radius: Metrics.rowRadiusSm
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: Theme.workspaceText
                                    opacity: ag.gActive ? 0.9 : (gHover.hovered ? 0.8 : 0.45)
                                }
                                Rectangle {
                                    z: 2
                                    visible: ag.ninst > 1
                                    width: Metrics.workspaceMiniDot; height: Metrics.workspaceMiniDot
                                    radius: width * 0.5
                                    color: Theme.workspaceBadge
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

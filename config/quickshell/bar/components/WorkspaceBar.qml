import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.utils

Item {
    id: root
    implicitWidth: shell.implicitWidth
    implicitHeight: parent ? parent.height : 44

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

            const appId = c.wayland && c.wayland.appId;
            
            const rawClass = appId
                || (c.lastIpcObject ? c.lastIpcObject["class"] : "") 
                || c["class"] 
                || c.initialClass 
                || "";

            const key = String(rawClass).trim();

            if (["", "org.quickshell"].includes(key)) {
                continue;
            }

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

    Item {
        id: shell
        width: row.implicitWidth
        implicitWidth: row.implicitWidth
        height: 36
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: row
            z: 1
            anchors.fill: parent
            leftPadding: 8
            rightPadding: 8
            spacing: 14

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

                    width: appIconsRow.width > 0 ? appIconsRow.width + 16 : 22
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        z: -1
                        onClicked: Hyprland.dispatch("workspace " + wsSeg.wsId)
                    }

                    // --- 1. Main Workspace Background ---
                    Rectangle {
                        id: wsBg
                        visible: false // Hidden so MultiEffect can draw it
                        anchors.fill: parent
                        radius: 12
                        color: Qt.rgba(Theme.colors.surface.r, Theme.colors.surface.g, Theme.colors.surface.b, 1.0)
                        border.width: active ? 1 : 0
                        border.color: Theme.colors.accent
                        
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on border.width { NumberAnimation { duration: 160 } }
                    }

                    MultiEffect {
                        source: wsBg
                        anchors.fill: wsBg
                        z: 1
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.2)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 2
                    }

                    // --- 2. Workspace Number Background ---
                    Rectangle {
                        id: wsNumBg
                        visible: false // Hidden so MultiEffect can draw it
                        width: 16
                        height: 16
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: -(width / 2) 
                        
                        color: active ? Theme.colors.accent : Qt.rgba(Theme.colors.surface.r, Theme.colors.surface.g, Theme.colors.surface.b, 1.0)
                        
                        border.width: active ? 0 : 1
                        border.color: active ? "transparent" : Qt.rgba(Theme.colors.border.r, Theme.colors.border.g, Theme.colors.border.b, 0.4)
                        
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    MultiEffect {
                        source: wsNumBg
                        anchors.fill: wsNumBg
                        z: 3
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.25)
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
                            ? Theme.colors.surface 
                            : Qt.rgba(Theme.colors.textMuted.r, Theme.colors.textMuted.g, Theme.colors.textMuted.b, 0.9)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: active
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // --- 4. Application Icons ---
                    Row {
                        id: appIconsRow
                        z: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: (wsNumBg.width / 2) + 1 
                        spacing: 4

                        Repeater {
                            id: appRepeater
                            model: wsSeg.appGroups

                            Item {
                                id: ag
                                required property var modelData
                                property var g: ag.modelData
                                width: 16
                                height: 16
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
                                    sourceSize: Qt.size(16, 16)
                                    smooth: true
                                    opacity: ag.gActive ? 1.0 : (gHover.hovered ? 0.88 : 0.5)
                                    Behavior on opacity { NumberAnimation { duration: 130 } }
                                }
                                Rectangle {
                                    z: 2
                                    visible: ag.ninst > 1
                                    width: 3; height: 3
                                    radius: width * 0.5
                                    color: Theme.colors.accent
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

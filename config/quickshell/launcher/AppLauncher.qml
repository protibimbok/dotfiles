import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import qs.theme

Item {
    id: root
    signal close()

    property string query: ""
    property int selectedIndex: 0
    property var hiddenApps: []
    property var customCommands: []
    property var allApps: []
    property var filteredApps: []

    FileView {
        id: hiddenFile
        path: Quickshell.shellPath("launcher/launcher_hidden.json")
        preload: true
        watchChanges: true
        onFileChanged: {
            try { root.hiddenApps = JSON.parse(text()); } catch(e) { root.hiddenApps = []; }
            root._rebuildApps();
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root._rebuildApps(); }
    }

    FileView {
        id: commandsFile
        path: Quickshell.shellPath("launcher/launcher_commands.json")
        preload: true
        watchChanges: true
        onFileChanged: {
            try {
                let cmds = JSON.parse(text());
                root.customCommands = cmds.map(c => ({
                    name: c.name || "",
                    exec: c.cmd || "",
                    icon: c.icon || "application-x-executable",
                    comment: c.comment || "",
                    isCmd: true
                }));
            } catch(e) { root.customCommands = []; }
            _rebuildApps();
        }
    }

    Component.onCompleted: _rebuildApps()

    function _rebuildApps() {
        let apps = [];
        let entries = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        let hidden = new Set(hiddenApps);
        for (let i = 0; i < entries.length; i++) {
            let e = entries[i];
            if (e.noDisplay) continue;
            let id = (e.id || e.name || "").replace(/\.desktop$/, "");
            if (hidden.has(id)) continue;
            apps.push({
                name: e.name || id,
                icon: e.icon || "application-x-executable",
                comment: e.comment || "",
                isCmd: false,
                entry: e
            });
        }
        apps = apps.concat(customCommands);
        apps.sort((a, b) => a.name.localeCompare(b.name));
        allApps = apps;
        _filter();
    }

    function _filter() {
        let q = query.toLowerCase().trim();
        if (q.length === 0) {
            filteredApps = allApps.slice(0, 24);
        } else {
            let results = [];
            for (let i = 0; i < allApps.length && results.length < 24; i++) {
                let a = allApps[i];
                let haystack = (a.name + " " + a.comment).toLowerCase();
                if (_fuzzyMatch(haystack, q)) results.push(a);
            }
            filteredApps = results;
        }
        selectedIndex = 0;
    }

    function _fuzzyMatch(haystack: string, needle: string): bool {
        let hi = 0;
        for (let ni = 0; ni < needle.length; ni++) {
            let ch = needle[ni];
            let found = false;
            while (hi < haystack.length) {
                if (haystack[hi] === ch) { hi++; found = true; break; }
                hi++;
            }
            if (!found) return false;
        }
        return true;
    }

    onQueryChanged: _filter()

    function launch(app: var) {
        if (app.isCmd) {
            let cmd = app.exec || "";
            cmd = cmd.replace(/%[fFuUdDnNickvm]/g, "").trim();
            if (cmd.length > 0) {
                launchProc.command = ["/usr/bin/bash", "-c", cmd];
                launchProc.running = true;
            }
        } else if (app.entry) {
            app.entry.execute();
        }
        close();
    }

    Process { id: launchProc }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Theme.colors.bg
        opacity: 0.92
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        Rectangle {
            id: searchBar
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 14
            color: Theme.colors.bg1
            border.color: searchInput.activeFocus ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.5) : Theme.colors.border
            border.width: searchInput.activeFocus ? 2 : 1
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on border.width { NumberAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: "\uf002"
                    color: Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true
                    selectionColor: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.3)

                    Component.onCompleted: forceActiveFocus()

                    onTextChanged: root.query = text

                    Keys.onEscapePressed: root.close()
                    Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                    Keys.onDownPressed: root.selectedIndex = Math.min(root.filteredApps.length - 1, root.selectedIndex + 1)
                    Keys.onReturnPressed: {
                        if (root.filteredApps.length > 0)
                            root.launch(root.filteredApps[root.selectedIndex]);
                    }
                }

                Text {
                    text: root.filteredApps.length + " apps"
                    color: Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: width > 0 ? width / 5 : 80
            cellHeight: 100
            model: root.filteredApps
            currentIndex: root.selectedIndex

            populate: Transition {
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 110; easing.type: Easing.OutCubic }
                NumberAnimation { properties: "y"; from: 6; duration: 110; easing.type: Easing.OutCubic }
            }

                delegate: Item {
                    id: appDelegate
                    required property var modelData
                    required property int index
                    width: grid.cellWidth
                    height: grid.cellHeight

                    property bool isSelected: index === root.selectedIndex
                    property bool hovered: delegateHover.hovered

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 12
                        color: appDelegate.isSelected ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.15) : (appDelegate.hovered ? Qt.rgba(Theme.colors.bg1.r, Theme.colors.bg1.g, Theme.colors.bg1.b, 0.5) : "transparent")
                        border.color: appDelegate.isSelected ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.3) : "transparent"
                        border.width: appDelegate.isSelected ? 1 : 0
                        Behavior on color { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Image {
                            Layout.alignment: Qt.AlignHCenter
                            width: 40; height: 40
                            source: Quickshell.iconPath(appDelegate.modelData.icon, "application-x-executable")
                            sourceSize: Qt.size(40, 40)
                            smooth: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: grid.cellWidth - 16
                            text: appDelegate.modelData.name
                            color: Theme.colors.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    HoverHandler {
                        id: delegateHover
                        onHoveredChanged: {
                            if (hovered) root.selectedIndex = appDelegate.index;
                        }
                    }
                    TapHandler {
                        onTapped: root.launch(appDelegate.modelData)
                    }
                }
        }
    }
}

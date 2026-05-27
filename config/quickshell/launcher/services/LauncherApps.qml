pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import qs.tokens

Singleton {
    id: root

    property var hiddenApps: []
    property var customCommands: []
    property var allApps: []

    FileView {
        id: hiddenFile
        path: Quickshell.shellPath("launcher/launcher_hidden.json")
        preload: true
        watchChanges: true
        onFileChanged: {
            try { root.hiddenApps = JSON.parse(text()); } catch (e) { root.hiddenApps = []; }
            root._rebuild();
        }
    }

    FileView {
        id: commandsFile
        path: Quickshell.shellPath("launcher/launcher_commands.json")
        preload: true
        watchChanges: true
        onFileChanged: root._loadCommands()
        onLoaded: root._loadCommands()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root._rebuild(); }
    }

    Component.onCompleted: _rebuild()

    function _loadCommands() {
        try {
            const cmds = JSON.parse(commandsFile.text());
            root.customCommands = cmds.map(c => ({
                name: c.name || "",
                exec: c.cmd || "",
                icon: c.icon || "application-x-executable",
                comment: c.comment || "",
                isCmd: true
            }));
        } catch (e) {
            root.customCommands = [];
        }
        _rebuild();
    }

    function _rebuild() {
        let apps = [];
        const entries = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const hidden = new Set(hiddenApps);
        for (let i = 0; i < entries.length; i++) {
            const e = entries[i];
            if (e.noDisplay)
                continue;
            const id = (e.id || e.name || "").replace(/\.desktop$/, "");
            if (hidden.has(id))
                continue;
            apps.push({
                name: e.name || id,
                icon: e.icon || "application-x-executable",
                comment: e.comment || e.genericName || "",
                isCmd: false,
                entry: e
            });
        }
        apps = apps.concat(customCommands || []);
        apps.sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")));
        allApps = apps;
    }

    function search(text: string): var {
        return Searcher.query(allApps, text, {
            key: "name",
            keys: ["name", "comment"],
            weights: [1, 0.3],
            selector: item => ((item.name || "") + " " + (item.comment || "")).trim()
        });
    }

    function launch(app: var): void {
        if (!app)
            return;
        if (app.isCmd) {
            let cmd = (app.exec || "").replace(/%[fFuUdDnNickvm]/g, "").trim();
            if (cmd.length > 0)
                Quickshell.execDetached(["/usr/bin/bash", "-c", cmd]);
        } else if (app.entry) {
            app.entry.execute();
        }
    }
}

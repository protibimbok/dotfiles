pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.utils
import qs.tokens
import qs.launcher.services

Singleton {
    id: root

    property var actions: []

    FileView {
        id: actionsFile
        path: Quickshell.shellPath("launcher/launcher_actions.json")
        preload: true
        watchChanges: true
        onFileChanged: root._load()
        onLoaded: root._load()
    }

    function _load() {
        try {
            actions = JSON.parse(actionsFile.text()).filter(a => a.enabled !== false);
        } catch (e) {
            actions = [];
        }
    }

    function transformSearch(search: string): string {
        return search.slice(LauncherMetrics.actionPrefix.length);
    }

    function query(search: string): var {
        if (!search.startsWith(LauncherMetrics.actionPrefix))
            return [];
        return Searcher.query(actions, search, {
            key: "name",
            keys: ["name", "description"],
            weights: [0.9, 0.1],
            transformSearch: transformSearch
        });
    }

    function runAction(action: var, searchField: var, onClose: var): void {
        const cmd = action.command ?? [];
        if (cmd.length === 0)
            return;

        if (cmd[0] === "autocomplete" && cmd.length > 1) {
            searchField.text = `${LauncherMetrics.actionPrefix}${cmd[1]} `;
            return;
        }

        if (cmd[0] === "setMode" && cmd.length > 1) {
            onClose();
            Theme.setWalMode(cmd[1]);
            return;
        }

        if (cmd[0] === "randomWallpaper") {
            onClose();
            LauncherWallpapers.applyRandom();
            return;
        }

        onClose();
        Quickshell.execDetached(cmd);
    }
}

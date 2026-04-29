pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ethernetProc.running = true
    }

    // NetMgr-style: only TYPE and STATE — lines are "ethernet:connected" (two fields; old parser wrongly required >= 3 parts)
    Process {
        id: ethernetProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE", "dev"]
        stdout: StdioCollector {
            onStreamFinished: root._parseEthernet(text)
        }
        onExited: (code) => {
            if (code !== 0)
                root.connected = false;
        }
    }

    function _parseEthernet(data: string) {
        let eth = false;
        for (let line of data.trim().split("\n")) {
            line = line.trim();
            if (!line.length)
                continue;
            let idx = line.indexOf(":");
            if (idx < 0)
                continue;
            let type = line.slice(0, idx).toLowerCase();
            let state = line.slice(idx + 1).toLowerCase();
            if (type === "ethernet" || type === "bridge") {
                if (state === "connected" || state.indexOf("connected") >= 0)
                    eth = true;
            }
        }
        connected = eth;
    }

    function openSettings() {
        ethSettingsLaunchProc.command = ["bash", "-c",
            "(command -v nm-connection-editor >/dev/null && exec nm-connection-editor) || " +
            "(command -v gnome-control-center >/dev/null && exec gnome-control-center network) || " +
            "(command -v nmtui >/dev/null && (command -v kitty >/dev/null && exec kitty -e nmtui || command -v foot >/dev/null && exec foot nmtui || exec xterm -e nmtui)) || true"];
        ethSettingsLaunchProc.running = true;
    }

    Process { id: ethSettingsLaunchProc }
}

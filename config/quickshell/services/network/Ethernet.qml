pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    /// Wired interface currently connected (from poll).
    property string device: ""
    /// Last disconnected wired interface — used to reconnect on toggle.
    property string _reconnectDevice: ""

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ethernetProc.running = true
    }

    Process {
        id: ethernetProc
        command: ["/usr/bin/nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "dev"]
        stdout: StdioCollector {
            onStreamFinished: root._parseEthernet(text)
        }
        onExited: (code) => {
            if (code !== 0) {
                root.connected = false;
                root.device = "";
            }
        }
    }

    function _wiredStateConnected(state: string): bool {
        state = state.toLowerCase();
        return state === "connected" || state.startsWith("connected ");
    }

    function _parseEthernet(data: string) {
        let eth = false;
        let connectedDev = "";
        let disconnectedDev = "";

        for (let line of data.trim().split("\n")) {
            line = line.trim();
            if (!line.length)
                continue;
            let parts = line.split(":");
            if (parts.length < 3)
                continue;
            let state = parts[parts.length - 1];
            let type = parts[parts.length - 2].toLowerCase();
            let dev = parts.slice(0, -2).join(":");
            if (type !== "ethernet" && type !== "bridge")
                continue;
            if (_wiredStateConnected(state)) {
                eth = true;
                connectedDev = dev;
            } else if (state.toLowerCase() === "disconnected" && !disconnectedDev.length) {
                disconnectedDev = dev;
            }
        }

        connected = eth;
        device = connectedDev;
        if (disconnectedDev.length)
            _reconnectDevice = disconnectedDev;
        else if (connectedDev.length)
            _reconnectDevice = connectedDev;
    }

    function _refreshAfterEthChange() {
        ethernetProc.running = true;
        ethRefreshTimer.restart();
    }

    function toggle() {
        if (connected) {
            if (!device.length)
                return;
            ethActionProc.command = ["/usr/bin/nmcli", "device", "disconnect", device];
        } else {
            let target = _reconnectDevice.length ? _reconnectDevice : device;
            if (!target.length)
                return;
            ethActionProc.command = ["/usr/bin/nmcli", "device", "connect", target];
        }
        ethActionProc.running = true;
    }

    function connect() {
        let target = _reconnectDevice.length ? _reconnectDevice : device;
        if (!target.length)
            return;
        ethActionProc.command = ["/usr/bin/nmcli", "device", "connect", target];
        ethActionProc.running = true;
    }

    function disconnect() {
        if (!device.length)
            return;
        ethActionProc.command = ["/usr/bin/nmcli", "device", "disconnect", device];
        ethActionProc.running = true;
    }

    Timer {
        id: ethRefreshTimer
        interval: 800
        repeat: false
        onTriggered: ethernetProc.running = true
    }

    Process {
        id: ethActionProc
        onExited: root._refreshAfterEthChange()
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

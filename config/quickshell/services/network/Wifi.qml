pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    property string ssid: ""
    /// SSID of the currently associated AP (from `nmcli dev wifi`), for matching list rows.
    property string activeSsid: ""
    property real strength: 0.0
    /// SSIDs that have a saved NetworkManager Wi-Fi profile.
    property var savedSsids: []

    property var networks: []

    /// True while `wifiScanProc` is running (list refresh / rescan).
    property bool scanning: false

    /// Non-empty while a connect/disconnect/scan/forget subprocess is running (user-initiated).
    property string busyMessage: ""
    property int _busyRef: 0
    /// SSID we are currently trying to join (cleared when connect subprocess ends).
    property string connectPendingSsid: ""
    /// Stable list-row id (never empty for a row); avoids matching `"" === ""` for hidden APs.
    property string connectPendingRowKey: ""
    /// Raw `GENERAL.STATE` from `nmcli device show` for the primary Wi-Fi interface (e.g. "100 (connected)").
    property string nmStateLine: ""
    /// True when NM reports an in-progress activation (state code 40–99).
    property bool nmConnecting: false

    /// `canPromptPassword`: false for open-network attempts; UI may offer a password prompt on failure only when true.
    signal connectFinished(string ssid, bool success, bool canPromptPassword, string rowKey)

    function _busyPush(msg: string) {
        _busyRef++;
        busyMessage = msg;
    }

    function _busyPop() {
        _busyRef = Math.max(0, _busyRef - 1);
        if (_busyRef === 0)
            busyMessage = "";
    }

    function _updateNmConnecting() {
        let m = /^\s*(\d+)/.exec(nmStateLine || "");
        let code = m ? parseInt(m[1], 10) : -1;
        nmConnecting = code >= 40 && code <= 99;
    }

    function _refreshAfterWifiChange() {
        nmWifiProc.running = true;
        wifiRadioProc.running = true;
        wifiActiveSsidProc.running = true;
        wifiSavedListProc.running = true;
        wifiNmIfaceStateProc.running = true;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiRadioProc.running = true;
            nmWifiProc.running = true;
            wifiActiveSsidProc.running = true;
            wifiSavedListProc.running = true;
            wifiNmIfaceStateProc.running = true;
        }
    }

    Process {
        id: wifiNmIfaceStateProc
        command: ["bash", "-c",
            "d=$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | awk -F: '$2==\"wifi\"{print $1; exit}'); " +
            "[ -n \"$d\" ] && nmcli -g GENERAL.STATE device show \"$d\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.nmStateLine = text.trim();
                root._updateNmConnecting();
            }
        }
    }

    // Same as NetMgr wifiPoller: direct argv (no shell pipeline); terse lines "yes:SSID" / "no:…"
    Process {
        id: wifiActiveSsidProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeSsid = "";
                for (let line of text.trim().split("\n")) {
                    line = line.trim();
                    if (!line.length)
                        continue;
                    if (line.startsWith("yes:")) {
                        // Everything after "yes:" is the SSID (may contain ':')
                        root.activeSsid = line.slice(4);
                        break;
                    }
                }
                // Authoritative: same source as NetMgr wifiPoller — `dev status` parse breaks on ':' in names
                root.connected = root.activeSsid.length > 0;
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                root.activeSsid = "";
                root.connected = false;
            }
        }
    }

    Process {
        id: wifiSavedListProc
        command: ["bash", "-c",
            "nmcli -t -f UUID,TYPE connection show 2>/dev/null | awk -F: '$2==\"802-11-wireless\"{print $1}' | while read -r u; do " +
            "nmcli -g 802-11-wireless.ssid connection show \"$u\" 2>/dev/null; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n").map(s => s.trim()).filter(s => s.length > 0);
                root.savedSsids = lines;
            }
        }
    }

    Process {
        id: wifiRadioProc
        command: ["nmcli", "-t", "-f", "WIFI", "g"]
        stdout: StdioCollector {
            onStreamFinished: root.enabled = (text.trim() === "enabled")
        }
    }

    Process {
        id: nmWifiProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,SIGNAL", "dev", "status"]
        stdout: StdioCollector {
            onStreamFinished: root._parseNmWifi(text)
        }
    }

    /// TYPE:STATE:CONNECTION:SIGNAL — CONNECTION may contain ':'; SIGNAL is always last field.
    function _parseNmWifi(data: string) {
        let lines = data.trim().split("\n");
        let outSsid = "";
        let signal = 0;
        let found = false;

        for (let line of lines) {
            let parts = line.split(":");
            if (parts.length < 4) continue;
            let type = parts[0].toLowerCase();
            if (type !== "wifi") continue;
            let state = parts[1].toLowerCase();
            let sig = parseInt(parts[parts.length - 1], 10) || 0;
            let conn = parts.slice(2, -1).join(":");
            if (state === "connected" || state.indexOf("connected") >= 0) {
                found = true;
                outSsid = conn;
                signal = sig;
                break;
            }
        }

        if (found) {
            ssid = outSsid;
            strength = Math.min(1.0, signal / 100);
        } else {
            strength = 0;
            // Do not clear ssid here — association label comes from activeSsid when terse parse fails
        }
    }

    function setEnabled(on: bool) {
        wifiToggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        wifiToggleProc.running = true;
    }

    Process {
        id: wifiToggleProc
        onExited: root._refreshAfterWifiChange()
    }

    function scan() {
        _busyPush("Scanning networks…");
        scanning = true;
        wifiScanProc.running = true;
    }

    Process {
        id: wifiScanProc
        command: ["bash", "-c", "nmcli dev wifi rescan 2>/dev/null; sleep 1; nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = typeof text !== "undefined" && text !== null ? String(text) : "";
                root._parseWifiList(raw);
                wifiSavedListProc.running = true;
            }
        }
        onExited: {
            root.scanning = false;
            root._busyPop();
        }
    }

    function _parseWifiList(data: string) {
        const s = typeof data !== "undefined" && data !== null ? String(data) : "";
        let out = [];
        let hiddenSeq = 0;
        for (let line of s.trim().split("\n")) {
            if (!line.length) continue;
            let sigIdx = line.lastIndexOf(":");
            if (sigIdx < 0) continue;
            let sec = line.slice(sigIdx + 1);
            let rest = line.slice(0, sigIdx);
            let sig2 = rest.lastIndexOf(":");
            if (sig2 < 0) continue;
            let sigStr = rest.slice(sig2 + 1);
            let ssidPart = rest.slice(0, sig2);
            let signal = parseInt(sigStr) || 0;
            if (!ssidPart.length && sec.indexOf("--") >= 0) continue;
            let rowKey = ssidPart.length ? ssidPart : ("__hidden_" + (hiddenSeq++));
            out.push({ ssid: ssidPart, rowKey: rowKey, signal: signal, security: sec });
        }
        networks = out;
    }

    function connectOpen(ssidParam: string, rowKey: string) {
        if (!ssidParam.length) return;
        _busyPush("Connecting to " + ssidParam + "…");
        connectPendingSsid = ssidParam;
        connectPendingRowKey = rowKey.length ? rowKey : ssidParam;
        wifiConnectProc._targetSsid = ssidParam;
        wifiConnectProc._targetRowKey = connectPendingRowKey;
        wifiConnectProc.command = ["nmcli", "device", "wifi", "connect", ssidParam];
        wifiConnectProc.running = true;
    }

    function disconnect() {
        _busyPush("Disconnecting…");
        wifiDisconnectProc.running = true;
    }

    Process {
        id: wifiDisconnectProc
        command: ["bash", "-c",
            "d=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':wifi:connected' | head -1 | cut -d: -f1); " +
            "[ -n \"$d\" ] && nmcli device disconnect \"$d\""]
        onExited: {
            root._busyPop();
            root._refreshAfterWifiChange();
        }
    }

    function forget(ssidParam: string) {
        if (!ssidParam.length) return;
        _busyPush("Removing network…");
        let esc = ssidParam.replace(/'/g, "'\\''");
        wifiForgetProc.command = ["bash", "-c",
            "target='" + esc + "'; " +
            "for u in $(nmcli -t -f UUID,TYPE connection show 2>/dev/null | awk -F: '$2==\"802-11-wireless\"{print $1}'); do " +
            "s=$(nmcli -g 802-11-wireless.ssid connection show \"$u\" 2>/dev/null); " +
            "[ \"$s\" = \"$target\" ] && nmcli connection delete \"$u\" && break; done"];
        wifiForgetProc.running = true;
    }

    Process {
        id: wifiForgetProc
        onExited: {
            root._busyPop();
            wifiSavedListProc.running = true;
            nmWifiProc.running = true;
        }
    }

    /// Connect to a secured network: empty password uses saved profile only.
    function tryConnect(ssidParam: string, password: string, rowKey: string) {
        if (!ssidParam.length) return;
        _busyPush("Connecting to " + ssidParam + "…");
        connectPendingSsid = ssidParam;
        connectPendingRowKey = rowKey.length ? rowKey : ssidParam;
        wifiSecureConnectProc._targetSsid = ssidParam;
        wifiSecureConnectProc._targetRowKey = connectPendingRowKey;
        if (password.length > 0)
            wifiSecureConnectProc.command = ["nmcli", "device", "wifi", "connect", ssidParam, "password", password];
        else
            wifiSecureConnectProc.command = ["nmcli", "device", "wifi", "connect", ssidParam];
        wifiSecureConnectProc.running = true;
    }

    Process {
        id: wifiConnectProc
        property string _targetSsid: ""
        property string _targetRowKey: ""
        onExited: function (exitCode) {
            root.connectFinished(_targetSsid, exitCode === 0, false, _targetRowKey);
            root.connectPendingSsid = "";
            root.connectPendingRowKey = "";
            root._busyPop();
            root._refreshAfterWifiChange();
        }
    }

    Process {
        id: wifiSecureConnectProc
        property string _targetSsid: ""
        property string _targetRowKey: ""
        onExited: function (exitCode) {
            root.connectFinished(_targetSsid, exitCode === 0, true, _targetRowKey);
            root.connectPendingSsid = "";
            root.connectPendingRowKey = "";
            root._busyPop();
            root._refreshAfterWifiChange();
        }
    }

    function openSettings() {
        wifiSettingsLaunchProc.command = ["bash", "-c",
            "(command -v nm-connection-editor >/dev/null && exec nm-connection-editor) || " +
            "(command -v gnome-control-center >/dev/null && exec gnome-control-center wifi) || " +
            "(command -v nmtui >/dev/null && (command -v kitty >/dev/null && exec kitty -e nmtui || command -v foot >/dev/null && exec foot nmtui || exec xterm -e nmtui)) || true"];
        wifiSettingsLaunchProc.running = true;
    }

    Process { id: wifiSettingsLaunchProc }
}

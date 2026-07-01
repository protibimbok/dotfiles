pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Read-only Wi-Fi status, backend-agnostic (works with iwd or NetworkManager).
// Sourced from /sys/class/net, /proc/net/wireless and `iw`  no nmcli dependency.
Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    property real strength: 0.0
    property string ssid: ""
    property real frequency: 0.0   // GHz

    /// Saved + currently-available networks, connected/saved first then by signal.
    /// Each entry: { ssid, security, open, strength (0..1), known, connected }.
    property var networks: []
    property bool scanning: false

    /// SSID passed to `connectNetwork` while a connection attempt is in flight.
    property string connectingSsid: ""
    /// SSID passed to `disconnect` while a disconnect attempt is in flight.
    property string disconnectingSsid: ""

    // Shared bash prefix that resolves the first wireless interface into $ifc
    // (exiting 0 if there is none). Reused by every iwctl command below.
    readonly property string _findIface:
        "ifc=''; for w in /sys/class/net/*/wireless; do [ -e \"$w\" ] || continue; " +
        "ifc=$(basename \"$(dirname \"$w\")\"); break; done; [ -z \"$ifc\" ] && exit 0; "

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
    }

    Process {
        id: pollProc
        command: ["bash", "-c",
            "ifc=''\n" +
            "for w in /sys/class/net/*/wireless; do [ -e \"$w\" ] || continue; ifc=$(basename \"$(dirname \"$w\")\"); break; done\n" +
            "if [ -z \"$ifc\" ]; then echo 'iface='; exit 0; fi\n" +
            "echo \"iface=$ifc\"\n" +
            "echo \"state=$(cat /sys/class/net/$ifc/operstate 2>/dev/null)\"\n" +
            "echo \"qual=$(awk -v i=\"$ifc:\" '$1==i{print $3}' /proc/net/wireless 2>/dev/null | tr -d '.')\"\n" +
            "if command -v iw >/dev/null 2>&1; then\n" +
            "  link=$(iw dev \"$ifc\" link 2>/dev/null)\n" +
            "  echo \"ssid=$(printf '%s\\n' \"$link\" | sed -n 's/^[[:space:]]*SSID:[[:space:]]*//p' | head -1)\"\n" +
            "  echo \"freq=$(printf '%s\\n' \"$link\" | sed -n 's/^[[:space:]]*freq:[[:space:]]*//p' | head -1)\"\n" +
            "fi"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function _parse(data: string) {
        let info = ({});
        for (let line of data.trim().split("\n")) {
            let i = line.indexOf("=");
            if (i < 0) continue;
            info[line.slice(0, i)] = line.slice(i + 1).trim();
        }

        let ifc = info["iface"] || "";
        if (!ifc.length) {
            enabled = false;
            connected = false;
            strength = 0;
            ssid = "";
            frequency = 0;
            return;
        }

        let state = (info["state"] || "").toLowerCase();
        enabled = true;
        connected = state === "up";
        let q = parseInt(info["qual"] || "0", 10);
        strength = connected ? Math.max(0, Math.min(1, q / 70)) : 0;
        ssid = info["ssid"] || "";
        let f = parseFloat(info["freq"] || "0");
        frequency = f > 0 ? Math.round(f / 100) / 10 : 0;   // MHz -> GHz, 1 decimal
        root._clearOperationHints();
    }

    // --- network list (scan) + connect, via iwd's iwctl -------------------------

    // Rescan, wait for iwd to settle, then dump known + visible networks in one
    // shot. The raw output (ANSI intact) is parsed in JS: iwd encodes signal
    // strength as lit vs. dimmed asterisks, which stripping the colours would lose.
    Process {
        id: scanProc
        command: ["bash", "-c",
            root._findIface +
            "iwctl station \"$ifc\" scan >/dev/null 2>&1\n" +
            "sleep 2\n" +
            "echo '###KNOWN###'\n" +
            "iwctl known-networks list\n" +
            "echo '###NETWORKS###'\n" +
            "iwctl station \"$ifc\" get-networks"]
        stdout: StdioCollector {
            onStreamFinished: { root._parseNetworks(text); root.scanning = false; }
        }
    }

    Process {
        id: ctlProc
        onRunningChanged: {
            if (!running) {
                pollProc.running = true;
                root.scan();
            }
        }
    }

    Timer {
        id: operationTimer
        interval: 20000
        onTriggered: {
            root.connectingSsid = "";
            root.disconnectingSsid = "";
        }
    }

    function scan() {
        if (scanProc.running)
            return;
        scanning = true;
        scanProc.running = true;
    }

    function connectNetwork(ssid: string) {
        let net = null;
        for (let n of networks) {
            if (n.ssid === ssid) { net = n; break; }
        }
        // Known and open networks connect straight away; a new secured network
        // needs a passphrase we can't prompt for here, so hand off to the Impala TUI.
        if (net && !net.known && !net.open) {
            Quickshell.execDetached(["bash", "-c",
                "rfkill unblock wifi; omarchy-launch-or-focus-tui impala"]);
            return;
        }
        root.connectingSsid = ssid;
        root.disconnectingSsid = "";
        operationTimer.restart();
        ctlProc.command = ["bash", "-c",
            root._findIface + "iwctl station \"$ifc\" connect " + root._shq(ssid)];
        ctlProc.running = true;
    }

    function disconnect(ssid) {
        let target = (ssid && ssid.length) ? ssid : root.ssid;
        root.disconnectingSsid = target;
        root.connectingSsid = "";
        operationTimer.restart();
        ctlProc.command = ["bash", "-c",
            root._findIface + "iwctl station \"$ifc\" disconnect"];
        ctlProc.running = true;
    }

    /// Secondary label for network rows: "Connecting", "Disconnecting", or empty.
    function connectionStatusFor(ssid: string): string {
        if (!ssid.length)
            return "";
        if (root.connectingSsid === ssid)
            return "Connecting";
        if (root.disconnectingSsid === ssid)
            return "Disconnecting";
        return "";
    }

    function _clearOperationHints() {
        if (connectingSsid.length && connected && ssid === connectingSsid) {
            connectingSsid = "";
            operationTimer.stop();
        }
        if (disconnectingSsid.length && (!connected || ssid !== disconnectingSsid)) {
            disconnectingSsid = "";
            operationTimer.stop();
        }
    }

    function _shq(s: string): string {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function _stripAnsi(s: string): string {
        return s.replace(/\[[0-9;]*m/g, "").replace(/\x1b/g, "");
    }

    function _parseNetworks(raw: string) {
        let knownText = "";
        let netText = raw;
        let ki = raw.indexOf("###KNOWN###");
        let ni = raw.indexOf("###NETWORKS###");
        if (ki >= 0 && ni >= 0) {
            knownText = raw.slice(ki + "###KNOWN###".length, ni);
            netText = raw.slice(ni + "###NETWORKS###".length);
        }

        // Saved network names.
        let known = ({});
        for (let line of knownText.split("\n")) {
            let plain = root._stripAnsi(line);
            if (!plain.trim()) continue;
            if (/Known Networks|Last connected|^\s*Name\s/.test(plain)) continue;
            if (/^\s*-+\s*$/.test(plain)) continue;
            let m = plain.match(/^\s{2}(.+?)\s{2,}\S/);
            if (m) known[m[1].trim()] = true;
        }

        // Available (scanned) networks.
        let out = [];
        for (let line of netText.split("\n")) {
            let plain = root._stripAnsi(line);
            if (!plain.trim()) continue;
            if (/Available networks|Network name/.test(plain)) continue;
            if (/^\s*-+\s*$/.test(plain)) continue;
            // A "> " marker in the leading columns flags the connected network.
            let connected = plain.slice(0, 6).indexOf(">") >= 0;
            let m = plain.replace(/^\s*>?\s*/, "").match(/^(.+?)\s{2,}(\S+)\s+\*+\s*$/);
            if (!m) continue;
            let ssid = m[1].trim();
            if (!ssid.length) continue;
            let security = m[2].trim();
            // iwd dims the unused signal bars with \e[1;90m, so the first run of
            // asterisks in the RAW line is the count of lit bars (1..4).
            let lit = (line.match(/\*+/) || [""])[0].length;
            out.push({
                ssid: ssid,
                security: security,
                open: security.toLowerCase() === "open",
                strength: Math.max(0, Math.min(1, lit / 4)),
                known: known[ssid] === true,
                connected: connected
            });
        }

        out.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return b.strength - a.strength;
        });
        for (let n of out) {
            if (connectingSsid.length && n.ssid === connectingSsid && n.connected) {
                connectingSsid = "";
                operationTimer.stop();
            }
            if (disconnectingSsid.length && n.ssid === disconnectingSsid && !n.connected) {
                disconnectingSsid = "";
                operationTimer.stop();
            }
        }
        if (disconnectingSsid.length) {
            let stillConnected = false;
            for (let n of out) {
                if (n.ssid === disconnectingSsid && n.connected) {
                    stillConnected = true;
                    break;
                }
            }
            if (!stillConnected) {
                disconnectingSsid = "";
                operationTimer.stop();
            }
        }
        root.networks = out;
    }
}

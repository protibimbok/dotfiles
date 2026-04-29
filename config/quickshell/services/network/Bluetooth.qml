pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    property string device: ""

    /// MAC addresses currently connected (from `bluetoothctl devices Connected`).
    property var connectedAddresses: []

    /// MAC passed to `connectTo` while `bluetoothctl connect` is running.
    property string connectingAddress: ""

    property var devices: []

    /// MACs from `bluetoothctl devices Paired` (saved devices; listed before scanned-only peers).
    property var pairedAddresses: []

    /// True while `bluetoothctl --timeout … scan on` is running.
    property bool scanning: false

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: btShowProc.running = true
    }

    Process {
        id: btShowProc
        command: ["bash", "-c", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show || echo 'unavailable'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.indexOf("Powered: yes") >= 0;
                if (root.enabled) {
                    btInfoProc.running = true;
                } else {
                    root.connected = false;
                    root.device = "";
                    root.connectedAddresses = [];
                    root.connectingAddress = "";
                    root.pairedAddresses = [];
                }
            }
        }
    }

    /// Resolves active connection name from `bluetoothctl devices Connected` (info requires a MAC).
    Process {
        id: btInfoProc
        command: ["bash", "-c", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl devices Connected || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n").filter(function (l) {
                    return l.length;
                });
                let addrs = [];
                let firstName = "";
                for (let line of lines) {
                    let m = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                    if (m) {
                        addrs.push(m[1]);
                        if (!firstName.length)
                            firstName = m[2].trim();
                    }
                }
                root.connectedAddresses = addrs;
                root.connected = addrs.length > 0;
                root.device = firstName;
            }
        }
    }

    function setEnabled(on: bool) {
        btToggleProc.command = ["bash", "-c", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl power " + (on ? "on" : "off")];
        btToggleProc.running = true;
    }

    Process {
        id: btToggleProc
        onExited: btShowProc.running = true
    }

    function refresh() {
        btListProc.running = true;
    }

    /// Discovery scan (lists populate via `devices` after scan ends).
    function startScan() {
        if (scanning)
            return;
        scanning = true;
        btScanProc.running = true;
    }

    Process {
        id: btScanProc
        command: ["bash", "-c", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl --timeout 15 scan on"]
        onExited: {
            root.scanning = false;
            btListProc.running = true;
        }
    }

    Process {
        id: btListProc
        command: ["bash", "-c",
            "command -v bluetoothctl >/dev/null 2>&1 || exit 0\n" +
            "echo '__QS_PAIRED__'\n" +
            "bluetoothctl devices Paired 2>/dev/null || true\n" +
            "echo '__QS_ALL__'\n" +
            "bluetoothctl devices 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: root._parseBtDevices(text)
        }
    }

    /// Snapshot for merging `btEnrichProc` results (only addresses needing Alias/Name from `info`).
    property var _enrichPending: null

    Process {
        id: btEnrichProc
        stdout: StdioCollector {
            onStreamFinished: {
                let pending = root._enrichPending;
                root._enrichPending = null;
                if (!pending || !pending.length)
                    return;
                let map = {};
                for (let line of text.trim().split("\n")) {
                    if (!line.length)
                        continue;
                    let i = line.indexOf("|");
                    if (i <= 0)
                        continue;
                    let addr = line.substring(0, i);
                    let nm = line.substring(i + 1).trim();
                    if (nm.length)
                        map[addr] = nm;
                }
                let merged = [];
                for (let d of pending) {
                    let enriched = map[d.address];
                    if (enriched && enriched.length && !root._looksLikeUnresolvedName(enriched, d.address))
                        merged.push({ address: d.address, name: enriched });
                    else
                        merged.push(d);
                }
                devices = root._sortSavedFirst(merged);
            }
        }
    }

    /// BlueZ often echoes the MAC as the label until Alias is known; `bluetoothctl info` resolves it.
    function _looksLikeUnresolvedName(name: string, address: string): bool {
        let n = name.trim();
        if (!n.length)
            return true;
        if (n === address)
            return true;
        if (/^[0-9A-Fa-f:]{17}$/.test(n))
            return true;
        // Windows-style MAC in BlueZ Alias when no real name (distinct from colon form in `address`)
        if (/^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/.test(n))
            return true;
        let compact = n.replace(/[:-]/g, "").toUpperCase();
        let addrCompact = address.replace(/:/g, "").toUpperCase();
        return compact.length === 12 && compact === addrCompact;
    }

    function _addressMatch(a: string, b: string): bool {
        if (!a.length || !b.length)
            return false;
        return a.replace(/:/g, "").toUpperCase() === b.replace(/:/g, "").toUpperCase();
    }

    /// Secondary label for device rows: "Connecting", "Connected", or empty.
    function connectionStatusFor(address: string): string {
        if (!address.length)
            return "";
        if (_addressMatch(root.connectingAddress, address))
            return "Connecting";
        for (let ca of root.connectedAddresses) {
            if (_addressMatch(ca, address))
                return "Connected";
        }
        return "";
    }

    function _sortSavedFirst(list): var {
        let paired = root.pairedAddresses;
        function key(addr: string): string {
            return addr.replace(/:/g, "").toUpperCase();
        }
        let rank = {};
        for (let i = 0; i < paired.length; ++i)
            rank[key(paired[i])] = i;
        let copy = list.slice();
        copy.sort(function (a, b) {
            let ka = key(a.address);
            let kb = key(b.address);
            let ra = rank.hasOwnProperty(ka);
            let rb = rank.hasOwnProperty(kb);
            if (ra !== rb)
                return ra ? -1 : 1;
            if (ra && rb && rank[ka] !== rank[kb])
                return rank[ka] - rank[kb];
            return 0;
        });
        return copy;
    }

    /// Primary label for UI: avoid showing MAC-as-name when `address` is already shown separately.
    function displayName(name: string, address: string): string {
        if (_looksLikeUnresolvedName(name, address))
            return "Unknown device";
        return name.trim();
    }

    function _parseBtDevices(data: string) {
        let paired = [];
        let allBlock = data;
        let i = data.indexOf("__QS_PAIRED__");
        let j = data.indexOf("__QS_ALL__");
        let mkP = "__QS_PAIRED__";
        let mkA = "__QS_ALL__";
        if (i >= 0 && j > i) {
            let pairedBlock = data.substring(i + mkP.length, j).trim();
            for (let line of pairedBlock.split("\n")) {
                let m = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+/);
                if (m)
                    paired.push(m[1]);
            }
            allBlock = data.substring(j + mkA.length);
        }
        root.pairedAddresses = paired;

        let out = [];
        for (let line of allBlock.trim().split("\n")) {
            let m = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
            if (m) out.push({ address: m[1], name: m[2].trim() });
        }
        out = root._sortSavedFirst(out);
        let need = [];
        for (let d of out) {
            if (_looksLikeUnresolvedName(d.name, d.address))
                need.push(d.address);
        }
        devices = out;
        if (!need.length)
            return;
        root._enrichPending = out;
        let quoted = need.map(function (a) {
            return "'" + a.replace(/'/g, "'\\''") + "'";
        }).join(" ");
        btEnrichProc.command = ["bash", "-c",
            "command -v bluetoothctl >/dev/null 2>&1 || exit 0\n" +
            "for a in " + quoted + "; do\n" +
            "  info=$(bluetoothctl info \"$a\" 2>/dev/null) || continue\n" +
            "  alias=$(printf '%s\\n' \"$info\" | grep -iE '^[[:space:]]*Alias:' | head -1 | sed 's/.*Alias:[[:space:]]*//')\n" +
            "  name=$(printf '%s\\n' \"$info\" | grep -iE '^[[:space:]]*Name:' | head -1 | sed 's/.*Name:[[:space:]]*//')\n" +
            "  resolved=${alias:-$name}\n" +
            "  [ -n \"$resolved\" ] && printf '%s|%s\\n' \"$a\" \"$resolved\"\n" +
            "done"];
        btEnrichProc.running = true;
    }

    /// Pair if needed, trust, then connect (same tap for new and known devices).
    function connectTo(address: string) {
        if (!address.length) return;
        root.connectingAddress = address;
        let a = address.replace(/'/g, "'\\''");
        btConnectProc.command = ["bash", "-c",
            "command -v bluetoothctl >/dev/null 2>&1 && " +
            "(bluetoothctl pair '" + a + "' 2>/dev/null || true) && " +
            "bluetoothctl trust '" + a + "' && " +
            "bluetoothctl connect '" + a + "'"];
        btConnectProc.running = true;
    }

    Process {
        id: btConnectProc
        onExited: {
            root.connectingAddress = "";
            btInfoProc.running = true;
            btListProc.running = true;
        }
    }

    function openSettings() {
        btSettingsLaunchProc.command = ["bash", "-c",
            "(command -v blueman-manager >/dev/null && exec blueman-manager) || " +
            "(command -v blueberry >/dev/null && exec blueberry) || " +
            "(command -v gnome-control-center >/dev/null && exec gnome-control-center bluetooth) || " +
            "(command -v kitty >/dev/null && exec kitty -1 bluetoothctl) || " +
            "(command -v foot >/dev/null && exec foot bluetoothctl) || true"];
        btSettingsLaunchProc.running = true;
    }

    Process { id: btSettingsLaunchProc }
}

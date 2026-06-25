pragma Singleton
import Quickshell
import Quickshell.Bluetooth as Bluez
import Quickshell.Io
import QtQuick

// Bluetooth status/control backed by Quickshell's native BlueZ (org.bluez) D-Bus
// bindings — no bluetoothctl/busctl shelling. Properties update reactively as
// devices connect/disconnect; the only external process is launching a settings GUI.
Singleton {
    id: root

    readonly property var adapter: Bluez.Bluetooth.defaultAdapter

    property bool enabled: adapter ? adapter.enabled : false
    property bool connected: false
    property string device: ""

    /// MAC addresses currently connected.
    property var connectedAddresses: []

    /// Human-readable names for `connectedAddresses` (same order).
    property var connectedNames: []

    /// MAC passed to `connectTo` while a connection attempt is in flight.
    property string connectingAddress: ""

    /// All known devices as `{ address, name }`, saved (paired) ones first.
    property var devices: []

    /// MACs of paired (saved) devices.
    property var pairedAddresses: []

    /// True while the adapter is discovering (see `startScan`).
    property bool scanning: adapter ? adapter.discovering : false

    // Per-device watcher: any membership or relevant property change recomputes
    // the aggregate lists. `sig` rolls all watched fields into one binding so a
    // change to any of them fires a single onSigChanged.
    Instantiator {
        model: Bluez.Bluetooth.devices
        delegate: QtObject {
            required property var modelData
            readonly property string sig: [
                modelData.connected, modelData.paired, modelData.trusted,
                modelData.deviceName, modelData.name, modelData.state
            ].join("|")
            onSigChanged: recompute.restart()
            Component.onCompleted: recompute.restart()
            Component.onDestruction: recompute.restart()
        }
    }

    // Debounce bursts of device-property changes into one recompute.
    Timer {
        id: recompute
        interval: 50
        onTriggered: root._recompute()
    }

    Component.onCompleted: root._recompute()

    function _deviceName(d): string {
        if (d.deviceName && d.deviceName.length)
            return d.deviceName;
        return d.name || "";
    }

    function _recompute() {
        let list = Bluez.Bluetooth.devices ? Bluez.Bluetooth.devices.values : [];
        let addrs = [];
        let names = [];
        let paired = [];
        let devs = [];
        for (let d of list) {
            if (!d)
                continue;
            let addr = d.address || "";
            let nm = _deviceName(d);
            devs.push({ address: addr, name: nm });
            if (d.paired)
                paired.push(addr);
            if (d.connected) {
                addrs.push(addr);
                names.push(nm);
            }
        }
        connectedAddresses = addrs;
        connectedNames = names;
        connected = addrs.length > 0;
        device = names.length ? names[0] : "";
        pairedAddresses = paired;
        devices = _sortSavedFirst(devs);

        // Clear the in-flight hint once the device settles (connected or idle).
        if (connectingAddress.length) {
            let d = _findByAddress(connectingAddress);
            if (!d || (d.state !== Bluez.BluetoothDeviceState.Connecting && !d.pairing))
                connectingAddress = "";
        }
    }

    function _findByAddress(address: string): var {
        if (!address.length)
            return null;
        let list = Bluez.Bluetooth.devices ? Bluez.Bluetooth.devices.values : [];
        for (let d of list) {
            if (d && _addressMatch(d.address || "", address))
                return d;
        }
        return null;
    }

    function setEnabled(on: bool) {
        if (adapter)
            adapter.enabled = on;
    }

    /// Native bindings stay current on their own; kept for API compatibility.
    function refresh() {
        recompute.restart();
    }

    /// Discovery scan; lists populate via `devices` as peers are found.
    function startScan() {
        if (!adapter || adapter.discovering)
            return;
        adapter.discovering = true;
        scanTimer.restart();
    }

    Timer {
        id: scanTimer
        interval: 15000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }

    /// Pair if needed, trust, then connect (same tap for new and known devices).
    function connectTo(address: string) {
        let d = _findByAddress(address);
        if (!d)
            return;
        root.connectingAddress = address;
        if (!d.paired)
            d.pair();
        d.trusted = true;
        d.connect();
    }

    function disconnectFrom(address: string) {
        let d = _findByAddress(address);
        if (d)
            d.disconnect();
    }

    function _addressMatch(a: string, b: string): bool {
        if (!a.length || !b.length)
            return false;
        return a.replace(/:/g, "").toUpperCase() === b.replace(/:/g, "").toUpperCase();
    }

    /// Secondary label for device rows: "Connecting", "Connected", or empty.
    function connectionStatusFor(address: string): string {
        let d = _findByAddress(address);
        if (!d)
            return "";
        if (d.pairing || d.state === Bluez.BluetoothDeviceState.Connecting
                || _addressMatch(root.connectingAddress, address))
            return "Connecting";
        if (d.connected || d.state === Bluez.BluetoothDeviceState.Connected)
            return "Connected";
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

    /// BlueZ may echo the MAC as the label until an Alias is known.
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

    /// Primary label for UI: avoid showing MAC-as-name when `address` is already shown separately.
    function displayName(name: string, address: string): string {
        if (_looksLikeUnresolvedName(name, address))
            return "Unknown device";
        return name.trim();
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

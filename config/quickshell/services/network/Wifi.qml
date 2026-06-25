pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Read-only Wi-Fi status, backend-agnostic (works with iwd or NetworkManager).
// Sourced from /sys/class/net, /proc/net/wireless and `iw` — no nmcli dependency.
Singleton {
    id: root

    property bool enabled: false
    property bool connected: false
    property real strength: 0.0
    property string ssid: ""
    property real frequency: 0.0   // GHz

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
    }
}

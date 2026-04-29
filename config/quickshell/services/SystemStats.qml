pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

Singleton {
    id: root

    /// Wired link up (ethernet or bridge), from NetworkManager — see Ethernet.qml
    property bool ethernetConnected: Ethernet.connected

    property var cpuCores: []
    property real cpuAverage: 0.0

    property real memUsage: 0.0
    property real memUsedGb: 0.0
    property real memTotalGb: 0.0

    property string netDown: "0 B/s"
    property string netUp: "0 B/s"
    property real netDownBytes: 0
    property real netUpBytes: 0

    property bool batteryPresent: false
    property int batteryLevel: 0
    property bool batteryCharging: false

    property string inputLocale: "EN"

    property string perfMode: "balanced"

    property int brightness: 0
    property bool capsLock: false

    signal batteryWarning(int level)

    property var _prevCpu: []
    property real _prevRxBytes: 0
    property real _prevTxBytes: 0
    property bool _firstTick: true
    property bool _prevCharging: false
    property var _warnedLevels: []

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true;
            memProc.running = true;
            netProc.running = true;
            battProc.running = true;
            langProc.running = true;
            perfProc.running = true;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            brightnessProc.running = true;
            capsLockProc.running = true;
        }
    }

    Process {
        id: cpuProc
        command: ["grep", "^cpu", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: root._parseCpu(text)
        }
    }

    Process {
        id: memProc
        command: ["grep", "-E", "^(MemTotal|MemAvailable):", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root._parseMem(text)
        }
    }

    Process {
        id: netProc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: root._parseNet(text)
        }
    }

    Process {
        id: battProc
        command: ["bash", "-c", "for d in /sys/class/power_supply/BAT*; do [ -d \"$d\" ] && echo \"$(cat $d/capacity) $(cat $d/status)\" && exit 0; done; echo 'none'"]
        stdout: StdioCollector {
            onStreamFinished: root._parseBatt(text)
        }
    }

    Process {
        id: langProc
        command: ["bash", "-c", "command -v fcitx5-remote >/dev/null 2>&1 && fcitx5-remote -n || echo 'keyboard-us'"]
        stdout: StdioCollector {
            onStreamFinished: root._parseLang(text)
        }
    }

    Process {
        id: perfProc
        command: ["bash", "-c", "if command -v busctl >/dev/null 2>&1 && busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile >/dev/null 2>&1; then busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk -F'\"' '{print $2}'; elif command -v powerprofilesctl >/dev/null 2>&1; then powerprofilesctl get 2>/dev/null; elif [ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor; else echo none; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let first = text.trim().split("\n")[0] || "";
                let raw = first.split(":")[0].trim().toLowerCase();
                if (raw === "power-saver" || raw === "power saver") root.perfMode = "powersave";
                else if (raw === "performance") root.perfMode = "performance";
                else if (raw === "balanced") root.perfMode = "balanced";
                else if (raw === "powersave") root.perfMode = "powersave";
                else if (raw === "schedutil" || raw === "ondemand" || raw === "conservative") root.perfMode = "balanced";
                else if (raw === "none" || raw === "") root.perfMode = "balanced";
                else root.perfMode = "balanced";
            }
        }
    }

    Process {
        id: brightnessProc
        command: ["bash", "-c", "command -v brightnessctl >/dev/null 2>&1 && brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4}' || echo -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim());
                if (!isNaN(val) && val >= 0) root.brightness = val;
            }
        }
    }

    Process {
        id: capsLockProc
        command: ["bash", "-c", "f=$(ls /sys/class/leds/ 2>/dev/null | grep -m1 'capslock'); [ -n \"$f\" ] && cat \"/sys/class/leds/$f/brightness\" 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim());
                root.capsLock = val === 1;
            }
        }
    }

    function _parseCpu(data: string) {
        let lines = data.trim().split("\n");
        let cores = [];
        for (let i = 0; i < lines.length; i++) {
            let parts = lines[i].trim().split(/\s+/);
            if (!parts[0].match(/^cpu\d+$/)) continue;
            let vals = parts.slice(1).map(Number);
            let total = vals.reduce((a, b) => a + b, 0);
            let idle = vals[3] + (vals[4] || 0);
            cores.push({ total: total, idle: idle });
        }

        if (_prevCpu.length === cores.length && !_firstTick) {
            let usages = [];
            let sumUsage = 0;
            for (let i = 0; i < cores.length; i++) {
                let dt = cores[i].total - _prevCpu[i].total;
                let di = cores[i].idle - _prevCpu[i].idle;
                let usage = dt > 0 ? (dt - di) / dt : 0;
                usages.push(Math.max(0, Math.min(1, usage)));
                sumUsage += usages[i];
            }
            cpuCores = usages;
            cpuAverage = cores.length > 0 ? sumUsage / cores.length : 0;
        }
        _prevCpu = cores;
        _firstTick = false;
    }

    function _parseMem(data: string) {
        let lines = data.trim().split("\n");
        let total = 0, avail = 0;
        for (let line of lines) {
            let m = line.match(/^(\w+):\s+(\d+)/);
            if (!m) continue;
            if (m[1] === "MemTotal") total = parseInt(m[2]);
            else if (m[1] === "MemAvailable") avail = parseInt(m[2]);
        }
        if (total > 0) {
            memTotalGb = Math.round(total / 1048576 * 10) / 10;
            memUsedGb = Math.round((total - avail) / 1048576 * 10) / 10;
            memUsage = (total - avail) / total;
        }
    }

    function _parseNet(data: string) {
        let lines = data.trim().split("\n");
        let rx = 0, tx = 0;
        for (let line of lines) {
            let m = line.trim().match(/^(eth|en|wl)\S*:\s*([\d]+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+([\d]+)/);
            if (m) {
                rx += parseInt(m[2]);
                tx += parseInt(m[3]);
            }
        }
        if (_prevRxBytes > 0 && !_firstTick) {
            let drx = (rx - _prevRxBytes) / 1.5;
            let dtx = (tx - _prevTxBytes) / 1.5;
            netDownBytes = Math.max(0, drx);
            netUpBytes = Math.max(0, dtx);
            netDown = _fmtSpeed(netDownBytes);
            netUp = _fmtSpeed(netUpBytes);
        }
        _prevRxBytes = rx;
        _prevTxBytes = tx;
    }

    function _fmtSpeed(bps: real): string {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s";
        if (bps >= 1024) return (bps / 1024).toFixed(0) + " KB/s";
        return Math.round(bps) + " B/s";
    }

    function _parseBatt(data: string) {
        let d = data.trim();
        if (d === "none") {
            batteryPresent = false;
            return;
        }
        let parts = d.split(" ");
        batteryPresent = true;
        let newLevel = parseInt(parts[0]) || 0;
        let newCharging = (parts[1] || "").toLowerCase().indexOf("charging") >= 0 && parts[1] !== "Discharging";

        batteryLevel = newLevel;
        batteryCharging = newCharging;

        if (newCharging) {
            _warnedLevels = [];
        } else if (!_firstTick) {
            let thresholds = [20, 10, 5];
            for (let t of thresholds) {
                if (newLevel <= t && _warnedLevels.indexOf(t) < 0) {
                    _warnedLevels = _warnedLevels.concat([t]);
                    root.batteryWarning(newLevel);
                }
            }
        }
    }

    function _parseLang(data: string) {
        let d = data.trim().toLowerCase();
        if (d.indexOf("arabic") >= 0) inputLocale = "AR";
        else if (d.indexOf("french") >= 0) inputLocale = "FR";
        else if (d.indexOf("german") >= 0) inputLocale = "DE";
        else if (d.indexOf("spanish") >= 0) inputLocale = "ES";
        else if (d.indexOf("japanese") >= 0) inputLocale = "JP";
        else if (d.indexOf("chinese") >= 0) inputLocale = "ZH";
        else if (d.indexOf("korean") >= 0) inputLocale = "KR";
        else if (d.indexOf("russian") >= 0) inputLocale = "RU";
        else inputLocale = "EN";
    }

    function setPerfMode(mode: string) {
        let profile = "balanced";
        if (mode === "powersave")
            profile = "power-saver";
        else if (mode === "performance")
            profile = "performance";
        perfModeProc.command = ["bash", "-c",
            "if command -v busctl >/dev/null 2>&1 && busctl --system get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile >/dev/null 2>&1; then busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s " + profile + "; elif command -v powerprofilesctl >/dev/null 2>&1; then powerprofilesctl set " + profile + "; fi"];
        perfModeProc.running = true;
    }

    Process {
        id: perfModeProc
        command: ["true"]
        onExited: perfProc.running = true
    }

    function setBrightness(percent: int) {
        let v = Math.max(0, Math.min(100, Math.round(percent)));
        root.brightness = v;
        setBrightProc.command = ["bash", "-c",
            "command -v brightnessctl >/dev/null 2>&1 && brightnessctl set " + v + "% 2>/dev/null || true"];
        setBrightProc.running = true;
    }

    Process { id: setBrightProc }
}

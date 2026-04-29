pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int volume: 50
    property bool muted: false
    property var sinks: []
    property var sources: []

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volProc.running = true;
            statusProc.running = true;
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                let m = text.match(/Volume:\s+([\d.]+)/);
                if (m) root.volume = Math.round(parseFloat(m[1]) * 100);
                root.muted = text.indexOf("[MUTED]") >= 0;
            }
        }
    }

    Process {
        id: statusProc
        command: ["wpctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parsed = root._parseWpctlStatus(text);
                root.sinks = parsed.sinks;
                root.sources = parsed.sources;
                if (parsed.sinks.length === 0) sinksFallbackProc.running = true;
                if (parsed.sources.length === 0) sourcesFallbackProc.running = true;
            }
        }
    }

    function _parseWpctlNodeLine(line: string): var {
        let s = String(line).replace(/^[│├└\s]+/, "").replace(/^\s+/, "");
        if (!s.length) return null;
        let m = s.match(/^\*\s+(\d+)\.\s+(.+)$/);
        if (m) {
            let tail = String(m[2]).replace(/\s+\[.*$/, "").replace(/ +$/g, "").replace(/^\s+|\s+$/g, "");
            return { id: parseInt(m[1], 10), description: tail, isDefault: true };
        }
        m = s.match(/^(\d+)\.\s+(.+)$/);
        if (m) {
            let tail = String(m[2]).replace(/\s+\[.*$/, "").replace(/ +$/g, "").replace(/^\s+|\s+$/g, "");
            return { id: parseInt(m[1], 10), description: tail, isDefault: false };
        }
        return null;
    }

    function _parseWpctlStatus(data: string): var {
        let sinksOut = [];
        let sourcesOut = [];
        let section = null;
        let inAudio = false;
        let text = String(data);
        for (let raw of text.split("\n")) {
            let line = String(raw).replace(/\s+$/, "");
            let t = line.trim();
            if (t === "Audio") {
                inAudio = true;
                section = null;
                continue;
            }
            if (t.indexOf("Video") === 0 || t.indexOf("Settings") === 0) {
                inAudio = false;
                section = null;
                continue;
            }
            if (!inAudio) continue;

            if (t.indexOf("├─ Sinks:") >= 0) {
                section = "sinks";
                continue;
            }
            if (t.indexOf("├─ Sources:") >= 0) {
                section = "sources";
                continue;
            }
            if (t.indexOf("├─") === 0 && section) {
                if (section === "sinks" && t.indexOf("Sinks:") < 0) section = null;
                else if (section === "sources" && t.indexOf("Sources:") < 0) section = null;
                continue;
            }
            if (!section) continue;
            let node = root._parseWpctlNodeLine(line);
            if (!node) continue;
            let item = {
                id: node.id,
                name: String(node.id),
                description: node.description.length ? node.description : ("Device " + node.id),
                isDefault: node.isDefault
            };
            if (section === "sinks") sinksOut.push(item);
            else sourcesOut.push(item);
        }
        return { sinks: sinksOut, sources: sourcesOut };
    }

    Process {
        id: sinksFallbackProc
        command: ["pactl", "-f", "json", "list", "sinks"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let arr = JSON.parse(text);
                    if (!Array.isArray(arr)) return;
                    root.sinks = arr.map(s => root._sinkFromPactlJson(s));
                    defaultSinkProc.running = true;
                } catch (e) {}
            }
        }
    }

    Process {
        id: sourcesFallbackProc
        command: ["pactl", "-f", "json", "list", "sources"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let arr = JSON.parse(text);
                    if (!Array.isArray(arr)) return;
                    root.sources = arr
                        .filter(s => !(s.name || "").match(/\.monitor$/))
                        .map(s => root._sourceFromPactlJson(s));
                    defaultSourceProc.running = true;
                } catch (e) {}
            }
        }
    }

    function _sinkFromPactlJson(s: var): var {
        let desc = s.description || "";
        if (!desc && s.properties) {
            let p = s.properties;
            desc = p["node.description"] || p["device.description"] || "";
        }
        let name = s.name || "";
        return {
            id: -1,
            name: name,
            description: (desc || name).replace(/\s+/g, " ").trim(),
            isDefault: false
        };
    }

    function _sourceFromPactlJson(s: var): var {
        return root._sinkFromPactlJson(s);
    }

    property string defaultSinkName: ""
    property string defaultSourceName: ""

    Process {
        id: defaultSinkProc
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaultSinkName = text.trim();
                root.sinks = root.sinks.map(s => {
                    s.isDefault = s.name === root.defaultSinkName;
                    return s;
                });
            }
        }
    }

    Process {
        id: defaultSourceProc
        command: ["pactl", "get-default-source"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaultSourceName = text.trim();
                root.sources = root.sources.map(s => {
                    s.isDefault = s.name === root.defaultSourceName;
                    return s;
                });
            }
        }
    }

    function setVolume(vol: int) {
        let v = Math.max(0, Math.min(100, vol)) / 100;
        setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)];
        setVolProc.running = true;
        volume = vol;
    }

    Process { id: setVolProc }

    onMutedChanged: {
        muteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", muted ? "1" : "0"];
        muteProc.running = true;
    }

    Process { id: muteProc }

    function setDefaultSink(nameOrId: string) {
        let s = String(nameOrId).trim();
        if (/^\d+$/.test(s)) {
            let id = parseInt(s, 10);
            if (id > 0 && id < 2147483647) {
                setSinkWpProc.command = ["wpctl", "set-default", s];
                setSinkWpProc.running = true;
                return;
            }
        }
        setSinkProc.command = ["pactl", "set-default-sink", s];
        setSinkProc.running = true;
    }

    Process {
        id: setSinkWpProc
        onExited: statusProc.running = true
    }

    Process {
        id: setSinkProc
        onExited: {
            statusProc.running = true;
            sinksFallbackProc.running = true;
        }
    }

    function setDefaultSource(nameOrId: string) {
        let s = String(nameOrId).trim();
        if (/^\d+$/.test(s)) {
            let id = parseInt(s, 10);
            if (id > 0 && id < 2147483647) {
                setSourceWpProc.command = ["wpctl", "set-default", s];
                setSourceWpProc.running = true;
                return;
            }
        }
        setSourceProc.command = ["pactl", "set-default-source", s];
        setSourceProc.running = true;
    }

    Process {
        id: setSourceWpProc
        onExited: statusProc.running = true
    }

    Process {
        id: setSourceProc
        onExited: {
            statusProc.running = true;
            sourcesFallbackProc.running = true;
        }
    }

    function refresh() {
        volProc.running = true;
        statusProc.running = true;
    }
}

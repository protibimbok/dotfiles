pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool isActive: false
    property string status: "Stopped"
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property string playerName: ""

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: metaProc.running = true
    }

    Process {
        id: metaProc
        command: ["bash", "-c",
            "command -v playerctl >/dev/null 2>&1 || exit 1; " +
            "playerctl -f '{{status}}\n{{title}}\n{{artist}}\n{{mpris:artUrl}}\n{{playerName}}' metadata 2>/dev/null || echo 'Stopped\n\n\n\n'"]
        stdout: StdioCollector {
            onStreamFinished: root._parseMeta(text)
        }
        onExited: code => {
            if (code !== 0) {
                root.isActive = false;
                root.status = "Stopped";
                root.title = "";
                root.artist = "";
                root.artUrl = "";
                root.playerName = "";
            }
        }
    }

    function _parseMeta(data: string) {
        let lines = data.split("\n");
        let s = (lines[0] || "").trim();
        let t = (lines[1] || "").trim();
        let a = (lines[2] || "").trim();
        let u = (lines[3] || "").trim();
        let p = (lines[4] || "").trim();

        root.status = s || "Stopped";
        root.title = t;
        root.artist = a;
        root.artUrl = u.startsWith("file://") ? u : (u.startsWith("http") ? u : "");
        root.playerName = p;
        root.isActive = (s === "Playing" || s === "Paused") && t !== "";
    }

    function playPause() {
        _runCmd(["playerctl", "play-pause"]);
    }

    function next() {
        _runCmd(["playerctl", "next"]);
    }

    function previous() {
        _runCmd(["playerctl", "previous"]);
    }

    function _runCmd(cmd: var) {
        ctrlProc.command = cmd;
        ctrlProc.running = true;
    }

    Process {
        id: ctrlProc
        onExited: metaProc.running = true
    }
}

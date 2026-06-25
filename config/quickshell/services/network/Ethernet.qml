pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Read-only wired-link status from /sys/class/net (no nmcli dependency).
Singleton {
    id: root

    property bool connected: false
    property string device: ""

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
            "for d in /sys/class/net/*; do\n" +
            "  ifc=$(basename \"$d\")\n" +
            "  [ \"$ifc\" = \"lo\" ] && continue\n" +
            "  [ -e \"$d/wireless\" ] && continue\n" +   // skip Wi-Fi
            "  [ -e \"$d/device\" ] || continue\n" +     // skip virtual interfaces
            "  state=$(cat \"$d/operstate\" 2>/dev/null)\n" +
            "  carrier=$(cat \"$d/carrier\" 2>/dev/null)\n" +
            "  if [ \"$state\" = \"up\" ] || { [ \"$state\" = \"unknown\" ] && [ \"$carrier\" = \"1\" ]; }; then\n" +
            "    echo \"$ifc\"; exit 0\n" +
            "  fi\n" +
            "done\n" +
            "echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d = text.trim();
                root.device = d;
                root.connected = d.length > 0;
            }
        }
    }
}

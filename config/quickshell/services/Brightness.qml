pragma Singleton
import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root

    readonly property int level: SystemStats.brightness

    function setLevel(percent: int) {
        SystemStats.setBrightness(percent);
    }
}

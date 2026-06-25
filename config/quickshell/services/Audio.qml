pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Audio status/control backed by Quickshell's native PipeWire bindings — no
// wpctl/pactl polling or status-tree parsing. Volume/mute and the device lists
// update reactively from PipeWire itself (the audio server already running).
Singleton {
    id: root

    property int volume: (activeSink && activeSink.audio) ? Math.round(activeSink.audio.volume * 100) : 0
    property bool muted: false

    property var sinks: []
    property var sources: []
    property string defaultSinkName: ""
    property string defaultSourceName: ""

    readonly property var activeSink: Pipewire.defaultAudioSink
    readonly property var activeSource: Pipewire.defaultAudioSource

    // PipeWire binds object properties lazily; tracking keeps the active devices'
    // `audio` (volume/mute) live so the bindings above stay current.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // --- mute: two-way sync (consumers do `Audio.muted = !Audio.muted`) ---
    onMutedChanged: {
        let a = activeSink && activeSink.audio ? activeSink.audio : null;
        if (a && a.muted !== muted)
            a.muted = muted;
    }
    onActiveSinkChanged: _syncMutedFromNative()
    function _syncMutedFromNative() {
        let a = activeSink && activeSink.audio ? activeSink.audio : null;
        if (a && a.muted !== muted)
            muted = a.muted;
    }
    Connections {
        target: root.activeSink && root.activeSink.audio ? root.activeSink.audio : null
        function onMutedChanged() { root._syncMutedFromNative(); }
    }

    // --- device lists: recompute on node membership / default-device changes ---
    Instantiator {
        model: Pipewire.nodes
        delegate: QtObject {
            required property var modelData
            readonly property string sig: [
                modelData.id, modelData.name, modelData.description,
                modelData.nickname, modelData.type, modelData.isStream
            ].join("|")
            onSigChanged: recompute.restart()
            Component.onCompleted: recompute.restart()
            Component.onDestruction: recompute.restart()
        }
    }
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { recompute.restart(); }
        function onDefaultAudioSourceChanged() { recompute.restart(); }
    }

    Timer {
        id: recompute
        interval: 50
        onTriggered: root._recompute()
    }
    Component.onCompleted: { root._syncMutedFromNative(); root._recompute(); }

    function _recompute() {
        let nodes = Pipewire.nodes ? Pipewire.nodes.values : [];
        let defSink = Pipewire.defaultAudioSink;
        let defSource = Pipewire.defaultAudioSource;
        let sinksOut = [];
        let sourcesOut = [];
        for (let n of nodes) {
            if (!n || n.isStream)
                continue;
            if (!(n.type & PwNodeType.Audio))
                continue;
            let desc = n.description || n.nickname || n.name || ("Device " + n.id);
            let item = {
                id: n.id,
                name: n.name || String(n.id),
                description: String(desc).replace(/\s+/g, " ").trim(),
                isDefault: false
            };
            if (n.type & PwNodeType.Sink) {
                item.isDefault = !!defSink && n.id === defSink.id;
                sinksOut.push(item);
            } else if (n.type & PwNodeType.Source) {
                if ((n.name || "").match(/\.monitor$/))
                    continue;
                item.isDefault = !!defSource && n.id === defSource.id;
                sourcesOut.push(item);
            }
        }
        sinks = sinksOut;
        sources = sourcesOut;
        defaultSinkName = defSink ? (defSink.name || "") : "";
        defaultSourceName = defSource ? (defSource.name || "") : "";
    }

    function _findNode(nameOrId: string, wantSink: bool): var {
        let s = String(nameOrId).trim();
        let byId = /^\d+$/.test(s) ? parseInt(s, 10) : -1;
        let nodes = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (let n of nodes) {
            if (!n || n.isStream || !(n.type & PwNodeType.Audio))
                continue;
            let isSink = !!(n.type & PwNodeType.Sink);
            if (isSink !== wantSink)
                continue;
            if (byId >= 0 ? n.id === byId : n.name === s)
                return n;
        }
        return null;
    }

    function setVolume(vol: int) {
        let v = Math.max(0, Math.min(100, vol)) / 100;
        let a = activeSink && activeSink.audio ? activeSink.audio : null;
        if (a)
            a.volume = v;
    }

    function setDefaultSink(nameOrId: string) {
        let n = _findNode(nameOrId, true);
        if (n)
            Pipewire.preferredDefaultAudioSink = n;
    }

    function setDefaultSource(nameOrId: string) {
        let n = _findNode(nameOrId, false);
        if (n)
            Pipewire.preferredDefaultAudioSource = n;
    }

    /// Native bindings stay current on their own; kept for API compatibility.
    function refresh() {
        recompute.restart();
    }
}

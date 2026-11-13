pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../config"

// Audio: default output (sink) + input (source) volume/mute, plus the lists of real
// output/input devices and a way to switch the default. PwObjectTracker keeps the default
// nodes' `audio` bound; without it volume/muted go stale or straight null (gotcha #5).
// `defaultAudioSink`/`Source` swap out as devices come and go, and the tracker rebinds.
Singleton {
    id: root

    // output (sink)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property bool ready: sink !== null && sink.audio !== null

    // input (source / mic)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real sourceVolume: (source && source.audio) ? source.audio.volume : 0
    readonly property bool sourceMuted: (source && source.audio) ? source.audio.muted : false

    // device lists (real devices, not per-app streams). `sinks`/`sources` are everything
    // PipeWire publishes; `shownSinks`/`shownSources` are what the sheet lists.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    // ── which devices are REAL right now ──
    // PipeWire publishes a node for every path the card has (three HDMI/DP outputs, the
    // headphone jack, the jack mic) whether or not anything is plugged in. Quickshell's
    // Pipewire service exposes the nodes but not the per-port jack state, so that comes
    // from pactl's JSON: a device whose active port is "not available" is dropped from the
    // sheet and comes back the moment it's plugged ("available" and "unknown" both stay).
    // `pactl subscribe` keeps it current; refreshes are debounced.
    property var unavailable: ({})      // node.name -> true
    property var _unavailSinks: ({})
    property var _unavailSources: ({})
    function _notAvail(text) {
        const out = {};
        try {
            for (const d of JSON.parse(text)) {
                const ap = d.active_port;
                if (!ap) continue;
                for (const port of (d.ports || []))
                    if (port.name === ap && port.availability === "not available") out[d.name] = true;
            }
        } catch (e) {}
        return out;
    }
    function _mergeUnavail() { unavailable = Object.assign({}, _unavailSinks, _unavailSources); }
    Process {
        id: pactlSinks
        command: ["pactl", "--format=json", "list", "sinks"]
        stdout: StdioCollector { onStreamFinished: { root._unavailSinks = root._notAvail(text); root._mergeUnavail(); } }
    }
    Process {
        id: pactlSources
        command: ["pactl", "--format=json", "list", "sources"]
        stdout: StdioCollector { onStreamFinished: { root._unavailSources = root._notAvail(text); root._mergeUnavail(); } }
    }
    function refreshPorts() {
        if (!pactlSinks.running) pactlSinks.running = true;
        if (!pactlSources.running) pactlSources.running = true;
    }
    Timer { id: portsSoon; interval: 350; onTriggered: root.refreshPorts() }
    Process {
        id: pactlSub
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => { if (/ on (card|sink|source|server)/.test(line)) portsSoon.restart(); }
        }
    }
    Component.onCompleted: refreshPorts()

    // ── devices the user hid by hand (Config.audioHidden, a JSON array of node names) ──
    // for the ones PipeWire can't judge, like a USB mic's headphone jack
    readonly property var hidden: {
        try { const a = JSON.parse(Config.audioHidden || "[]"); const o = {}; for (const n of a) o[n] = true; return o; }
        catch (e) { return {}; }
    }
    function isHidden(n) { return !!(n && hidden[n.name]); }
    function hide(n) {
        if (!n || hidden[n.name]) return;
        const a = Object.keys(hidden); a.push(n.name);
        Config.audioHidden = JSON.stringify(a);
    }
    function unhide(n) {
        if (!n || !hidden[n.name]) return;
        Config.audioHidden = JSON.stringify(Object.keys(hidden).filter(k => k !== n.name));
    }
    // present (plugged, or unjudgeable) devices, hidden ones included: the sheet's "show hidden" list
    readonly property var presentSinks: sinks.filter(n => !unavailable[n.name])
    readonly property var presentSources: sources.filter(n => !unavailable[n.name])
    // what the sheet shows by default
    readonly property var shownSinks: presentSinks.filter(n => !hidden[n.name])
    readonly property var shownSources: presentSources.filter(n => !hidden[n.name])

    function nodeLabel(n) {
        if (!n) return "";
        return n.description || n.nickname || n.name || "Audio device";
    }

    // output controls
    function setVolume(v) { if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v)); }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function setSink(n) { if (n) Pipewire.preferredDefaultAudioSink = n; }

    // input controls
    function setSourceVolume(v) { if (source && source.audio) source.audio.volume = Math.max(0, Math.min(1, v)); }
    function toggleSourceMute() { if (source && source.audio) source.audio.muted = !source.audio.muted; }
    function setSource(n) { if (n) Pipewire.preferredDefaultAudioSource = n; }

    PwObjectTracker {
        objects: {
            const o = [];
            if (root.sink) o.push(root.sink);
            if (root.source) o.push(root.source);
            return o;
        }
    }
}

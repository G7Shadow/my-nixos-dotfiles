pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// Night light (blue-light filter) via hyprsunset. On: fire up hyprsunset at a warm
// temperature (a detached daemon that hangs onto the gamma). Off: kill it, which
// lets go of the gamma and puts color back to normal. No native binding, so it's
// one of the few legit Process uses (same deal as brightness). State is session-local.
Singleton {
    id: root

    // standard "mode" interface (see shell.qml toggleMode): label + iconName + enabled +
    // toggle(). shell.qml's toggleMode() drives the island indicator off these.
    readonly property string label: "Night Light"
    readonly property string iconName: "night"

    property bool enabled: false
    property int temperature: Config.nightLightTemp   // warm, in K

    function toggle() { enabled = !enabled; apply(); }

    function apply() {
        if (enabled)
            // A daemon that is already running is KEPT and only told the temperature. It
            // used to be killed and started again on every enable, and the shell enables
            // on every start and every reload (the schedule re-syncs), so each reload
            // dropped the tint to full daylight for a moment, and when the new daemon
            // came up before the old one had let go of the gamma it died with "a CTM
            // manager is already running" and the tint stayed off. Only with no daemon
            // at all is one started, after any dying one is really gone.
            Quickshell.execDetached(["sh", "-c",
                "if pgrep -x hyprsunset >/dev/null && hyprctl hyprsunset temperature " + temperature + " >/dev/null 2>&1; then exit 0; fi; "
                + "n=0; while pgrep -x hyprsunset >/dev/null && [ $n -lt 40 ]; do sleep 0.05; n=$((n+1)); done; "
                + "exec hyprsunset -t " + temperature]);
        else
            Quickshell.execDetached(["pkill", "hyprsunset"]);
    }
    // hyprsunset outlives the shell (it is detached), so a shell that starts or reloads
    // while it is running takes it over: Night Light is ON, whatever the schedule would
    // say right now (a manual switch stands between boundaries, across reloads too).
    Process {
        command: ["pgrep", "-x", "hyprsunset"]
        running: true
        onExited: code => { if (code === 0 && !root.enabled) root.enabled = true; }
    }

    // Live temperature change while Night Light is on, through the daemon's own socket:
    // `hyprctl hyprsunset temperature K` (hyprsunset 0.4). A second `hyprsunset -t K` does
    // NOT forward to the running daemon, it dies with "A CTM manager is already running on
    // the current compositor" and the tint never moves (that was the broken slider), and a
    // pkill + respawn flashes the gamma. Throttled to ~90ms so a drag updates the tint in
    // smooth steps instead of spawning a process per pixel.
    property int _pendingTemp: -1
    function setTemp(k) {
        temperature = k;                       // drives the UI live (fill, subtitle)
        if (!enabled) return;
        _pendingTemp = k;
        if (!tempThrottle.running) { flushTemp(); tempThrottle.start(); }
    }
    function flushTemp() {
        if (_pendingTemp < 0) return;
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(_pendingTemp)]);
        _pendingTemp = -1;
    }
    Timer { id: tempThrottle; interval: 90; onTriggered: root.flushTemp() }

    // ── schedule ──
    // On from Config.nightLightStart to Config.nightLightEnd (minutes after midnight; the
    // window may wrap past midnight, 20:00 -> 07:00 being the usual shape). The schedule
    // only acts on a BOUNDARY: when the clock crosses into or out of the window it sets
    // the state, and between boundaries a manual toggle stands (turn it off early tonight
    // and it stays off until tomorrow evening). Turning the schedule on, or moving either
    // time, re-syncs to the window at once.
    readonly property bool scheduled: Config.nightLightSchedule
    property var _wasIn: null
    function minutesNow() { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); }
    function inWindow(m) {
        const a = Config.nightLightStart, b = Config.nightLightEnd;
        if (a === b) return false;
        return a < b ? (m >= a && m < b) : (m >= a || m < b);
    }
    function tick() {
        if (!scheduled) return;
        const w = inWindow(minutesNow());
        if (w === _wasIn) return;
        _wasIn = w;
        if (enabled !== w) { enabled = w; apply(); }
    }
    function resync() { _wasIn = null; tick(); }
    // Re-syncs wait for the settings to hold still. The config file loads one value at a
    // time, so on every shell start and reload "schedule on" arrived while the two times
    // were still the built-in 20:00 and 07:00, and the schedule was judged against those
    // for a moment: between your start time and 20:00 that read as "outside the window",
    // switched Night Light off (killing hyprsunset) and then on again a few ms later.
    onScheduledChanged: settle.restart()
    Connections {
        target: Config
        function onNightLightStartChanged() { settle.restart(); }
        function onNightLightEndChanged() { settle.restart(); }
    }
    Timer { id: settle; interval: 300; onTriggered: root.resync() }
    Timer { interval: 20000; repeat: true; running: root.scheduled; onTriggered: root.tick() }

    function fmtTime(m) {
        const d = new Date(2000, 0, 1, Math.floor(m / 60), m % 60);
        return Qt.formatTime(d, Config.clock24h ? "HH:mm" : "h:mm AP");
    }
    // typed time -> minutes after midnight, or -1. Takes "7", "07", "7:30", "7.30", "730",
    // "1930", with an optional am/pm ("7pm", "7:30 PM").
    function parseTime(str) {
        const m = String(str).trim().toLowerCase().match(/^(\d{1,2})(?:[:. ]?(\d{2}))?\s*(am|pm|a|p)?$/);
        if (!m) return -1;
        let h = parseInt(m[1]), mi = m[2] ? parseInt(m[2]) : 0;
        if (m[3]) {
            if (h < 1 || h > 12) return -1;
            if (m[3][0] === "p" && h < 12) h += 12;
            if (m[3][0] === "a" && h === 12) h = 0;
        }
        if (h > 23 || mi > 59) return -1;
        return h * 60 + mi;
    }
    // one line for the tile and the sheet: what the schedule will do next
    readonly property string scheduleHint: !scheduled ? ""
        : enabled ? "Until " + fmtTime(Config.nightLightEnd)
                  : "At " + fmtTime(Config.nightLightStart)
}

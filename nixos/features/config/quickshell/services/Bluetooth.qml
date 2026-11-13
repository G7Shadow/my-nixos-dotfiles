pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Bluetooth summary. Quickshell.Bluetooth (BlueZ) covers power, connect/disconnect,
// info, and basic pairing. Anything fancier and yer back to bluetoothctl (gotcha #10).
Singleton {
    id: root

    function asArray(m) { return !m ? [] : (m.values !== undefined ? m.values : m); }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    // Devices BlueZ finds while discovering land in Bluetooth.devices, but no change signal
    // reaches a QML BINDING for those insertions (fresh reads see them, bindings don't), so
    // anything derived from the model froze at whatever existed at startup: a new pair of
    // earbuds in pairing mode never showed up. `rev` is bumped by the model's own signals
    // AND by a 1s tick while discovery runs, and every derived list reads through it.
    property int rev: 0
    Connections {
        target: Bluetooth.devices
        function onValuesChanged() { root.rev++; }
        function onObjectInsertedPost() { root.rev++; }
        function onObjectRemovedPost() { root.rev++; }
    }
    Timer { interval: 1000; repeat: true; running: root.adapter ? root.adapter.discovering : false; onTriggered: root.rev++ }
    function devicesNow() { rev; return asArray(Bluetooth.devices); }

    readonly property var connectedDevices: devicesNow().filter(d => d.connected)
    readonly property bool hasConnection: connectedDevices.length > 0

    readonly property string label: {
        if (!enabled) return "BT off";
        if (connectedDevices.length === 0) return "BT on";
        if (connectedDevices.length === 1) {
            const d = connectedDevices[0];
            return d.deviceName || d.name || "BT";
        }
        return `BT ×${connectedDevices.length}`;
    }

    // ── when each device was last connected ──
    // BlueZ does not tell anyone this, so the shell keeps its own small record: address ->
    // time (ms), stamped while a device is connected and again as it drops, kept in the
    // shell's state folder (not in config.json: it is history, not a setting). So a saved
    // device only has a time once it has been connected with this running.
    property var lastSeen: ({})
    FileView {
        id: seenFile
        path: Quickshell.statePath("bluetooth-last-connected.json")
        blockLoading: true
        printErrors: false
    }
    Component.onCompleted: {
        try { const o = JSON.parse(seenFile.text() || "{}"); if (o && typeof o === "object") lastSeen = o; } catch (e) {}
        stamp();
    }
    property var _wasConnected: []
    readonly property var connectedAddrs: connectedDevices.map(d => d.address).filter(a => !!a).sort()
    onConnectedAddrsChanged: stamp()
    function stamp() {
        const now = Date.now(), cur = connectedAddrs;
        const touched = cur.concat(_wasConnected.filter(a => cur.indexOf(a) < 0));
        _wasConnected = cur;
        if (touched.length === 0) return;
        const o = Object.assign({}, lastSeen);
        for (const a of touched) o[a] = now;
        lastSeen = o;
        seenFile.setText(JSON.stringify(o));
    }
    // "Just now", "12 min ago", "3 h ago", "Yesterday", "4 days ago", then the date
    function ago(ms, now) {
        if (!ms) return "";
        const s = Math.max(0, (now - ms) / 1000);
        if (s < 90) return "Just now";
        if (s < 3600) return Math.round(s / 60) + " min ago";
        if (s < 86400) return Math.round(s / 3600) + " h ago";
        if (s < 172800) return "Yesterday";
        if (s < 7 * 86400) return Math.round(s / 86400) + " days ago";
        return Qt.formatDate(new Date(ms), "MMM d");
    }

    function toggle() { if (adapter) adapter.enabled = !adapter.enabled; }
    function setEnabled(on) { if (adapter) adapter.enabled = on; }

    // Paired devices for the control center list, connected ones up top.
    readonly property var pairedDevices: devicesNow()
        .filter(d => d.paired)
        .slice()
        .sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0))
}

import QtQuick
import Quickshell
// qualified: the module's `Bluetooth` singleton would otherwise shadow the services one
import Quickshell.Bluetooth as QB
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The Bluetooth btSheet. Three sections the way One UI and Nothing OS lay them out:
// CONNECTED (with battery, drawn with the shell's own battery icon), SAVED (paired but
// idle, one tap to connect), NEARBY (unpaired devices found while this sheet has the
// adapter discovering; one tap to pair). Device glyphs come from the BlueZ icon names.
Column {
    id: btSheet
    move: CcSheetBits.MoveSpring {}

    property var panel: null
    spacing: Theme.s3

    readonly property var adapter: Bluetooth.adapter
    readonly property bool on: Bluetooth.enabled
    readonly property bool discovering: adapter ? adapter.discovering : false

    // The lists are ScriptModels bound STRAIGHT to Quickshell's device model, the way
    // caelestia / noctalia do it: the binding reads `QB.Bluetooth.devices.values` itself, so
    // the model's own change signal reaches it when BlueZ finds something (a list derived
    // through a helper in the service never re-evaluated, and the keyboard you switched on
    // stayed invisible while bluetoothctl listed it), and ScriptModel diffs by object
    // identity, so rows are not rebuilt on every change. `bonded` is the saved criterion.
    ScriptModel { id: connectedModel; values: QB.Bluetooth.devices.values.filter(d => d.connected).sort((a, b) => (a.name || "").localeCompare(b.name || "")) }
    ScriptModel { id: savedModel;     values: QB.Bluetooth.devices.values.filter(d => d.bonded && !d.connected).sort((a, b) => (a.name || "").localeCompare(b.name || "")) }
    ScriptModel { id: nearbyModel;    values: QB.Bluetooth.devices.values.filter(d => !d.bonded).sort((a, b) => (b.pairing - a.pairing) || (a.name || a.address).localeCompare(b.name || b.address)) }
    readonly property int connectedCount: connectedModel.values.length
    readonly property int savedCount: savedModel.values.length
    readonly property int nearbyCount: nearbyModel.values.length

    // Discovery is ASKED FOR ("Scan" on the Nearby label), never started by opening the
    // sheet: it is radio-noisy and costs battery. It stops itself after a short while,
    // and when the sheet closes or the adapter goes off.
    function setDiscovering(on) { if (adapter && adapter.enabled) adapter.discovering = on; }
    onVisibleChanged: {
        if (visible) now = Date.now();
        else if (adapter && adapter.discovering) adapter.discovering = false;
    }
    Timer { interval: 15000; running: btSheet.discovering; onTriggered: btSheet.setDiscovering(false) }

    function glyph(d) {
        const i = (d.icon || "").toLowerCase();
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "headphones";
        if (i.indexOf("phone") >= 0) return "phone";
        if (i.indexOf("keyboard") >= 0) return "keyboard";
        if (i.indexOf("mouse") >= 0) return "mouse";
        if (i.indexOf("watch") >= 0) return "watch";
        if (i.indexOf("audio") >= 0 || i.indexOf("speaker") >= 0) return "volume";
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0) return "controller";
        if (i.indexOf("computer") >= 0 || i.indexOf("laptop") >= 0 || i.indexOf("display") >= 0) return "display";
        return "bluetooth";
    }
    function label(d) { return d.deviceName || d.name || d.address; }
    // a clock for the "last connected" lines: read when the sheet opens (onVisibleChanged
    // above) and each minute
    // it stays open, so "12 min ago" does not go stale in front of you
    property real now: Date.now()
    Timer { interval: 60000; repeat: true; running: btSheet.visible; onTriggered: btSheet.now = Date.now() }
    function lastLine(d) {
        const t = Bluetooth.lastSeen[d.address];
        return t ? "Last connected " + Bluetooth.ago(t, btSheet.now).replace(/^[A-Z]/, c => c.toLowerCase()) : "";
    }

    // the right-click menu for a device
    function menuFor(d, item, x, y) {
        const items = [{ header: true, title: label(d),
                         subtitle: d.address + (d.connected && d.batteryAvailable ? "  ·  " + Math.round(d.battery * 100) + "%" : "") }];
        if (d.connected) items.push({ label: "Disconnect", act: () => d.disconnect() });
        else if (d.bonded) items.push({ label: "Connect", act: () => d.connect() });
        else if (d.pairing) items.push({ label: "Cancel pairing", act: () => d.cancelPair() });
        else items.push({ label: "Pair", act: () => d.pair() });
        if (d.bonded) items.push({ label: d.trusted ? "Untrust device" : "Trust device", act: () => { d.trusted = !d.trusted; } });
        if (d.bonded) items.push({ label: "Forget device", danger: true, act: () => d.forget() });
        items.push({ label: "Copy address", act: () => { Quickshell.clipboardText = d.address; } });
        panel.openMenu(items, item, x, y);
    }

    // one device row, used by all three sections
    component DeviceRow: Rectangle {
        id: r
        property var d: null
        property string verb: ""            // what the chip offers
        signal act()
        width: parent ? parent.width : 0
        height: 52
        radius: Theme.rMd
        color: rMa.containsMouse ? Theme.fillHigh : Theme.fillLow
        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
        opacity: entered
        // delegate-owned entrance (patterns.md #5): a positioner `add` transition is canceled
        // by the next relayout and strands the row at opacity 0
        property real entered: 0
        Component.onCompleted: entered = 1
        Behavior on entered { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        MouseArea {
            id: rMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => { if (m.button === Qt.RightButton) btSheet.menuFor(r.d, r, m.x, m.y); else r.act(); }
        }

        CcSheetBits.Disc { tint: Theme.hue("toggles");
            id: dDisc
            anchors.left: parent.left
            anchors.leftMargin: Theme.s2
            anchors.verticalCenter: parent.verticalCenter
            size: 36
            live: r.d.connected
            icon: btSheet.glyph(r.d)
        }
        Column {
            anchors.left: dDisc.right
            anchors.leftMargin: Theme.s3
            anchors.right: chip.left
            anchors.rightMargin: Theme.s2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            StyledText {
                width: parent.width; elide: Text.ElideRight
                variant: "label"; font.weight: Theme.wMedium
                text: btSheet.label(r.d)
                color: Theme.inkPrimary
            }
            // the section a row sits in already says Connected / Saved / Nearby, so the
            // second line is only the things that aren't: a pairing in flight, a connected
            // device's battery and charge, or when a saved one was last connected
            Row {
                id: line2
                spacing: Theme.s1 + 2
                readonly property string last: (!r.d.connected && r.d.bonded && !r.d.pairing) ? btSheet.lastLine(r.d) : ""
                visible: r.d.pairing || (r.d.connected && r.d.batteryAvailable) || last !== ""
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: r.d.pairing
                    variant: "caption"
                    text: "Pairing…"
                    color: Theme.hue("toggles")
                }
                BatteryIcon {
                    // centered on the DIGITS beside it, not on the text's box: a line box
                    // carries room under the baseline, so box-centering left the battery
                    // sitting visibly lower than the "66%" it belongs to
                    y: Math.round(pct.y + pct.baselineOffset - pctFm.capitalHeight / 2 - height / 2)
                    visible: r.d.connected && r.d.batteryAvailable
                    level: r.d.battery
                    low: r.d.battery <= 0.2
                    bodyWidth: 16; bodyHeight: 8
                }
                StyledText {
                    id: pct
                    visible: r.d.connected && r.d.batteryAvailable
                    variant: "caption"
                    text: Math.round(r.d.battery * 100) + "%"
                    color: Theme.inkDim
                    FontMetrics { id: pctFm; font: pct.font }
                }
                StyledText {
                    visible: line2.last !== ""
                    variant: "caption"
                    text: line2.last
                    color: Theme.inkDim
                }
            }
        }
        CcSheetBits.Chip { tint: Theme.hue("toggles");
            id: chip
            anchors.right: parent.right
            anchors.rightMargin: Theme.s2
            anchors.verticalCenter: parent.verticalCenter
            text: r.verb
            accent: !r.d.connected
            onClicked: r.act()
        }
    }

    // ── off ──
    Rectangle {
        visible: opacity > 0
        width: parent.width
        height: 72
        opacity: (!btSheet.on) ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        radius: Theme.rLg
        color: Theme.fillLow
        CcSheetBits.Disc { tint: Theme.hue("toggles"); id: offDisc; anchors.left: parent.left; anchors.leftMargin: Theme.s3; anchors.verticalCenter: parent.verticalCenter; size: 44; icon: "bluetooth" }
        Column {
            anchors.left: offDisc.right; anchors.leftMargin: Theme.s3; anchors.right: parent.right; anchors.rightMargin: Theme.s3
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            StyledText { variant: "body"; font.weight: Theme.wMedium; text: "Bluetooth is off"; color: Theme.inkPrimary }
        }
    }

    // ── connected ──
    CcSheetBits.SectionLabel { text: "Connected"; opacity: (btSheet.on && btSheet.connectedCount > 0) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
    Column {
        visible: btSheet.on && btSheet.connectedCount > 0
        width: parent.width
        spacing: Theme.s1
        move: CcSheetBits.MoveSpring {}
        Repeater {
            model: connectedModel
            delegate: DeviceRow { required property var modelData; d: modelData; verb: "Disconnect"; onAct: modelData.disconnect() }
        }
    }

    // ── saved ──
    CcSheetBits.SectionLabel { text: "Saved"; opacity: (btSheet.on && btSheet.savedCount > 0) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
    Column {
        visible: btSheet.on && btSheet.savedCount > 0
        width: parent.width
        spacing: Theme.s1
        move: CcSheetBits.MoveSpring {}
        Repeater {
            model: savedModel
            delegate: DeviceRow { required property var modelData; d: modelData; verb: "Connect"; onAct: modelData.connect() }
        }
    }

    // ── nearby ──
    CcSheetBits.SectionLabel { text: "Nearby"; busy: btSheet.discovering; action: "Scan"; onActed: btSheet.setDiscovering(!btSheet.discovering); opacity: (btSheet.on) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
    Column {
        visible: btSheet.on && btSheet.nearbyCount > 0
        width: parent.width
        spacing: Theme.s1
        move: CcSheetBits.MoveSpring {}
        Repeater {
            model: nearbyModel
            delegate: DeviceRow { required property var modelData; d: modelData; verb: modelData.pairing ? "Cancel" : "Pair"; onAct: modelData.pairing ? modelData.cancelPair() : modelData.pair() }
        }
    }
}

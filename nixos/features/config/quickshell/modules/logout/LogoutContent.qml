import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Power menu that lives INSIDE the bar island (the island morphs into it, see Bar.qml).
// One quiet line about the session on top, then five discs with Lock in the middle, and
// under them the name of the one that is selected: one label on screen at a time.
// Lock is where the selection starts, so opening the menu and pressing Enter locks.
//
// Lock and Suspend act on a click or Enter. The three that end the session (Log Out,
// Reboot, Power Off) have to be HELD: a ring fills around the disc while the mouse button
// or Enter is down, the action fires when it closes, and letting go early springs it
// back. So one stray Enter can't nuke your session, and there is no "Confirm?" to read.
//
// Choosing Lock does not close the menu: the menu BECOMES the lock. The session locks at
// once, and the lock screen starts as a copy of this very menu at this very size
// (LockState.pillScreen / pillFrom). On that copy `locking` is set: everything but the
// lock glyph fades and the glyph rides to the middle while the lock screen pulls its
// island in around it, down to its own padlock pill.
//
// Logout exits Hyprland; suspend/reboot/poweroff shell out to systemctl.
Item {
    id: root

    property bool active: false
    // the screen this menu is on, and the height of the bar's resting pill: what the
    // island has to become before the lock screen can take it over
    property string screenName: ""
    property real pillH: 34

    readonly property var actions: [
        { id: "suspend",  label: "Suspend",   icon: "night",   hold: false },
        { id: "logout",   label: "Log Out",   icon: "logout",  hold: true  },
        { id: "lock",     label: "Lock",      icon: "lock",    hold: false },
        { id: "reboot",   label: "Reboot",    icon: "restart", hold: true  },
        { id: "poweroff", label: "Power Off", icon: "power",   hold: true  }
    ]
    readonly property int center: 2
    property int index: center
    onIndexChanged: letGo()

    // ── geometry ──
    readonly property real disc: 44
    readonly property real gap: 22
    readonly property real ring: 56               // the hold ring's box, around a disc
    readonly property real rowW: actions.length * disc + (actions.length - 1) * gap
    readonly property real lineH: 16
    // air inside the island, on top of the s4 the bar already leaves around every panel
    readonly property real padV: 10
    readonly property real padH: 62
    readonly property real rowY: padV + lineH + 14 + (ring - disc) / 2
    readonly property real labelY: padV + lineH + 14 + ring + 8
    readonly property real bodyH: labelY + lineH + padV
    // What the ISLAND should be (Bar reads these): the menu, or while locking the
    // lock screen's padlock pill, which is the same sum LockContent uses for its own.
    readonly property real pillW: 2 * Math.round((pillH + 22) / 2)
    readonly property real islandW: locking ? pillW : rowW + 2 * padH
    readonly property real islandH: locking ? pillH : bodyH + Theme.s4 * 2
    implicitHeight: bodyH

    function close() { GlobalState.logoutOpen = false; }

    function execute(id) {
        if (id === "logout")        Hyprland.dispatch("exit");
        else if (id === "suspend")  Quickshell.execDetached(["systemctl", "suspend"]);
        else if (id === "reboot")   Quickshell.execDetached(["systemctl", "reboot"]);
        else if (id === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    // ── hold to confirm ──
    // `hold` runs 0 -> 1 while the button or key is down. The fill is linear on purpose (a
    // countdown you can read); the way back is a quick ease.
    property real hold: 0
    readonly property bool holding: holdUp.running
    function press(i) {
        if (locking) return;
        const a = actions[i];
        if (!a) return;
        index = i;
        if (!a.hold) { activate(i); return; }
        holdDown.stop();
        holdUp.duration = Theme.reducedMotion ? 400 : Math.max(1, Math.round(900 * (1 - hold)));
        holdUp.restart();
    }
    function letGo() {
        if (!holdUp.running && hold === 0) return;
        holdUp.stop();
        holdDown.restart();
    }
    NumberAnimation {
        id: holdUp
        target: root; property: "hold"; to: 1
        onFinished: if (root.hold >= 1) { const a = root.actions[root.index]; root.hold = 0; root.execute(a.id); root.close(); }
    }
    NumberAnimation { id: holdDown; target: root; property: "hold"; to: 0; duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic }

    function activate(i) {
        const a = actions[i];
        if (!a || a.hold || locking) return;
        if (a.id === "lock") { lockNow(); return; }
        execute(a.id);
        close();
    }

    // ── the morph into the lock ──
    // `locking` (set from outside, on the lock screen's copy) fades the rest of the menu;
    // `lockT` carries the lock glyph from its disc to the middle of whatever the island
    // is shrinking to.
    property bool locking: false
    property real lockT: locking ? 1 : 0
    Behavior on lockT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    // Lock AT ONCE: the press and the locked session are the same instant, exactly like
    // the lock key. The lock screen is handed this island's size and starts as a copy of
    // this menu, which it then shrinks to the pill by setting `locking` on its copy. (The
    // first version played the shrink here and locked after it: a third of a second in
    // which the screen was not locked yet, and it felt slower than the lock key.)
    function lockNow() {
        letGo();
        LockState.lock(root.screenName, { w: islandW, h: islandH });
    }

    onActiveChanged: {
        if (active) {
            index = center;
            hold = 0;
            locking = false;
            uptimeFile.reload();
            Qt.callLater(() => keyCatcher.forceActiveFocus());
        } else {
            holdUp.stop();
        }
    }

    // ── the session line ──
    FileView { id: uptimeFile; path: "/proc/uptime"; blockLoading: true }
    readonly property string uptimeText: {
        const s = parseFloat(String(uptimeFile.text()).split(" ")[0]);
        if (!(s > 0)) return "";
        const m = Math.floor(s / 60), h = Math.floor(m / 60), d = Math.floor(h / 24);
        if (d > 0) return "Up " + d + " d " + (h % 24) + " h";
        if (h > 0) return "Up " + h + " h " + (m % 60) + " min";
        return "Up " + m + " min";
    }
    readonly property string sessionText: uptimeText

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: if (!root.locking) root.index = Math.max(0, root.index - 1)
        Keys.onRightPressed: if (!root.locking) root.index = Math.min(root.actions.length - 1, root.index + 1)
        // Enter and Space are a button: down starts (or acts), up lets go. Auto-repeat
        // is the same press still being held, not a new one.
        Keys.onPressed: event => {
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space) return;
            event.accepted = true;
            if (!event.isAutoRepeat) root.press(root.index);
        }
        Keys.onReleased: event => {
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space) return;
            event.accepted = true;
            if (!event.isAutoRepeat) root.letGo();
        }
    }

    // everything but the lock glyph: gone as the island pulls in
    readonly property real restOpacity: Math.max(0, 1 - lockT * 2.2)

    StyledText {
        id: sessionLine
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.padV
        height: root.lineH
        variant: "caption"
        text: root.sessionText
        color: Theme.inkDim
        opacity: root.restOpacity
    }

    Item {
        id: row
        width: root.rowW
        height: root.disc
        x: (parent.width - width) / 2
        // the row rides to the island's middle with the lock glyph; the content box
        // shrinks with the island, so "middle" is simply this item's parent's middle
        y: root.rowY + ((parent.height - root.disc) / 2 - root.rowY) * root.lockT

        Repeater {
            model: root.actions
            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool sel: index === root.index
                readonly property bool isLock: modelData.id === "lock"
                readonly property bool danger: modelData.hold
                // the lock's own disc and color melt away during the morph: what is left
                // is the lock screen's padlock, a 16px glyph in the island's ink
                readonly property real melt: isLock ? root.lockT : 0
                x: index * (root.disc + root.gap)
                width: root.disc
                height: root.disc
                opacity: isLock ? 1 : root.restOpacity

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: cell.sel ? (cell.danger ? Theme.alpha(Theme.bad, 0.22) : Theme.accent) : Theme.fillHigh
                    opacity: 1 - Math.min(1, cell.melt * 2.2)
                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                }
                Icon {
                    anchors.centerIn: parent
                    name: cell.modelData.icon
                    size: 20 - 4 * cell.melt
                    color: cell.melt > 0.5 ? Theme.inkPrimary
                         : cell.sel ? (cell.danger ? Theme.bad : Theme.onAccent) : Theme.inkPrimary
                }
                // the hold ring: grows clockwise from the top while the hold is on
                Shape {
                    anchors.centerIn: parent
                    width: root.ring; height: root.ring
                    visible: cell.sel && cell.danger && root.hold > 0
                    antialiasing: true
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Theme.bad
                        strokeWidth: 3
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: root.ring / 2; centerY: root.ring / 2
                            radiusX: root.ring / 2 - 2; radiusY: root.ring / 2 - 2
                            startAngle: -90
                            sweepAngle: 360 * root.hold
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Math.round(root.gap / 2)
                    enabled: !root.locking
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: if (!pressed) root.index = cell.index
                    onPressed: root.press(cell.index)
                    onReleased: root.letGo()
                    onCanceled: root.letGo()
                }
            }
        }
    }

    // The label under the discs: the name of what is selected, and "Keep holding to ..."
    // the instant a hold starts. It ROLLS on every change (the old line up and out, the new
    // one up from below), on the fast clock, so a press is answered within a few frames:
    // the label is the menu's way of saying "yes, that is being held".
    readonly property var cur: actions[index]
    readonly property string labelText: !cur ? "" : (cur.hold && (holding || hold > 0.02)) ? "Keep holding to " + cur.label.toLowerCase() : cur.label
    Item {
        id: tag
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.labelY
        width: parent.width
        height: root.lineH
        clip: true
        opacity: root.restOpacity
        // what is on screen; set by hand (a binding would follow labelText at once and
        // there would be nothing left to roll from)
        property string shown: ""
        Component.onCompleted: shown = root.labelText
        readonly property color ink: (root.cur && root.cur.hold) ? Theme.bad : Theme.inkPrimary
        Connections {
            target: root
            function onLabelTextChanged() {
                if (tag.shown === root.labelText) return;
                tagOut.text = tag.shown;
                tagOut.color = tagIn.color;
                tag.shown = root.labelText;
                tagRoll.restart();
            }
        }
        StyledText {
            id: tagIn
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            variant: "caption"; font.weight: Theme.wMedium
            text: tag.shown
            color: tag.ink
        }
        StyledText {
            id: tagOut
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            variant: "caption"; font.weight: Theme.wMedium
            opacity: 0
        }
        ParallelAnimation {
            id: tagRoll
            NumberAnimation { target: tagIn; property: "y"; from: tag.height * 0.7; to: 0; duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic }
            NumberAnimation { target: tagIn; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic }
            NumberAnimation { target: tagOut; property: "y"; from: 0; to: -tag.height * 0.7; duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic }
            NumberAnimation { target: tagOut; property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic }
        }
    }
}

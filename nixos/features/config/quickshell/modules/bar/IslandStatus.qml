import QtQuick
import "../../theme"
import "../../services"
import "../../components"
import "../../config"

// Battery and Wi-Fi in the pill's own vocabulary (the workspace capsules on the left):
// the network is the cellular glyph from the user's reference, four rising rounded bars,
// each lit once the signal clears its threshold, all faint when off or disconnected, all
// lit on a wired link; the battery is iOS 27's (the user's reference): a soft
// outline-less body, the charge a solid fill from the left, a bolt over it while charging.
//
// ONE set of glyphs with TWO homes, exactly the capsules' arrangement (IslandDots). At
// rest they sit in the pill, right of the time; in the open island they sit in the right
// column, a size up. Each element (the four bars, the battery) owns a clock `t` between
// the homes and glides from one to the other on its own spring, one after the other:
// the battery leads the way out and the signal follows, so the row visibly travels from
// the center to the right edge and back, retracting from its far end. The signal moves
// as ONE unit: its four bars gliding separately was too much motion to look at. The
// parent hands over both homes in ITS coordinate space (this item fills the parent); the
// spring's overshoot is the settle.
Item {
    id: root

    property bool open: false        // which home is current
    property bool restOn: true       // the rest home is wanted at all (pill glyphs enabled)
    property bool openOn: true       // the open home is wanted at all
    // rest home: the row's left edge and its vertical center, and the pill's sizes
    property real restX: 0
    property real restY: 0
    property real restCapH: 12
    property real restBarW: 3
    property real restGap: 7         // between the signal bars and the battery
    property real restBattW: 27
    property real restBattH: 13
    // open home, the same a size up
    property real openX: 0
    property real openY: 0
    property real openCapH: 17
    property real openBarW: 4
    property real openGap: 10
    property real openBattW: 36
    property real openBattH: 17
    readonly property real barGap: 1.5

    readonly property bool batt: Battery.available
    readonly property int count: 1 + (batt ? 1 : 0)
    // the capsules' gap: one element after another, fast
    property int stagger: Math.round(Math.min(Theme.stagger * 0.45, 220 / count))

    function barsW(bw) { return 4 * bw + 3 * barGap; }
    readonly property real restW: barsW(restBarW) + (batt ? restGap + restBattW + 3 : 0)
    readonly property real openW: barsW(openBarW) + (batt ? openGap + openBattW + 3 : 0)

    readonly property color lit: Theme.hue("status")
    // 0.16 (the empty capsule's trace) read as black on the signal bars: with no network
    // the glyph looked missing. The bars are thinner than a capsule, so they need more
    // alpha for the same presence.
    readonly property color faint: Theme.alpha(lit, Math.min(1, 0.34 * Theme.iconUnlit))
    readonly property bool wifiOn: Network.wifiEnabled && Network.isWifi && Network.connected
    readonly property bool wired: Network.isWired && Network.connected
    readonly property real signal: wifiOn ? Network.signalStrength : 0

    // ── one element with two homes ──
    component Glide: Item {
        id: el
        property int order: 0        // its turn on the way out; the reverse on the way home
        // 0 = at rest in the pill, 1 = in the open island
        property real t: 0
        Component.onCompleted: { t = root.open ? 1 : 0; entered = 1; }
        Connections {
            target: root
            function onOpenChanged() { glide.restart(); }
        }
        SequentialAnimation {
            id: glide
            PauseAnimation { duration: Theme.dur(root.stagger) * (root.open ? el.order : (root.count - 1 - el.order)) }
            NumberAnimation { target: el; property: "t"; to: root.open ? 1 : 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        }
        function mix(a, b) { return a + (b - a) * t; }
        // delegate-owned entrance (patterns.md #5), times the homes that are wanted: a
        // home that is off fades the element out on the way there
        property real entered: 0
        Behavior on entered { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        readonly property real tc: Math.max(0, Math.min(1, t))
        // the rest home coming and going (the pill hides the glyphs until it is
        // presented): each pops in on the spring as its room opens, the bars first then
        // the battery; they LEAVE at once on a short fade, ahead of the island's edge
        // closing over where they were. Opacity and a size pop ride one clock.
        property real restT: root.restOn ? 1 : 0
        Behavior on restT {
            SequentialAnimation {
                PauseAnimation { duration: root.restOn ? Theme.dur(root.stagger) * (root.count - 1 - el.order) : 0 }
                NumberAnimation {
                    duration: root.restOn ? Theme.dur(Theme.dSpring) : Theme.dur(Theme.dFast)
                    easing.type: Easing.Bezier
                    easing.bezierCurve: root.restOn ? Theme.springBezier : Theme.effectsBezier
                }
            }
        }
        opacity: entered * (Math.min(1, restT) * (1 - tc) + (root.openOn ? tc : 0))
        visible: opacity > 0.01
        transform: Scale { origin.x: el.width / 2; origin.y: el.height / 2; xScale: (0.55 + 0.45 * el.restT) * (1 - el.tc) + el.tc; yScale: xScale }
    }

    // ── the hover plate: one quiet fill behind the whole group (bars + battery), the
    // pill's own "this is pressable" cue; a click opens the control center. Sized from
    // the elements' live boxes so it follows them between the two homes.
    Rectangle {
        id: plate
        readonly property real padX: 6
        readonly property real padY: 4
        readonly property real edgeR: root.batt ? batt.x + batt.width : sig.x + sig.width
        x: sig.x - padX
        y: Math.min(sig.y, root.batt ? batt.y : sig.y) - padY
        width: edgeR - sig.x + 2 * padX
        height: Math.max(sig.height, root.batt ? batt.height : 0) + 2 * padY
        radius: height / 2
        color: plateMa.containsMouse ? Theme.fillLow : "transparent"   // the clock's hover fill; the capsules' plate matches
        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
        opacity: sig.opacity
        visible: sig.visible
        MouseArea {
            id: plateMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: GlobalState.toggleControlCenter()
        }
    }

    // ── signal: the cellular bars, four rising rounded bars, one unit ──
    Glide {
        id: sig
        order: root.batt ? 1 : 0          // after the battery
        readonly property real barW: mix(root.restBarW, root.openBarW)
        width: root.barsW(barW)
        height: mix(root.restCapH, root.openCapH)
        x: mix(root.restX, root.openX)
        y: mix(root.restY, root.openY) - height / 2
        Repeater {
            model: [ { h: 0.34, t: 0.01 }, { h: 0.56, t: 0.30 }, { h: 0.78, t: 0.55 }, { h: 1.00, t: 0.80 } ]
            delegate: Rectangle {
                required property var modelData
                required property int index
                x: index * (sig.barW + root.barGap)
                anchors.bottom: parent.bottom
                width: sig.barW
                height: Math.round(sig.height * modelData.h)
                radius: 1.2
                color: (root.wired || (root.wifiOn && root.signal >= modelData.t)) ? root.lit : root.faint
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dEffects) } }
            }
        }
    }

    // ── battery: iOS 27's, drawn by BatteryIcon ──
    Glide {
        id: batt
        order: 0
        visible: root.batt && opacity > 0.01
        readonly property real bodyW: mix(root.restBattW, root.openBattW)
        readonly property real bodyH: mix(root.restBattH, root.openBattH)
        // the LEVEL animates, not the fill's width: a Behavior on the width chased the
        // body as it resized between homes and the fill trailed the settle by its own
        // duration (seen: the charge creeping to its value a beat after the glide)
        property real level: Math.max(0, Math.min(1, Battery.percentage / 100))
        Behavior on level { NumberAnimation { duration: Theme.dur(Theme.dBase); easing.type: Theme.easeOut } }
        width: bodyW + 3
        height: bodyH
        x: mix(root.restX + root.barsW(root.restBarW) + root.restGap, root.openX + root.barsW(root.openBarW) + root.openGap)
        y: mix(root.restY, root.openY) - height / 2

        BatteryIcon {
            bodyWidth: batt.bodyW; bodyHeight: batt.bodyH
            level: batt.level
            charging: Battery.charging
            low: Battery.low
            tint: root.lit
        }
    }
}

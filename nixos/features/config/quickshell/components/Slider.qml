import QtQuick
import "../theme"

// Controlled horizontal slider. `value` is driven by the owner (bind it to a service
// property); a drag emits `moved(value)`. Do NOT bind value two-way: route `moved` to
// the service setter instead, or yer gonna get a feedback loop.
//
// Two looks, picked by how many values there are to choose from:
//   a FILL for anything continuous: a thick sunken track and an accent fill whose right
//     edge is the thing you drag, marked with a small grab bar. No knob floating on a
//     line; the whole band is the control, the way the control center's sliders are.
//   STEPS for a handful of whole values (`step` set and no more than `maxSteps` of them):
//     a dot for every choice and a disc on the one you are on, which snaps from dot to
//     dot. A weekday or a column count is not a point on a line, and a fill made it
//     look like one.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    // the size of one notch; 0 = continuous
    property real step: 0
    readonly property int maxSteps: 12
    signal moved(real value)

    readonly property int stepCount: step > 0 ? Math.round((to - from) / step) : 0
    readonly property bool stepped: stepCount >= 1 && stepCount <= maxSteps

    implicitWidth: 200
    implicitHeight: stepped ? 24 : 20

    readonly property real ratio: to === from ? 0 : Math.max(0, Math.min(1, (value - from) / (to - from)))
    // which notch the value is on, when stepped
    readonly property int at: stepped ? Math.round(ratio * stepCount) : 0

    function applyAt(px) {
        if (stepped) {
            const i = Math.max(0, Math.min(stepCount, Math.round((px - dotInset) / dotPitch)));
            const v = from + i * step;
            if (v !== value) root.moved(v);
            return;
        }
        const r = Math.max(0, Math.min(1, px / width));
        root.moved(from + r * (to - from));
    }

    // ── the fill ──
    Rectangle {
        id: track
        visible: !root.stepped
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 20
        radius: 7
        color: Theme.sunken

        Rectangle {
            id: fill
            // never narrower than its own grab bar needs: at zero there is still an edge
            // to take hold of
            width: Math.max(18, parent.width * root.ratio)
            height: parent.height
            radius: parent.radius
            color: ma.pressed ? Qt.lighter(Theme.accent, 1.08) : Theme.accent
            Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
            // the grab bar: it stands a little taller while the slider is held
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: ma.pressed ? 13 : 10
                radius: 1.5
                color: Theme.onAccent
                opacity: 0.7
                Behavior on height { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Theme.easeOut } }
            }
        }
    }

    // ── the steps ──
    readonly property real dotInset: 12
    readonly property real dotPitch: stepCount > 0 ? (width - 2 * dotInset) / stepCount : 0
    Rectangle {
        id: rail
        visible: root.stepped
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 24
        radius: 12
        color: Theme.sunken

        // a soft tint from the start to the disc, so "how far along" still reads
        Rectangle {
            height: parent.height
            radius: parent.radius
            width: disc.x + disc.width / 2 + root.dotInset
            color: Theme.alpha(Theme.accent, 0.28)
        }
        Repeater {
            model: root.stepped ? root.stepCount + 1 : 0
            delegate: Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: 4; height: 4; radius: 2
                x: root.dotInset + index * root.dotPitch - width / 2
                color: index <= root.at ? Theme.accent : Theme.inkFaint
            }
        }
        Rectangle {
            id: disc
            anchors.verticalCenter: parent.verticalCenter
            width: ma.pressed ? 18 : 16
            height: width
            radius: width / 2
            x: root.dotInset + root.at * root.dotPitch - width / 2
            color: Theme.accent
            Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
            Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Theme.easeOut } }
        }
    }

    // Hit area, a little TALLER than the track: grabbing a slider shouldn't need careful
    // aim. Extends `grab` px above and below the item (a MouseArea may spill past its
    // parent as long as nothing clips it), so the whole band around the track drags.
    //
    // It does NOT take the wheel. It used to, so scrolling a page of sliders changed
    // whichever one happened to pass under the pointer. The wheel is left to the page.
    readonly property int grab: 6

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.topMargin: -root.grab
        anchors.bottomMargin: -root.grab
        cursorShape: Qt.PointingHandCursor
        onPressed: root.applyAt(mouseX)
        onPositionChanged: if (pressed) root.applyAt(mouseX)
        onWheel: wheel => { wheel.accepted = false; }
    }
}

import QtQuick
import QtQuick.Effects
import "../theme"

// The battery, iOS 27's: a soft rounded body with no outline, a translucent track in the
// tint, the charge a solid fill from the left ending in a straight edge (clipped to the
// body's corners by a mask, not by `clip`, which would square them), a small terminal
// past the right end, no number. The tint while discharging; green while charging; red
// when low.
//
// The charging bolt is a KNOCKOUT, not one color: a copy in the tint shows over the
// empty part of the track, and a copy in the fill's own contrast ink is clipped to the
// fill's width and shows over the charge. One color was tried and failed both ways:
// the ink picked for the accent went black over the dark track at a low level, and a
// light bolt vanishes over a light green fill.
//
// This is the one battery drawing in the shell: the island's status row, the lock
// screen's corner and the Bluetooth sheet's device rows all draw it at their own size.
Item {
    id: root

    property real level: 1.0          // 0..1, drawn continuously
    property bool charging: false
    property bool low: false
    property color tint: Theme.inkPrimary
    property real bodyWidth: 27
    property real bodyHeight: 13

    readonly property real frac: Math.max(0, Math.min(1, level))
    readonly property real corner: bodyHeight * 0.35
    readonly property color fillColor: low ? Theme.bad : charging ? Theme.good : tint
    readonly property int boltSize: Math.round(bodyHeight * 0.7)

    implicitWidth: bodyWidth + 3
    implicitHeight: bodyHeight

    // The body: the translucent track, and over it the charge. The charge is the body's
    // own rounded shape again in the fill color, shown only as far as the level by a
    // plain clip, so its left end has the body's real, antialiased corners and its right
    // end is the straight edge. (This used to be one layer cut to the corners by a
    // thresholded mask. A mask's edge is a cutoff, not a curve: the rounded left end came
    // out stair-stepped, most visibly on a scaled screen.) The clip is a pixel bigger than
    // the body on the left, top and bottom, so it never trims the soft edge of the curve.
    Rectangle {
        id: body
        width: root.bodyWidth; height: root.bodyHeight; radius: root.corner
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.alpha(root.tint, 0.22)
        antialiasing: true
        Item {
            x: -1; y: -1
            width: parent.width * root.frac + 1
            height: parent.height + 2
            clip: true
            Rectangle {   // the charge
                x: 1; y: 1
                width: body.width; height: body.height; radius: root.corner
                antialiasing: true
                color: root.fillColor
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
            }
        }
    }

    // the bolt, fading in over the fill rather than popping
    Item {
        id: bolt
        anchors.fill: body
        opacity: root.charging ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        visible: opacity > 0
        Icon {        // over the track
            anchors.centerIn: parent
            name: "bolt"; size: root.boltSize
            color: root.tint
        }
        Item {        // over the charge: clipped to the fill's width, centered on the body
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: body.width * root.frac
            clip: true
            Icon {
                x: (body.width - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                name: "bolt"; size: root.boltSize
                color: Theme.inkOn(root.fillColor)
            }
        }
    }

    Rectangle {   // terminal
        anchors.left: body.right; anchors.leftMargin: 1
        anchors.verticalCenter: body.verticalCenter
        // sized off the body, so on a small battery it is a small nub and not a 2px
        // bar that reads as a broken-off piece
        width: Math.max(1.5, root.bodyHeight * 0.15); height: Math.max(3, Math.round(root.bodyHeight * 0.42)); radius: width / 2
        antialiasing: true
        color: Theme.alpha(root.tint, 0.40)
    }
}

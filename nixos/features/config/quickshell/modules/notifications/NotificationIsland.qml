import QtQuick
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../config"

// Notification content that lives INSIDE the bar island. The island morphs to show this,
// then snaps back (see Bar.qml). Compact: app-icon badge, app name, summary, body.
// `notif` is the one to display. Click dismisses the popup but keeps it in history;
// hovering pauses the auto-dismiss countdown so it won't vanish while you're reading it.
//
// What is drawn is not `notif` itself but a copy of what it says (`cur`), and one of the
// notification before it (`old`). When another notification takes the island while one is
// up, the two ROLL, the way the clock's digits do: the old one travels up and fades, the
// new one rises into its place. It used to be one set of labels bound straight to
// `notif`, so the next notification simply overwrote the last, and the text blanked the
// instant the popup started to leave. The copies also outlive the notification: the
// island fades out still showing what it was showing.
Item {
    id: root

    property var notif: null
    implicitHeight: Math.max(40, curFace.implicitHeight)
    clip: roll.running

    function read(n) {
        return {
            icon: n.appIcon ? Quickshell.iconPath(n.appIcon, "dialog-information") : (n.image || ""),
            app: n.appName || "",
            summary: n.summary || "",
            body: n.body ? Notifications.markup(n.body) : ""
        };
    }
    readonly property var blank: ({ icon: "", app: "", summary: "", body: "" })
    property var cur: blank
    property var old: blank
    property var curId: -1
    onNotifChanged: {
        if (!notif) return;                     // leaving: keep what is on the face
        if (notif.id === curId) { cur = read(notif); return; }
        const wasUp = curId !== -1 && opacity > 0.05;
        old = cur;
        cur = read(notif);
        curId = notif.id;
        if (wasUp) roll.restart();
    }
    // nothing has been up for a while: the next one arrives on a clean face, no roll
    onVisibleChanged: if (!visible) { curId = -1; roll.stop(); oldFace.opacity = 0; oldFace.shift = 0; curFace.opacity = 1; curFace.shift = 0; }

    ParallelAnimation {
        id: roll
        // incoming: rises from below into place
        NumberAnimation { target: curFace; property: "shift"; from: root.height * 0.55; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        NumberAnimation { target: curFace; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
        // outgoing: keeps traveling up and out
        NumberAnimation { target: oldFace; property: "shift"; from: 0; to: -root.height * 0.55; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        NumberAnimation { target: oldFace; property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
    }

    // ── the outgoing face ──
    Item {
        id: oldFace
        width: parent.width
        height: Math.max(40, oldCol.implicitHeight)
        property real shift: 0
        y: (root.height - height) / 2 + shift
        opacity: 0
        visible: opacity > 0
        Rectangle {
            id: oldBadge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; radius: 20
            color: Theme.fillHigh
            clip: true
            Image {
                anchors.fill: parent; anchors.margins: 7
                source: root.old.icon; visible: source != ""
                sourceSize.width: 28; sourceSize.height: 28
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            StyledText {
                anchors.centerIn: parent
                visible: root.old.icon === ""
                variant: "label"; font.weight: Theme.wMedium
                text: root.old.app ? root.old.app.charAt(0).toUpperCase() : "!"
                color: Theme.accent
            }
        }
        Column {
            id: oldCol
            anchors.left: oldBadge.right
            anchors.leftMargin: Theme.s3
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "caption"; visible: text !== ""; text: root.old.app; color: Theme.inkDim }
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "label"; font.weight: Theme.wMedium; text: root.old.summary; color: Theme.inkPrimary }
            StyledText { width: parent.width; elide: Text.ElideRight; variant: "caption"; visible: Config.notifShowBody && root.old.body !== ""; text: root.old.body; textFormat: Text.StyledText; color: Theme.inkDim }
        }
    }

    // ── the face that is up ──
    Item {
        id: curFace
        width: parent.width
        height: Math.max(40, ncol.implicitHeight)
        implicitHeight: height
        property real shift: 0
        y: (root.height - height) / 2 + shift

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; radius: 20
            color: Theme.fillHigh
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 7
                source: root.cur.icon
                visible: source != ""
                sourceSize.width: 28
                sourceSize.height: 28
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            // letter-avatar fallback for apps that can't be bothered to send an icon
            StyledText {
                anchors.centerIn: parent
                visible: root.cur.icon === ""
                variant: "label"
                font.weight: Theme.wMedium
                text: root.cur.app ? root.cur.app.charAt(0).toUpperCase() : "!"
                color: Theme.accent
            }
        }

        Column {
            id: ncol
            anchors.left: badge.right
            anchors.leftMargin: Theme.s3
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            StyledText {
                width: parent.width
                elide: Text.ElideRight
                variant: "caption"
                visible: text !== ""
                text: root.cur.app
                color: Theme.inkDim
            }
            StyledText {
                width: parent.width
                elide: Text.ElideRight
                variant: "label"
                font.weight: Theme.wMedium
                text: root.cur.summary
                color: Theme.inkPrimary
            }
            StyledText {
                width: parent.width
                elide: Text.ElideRight
                variant: "caption"
                visible: Config.notifShowBody && root.cur.body !== ""
                text: root.cur.body
                textFormat: Text.StyledText
                color: Theme.inkDim
            }
        }
    }

    // click dismisses the popup (history keeps it); hover pauses the countdown
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: Notifications.popupHovered = true
        onExited: Notifications.popupHovered = false
        onClicked: if (root.notif) Notifications.hidePopup(root.notif)
    }
}

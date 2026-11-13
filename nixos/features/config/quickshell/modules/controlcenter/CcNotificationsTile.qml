import QtQuick
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Notification history as a card. Always full width; its HEIGHT is the size lever (1 to
// 4 rows): a header row with "Clear all", then as much of the list as fits, clipped.
//
// The list is grouped by app. Each app is ONE rounded block: its badge and name, how
// long ago its newest message came, and its messages as lines under the name ("Mika  are
// we still on for tonight?"). An app with one message is a pill; a chatty one is a taller
// block with a count, not a wall of rows. A block with something in it you have not seen
// yet carries a dot; one with an urgent message is tinted red.
//
// A block with more than one message OPENS on a click: its lines become rows of their
// own, each with its age. A click on anything with nothing to open (a block with one
// message, or a row in an open block) dismisses it. Anything can also be thrown away by
// sliding it sideways: a block (that app, all of it) or a single row. Hovering shows a
// close mark in place of the age. However it goes, it goes by sliding out.
//
// With nothing to show the card says so properly: a bell, "All caught up", and since when;
// or, with Focus on, that it is on and that things still land here.
Item {
    id: tile

    property var ctl: null
    readonly property bool interactive: ctl ? ctl.interactive : true

    // the clock the ages are read against: now when the control center opens, then every
    // half minute while it stays open
    property real now: Date.now()
    Timer { interval: 30000; repeat: true; running: GlobalState.controlCenterOpen; onTriggered: tile.now = Date.now() }
    Connections {
        target: GlobalState
        function onControlCenterOpenChanged() {
            if (GlobalState.controlCenterOpen) tile.now = Date.now();
            else Notifications.markSeen();      // seen once: the dots are gone next time
        }
    }
    function esc(t) { return String(t || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
    function lineText(n) {
        return "<font color=\"" + Theme.inkPrimary + "\">" + esc(n.summary) + "</font>"
             + ((n.body || "") !== "" ? "&nbsp;&nbsp;" + Notifications.markup(n.body) : "");
    }
    // which apps are open, by name. Kept here, not in the block: it has to outlive the
    // block being rebuilt.
    property var open: ({})
    // Notifications that are on their way out, by id. The moment one is sent off it stops
    // counting: its block resizes, recounts and re-reads its lines at once, while the row
    // itself is still sliding away. (It used to count until it was really gone, so the
    // card sat still for the whole slide and only then reacted.)
    property var leaving: ({})
    function setLeaving(id, on) {
        const o = Object.assign({}, leaving);
        if (on) o[id] = true; else delete o[id];
        leaving = o;
    }
    // how long anything takes to leave: slide, fade and close-up run together over this
    // (the fade is linear on purpose: eased out, it was gone before the slide could be seen)
    readonly property int outMs: Theme.dur(Theme.dFast) + 60
    function toggle(app) { const o = Object.assign({}, open); o[app] = !o[app]; open = o; }
    function groupOf(app) { return Notifications.groups.find(g => g.app === app) || null; }

    // The list's model is the app NAMES, diffed by value, and each block looks its group
    // up. A model of the group objects themselves is a new set of objects on every change,
    // which rebuilt every block each time one notification came or went: nothing could
    // slide, collapse or stay open across that.
    ScriptModel { id: appModel; values: Notifications.groups.map(g => g.app) }

    // sliding something past this much of its width on release throws it away
    readonly property real flick: 0.3

    Rectangle {
        anchors.fill: parent
        radius: Theme.rXl
        color: Theme.surfaceOverlay
    }

    // Hairline rim (Tahoe's glass edge, without the glass): a 1px stroke in the ink color at
    // hairline alpha, drawn ON TOP so hover veils and album art never soften it. It is what
    // separates a tile from the black island without any glow.
    Rectangle {
        anchors.fill: parent
        radius: Theme.rXl
        color: "transparent"
        border.width: 1
        border.color: Theme.rim
        z: 5
    }

    Item {
        id: head
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: Theme.s3; leftMargin: Theme.s4; rightMargin: Theme.s4 }
        height: 18
        // Nothing in this card just appears or vanishes: `visible` follows the opacity,
        // never the state, so a thing that is leaving fades out before it is gone. (The
        // header used to cut out the instant the last notification left.)
        opacity: Notifications.count > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        visible: opacity > 0
        StyledText {
            anchors.left: parent.left; capCenterIn: parent
            variant: "caption"; text: "Notifications"; color: Theme.inkDim
        }
        StyledText {
            anchors.right: parent.right; capCenterIn: parent
            variant: "caption"; text: "Clear all"; color: clearMa.containsMouse ? Theme.accent : Theme.inkDim
            Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
            MouseArea { id: clearMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; enabled: tile.interactive && Notifications.count > 0; cursorShape: Qt.PointingHandCursor; onClicked: Notifications.clearAll() }
        }
    }

    // ── nothing to show ──
    // Centered in the whole card. A short card (one grid row) has room for the bell and the
    // one line beside it; a taller one stacks them and adds since when.
    Item {
        id: emptyState
        anchors.fill: parent
        opacity: Notifications.count === 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        visible: opacity > 0
        readonly property bool roomy: height >= 124
        // With Focus (do not disturb) on, the empty card says THAT, not "all caught up":
        // nothing is popping up, but anything that arrives still lands here. The disc
        // takes the toggle's lit look, and the bell and the two lines cross-fade with the
        // Focus glyph and its own two lines.
        readonly property bool quiet: GlobalState.dnd
        readonly property string title: quiet ? "Focus is on" : "All caught up"
        Column {
            visible: parent.roomy
            anchors.centerIn: parent
            spacing: Theme.s2 + 2
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44; height: 44; radius: 22
                color: emptyState.quiet ? Theme.alpha(Theme.accent, 0.2) : Theme.fillHigh
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dEffects) } }
                Icon { anchors.centerIn: parent; name: "bell"; size: 20; color: Theme.inkDim; opacity: emptyState.quiet ? 0 : 1; scale: emptyState.quiet ? 0.6 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
                Icon { anchors.centerIn: parent; name: "dnd"; size: 20; color: Theme.accent; opacity: emptyState.quiet ? 1 : 0; scale: emptyState.quiet ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
            }
            // the two lines, each a pair stacked in one box: the one that applies is up
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(t1a.implicitWidth, t1b.implicitWidth, t2a.implicitWidth, t2b.implicitWidth)
                height: t1a.implicitHeight + 2 + t2a.implicitHeight
                StyledText { id: t1a; anchors.horizontalCenter: parent.horizontalCenter; variant: "label"; font.weight: Theme.wMedium; text: "All caught up"; color: Theme.inkPrimary
                    opacity: emptyState.quiet ? 0 : 1; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
                StyledText { id: t1b; anchors.horizontalCenter: parent.horizontalCenter; variant: "label"; font.weight: Theme.wMedium; text: "Focus is on"; color: Theme.inkPrimary
                    opacity: emptyState.quiet ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
                StyledText { id: t2a; anchors.horizontalCenter: parent.horizontalCenter; y: t1a.implicitHeight + 2; variant: "caption"; color: Theme.inkDim
                    text: "Nothing new since " + Qt.formatTime(new Date(Notifications.quietSince), Config.clock24h ? "HH:mm" : "h:mm AP")
                    opacity: emptyState.quiet ? 0 : 1; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
                StyledText { id: t2b; anchors.horizontalCenter: parent.horizontalCenter; y: t1a.implicitHeight + 2; variant: "caption"; color: Theme.inkDim
                    text: "Notifications arrive here quietly"
                    opacity: emptyState.quiet ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
            }
        }
        Row {
            visible: !parent.roomy
            anchors.centerIn: parent
            spacing: Theme.s3
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: emptyState.quiet ? Theme.alpha(Theme.accent, 0.2) : Theme.fillHigh
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dEffects) } }
                Icon { anchors.centerIn: parent; name: emptyState.quiet ? "dnd" : "bell"; size: 15; color: emptyState.quiet ? Theme.accent : Theme.inkDim }
            }
            StyledText { anchors.verticalCenter: parent.verticalCenter; variant: "label"; font.weight: Theme.wMedium; text: emptyState.title; color: Theme.inkPrimary }
        }
    }

    ListView {
        id: list
        anchors { top: head.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: Theme.s2 + 2; leftMargin: Theme.s3; rightMargin: Theme.s3; bottomMargin: Theme.s3 }
        clip: true
        spacing: Theme.s1 + 2
        model: appModel
        boundsBehavior: Flickable.StopAtBounds
        interactive: tile.interactive && Notifications.count > 0
        // a block that goes without being slid away ("Clear all", or its app closing it)
        // fades and eases back; the blocks under one that has gone close up on the spring
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                NumberAnimation { property: "scale"; to: 0.96; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
            }
        }
        removeDisplaced: Transition { NumberAnimation { properties: "y"; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        addDisplaced: Transition { NumberAnimation { properties: "y"; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        delegate: Item {
            id: block
            required property string modelData
            readonly property var g: tile.groupOf(modelData)
            readonly property var all: g ? g.items : []
            readonly property var items: all.filter(n => !tile.leaving[n.id])
            readonly property var newest: items.length > 0 ? items[0] : null
            readonly property bool crit: g ? g.crit : false
            readonly property bool many: items.length > 1
            readonly property bool isOpen: many && tile.open[modelData] === true
            readonly property int maxLines: 4
            readonly property int shownLines: Math.min(items.length, maxLines)
            readonly property bool more: items.length > maxLines
            readonly property bool unread: items.some(n => Notifications.isUnread(n))
            readonly property real lineH: 18
            readonly property real rowH: 32
            // hovered anywhere on it: its own area, its close mark, or a row inside it
            property int rowsHovered: 0
            readonly property bool hot: blockMa.containsMouse || closeMa.containsMouse || rowsHovered > 0

            width: ListView.view.width
            // closed with one line this is exactly a 54px pill; open, a row per message
            property real baseH: isOpen ? 32 + items.length * rowH + 8
                                        : 28 + (Math.max(1, shownLines) + (more ? 1 : 0)) * lineH + 8
            Behavior on baseH { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
            // 1 normally; run to 0 as the block is sent off, so the blocks under it close
            // up WHILE it slides and fades, not after
            property real fold: 1
            height: baseH * fold
            clip: fold < 1
            // delegate-owned entrance (patterns.md #5)
            opacity: entered
            property real entered: 0
            Component.onCompleted: entered = 1
            Behavior on entered { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

            readonly property string nIcon: !newest ? ""
                : newest.appIcon ? Quickshell.iconPath(newest.appIcon, "dialog-information")
                : (newest.image || "")

            // throw the whole block away: slide it out the way it was going, then dismiss
            // what is in it (the list closes the gap)
            // throw the whole block away: it slides the way it was going, fades and
            // closes up, all at once, and then what is in it is dismissed
            function sendOff(dir) {
                if (slideOut.running) return;
                slideBack.stop();
                slideOutX.to = slab.x + dir * width * 0.5;
                slideOut.start();
            }
            ParallelAnimation {
                id: slideOut
                NumberAnimation { id: slideOutX; target: slab; property: "x"; duration: tile.outMs; easing.type: Easing.OutCubic }
                NumberAnimation { target: slab; property: "fade"; to: 0; duration: tile.outMs }
                NumberAnimation { target: block; property: "fold"; to: 0; duration: tile.outMs; easing.type: Easing.OutCubic }
                onFinished: { for (const n of block.all.slice()) Notifications.dismiss(n); }
            }
            NumberAnimation { id: slideBack; target: slab; property: "x"; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }

            // everything visible rides on this, so the whole block slides as one
            Item {
                id: slab
                width: parent.width
                height: block.baseH
                // dims as it is dragged aside, and `fade` takes it the rest of the way
                // out when it is let go of for good
                property real fade: 1
                opacity: (1 - Math.min(1, Math.abs(x) / Math.max(1, width)) * 0.6) * fade

                Rectangle {
                    anchors.fill: parent
                    radius: 27
                    color: block.crit ? Theme.alpha(Theme.bad, block.hot ? 0.22 : 0.16)
                                      : (block.hot ? Theme.fillHigh : Theme.fillLow)
                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                }

                Rectangle {
                    id: nbadge
                    x: 11; y: 11
                    width: 32; height: 32; radius: 16
                    color: block.crit ? Theme.alpha(Theme.bad, 0.2)
                         : block.nIcon !== "" ? Theme.fillHigh : Theme.alpha(Theme.accent, 0.18)
                    clip: true
                    Image {
                        anchors.fill: parent; anchors.margins: 5
                        source: block.nIcon; visible: source != ""
                        sourceSize.width: 24; sourceSize.height: 24
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    StyledText {
                        anchors.centerIn: parent
                        visible: block.nIcon === ""
                        variant: "caption"
                        font.weight: Theme.wMedium
                        text: (block.modelData || "?").charAt(0).toUpperCase()
                        color: block.crit ? Theme.bad : Theme.accent
                    }
                }

                // the app's name, and on the right what there is to know about the block:
                // how many, how long ago, unread or not. Hover swaps the age and dot for a
                // close mark (drawn here, pressed through closeMa above the block's area).
                Item {
                    id: top
                    x: 54; y: 8
                    width: parent.width - 54 - 18
                    height: 20
                    StyledText {
                        anchors.left: parent.left; anchors.right: side.left; anchors.rightMargin: Theme.s2
                        capCenterIn: parent
                        elide: Text.ElideRight
                        variant: "label"; font.weight: Theme.wMedium
                        text: block.modelData
                        color: block.crit ? Theme.bad : Theme.inkPrimary
                    }
                    Row {
                        id: side
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.s2
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: block.many ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                            visible: opacity > 0
                            // On hover the age and the dot fade away and the close mark takes
                            // the row's end. The count moves over into the room they leave, up
                            // against the close mark, on the same clock as their fade, so it
                            // is already on its way the moment they start to go. Without this
                            // it stayed put with a hole between it and the mark.
                            readonly property real hoverShift: ageText.width + side.spacing
                                + (unreadDot.visible ? unreadDot.width + side.spacing : 0)
                                - (closeMark.implicitWidth + side.spacing)
                            transform: Translate {
                                x: block.hot ? Math.max(0, countPill.hoverShift) : 0
                                Behavior on x { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                            }
                            id: countPill
                            width: Math.max(20, cnt.implicitWidth + 12); height: 17; radius: 8.5
                            color: block.crit ? Theme.alpha(Theme.bad, 0.22) : Theme.alpha(Theme.accent, 0.2)
                            StyledText { id: cnt; anchors.centerIn: parent; variant: "caption"; font.weight: Theme.wMedium; text: block.items.length; color: block.crit ? Theme.bad : Theme.accent }
                        }
                        StyledText {
                            id: ageText
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: block.hot ? 0 : 1
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                            variant: "caption"
                            text: block.newest ? Notifications.ago(Notifications.arrived[block.newest.id], tile.now) : ""
                            color: Theme.inkFaint
                        }
                        Rectangle {
                            id: unreadDot
                            anchors.verticalCenter: parent.verticalCenter
                            visible: block.unread
                            opacity: block.hot ? 0 : 1
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                            width: 7; height: 7; radius: 3.5
                            color: block.crit ? Theme.bad : Theme.accent
                        }
                    }
                    // the close mark fades in over the age and the dot, at the row's end
                    StyledText {
                        id: closeMark
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: block.hot ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                        visible: opacity > 0
                        text: "✕"
                        color: closeMa.containsMouse ? Theme.inkPrimary : Theme.inkDim
                    }
                }

                // closed: the messages as lines, who or what in the primary ink, then the text
                Column {
                    x: 54; y: 28
                    width: parent.width - 54 - 18
                    visible: opacity > 0
                    opacity: block.isOpen ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast) } }
                    Repeater {
                        model: block.items.slice(0, block.shownLines)
                        delegate: StyledText {
                            required property var modelData
                            width: parent.width
                            height: block.lineH
                            elide: Text.ElideRight
                            variant: "caption"
                            textFormat: Text.StyledText
                            text: tile.lineText(modelData)
                            color: Theme.inkDim
                        }
                    }
                    StyledText {
                        opacity: block.more ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                        visible: opacity > 0
                        height: block.lineH
                        variant: "caption"
                        text: "+" + (block.items.length - block.maxLines) + " more"
                        color: Theme.inkFaint
                    }
                }

                // The block's own area: hover, the click that opens it, and the sideways
                // slide. It sits OVER the text (a styled Text takes hover for itself, which
                // is why hovering a line used to drop the highlight) and UNDER the close
                // mark's area and the open rows, which have their own.
                MouseArea {
                    id: blockMa
                    anchors.fill: parent
                    enabled: tile.interactive
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    drag.target: slab
                    drag.axis: Drag.XAxis
                    drag.threshold: 8
                    property bool slid: false
                    onPressed: { slid = false; slideBack.stop(); }
                    onPositionChanged: if (drag.active) slid = true
                    onReleased: {
                        if (Math.abs(slab.x) > slab.width * tile.flick) block.sendOff(slab.x > 0 ? 1 : -1);
                        else if (slab.x !== 0) slideBack.restart();
                    }
                    onCanceled: slideBack.restart()
                    // a click opens a block that has more than one message in it; one
                    // that has nothing to open is dismissed, sliding out like any other
                    onClicked: {
                        if (slid) return;
                        if (block.many) tile.toggle(block.modelData);
                        else block.sendOff(1);
                    }
                }
                MouseArea {
                    id: closeMa
                    x: top.x + top.width - 22; y: 0
                    width: 40; height: 36
                    visible: block.hot
                    enabled: tile.interactive
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: block.sendOff(1)
                }

                // open: a row per message, each one its own thing to hover, click, close
                // or slide. The rows live in the text column, to the right of the badge:
                // their hover pill starts just left of the text and never runs under the
                // badge, and the text stays on the same left edge as the app's name.
                Column {
                    x: 44; y: 32
                    width: parent.width - 44 - 8
                    visible: opacity > 0
                    opacity: block.isOpen ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                    Repeater {
                        // every message of the app, the ones on their way out included:
                        // they are still here to finish sliding
                        model: ScriptModel { values: (block.isOpen || block.all.length !== block.items.length) ? block.all : [] }
                        delegate: Item {
                            id: row
                            required property var modelData
                            width: parent.width
                            // closes up as the row slides and fades, in the same motion
                            property real fold: 1
                            height: block.rowH * fold
                            clip: fold < 1
                            readonly property bool hot: rowMa.containsMouse || rowCloseMa.containsMouse
                            onHotChanged: block.rowsHovered += hot ? 1 : -1
                            // taken apart while hovered: give the count back. Taken apart
                            // while still on its way out (its block closed under it): it
                            // is dismissed all the same.
                            Component.onDestruction: {
                                if (hot) block.rowsHovered -= 1;
                                if (sent && rowOut.running) finish();
                            }

                            // slide, fade and close up together; it stops counting for
                            // the block right away (tile.leaving) and is dismissed at the end
                            property bool sent: false
                            readonly property var note: modelData
                            function sendOff(dir) {
                                if (sent) return;
                                sent = true;
                                rowBack.stop();
                                tile.setLeaving(note.id, true);
                                rowOutX.to = rowSlab.x + dir * width * 0.5;
                                rowOut.start();
                            }
                            function finish() {
                                const n = note, id = n.id;
                                Notifications.dismiss(n);
                                tile.setLeaving(id, false);
                            }
                            ParallelAnimation {
                                id: rowOut
                                NumberAnimation { id: rowOutX; target: rowSlab; property: "x"; duration: tile.outMs; easing.type: Easing.OutCubic }
                                NumberAnimation { target: rowSlab; property: "fade"; to: 0; duration: tile.outMs }
                                NumberAnimation { target: row; property: "fold"; to: 0; duration: tile.outMs; easing.type: Easing.OutCubic }
                                onFinished: row.finish()
                            }
                            NumberAnimation { id: rowBack; target: rowSlab; property: "x"; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }

                            Item {
                                id: rowSlab
                                width: parent.width
                                height: block.rowH
                                property real fade: 1
                                opacity: (1 - Math.min(1, Math.abs(x) / Math.max(1, width)) * 0.6) * fade
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: 1; anchors.bottomMargin: 1
                                    radius: height / 2
                                    color: row.hot ? Theme.fillHigh : "transparent"
                                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                                }
                                StyledText {
                                    x: 10
                                    width: parent.width - 10 - 44
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    variant: "caption"
                                    textFormat: Text.StyledText
                                    text: tile.lineText(row.modelData)
                                    color: Theme.inkDim
                                }
                                StyledText {
                                    anchors.right: parent.right; anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: row.hot ? 0 : 1
                                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                                    variant: "caption"
                                    text: Notifications.ago(Notifications.arrived[row.modelData.id], tile.now)
                                    color: Theme.inkFaint
                                }
                                StyledText {
                                    anchors.right: parent.right; anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    opacity: row.hot ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic } }
                                    visible: opacity > 0
                                    text: "✕"
                                    color: rowCloseMa.containsMouse ? Theme.inkPrimary : Theme.inkDim
                                }
                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    enabled: tile.interactive && block.isOpen
                                    hoverEnabled: true
                                    drag.target: rowSlab
                                    drag.axis: Drag.XAxis
                                    drag.threshold: 8
                                    cursorShape: Qt.PointingHandCursor
                                    property bool slid: false
                                    onPressed: { slid = false; rowBack.stop(); }
                                    onPositionChanged: if (drag.active) slid = true
                                    onReleased: {
                                        if (Math.abs(rowSlab.x) > rowSlab.width * tile.flick) row.sendOff(rowSlab.x > 0 ? 1 : -1);
                                        else if (rowSlab.x !== 0) rowBack.restart();
                                    }
                                    onCanceled: rowBack.restart()
                                    onClicked: if (!slid) row.sendOff(1)
                                }
                                MouseArea {
                                    id: rowCloseMa
                                    anchors.right: parent.right
                                    width: 40; height: parent.height
                                    visible: row.hot
                                    enabled: tile.interactive && block.isOpen
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: row.sendOff(1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

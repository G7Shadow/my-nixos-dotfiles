import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Wallpaper picker that lives INSIDE the bar island (the island morphs into it, see
// Bar.qml). A CAROUSEL, not a grid: five thumbnails across, the middle one held at
// center and a size larger than the rest, which fall away by distance and fade out toward
// the island's sides. A search row on top narrows it by file name, the way the launcher
// and the theme list do. Flick it with the arrows, the wheel, or by dragging; nothing is
// applied until you press Enter, so you can browse past a dozen wallpapers without the
// desktop strobing behind you. The one currently in use keeps an accent dot.
// Running into either end rubber-bands instead of stopping dead.
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    // five across, 16:10-ish. The strip is one cell tall; the center cell sits at scale 1
    // and its neighbors shrink, so nothing needs headroom above it.
    // Sized off the panel's SETTLED width, not its live one. The cell height feeds
    // implicitHeight, which is what the island animates its height toward — read from the
    // animating width, the island could only learn how tall to be once it had finished
    // getting wide, so it expanded outward first and then downward, in two beats instead of
    // one motion. Off a constant, the final height is known on the first frame and both axes
    // travel together; the strip is still only as wide as the panel, so during the morph the
    // thumbnails are revealed rather than resized.
    readonly property int perView: 5
    readonly property int panelW: Math.max(240, Config.wallpaperPickerWidth - Theme.s4 * 2)
    readonly property int cellW: Math.floor(panelW / perView)
    readonly property int cellH: Math.round(cellW * 0.62)
    // Headroom for the hover lift. The strip has to clip horizontally, so without room set
    // aside the raised thumbnail (and its ring) would just get sliced off the top — the row
    // is cellH + 2*cellPad tall and the thumbnail sits centered in it, so the lift happens
    // INSIDE the clip. Same arrangement the theme switcher uses.
    readonly property int liftPx: 3
    readonly property int cellPad: 8
    // the centered thumbnail is drawn this much larger than its cell, so the row is that
    // much taller (the cell pitch stays: it grows over its neighbors' margins)
    readonly property real heroScale: 1.2
    readonly property int rowH: Math.round(cellH * heroScale) + cellPad * 2
    // air either side of the centered picture, and how far the ones beyond its neighbors
    // are pulled in (see the delegate's `nudge`)
    readonly property int heroGap: Math.round(cellW * 0.06)
    readonly property int tuck: Math.round(cellW * 0.20)
    // the corner every thumbnail wears: the theme list's open band's
    readonly property int thumbR: 20
    // the size thumbnails are decoded at. The strip's Images and the warm-up below MUST
    // agree on it (and on the fill mode) or they are different cache entries.
    readonly property size thumbSize: Qt.size(480, 300)

    // ── warm-up: the folder's thumbnails are decoded before the picker is opened ──
    // Each thumbnail used to start decoding when its cell was first built, so the strip
    // opened as a row of gray cards that filled in one by one. A hidden Image per file
    // holds every thumbnail of the current theme's folder from a few seconds after the
    // shell starts (and again when the theme or the folder changes). Qt keeps one decoded
    // copy per (file, size, fill mode), so the strip's own Images find theirs ready.
    property bool warm: false
    Timer { interval: 3000; running: true; onTriggered: root.warm = true }
    FolderListModel {
        id: warmModel
        folder: root.warm ? "file://" + Wallpapers.dir : ""
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }
    Item {
        visible: false
        Repeater {
            model: warmModel
            delegate: Image {
                required property url fileUrl
                width: 1; height: 1
                source: fileUrl
                sourceSize: root.thumbSize
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }
        }
    }

    readonly property int count: Wallpapers.model?.count ?? 0

    function close() { GlobalState.wallpaperPickerOpen = false; }

    // Move by one, or rubber-band if that's the end of the road.
    function step(dir) {
        if (root.count === 0) return;
        const next = strip.currentIndex + dir;
        root.touched = true;
        if (next < 0 || next >= root.count) { strip.kick(dir); return; }
        strip.currentIndex = next;
    }

    // Apply the CENTERED one. This is the only thing that touches Config.wallpaper —
    // moving through the carousel is free.
    function apply() {
        const m = Wallpapers.model;
        if (!m || m.count === 0 || strip.currentIndex < 0) return;
        const path = m.get(strip.currentIndex, "filePath");
        if (!path) return;
        Config.wallpaper = path;
        Quickshell.execDetached(["bash", `${Quickshell.env("HOME")}/.config/wallust/wallpaper-record.sh`, Config.theme, path]);
    }

    // Open on whatever's already applied rather than at the far left. The folder model
    // populates asynchronously, so this gets called again when the count lands.
    function syncToCurrent() {
        const m = Wallpapers.model;
        if (!m || m.count === 0) return;
        for (let i = 0; i < m.count; i++) {
            if (m.get(i, "filePath") === Config.wallpaper) {
                strip.currentIndex = i;
                strip.jump(i);
                return;
            }
        }
    }

    // once the user has stepped, the folder model landing late must not yank the selection
    // back to the applied wallpaper under their keys
    property bool touched: false
    onActiveChanged: {
        if (active) {
            touched = false;
            animateIn = false;
            field.text = "";
            Wallpapers.query = "";
            Qt.callLater(() => { field.forceActiveFocus(); root.syncToCurrent(); });
        } else {
            Wallpapers.query = "";      // the list is whole again for the next open
        }
    }

    // A search narrows the folder model itself, which refills a moment later. With
    // something typed the strip goes to the first match; with the box cleared it goes
    // back to the wallpaper that is applied.
    function refit() {
        if (Wallpapers.needle === "") { if (!touched) syncToCurrent(); return; }
        if (root.count > 0) { strip.currentIndex = 0; strip.jump(0); }
    }
    Timer { id: refitSoon; interval: 120; onTriggered: root.refit() }
    // Pictures brought in by a search arrive, they do not just appear: while this is
    // set, a thumbnail that gets built fades and rises into place, one after another out
    // from the first match (see the delegate's `entered`). Only a search sets it. The
    // open has its own motion (the island's), and scrolling builds cells at the edges
    // all the time, which must stay quiet.
    property bool animateIn: false
    // The three corner labels (the theme's name, the picture's name, the count) stand in
    // from the island's edge by this much. Flush with the edge they sat out in the
    // rounded corners, away from everything else in the picker.
    readonly property int labelInset: Theme.s2
    Timer { id: animateInOff; interval: 450; onTriggered: root.animateIn = false }
    Connections {
        target: Wallpapers
        function onNeedleChanged() {
            root.touched = false;
            refitSoon.restart();
            if (root.active) { root.animateIn = true; animateInOff.restart(); }
        }
    }
    Connections {
        target: Wallpapers.model
        function onCountChanged() { if (root.active) Qt.callLater(root.refit); }
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.s3

        // search row: doubles as the header, same idiom as the launcher and the theme list.
        // The field keeps the keyboard the whole time; it forwards the keys that drive
        // the strip.
        Item {
            width: parent.width
            height: Theme.s6
            Icon {
                id: glass
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                color: Theme.inkDim
            }
            TextInput {
                id: field
                cursorDelegate: Caret {}
                anchors.left: glass.right
                anchors.leftMargin: Theme.s3
                anchors.right: themeTag.left
                anchors.rightMargin: Theme.s2
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.inkPrimary
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.fontBody
                font.pixelSize: Theme.fsBody
                onTextChanged: Wallpapers.query = text
                onAccepted: root.apply()
                Keys.onEscapePressed: root.close()
                Keys.onReleased: event => { if (!event.isAutoRepeat && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) strip.release(); }
                Keys.onLeftPressed: root.step(-1)
                Keys.onRightPressed: root.step(1)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab) { root.step(1); event.accepted = true; }
                    else if (event.key === Qt.Key_Backtab) { root.step(-1); event.accepted = true; }
                }
                StyledText {
                    id: searchHint
                    capCenterIn: parent
                    visible: field.text.length === 0
                    variant: "body"
                    color: Theme.inkFaint
                    text: "Search wallpapers…"
                }
            }
            // On the search text's own LINE: the two share a baseline. Centering each one
            // on the row (by box or by capital height) put the smaller text's feet a couple
            // of pixels above the bigger text's, and it read as sitting higher. The search
            // text's baseline is the row's middle plus half its capital height, so the
            // theme's name is hung from that same spot.
            FontMetrics { id: searchFm; font: searchHint.font }
            StyledText {
                id: themeTag
                anchors.right: parent.right
                anchors.rightMargin: root.labelInset
                anchors.baseline: parent.verticalCenter
                anchors.baselineOffset: searchFm.capitalHeight / 2
                variant: "caption"
                text: Config.theme
                color: Theme.inkDim
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.hairline }

        // the carousel
        Item {
            width: parent.width
            height: root.rowH

            ListView {
                id: strip
                // settled width, centered, from frame one (see the theme switcher's strip)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.panelW
                orientation: ListView.Horizontal
                model: Wallpapers.model
                clip: true

                // ── the strip owns its scrolling ──
                // No highlight range, no snap mode: the view's range enforcement re-places
                // itself INSTANTLY whenever the current index moves against a fast highlight
                // animation (a left pressed mid-sweep jumped the strip 58px in one frame,
                // measured), and no amount of tuning changes that. Instead the content position
                // is animated explicitly: `go` stops whatever is in flight and starts a fresh
                // spring from wherever the strip IS to the center of the index, so a reversal,
                // a burst or a hitch is always one continuous motion. `jump` places it
                // instantly (the open, a filter reset). A drag stops the animation and hands
                // the strip back to the nearest card on release.
                highlightRangeMode: ListView.NoHighlightRange
                highlightFollowsCurrentItem: false
                snapMode: ListView.NoSnap
                readonly property real pitch: root.cellW + spacing
                readonly property real centerOff: (width - root.cellW) / 2
                function xFor(i) { return i * pitch - centerOff; }
                function nearest() { return Math.max(0, Math.min(count - 1, Math.round((contentX + centerOff) / pitch))); }
                function go(i) { scroll.stop(); if (count === 0) return; scroll.from = contentX; scroll.to = xFor(i); scroll.start(); }
                function jump(i) { scroll.stop(); if (count === 0) return; contentX = xFor(i); }
                // a full card of travel per step: the island's longer entrance timing, not the
                // base spring, or the strip reads as snapping between cards
                NumberAnimation { id: scroll; target: strip; property: "contentX"; duration: Theme.dur(Theme.dEnter); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                onDragStarted: scroll.stop()
                onMovementEnded: { const n = nearest(); if (n === currentIndex) go(n); else currentIndex = n; }
                // Room at both ends so the FIRST and LAST items can actually reach the center.
                leftMargin: Math.max(0, (width - root.cellW) / 2)
                rightMargin: Math.max(0, (width - root.cellW) / 2)
                onCurrentIndexChanged: if (currentIndex >= 0) go(currentIndex)
                // dragging past either end rubber-bands rather than hitting a wall
                boundsBehavior: Flickable.DragOverBounds
                boundsMovement: Flickable.FollowBoundsBehavior

                // run-into-the-end rubber band: a pull, held while the KEY is held. A press
                // sets ONE target (the shove) and the spring carries the strip there; repeats
                // keep the same target, so nothing restarts (a new target per repeat restarted
                // the spring from a standstill 30 times a second and the strip spazzed). The
                // let-go follows the key's RELEASE, not a timer: the compositor's repeat delay
                // (~280ms here) is longer than any sensible timer, so a timed let-go dropped
                // the strip and the first repeat pulled it out again, every hold. The timer
                // stays only as a long fallback for a release that never arrives.
                property real bumpX: 0
                Behavior on bumpX { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                Timer { id: bumpBack; interval: 900; onTriggered: strip.bumpX = 0 }
                function kick(dir) { bumpX = -dir * 24; bumpBack.interval = 900; bumpBack.restart(); }
                // a tap releases within a few ms of pressing; give the pull a beat to show
                function release() { bumpBack.interval = Theme.dur(Theme.dFast); bumpBack.restart(); }
                transform: Translate { x: strip.bumpX }

                delegate: Item {
                    id: cell
                    required property int index
                    required property string filePath
                    required property url fileUrl

                    width: root.cellW
                    height: root.rowH

                    readonly property bool inUse: filePath === Config.wallpaper
                    readonly property bool centered: index === strip.currentIndex
                    // Distance from the center of the viewport in CELL units, read off the live
                    // contentX rather than the index, so the falloff tracks a drag continuously
                    // instead of stepping when the current index flips.
                    readonly property real sdist: ((x + width / 2) - (strip.contentX + strip.width / 2)) / Math.max(1, root.cellW)
                    readonly property real dist: Math.abs(sdist)
                    // The cells sit on an even pitch, which left the big centered picture
                    // touching its neighbors and the small ones further out spread thin.
                    // So each picture is nudged sideways by where it is: the neighbors are
                    // pushed away from the center to give it air, and everything past them
                    // is pulled back in toward them.
                    readonly property real nudge: (sdist < 0 ? -1 : 1) * (Math.min(1, dist) * root.heroGap - Math.max(0, dist - 1) * root.tuck)

                    // the entrance after a search (see root.animateIn): 0 -> 1, a beat later
                    // for each step away from the first match
                    property real entered: 1
                    Component.onCompleted: if (root.animateIn) { entered = 0; enter.start(); }
                    SequentialAnimation {
                        id: enter
                        PauseAnimation { duration: Theme.dur(Math.min(cell.index, 6) * 28) }
                        NumberAnimation { target: cell; property: "entered"; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                    }

                    opacity: (1 - Math.min(0.6, dist * 0.32)) * entered
                    // the centered one a size up, its neighbors a touch under their cell,
                    // the rest smaller still; continuous in `dist`, so it tracks a drag
                    // (everything off-center is a further 10% smaller than it was: 0.83
                    // of a cell for the neighbors, 0.74 beyond them)
                    scale: (dist < 1 ? root.heroScale - dist * (root.heroScale - 0.828)
                                     : Math.max(0.738, 0.828 - (dist - 1) * 0.252)) * (0.94 + 0.06 * entered)
                    z: 10 - Math.round(dist * 2)      // the bigger one lies over its neighbors
                    // nudges up under the pointer, so hovering visibly does something even
                    // though it still takes a click to select — same as the theme switcher
                    transform: Translate {
                        x: cell.nudge
                        y: (cellMa.containsMouse ? -root.liftPx : 0) + (1 - cell.entered) * 12
                        Behavior on y { enabled: cell.entered === 1; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    }

                    Item {
                        // the thumbnail itself keeps its own size, centered in the padded row
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.cellW - Theme.s1 * 2
                        height: root.cellH - Theme.s1 * 2

                        Image {
                            id: thumb
                            readonly property bool ready: status === Image.Ready && source.toString() !== ""
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize: root.thumbSize
                            source: cell.fileUrl
                            visible: false
                            layer.enabled: true
                        }
                        Rectangle {
                            id: thumbMask
                            anchors.fill: parent
                            radius: root.thumbR
                            visible: false
                            layer.enabled: true
                        }
                        // placeholder under the art, so a not-yet-decoded thumb is a quiet
                        // surface rather than a hole punched in the strip
                        Rectangle {
                            anchors.fill: parent
                            radius: root.thumbR
                            color: Theme.surfaceBase
                            visible: !thumb.ready
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: thumb
                            maskSource: thumbMask
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            // decoding is async, so fade the art up as it lands instead of
                            // letting it snap in a frame after the panel is already open
                            opacity: thumb.ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                        }

                        // the centered one (the one Enter will apply) wears a rim in the
                        // shell's ink, not the accent: the accent shouted over the pictures.
                        // A fainter hairline on hover so the off-center ones read as targets.
                        Rectangle {
                            anchors.fill: parent
                            radius: root.thumbR
                            color: "transparent"
                            // hover has to be clearly brighter than idle; hairline was too close
                            // to invisible to read as a response
                            border.color: cell.centered ? Theme.alpha(Theme.foreground, 0.3)
                                        : cellMa.containsMouse ? Theme.alpha(Theme.foreground, 0.15)
                                        : "transparent"
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                        }

                        // "this one's actually live" dot, so the applied wallpaper stays
                        // identifiable while you browse past it
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: Theme.s2
                            width: 8; height: 8
                            radius: 4
                            visible: cell.inUse
                            color: Theme.accent
                            border.width: 1
                            border.color: Theme.alpha(Theme.base, 0.45)
                        }

                        MouseArea {
                            id: cellMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // click an outer one to bring it to the middle; click the middle
                            // one to apply it (same as Enter)
                            onClicked: {
                                if (cell.centered) root.apply();
                                else strip.currentIndex = cell.index;
                            }
                        }
                    }
                }
            }

            // The strip fades out toward the island's sides instead of being cut off: a
            // veil of the island's own color over each end.
            Repeater {
                model: 2
                delegate: Rectangle {
                    required property int index
                    z: 20
                    width: Math.round(root.cellW * 0.7)
                    height: parent.height
                    x: index === 0 ? strip.x : strip.x + strip.width - width
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: index === 0 ? Theme.base : Theme.alpha(Theme.base, 0) }
                        GradientStop { position: 1; color: index === 0 ? Theme.alpha(Theme.base, 0) : Theme.base }
                    }
                }
            }

            // wheel anywhere over the strip steps through it. NoButton so it never eats the
            // clicks the thumbnails need (same trick the media zone uses in Bar.qml).
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                    if (d !== 0) root.step(d < 0 ? 1 : -1);
                }
            }
        }

        // footer: what's centered, where you are, and how to commit it
        Item {
            width: parent.width
            height: 18

            // The name of the centered picture ROLLS when it changes, the way the power
            // menu's label does: the old name out one way, the new one in behind it, on
            // the fast clock. It goes up when you move right and down when you move left,
            // so the direction you stepped in is in the motion.
            Item {
                id: nameTag
                anchors.left: parent.left
                anchors.leftMargin: root.labelInset
                width: parent.width * 0.6
                height: parent.height
                clip: true
                readonly property string want: {
                    const m = Wallpapers.model;
                    if (!m || m.count === 0) return Wallpapers.needle !== "" ? "No wallpapers match" : "No wallpapers in this theme's folder";
                    if (strip.currentIndex < 0) return "";
                    return m.get(strip.currentIndex, "fileName") ?? "";
                }
                // what is on screen; set by hand (a binding would follow `want` at once
                // and there would be nothing left to roll from)
                property string shown: ""
                property int lastIndex: -1
                property real roll: 1          // 0 = the old name in place, 1 = the new one
                property int dir: 1
                Component.onCompleted: { shown = want; lastIndex = strip.currentIndex; }
                onWantChanged: {
                    const i = strip.currentIndex;
                    if (shown === want) { lastIndex = i; return; }
                    // nothing to roll from while the picker is closed or just opening
                    if (!root.active || shown === "") { shown = want; lastIndex = i; return; }
                    dir = i < lastIndex ? -1 : 1;
                    lastIndex = i;
                    nameOut.text = shown;
                    shown = want;
                    nameRoll.restart();
                }
                NumberAnimation { id: nameRoll; target: nameTag; property: "roll"; from: 0; to: 1; duration: Theme.dur(Theme.dFast); easing.type: Easing.OutCubic }
                StyledText {
                    anchors.left: parent.left
                    capCenterIn: parent
                    width: parent.width
                    elide: Text.ElideMiddle
                    variant: "caption"
                    color: Theme.inkDim
                    text: nameTag.shown
                    opacity: nameTag.roll
                    transform: Translate { y: nameTag.dir * (1 - nameTag.roll) * nameTag.height * 0.7 }
                }
                StyledText {
                    id: nameOut
                    anchors.left: parent.left
                    capCenterIn: parent
                    width: parent.width
                    elide: Text.ElideMiddle
                    variant: "caption"
                    color: Theme.inkDim
                    opacity: 1 - nameTag.roll
                    visible: opacity > 0
                    transform: Translate { y: -nameTag.dir * nameTag.roll * nameTag.height * 0.7 }
                }
            }
            StyledText {
                anchors.right: parent.right
                anchors.rightMargin: root.labelInset
                capCenterIn: parent
                variant: "caption"
                color: Theme.inkFaint
                visible: root.count > 0
                text: `${strip.currentIndex + 1}/${root.count}`
            }
        }
    }
}

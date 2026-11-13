import QtQuick
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Theme switcher that lives INSIDE the bar island (the island morphs into it, see
// Bar.qml). A list in the launcher's own language, where the row you are on turns into
// a page of a COLOR BOOK: closed, a theme is a launcher row (a badge in its background
// and accent, its name, its six hues at the end); open, it is a band drawn in the theme
// itself, the name large in its own foreground, the hues under it, and the wallpaper the
// theme would bring on the right.
//
// Driven from the keyboard the same way the launcher is: type to filter, arrows to move,
// Enter to apply. A click moves to a band; a click on the open band applies it. The DOT
// before a name marks the theme that is live right now.
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    property string query: ""
    property int index: 0

    // ── geometry, all settled values (the island animates toward implicitHeight, so
    // nothing here may be read off something that is itself animating) ──
    readonly property int bookW: Math.min(Config.themeSwitcherWidth, 640)   // the island's width (Bar reads this)
    readonly property int closedH: Config.launcherRowHeight   // a closed row is a launcher row
    readonly property int openH: 104
    readonly property int gap: 0
    readonly property int pitch: closedH + gap
    readonly property int rowsAround: 4            // closed rows visible besides the open one
    readonly property int totalH: count > 0 ? openH + (count - 1) * pitch : 0
    readonly property int viewH: count > 0 ? Math.min(totalH, openH + rowsAround * pitch) : 56
    // where the stack is scrolled to: the open band in the middle of the view, held to the ends
    readonly property real scrollTarget: Math.max(0, Math.min(totalH - viewH, index * pitch + openH / 2 - viewH / 2))

    // Matches are RANKED, not just filtered. A plain substring filter kept the list in its
    // alphabetical order, so a single character put the wrong theme first: "n" matches
    // "anime" and "kanagawa" as well as "nightfox"/"noir"/"nord", and alphabetically the
    // incidental matches win. Names that START with what you typed come first, then the
    // rest ordered by how early the match lands, alphabetical within each tier.
    readonly property var shown: {
        const all = Themes.list ?? [];
        const q = query.trim().toLowerCase();
        if (q === "") return all;
        const hits = [];
        for (let i = 0; i < all.length; i++) {
            const n = (all[i].name ?? "").toLowerCase();
            const at = n.indexOf(q);
            if (at < 0) continue;
            hits.push({ t: all[i], at: at, n: n });
        }
        hits.sort((a, b) => a.at - b.at || a.n.localeCompare(b.n));
        return hits.map(h => h.t);
    }
    readonly property int count: shown.length
    readonly property var current: count > 0 ? shown[Math.max(0, Math.min(index, count - 1))] : null

    function close() { GlobalState.themeSwitcherOpen = false; }

    function apply(name) {
        // DON'T set Config.theme here. theme-apply.sh is the single writer of config.json:
        // it sets both the theme AND this theme's wallpaper. If we also touch Config, the
        // shell serializes the WHOLE config (with the OLD wallpaper still in it) and that
        // write races the script's, so the wallpaper sometimes gets stomped back to the old
        // one. We just kick off the script; the FileView reload pulls in theme + wallpaper.
        Quickshell.execDetached(["bash", `${Quickshell.env("HOME")}/.config/wallust/theme-apply.sh`, name]);
    }
    function activate() { if (root.current) root.apply(root.current.name); }
    function step(dir) {
        if (root.count === 0) return;
        root.userMoved();
        root.index = Math.max(0, Math.min(root.count - 1, root.index + dir));
    }
    // The list of themes can land AFTER the switcher has opened (right after the shell
    // starts or reloads it is still being read): the book then opened on the first theme
    // instead of the live one. Until you have moved, a list arriving re-opens it on the
    // live theme.
    property bool moved: false
    // The first move hands the book to you: from then on changes are MOTION. The open
    // places things without animating for the length of the island's morph, and a move
    // made inside that window used to be placed too, so stepping right after opening
    // showed no animation at all until you had waited it out.
    function userMoved() { moved = true; placing = false; placed.stop(); }
    onCountChanged: if (active && !moved && query === "") { placing = true; placed.restart(); syncToCurrent(); }

    // Open sitting on whatever's applied, so Enter alone is a no-op instead of a surprise.
    function syncToCurrent() {
        let found = 0;
        for (let i = 0; i < root.count; i++) {
            if (root.shown[i].name === Config.theme) { found = i; break; }
        }
        root.index = found;
    }

    // placed, not animated, while the island is still morphing open (and after a filter
    // change): the stack should already be where it belongs when it is revealed
    property bool placing: false
    Timer { id: placed; interval: Theme.dur(Theme.dSpring) + 60; onTriggered: root.placing = false }

    onActiveChanged: {
        if (active) {
            Themes.refresh();
            stateFile.reload();
            animateIn = false;
            field.text = "";
            query = "";
            placing = true;
            placed.restart();
            moved = false;
            syncToCurrent();
            Qt.callLater(() => field.forceActiveFocus());
        } else {
            placing = false;
            placed.stop();
        }
    }
    onQueryChanged: { placing = true; placed.restart(); index = 0; }
    // A search hands the list a new set of rows, which are built fresh: they used to just
    // be there. Each row now fades and rises in, a beat after the one above it. Only for a
    // SETTLED change though: typed fast, every keystroke rebuilds the rows, and restarting
    // a fade on each one would leave the list blank for as long as you kept typing, so
    // keystrokes in quick succession show their rows at once.
    property bool animateIn: false
    property double lastTypedAt: 0
    function setQuery(t) {
        const now = Date.now();
        animateIn = (now - lastTypedAt) > 220;
        lastTypedAt = now;
        query = t;
    }

    // ── the wallpaper a theme would bring ──
    // theme-apply.sh restores the one last used with that theme (wallpaper-state: one
    // "theme<TAB>path" line each), else the first in its folder. The open band shows the
    // same: the remembered one, or the folder's first.
    FileView { id: stateFile; path: Quickshell.shellDir + "/wallpaper-state"; blockLoading: true; printErrors: false }
    readonly property var remembered: {
        const m = {};
        for (const line of String(stateFile.text()).split("\n")) {
            const at = line.indexOf("\t");
            if (at > 0) m[line.slice(0, at)] = line.slice(at + 1);
        }
        return m;
    }
    // A theme with nothing remembered falls back to the first picture in its folder,
    // found by a small folder model of its own (see the warm-up below).
    property var firstOf: ({})
    function wallOf(name) {
        const r = root.remembered[name];
        return r ? "file://" + r : (root.firstOf[name] || "");
    }
    readonly property string openWall: root.current ? root.wallOf(root.current.name) : ""

    // ── warm-up: every theme's picture is decoded BEFORE it is asked for ──
    // The open band used to start decoding its wallpaper when it opened: a 5K picture
    // takes a few hundred ms, so every step through the book showed an empty band and then
    // a fade. Now a hidden Image per theme holds each picture, already decoded at the size
    // the band draws it, from a moment after the shell starts. Qt keeps one copy per
    // (file, size, fill mode), so the band's own Image finds it ready and shows it on the
    // frame it opens. `thumb` and the fill mode MUST match the band's Image exactly, or it
    // is a different entry and nothing is saved.
    readonly property size thumb: Qt.size(640, 360)
    property bool warm: false
    Timer { interval: 2500; running: true; onTriggered: root.warm = true }
    Item {
        visible: false
        Repeater {
            model: Themes.list
            delegate: Item {
                id: pre
                required property var modelData
                Loader {
                    active: !root.remembered[pre.modelData.name]
                    sourceComponent: FolderListModel {
                        folder: "file://" + Config.expandHome(Config.wallpaperDir).replace(/\/+$/, "") + (Config.wallpaperPerTheme ? "/" + pre.modelData.name : "")
                        nameFilters: ["*.jpg", "*.jpeg", "*.png"]
                        showDirs: false
                        sortField: FolderListModel.Name
                        onCountChanged: {
                            if (count === 0) return;
                            const o = Object.assign({}, root.firstOf);
                            o[pre.modelData.name] = String(get(0, "fileUrl"));
                            root.firstOf = o;
                        }
                    }
                }
                Image {
                    width: 1; height: 1
                    source: root.warm ? root.wallOf(pre.modelData.name) : ""
                    sourceSize: root.thumb
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
            }
        }
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.s3

        // search row: doubles as the header, same idiom as the launcher
        Item {
            id: searchBar
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
                anchors.right: countLabel.left
                anchors.rightMargin: Theme.s2
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.inkPrimary
                selectionColor: Theme.alpha(Theme.accent, 0.4)
                font.family: Theme.fontBody
                font.pixelSize: Theme.fsBody
                onTextChanged: root.setQuery(text)
                // the field keeps focus the whole time so you can keep typing; it just
                // forwards the navigation keys to the book
                onAccepted: root.activate()
                Keys.onEscapePressed: root.close()
                Keys.onUpPressed: root.step(-1)
                Keys.onDownPressed: root.step(1)
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Home) { root.userMoved(); root.index = 0; event.accepted = true; }
                    else if (event.key === Qt.Key_End) { root.userMoved(); root.index = Math.max(0, root.count - 1); event.accepted = true; }
                    else if (event.key === Qt.Key_PageUp) { root.step(-root.rowsAround); event.accepted = true; }
                    else if (event.key === Qt.Key_PageDown) { root.step(root.rowsAround); event.accepted = true; }
                    else if (event.key === Qt.Key_Tab) { root.step(1); event.accepted = true; }
                    else if (event.key === Qt.Key_Backtab) { root.step(-1); event.accepted = true; }
                }
                StyledText {
                    capCenterIn: parent
                    visible: field.text.length === 0
                    variant: "body"
                    color: Theme.inkFaint
                    text: "Search themes…"
                }
            }
            StyledText {
                id: countLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                variant: "caption"
                font.features: { "tnum": 1 }
                text: root.count > 0 ? (root.index + 1) + "/" + root.count : ""
                color: Theme.inkDim
            }
        }

        // the same hairline the launcher has under its search row
        Rectangle { width: parent.width; height: 1; color: Theme.hairline }

        // ── the book ──
        Item {
            id: view
            width: parent.width
            height: root.viewH
            clip: true

            StyledText {
                anchors.centerIn: parent
                visible: root.count === 0
                variant: "label"
                color: Theme.inkDim
                text: (Themes.list?.length ?? 0) === 0 ? "No colorschemes found" : "No themes match"
            }

            // the wheel turns the pages, one band a notch
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
                    if (dy !== 0) root.step(dy > 0 ? -1 : 1);
                }
            }

            Column {
                id: stack
                width: parent.width
                spacing: root.gap
                y: -scroll
                property real scroll: root.scrollTarget
                Behavior on scroll { enabled: !root.placing; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                Repeater {
                    model: root.shown
                    // CLOSED, a theme is a row out of the launcher: same height, same
                    // corner, a 36px badge on the left (the theme's background with its
                    // accent in the middle), the name in the shell's own ink, the same
                    // hover tint. Only the row you are on leaves that language: it opens
                    // into a band in the theme's colors. One value `t` on the spring takes
                    // every part from the one look to the other.
                    delegate: Item {
                        id: band
                        required property var modelData
                        required property int index
                        readonly property bool on: index === root.index
                        readonly property bool live: modelData.name === Config.theme
                        property real t: on ? 1 : 0
                        Behavior on t { enabled: !root.placing; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                        readonly property real tc: Math.max(0, Math.min(1, t))
                        // The live mark comes and goes on the spring: applying a theme
                        // shrinks the dot out of the old row and pops it into the new one,
                        // and the names slide to give it room. (It used to jump.)
                        property real liveT: live ? 1 : 0
                        Behavior on liveT { enabled: !root.placing; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                        readonly property color themeBg: modelData.bg || Theme.surfaceOverlay
                        readonly property color themeFg: modelData.fg || Theme.inkPrimary
                        readonly property color themeAccent: modelData.accent || Theme.accent

                        width: stack.width
                        height: root.closedH + (root.openH - root.closedH) * t

                        // the row's own entrance (see root.animateIn)
                        property real entered: 1
                        opacity: entered
                        transform: Translate { y: (1 - band.entered) * 10 }
                        Component.onCompleted: if (root.animateIn) { entered = 0; enter.start(); }
                        SequentialAnimation {
                            id: enter
                            PauseAnimation { duration: Theme.dur(Math.min(band.index, 7) * 24) }
                            NumberAnimation { target: band; property: "entered"; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                        }

                        // the band: nothing when closed, the theme's own background when open
                        Rectangle {
                            id: fill
                            anchors.fill: parent
                            radius: Theme.rSm + (20 - Theme.rSm) * band.tc
                            color: band.themeBg
                            opacity: band.tc
                        }
                        // closed: the launcher's hover tint
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.rSm
                            color: Theme.glassLow
                            opacity: (bandMa.containsMouse && !band.on) ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast) } }
                        }

                        // the wallpaper, on the open band only: the right half, fading into
                        // the band's own color toward the name, cut to the band's corners
                        Loader {
                            anchors.fill: parent
                            active: band.on && root.openWall !== ""
                            sourceComponent: Item {
                                // comes in with the band opening, no fade of its own to
                                // wait for (a picture that is somehow not ready stays out)
                                opacity: pic.status === Image.Ready ? band.tc : 0
                                Item {
                                    id: art
                                    anchors.fill: parent
                                    visible: false
                                    layer.enabled: true
                                    Image {
                                        id: pic
                                        anchors.right: parent.right
                                        width: Math.round(parent.width * 0.46)
                                        height: root.openH
                                        anchors.verticalCenter: parent.verticalCenter
                                        source: root.openWall
                                        // same size and fill mode as the warm-up copy:
                                        // that is what makes this one instant
                                        sourceSize: root.thumb
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                    }
                                    Rectangle {
                                        anchors.left: pic.left
                                        width: Math.round(pic.width * 0.55)
                                        height: parent.height
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0; color: band.themeBg }
                                            GradientStop { position: 1; color: Theme.alpha(band.themeBg, 0) }
                                        }
                                    }
                                }
                                Rectangle { id: artMask; anchors.fill: parent; radius: fill.radius; visible: false; layer.enabled: true }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: art
                                    maskEnabled: true
                                    maskSource: artMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }
                            }
                        }

                        // the badge, where the launcher has an app's icon: the theme's
                        // background with its accent in the middle. It fades as the row
                        // opens, since the whole band is that color by then.
                        Rectangle {
                            id: badge
                            x: Theme.s3
                            y: (root.closedH - height) / 2
                            width: 36; height: 36
                            radius: Theme.rSm
                            color: band.themeBg
                            border.width: 1
                            border.color: Theme.rim
                            opacity: 1 - band.tc
                            visible: opacity > 0
                            Rectangle { anchors.centerIn: parent; width: 14; height: 14; radius: 7; color: band.themeAccent }
                        }

                        // closed, the name starts where the launcher's titles do; open, at
                        // the band's own left inset. The live dot sits in front of it.
                        readonly property real nameX0: Theme.s3 + 36 + Theme.s3
                        readonly property real nameX: nameX0 + (18 - nameX0) * tc
                        Rectangle {
                            x: band.nameX
                            y: nameText.y + nameText.height / 2 - height / 2
                            width: 7 + 2 * band.tc; height: width; radius: width / 2
                            color: band.themeAccent
                            opacity: Math.max(0, Math.min(1, band.liveT))
                            scale: band.liveT
                            visible: opacity > 0
                        }
                        // The name is two texts, each set once at its own size: the closed
                        // row's line and the open band's heading. Growing one text's
                        // font.pixelSize through the morph laid it out again at every whole
                        // size on the way (15, 16, ... 22), each with its own hinted letter
                        // spacing, so the far end of a long name jumped about while the
                        // near end slid. These only scale and cross-fade, which is smooth,
                        // and each is at scale 1 (pixel-crisp) whenever it is at rest.
                        readonly property real nameScale: Theme.fsBody + (22 - Theme.fsBody) * tc   // the size it looks, px
                        // open, the name and the hues sit together as one block in the
                        // middle of the band: the heading's top lands on 23
                        readonly property real nameMid: root.closedH / 2 + (23 + headText.height / 2 - root.closedH / 2) * t
                        readonly property real headIn: Math.min(1, tc / 0.35)
                        Text {
                            id: nameText
                            x: band.nameX + (7 + 2 * band.tc + 7) * band.liveT
                            y: band.nameMid - height / 2
                            text: band.modelData.name
                            // a closed row is a line in a list and is set like a launcher title
                            font.family: Theme.fontBody
                            font.weight: Theme.wMedium
                            font.pixelSize: Theme.fsBody
                            color: Theme.inkPrimary
                            renderType: Text.NativeRendering
                            transformOrigin: Item.Left
                            scale: band.nameScale / Theme.fsBody
                            opacity: 1 - band.headIn
                            visible: opacity > 0
                        }
                        Text {
                            id: headText
                            x: nameText.x
                            y: band.nameMid - height / 2
                            text: band.modelData.name
                            // the display face is for the open band's heading only
                            font.family: Theme.fontDisplay
                            font.weight: Theme.wSemiBold
                            font.pixelSize: 22
                            color: band.themeFg
                            renderType: Text.NativeRendering
                            transformOrigin: Item.Left
                            scale: band.nameScale / 22
                            opacity: band.headIn
                            visible: opacity > 0
                        }
                        // the six hues: at the right end of a closed row, under the name on the open one
                        Row {
                            readonly property real d: 8 + 4 * band.tc
                            readonly property real x0: band.width - width - Theme.s3
                            spacing: d * 0.5
                            x: x0 + (18 - x0) * band.tc
                            y: (root.closedH - d) / 2 + (63 - (root.closedH - d) / 2) * band.t
                            Repeater {
                                model: band.modelData.palette || []
                                delegate: Rectangle { required property string modelData; width: parent.d; height: parent.d; radius: parent.d / 2; color: modelData }
                            }
                        }

                        MouseArea {
                            id: bandMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (band.on) root.activate(); else { root.userMoved(); root.index = band.index; } }
                        }
                    }
                }
            }
        }
    }
}

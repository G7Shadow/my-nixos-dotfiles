import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../logout"
import "../../config"
import "../../config/IslandShape.js" as IslandShape

// The visual guts of the lock screen, split out of Lock.qml so it can be previewed
// without actually locking the session (you do NOT want to trigger a real lock just to
// eyeball it). Full-bleed wallpaper and nothing on it but the time, dead center, cut
// from glass, with the date under it in the shell's own face, inked in the palette's
// accent (never raw white). There is no avatar and no hint. The
// password box does not exist until you type: the first character brings it out from
// under the date, and the clock rises at the same moment so the two together are centered
// on the screen. Escape on an empty box sends it back and the clock returns to the
// center. Auth still runs entirely through LockState (fail-closed, PAM); this is only
// chrome. Fills its parent (a WlSessionLockSurface, or a preview window).
Item {
    id: root

    // The lock is the ISLAND's, like every other surface in the shell. The lock surface
    // has to be its own window (the session lock protocol says so), so it carries a copy
    // of the island that starts on the exact spot of the bar's (see `isle`), and from
    // there everything is that island acting. The surface starts transparent and Hyprland
    // keeps drawing the screen behind it (misc:session_lock_xray in hypr/modules/misc.lua),
    // so the windows are what fades out as the wallpaper fades in; without xray the
    // compositor cuts to black on lock and the only thing left to fade would be black ->
    // picture, which reads as the screen dying. Two clocks, one after the other:
    //   `lit`   the ground (wallpaper + its scrim) fades up over the live screen and the
    //           picture eases back a touch;
    //   `flyT`  a beat later the time leaves the island: the bar's small ink clock rides
    //           a line to the middle of the screen, growing and turning to glass on the
    //           way, the date comes up under it, and the island pulls in around a padlock.
    // Unlock is the same run backwards: the padlock opens, the time flies home and the
    // island grows back into the bar's pill, and only once it is all but home (`leaving`)
    // does the ground lift to show the windows, the wallpaper coming forward to its own
    // size on the way. All of it must fit inside LockState.unlockTimer, which is when the
    // surface is torn down. On the way in, the beat also lets the heavy first frame
    // (wallpaper decode + the shadow FBOs) settle before the flight starts, and the big
    // clock sits at a hair above 0 opacity (not a hard 0) until then so Qt paints it
    // invisibly and builds its FBOs warm.
    // Input is locked from the first frame regardless; the screen is only ever visible
    // through the surface while the ground is mid-fade, and the dark fallback under the
    // wallpaper means a missing image still leaves the surface opaque.
    property bool lit: false
    // the chrome's beat is read off the ground's REAL opacity, not a timer, so a stalled
    // heavy frame can never let the clock run ahead of the wallpaper it should land on.
    // 0.75 on the OutCubic curve is ~37% of the way in (about 190ms at the default spring).
    readonly property bool entered: ground.opacity >= 0.75
    // `lit` flips once the window has PRESENTED a frame AND the wallpaper is decoded, not
    // on Component.onCompleted. Two reasons:
    //  - a Behavior started at creation runs on the wall clock while the first frame is
    //    still being built, so the fade was over before anyone saw it (measured);
    //  - the compositor paints BLACK (then its lockdead screen) from the moment the lock
    //    engages until our surface's first commit, so that first commit has to be cheap.
    //    Decoding a full-res wallpaper on the main thread before it was 300-600ms of black.
    //    The image now decodes off-thread while the first (transparent, xray) frame goes
    //    out at once, and the fade starts the moment the picture is in.
    property bool framed: false
    readonly property bool ready: framed && isleUp && paper.status !== Image.Loading && paper.status !== Image.Null
    // Locked from the open island, our island is not drawn until the bar's picture of
    // its contents is in (it is taken a frame after the lock, so it can land after our
    // first frame). Until then the surface stays clear and the bar's own island is what
    // shows through; drawn without the picture, ours covered the real one with an empty
    // island for a frame or two and the song and the date blinked. `shotLate` gives up
    // on a picture that never comes.
    readonly property bool shotDue: LockState.pillKind !== "" && !LockState.unlocking && (screenName === "" || fromShot)
    property bool shotLate: false
    readonly property bool isleUp: !shotDue || shotImg.status === Image.Ready || shotLate
    Timer { interval: 250; running: root.framed && !root.isleUp; onTriggered: root.shotLate = true }
    // frames on the glass with our island in them: the bar may only hide its own once
    // one is really up (two, so the first cannot be one drawn before the island was)
    property int isleFrames: 0
    onIsleFramesChanged: if (isleFrames === 2 && !LockState.unlocking) LockState.setCovered(screenName, true)
    onReadyChanged: if (ready) light()
    // our island is on the glass: tell the bar, which stops drawing its own under it. The
    // moment we start unlocking the bar's comes back (still hidden by the ground), so it
    // is there to take over when the ground lifts.
    Connections {
        target: LockState
        function onUnlockingChanged() { if (LockState.unlocking) LockState.setCovered(root.screenName, false); }
    }
    function light() { lit = true; }
    Connections {
        target: root.Window.window
        enabled: root.isleFrames < 2
        function onFrameSwapped() { root.framed = true; if (root.isleUp) root.isleFrames++; }
    }
    // never leave the surface transparent: if no frame ever swaps or the decode hangs,
    // light anyway (the dark fallback under the image makes the surface opaque)
    Timer {
        interval: 1500
        running: !root.lit
        onTriggered: root.light()
    }
    // (locked from the power menu, the island first has to finish becoming the pill:
    // the clock comes out of the pill, not out of a menu that is still closing)
    // (locked from the OPEN island it does not wait: the big time is what leaves, and
    // the island closes behind it, both from the same moment)
    readonly property bool shown: entered && !LockState.unlocking && !(menuOn && !fromIsland && isle.menuT > 0.03)
    // `out`: the time is out of the island (or on its way). It follows `shown` at once on
    // the way out, and a short beat late on the way home, which is the padlock's moment:
    // it swings open in the small pill before the pill starts growing back.
    property bool out: false
    onShownChanged: {
        if (shown) { homeBeat.stop(); out = true; if (fromIsland && isle.menuShown) menuShrink.start(); }
        else homeBeat.restart();
    }
    Timer { id: homeBeat; interval: Theme.dur(110); onTriggered: root.out = false }
    // THE flight clock: 0 = the time is the bar's, in the island; 1 = it is the big glass
    // clock in the middle. Everything in the flight reads this one value.
    property real flyT: out ? 1 : 0
    Behavior on flyT { NumberAnimation { duration: Theme.dur(Theme.dExpand); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    // the way out, stage two: read off the flight's REAL value like `entered` is off the
    // ground's, so the ground can never start lifting under a clock that is still out
    readonly property bool leaving: LockState.unlocking && !out && flyT <= 0.08
    readonly property bool grounded: lit && !leaving

    // true from the first keypress until Escape on an empty field: the keys go to the
    // (unseen) password field. What shows is `shownN`, the number of dots in the island.
    property bool typing: false
    property int shownN: 0

    SystemClock { id: clk; precision: SystemClock.Minutes }

    // ── the current wallpaper + a scrim so text stays legible ──
    // The wallpaper, not a screenshot of the desktop: nothing of what was on screen is
    // captured, and there is nothing to grab before the lock can engage. The ground
    // crossfades over the live screen (see the header); the dark fallback under the image
    // keeps the surface opaque even if the wallpaper is missing or fails to decode.
    Item {
        id: ground
        anchors.fill: parent
        opacity: root.grounded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dExpand); easing.type: Easing.OutCubic } }
        Rectangle {
            anchors.fill: parent
            color: Theme.background
        }
        Image {
            id: paper
            anchors.fill: parent
            // source waits for a real size so the decode happens once, at screen size,
            // not first at the file's full size with width still 0
            source: width > 0 && height > 0 ? Config.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true           // off the main thread: the first commit must not wait on it
            sourceSize.width: width
            sourceSize.height: height
            // eases BACK a touch (1 -> 1.03) under the lock, forward again on unlock, so
            // the last frame before teardown is the desktop's own wallpaper at its own size
            scale: root.grounded ? 1.03 : 1.0
            transformOrigin: Item.Center
            Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dExpand); easing.type: Easing.OutCubic } }
        }
    }
    // darken a touch so the wallpaper's bright bits don't fight the text. Fades in over
    // the bare wallpaper on lock (this IS the visible part of the lock's entrance) and
    // lifts with the wallpaper on unlock so no dim frame lingers before teardown.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Config.lockDim / 100)
        opacity: root.grounded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dExpand); easing.type: Easing.OutCubic } }
    }
    Rectangle {
        anchors.fill: parent
        opacity: root.grounded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dExpand); easing.type: Easing.OutCubic } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.28) }
            GradientStop { position: 0.28; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 0.72; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.35) }
        }
    }

    // catches the first keypress (any key) and hands it to the password field, seeding
    // the typed character. Holds focus until then; afterward the TextInput owns focus.
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: !root.typing
        Keys.onPressed: (event) => {
            if (root.typing) return;
            switch (event.key) {
            case Qt.Key_Shift: case Qt.Key_Control: case Qt.Key_Alt:
            case Qt.Key_Meta: case Qt.Key_CapsLock: case Qt.Key_AltGr:
                return;   // ignore lone modifiers
            case Qt.Key_Escape:
                return;   // Escape puts the box away; it must not be what brings it out
            }
            root.typing = true;
            pwField.forceActiveFocus();
            if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 0x20) {
                pwField.text = event.text;
                pwField.cursorPosition = pwField.text.length;
            }
            event.accepted = true;
        }
    }

    // ── the island's resting pill, as the bar draws it on this screen ──
    // The bar publishes its own numbers (LockState.rest); the fallback is the bar's sum
    // for a pill that carries only the time, for a preview with no bar running.
    property string screenName: ""
    // Locked from the power menu: the bar's island on this screen has already become
    // the padlock pill, so that is where this one starts. The pill and the padlock are
    // simply there from the first frame, and the big clock comes out of the pill on its
    // way to the middle (the bar's small clock was never in it, so its ink copy sits the
    // way out, out). The way home is the same as ever: back into the bar's resting pill.
    readonly property bool fromPill: LockState.pillScreen !== "" && LockState.pillScreen === screenName
    readonly property bool pillHeld: fromPill && !LockState.unlocking
    // Locked from the OPEN island (the pointer on it, or pinned): we start as that
    // island, to the pixel, with its big time in the bar's ink where the bar had it and
    // a picture of the rest (LockState.pillShot). The time takes off from THERE, at
    // that size, the rest fades by the bar's own closing rule, and the island closes
    // around the padlock behind it. `menuHeld` is the other kind of start, the power
    // menu's, where there is no time in the island to fly.
    // (The control center is the same case: it has a time of its own, top left, and
    // says where. `fromIsland` is any start that has a time in it to fly.)
    readonly property bool fromIsland: fromPill && !!LockState.pillFrom && LockState.pillFrom.ts !== undefined
    readonly property bool islandHeld: fromIsland && !LockState.unlocking
    readonly property bool menuHeld: pillHeld && !fromIsland
    // Either start that comes with a picture from the bar: the open island, or a panel
    // (launcher, control center, a switcher). A panel plays like the power menu, shrink
    // first and then the clock out of the pill, with its picture where the menu's copy
    // would be.
    readonly property bool fromShot: fromPill && LockState.pillKind !== "" && !!LockState.pillFrom
    // where the flight starts and how big the time is there: the resting pill and the
    // bar's small clock, or the open island's big time. Only on the way out: home is
    // always the resting pill (the two agree at the far end, so the switch is unseen).
    readonly property real fromCx: islandHeld ? LockState.pillFrom.tx : restCx
    readonly property real fromCy: islandHeld ? LockState.pillFrom.ty : restCy
    readonly property real fromK: islandHeld ? LockState.pillFrom.ts : 1
    // Nothing on the island animates until our first frame is on the glass. `fromPill`
    // can turn true a beat after this item exists (the screen's name arrives through
    // the parent's binding), and that change used to be animated like any other: the pill
    // sprang in from the bar's size and the padlock popped, a second time, right after
    // the power menu had just done exactly that. Before the first frame a state is
    // simply taken up; after it, changes are motion.
    readonly property bool primed: framed && isleUp
    // The power menu's island, if that is what we were locked from: its size, and the
    // go-ahead to start shrinking it, which is our first frame on the glass.
    readonly property bool menuOn: fromPill && !!LockState.pillFrom
    onPrimedChanged: if (primed && menuOn && !fromIsland) menuShrink.start()
    NumberAnimation { id: menuShrink; target: isle; property: "menuT"; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier; onFinished: isle.menuDone = true }
    readonly property var restPub: LockState.rest[screenName]
    readonly property bool notchForm: Config.notchMode
    readonly property real restW: restPub ? restPub.w
        : 2 * Math.ceil(Math.max(Config.islandCollapsedWidth, Math.round(inkTime.width) + 2 * Theme.s3 + Theme.s4) / 2)
    readonly property real restH: restPub ? restPub.h : Math.max(34, Config.barHeight + 4)
    readonly property real restY: notchForm ? 0 : Config.islandGap
    readonly property real restCx: width / 2
    readonly property real restCy: restY + restH / 2

    // where the big clock's INK is centered once it has landed, and where the flying time is
    // right now: a straight line from the island's middle to there, ridden by flyT
    readonly property real heroCx: cluster.x + clockBox.x + clockBox.width / 2
    readonly property real heroCy: cluster.y + clockBox.y + clockBox.inkMid
    // The spring rings a little past both ends. Past 1 that is the big clock landing with
    // some life. Past 0 the full ring is too much (the flight is half a screen long, so
    // 1.5% of it is the time bobbing 8px about inside a 34px pill), and none at all
    // is a dead stop, so a quarter of it is kept: the time settles into the pill.
    readonly property real fly: flyT >= 0 ? flyT : flyT * 0.25
    readonly property real flyX: fromCx + (heroCx - fromCx) * fly
    readonly property real flyY: fromCy + (heroCy - fromCy) * fly
    // the bar time's size as a fraction of the big clock's, by ink height: the two copies
    // are scaled against each other with this so they are the same size all the way
    readonly property real smallK: tmInk.tightBoundingRect.height / Math.max(1, tmClock.tightBoundingRect.height)
    // how far into the flight the time's box has cleared the island's bottom edge (the
    // box grows as it goes, so this is solved for, not guessed): the island must not
    // change under the time before this, nor after it on the way home
    readonly property real clearT: Math.max(0.02, Math.min(0.3,
        (restH / 2 + inkTime.height / 2) / Math.max(1, (heroCy - restCy) - (inkTime.height / Math.max(0.01, smallK) - inkTime.height) / 2)))
    // The island's pieces here (the pill, the padlock's pop, the dots) ride the shell's
    // livelier spring, Theme.bounceBezier. At the shell's everyday damping the overshoot is
    // about 1.5%, which on a pill this small is under a pixel: it read as no spring at
    // all. The flight does NOT ride it: it covers half the screen, and the same ring there
    // would throw the big clock 70px past.
    function ramp(a, b, x) { var u = Math.max(0, Math.min(1, (x - a) / (b - a))); return u * u * (3 - 2 * u); }

    // ── CENTER: the clock, with the date under it ──
    // The time is SF Compact Rounded, heavy, filled with glass (see clockBox). The date
    // under it, like every other piece of text here, is the shell's own face, in the accent.
    // The pair is centered on the screen and never moves: the password goes in the island.
    Column {
        id: cluster
        z: 1    // over the island: the clock leaves it and comes home to it in plain view
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // Centered by INK, not by text boxes: a line of text carries empty room above its
        // capitals and below its baseline, so centering the boxes leaves what you see off
        // by a few pixels. `inkTop` is the top of the digits, `inkBottom` the bottom of the
        // date's lowest glyph (both from the cluster's top). The middle of the two is put
        // on the screen's middle.
        readonly property real inkTop: clockBox.y + clockText.baselineOffset + tmClock.tightBoundingRect.y
        // The date is off for now (flip `showDate` to bring it back): the clock stands
        // alone and is centered on its own ink.
        readonly property bool showDate: false
        readonly property real inkBottom: showDate
            ? dateText.y + dateText.baselineOffset + tmDate.tightBoundingRect.y + tmDate.tightBoundingRect.height
            : clockBox.y + clockText.baselineOffset + tmClock.tightBoundingRect.y + tmClock.tightBoundingRect.height
        anchors.verticalCenterOffset: height / 2 - (inkTop + inkBottom) / 2
        TextMetrics { id: tmClock; font: clockText.font; text: clockText.text }
        TextMetrics { id: tmDate; font: dateText.font; text: dateText.text }
        spacing: -Math.round(root.height * 0.012)

        // The time is GLASS: the digits are a window onto a blurred, brightened copy of
        // the wallpaper right behind them, so the clock looks cut from the picture and
        // not printed on it. Three layers in a box the size of the text:
        //   clockMask  the digits themselves (clockText), never drawn, only used as the mask;
        //   glassPaper a second copy of the wallpaper laid exactly over the real one
        //              (same file, same size, same scale, so it is a pixmap cache hit),
        //              also never drawn, only the blur's source;
        //   the MultiEffect blurs and lifts that copy and cuts it to the digits.
        // A faint foreground wash on top keeps the digits readable where the wallpaper
        // behind them is dark, and the shadow under the box gives them an edge where it
        // is bright.
        // In flight the whole box is scaled about the middle of its ink and carried along
        // the line from the island, fading up as it leaves the bar's ink copy behind.
        Item {
            id: clockBox
            anchors.horizontalCenter: parent.horizontalCenter
            // The box is WIDER than the text item, with the text set in from the left. A
            // Text with negative letter spacing reports a width that is short by one
            // spacing (the pull-in after the last glyph is counted too), so a box of
            // exactly that width sliced the right edge off the last digit: everything
            // here, mask and blur and wash, is cut to the box. `pad` each side clears it,
            // and the half-spacing shift puts the INK, not the text item, in the middle.
            readonly property real tight: -clockText.font.letterSpacing
            readonly property real pad: Math.max(8, 2 * tight)
            readonly property real textX: pad - tight / 2
            width: clockText.width + 2 * pad
            height: clockText.height
            readonly property real inkMid: clockText.baselineOffset + tmClock.tightBoundingRect.y + tmClock.tightBoundingRect.height / 2
            readonly property real k: root.smallK * root.fromK + (1 - root.smallK * root.fromK) * root.fly
            transform: [
                Scale { origin.x: clockBox.width / 2; origin.y: clockBox.inkMid; xScale: clockBox.k; yScale: clockBox.k },
                Translate { x: root.flyX - root.heroCx; y: root.flyY - root.heroCy }
            ]
            // a hair above 0 (not a hard 0) before the flight so Qt paints it invisibly
            // and builds its FBOs warm; a true 0 once we are unlocking leaves no ghost
            // (from the pill it stays unseen until it has cleared the pill: over the
            // padlock it would be a second, tiny clock sitting on the glyph)
            // and its warm-up is fainter still there: a pill with a padlock has no clock
            // on it to hide a 1% ghost under)
            opacity: Math.max(LockState.unlocking ? 0 : (root.menuHeld ? 0.004 : 0.01),
                              root.menuHeld ? root.ramp(root.clearT, root.clearT + 0.15, root.flyT) : root.ramp(0.0, 0.12, root.flyT))
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.3)
                shadowBlur: 0.9
                shadowVerticalOffset: 3
                blurMax: 48
            }

            Item {
                id: clockMask             // the mask: box-sized, so it lines up with the blur
                anchors.fill: parent
                visible: false
                layer.enabled: true
                // The time as ONE text is still here, unseen: it is what everything is
                // measured from (the box, the ink's middle, the flight). What is drawn is
                // RollDigits, the same time a character at a time, so a digit can roll.
                Text {
                    id: clockText
                    x: clockBox.textX
                    opacity: 0
                    text: Qt.formatDateTime(clk.date, "hh:mm")
                    font.family: "SF Compact Rounded"
                    font.weight: 800
                    font.pixelSize: Math.round(root.height * 0.28)
                    font.letterSpacing: -Math.round(root.height * 0.010)
                    color: "white"
                    renderType: Text.CurveRendering   // distance fields go lumpy at this size
                }
                RollDigits { x: clockBox.textX; ink: "white" }   // mask ink: only its alpha is used
            }
            Item {
                id: glassPaper
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Image {
                    // the box's place on the screen, undone, so this copy sits pixel for
                    // pixel on the wallpaper behind it and follows its ease
                    x: -(cluster.x + clockBox.x)
                    y: -(cluster.y + clockBox.y)
                    width: root.width
                    height: root.height
                    source: paper.source
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: width
                    sourceSize.height: height
                    scale: paper.scale
                    transformOrigin: Item.Center
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: glassPaper
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                brightness: 0.38
                saturation: 0.5
                // no auto padding: it grows the effect past the box for the blur and
                // stretches the mask with it, so the digits come out a size too big and
                // off their own shadow. The spread softens the mask's edge (it is a hard
                // threshold otherwise, and the curves stair-step).
                autoPaddingEnabled: false
                maskEnabled: true
                maskSource: clockMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            RollDigits { x: clockBox.textX; ink: Theme.alpha(Theme.foreground, 0.16) }
        }
        Text {
            id: dateText
            visible: cluster.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clk.date, "dddd, MMMM d")
            font.family: Theme.fontDisplay
            font.weight: 600
            font.pixelSize: Math.round(root.height * 0.026)
            color: Theme.accent
            // comes up last, once the clock has all but landed, and is first to go
            opacity: Math.max(LockState.unlocking ? 0 : 0.01, root.ramp(0.55, 1.0, root.flyT))
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0,0,0,0.35); shadowBlur: 0.5; shadowVerticalOffset: 1; blurMax: 16 }
        }
    }

    // The big clock's digits ROLL when the time changes, the way the bar's small clock
    // does (Bar.qml's timeText, same motion): the old digit travels up and fades while
    // the new one rises into its place, and only the digits that changed move.
    // Each character sits exactly where the one-piece text has it: its x is the width of
    // everything before it (letter spacing included), measured in the same font. A cell
    // is wider than its character by `pad` each side, because the letter spacing here is
    // negative and a cell of the bare advance would shave the glyph's edges; it is the
    // cell's top and bottom that do the masking. There are two of these, the glass's mask
    // and the pale wash over it, and they roll together off the same text.
    component RollDigits: Item {
        id: rd
        property color ink: "white"
        readonly property string str: clockText.text
        readonly property real pad: clockBox.pad
        width: clockText.width
        height: clockText.height
        Repeater {
            model: rd.str.length
            delegate: Item {
                id: cell
                required property int index
                readonly property string ch: rd.str.charAt(cell.index)
                TextMetrics { id: before; font: clockText.font; text: rd.str.slice(0, cell.index) }
                TextMetrics { id: chM; font: clockText.font; text: cell.ch }
                x: before.advanceWidth - rd.pad
                width: chM.advanceWidth + 2 * rd.pad
                height: rd.height
                clip: true

                // what is on screen; lags `ch` by one roll (set by hand: a binding would
                // already hold the new digit by the time the change handler compares)
                property string shown: ""
                property bool ready: false
                Component.onCompleted: { shown = ch; ready = true; }
                onChChanged: {
                    if (!cell.ready || cell.shown === cell.ch) return;
                    outT.text = cell.shown;
                    cell.shown = cell.ch;
                    roll.restart();
                }
                // (two plain Texts: an inline component cannot be declared inside another)
                Text { id: curT; x: rd.pad; y: 0; text: cell.shown; font: clockText.font; color: rd.ink; renderType: Text.CurveRendering }
                Text { id: outT; x: rd.pad; opacity: 0; font: clockText.font; color: rd.ink; renderType: Text.CurveRendering }
                ParallelAnimation {
                    id: roll
                    NumberAnimation { target: curT; property: "y"; from: cell.height * root.rollTravel; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                    NumberAnimation { target: curT; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                    NumberAnimation { target: outT; property: "y"; from: 0; to: -cell.height * root.rollTravel; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                    NumberAnimation { target: outT; property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                }
            }
        }
    }
    // how far a digit travels in a roll, as a part of the clock's line height (the bar's
    // small clock uses the same 0.6)
    readonly property real rollTravel: 0.35

    // ── THE ISLAND ──
    // The bar's island, carried onto the lock screen: same outline (config/IslandShape.js),
    // same fill, same shadow, and on the first frame the same place and size with the same
    // time in it, so it lands on the real one and nobody sees a second island arrive. From
    // there it is the only thing on the screen that acts:
    //   rest     a small pill around a closed padlock (the time has left for the center);
    //   typing   the padlock melts into the first dot, and the pill grows a dot at a time
    //            with the password. There is no prompt and no caret: with nothing typed
    //            the padlock is what you see, always;
    //   checking the dots breathe while PAM decides;
    //   wrong    it shakes with a red rim, the dots go, and it is the padlock again;
    //   unlock   the dots fade, the padlock swings open, and the pill grows back into the
    //            bar's as the time comes home, ready for the real island to take over.
    // It hangs from its top edge like the bar's does.
    Item {
        id: isle
        readonly property real idleW: 2 * Math.round((root.restH + 22) / 2)
        // The width is three parts added up, because they mean different things:
        //   homeW  the pill itself: the bar's resting pill at home, pulled in around the
        //          padlock once the time has left. `pull` (0 = resting pill, 1 = pulled
        //          in) is animated by hand, not by a Behavior, because the two ways are
        //          not the same motion:
        //            in    let go only once the time has cleared the pill's bottom edge
        //                  (`clearT`), on the bouncy spring: it closes past the padlock
        //                  pill and springs back;
        //            home  let go at the very start of the way home and with NO ring, so
        //                  the pill is simply back at full size before the time arrives
        //                  (the time is never wider than the pill it is inside);
        //   kick   the bounce on the way home. It belongs to the LANDING: when the time
        //          has come to rest in the pill, the pill jumps out a few pixels, swings
        //          back past its resting size and settles on it exactly, as if the time
        //          landing set it off. Before, the pill's own spring had rung out while the time was
        //          still on its way;
        //   extraW what the password dots add on top.
        property real pull: root.fromPill ? 1 : 0
        readonly property real homeW: root.restW + (idleW - root.restW) * pull
        readonly property bool pulled: root.pillHeld || (root.out && root.flyT > root.clearT)
        onPulledChanged: {
            if (!root.primed) { pullIn.stop(); pullHome.stop(); pull = pulled ? 1 : 0; return; }
            if (pulled) { pullHome.stop(); kickAnim.stop(); kickT = 1; pullIn.restart(); } else { pullIn.stop(); pullHome.restart(); }
        }
        NumberAnimation { id: pullIn; target: isle; property: "pull"; to: 1; duration: Theme.dur(Theme.dBounce); easing.type: Easing.Bezier; easing.bezierCurve: Theme.bounceBezier }
        NumberAnimation { id: pullHome; target: isle; property: "pull"; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
        // The island steps DOWN while the screen is locked, and goes back up on unlock.
        // It rides the same moment as the pull: down once the time has cleared the pill
        // (on the spring, so it lands with a little life), and home from the very start of
        // the way back, with no ring, so the island is in the bar's exact place again
        // before the time arrives in it and long before the ground lifts. Not before our
        // first frame, and not as a notch, which is part of the screen's edge.
        readonly property real dropPx: root.notchForm ? 0 : 30
        // (from the open island, not before the time takes off: until then we are
        // standing in for the bar's island and must not move under its time)
        readonly property bool lowered: root.primed && pulled && (!root.islandHeld || root.out)
        property real drop: 0
        onLoweredChanged: {
            if (lowered) { dropHome.stop(); dropIn.restart(); } else { dropIn.stop(); dropHome.restart(); }
        }
        NumberAnimation { id: dropIn; target: isle; property: "drop"; to: isle.dropPx; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        NumberAnimation { id: dropHome; target: isle; property: "drop"; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
        // The kick is a struck spring, written out: a sine under a decaying envelope,
        // read off a plain linear clock (kickT 0 -> 1). An easing curve can only go from
        // A to B; this starts and ends at rest and rings in between: out to the full kick
        // in ~70ms, back through to about a third of it the other way, and still. Scaled
        // by the Settings bounce, so no bounce there means no kick here.
        property real kickT: 1
        readonly property real kick: kickT >= 1 ? 0 : Math.exp(-4.1 * kickT) * Math.sin(11 * kickT) / 0.6 * (1 - kickT)
        readonly property real kickPx: (root.restW - idleW) * 0.26 * Math.min(1, (1 - Theme.springDamping) / 0.2)
        readonly property bool landed: !root.out && root.flyT <= 0.004
        // (only once we are on the glass: `landed` also reads true while the item is
        // being built, and that fired a kick at the very start of every lock)
        onLandedChanged: if (landed && root.primed && !Theme.reducedMotion) kickAnim.restart()
        NumberAnimation { id: kickAnim; target: isle; property: "kickT"; from: 0; to: 1; duration: Math.round(Theme.dSpring * 1.5) }
        readonly property real dotD: 7
        readonly property real dotPitch: dotD + 6
        readonly property int dotMax: 40
        readonly property int dotN: Math.min(root.shownN, dotMax)
        property real extraW: Math.max(0, dotN * dotPitch - 6 + 2 * (idleW - 16) / 2 - idleW)
        Behavior on extraW { NumberAnimation { duration: Theme.dur(Theme.dBounce); easing.type: Easing.Bezier; easing.bezierCurve: Theme.bounceBezier } }
        // the dots are laid out around the middle for this many of them; it follows the
        // real count on the same spring as the width, so they slide apart as the pill
        // grows and a new one never makes the others jump
        property real dotNA: dotN
        Behavior on dotNA { NumberAnimation { duration: Theme.dur(Theme.dBounce); easing.type: Easing.Bezier; easing.bezierCurve: Theme.bounceBezier } }
        // From the power menu: `menuT` is how much of the menu is left. At 1 the island
        // is the menu's island to the pixel (same width, same height, and a copy of the
        // menu inside it, see menuCopy), so our first frame lands on the bar's; from there
        // it runs to 0 on the shell's spring and what is left is the padlock pill.
        property real menuT: root.menuOn ? 1 : 0
        property bool menuDone: false
        readonly property bool menuShown: root.menuOn && !menuDone
        readonly property real menuW: root.menuOn ? (LockState.pillFrom.w - idleW) * menuT : 0
        readonly property real menuH: root.menuOn ? (LockState.pillFrom.h - root.restH) * menuT : 0
        readonly property real liveW: homeW + extraW + menuW + kick * kickPx
        // even widths on a whole-pixel x, exactly as the bar rounds its own
        width: 2 * Math.round(liveW / 2)
        height: root.restH + menuH
        x: Math.round((root.width - width) / 2)
        y: root.restY + drop
        visible: root.isleUp
        // the bar's own corner rule: the pill's radius, opening up as it gets taller
        readonly property real rad: Math.min(width / 2, height / 2,
                    Theme.rIsland + (Theme.rIslandOpen - Theme.rIsland)
                      * Math.max(0, Math.min(1, (height - root.restH) / Math.max(1, 2 * Theme.rIslandOpen - root.restH))))
        readonly property real flare: root.notchForm ? Math.max(0, Math.min(Config.notchFlare, height - Math.min(rad, height / 2), width / 2)) : 0
        property bool err: false
        // ONE shadow on the screen, always. While the bar's island is drawn underneath
        // (before it has hidden on lock, and again from the moment we start unlocking) its
        // shadow shows through the ground wherever the ground is not opaque, and ours on
        // top of it doubled up: the shadow was darker until teardown, then dropped to the
        // real one. So ours is only as strong as the ground is opaque while the bar's is
        // there, and the two always add up to one.
        readonly property bool realUnder: LockState.covered[root.screenName] !== true
        readonly property real shadowK: realUnder ? ground.opacity : 1
        transform: Translate { id: shakeT; x: 0 }

        Shape {
            id: isleFill
            readonly property real over: root.notchForm ? 4 : 0
            y: -over
            x: Math.round((parent.width - width) / 2)
            width: isle.width + 2 * isle.flare
            height: isle.height + over
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: Theme.shadows
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowOpacity: isle.shadowK
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
            }
            ShapePath {
                fillColor: Theme.base
                strokeColor: isle.err ? Theme.alpha(Theme.bad, 0.9) : Theme.hairline
                strokeWidth: isle.err ? 1.5 : (root.notchForm ? 0 : 1)
                Behavior on strokeColor { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                PathSvg {
                    path: IslandShape.notchPath(isle.width, isle.height + isleFill.over,
                                                root.notchForm ? 0 : isle.rad, Math.min(isle.rad, isle.height / 2), isle.flare)
                }
            }
        }

        // The padlock, drawn on the icon set's 24 grid with its stroke so it sits in the
        // family: a body with a keyhole dot, and the shackle as its own piece so it can
        // swing open about its right leg when the password is taken. Always in the middle
        // of the pill. Two things decide how much of it there is, multiplied:
        //   `flown` it pops out of the middle, on a spring, once the time has cleared the
        //           pill, and is let go at the start of the way home;
        //   `held`  it melts away the moment there is a dot to show, and comes back when
        //           there are none.
        Item {
            id: padlock
            readonly property real size: 16
            readonly property real sw: Math.max(Theme.iconStroke, Theme.iconStrokeFloor * 24 / size)
            readonly property bool open: LockState.unlocking
            property real flown: (root.pillHeld || (root.out && root.flyT > root.clearT + 0.04)) ? 1 : 0
            Behavior on flown { enabled: root.primed; NumberAnimation { duration: Theme.dur(Theme.dBounce); easing.type: Easing.Bezier; easing.bezierCurve: Theme.bounceBezier } }
            // Going, it melts at once, under the first dot as that lands. Coming back it
            // waits for the dots to be all but gone first, so it never shows through
            // them. It does not come back for the unlock: the pill is empty for the
            // moment it takes to grow back and take the time in.
            readonly property bool want: root.shownN === 0 && !LockState.unlocking
            property real held: 1
            onWantChanged: { if (want) { heldOut.stop(); heldIn.restart(); } else { heldIn.stop(); heldOut.restart(); } }
            SequentialAnimation {
                id: heldIn
                PauseAnimation { duration: Theme.dur(Math.round(Theme.dEffects * 0.7)) }
                NumberAnimation { target: padlock; property: "held"; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
            }
            NumberAnimation { id: heldOut; target: padlock; property: "held"; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
            width: size; height: size
            x: (isle.width - size) / 2
            y: (isle.height - size) / 2
            // (while the menu's copy is still up, its own lock glyph is the padlock.
            // The open island has no glyph to hand over: the padlock comes up in the
            // middle as the island finishes closing, over the last third of the way)
            readonly property real arrive: root.fromShot ? root.ramp(0.66, 1.0, 1 - isle.menuT) : (isle.menuShown ? 0 : 1)
            opacity: arrive * Math.max(0, Math.min(1, flown)) * held
            scale: (0.4 + 0.6 * flown) * (0.3 + 0.7 * held) * (0.4 + 0.6 * arrive)
            transformOrigin: Item.Center
            // Built through a one-row Repeater keyed on the stroke width: the curve
            // renderer DROPS a stroke whose width changes after the shape exists (seen when
            // the config, and so the icon stroke floor, loaded a moment after creation: the
            // padlock never drew). A new width makes new shapes instead of changing these.
            Repeater {
                model: [padlock.sw]
                delegate: Item {
                    id: lockArt
                    required property real modelData
                    width: 24; height: 24
                    scale: padlock.size / 24
                    transformOrigin: Item.TopLeft
                    Shape {
                        anchors.fill: parent
                        antialiasing: true
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Theme.inkPrimary
                            strokeWidth: lockArt.modelData
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: "M6.5,9 H17.5 a1.5,1.5 0 0,1 1.5,1.5 V19.5 a1.5,1.5 0 0,1 -1.5,1.5 H6.5 a1.5,1.5 0 0,1 -1.5,-1.5 V10.5 a1.5,1.5 0 0,1 1.5,-1.5 Z M12,15 L12,15.01" }
                        }
                    }
                    Shape {
                        anchors.fill: parent
                        antialiasing: true
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Theme.inkPrimary
                            strokeWidth: lockArt.modelData
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: "M8,9 V6.5 a4,4 0 0,1 8,0 V9" }
                        }
                        transform: Rotation {
                            origin.x: 16; origin.y: 9
                            angle: padlock.open ? 34 : 0
                            Behavior on angle { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                        }
                    }
                }
            }
        }

        // The power menu, carried over: the same component the bar shows, at the same
        // inset, so frame one is the bar's menu pixel for pixel. It is told it is
        // `locking` on our first frame, fades everything but its lock glyph and brings
        // that to the middle as the island closes around it; when the island is the pill
        // it is dropped and the padlock above (the same drawing, in the same place) is
        // what is left. It never takes input here.
        Loader {
            id: menuCopy
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: isle.menuShown && !root.fromShot
            enabled: false
            sourceComponent: LogoutContent { pillH: root.restH; locking: root.primed }
        }

        // The open island's contents, carried over: the bar's own picture of them, laid
        // where the bar had them, so frame one is the open island as it stood. The big
        // time is painted out of the picture (the island's fill over it): the time here
        // is `inkTime`, on top, and it is about to leave. The rest goes by the rule the
        // bar closes with (Bar.qml `openFade`): gone while the island is still mostly
        // open, so the closing edge has nothing to cut. Clipped to the island, and held
        // to the screen, not to the island's shrinking left edge.
        Item {
            anchors.fill: parent
            clip: true
            visible: root.fromShot && isle.menuShown
            Item {
                id: shot
                readonly property var from: root.fromShot ? LockState.pillFrom : null
                x: from ? (isle.width - from.w) / 2 + from.gx : 0
                y: from ? from.gy : 0
                width: from ? from.gw : 0
                height: from ? from.gh : 0
                opacity: Math.max(0, Math.min(1, (isle.menuT - 0.6) / 0.32))
                visible: opacity > 0.01
                layer.enabled: true     // one sheet: the paint-out fades WITH the picture, not over it
                Image {
                    id: shotImg
                    anchors.fill: parent
                    source: LockState.pillShot ? LockState.pillShot.url : ""
                    cache: false
                }
                Rectangle {
                    visible: root.fromIsland
                    color: Theme.base
                    width: Math.ceil(inkTime.width * root.fromK) + 6
                    height: Math.ceil(tmInk.tightBoundingRect.height * root.fromK) + 14
                    x: shot.from ? shot.from.tx - isle.x - shot.x - width / 2 : 0
                    y: shot.from ? shot.from.ty - root.restY - shot.y - height / 2 : 0
                }
            }
        }

        // The password: one dot per character, centered in the pill, the first one landing
        // where the padlock was. A fixed set of dots that switch on and off (not a model
        // that grows), so a dot can ease in when typed and ease out when deleted, and the
        // row slides to stay centered. Past `dotMax` characters the row stops growing.
        Item {
            id: dots
            anchors.fill: parent
            // breathes while PAM is checking, and is solid the rest of the time
            property real pulse: 1
            opacity: pulse
            SequentialAnimation {
                running: LockState.authenticating && !Theme.reducedMotion
                loops: Animation.Infinite
                onStopped: settle.restart()
                NumberAnimation { target: dots; property: "pulse"; to: 0.35; duration: 420; easing.type: Easing.InOutQuad }
                NumberAnimation { target: dots; property: "pulse"; to: 1.0; duration: 420; easing.type: Easing.InOutQuad }
            }
            NumberAnimation { id: settle; target: dots; property: "pulse"; to: 1; duration: Theme.dur(Theme.dFast) }
            Repeater {
                model: isle.dotMax
                delegate: Rectangle {
                    id: dot
                    required property int index
                    readonly property bool on: index < isle.dotN
                    width: isle.dotD; height: isle.dotD; radius: isle.dotD / 2
                    color: Theme.inkPrimary
                    x: isle.width / 2 + (index - (isle.dotNA - 1) / 2) * isle.dotPitch - width / 2
                    y: (root.restH - height) / 2
                    visible: opacity > 0
                    opacity: on ? 1 : 0
                    scale: on ? 1 : 0.2
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                    Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dBounce); easing.type: Easing.Bezier; easing.bezierCurve: Theme.bounceBezier } }
                }
            }
        }

        // The field itself is never seen: it only takes the keys. What is typed is shown
        // as the dots above and nothing else.
        TextInput {
            id: pwField
            width: 1; height: 1
            opacity: 0
            echoMode: TextInput.Password
            passwordCharacter: ""
            cursorVisible: false
            enabled: root.typing && LockState.prompting && !LockState.authenticating && !LockState.unlocking
            // the dots follow the field, except while PAM is checking: the field is
            // emptied the moment it is submitted, and the dots stay up until the answer
            onTextChanged: if (!LockState.authenticating) root.shownN = text.length
            onAccepted: { LockState.submit(text); text = ""; }
            // Escape clears what is typed; on an EMPTY field it hands the keyboard back
            // to the key catcher
            Keys.onEscapePressed: {
                if (text !== "") { text = ""; return; }
                root.typing = false;
                keyCatcher.forceActiveFocus();
            }
        }
    }

    // ── the time, in the bar's ink ──
    // The other half of the flight. At rest in the island it IS the bar's clock: the same
    // face, size, weight and per-character advances, centered where the bar centers its
    // own, so the hand-off from the real island is onto identical pixels. As the island
    // lets go of it, it rides the same line as the glass clock at the same size, and the
    // two trade places in the first eighth of the way, while the time is still at the
    // island's lip, so one time appears to leave the island and turn to glass.
    Row {
        id: inkTime
        z: 2
        readonly property string timeStr: Qt.formatDateTime(clk.date, Config.clock24h ? "HH:mm" : "h:mm AP")
        readonly property real k: root.fromK + (1 / Math.max(0.01, root.smallK) - root.fromK) * root.fly
        x: root.flyX - width / 2
        // (the open island's place already has the notch's lift in it)
        y: root.flyY - height / 2 - (root.notchForm && !root.islandHeld ? 1.5 : 0) * (1 - Math.min(1, root.fly))
        spacing: 0
        scale: k
        transformOrigin: Item.Center
        opacity: root.menuHeld ? 0 : 1 - root.ramp(0.0, 0.12, root.flyT)
        visible: opacity > 0 && root.isleUp
        TextMetrics { id: tmInk; font.family: Theme.fontDisplay; font.pixelSize: Theme.fsClock; font.weight: Theme.wSemiBold; text: "0" }
        FontMetrics { id: inkFm; font.family: Theme.fontDisplay; font.pixelSize: Theme.fsClock; font.weight: Theme.wSemiBold }
        Repeater {
            model: inkTime.timeStr.length
            delegate: Item {
                id: cell
                required property int index
                readonly property string ch: inkTime.timeStr.charAt(cell.index)
                width: chM.advanceWidth
                height: inkFm.height
                TextMetrics { id: chM; font.family: Theme.fontDisplay; font.pixelSize: Theme.fsClock; font.weight: Theme.wSemiBold; text: cell.ch }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.ch
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fsClock
                    font.weight: Theme.wSemiBold
                    color: Theme.inkPrimary
                    renderType: Text.QtRendering
                }
            }
        }
    }

    // wrong-password feedback: the island shakes with a red rim, still holding the dots
    // that were tried; then the dots go and it is the padlock again, and the rim fades.
    // A correct one: the dots fade as the exit starts.
    Connections {
        target: LockState
        function onErrorMsgChanged() {
            if (LockState.errorMsg !== "") {
                pwField.text = "";
                isle.err = true;
                shake.restart();
                dotsGo.restart();
                errClear.restart();
            }
        }
        function onUnlockingChanged() { if (LockState.unlocking) root.shownN = 0; }
    }
    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeT; property: "x"; to: -10; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; to: 9;  duration: 60 }
        NumberAnimation { target: shakeT; property: "x"; to: -6; duration: 55 }
        NumberAnimation { target: shakeT; property: "x"; to: 3;  duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 0;  duration: 45 }
    }
    // after the shake: back to whatever is in the field, which is nothing unless a new
    // try was started in the meantime
    Timer { id: dotsGo; interval: 300; onTriggered: root.shownN = pwField.text.length }
    Timer { id: errClear; interval: 800; onTriggered: isle.err = false }

    // focus the key-catcher so the very first keystroke is the first dot
    function grabFocus() { keyCatcher.forceActiveFocus(); }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../../config"
import "../../config/IslandShape.js" as IslandShape
import "../../services"
import "../../components"
import "../launcher"
import "../controlcenter"
import "../notifications"
import "../osd"
import "../wallpaper"
import "../theme"
import "../logout"
import "../polkit"
import "../calendar"

// The notch (one per screen): a "dynamic island" that floats below the top edge
// (small gap above and below, all corners rounded, subtle shadow, the only bit of
// depth we let in). Collapsed it's the clock with the workspace capsules beside it (the
// group stays centered).
// Hover or click-to-pin springs it open to a media player (left), clock + date
// (center), and a control-center pill (right). Every size/radius/motion comes
// from Theme tokens. Modeled on notch-bar.html.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:bar"
    anchors { top: true; left: true; right: true }
    // Reserve a strip so windows tile BELOW the island, with the gap under the
    // (collapsed) island matching the gap above it (topGap). Hyprland piles gaps_out
    // on top of the reserved edge, so subtract it or the two stack and the window
    // sits too far down. The wallpaper ignores this (fills the screen → no band).
    exclusionMode: ExclusionMode.Normal
    // reserve the floating-island strip (gap above and below the collapsed island).
    // notch: no gap above (flush), so reserve just the notch height + the below gap.
    exclusiveZone: notchMode ? Math.max(0, topGap + collapsedH - gapsOut)
                 : Math.max(0, topGap * 2 + collapsedH - gapsOut)
    // Full-height ALWAYS: transparent and click-through via the mask except for the
    // island. Resizing the window on open (116 → full) is what gave us the morph flash,
    // 'cause the layer-surface reconfigure briefly yanked the island upward before it
    // settled. Keep it a constant size and opening the launcher never reconfigures the
    // window. Still anchored top/left/right (never bottom) so the exclusiveZone keeps
    // reserving only the strip and tiled windows sit below the island.
    implicitHeight: modelData?.height ?? 1600
    color: "transparent"
    // EXCLUSIVE keyboard focus while a panel's open so keystrokes stay with the
    // launcher/CC even under focus-follows-mouse (OnDemand let the pointer steal focus).
    WlrLayershell.keyboardFocus: morphWanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // input mask: the morph backdrop (click-outside) when a panel's open, else the bar
    // itself.
    mask: Region {
        // the clicked-open island takes the backdrop too, so a click anywhere else closes it
        item: (morphWanted || pinned) ? backdrop : notch
        Region { item: (!bar.morphWanted && transientHost.shown) ? transientHost : null }
    }

    property bool pinned: false
    // Hover OPENS the island; leaving closes it again. A click PINS it open, and a pinned
    // island stays until it is clicked again or a click lands anywhere else.
    readonly property bool expanded: hover.hovered || pinned || GlobalState.islandHold || returnHold || lockHold
    // held open for the moment between a lock and the lock screen covering it (see the
    // LockState connections below)
    property bool lockHold: false
    readonly property bool playing: Media.player?.isPlaying ?? false

    // When a panel closes with the cursor still over its (tall) area, the hover handler
    // would immediately report hovered → the island would flash its expanded/hover state
    // before shrinking below the cursor. Suppress hover for the collapse animation so it
    // drops straight to the collapsed notch/island instead; a fresh hover afterward works.
    property bool closeGuard: false
    Timer { id: closeGuardTimer; interval: Theme.dur(Theme.dSpring) + 80; onTriggered: bar.closeGuard = false }
    // A panel can ask to hand back to the EXPANDED island instead of closing to the pill
    // (the calendar's header does). Then there is no close guard: the island is held
    // open so the panel morphs straight into it, and the hold lets go as soon as the
    // pointer is found over the island (hover takes over) or after a moment if it never is.
    property bool returnHold: false
    // long enough for the panel to come down into the island (one spring) plus a beat to
    // see it; then hover decides. `returnLinger` is that beat.
    readonly property int returnLinger: 350
    Timer { id: returnHoldTimer; interval: Theme.dSpring + bar.returnLinger; onTriggered: bar.returnHold = false }
    onMorphWantedChanged: {
        if (!morphWanted) {
            if (GlobalState.returnToIsland && onFocusedMon) {
                GlobalState.returnToIsland = false;
                returnHold = true; returnHoldTimer.restart();
            } else { closeGuard = true; closeGuardTimer.restart(); }
        }
        else { pinned = false; returnHold = false; }    // a panel taking the island lets go of the pin
    }

    // launcher state: the island ITSELF morphs into the launcher, no extra layer
    readonly property bool onFocusedMon: (Hyprland.focusedMonitor?.name ?? "") === (modelData?.name ?? "x")
    // polkit (privilege escalation) is the top-priority morph: the agent drives it (not
    // a GlobalState toggle), and it SUPPRESSES the other panels so nothing open can ever
    // overlap an auth prompt.
    readonly property bool polkitWanted: Polkit.active && onFocusedMon
    readonly property bool launcherWanted: GlobalState.launcherOpen && onFocusedMon && !polkitWanted
    readonly property bool ccWanted: GlobalState.controlCenterOpen && onFocusedMon && !polkitWanted
    readonly property bool wallpaperWanted: GlobalState.wallpaperPickerOpen && onFocusedMon && !polkitWanted
    readonly property bool themeWanted: GlobalState.themeSwitcherOpen && onFocusedMon && !polkitWanted
    readonly property bool logoutWanted: GlobalState.logoutOpen && onFocusedMon && !polkitWanted
    readonly property bool calendarWanted: GlobalState.calendarOpen && onFocusedMon && !polkitWanted
    // any of these panels morphs the island; the window's full-height already, so this
    // just drives keyboard focus + the click-outside backdrop + the input mask.
    readonly property bool morphWanted: polkitWanted || launcherWanted || ccWanted || wallpaperWanted || themeWanted || logoutWanted || calendarWanted
    // a volume/brightness change morphs the island into a level pill (auto-hide), on the
    // monitor the OSD fired for. Beats a notification ('cause that's direct feedback to a
    // keypress), but never beats launcher/CC, those own the island.
    readonly property bool osdWanted: !morphWanted && OsdState.active && OsdState.screen === (modelData?.name ?? "")
    // a transient notification morphs the island to show it (auto-dismiss), but only
    // when idle (nothing else up: launcher/CC/OSD) and on the focused monitor.
    readonly property bool notifWanted: !morphWanted && !osdWanted && onFocusedMon && Notifications.showing !== null
    // Notch mode: instead of the floating island, the bar hangs flush from the top edge
    // with SQUARE top corners and a ROUNDED bottom (a hardware-notch look). Toggled from
    // settings (Config.notchMode).
    readonly property bool notchMode: Config.notchMode

    // ── shape morph clocks ────────────────────────────────────────────────────────────────
    // Switching island↔notch used to hard-swap two different fills (a rounded Rectangle and
    // the teardrop Shape) via `visible`, so one popped out as the other popped in while the
    // geometry animated underneath — that was the chop. Now there's ONE shape that morphs,
    // driven by these. Everything positional reads them too, so the whole switch runs off a
    // single clock and nothing steps.
    property real notchT: notchMode ? 1 : 0        // 0 = island, 1 = notch
    Behavior on notchT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
    // how "flush to the top edge" we are. Derived, so it's already continuous.
    readonly property real flushT: notchT

    // notch bottom radius (clamped to fit the current height) and the effective flare
    // (concave top-corner radius), clamped so the arcs always fit no matter the state.
    // real, not int: notch.rad interpolates continuously with the height, so rounding these to
    // whole px would re-quantize the corner into visible 1px jumps mid-animation.
    readonly property real notchBR: Math.min(notch.rad, notch.height / 2)
    readonly property real notchFlareRaw: Math.max(0, Math.min(Config.notchFlare, notch.height - notchBR, notch.width / 2))
    // TWO-PHASE morph, so the outline is well defined at every frame instead of trying to be a
    // rounded top and a flared top at once: for t<0.5 the top corners un-round, for t>0.5 the
    // flares grow out. Midpoint is a plain square-top / round-bottom slab, which reads fine.
    // The OUTLINE reads the clock held to 0..1 (`notchK`), not the clock itself. notchT
    // rides the bouncy spring and rings a little past both ends. Past 0 that made the
    // top radius a hair bigger than the pill is tall can hold (17.01 + 17 into a height of
    // 34): the side of the outline became a tiny stroke running backwards, and on the one
    // frame where that stroke was almost nothing the renderer lost the shape and drew a
    // hollow, torn island. That was the flicker on switching notch mode off. The position
    // (the gap above the island) still follows the real clock, so the bounce is still
    // there; only the shape stops short of an outline that cannot exist. The top radius
    // is also held to the room the bottom radius leaves, whatever else changes.
    readonly property real notchK: Math.max(0, Math.min(1, notchT))
    readonly property real notchFlareEff: notchFlareRaw * Math.max(0, 2 * notchK - 1)
    readonly property real notchTopR: Math.max(0, Math.min(notch.rad * Math.max(0, 1 - 2 * notchK), notch.height + 4 * notchK - notchBR))

    // The outline covering BOTH forms, rounded-top island through to the flared notch. It
    // lives in config/IslandShape.js so the lock screen's island is drawn from the same one.
    function notchPath(bw, h, tr, br, fr) { return IslandShape.notchPath(bw, h, tr, br, fr); }

    readonly property int topGap: Config.islandGap  // gap above the island (and below it too, via exclusiveZone)
    readonly property int gapsOut: Config.hyprGapsOut // must match Hyprland general:gaps_out (top); subtract it or it stacks
    // The resting pill is at least the configured width, and grows to fit what the collapsed
    // clock row carries (capsules, glyphs) so verbose content never clips. Computed from the
    // row's SETTLED parts, never from timeRow.width: on a collapse the capsule and glyph
    // wrappers spring open over ~200ms, and a target that moved every frame restarted the
    // island's width animation every frame, so the island hung near its open width until
    // the wrappers settled and only then dropped (logged: 688 -> 568 in the first 200ms
    // while the target climbed 90 -> 252, then 16px a frame). One fixed target, one motion.
    // what the collapsed pill shows beside the time
    readonly property bool dotsOn: Config.clockDots && ws.count > 0
    readonly property bool statusOn: Config.clockStatus
    // The companions' rooms either side of the time. When BOTH are in they take the same
    // room, the wider one's, so the pill is symmetric about the time and the time holds
    // the island's center line as they arrive together (both toggled on in Settings);
    // before, the centered row shifted it by half the difference of the two rooms. A lone
    // companion takes only its own room: no mirrored air on the empty side.
    readonly property real restRoomL: dotsOn ? (statusOn ? Math.max(ws.restW, st.restW) : ws.restW) + wsWrap.pad : 0
    readonly property real restRoomR: statusOn ? (dotsOn ? Math.max(ws.restW, st.restW) : st.restW) + wsWrap.pad : 0
    readonly property real restRowW: timeText.width + (dotsOn ? restRoomL + Theme.s5 : 0) + (statusOn ? restRoomR + Theme.s5 : 0)
    // EVEN widths, always: the island is centered on the screen, so an odd width puts its
    // edges on half pixels and the text inside snaps a pixel sideways between one settled
    // width and the next (the clock moved 1px between two settled pill widths)
    readonly property int collapsedW: 2 * Math.ceil(Math.max(Config.islandCollapsedWidth, Math.round(restRowW) + 2 * Theme.s3 + Theme.s4) / 2)
    readonly property int collapsedH: Math.max(34, Config.barHeight + 4)
    // The lock screen carries its own copy of the island and starts it on this exact pill,
    // so it is told the pill's size; while that copy is up this one is not drawn, so
    // there is only ever one island on the screen (see LockContent's `isle`).
    readonly property var lockRest: ({ w: collapsedW, h: collapsedH })
    onLockRestChanged: LockState.setRest(modelData?.name ?? "", lockRest)
    readonly property bool lockCovered: LockState.locked && !LockState.unlocking && LockState.covered[modelData?.name ?? ""] === true
    Connections {
        target: LockState
        // nothing may be open under the lock: when it lifts, the island the lock screen
        // hands back to has to be the resting pill
        // Locked with the island OPEN (the pointer on it, or pinned). The lock screen
        // starts its own island on the resting pill, so the open island used to be
        // swapped for a small pill in one frame. Now the lock screen starts as this
        // island, as it is this instant: it is told the island's size, where the big
        // time is and how big, and where the contents sit, and it gets a picture of the
        // contents. From there the lock screen plays it: the big time flies to the
        // middle, the rest fades and the island closes around the padlock. This island
        // holds still until the lock screen's copy is over it (`lockHold`), then closes
        // unseen, so what the unlock hands back to is the pill.
        // (Here and not in onLockedChanged: by then the lock has switched the hover off
        // and a hovered island no longer knows it was open.)
        // Locked with a PANEL open (launcher, control center, a switcher, the calendar):
        // the same hand-over. The panels used to be closed the instant the lock engaged,
        // so the island was springing shut under a lock screen that had already drawn
        // its small pill on top of it, and the panel then vanished in one frame. Now the
        // lock screen starts as the panel's island with a picture of the panel in it,
        // fades that and closes around the padlock; the panel itself stays as it is
        // until the lock screen's copy is over it, then closes unseen (onCoveredChanged).
        // (Not the power menu, which hands itself over, and not the auth prompt, which
        // the lock does not close.)
        function onAboutToLock() {
            if (LockState.pillScreen !== "") return;
            const name = bar.modelData?.name ?? "";
            if (bar.morphWanted) {
                if (bar.polkitWanted || bar.logoutWanted) return;
                LockState.pillKind = "panel";
                const from = { w: notch.width, h: notch.height, gx: 0, gy: 0, gw: notch.width, gh: notch.height };
                // the control center has a time of its own, top left: that is the one
                // that becomes the lock screen's clock (as the open island's big time
                // does), so the lock screen is told where it is and how big
                if (bar.ccWanted && controlCenter.view === "main" && !bar.clockFlying) {
                    const c = controlCenter.clockCenter();
                    from.tx = c.x; from.ty = c.y; from.ts = controlCenter.clockPx / Theme.fsClock;
                }
                LockState.pillFrom = from;
                LockState.pillScreen = name;
                morphHost.grabToImage(function(shot) {
                    if (LockState.locked && LockState.pillKind === "panel" && LockState.pillScreen === name) LockState.pillShot = shot;
                });
                return;
            }
            if (!bar.expanded) return;
            const c = timeText.mapToItem(null, timeText.width / 2, timeText.height / 2);
            const g = barRow.mapToItem(notch, 0, 0);
            LockState.pillKind = "island";
            LockState.pillFrom = { w: notch.width, h: notch.height,
                                   tx: c.x, ty: c.y, ts: timeText.scale,
                                   gx: g.x, gy: g.y, gw: barRow.width, gh: barRow.height };
            LockState.pillScreen = name;
            bar.lockHold = true;
            barRow.grabToImage(function(shot) {
                if (LockState.locked && LockState.pillKind === "island" && LockState.pillScreen === name) LockState.pillShot = shot;
            });
        }
        function onLockedChanged() {
            if (!LockState.locked) { bar.lockHold = false; return; }
            bar.pinned = false;
            bar.returnHold = false;
            // a panel that is being handed over stays until the lock screen's island is
            // over it (below)
            if (LockState.pillKind !== "panel") bar.closePanels();
            // the power menu that just morphed into the lock's pill stays as it is until
            // the lock screen's own island is over it (below): closing it now would show
            // the clock pill for the frame or two before that
            if (LockState.pillScreen === "") GlobalState.logoutOpen = false;
        }
        function onCoveredChanged() {
            if (LockState.pillScreen !== "" && bar.lockCovered) GlobalState.logoutOpen = false;
            if (LockState.pillKind === "panel" && LockState.covered[LockState.pillScreen] === true) bar.closePanels();
            if (bar.lockCovered) bar.lockHold = false;
        }
        function onUnlockingChanged() { if (LockState.unlocking) { GlobalState.logoutOpen = false; bar.closePanels(); } }
    }
    function closePanels() {
        GlobalState.launcherOpen = false;
        GlobalState.controlCenterOpen = false;
        GlobalState.wallpaperPickerOpen = false;
        GlobalState.themeSwitcherOpen = false;
        GlobalState.calendarOpen = false;
    }
    // The expanded island is the pill, grown: the workspace capsules on the left and the
    // status glyphs on the right, both larger and with air around them, the clock with the
    // big time in the middle with the media card under it while something plays. Form
    // over function: nothing that is not already in the pill's vocabulary plus the one
    // card. The sides size to their content and take the same width so the clock sits
    // dead center. With no player the island is the configured height with the time
    // centered; with one it grows to hold the card and the time lifts to the top. Each
    // part has its own Settings toggle.
    readonly property bool showWs: Config.islandWorkspaces && ws.count > 0
    // the card is always there when enabled; with no player it says so
    readonly property bool showNow: Config.islandMedia
    readonly property int wsBigPad: 8          // room for the active capsule's scale and glow
    // The media block sits to the LEFT of the time and date, on the same line: a square
    // of album art with the title and the artist beside it. `cardH` is the art's side,
    // `mediaTextW` the fixed room for the two lines of text (fixed, so a new song's
    // longer title cannot push the clock sideways), `mediaGap` the air between the block
    // and the clock.
    readonly property int cardH: 36
    readonly property int mediaTextW: 170
    readonly property int cardW: cardH + 12 + mediaTextW
    readonly property int mediaGap: 28
    // With the media block on, the island is two groups: the block against the left edge
    // and the clock against the right, both with their INK inset `wsBigPad` (the clock
    // button's own side padding hangs past that). The natural width leaves `mediaGap`
    // between them; a larger Settings min width only widens that gap, never the edges.
    // The clock is a right-aligned STACK in the open island: the hero time and the
    // workspace dots under it. (The date used to sit between the two; it is gone.)
    // `heroW` is the big time's settled width, `clockFullW` the stack's box (the time
    // plus the button's padding).
    // THE HERO CLOCK layout: a very large time against the LEFT edge with the full date
    // under it, and a small right column: the song (title and artist right-aligned, the
    // art at the end), a hairline, and the workspace dots.
    // `heroPx` is the big time's size, `colW` the right column's width, `rowOff` how far
    // its two rows sit above and below the island's center line.
    readonly property int heroPx: 40
    readonly property int colW: 250
    readonly property int rowOff: 18
    // The song row is taller than the dots' row (the art against a line of dots), so
    // two rows set the same distance from the island's center line leave the column
    // sitting high: more air under it than over it. The whole column drops by a quarter
    // of that difference, which puts the art's top and the glyphs' bottom the same
    // distance from the island's edges.
    readonly property int colDrop: Math.round((cardH - 9) / 4)
    readonly property int dateCap: Math.round(Theme.fsBody * 0.72)
    readonly property int heroDateGap: 14
    readonly property real dateY: timeLift + heroCap / 2 + heroDateGap + dateCap / 2
    readonly property real heroW: timeText.width * (heroPx / Theme.fsClock)
    readonly property int clockFullW: Math.ceil(Math.max(heroW, heroDate.implicitWidth)) + 2 * Theme.s4
    readonly property int centerW: clockFullW + mediaGap + colW
    // the stack's vertical plan, in ink heights, centered on the island's center line:
    // time, `heroDotsGap`, dots
    readonly property int heroCap: Math.round(heroPx * 0.72)
    readonly property int heroDotsGap: 17
    readonly property real stackH: heroCap + heroDateGap + dateCap
    // the vertical plan with the card: the time's center from the island's top, the card
    // centered in what is left under it
    readonly property int timeY: 36
    readonly property int timeBottom: timeY + 22
    readonly property int expandedContentW:
          2 * (Theme.s3 + Config.islandPadding)         // barRow left+right insets at full expand
        + centerW
    readonly property int expandedW: 2 * Math.ceil(Math.max(Config.islandMinWidth, expandedContentW) / 2)
    readonly property int cardGap: 5          // between the time and the card
    // 26 under the card = the air above the time's cap height (timeY minus half a cap), so
    // the time-plus-card block sits centered in the island
    readonly property int expandedH: Math.max(Config.islandExpandedHeight, 132)
    // WHEN THE OPEN ISLAND'S CONTENTS SHOW. Not on a timer: on how far open the island
    // actually is. `openP` is the island's live height between the pill (0) and the open
    // island (1). The date, the song and the hairline are invisible until it is
    // `openFadeFrom` of the way open and reach full strength as it finishes. Opening,
    // they come in late, into room that already exists (they used to start fading in the
    // moment the pointer touched the pill). Closing, the same rule runs backwards: they
    // are gone while the island is still mostly open, so nothing is left to be cut off
    // by its edge on the way down to the pill.
    readonly property real openFadeFrom: 0.6
    readonly property real openP: Math.max(0, Math.min(1, (notch.height - collapsedH) / Math.max(1, expandedH - collapsedH)))
    // ...and they are not shown in something TALLER than the open island either. A panel
    // shrinking back into the island (the control center, after its clock is pressed) is
    // "fully open" by height long before it is the island, and the song and the date came
    // up floating in the middle of it, over the panel's own fading content. `tallP` is how
    // much taller than the open island it still is; they wait until it is within
    // `openFadeTall` of the island's height (a few percent of slack, so the spring's own
    // overshoot on a plain open does not dim them).
    readonly property real openFadeTall: 0.25
    readonly property real tallP: Math.max(0, (notch.height - expandedH) / Math.max(1, expandedH) - 0.06)
    // (full strength from `openFadeFull`, not from 1: the island's spring settles a few
    // pixels short and back, and at exactly 1 the contents dimmed to 86% and came back
    // on every open)
    readonly property real openFadeFull: 0.92
    readonly property real openFade: Math.max(0, Math.min(1, (openP - openFadeFrom) / (openFadeFull - openFadeFrom)))
                                   * Math.max(0, Math.min(1, 1 - tallP / openFadeTall))
                                   * openK
    // ...and only when the island they are in IS the open island, or one on its way to
    // or from the pill. The rule above is all height, and a panel opening from the pill
    // or closing to it passes through the open island's height on the way: the song,
    // the date, the hairline and the dots showed at full strength in the middle of
    // every launcher, control center and switcher morph, most plainly on the close.
    // `openLive` remembers which island this is: set when the island opens for itself,
    // dropped the moment a panel (or an OSD, or a notification) takes it, and not set
    // again until the island next opens for itself. Dropping it fades on the row's own
    // pace (so an open island handing over to a panel goes as one); setting it is at
    // once, because the height rule is what brings the contents in.
    property bool openLive: false
    readonly property bool rowYielded: osdWanted || notifWanted || morphWanted
    function openLiveSync() { if (rowYielded) openLive = false; else if (expanded) openLive = true; }
    onRowYieldedChanged: openLiveSync()
    onExpandedChanged: openLiveSync()
    property real openK: openLive ? 1 : 0
    Behavior on openK { enabled: !bar.openLive; NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
    // the island has come down to its open size (a few pixels of slack for the spring)
    readonly property bool settledOpen: notch.height <= expandedH + 4
    // the time's center against the island's center line: lifted so the whole stack
    // (time, dots) sits centered as a group
    readonly property real timeLift: (heroCap - stackH) / 2
    readonly property int launcherW: Config.launcherWidth
    readonly property int calendarW: Config.calendarWidth       // the calendar's a compact morph
    readonly property int wallpaperW: Config.wallpaperPickerWidth // wallpaper picker wants room for big previews
    readonly property int themeW: themeContent.bookW            // the color book: as wide as the setting, up to its own limit
    readonly property int polkitW: 460                          // the auth prompt: one column, no room needed for a grid
    readonly property int ccW: Config.ccPanelW
    readonly property int morphW: polkitWanted ? polkitW : calendarWanted ? calendarW : wallpaperWanted ? wallpaperW : themeWanted ? themeW : ccWanted ? ccW : logoutWanted ? logoutContent.islandW : launcherW
    readonly property int notifW: Config.notificationWidth
    readonly property int osdW: Config.osdWidth

    // click-outside dismiss while the launcher's open (full-window, behind the island)
    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: bar.morphWanted || bar.pinned
        onClicked: {
            // the clicked-open island: a click anywhere away from it lets go of the pin
            if (!bar.morphWanted) { bar.pinned = false; return; }
            // polkit: click-outside CANCELS the auth request (fail closed), never a quiet close
            if (bar.polkitWanted) { if (Polkit.flow) Polkit.flow.cancelAuthenticationRequest(); return; }
            GlobalState.launcherOpen = false;
            GlobalState.controlCenterOpen = false;
            GlobalState.wallpaperPickerOpen = false;
            GlobalState.themeSwitcherOpen = false;
            GlobalState.logoutOpen = false;
            GlobalState.calendarOpen = false;
        }
    }

    Item {
        id: notch
        anchors.top: parent.top
        // continuous: closes to 0 as it goes flush (notch). No Behavior here —
        // flushT is already animating, so one would just chase a per-frame target and stall.
        anchors.topMargin: bar.topGap * (1 - bar.flushT)
        // centered on a WHOLE pixel. horizontalCenter put x on fractions while the width
        // springs, and the layered fill (a texture, sampled unsmoothed) snapped a pixel
        // sideways each time x crossed a half: the island shimmied left and right as it
        // settled. The width stays fractional; only the right edge's anti-aliasing moves.
        x: Math.round((parent.width - width) / 2)

        // liveW is what the spring drives; what is RENDERED is it rounded to an EVEN
        // integer, so the island's x is a whole pixel, its center exact, and the spring's
        // last sub-pixel ringing lands as settled instead of shimmying the edges by a
        // pixel either way
        readonly property real targetW: bar.morphWanted ? bar.morphW
             : (bar.notifWanted || bar.osdWanted) ? transientHost.contentW
             : bar.expanded ? bar.expandedW : bar.collapsedW
        property real liveW: targetW
        // within 2px of the target the spring's last ring is only ever a late 2px tick
        // after the eye has seen the island settle; render the target itself from there
        width: Math.abs(liveW - targetW) < 2 ? 2 * Math.round(targetW / 2) : 2 * Math.round(liveW / 2)
        // the island sizes to content
        readonly property real targetH: bar.morphWanted ? morphHost.contentHeight
              : (bar.notifWanted || bar.osdWanted) ? transientHost.contentH
              : bar.expanded ? bar.expandedH : bar.collapsedH
        property real liveH: targetH
        // The spring closes a little past the target and comes back, and how far past
        // grows with how far it had to travel. From most panels that is a few pixels and
        // reads as a soft landing. From the control center, the tallest thing the island
        // becomes, it was twice that: the bottom edge came up to within 2px of the time
        // before it let go. So the part of a close that goes PAST the target is scaled
        // down for a long trip, to what a trip of `underRef` gives. Nothing else changes:
        // shorter trips, and the way down to the target, are the spring as it is.
        readonly property real underRef: 300
        property real underK: 1
        onTargetHChanged: { const trip = height - targetH; underK = trip > underRef ? underRef / trip : 1; }
        height: liveH >= targetH ? liveH : targetH - (targetH - liveH) * underK
        // Corner radius, DERIVED from the live (already-animated) height instead of stepped on
        // state. Stepping it snapped the corners to the collapsed radius the INSTANT you hovered
        // off (or closed a panel) while the island was still at full height, so they flashed
        // sharp for a beat until the shrink caught up. As a pure function of the current height
        // they're always right for the size the island actually is, at every frame of the
        // animation. Interpolates rIsland→rIslandOpen across the collapse↔expand range and caps
        // there, so tall morph/notification surfaces still round fully. Clamped to half the box
        // so the arcs always fit. Both the island Rectangle and the notch Shape read this, so
        // neither shape can drift from the other.
        // Ramps from the collapsed pill's radius to the open card's, then holds. The ramp has
        // to be height-derived (not a flat per-state value) or the corners desync from the size
        // mid-morph and visibly pop. But it saturates as soon as the surface is TALL ENOUGH to
        // draw the open radius — 2*rIslandOpen — not at the expanded island's height. Ramping
        // all the way to expandedH meant every surface shorter than that got short-changed:
        // the power menu sat at 30.4 and the OSD at 21.4 while the launcher/CC/pickers were 31.
        // Now everything from ~62px up is exactly rIslandOpen, and the only surfaces below it
        // are ones physically too short to fit that corner (height/2 caps them).
        readonly property real radSat: 2 * Theme.rIslandOpen
        readonly property real rad: Math.min(width / 2, height / 2,
                    Theme.rIsland + (Theme.rIslandOpen - Theme.rIsland)
                      * Math.max(0, Math.min(1, (height - bar.collapsedH)
                                                / Math.max(1, radSat - bar.collapsedH))))

        Behavior on liveW  { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
        // Width and height animate on the SAME always-on Behavior so a morph is uniform (both
        // axes together, never one then the other). The island height is the ONE spring for
        // content changes too: content resizes instantly, contentHeight steps, this springs
        // to it, and the root's clip reveals the content as the island grows (patterns.md #48).
        // The one exception: while a list inside the control center folds on ITS spring
        // (`controlCenter.folding`) this stands aside and tracks the content frame by frame,
        // so that fold is still the only spring and the island moves in lockstep with it.
        Behavior on liveH { enabled: !controlCenter.folding; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

        visible: !bar.lockCovered

        // drop-in entrance
        opacity: 0
        transform: Translate { id: dropT; y: -22 }
        Component.onCompleted: { dropAnim.start(); LockState.setRest(bar.modelData?.name ?? "", bar.lockRest); }
        ParallelAnimation {
            id: dropAnim
            NumberAnimation { target: notch; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEnter); easing.type: Easing.OutCubic }
            NumberAnimation { target: dropT; property: "y"; from: -22; to: 0; duration: Theme.dur(Theme.dEnter); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
        }

        // THE fill — one shape for every form. Island (rounded top + gap above) and notch
        // (flush, square-ish top flaring out at the corners) both come out of the same
        // outline, interpolated by bar.notchT. There's no second
        // surface to swap to, so switching modes can't pop: the corners un-round, the flares
        // grow, and the top margin closes on one clock.
        //
        // In notch mode it overshoots the top edge a few px (`over`) so it sits TRULY flush,
        // with no sliver of desktop above it — that overshoot scales to 0 as it becomes the
        // floating island, which needs its gap back.
        Shape {
            id: notchFill
            readonly property real over: 4 * bar.notchK
            anchors.top: parent.top
            anchors.topMargin: -over
            x: Math.round((parent.width - width) / 2)    // whole pixel, as the notch (see there)
            width: notch.width + 2 * bar.notchFlareEff
            height: notch.height + over
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: Theme.shadows
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: Theme.shadowBlur
                shadowVerticalOffset: Theme.shadowY
                blurMax: Theme.shadowBlurMax
                autoPaddingEnabled: true
            }
            ShapePath {
                fillColor: Theme.base   // follows scheme polarity, same as the island body
                // hairline on the floating island only: flush against the screen edge it'd
                // read as a 1px strip holding the bar off the top. Fades out as it goes flush.
                strokeColor: Theme.hairline
                strokeWidth: (1 - bar.notchK)
                PathSvg {
                    path: bar.notchPath(notch.width, notch.height + notchFill.over,
                                        bar.notchTopR, bar.notchBR, bar.notchFlareEff)
                }
            }
        }

        // pin toggle: a press on any NON-interactive part of the island toggles pin.
        // Sits BELOW the content (declared before barRow), so the real buttons (cc pill,
        // media controls) grab their own clicks and only empty areas reach this. Replaces
        // a notch-wide TapHandler that fired even on the buttons.
        MouseArea {
            id: pinArea
            anchors.fill: parent
            enabled: !bar.morphWanted && !bar.notifWanted && !bar.osdWanted
            onClicked: bar.pinned = !bar.pinned
        }

        // bar content (media | clock): fades out as the island morphs
        RowLayout {
            id: barRow
            anchors.fill: parent
            // extra breathing room inside the EXPANDED island (7px on every side, on top of
            // the base s3 side inset). Animates via `pad` so the content eases inward as the
            // island opens instead of the margins jumping.
            property real pad: bar.expanded ? Config.islandPadding : 0
            Behavior on pad { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
            anchors.leftMargin: Theme.s3 + pad
            anchors.rightMargin: Theme.s3 + pad
            anchors.topMargin: pad
            anchors.bottomMargin: pad
            spacing: 0
            // clipped to the island: the content fades on dEffects while the island
            // shrinks on the longer spring, and the now-playing strip sits low enough that
            // it showed under the pill for a few frames of every collapse
            clip: true
            // hidden when an OSD/notification takes the bar, or when a panel morphs the
            // island in place
            readonly property bool yielded: bar.osdWanted || bar.notifWanted || bar.morphWanted
            opacity: yielded ? 0 : 1
            enabled: !yielded
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

            // CENTER: clock. Fills the middle.
            Item {
                id: clock
                // the media block's room to the left of the clock: 0 = none (pill, or the
                // card switched off), 1 = the clock has moved right by half the block so
                // the two sit centered as one group
                property real mediaT: bar.expanded ? 1 : 0
                Behavior on mediaT { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                Layout.fillWidth: true
                Layout.fillHeight: true

                // subtle "button" affordance behind the time/date: a faint fill shows on
                // hover so the clock reads as pressable; pressing it morphs the island into
                // the calendar. Only active in the clock's full form (expanded island or game
                // bar); collapsed, clicks fall through to the pin toggle.
                Rectangle {
                    id: clockBtn
                    readonly property real sf: bar.expanded ? (bar.heroPx / Theme.fsClock) : 1
                    // The clock sits in the MIDDLE of what the side columns leave, which is the
                    // island's center when both are on. Pure binding, NO Behavior on x: the
                    // zones' widths already animate, so the slide is smooth, and a Behavior
                    // would chase a target that moves every frame and visibly stall.
                    //
                    // Written against barRow (NOT the clock item) on purpose. The RowLayout hands
                    // `clock` INTEGER x/width, so while the spring settles its bounce arrives as 1px
                    // steps — that was the clock snapping sideways at the end of a collapse. The
                    // middle of the free span is (barRow.width + left - right) / 2 in barRow
                    // coordinates, all continuous values, and clock.x only converts it back.
                    // mediaT 0: centered. mediaT 1: against the right edge, the ink at
                    // the media block's inset.
                    x: (barRow.width - width) / 2 * (1 - clock.mediaT)
                       - clock.mediaT * (Theme.s4 - bar.wsBigPad) - clock.x
                    anchors.verticalCenter: parent.verticalCenter
                    // open: the box around the time (NOT the dots: the press area fills
                    // this box and would take their clicks)
                    readonly property real topY: bar.timeLift - bar.heroCap / 2 - Theme.s2 - 2
                    readonly property real botY: bar.dateY + bar.dateCap / 2 + Theme.s2 + 2
                    anchors.verticalCenterOffset: bar.expanded ? (topY + botY) / 2 : 0
                    // sized from the TIME alone, never from timeRow.width: on an expand the
                    // capsule and glyph wrappers are still folding away inside that row for
                    // the length of the spring, and a width that followed it retargeted every
                    // frame, so the hover box sat wide for a beat and shrank late (the stall
                    // in patterns.md #64). One target: the big time plus a rectangle's worth
                    // of padding, more at the sides than above and below.
                    width: (bar.expanded ? Math.max(bar.heroW, heroDate.implicitWidth) : timeText.width) + 2 * Theme.s4
                    height: bar.expanded ? Math.round(botY - topY) : Math.round(clockFm.height) + 2 * Theme.s2
                    radius: Theme.rMd
                    visible: bar.expanded
                    color: clockMa.containsMouse ? Theme.fillLow : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                    Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                }

                Row {
                    id: timeRow
                    // centered on the clock button; lifted to the top while the media card sits
                    // under it, on the island's center line otherwise. The lift animates as a
                    // number (not the font) so it stays smooth.
                    property real shift: bar.expanded ? bar.timeLift : 0
                    Behavior on shift { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    // the capsule wrapper's left glow margin is dead space; pull the row back
                    // by exactly half of it so the content BOX sits centered (measured 25.6 /
                    // 21.6 before). What remains is glyph side-bearing: the time's last digit
                    // changes every minute (a 0 reaches further right than a 1), so the ink
                    // margin wobbles by up to a pixel on its own. Centering on the box keeps the
                    // pill still; centering on the ink would nudge it every minute.
                    // (open: the time's left ink on the box's inset, not centered in it,
                    // so it lines up with the date under it)
                    readonly property real raw: clockBtn.x + (clockBtn.width - width) / 2
                       - clock.mediaT * (clockBtn.width - 2 * Theme.s4 - bar.heroW) / 2
                    // snapped to a whole pixel of the SCREEN, not of the row. While the island
                    // resizes its left edge passes through fractions and the layout's integer
                    // x steps under it, so the time, placed by fractions of both, re-snapped a
                    // pixel sideways from frame to frame; rounding its screen position holds
                    // it still while the edges move
                    readonly property real screenL: notch.x + barRow.anchors.leftMargin + clock.x
                    // ... and off the SCREEN'S center, which never moves, not off notch.x:
                    // the island is always centered, and its x is rounded to the pixel, so
                    // placing the time from its left edge would let that rounding flip the
                    // time's own snap while the width passes through fractions. From the
                    // center the width cancels and the time's pixel is a constant.
                    readonly property real screenC: notch.parent.width / 2 - notch.width / 2 + barRow.anchors.leftMargin + clock.x
                    // and it is the TIME that lands on the pixel, not the row: the time sits
                    // at the row's left plus the capsule wrapper's width, which is mid-spring
                    // while the companions arrive, so snapping the row left the digits
                    // drifting through fractions and re-snapping a pixel either way. (The
                    // 0.001 keeps a value that happens to sit on a half from flipping on
                    // float noise.)
                    x: Math.round(screenC + raw + timeText.x + 0.001) - timeText.x - screenL
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: shift
                    // NO row spacing: the gap from the time to each companion lives inside
                    // that companion's wrapper, so it folds away with the room on the same
                    // spring. A Row drops a spacing the instant an item's width reaches 0
                    // (and the spring crosses 0 more than once), which snapped the time by a
                    // whole gap at the end of every collapse, after it had already settled.
                    spacing: 0

                    // workspace dots, left of everything, collapsed only (the dial takes the
                    // expanded island). Reveal: width to 0 on the spring,
                    // fade, a little scale, clipped.
                    // room for the workspace capsules at rest, collapsed only. The capsules
                    // themselves are `ws` below (one set, two homes); this only holds their
                    // place in the row and gives it back on the spring as the island opens.
                    Item {
                        id: wsWrap
                        readonly property bool act: bar.dotsOn && !bar.expanded
                        // an outer margin for the active capsule's scale and glow
                        readonly property int pad: 6
                        width: act ? bar.restRoomL + Theme.s5 : 0    // the gap to the time rides inside
                        height: 1
                        Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    }

                    // Time. Sits DIRECTLY in the Row (not in a scale-tracking wrapper) on purpose:
                    // an item's width ignores its `scale` transform, so timeRow.width stays CONSTANT
                    // while the time scales up. clockBtn.width keys off it (times the step `sf`), so
                    // the button has one fixed target its Behavior can animate to cleanly. Wrapping
                    // this to report the animating scaled width made timeRow.width change every
                    // frame, so clockBtn's width Behavior chased a moving target and the whole clock
                    // stalled/stuttered on hover — same trap as a Behavior on x. Don't reintroduce it.
                    // The time, drawn per digit so the digits can ROLL — iPhone-lock-screen
                    // style: when a digit changes, the old glyph slides up and fades out while
                    // the new one rises into its place fading in, masked to the line box. Only
                    // the digits that actually change move (onChChanged fires per cell); the
                    // rest hold perfectly still.
                    //
                    // Cells take each character's PROPORTIONAL advance (no tabular figures —
                    // tnum gave "1" a full digit slot and the time read gap-toothed). Widths
                    // change only AT the tick, a discrete step identical to what the single
                    // Text used to do, and clockBtn's width Behavior smooths it; during the
                    // roll itself nothing resizes, so there's still no per-frame churn.
                    Row {
                        id: timeText
                        // hidden the moment its flying copy takes off for the control center
                        opacity: bar.clockFlying ? 0 : 1
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        transformOrigin: Item.Center
                        scale: bar.expanded ? (bar.heroPx / Theme.fsClock) : 1.0
                        // optical center: the digits' cap height sits below the text box's
                        // middle (measured 1.6px low against the notch's center line, which
                        // the flat top edge makes easy to see), so the glyphs ride up a touch.
                        // NOTCH ONLY: in the floating island the same lift measured 1.6px HIGH
                        // (every element, uniformly), so it fades out with notchT
                        transform: Translate { y: -1.5 * bar.notchT }
                        Behavior on scale { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                        readonly property string timeStr: Qt.formatDateTime(sysclock.date, (Config.clock24h ? "HH:mm" : "h:mm") + (Config.clockSeconds ? ":ss" : "") + (Config.clock24h ? "" : " AP"))
                        SystemClock { id: sysclock; precision: Config.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }

                        FontMetrics {
                            id: clockFm
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fsClock
                            font.weight: Theme.wSemiBold
                        }

                        Repeater {
                            model: timeText.timeStr.length
                            delegate: Item {
                                id: cell
                                required property int index
                                readonly property string ch: timeText.timeStr.charAt(cell.index)

                                width: chM.advanceWidth
                                height: clockFm.height
                                clip: true                        // the mask that sells the roll

                                TextMetrics {
                                    id: chM
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Theme.fsClock
                                    font.weight: Theme.wSemiBold
                                    text: cell.ch
                                }

                                // what's on screen; lags ch by one roll
                                property string shown: ""
                                property bool ready: false
                                Component.onCompleted: { shown = ch; ready = true; }
                                onChChanged: {
                                    if (!cell.ready || cell.shown === cell.ch) return;
                                    outT.text = cell.shown;
                                    cell.shown = cell.ch;
                                    roll.restart();
                                }

                                component ClockGlyph: Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Theme.fsClock
                                    font.weight: Theme.wSemiBold
                                    color: Theme.inkPrimary
                                    renderType: Text.QtRendering
                                }

                                ClockGlyph { id: curT; text: cell.shown; y: 0 }
                                ClockGlyph { id: outT; opacity: 0 }

                                ParallelAnimation {
                                    id: roll
                                    // incoming: rises from below into place
                                    NumberAnimation { target: curT; property: "y"; from: cell.height * 0.6; to: 0; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                                    NumberAnimation { target: curT; property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                                    // outgoing: keeps traveling up and out
                                    NumberAnimation { target: outT; property: "y"; from: 0; to: -cell.height * 0.6; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier }
                                    NumberAnimation { target: outT; property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                                }
                            }
                        }
                    }

                    // battery + Wi-Fi's room, right of the time, collapsed only: the mirror of
                    // the capsules' spacer. The glyphs themselves are `st` in the clock item,
                    // one set with two homes.
                    Item {
                        id: stWrap
                        readonly property bool act: bar.statusOn && !bar.expanded
                        width: act ? bar.restRoomR + Theme.s5 : 0    // the gap to the time rides inside
                        height: 1
                        Behavior on width { NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    }
                }

                // The media block, against the island's left edge, on its center line.
                IslandMedia {
                    id: mediaCard
                    x: clock.width - bar.wsBigPad - width      // the right column's top row
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -bar.rowOff + bar.colDrop
                    mirrored: true
                    cardW: bar.cardW
                    cardH: bar.cardH
                    live: bar.expanded && bar.showNow
                    opacity: bar.showNow ? bar.openFade : 0
                    visible: Config.islandMedia && opacity > 0.01
                }

                // THE workspace capsules, one set with two homes (IslandDots): at rest in
                // the pill's row, where the wsWrap spacer holds their room, open in a row
                // under the time and date, centered on the clock button. Both homes are
                // handed over in THIS item's coordinates. With the pill's capsules on they
                // glide from beside the time to under it and back; with them off (no rest
                // home to come from) they pop in from just below their place, one after
                // another.
                IslandDots {
                    id: ws
                    screen: bar.modelData
                    anchors.fill: parent
                    // With no dots in the pill there is nowhere for them to travel from, and
                    // their own entrance (each one popping up in turn, on its own spring)
                    // ran on a different clock from the rest of the open island: on a close
                    // they were still plainly there when the song and the date had gone.
                    // So in that case they simply live at their open place and fade with
                    // the island's contents (bar.openFade), exactly as the song does. With
                    // dots in the pill they still glide between the two homes.
                    open: bar.expanded || !bar.dotsOn
                    opacity: bar.dotsOn ? 1 : bar.openFade
                    visible: opacity > 0.01
                    restOn: bar.dotsOn
                    openOn: bar.showWs
                    // the rest row ends one row-gap left of the TIME's visible left edge (its
                    // live scale included), not at the wsWrap spacer: the spacer folds to 0
                    // as the island opens and the row recenters, which slid the capsules
                    // still waiting their turn under the growing digits. With the pill at
                    // rest this is exactly wsWrap.x + pad.
                    restX: timeRow.x + timeText.x + timeText.width / 2 - timeText.width * timeText.scale / 2 - Theme.s5 - ws.restW
                    restY: timeRow.y + timeRow.height / 2 - 1.5 * bar.notchT   // the digits' optical lift, shared
                    // the right column's bottom row: the dots, then the status glyphs
                    openX: clock.width - bar.wsBigPad - ws.openW
                    openY: clock.height / 2 + bar.rowOff + bar.colDrop
                    restCapW: 7; restCapH: 7; restGap: 5
                    openCapW: 9; openCapH: 9; openGap: 7
                }

                // THE status glyphs: the pill's companions right of the time, where the
                // stWrap spacer holds their room. They have no home in the open island any
                // more (the right column is gone): they fade out in place as it opens.
                IslandStatus {
                    id: st
                    anchors.fill: parent
                    open: bar.expanded
                    restOn: bar.statusOn
                    openOn: false      // no battery or signal in the open island
                    // the rest row starts one row-gap right of the TIME's visible right edge
                    // (its live scale included), the capsules' rule mirrored; with the pill
                    // at rest this is exactly stWrap.x + pad
                    restX: timeRow.x + timeText.x + timeText.width / 2 + timeText.width * timeText.scale / 2 + Theme.s5
                    restY: timeRow.y + timeRow.height / 2 - 1.5 * bar.notchT   // the digits' optical lift, shared
                    openX: restX
                    openY: restY
                }

                // The full date, under the hero time, its left edge on the time's. Open
                // island only; it fades up with the island.
                StyledText {
                    id: heroDate
                    x: clockBtn.x + Theme.s4 + 2
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: bar.dateY
                    text: Qt.formatDateTime(sysclock.date, "dddd, MMMM d")
                    font.pixelSize: Theme.fsBody
                    color: Theme.inkDim
                    opacity: bar.openFade
                    visible: opacity > 0.01
                }
                // the hairline between the right column's two rows
                Rectangle {
                    x: clock.width - bar.wsBigPad - width
                    anchors.verticalCenter: parent.verticalCenter
                    // midway between the art's bottom edge and the dots' top
                    anchors.verticalCenterOffset: bar.colDrop + (bar.cardH - ws.openCapH) / 4
                    width: bar.colW; height: 1
                    color: Theme.hairline
                    opacity: bar.openFade
                    visible: opacity > 0.01
                }

                // press target: opens the calendar. Sits on top of the text so it grabs the
                // click instead of the pin-toggle behind the island.
                MouseArea {
                    id: clockMa
                    anchors.fill: clockBtn
                    enabled: bar.expanded
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // the big time opens the control center, and travels there: see flyClock
                    onClicked: GlobalState.controlCenterOpen = true
                }
            }
        }

        // the clicked-open island stays open until it is clicked again or a click lands
        // anywhere else (the backdrop); leaving it with the pointer does nothing. On the
        // notch itself, an ancestor of everything inside, so the inner mouse areas keep
        // their hover (a HoverHandler on a topmost child took the hover first and the
        // clock's MouseArea underneath never saw its leave).
        HoverHandler {
            id: hover
            // (not under the lock: the pointer may still be resting where the island is,
            // and it would keep the island open under the lock screen)
            enabled: !bar.morphWanted && !bar.notifWanted && !bar.osdWanted && !bar.closeGuard && !LockState.locked
            // Hover takes the island over from the return hold, but only once the panel
            // has finished shrinking into the open island. A control center on its way
            // back is much taller than the island: a pointer resting below the island's
            // place was "over the island" while the panel was still tall, which let go
            // of the hold, and then the panel's edge shrank past it, which read as the
            // pointer leaving. The island opened and collapsed in one go. While the
            // panel is still coming down the hold stays; it lets go by itself after its
            // moment (returnHoldTimer).
            onHoveredChanged: if (hovered && bar.settledOpen) bar.returnHold = false
        }
    }

    // transient host: OSD + notification + mode indicator. Coincides with the notch (rides
    // notch.fill), so the island morphs to the content. Single instances; the notch
    // references these ids for sizing.
    Item {
        id: transientHost
        readonly property bool shown: bar.notifWanted || bar.osdWanted
        readonly property int contentH: bar.notifWanted ? (notifIsland.implicitHeight + Theme.s3 * 2)
              : bar.osdWanted ? (osdIsland.implicitHeight + Theme.s3 * 2)
              : bar.collapsedH
        readonly property int contentW: bar.notifWanted ? bar.notifW
              : bar.osdWanted ? (OsdState.kind === "mode" ? (osdIsland.modeWidth + Theme.s5 * 2) : bar.osdW)
              : bar.collapsedW
        anchors.top: parent.top
        anchors.topMargin: bar.topGap * (1 - bar.flushT)   // rides the same clock as the notch
        anchors.horizontalCenter: parent.horizontalCenter
        // clip the (fixed-width, centered) content to the notch while it grows from
        // collapsed → full, or the icon/%/label hang outside the pill onto the wallpaper
        // for a frame before the background catches up. The content gets revealed as the
        // pill expands instead.
        clip: true
        // ride the notch exactly (the island is the animated surface; this just follows it)
        width: notch.width
        height: notch.height

        NotificationIsland {
            id: notifIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: bar.notifW - Theme.s3 * 2
            notif: Notifications.showing
            opacity: bar.notifWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        OsdIsland {
            id: osdIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: OsdState.kind === "mode" ? osdIsland.modeWidth : (bar.osdW - Theme.s3 * 2)
            opacity: bar.osdWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
    }

    // morph panels host (launcher / control center / pickers / settings / power /
    // polkit). It coincides with the notch exactly (same center, width, height, top
    // margin), so a panel reads as the island morphing IN PLACE: the notch.fill is its
    // background. Single instances live here.
    // ── THE CLOCK'S FLIGHT BETWEEN THE ISLAND AND THE CONTROL CENTER ──
    // Pressing the big time in the open island opens the control center, and the time goes
    // with it: one copy leaves the island's clock at that size, shrinks, and lands on the
    // control center's top-left clock. Pressing that clock is the same trip backwards,
    // into the open island. While the copy is in the air the island's own time and the
    // control center's are both hidden, so there is one time on screen, moving.
    //
    // `flyT` is where it is: 0 = on the island's time, 1 = on the control center's. Every
    // frame it is placed BETWEEN THE TWO REAL CLOCKS AS THEY ARE RIGHT NOW (flyUpdate),
    // not between two points written down at the press. Both of them ride the island's
    // edge as it resizes, so the copy does too. (Aimed from a fixed starting point it
    // lagged behind the shrinking island and hung outside its edge for a moment.)
    // No bounce: scaled text on a ringing spring shudders at the end (patterns.md #55).
    property bool clockFlying: false
    property real flyT: 0
    property point flySpot: Qt.point(0, 0)      // the target clock's box inside the panel
    function flyUpdate() {
        const h = timeText.mapToItem(flyClock.parent, 0, 0);
        const cx = morphHost.x + Theme.s4 + flySpot.x, cy = morphHost.y + Theme.s4 + flySpot.y;
        const s1 = controlCenter.clockPx / Theme.fsClock;
        // Sideways it follows the island's live time (which rides the island's left
        // edge). Up and down it cannot simply do the same: that time sits on the
        // island's center line, and on the way in the island is as tall as the control
        // center, so following it made the copy dip halfway down the panel and climb
        // back. So the height is worked out from the island's own plan, for the form the
        // island is HEADING to: `k` is how far the time has grown from its pill size to
        // its hero size (it animates on the spring), and the island's settled height and
        // the time's lift are read off the same `k`. Open island: the hero's place.
        // Collapsing (the pointer left right after the press): the pill's middle, and the
        // copy comes home to the pill with the real time. (With the hero's place fixed,
        // it flew to where the big clock would have been and hung there, under the
        // closing island, until the flight was over.)
        const s0 = bar.heroPx / Theme.fsClock;
        const k = Math.max(0, Math.min(1, (timeText.scale - 1) / Math.max(0.001, s0 - 1)));
        // (only ever SHORTER than the plan: when the island closes past its resting
        // height and springs back, its own time rides that on the center line, and so
        // does the copy. Standing still, it let the bottom edge come up at it.)
        const plan = bar.collapsedH + (bar.expandedH - bar.collapsedH) * k;
        const hgt = Math.min(plan, notch.height);
        const hy = morphHost.y + hgt / 2 + bar.timeLift * k - timeText.height * timeText.scale / 2;
        flyClock.x = h.x + (cx - h.x) * flyT;
        flyClock.y = hy + (cy - hy) * flyT;
        flyClock.scale = timeText.scale + (s1 - timeText.scale) * flyT;
    }
    function flyStart(from) {
        const r = controlCenter.clockSpot();
        flySpot = Qt.point(r.x, r.y);
        flyIn.stop(); flyBack.stop();
        flyT = from;
        flyUpdate();
        clockFlying = true;
    }
    function flyClockToCc() { flyStart(0); flyIn.start(); }
    function flyClockBack() { flyStart(1); flyBack.start(); }
    // The trip is taken on EVERY way between the island and the control center, not only
    // on a press of either clock: the shortcut, the pill, Escape, a click outside. The
    // rule: when the time is on screen before and after, it travels, it does not fade
    // out in one place and in at another. (From the pill it used to ride the island's
    // center line down into the opening panel and fade there, like under any panel.)
    // Only when the island's row is what the control center opens from or closes to:
    // not from another panel, not under a level pill or a notification, not at a lock.
    onCcWantedChanged: {
        if (LockState.locked || LockState.unlocking) return;
        if (ccWanted) { if (barRow.opacity > 0.5) flyClockToCc(); }
        else {
            // spelled out from the raw switches, not read off morphWanted / osdWanted /
            // notifWanted or the other panels' *Wanted: all of those are bindings that
            // have not caught up yet when this runs. (Another panel opening is what
            // closes the control center, and read off launcherWanted and friends the
            // answer was still "no panel", so the time flew home to the middle of the
            // island and sat on top of the panel that had just taken it.)
            const g = GlobalState;
            const panel = Polkit.active || g.launcherOpen || g.wallpaperPickerOpen || g.themeSwitcherOpen || g.logoutOpen || g.calendarOpen;
            const osd = OsdState.active && OsdState.screen === (modelData?.name ?? "");
            const notif = onFocusedMon && Notifications.showing !== null;
            if (!panel && !osd && !notif) flyClockBack();
        }
    }
    // the way in is quicker than the way home: it is a small thing arriving, and at the
    // island's own spring length it was still drifting after the panel had opened
    readonly property int flyInMs: Math.round(Theme.dSpring * 0.6)
    NumberAnimation {
        id: flyIn
        target: bar; property: "flyT"; to: 1
        duration: Theme.dur(bar.flyInMs); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier
        onFinished: bar.clockFlying = false
    }
    NumberAnimation {
        id: flyBack
        target: bar; property: "flyT"; to: 0
        duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier
        onFinished: bar.clockFlying = false
    }
    // both clocks move on their own springs while the island resizes, so the copy is
    // re-placed on every frame, not only when flyT changes
    FrameAnimation { running: bar.clockFlying; onTriggered: bar.flyUpdate() }
    Text {
        id: flyClock
        z: 60
        visible: bar.clockFlying
        text: timeText.timeStr
        font.family: Theme.fontDisplay
        font.weight: Theme.wSemiBold
        font.pixelSize: Theme.fsClock
        color: Theme.inkPrimary
        renderType: Text.QtRendering
        // The island draws its time one character at a time (so digits can roll), and a
        // colon drawn alone sits on the baseline. A whole "18:19" in one text gets the
        // font's contextual colon, raised to the digits' middle: the copy landed with its
        // colon a few pixels higher than the island's, and the colon dropped at the
        // hand-over. With contextual alternates off the two are drawn the same.
        font.features: { "calt": 0 }
        transformOrigin: Item.TopLeft
    }

    Item {
        id: morphHost
        anchors.top: parent.top
        // notch: flush. island: its gap. One continuous expression off flushT, so it never steps.
        anchors.topMargin: bar.topGap * (1 - bar.flushT)
        anchors.horizontalCenter: parent.horizontalCenter

        // the height the open panel wants: single source of truth (the notch reads this
        // too when it morphs the panel in place).
        readonly property int contentHeight: bar.polkitWanted ? (polkitContent.implicitHeight + Theme.s4 * 2)
              : bar.launcherWanted ? (launcher.implicitHeight + Theme.s4 * 2)
              : bar.ccWanted ? (controlCenter.implicitHeight + Theme.s4 * 2)
              : bar.wallpaperWanted ? (wallpaperContent.implicitHeight + Theme.s4 * 2)
              : bar.themeWanted ? (themeContent.implicitHeight + Theme.s4 * 2)
              : bar.logoutWanted ? logoutContent.islandH
              : bar.calendarWanted ? (calendarContent.implicitHeight + Theme.s4 * 2)
              : 0

        // ride the notch exactly (seamless in-place morph, the notch is the animated
        // surface and this just follows it)
        width: notch.width
        height: notch.height
        // ...and nothing of a panel shows outside it. The power menu lays its row out at
        // full size from the first frame, centered, so while the island was still a pill
        // on its way out the buttons and their label hung in the air around it, on the
        // desktop, with no island behind them. The island's edge reveals a panel.
        clip: true

        // swallow clicks inside the panel (so they don't reach the click-outside backdrop)
        MouseArea {
            anchors.fill: parent
            enabled: bar.morphWanted
        }
        // The control center's outer edge, the ring of padding between the island's edge
        // and its controls on all four sides, goes back to the expanded island on a click
        // (the calendar's header does the same). It lives here and not in the panel because
        // that ring is the panel's inset, outside the panel's own clip. A click further in
        // (the gaps between the controls) is left alone. Not while a sheet is open: that
        // click belongs to the sheet's scrim.
        MouseArea {
            anchors.fill: parent
            enabled: bar.ccWanted && controlCenter.view === "main"
            onClicked: mouse => {
                const m = Theme.s4;
                const inside = mouse.x >= m && mouse.x <= width - m && mouse.y >= m && mouse.y <= height - m;
                if (!inside) GlobalState.controlCenterBack();
            }
        }

        LauncherContent {
            id: launcher
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.launcherWanted
            opacity: bar.launcherWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        ControlCenterContent {
            id: controlCenter
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.ccWanted
            clockFlying: bar.clockFlying
            // its clock is the way back to the open island, the time flying home
            onClockPressed: GlobalState.controlCenterBack()
            opacity: bar.ccWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        WallpaperContent {
            id: wallpaperContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.wallpaperWanted
            opacity: bar.wallpaperWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        ThemeContent {
            id: themeContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.themeWanted
            opacity: bar.themeWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        LogoutContent {
            id: logoutContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.logoutWanted
            screenName: bar.modelData?.name ?? ""
            pillH: bar.collapsedH
            opacity: bar.logoutWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        PolkitContent {
            id: polkitContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.polkitWanted
            opacity: bar.polkitWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
        CalendarContent {
            id: calendarContent
            anchors.fill: parent
            anchors.margins: Theme.s4
            active: bar.calendarWanted
            opacity: bar.calendarWanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        }
    }

}

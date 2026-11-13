import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The Sound sheet: macOS's Sound panel crossed with Android's output switcher, plus the
// mixer both of them hide. OUTPUT: every sink as a selectable row (glyph by what it is, a
// check on the current one) with the master volume under it. INPUT: the same for sources
// with the mic level. APPS: one row per application that is playing right now, each with
// its own volume and mute, straight from PipeWire. Lists are ScriptModels bound directly
// to Pipewire.nodes (patterns.md #46); the tracker below binds the audio interface of every
// node while the sheet is showing, so the per-app sliders are live.
Column {
    id: soundSheet
    move: CcSheetBits.MoveSpring {}

    property var panel: null
    spacing: Theme.s3

    // bind audio props for everything we list, only while visible (it costs a little)
    PwObjectTracker { objects: soundSheet.visible ? Pipewire.nodes.values.filter(n => n.audio) : [] }

    // Only devices that are actually there (Audio drops unplugged jacks / dark HDMI ports)
    // and that the user hasn't hidden; "show hidden" brings the hidden ones back, dimmed,
    // so a right-click can unhide them.
    property bool showHiddenOut: false
    property bool showHiddenIn: false
    readonly property int hiddenOut: Audio.presentSinks.length - Audio.shownSinks.length
    readonly property int hiddenIn: Audio.presentSources.length - Audio.shownSources.length
    onVisibleChanged: if (!visible) { showHiddenOut = false; showHiddenIn = false; }
    ScriptModel { id: sinkModel;   values: soundSheet.showHiddenOut ? Audio.presentSinks : Audio.shownSinks }
    ScriptModel { id: sourceModel; values: soundSheet.showHiddenIn ? Audio.presentSources : Audio.shownSources }
    ScriptModel { id: appModel;    values: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.isSink) }

    function glyphFor(n) {
        const s = ((n.name || "") + " " + (n.description || "")).toLowerCase();
        if (!n.isSink) return "mic";                                 // any source is a mic
        if (s.indexOf("bluez") >= 0 || s.indexOf("headphone") >= 0 || s.indexOf("headset") >= 0) return "headphones";
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0) return "display";
        return "volume";                                             // a sink is a speaker, whatever its name says
    }
    function appName(n) { const p = n.properties || {}; return p["application.name"] || n.nickname || n.name || "App"; }
    function mediaName(n) { const p = n.properties || {}; return p["media.name"] || ""; }

    // one selectable device row
    component DeviceRow: Rectangle {
        id: r
        property var node: null
        property bool selected: false
        signal pick()
        width: parent ? parent.width : 0
        height: 44
        radius: Theme.rMd
        color: rMa.containsMouse ? Theme.fillHigh : Theme.fillLow
        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
        opacity: entered
        // delegate-owned entrance (patterns.md #5): a positioner `add` transition is canceled
        // by the next relayout and strands the row at opacity 0
        property real entered: 0
        Component.onCompleted: entered = 1
        Behavior on entered { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
        readonly property bool hiddenRow: Audio.isHidden(node)
        // right-click hides a device from the sheet (or unhides a dimmed one); left picks it
        MouseArea {
            id: rMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (m) => {
                if (m.button === Qt.RightButton) { if (r.hiddenRow) Audio.unhide(r.node); else Audio.hide(r.node); }
                else r.pick();
            }
        }
        CcSheetBits.Disc { tint: Theme.hue("sliders");
            id: rDisc
            anchors.left: parent.left; anchors.leftMargin: Theme.s2
            anchors.verticalCenter: parent.verticalCenter
            size: 32
            live: r.selected
            icon: soundSheet.glyphFor(r.node)
        }
        StyledText {
            anchors.left: rDisc.right; anchors.leftMargin: Theme.s3
            anchors.right: tick.left; anchors.rightMargin: Theme.s2
            capCenterIn: parent
            elide: Text.ElideRight
            variant: "label"; font.weight: r.selected ? Theme.wMedium : Theme.wRegular
            text: Audio.nodeLabel(r.node)
            color: r.hiddenRow ? Theme.inkDim : Theme.inkPrimary
        }
        Icon { id: tick; anchors.right: parent.right; anchors.rightMargin: Theme.s3; anchors.verticalCenter: parent.verticalCenter; name: "check"; size: Theme.icon(16); color: Theme.hue("sliders"); opacity: r.selected ? 1 : 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast) } } }
    }

    // "2 hidden · Show" under a list, only when something is hidden
    component HiddenToggle: Item {
        property int count: 0
        property bool open: false
        signal toggled()
        width: parent ? parent.width : 0
        height: visible ? 24 : 0
        visible: count > 0
        StyledText {
            anchors.right: parent.right; anchors.rightMargin: Theme.s2
            capCenterIn: parent
            variant: "caption"
            color: htMa.containsMouse ? Theme.inkPrimary : Theme.inkDim
            text: count + (count === 1 ? " hidden  \u00b7  " : " hidden  \u00b7  ") + (open ? "Hide" : "Show")
            MouseArea { id: htMa; anchors.fill: parent; anchors.margins: -Theme.s2; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.toggled() }
        }
    }

    // ── output ──
    CcSheetBits.SectionLabel { text: "Output" }
    Column {
        width: parent.width
        spacing: Theme.s1
        move: CcSheetBits.MoveSpring {}
        Repeater {
            model: sinkModel
            delegate: DeviceRow { required property var modelData; node: modelData; selected: modelData === Audio.sink; onPick: Audio.setSink(modelData) }
        }
        HiddenToggle { count: soundSheet.hiddenOut; open: soundSheet.showHiddenOut; onToggled: soundSheet.showHiddenOut = !soundSheet.showHiddenOut }
    }
    CcSheetBits.Track { tint: Theme.hue("sliders");
        icon: Audio.muted ? "volumeMuted" : "volume"
        value: Audio.volume
        muted: Audio.muted
        onMoved: v => Audio.setVolume(v)
        onIconClicked: Audio.toggleMute()
    }

    // ── input ──
    CcSheetBits.SectionLabel { text: "Input"; gap: Theme.s4 }
    Column {
        width: parent.width
        spacing: Theme.s1
        move: CcSheetBits.MoveSpring {}
        Repeater {
            model: sourceModel
            delegate: DeviceRow { required property var modelData; node: modelData; selected: modelData === Audio.source; onPick: Audio.setSource(modelData) }
        }
        HiddenToggle { count: soundSheet.hiddenIn; open: soundSheet.showHiddenIn; onToggled: soundSheet.showHiddenIn = !soundSheet.showHiddenIn }
        StyledText { variant: "label"; text: "No input devices"; color: Theme.inkDim; opacity: (sourceModel.values.length === 0) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
    }
    CcSheetBits.Track { tint: Theme.hue("sliders");
        visible: sourceModel.values.length > 0
        icon: "mic"
        value: Audio.sourceVolume
        muted: Audio.sourceMuted
        onMoved: v => Audio.setSourceVolume(v)
        onIconClicked: Audio.toggleSourceMute()
    }

    // ── apps ──
    CcSheetBits.SectionLabel { text: "Apps"; gap: Theme.s4; opacity: (appModel.values.length > 0) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } } }
    Column {
        width: parent.width
        spacing: Theme.s2
        move: CcSheetBits.MoveSpring {}
        Repeater {
            model: appModel
            delegate: Rectangle {
                id: app
                required property var modelData
                readonly property var node: modelData
                width: parent.width
                height: appCol.implicitHeight + Theme.s2 * 2
                radius: Theme.rMd
                color: Theme.fillLow
                opacity: entered
                // delegate-owned entrance (patterns.md #5): a positioner `add` transition is canceled
                // by the next relayout and strands the row at opacity 0
                property real entered: 0
                Component.onCompleted: entered = 1
                Behavior on entered { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                Column {
                    id: appCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: Theme.s3; rightMargin: Theme.s3; topMargin: Theme.s2 }
                    // heading-to-track gap matches the Sound / Display grid tiles: their 16px
                    // header, 6px headGap, plus the half trackTrim the groove sits down by
                    spacing: 8
                    Item {
                        width: parent.width
                        height: 16
                        StyledText { anchors.left: parent.left; anchors.right: sub.left; anchors.rightMargin: Theme.s2; capCenterIn: parent; elide: Text.ElideRight; variant: "label"; font.weight: Theme.wMedium; text: soundSheet.appName(app.node); color: Theme.inkPrimary }
                        StyledText { id: sub; anchors.right: parent.right; capCenterIn: parent; width: Math.min(implicitWidth, app.width * 0.5); elide: Text.ElideRight; variant: "caption"; text: soundSheet.mediaName(app.node) === soundSheet.appName(app.node) ? "" : soundSheet.mediaName(app.node); color: Theme.inkDim }
                    }
                    CcSheetBits.Track { tint: Theme.hue("sliders");
                        icon: app.node.audio && app.node.audio.muted ? "volumeMuted" : "volume"
                        value: app.node.audio ? app.node.audio.volume : 0
                        muted: app.node.audio ? app.node.audio.muted : false
                        onMoved: v => { if (app.node.audio) app.node.audio.volume = v; }
                        onIconClicked: if (app.node.audio) app.node.audio.muted = !app.node.audio.muted
                    }
                }
            }
        }
    }
}

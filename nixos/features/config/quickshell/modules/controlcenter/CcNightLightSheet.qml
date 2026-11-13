import QtQuick
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The Night Light sheet (the on/off switch is the sheet header's toggle). Two cards:
// WARMTH, the color temperature, and SCHEDULE, which turns it on and off by the clock
// (see NightLight: it acts on the boundaries only, so a manual toggle in between stands).
Column {
    id: nlSheet

    property var panel: null
    spacing: Theme.s3
    // a fold inside a card is running on its own spring: the island's height spring stands
    // aside for exactly that long (ControlCenterContent.folding, patterns.md #48)
    property int folding: 0

    // 6500 K (neutral) at the left of the track, 1500 K (very warm) at the right
    function kelvin(v) { return Math.round((1500 + (1 - v) * 5000) / 100) * 100; }
    // −  20:00  +   quarter-hour steps, wrapping past midnight; the time itself is a field
    // you can click and type into ("7", "7:30", "1930", "7:30 pm" all parse). Enter or
    // clicking away commits, Escape puts the old time back; either way the keyboard goes
    // back to the panel so Escape closes the sheet again.
    component TimeRow: Item {
        id: tr
        property string label: ""
        property int minutes: 0
        signal changed(int m)
        width: parent ? parent.width : 0
        height: 32
        StyledText { anchors.left: parent.left; capCenterIn: parent; variant: "label"; text: tr.label; color: Theme.inkPrimary }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s2
            CcSheetBits.Chip { text: "\u2212"; anchors.verticalCenter: parent.verticalCenter; onClicked: tr.changed((tr.minutes + 1440 - 15) % 1440) }
            Rectangle {
                width: 76; height: 28
                radius: Theme.rSm
                anchors.verticalCenter: parent.verticalCenter
                color: tin.activeFocus ? Theme.sunken : (tinMa.containsMouse ? Theme.fillLow : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                MouseArea { id: tinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor; onClicked: tin.forceActiveFocus() }
                TextInput {
                    id: tin
                    anchors.fill: parent
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    cursorDelegate: Caret {}
                    color: Theme.inkPrimary
                    selectionColor: Theme.alpha(Theme.hue("sliders"), 0.45)
                    selectedTextColor: Theme.inkPrimary
                    font.family: Theme.fontBody
                    font.pixelSize: Theme.fsLabel
                    font.weight: Theme.wMedium
                    selectByMouse: true
                    maximumLength: 8
                    text: NightLight.fmtTime(tr.minutes)
                    function restore() { text = Qt.binding(() => NightLight.fmtTime(tr.minutes)); }
                    function commit() {
                        const m = NightLight.parseTime(text);
                        restore();
                        if (m >= 0 && m !== tr.minutes) tr.changed(m);
                    }
                    function leave() { if (nlSheet.panel) nlSheet.panel.refocus(); else focus = false; }
                    onActiveFocusChanged: if (activeFocus) selectAll(); else commit()
                    onAccepted: leave()
                    Keys.onEscapePressed: { restore(); leave(); }
                }
            }
            CcSheetBits.Chip { text: "+"; anchors.verticalCenter: parent.verticalCenter; onClicked: tr.changed((tr.minutes + 15) % 1440) }
        }
    }

    // ── warmth ──
    CcSheetBits.SectionLabel { text: "Warmth" }
    Rectangle {
        width: parent.width
        height: warmBody.implicitHeight + Theme.s3 * 2
        radius: Theme.rLg
        color: Theme.fillLow
        Column {
            id: warmBody
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s3 }
            // the label sits as far above its track as "Display" and "Sound" sit above
            // theirs on the grid (measured: 9.6px from the baseline to the track; this was
            // 15.2 with the old s2 + 3)
            spacing: Theme.s2 - 2.6
            Item {
                width: parent.width
                height: 18
                StyledText { anchors.left: parent.left; capCenterIn: parent; variant: "label"; font.weight: Theme.wMedium; text: "Color temperature"; color: Theme.inkPrimary }
                StyledText { anchors.right: parent.right; capCenterIn: parent; variant: "caption"; text: NightLight.temperature + " K"; color: Theme.inkDim }
            }
            // The tint follows the drag LIVE (NightLight.setTemp throttles the daemon call);
            // the disk write happens ONCE on release (patterns.md #49).
            CcSheetBits.Track {
                tint: Theme.hue("sliders")
                width: parent.width
                icon: "night"
                showPercent: false
                value: 1 - (NightLight.temperature - 1500) / 5000
                onMoved: v => NightLight.setTemp(nlSheet.kelvin(v))
                onReleased: v => { NightLight.setTemp(nlSheet.kelvin(v)); Config.nightLightTemp = nlSheet.kelvin(v); }
            }
        }
    }

    // ── schedule ──
    CcSheetBits.SectionLabel { text: "Schedule"; gap: Theme.s4 }
    Rectangle {
        width: parent.width
        height: schedBody.implicitHeight + Theme.s3 * 2
        radius: Theme.rLg
        color: Theme.fillLow
        clip: true
        Column {
            id: schedBody
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s3 }
            spacing: Theme.s2
            Item {
                width: parent.width
                height: 36
                Column {
                    anchors.left: parent.left
                    anchors.right: schedToggle.left; anchors.rightMargin: Theme.s3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    StyledText { variant: "label"; font.weight: Theme.wMedium; text: "Turn on automatically"; color: Theme.inkPrimary }
                    StyledText { variant: "caption"; text: Config.nightLightSchedule ? NightLight.scheduleHint : "Only when you switch it on"; color: Theme.inkDim }
                }
                Toggle { id: schedToggle; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: Config.nightLightSchedule; onToggled: Config.nightLightSchedule = !Config.nightLightSchedule }
            }
            // The two times fold in on the ONE spring here, the same way the display sheet's
            // mode list does: `fold` runs 0 -> 1, the wrapper's height follows it, the card
            // and the sheet follow the wrapper, and the island's own height spring is held
            // off while it runs (nlSheet.folding) so the notch tracks the fold frame by frame
            // instead of the card snapping and the notch chasing it. The wrapper is always
            // laid out, from -spacing (closed: cancels the Column gap, so the card at rest is
            // exactly the one-row card) to openH.
            Item {
                id: schedFold
                width: parent.width
                readonly property real openH: schedTimes.implicitHeight
                property real fold: Config.nightLightSchedule ? 1 : 0
                Behavior on fold { enabled: nlSheet.visible; NumberAnimation { duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier; onRunningChanged: nlSheet.folding += running ? 1 : -1 } }
                height: fold * (openH + schedBody.spacing) - schedBody.spacing
                clip: true
                Column {
                    id: schedTimes
                    anchors.top: parent.top
                    width: parent.width
                    spacing: Theme.s1
                    visible: schedFold.height > 0.5
                    opacity: Math.max(0, Math.min(1, schedFold.fold))
                    Rectangle { width: parent.width; height: 1; color: Theme.hairline }
                    TimeRow { label: "From";  minutes: Config.nightLightStart; onChanged: m => Config.nightLightStart = m }
                    TimeRow { label: "Until"; minutes: Config.nightLightEnd;   onChanged: m => Config.nightLightEnd = m }
                }
            }
        }
    }
}

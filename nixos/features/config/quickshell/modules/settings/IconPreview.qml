import QtQuick
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// A strip of the shell's drawn icons exactly where they are most visible, built from the
// same components at the same sizes and colors the shell uses: the control center's
// accent and neutral discs, the slider tracks with their small glyphs, the sheet chevron,
// the power menu row and the island's status corner. It sits on the island's own black so
// edges are judged against the real ground. Nothing here is a mock-up drawing: every
// glyph is Icon / WifiIcon / BatteryIcon, so each Settings knob shows up live.
Rectangle {
    id: root
    radius: Theme.rLg
    color: Theme.base
    border.width: 1
    border.color: Theme.hairline
    implicitHeight: 84

    readonly property real glyph: Theme.iconSize           // the tiles' glyph size at the default panel scale
    readonly property color tone: Theme.hue("toggles")

    Row {
        anchors.centerIn: parent
        spacing: Theme.s3

        // control center toggles: on (accent disc) and off (neutral disc)
        Rectangle {
            width: 44; height: 44; radius: 22; color: root.tone; anchors.verticalCenter: parent.verticalCenter
            WifiIcon {
                anchors.centerIn: parent
                scale: root.glyph / Theme.iconAnchor
                strength: 0.5
                color: Theme.onAccent
                dimColor: Theme.alpha(Theme.onAccent, Math.min(1, 0.45 * Theme.iconUnlit))
            }
        }
        Rectangle {
            width: 44; height: 44; radius: 22; color: root.tone; anchors.verticalCenter: parent.verticalCenter
            Icon { anchors.centerIn: parent; name: "bluetooth"; size: root.glyph; color: Theme.onAccent }
        }
        Rectangle {
            width: 44; height: 44; radius: 22; color: Theme.fillHigh; anchors.verticalCenter: parent.verticalCenter
            Icon { anchors.centerIn: parent; name: "dnd"; size: root.glyph; color: Theme.inkPrimary }
        }
        Rectangle {
            width: 44; height: 44; radius: 22; color: Theme.fillHigh; anchors.verticalCenter: parent.verticalCenter
            Icon { anchors.centerIn: parent; name: "night"; size: root.glyph; color: Theme.inkPrimary }
        }

        // slider tracks with their small glyphs, and the sheet chevron on its disc
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: ["brightness", "volume"]
                delegate: Row {
                    required property string modelData
                    spacing: 6
                    Rectangle {
                        width: 76; height: 23; radius: height / 2; color: Theme.sunken
                        Rectangle { width: 50; height: parent.height; radius: height / 2; color: Theme.hue("sliders")
                            Icon { anchors.left: parent.left; anchors.leftMargin: 9; anchors.verticalCenter: parent.verticalCenter; name: parent.parent.parent.modelData; size: Theme.icon(16); color: Theme.onAccent } }
                    }
                    Rectangle { width: 23; height: 23; radius: 11.5; color: Theme.fillLow
                        Icon { anchors.centerIn: parent; name: "chevron"; size: Theme.icon(14); color: Theme.inkDim } }
                }
            }
        }

        // the power menu row
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s2
            Repeater {
                model: ["lock", "logout", "restart", "power"]
                delegate: Icon { required property string modelData; name: modelData; size: Theme.icon(24); color: Theme.inkPrimary }
            }
        }

        // the island's status corner
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s2
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "bell"; size: Theme.icon(18); color: Theme.hue("status") }
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "search"; size: Theme.icon(18); color: Theme.inkDim }
            BatteryIcon { anchors.verticalCenter: parent.verticalCenter; bodyWidth: 27; bodyHeight: 13; level: 0.7; tint: Theme.hue("status") }
        }
    }
}

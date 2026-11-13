import QtQuick
import "../../theme"
import "../../components"

// A Settings row: label left, a segmented choice right. Its own file, not an inline
// component of SettingsWindow: a component added to a file while the shell is running
// fails the hot reload with "is not a type" (notes/patterns.md), a new file does not.
Item {
    id: cr
    property string label: ""
    property bool first: false
    property var options: []
    property string value: ""
    signal picked(string v)
    width: parent ? parent.width : 0
    implicitHeight: 48
    Rectangle {
        visible: !cr.first
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: Theme.s4; rightMargin: Theme.s4 }
        height: 1; color: Theme.hairline
    }
    StyledText {
        anchors { left: parent.left; leftMargin: Theme.s4 }
        capCenterIn: parent
        variant: "label"; text: cr.label; color: Theme.inkPrimary
    }
    Rectangle {
        anchors { right: parent.right; rightMargin: Theme.s4; verticalCenter: parent.verticalCenter }
        height: 30
        width: segRow.implicitWidth + 4
        radius: Theme.rPill
        color: Theme.surfaceOverlay
        Row {
            id: segRow
            anchors.centerIn: parent
            Repeater {
                model: cr.options
                delegate: Rectangle {
                    id: seg
                    required property string modelData
                    readonly property bool active: cr.value === modelData
                    width: segText.implicitWidth + Theme.s3 * 2; height: 26; radius: 13
                    color: active ? Theme.accent : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                    Rectangle { anchors.fill: parent; radius: 13; color: Theme.fillLow; opacity: segMa.containsMouse && !seg.active ? 1 : 0 }
                    StyledText { id: segText; anchors.horizontalCenter: parent.horizontalCenter; capCenterIn: parent; variant: "caption"; font.weight: Theme.wMedium; text: seg.modelData; color: seg.active ? Theme.onAccent : Theme.inkPrimary }
                    MouseArea { id: segMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cr.picked(seg.modelData) }
                }
            }
        }
    }
}

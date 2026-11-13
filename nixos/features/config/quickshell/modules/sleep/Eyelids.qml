import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

// The eyelids: one black sheet per monitor, above everything, as opaque as Sleep.closed.
// Not a surface of the shell (nothing lives on it), which is why it isn't the island's:
// it is the screen itself going dark before sleep and coming back after. Unmapped the
// whole time the eyes are open.
PanelWindow {
    id: lid

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:eyelids"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Sleep.closed > 0

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: Sleep.closed
    }

    // the pointer goes dark with the rest, and nothing underneath gets a stray click
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.BlankCursor
    }
}

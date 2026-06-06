import Quickshell // for PanelWindow
import QtQuick // for Text
import Quickshell.Io // for Process

PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 30

  Text {
    id: clock
    // center the bar in its parent component (the window)
    anchors.centerIn: parent

  }
}

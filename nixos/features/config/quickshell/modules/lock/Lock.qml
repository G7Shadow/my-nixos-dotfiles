import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// Lock screen. WlSessionLock freezes all compositor input 'til you unlock, with one
// WlSessionLockSurface per monitor. All the state + PAM auth live in the LockState
// singleton ('cause the surface is its own isolated scope and can't reach ids). Fail
// closed: only LockState clears `locked`, and only on PamResult.Success. The look lives
// in LockContent (split out so it can be previewed without triggering a real lock).
WlSessionLock {
    id: lock
    locked: LockState.locked

    surface: WlSessionLockSurface {
        id: surf
        color: "transparent"   // with misc:session_lock_xray the screen shows through until LockContent's wallpaper has faded up over it

        LockContent {
            id: content
            anchors.fill: parent
            screenName: surf.screen?.name ?? ""
        }

        // The eyelids, again: the desktop's sheet is under the lock once it is up, so the
        // lock screen carries its own. Sleep locks under the black and wake fades it off.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: Sleep.closed
            visible: opacity > 0
        }
        MouseArea {
            anchors.fill: parent
            visible: Sleep.closed > 0
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.BlankCursor
        }

        Component.onCompleted: content.grabFocus()
    }
}

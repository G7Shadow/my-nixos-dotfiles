import QtQuick
import "../theme"

// Text caret for every TextInput (`cursorDelegate: Caret {}`). A slim accent pill that
// jumps with the text like a normal caret (no glide: user call, a caret that drifts
// between glyphs read as lag) but fade-blinks instead of hard toggling, and holds solid
// while you type.
Item {
    id: caret

    property color tint: Theme.accent

    width: 2
    height: parent.cursorRectangle.height
    visible: parent.cursorVisible

    onXChanged: touch()

    // no blinking while typing: every edit holds the pill solid and the blink only starts
    // once the field has been idle for a moment (a blink restarting under each keystroke
    // reads as the caret vanishing mid-word)
    function touch() { blink.stop(); pill.opacity = 1; idle.restart(); }
    Timer { id: idle; interval: 900; onTriggered: blink.restart() }
    Connections { target: caret.parent; function onTextChanged() { caret.touch(); } }
    onVisibleChanged: visible ? touch() : blink.stop()
    Component.onCompleted: if (visible) touch()

    Rectangle {
        id: pill
        width: 2
        radius: 1
        height: Math.round(caret.height * 0.78)
        y: Math.round((caret.height - height) / 2)
        color: caret.tint
    }

    SequentialAnimation {
        id: blink
        loops: Animation.Infinite
        NumberAnimation { target: pill; property: "opacity"; to: 0.1; duration: 420; easing.type: Easing.InOutQuad }
        NumberAnimation { target: pill; property: "opacity"; to: 1.0; duration: 420; easing.type: Easing.InOutQuad }
    }
}

import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../../config"
import "../../theme"
import "../../services"
import "../../components"

// The media block in the expanded island, to the left of the time and date: the album
// art as a square, and the title and the artist to its right. No card behind it: it
// sits on the island itself. Prev / play / next sit under the artist. Click anywhere else
// on it to play or pause; scroll over it to change track.
Item {
    id: root

    property real cardW: 214         // the whole block: art + gap + text
    property real cardH: 52          // the art's side
    property bool live: false         // on screen
    // the small form for the island's right column: the art at the RIGHT end, the title
    // and the artist right-aligned to its left, no transport buttons (click = play or
    // pause, scroll = track). Set once; it is not switched while the block lives.
    property bool mirrored: false
    readonly property var p: Media.player
    readonly property bool playing: p ? p.isPlaying : false
    readonly property color tone: Theme.hue("media")

    implicitWidth: cardW
    implicitHeight: cardH
    width: implicitWidth
    height: implicitHeight

    // ── art ──
    Item {
        id: artBox
        anchors.left: root.mirrored ? undefined : parent.left
        anchors.right: root.mirrored ? parent.right : undefined
        anchors.verticalCenter: parent.verticalCenter
        width: root.cardH; height: width
        // The corner radius follows the art's size: the theme's card radius on a big
        // cover, a quarter of the side on a small one. (A 14 px radius on a 36 px cover
        // ate so much of each corner that the picture looked cut off.)
        readonly property real r: Math.min(Theme.rMd, width * 0.24)
        Rectangle {
            anchors.fill: parent
            radius: artBox.r
            color: Theme.surfaceOverlay
            opacity: artImg.ready ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            Icon { anchors.centerIn: parent; name: "music"; size: Theme.icon(16); color: root.tone }
        }
        // Rounded by a real clip with soft edges (Quickshell's ClippingRectangle), not by
        // a thresholded mask: the mask's edge was a cutoff, so the corners came out in
        // steps and a sliver of the cover went missing along every side.
        ClippingRectangle {
            anchors.fill: parent
            radius: artBox.r
            color: "transparent"
            opacity: artImg.ready ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
            Image {
                id: artImg
                readonly property bool ready: status === Image.Ready && source.toString() !== ""
                anchors.fill: parent
                source: root.p?.trackArtUrl ?? ""
                // read at twice the drawn size, so a small cover stays sharp on a scaled screen
                sourceSize.width: Math.ceil(artBox.width * 2)
                sourceSize.height: Math.ceil(artBox.height * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
            }
        }
    }

    // ── title and artist, left aligned, to the right of the art ──
    Column {
        anchors.left: root.mirrored ? parent.left : artBox.right
        anchors.leftMargin: root.mirrored ? 0 : 12
        anchors.right: root.mirrored ? artBox.left : parent.right
        anchors.rightMargin: root.mirrored ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
        z: 1                             // the buttons sit over the block's own press area
        spacing: 1
        StyledText {
            width: parent.width
            text: root.p?.trackTitle ?? "Nothing playing"
            horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
            font.pixelSize: Theme.fsLabel
            font.weight: Theme.wSemiBold
            color: Theme.inkPrimary
            elide: Text.ElideRight
        }
        StyledText {
            width: parent.width
            visible: text !== ""
            text: root.p?.trackArtist ?? ""
            horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
            font.pixelSize: Theme.fsCaption
            color: Theme.inkDim
            elide: Text.ElideRight
        }
        // prev / play / next, right below the artist; bare glyphs, no discs
        Row {
            visible: Config.mediaShowTransport && !root.mirrored
            topPadding: 9
            spacing: 18
            Icon {
                name: "prev"; size: Theme.icon(15); color: Theme.inkPrimary
                opacity: root.p?.canGoPrevious ? 0.85 : 0.3
                MouseArea { anchors.fill: parent; anchors.margins: -7; enabled: root.p?.canGoPrevious ?? false; cursorShape: Qt.PointingHandCursor; onClicked: root.p.previous() }
            }
            Icon {
                name: root.playing ? "pause" : "play"; size: Theme.icon(15); color: Theme.inkPrimary
                opacity: root.p ? 1 : 0.3
                MouseArea { anchors.fill: parent; anchors.margins: -7; enabled: !!root.p; cursorShape: Qt.PointingHandCursor; onClicked: root.p.togglePlaying() }
            }
            Icon {
                name: "next"; size: Theme.icon(15); color: Theme.inkPrimary
                opacity: root.p?.canGoNext ? 0.85 : 0.3
                MouseArea { anchors.fill: parent; anchors.margins: -7; enabled: root.p?.canGoNext ?? false; cursorShape: Qt.PointingHandCursor; onClicked: root.p.next() }
            }
        }
    }

    // ── press and scroll ──
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.p?.togglePlaying()
        onWheel: wheel => {
            const dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y;
            if (dy === 0 || !root.p || cool.running) return;
            if (dy < 0 ? !root.p.canGoNext : !root.p.canGoPrevious) return;
            if (dy < 0) root.p.next(); else root.p.previous();
            cool.restart();
        }
    }
    Timer { id: cool; interval: 300 }
}

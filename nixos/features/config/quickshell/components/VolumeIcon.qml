import QtQuick
import QtQuick.Shapes
import "../theme"

// Volume icon that tracks the level: a speaker, plus waves that fade in as the level
// rises (one wave above ~0%, a second above ~50%), or an X when muted. The wave and X
// transitions animate on alpha, so the icon reacts as you change the volume.
Item {
    id: root

    property real level: 0       // 0..1
    property bool muted: false
    property color color: Theme.inkPrimary
    property real size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size

    // the Settings knobs the shared icon set has, applied to this drawing too: stroke
    // (scaled by the knob, held above the minimum), scale in box, line ends, renderer
    readonly property real sw: Theme.stroke(2.2, size)
    layer.enabled: Theme.iconMsaa
    layer.samples: 4

    readonly property real lv: Math.max(0, Math.min(1, level))
    // each part's visibility, animated
    property real w1: (!muted && lv > 0.001) ? 1 : 0
    property real w2: (!muted && lv >= 0.5) ? 1 : 0
    property real xo: muted ? 1 : 0
    Behavior on w1 { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
    Behavior on w2 { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
    Behavior on xo { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Theme.iconMsaa ? Shape.GeometryRenderer : Shape.CurveRenderer
        transform: [
            Scale { xScale: root.size / 24 * Theme.iconScale; yScale: root.size / 24 * Theme.iconScale },
            Translate { x: root.size * (1 - Theme.iconScale) / 2; y: root.size * (1 - Theme.iconScale) / 2 }
        ]

        // speaker body: always drawn, filled
        ShapePath {
            fillColor: root.color; strokeColor: "transparent"; strokeWidth: 0
            PathSvg { path: "M4,10 H7 L11,6 V18 L7,14 H4 Z" }
        }
        // wave 1 (small)
        ShapePath {
            fillColor: "transparent"; strokeColor: Theme.alpha(root.color, root.w1); strokeWidth: root.sw; capStyle: Theme.iconCapStyle
            PathSvg { path: "M14,9.5 a3.5,3.5 0 0,1 0,5" }
        }
        // wave 2 (large)
        ShapePath {
            fillColor: "transparent"; strokeColor: Theme.alpha(root.color, root.w2); strokeWidth: root.sw; capStyle: Theme.iconCapStyle
            PathSvg { path: "M16.5,7 a7,7 0 0,1 0,10" }
        }
        // mute X
        ShapePath {
            fillColor: "transparent"; strokeColor: Theme.alpha(root.color, root.xo); strokeWidth: root.sw; capStyle: Theme.iconCapStyle
            PathSvg { path: "M14.5,9.5 L19.5,14.5 M19.5,9.5 L14.5,14.5" }
        }
    }
}

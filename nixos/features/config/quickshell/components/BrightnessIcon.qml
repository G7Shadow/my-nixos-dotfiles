import QtQuick
import QtQuick.Shapes
import "../theme"

// Brightness icon, a sun, that tracks the level: the rays brighten as the level rises
// (and fade toward a faint core when it's low), so the icon actually reacts as you
// change brightness. The core stays put; only the rays' alpha animates.
Item {
    id: root

    property real level: 0       // 0..1
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
    property real rayOp: 0.2 + 0.8 * lv      // rays fade in as it gets brighter
    Behavior on rayOp { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Theme.iconMsaa ? Shape.GeometryRenderer : Shape.CurveRenderer
        transform: [
            Scale { xScale: root.size / 24 * Theme.iconScale; yScale: root.size / 24 * Theme.iconScale },
            Translate { x: root.size * (1 - Theme.iconScale) / 2; y: root.size * (1 - Theme.iconScale) / 2 }
        ]

        // core, never changes
        ShapePath {
            fillColor: "transparent"; strokeColor: root.color; strokeWidth: root.sw
            PathSvg { path: "M8.5,12 a3.5,3.5 0 1,0 7,0 a3.5,3.5 0 1,0 -7,0" }
        }
        // rays, alpha animates with the level
        ShapePath {
            fillColor: "transparent"; strokeColor: Theme.alpha(root.color, root.rayOp); strokeWidth: root.sw; capStyle: Theme.iconCapStyle
            PathSvg { path: "M12,2 V4.5 M12,19.5 V22 M2,12 H4.5 M19.5,12 H22 M5,5 L6.8,6.8 M17.2,17.2 L19,19 M19,5 L17.2,6.8 M6.8,17.2 L5,19" }
        }
    }
}

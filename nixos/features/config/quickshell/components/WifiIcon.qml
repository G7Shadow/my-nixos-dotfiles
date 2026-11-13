import QtQuick
import QtQuick.Shapes
import "../theme"

// Wi-Fi icon drawn from shapes that also works as a signal meter: a dot + two arcs,
// each lit once `strength` clears its threshold, dim otherwise. `strength` takes either
// 0..1 or 0..100. Colors are themeable so it can sit inside an accent tile. Geometry's
// tuned so the fan's OPTICAL center lands on the box center (the dot + lower arcs are
// heavy), so it lines up with its sibling icons under verticalCenter.
Item {
    id: root

    property real strength: 0          // 0..1 or 0..100
    property bool active: true         // connected / enabled
    property color color: Theme.accent
    property color dimColor: Theme.inkFaint

    implicitWidth: 22
    implicitHeight: 16

    // take either 0..1 or a 0..100 percentage
    readonly property real level: strength > 1 ? strength / 100 : strength

    // the Settings knobs the shared icon set has, applied to this drawing too: stroke
    // (scaled, and held above the minimum), how much of its box the fan fills, the renderer
    readonly property real sw: Math.max(2.2 * Theme.strokeK, Theme.iconStrokeFloor)
    transform: Scale { origin.x: root.width / 2; origin.y: root.height / 2; xScale: Theme.iconScale; yScale: Theme.iconScale }
    layer.enabled: Theme.iconMsaa
    layer.samples: 4

    readonly property real cx: width / 2
    readonly property real cy: height - 4   // lifts the fan so its optical center sits ≈ box center

    function arcColor(t) {
        return (active && root.level >= t) ? root.color : root.dimColor;
    }

    // base dot, lit whenever connected
    Rectangle {
        width: 4; height: 4; radius: 2
        x: root.cx - 2
        y: root.cy - 2
        color: root.active ? root.color : root.dimColor
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Theme.iconMsaa ? Shape.GeometryRenderer : Shape.CurveRenderer   // curve: analytic GPU AA, smooth thin arcs

        // inner arc, any signal at all
        // two arcs over the dot: three steps in all. Three arcs in a 16px-tall box left
        // each one about a pixel and a half of room, and they smeared into each other
        ShapePath {
            strokeColor: root.arcColor(0.34); strokeWidth: root.sw; fillColor: "transparent"; capStyle: Theme.iconCapStyle
            PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 5.25; radiusY: 5.25; startAngle: 220; sweepAngle: 100 }
        }
        ShapePath {
            strokeColor: root.arcColor(0.6); strokeWidth: root.sw; fillColor: "transparent"; capStyle: Theme.iconCapStyle
            PathAngleArc { centerX: root.cx; centerY: root.cy; radiusX: 10; radiusY: 10; startAngle: 220; sweepAngle: 100 }
        }
    }
}

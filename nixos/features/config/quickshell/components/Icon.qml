import QtQuick
import QtQuick.Shapes
import "../theme"

// Custom icon set: swaps the nerd-font glyphs for shapes so every icon is actually
// drawn (so it tints and stays crisp at any size) instead of being a font codepoint.
// Each icon is an SVG path in a 24×24 space, scaled to `size`; `filled` icons get a
// solid fill, the rest are stroked at ~1.8px (steady stroke weight, round caps).
// Drop-in for `StyledText{ font.family: Theme.fontGlyph; text: gX }` →
// `Icon{ name: "x" }`. (Wi-Fi and battery have their own data-driven components.)
Item {
    id: root

    property string name: ""
    property real size: Theme.iconSize
    property color color: Theme.inkPrimary
    // in 24-space; the Scale transform shrinks it at render size. Floored so the rendered
    // stroke never drops under Theme.iconStrokeFloor px (1.2 by default): at 14px the theme
    // stroke came out at 0.99px and the curve renderer drew nothing at all (filled glyphs
    // beside it were fine). The floor is a Settings knob: higher is steadier and heavier.
    property real strokeWidth: Math.max(Theme.iconStroke, Theme.iconStrokeFloor * 24 / Math.max(1, size))

    implicitWidth: size
    implicitHeight: size

    readonly property var _icons: ({
        "back":       { d: "M19,12 H6 M12,6 L6,12 L12,18", filled: false },
        "bluetooth":  { d: "M7,8.5 L16.5,15.5 L12,19 V5 L16.5,8.5 L7,15.5", filled: false },
        "volume":     { d: "M3,9.5 H6.5 L11,5.5 V18.5 L6.5,14.5 H3 Z M14.5,9 a4.2,4.2 0 0,1 0,6 M17.5,6 a8.5,8.5 0 0,1 0,12", filled: false },
        "volumeMuted":{ d: "M3,9.5 H6.5 L11,5.5 V18.5 L6.5,14.5 H3 Z M15.5,9.2 L21,14.8 M21,9.2 L15.5,14.8", filled: false },
        "mic":        { d: "M12,3 a3,3 0 0,1 3,3 V11 a3,3 0 0,1 -6,0 V6 a3,3 0 0,1 3,-3 Z M6.5,11 a5.5,5.5 0 0,0 11,0 M12,16.5 V20.5 M9,20.5 H15", filled: false },
        "brightness": { d: "M8.5,12 a3.5,3.5 0 1,0 7,0 a3.5,3.5 0 1,0 -7,0 M12,2 V4.5 M12,19.5 V22 M2,12 H4.5 M19.5,12 H22 M5,5 L6.8,6.8 M17.2,17.2 L19,19 M19,5 L17.2,6.8 M6.8,17.2 L5,19", filled: false },
        "night":      { d: "M19.4,13.7 A8,8 0 1,1 10.3,4.6 A6.2,6.2 0 0,0 19.4,13.7 Z", filled: false },
        "bolt":       { d: "M13,2 L5,13.5 H11 L10,22 L19,10 H12.5 Z", filled: true },
        "dnd":        { d: "M4,12 a8,8 0 1,0 16,0 a8,8 0 1,0 -16,0 M8.5,12 H15.5", filled: false },
        "play":       { d: "M8,5 L19,12 L8,19 Z", filled: true },
        "pause":      { d: "M7,5 H10.5 V19 H7 Z M13.5,5 H17 V19 H13.5 Z", filled: true },
        "prev":       { d: "M7,5 H9.2 V19 H7 Z M17,5 L9.2,12 L17,19 Z", filled: true },
        "next":       { d: "M14.8,5 H17 V19 H14.8 Z M7,5 L14.8,12 L7,19 Z", filled: true },
        "rewind":     { d: "M11.5,6 L4.5,12 L11.5,18 Z M19,6 L12,12 L19,18 Z", filled: true },
        "forward":    { d: "M12.5,6 L19.5,12 L12.5,18 Z M5,6 L12,12 L5,18 Z", filled: true },
        "search":     { d: "M17,10.5 a6.5,6.5 0 0,1 -6.5,6.5 a6.5,6.5 0 0,1 -6.5,-6.5 a6.5,6.5 0 0,1 6.5,-6.5 a6.5,6.5 0 0,1 6.5,6.5 M15.2,15.2 L20.2,20.2", filled: false },
        "clipboard":  { d: "M7.5,6 H16.5 a1,1 0 0,1 1,1 V19.5 a1,1 0 0,1 -1,1 H7.5 a1,1 0 0,1 -1,-1 V7 a1,1 0 0,1 1,-1 Z M10,6 V5 a2,2 0 0,1 4,0 V6", filled: false },
        "calculator": { d: "M6.5,3.5 H17.5 a1,1 0 0,1 1,1 V19.5 a1,1 0 0,1 -1,1 H6.5 a1,1 0 0,1 -1,-1 V4.5 a1,1 0 0,1 1,-1 Z M8.5,6.5 H15.5 V9 H8.5 Z M9.5,13 h0 M14.5,13 h0 M9.5,16.5 h0 M14.5,16.5 h0", filled: false },
        "apps":       { d: "M7.9,6 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M13.9,6 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M19.9,6 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M7.9,12 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M13.9,12 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M19.9,12 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M7.9,18 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M13.9,18 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z M19.9,18 a1.9,1.9 0 0,1 -1.9,1.9 a1.9,1.9 0 0,1 -1.9,-1.9 a1.9,1.9 0 0,1 1.9,-1.9 a1.9,1.9 0 0,1 1.9,1.9 Z", filled: true },
        "music":      { d: "M8.2,18 a2.3,2.3 0 1,0 4.6,0 a2.3,2.3 0 1,0 -4.6,0 M12.8,17 V5 C15.5,5.5 17,7 17.5,9", filled: false },
        "controller": { d: "M7.5,6 H16.5 a3,3 0 0,1 2.97,2.57 L20.56,16.2 a1.55,1.55 0 0,1 -2.63,1.3 L15.4,15 H8.6 L6.07,17.5 a1.55,1.55 0 0,1 -2.63,-1.3 L4.53,8.57 a3,3 0 0,1 2.97,-2.57 Z M8.5,9 V12 M7,10.5 H10 M15,11.5 L15,11.51 M17.5,9.5 L17.5,9.51", filled: false },
        "power":      { d: "M12,3.5 V12.5 M6.9,5.9 a8,8 0 1,0 10.2,0", filled: false },
        "lock":       { d: "M6.5,9 H17.5 a1.5,1.5 0 0,1 1.5,1.5 V19.5 a1.5,1.5 0 0,1 -1.5,1.5 H6.5 a1.5,1.5 0 0,1 -1.5,-1.5 V10.5 a1.5,1.5 0 0,1 1.5,-1.5 Z M8,9 V6.5 a4,4 0 0,1 8,0 V9 M12,15 L12,15.01", filled: false },
        "restart":    { d: "M18.5,9 A7,7 0 1,0 19,12 M18.5,4.5 V9 H14", filled: false },
        "logout":     { d: "M10,4 H6 a2,2 0 0,0 -2,2 V18 a2,2 0 0,0 2,2 H10 M9.5,12 H20 M16.5,8.5 L20,12 L16.5,15.5", filled: false },
        "display":    { d: "M4,5 H20 a1,1 0 0,1 1,1 V15 a1,1 0 0,1 -1,1 H4 a1,1 0 0,1 -1,-1 V6 a1,1 0 0,1 1,-1 Z M9,20 H15 M12,16 V20", filled: false },
        "person":     { d: "M12,4.3 a3.9,3.9 0 1,0 0.01,0 Z M4.8,20 C4.8,14.6 8,12.9 12,12.9 C16,12.9 19.2,14.6 19.2,20 Z", filled: true },
        "chevron":    { d: "M9,6.8 L14.2,12 L9,17.2", filled: false },
        "check":      { d: "M5,12.5 L9.5,17 L19,7.5", filled: false },
        "headphones": { d: "M4,14 V12 a8,8 0 0,1 16,0 V14 M4,14 h2.5 a1,1 0 0,1 1,1 V19 a1,1 0 0,1 -1,1 H5 a1,1 0 0,1 -1,-1 Z M20,14 h-2.5 a1,1 0 0,0 -1,1 V19 a1,1 0 0,0 1,1 H19 a1,1 0 0,0 1,-1 Z", filled: false },
        "phone":      { d: "M8,3 H16 a1.5,1.5 0 0,1 1.5,1.5 V19.5 a1.5,1.5 0 0,1 -1.5,1.5 H8 a1.5,1.5 0 0,1 -1.5,-1.5 V4.5 a1.5,1.5 0 0,1 1.5,-1.5 Z M11,18.5 h2", filled: false },
        "keyboard":   { d: "M3.5,7 H20.5 a1,1 0 0,1 1,1 V16 a1,1 0 0,1 -1,1 H3.5 a1,1 0 0,1 -1,-1 V8 a1,1 0 0,1 1,-1 Z M7,10.5 h0 M11,10.5 h0 M15,10.5 h0 M19,10.5 h0 M8,14 h8", filled: false },
        "mouse":      { d: "M12,3 a5.5,5.5 0 0,1 5.5,5.5 V15.5 a5.5,5.5 0 0,1 -11,0 V8.5 a5.5,5.5 0 0,1 5.5,-5.5 Z M12,7 V10", filled: false },
        "watch":      { d: "M8.5,7.5 H15.5 a1.5,1.5 0 0,1 1.5,1.5 V15 a1.5,1.5 0 0,1 -1.5,1.5 H8.5 a1.5,1.5 0 0,1 -1.5,-1.5 V9 a1.5,1.5 0 0,1 1.5,-1.5 Z M9.5,7.5 L10,4 H14 L14.5,7.5 M9.5,16.5 L10,20 H14 L14.5,16.5", filled: false },
        "bell":       { d: "M12,3.5 a5.5,5.5 0 0,1 5.5,5.5 V13 L19.3,15.6 H4.7 L6.5,13 V9 a5.5,5.5 0 0,1 5.5,-5.5 Z M9.8,18.5 a2.2,2.2 0 0,0 4.4,0", filled: false }
    })
    readonly property var _def: _icons[name] ?? ({ d: "", filled: false })

    // The curve renderer by default (smooth analytic edges); Settings can switch the whole
    // set to the geometry renderer with multisampling, and a caller can still ask for a
    // renderer itself.
    property int renderer: Theme.iconMsaa ? Shape.GeometryRenderer : Shape.CurveRenderer
    layer.enabled: Theme.iconMsaa
    layer.samples: 4
    // Settings knobs: how much of the box the drawing fills, and the stroke's ends/corners.
    // (Dots drawn as zero-length strokes, the lock's keyhole and the controller's buttons,
    // only exist with round or square ends.)
    readonly property real _k: Theme.iconScale
    readonly property int _cap: Theme.iconCapStyle
    readonly property int _join: Theme.iconJoinStyle

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: root.renderer
        transform: [
            Scale { xScale: root.size / 24 * root._k; yScale: root.size / 24 * root._k },
            Translate { x: root.size * (1 - root._k) / 2; y: root.size * (1 - root._k) / 2 }
        ]

        ShapePath {
            fillColor: root._def.filled ? root.color : "transparent"
            strokeColor: root._def.filled ? "transparent" : root.color
            // -1 DISABLES stroking outright for filled icons. A transparent stroke with a
            // positive width isn't the same thing: the curve renderer still builds stroke
            // geometry for it, and that's enough to lose the fill entirely — which is why the
            // solid glyphs (play/pause/prev/next) drew nothing while the stroked ones were fine.
            strokeWidth: root._def.filled ? -1 : root.strokeWidth
            capStyle: root._cap
            joinStyle: root._join
            PathSvg { path: root._def.d }
        }
    }
}

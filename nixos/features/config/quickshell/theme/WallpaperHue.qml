pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

// What color the wallpaper IS, for the "accent from the wallpaper" setting. It finds the
// picture's most prominent color and, given the theme's hues, says which of them sits
// closest to it. The accent stays one of the theme's own colors: the wallpaper only
// chooses among them, it never brings a color of its own.
//
// Only exists once the setting is on (Theme reaches for it behind that check), and
// only looks again when the wallpaper changes. The picture is shrunk to 40x40 by
// ImageMagick (about a tenth of a second) and the 1600 pixels are read here. Without
// `magick` installed nothing is ever valid and the accent stays the theme's.
Singleton {
    id: root

    property bool valid: false
    property real hue: -1                 // the prominent color's hue angle, 0..360
    property color prominent: "transparent"

    // sRGB (0..1 each) -> [lightness, chroma, hue] in OKLCH, a space where "how far apart
    // two colors look" and "how far apart their numbers are" agree
    function lch(r, g, b) {
        const f = c => c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        r = f(r); g = f(g); b = f(b);
        const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
        const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
        const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
        const L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
        const A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
        const B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
        return [L, Math.hypot(A, B), (Math.atan2(B, A) * 180 / Math.PI + 360) % 360];
    }
    function apart(a, b) { return Math.abs((a - b + 540) % 360 - 180); }

    // The one of `list` whose hue is nearest the wallpaper's. Grays in the list have no
    // hue to compare and are passed over; with nothing to go on it answers `fallback`.
    function pick(list, fallback) {
        if (!valid) return fallback;
        let best = fallback, bestD = 1e9;
        for (const c of list) {
            const q = Qt.color(c), v = lch(q.r, q.g, q.b);
            if (v[1] < 0.03) continue;
            const d = apart(v[2], hue);
            if (d < bestD) { bestD = d; best = c; }
        }
        return best;
    }

    // "Most prominent" is not "most common": most wallpapers are mostly dark or mostly
    // gray, and that is not what the eye calls their color. Every pixel votes for its
    // hue with a weight of how colorful it is, in 36 bins around the wheel; near-black,
    // near-white and gray pixels sit it out. The winning stretch of the wheel is the
    // answer, and its pixels' average is the color itself. A picture with next to no
    // color in it has no answer.
    function read(text) {
        const re = /#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\b/g;
        const px = [], bins = new Array(36).fill(0);
        let m, total = 0, colorful = 0;
        while ((m = re.exec(text)) !== null) {
            const r = parseInt(m[1], 16) / 255, g = parseInt(m[2], 16) / 255, b = parseInt(m[3], 16) / 255;
            total++;
            const v = lch(r, g, b);
            if (v[1] < 0.04 || v[0] < 0.15 || v[0] > 0.96) continue;
            colorful++;
            bins[Math.floor(v[2] / 10) % 36] += v[1];
            px.push([r, g, b, v[1], v[2]]);
        }
        if (total === 0 || colorful < total * 0.04) { valid = false; return; }
        let top = 0, topW = -1;
        for (let i = 0; i < 36; i++) {
            const w = bins[i] + 0.5 * (bins[(i + 35) % 36] + bins[(i + 1) % 36]);
            if (w > topW) { topW = w; top = i; }
        }
        const mid = top * 10 + 5;
        let sx = 0, sy = 0, sr = 0, sg = 0, sb = 0, sw = 0;
        for (const p of px) {
            if (apart(p[4], mid) > 15) continue;
            sx += p[3] * Math.cos(p[4] * Math.PI / 180); sy += p[3] * Math.sin(p[4] * Math.PI / 180);
            sr += p[0] * p[3]; sg += p[1] * p[3]; sb += p[2] * p[3]; sw += p[3];
        }
        hue = (Math.atan2(sy, sx) * 180 / Math.PI + 360) % 360;
        prominent = Qt.rgba(sr / sw, sg / sw, sb / sw, 1);
        valid = true;
    }

    function refresh() { if (Config.wallpaper !== "") { sampler.running = false; sampler.running = true; } }
    Process {
        id: sampler
        // "[0]": the first frame, if the wallpaper is an animation
        command: ["magick", Config.wallpaper + "[0]", "-scale", "40x40!", "-depth", "8", "txt:-"]
        stdout: StdioCollector { onStreamFinished: root.read(text) }
    }
    // a wallpaper change during a theme switch arrives with a burst of other changes
    Timer { id: soon; interval: 150; onTriggered: root.refresh() }
    Connections { target: Config; function onWallpaperChanged() { soon.restart(); } }
    Component.onCompleted: refresh()
}

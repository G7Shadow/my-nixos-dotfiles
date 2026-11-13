.pragma library

// The island's outline, shared by the bar and the lock screen so both draw the very same
// shape. One SVG path covering BOTH forms: rounded-top island (fr = 0, tr > 0) through to
// the flared notch (fr > 0, tr = 0), with a rounded bottom either way. Local coords; the
// body sits at x in [fr, W-fr] and the flares stick out `fr` past each side at the top
// edge. Radii near zero degrade to straight lines (a zero-radius SVG arc is undefined).
function notchPath(bw, h, tr, br, fr) {
    var W = bw + 2 * fr;
    var L = fr, R = W - fr;
    var eps = 0.01;
    var p;
    // top-left: flare out, round in, or a hard corner
    if (fr > eps)      p = "M 0,0 A " + fr + "," + fr + " 0 0 1 " + L + "," + fr;
    else if (tr > eps) p = "M " + L + "," + tr;
    else               p = "M " + L + ",0";
    // left side down, across the bottom, back up the right
    if (br > eps) {
        p += " L " + L + "," + (h - br);
        p += " A " + br + "," + br + " 0 0 0 " + (L + br) + "," + h;
        p += " L " + (R - br) + "," + h;
        p += " A " + br + "," + br + " 0 0 0 " + R + "," + (h - br);
    } else {
        p += " L " + L + "," + h + " L " + R + "," + h;
    }
    // top-right, mirroring the top-left
    if (fr > eps) {
        p += " L " + R + "," + fr;
        p += " A " + fr + "," + fr + " 0 0 1 " + W + ",0";
    } else if (tr > eps) {
        p += " L " + R + "," + tr;
        p += " A " + tr + "," + tr + " 0 0 0 " + (R - tr) + ",0";
        p += " L " + (L + tr) + ",0";
        p += " A " + tr + "," + tr + " 0 0 0 " + L + "," + tr;
    } else {
        p += " L " + R + ",0";
    }
    return p + " Z";
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The launcher's calculator. The math is qalc's (libqalculate, the engine rofi-calc
// uses), so it does whatever that does: arithmetic, functions, units ("10 km to miles"),
// currencies ("5 usd to eur"), bases ("0x1f to bin"), equations ("x^2 = 16"). This just
// asks it as you type, keeps what it said, and remembers the ones you kept.
//
// One qalc at a time. It answers in about 60ms, so a keystroke that lands while one is
// running waits for it and then asks again with whatever is in the box by then. Killing
// the running one instead would let its half-written answer arrive under the new question.
Singleton {
    id: root

    property string input: ""
    // qalc's own reading of the input ("(12 × (4 + 3)) / 2"), the answer, and whether
    // the answer is rounded (qalc says "≈" where it would say "=")
    property string expr: ""
    property string result: ""
    property bool approx: false
    property string error: ""
    readonly property bool has: result !== ""

    // kept calculations, newest first: [{ e: expression, r: result, a: approx }]
    readonly property var history: store.entries
    readonly property int keep: 100

    function setInput(t) {
        input = t;
        if (t.trim() === "") { expr = ""; result = ""; error = ""; approx = false; ask.stop(); return; }
        ask.restart();
    }

    // `ans` is the newest kept result, the way it is in qalc's own prompt
    function withAns(t) {
        if (history.length === 0) return t;
        return t.replace(/\bans\b/gi, "(" + history[0].r + ")");
    }

    property bool again: false
    property string asked: ""
    function run() {
        if (qalc.running) { again = true; return; }
        again = false;
        asked = input;
        // qalc must never stop to ask something: nobody is there to answer, it would wait
        // forever, and every calculation after it would queue up behind it (that happened:
        // the first "+ 10%" made it ask how to read percentages). So: the percentage
        // question is answered up front (100 + 10% = 110), stdin is /dev/null so any other
        // question gets an immediate end-of-input, -m gives a calculation two seconds, and
        // the watchdog below puts down one that is still there after three.
        // Exchange rates are fetched at most once a week, on the calculation that needs them.
        qalc.command = ["sh", "-c", 'exec qalc -m 2000 -s "update_exchange_rates 7days" -s "simplified_percentage on" "$1" < /dev/null', "qalc", withAns(input)];
        dead = false;
        qalc.running = true;
        watchdog.restart();
    }
    // a killed qalc's half-written answer must not be read as an answer
    property bool dead: false
    Timer { id: watchdog; interval: 3000; onTriggered: if (qalc.running) { root.dead = true; root.again = root.input.trim() !== "" && root.input !== root.asked; qalc.running = false; } }
    Timer { id: ask; interval: 50; onTriggered: root.run() }

    // qalc prints warnings and errors on lines of their own, then "expression = result"
    // (or "≈"). An equation takes two lines: the equation as read, then its solutions.
    function read(text) {
        if (dead || asked.trim() === "" || input.trim() === "") return;
        const lines = text.split("\n").map(l => l.trim()).filter(l => l !== "");
        const errs = lines.filter(l => l.indexOf("error:") === 0);
        const body = lines.filter(l => !/^(warning|error):/.test(l));
        error = errs.length > 0 ? errs[errs.length - 1].slice(6).trim() : "";
        if (body.length === 0) { result = ""; expr = ""; return; }
        if (body.length > 1) {
            expr = body[0]; result = body[body.length - 1]; approx = false;
            return;
        }
        const m = body[0].match(/^(.*?) (=|≈) (.*)$/);
        if (!m) { expr = ""; result = body[0]; approx = false; return; }
        expr = m[1]; approx = m[2] === "≈"; result = m[3];
    }

    Process {
        id: qalc
        stdout: StdioCollector { onStreamFinished: root.read(text) }
        onExited: { watchdog.stop(); if (root.again) root.run(); }
    }

    // Keep what is on screen. Returns the result (to copy), or "" if there is nothing.
    // The same calculation kept twice moves to the top instead of sitting there twice.
    function commit() {
        if (!has) return "";
        const e = expr !== "" ? expr : input.trim();
        const next = [{ e: e, r: result, a: approx }].concat(history.filter(h => !(h.e === e && h.r === result)));
        store.entries = next.slice(0, keep);
        return result;
    }
    function remove(i) {
        if (i < 0 || i >= history.length) return;
        const next = history.slice();
        next.splice(i, 1);
        store.entries = next;
    }
    function clearHistory() { store.entries = []; }

    FileView {
        path: Quickshell.statePath("calc-history.json")
        printErrors: false      // no file yet on the very first run: that is not an error
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: store
            property var entries: []
        }
    }
}

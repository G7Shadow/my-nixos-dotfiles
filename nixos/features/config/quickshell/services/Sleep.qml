pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// Going to sleep and waking up, as a pair of eyes. logind says sleep is coming, every
// screen fades to black, and only then do we let the machine go. Nothing locks: it wakes
// up to whatever was on screen. On the way back the screens stay black until we say so, then fade up.
//
// It hangs off logind's PrepareForSleep signal instead of the power menu's button, so the
// idle timeout, the lid and a plain `systemctl suspend` all get the same goodbye. A delay
// inhibitor is what buys the time: logind waits for us to drop it (5s at most, we take
// about half a second).
//
// `closed` is the whole look: 0 is eyes open, 1 is shut. Eyelids.qml paints it over the
// desktop, Lock.qml paints it over the lock screen (for sleeping while already locked).
Singleton {
    id: root

    property real closed: 0

    // logind has announced sleep and we are still holding it back
    property bool going: false
    readonly property int closeMs: 420
    readonly property int openMs: 900

    function close() { openAnim.stop(); closeAnim.restart(); }
    function open() { closeAnim.stop(); openAnim.restart(); }

    NumberAnimation {
        id: closeAnim
        target: root; property: "closed"; to: 1
        duration: Theme.dur(root.closeMs); easing.type: Easing.InOutSine
        onFinished: if (root.going) root.settle()
    }
    // Slower than the way down, but it starts moving on the very first frame and eases
    // into the end: a black screen with its backlight on reads as broken, so there is
    // never a held black on the way up.
    NumberAnimation {
        id: openAnim
        target: root; property: "closed"; to: 0
        duration: Theme.dur(root.openMs); easing.type: Easing.OutCubic
    }

    // The screens are black. Put the laptop's backlight out too, give the black frame a
    // moment to reach the glass and let go.
    function settle() {
        lightsOut();
        letGo.restart();
    }

    // The NVIDIA driver makes the kernel switch to an empty text console for the couple of
    // seconds it takes to put the card away, and the console lights the panel back up. A
    // backlight at zero stays at zero through that, so the laptop screen is properly dark
    // from the end of the fade on. The old value is parked in a file, not in here, so a
    // shell that dies in the dark still finds it and puts it back when it next starts.
    // `dark` covers the whole stretch, plus a beat for the restore to land: the Brightness
    // service ignores what it polls meanwhile, or it would announce the trip to zero.
    property bool dark: false
    readonly property string parked: "${XDG_RUNTIME_DIR:-/tmp}/quickshell-backlight"
    function lightsOut() {
        dark = true;
        undark.stop();
        Quickshell.execDetached(["sh", "-c", `f="${parked}"; [ -e "$f" ] || cat /sys/class/backlight/*/brightness | head -n1 > "$f"; brightnessctl -q set 0`]);
    }
    function lightsOn() {
        // climbs back over about a quarter of a second, alongside the fade, instead of
        // snapping to full behind a screen that is still black
        Quickshell.execDetached(["sh", "-c", `f="${parked}"; [ -s "$f" ] || exit 0; v=$(cat "$f"); rm -f "$f"; `
            + `for i in 1 2 3 4 5 6 7; do brightnessctl -q set $((v * i * i / 64)); sleep 0.03; done; brightnessctl -q set "$v"`]);
        undark.restart();
    }
    Timer { id: undark; interval: 2500; onTriggered: root.dark = false }
    Component.onCompleted: lightsOn()

    function sleeping() {
        going = true;
        deadline.restart();
        close();
    }

    function woke() {
        going = false;
        deadline.stop();
        letGo.stop();
        stuck.stop();
        inhibitor.running = true;
        lightsOn();
        open();
    }

    Timer {
        id: letGo
        interval: 150
        onTriggered: {
            root.going = false;
            deadline.stop();
            inhibitor.running = false;
            stuck.restart();
        }
    }
    // never hold sleep back for long, whatever happened to the animation
    Timer { id: deadline; interval: 2500; onTriggered: if (root.going) root.settle() }
    // Timers stand still while the machine sleeps, so this only counts time awake. If we
    // let go and are still awake and still black this much later, the wake signal got
    // lost or the sleep never happened: open up rather than sit there in the dark.
    Timer { id: stuck; interval: 8000; onTriggered: { inhibitor.running = true; root.lightsOn(); root.open(); } }

    // The delay lock. Killing systemd-inhibit drops it (and takes its child with it). The
    // child is a `cat` on our stdin pipe, so if the shell dies without cleaning up the
    // pipe closes, cat ends and the lock goes with it: an orphaned one would make every
    // suspend wait out logind's full 5s.
    Process {
        id: inhibitor
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=Quickshell",
                  "--why=Fade the screens out before sleep", "cat"]
        stdinEnabled: true
        running: true
    }

    // /org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep (true,)
    Process {
        id: watcher
        // same stdin trick as the inhibitor, so a dead shell leaves no gdbus behind
        command: ["sh", "-c", "gdbus monitor --system --dest org.freedesktop.login1 "
                  + "--object-path /org/freedesktop/login1 & g=$!; trap 'kill $g' TERM; "
                  + "cat >/dev/null; kill $g"]
        stdinEnabled: true
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("Manager.PrepareForSleep") < 0)
                    return;
                if (line.indexOf("(true") >= 0) root.sleeping();
                else root.woke();
            }
        }
        onExited: rewatch.restart()
    }
    Timer { id: rewatch; interval: 2000; onTriggered: watcher.running = true }
}

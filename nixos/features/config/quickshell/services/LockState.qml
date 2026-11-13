pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam
import "../theme"
import "../config"

// Lock state + PAM auth, kept in a singleton 'cause the per-screen
// WlSessionLockSurface is its own isolated scope and can't see ids, only this.
// Locking is instant: lock() flips `locked` and nothing else.
// `locked` is cleared in exactly ONE place (unlockTimer), and that timer is armed
// from exactly ONE place (PamResult.Success). Every failure or error stays locked,
// no exceptions (fail closed). Password's never stored, logged, or echoed. Ever.
Singleton {
    id: root

    property bool locked: false
    property string errorMsg: ""
    property bool authenticating: false
    readonly property bool prompting: pam.responseRequired
    readonly property string message: pam.message

    // true for the brief window between a successful auth and the surface actually
    // tearing down, so LockContent can play its exit animation before we drop the lock.
    // Auth already succeeded here; this only defers the teardown, it never gates it.
    property bool unlocking: false

    // The lock screen draws its own island on the exact spot of the bar's, so the two
    // have to agree. `rest` is each bar's resting pill (screen name -> { w, h }), written
    // by the bar; `covered` is the screens whose lock surface has put its first frame up,
    // written by LockContent, and the bar hides its own island on those so there is only
    // ever one. Both are plain look-and-feel: nothing here gates the lock.
    property var rest: ({})
    property var covered: ({})
    function setRest(name, g) { if (!name) return; var r = Object.assign({}, rest); r[name] = g; rest = r; }
    function setCovered(name, on) {
        if (!name || !!covered[name] === on) return;
        var c = Object.assign({}, covered); c[name] = on; covered = c;
    }

    // Lock NOW. One assignment flips the WlSessionLock; nothing runs before it (no
    // screenshot, no timer, no animation): the key press and the locked screen are the
    // same instant. The lock screen draws the wallpaper, which is already on disk.
    // `pill` names the screen whose island is the POWER MENU right now, and `from` its
    // size: the lock screen on that screen starts as that very menu and shrinks it to the
    // padlock pill itself, instead of starting from the bar's clock. The lock is still
    // instant: the morph plays on the lock surface, after the session is locked, never
    // before it. Empty for every other way of locking.
    property string pillScreen: ""
    property var pillFrom: null         // { w, h }: the power menu's island at the moment of the press
    // What that island was. "" = the power menu (the lock screen draws a copy of the menu
    // in it while it shrinks). "island" = the open island, locked from a shortcut while
    // the pointer was on it or it was pinned. "panel" = a panel (launcher, control
    // center, a switcher, the calendar) was open: `pillFrom` is its island and
    // `pillShot` a picture of the whole of it. The bar fills these in itself on
    // `aboutToLock`, which is sent before `locked` flips so the bar still knows it is
    // open (the lock takes the hover away). For the open island `pillFrom` also says
    // where the big time is (tx, ty: its middle on the screen, ts: its scale) and where
    // the island's contents sit in it (gx, gy, gw, gh), and `pillShot` is a picture of
    // those contents, taken by the bar right after the lock: the lock screen starts as
    // the open island, sends its time to the middle and closes around the padlock.
    property string pillKind: ""
    property var pillShot: null
    signal aboutToLock()
    function lock(pill, from) {
        if (locked)
            return;
        pillKind = "";
        pillShot = null;
        pillScreen = pill || "";
        pillFrom = (pill && from) ? from : null;
        errorMsg = "";
        authenticating = false;
        unlocking = false;
        covered = ({});
        aboutToLock();
        locked = true;
        pam.start();
    }

    function submit(pw) {
        if (!pam.responseRequired || authenticating || pw.length === 0)
            return;
        errorMsg = "";
        authenticating = true;
        pam.respond(pw);
    }

    PamContext {
        id: pam
        // config is "su", NOT "login". Read this before you "fix" it: on this box
        // "login" (pam_unix with try_first_pass nullok + faillock) straight up ACCEPTED
        // a wrong password through Quickshell's conversation. As in it failed OPEN. Yeah.
        // "su" (plain pam_unix) rejects it like it should. Do NOT switch it back, and
        // re-test a wrong password after touching anything PAM. I'm serious.
        config: "su"

        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                // Don't drop the surface yet: flip `unlocking` so LockContent can play its
                // exit animation, then unlockTimer clears `locked` once it's done. This is
                // the ONLY path that arms unlockTimer, so it stays fail-closed.
                root.unlocking = true;
                unlockTimer.restart();
            } else {
                root.errorMsg = result === PamResult.MaxTries ? "Too many attempts"
                              : result === PamResult.Error ? "Authentication error"
                              : "Incorrect password";
                pam.start(); // fresh prompt, still locked
            }
        }
        onError: root.errorMsg = "Authentication error"
    }

    // Fires after the exit animation. The one and only place `locked` gets cleared, and
    // it's only ever armed by PamResult.Success above. Length matches LockContent's exit:
    // the padlock's beat (110ms), the time flying home (the ground starts lifting once it
    // is nearly in, measured ~300ms after the unlock at the default spring), then the
    // ground's own fade, a full dExpand: ~1.6x dExpand in all. The rest is air, because Qt
    // stretches animations when frames run slow and a short timer would cut the ground
    // off mid-fade.
    Timer {
        id: unlockTimer
        interval: Theme.reducedMotion ? 0 : Math.round(Theme.dExpand * 2)
        repeat: false
        onTriggered: {
            root.locked = false;
            root.unlocking = false;
            root.covered = ({});
            root.pillScreen = "";
            root.pillKind = "";
            root.pillFrom = null;
            root.pillShot = null;
        }
    }
}

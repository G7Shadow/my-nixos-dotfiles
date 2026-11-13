pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../config"

// Notification server. Everything that lands gets kept (tracked) as history; a
// separate `poppedIds` set is just which ones are up right now as transient popups.
// Hiding a popup (timeout or close) does NOT drop it from history, only dismiss()
// does that. The popup stack renders `popups`, the control center renders `list`.
Singleton {
    id: root

    function asArray(m) { return !m ? [] : (m.values !== undefined ? m.values : m); }

    // Whole history, newest first.
    readonly property var list: asArray(server.trackedNotifications).slice().reverse()

    // Ids that are up as popups right now.
    property var poppedIds: []
    readonly property var popups: GlobalState.dnd ? [] : list.filter(n => poppedIds.indexOf(n.id) >= 0)

    // Whichever popup's up in the island right now (newest first). Auto-dismisses
    // after a beat (longer for Critical), and the countdown pauses while yer hovering
    // the island, so it don't vanish mid-read.
    readonly property var showing: popups.length > 0 ? popups[0] : null
    property bool popupHovered: false
    onShowingChanged: { if (showing && !popupHovered) dismissTimer.restart(); else if (!showing) dismissTimer.stop(); }
    onPopupHoveredChanged: { if (popupHovered) dismissTimer.stop(); else if (showing) dismissTimer.restart(); }
    Timer {
        id: dismissTimer
        interval: (root.showing && root.showing.urgency === NotificationUrgency.Critical) ? Config.notifTimeoutCritical : Config.notifTimeout
        onTriggered: if (root.showing) root.hidePopup(root.showing)
    }

    // Hide the transient popup but leave the notification sitting in history.
    function hidePopup(notif) {
        if (notif)
            poppedIds = poppedIds.filter(id => id !== notif.id);
    }

    // Yank it clean out of history.
    function dismiss(notif) {
        if (notif)
            notif.dismiss();
    }

    function clearAll() {
        for (const n of asArray(server.trackedNotifications).slice())
            n.dismiss();
        poppedIds = [];
    }

    // A notification body may carry markup (we tell apps so: bodyMarkupSupported), and it
    // was being drawn as plain text, tags and all. This turns a body into what a
    // Text.StyledText can draw safely on one line:
    //   <b> <i> <u> are kept, and entities (&amp; and friends) are left for the text item;
    //   line breaks and <br> become a space;
    //   <img> is dropped outright (a StyledText would go and fetch its source);
    //   every other tag (<a href>, <span>, ...) is removed, its text kept;
    //   any "<" left over is not a tag ("2 < 3"), so it is escaped and shows as itself.
    // ── what the control center's card needs beyond the list itself ──
    // `arrived`  when each notification came in (id -> ms): the server does not say;
    // `seenAt`   the last time the control center was closed. Anything that arrived
    //            after it is unread: it has a dot the first time you see it in the card
    //            and has lost it the next time you open the card;
    // `quietSince` when the list last became empty, for the empty card's line;
    // `groups`   the list folded by app, newest app first, newest message first in each:
    //            one chatty app is one block in the card, not ten rows.
    property var arrived: ({})
    property real seenAt: Date.now()
    function markSeen() { seenAt = Date.now(); }
    function isUnread(n) { return (arrived[n.id] || 0) > seenAt; }
    property real quietSince: Date.now()
    readonly property int count: list.length
    onCountChanged: if (count === 0) quietSince = Date.now()
    readonly property var groups: {
        const out = [], by = {};
        for (const n of list) {
            const k = n.appName || "Notification";
            if (!by[k]) { by[k] = { app: k, items: [], crit: false }; out.push(by[k]); }
            by[k].items.push(n);
            if (n.urgency === NotificationUrgency.Critical) by[k].crit = true;
        }
        return out;
    }
    // "now", "2m", "3h", "4d"
    function ago(ms, now) {
        if (!ms) return "";
        const s = Math.max(0, (now - ms) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    function markup(body) {
        if (!body) return "";
        return String(body)
            .replace(/\r?\n/g, " ")
            .replace(/<br\s*\/?>/gi, " ")
            .replace(/<img\b[^<>]*>/gi, "")
            .replace(/<(\/?)(b|i|u)\s*>/gi, "\u0001$1$2\u0002")
            .replace(/<\/?[a-zA-Z][^<>]*>/g, "")
            .replace(/</g, "&lt;")
            .replace(/\u0001/g, "<").replace(/\u0002/g, ">");
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            root.poppedIds = root.poppedIds.concat([notif.id]);
            const a = Object.assign({}, root.arrived);
            a[notif.id] = Date.now();
            root.arrived = a;
        }
    }
}

import QtQuick
import QtQuick.Effects
import Quickshell
import "../../theme"
import "../../config"
import "../../services"
import "../../components"

// The launcher's guts: a search bar (top) plus results (below). This is NOT a
// window; it lives INSIDE the bar's island, which morphs to host it (see Bar.qml).
// The island grows around this; we just hand over the content and its natural
// implicitHeight (so the island knows how tall to get).
Item {
    id: root

    property bool active: false               // true while the island's wearing its launcher form
    implicitHeight: column.implicitHeight      // this is what tells the island how tall to be
    clip: true

    readonly property int rowH: Config.launcherRowHeight
    readonly property int listCap: rowH * Config.launcherMaxRows

    readonly property string queryBody: field.text
    // What the list is showing. Apps by default. A query that starts with ">" lists the
    // shell's own actions instead, and an action can take the launcher over as a MODE:
    // the calculator turns the field into its input and the list into its history.
    property string mode: "apps"
    readonly property bool calc: mode === "calc"
    readonly property bool clipMode: mode === "clip"
    readonly property bool wantsActions: mode === "apps" && queryBody.charAt(0) === ">"
    readonly property var items: !active ? [] : calc ? calcItems() : clipMode ? clipItems() : wantsActions ? actionItems() : appItems()
    // In the calculator -1 is the line being typed (the live result); 0 and up are rows.
    property int index: 0
    readonly property int topIndex: calc ? -1 : 0

    // ── actions (">") ──
    // glyph: an Icon name for the badge. stay: running it does not close the launcher.
    readonly property var actions: [
        { glyph: "calculator", title: "Calculator", subtitle: "Math, units, currencies", stay: true, run: () => root.enterCalc() },
        { glyph: "clipboard", title: "Clipboard", subtitle: "Copied items", stay: true, run: () => root.enterClip() }
    ]
    function actionItems() {
        const q = queryBody.slice(1).trim().toLowerCase();
        return actions.filter(a => q === "" || a.title.toLowerCase().indexOf(q) >= 0);
    }

    // ── calculator ──
    // Enter keeps the calculation (it goes to the top of the history) and copies its
    // result. Down goes into the history: Enter there copies that row's result, Delete
    // forgets the row. Tab puts a result (the live one, or the row's) into the field
    // to carry on from. Backspace in an empty field leaves the calculator.
    function calcItems() {
        return Calc.history.map(h => ({ plain: true, title: h.r, subtitle: h.e + (h.a ? " ≈" : " =") }));
    }
    function enterCalc() { mode = "calc"; field.text = ""; index = -1; }
    // how long the selection takes to fade between the live answer and the first
    // history row, in ms (both tints use it, so they stay in step)
    readonly property int selFade: 100
    // Delete on a history row. The selection stays where it is, so the row that was
    // below moves up under it; deleting the last row puts it on the new last row; only
    // when there are no rows left does it go back to the live answer. (Any change to the
    // list used to send it back to the answer, so the highlight slid up and faded out.)
    property int stayAt: -2          // where the selection should land after the next list change
    function forget() {
        if (index < 0 || !items[index]) return;
        stayAt = index;
        if (clipMode) Clipboard.remove(items[index].id);
        else Calc.remove(index);
    }

    // ── clipboard ──
    // The field filters what was copied (newest first, cliphist's list). Enter puts the
    // row back on the clipboard and closes; Delete forgets it; Backspace in an empty
    // field leaves. A text row is the text on one line. A picture is "Image" with its
    // kind and size under it; typing "image" finds the pictures.
    function clipItems() {
        const q = queryBody.trim().toLowerCase();
        const out = [];
        for (const e of Clipboard.entries) {
            if (q !== "" && e.t.toLowerCase().indexOf(q) < 0) continue;
            out.push({ plain: true, picture: e.image, key: e.id, id: e.id, title: e.image ? "Image" : e.t, subtitle: e.info });
            // cliphist keeps hundreds; the list shows the newest that match and the
            // field narrows it from there
            if (out.length >= clipShown) break;
        }
        return out;
    }
    readonly property int clipShown: 100
    // a picture's thumbnail in its row: 16:9, as tall as an app's badge
    readonly property int picW: 64
    readonly property int picH: 36
    function enterClip() { Clipboard.refresh(); mode = "clip"; field.text = ""; index = 0; }
    function leaveMode() { mode = "apps"; field.text = ">"; }
    property bool copied: false
    Timer { id: copiedOff; interval: 1100; onTriggered: root.copied = false }
    function copy(t) {
        if (t === "") return;
        Quickshell.clipboardText = t;
        copied = true;
        copiedOff.restart();
    }
    function useResult() {
        const t = index < 0 ? Calc.result : (items[index] ? items[index].title : "");
        if (t === "") return;
        field.text = t;
        index = -1;
    }

    function appItems() {
        // Icon NAME only; we resolve the real path per visible row. Resolving every
        // app's path up front is what made the first open feel sluggish.
        return Apps.query(queryBody).map(e => ({
            iconName: e.icon,
            title: e.name,
            subtitle: e.genericName || e.comment || "",
            run: () => e.execute()
        }));
    }

    function close() { GlobalState.launcherOpen = false; }
    function activate() {
        if (calc) {
            if (index < 0) { const r = Calc.commit(); if (r !== "") { copy(r); field.text = ""; } }
            else if (items[index]) copy(items[index].title);
            return;
        }
        if (clipMode) {
            if (items[index]) { Clipboard.copy(items[index].id); close(); }
            return;
        }
        const it = items[index];
        if (!it) return;
        it.run();
        if (!it.stay) close();
    }

    // the ListView re-targets its own currentIndex while the model is diffed (it follows the
    // ITEM, not the slot, and goes -1 when that item is removed), which severs a binding to
    // root.index. So the index is pushed imperatively: after every sync and on every change.
    // (The ListView is never told -1. With no current item it takes its highlight item
    // away on the spot, which is what made the selection blink in and out when stepping
    // between the calculator's live answer and its first history row. It keeps row 0 as
    // current, and the highlight fades itself by root.index.)
    onItemsChanged: {
        const want = stayAt;
        stayAt = -2;
        index = want > -2 ? Math.min(want, items.length - 1) : topIndex;
        syncResults();
        list.currentIndex = Math.max(0, index);
        if (index >= 0) list.positionViewAtIndex(index, ListView.Contain);
    }
    onIndexChanged: list.currentIndex = Math.max(0, index)

    // Back the list with a ListModel kept in sync by a key-diff (insert / remove / move) so the
    // ListView's add/remove/displaced transitions animate the rows reflowing as you filter.
    // Just reassigning a JS-array model resets the whole view and skips the animation.
    ListModel { id: resultModel }
    // a row can bring its own key (two clipboard entries may start with the same words)
    function itKey(it) { return it.key ?? ((it.title ?? "") + "" + (it.subtitle ?? "")); }
    function syncResults() {
        const items = root.items;
        const lm = resultModel;
        for (let i = lm.count - 1; i >= 0; i--) {
            const k = lm.get(i).key;
            if (!items.some(it => root.itKey(it) === k)) lm.remove(i);
        }
        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            const k = root.itKey(it);
            let cur = -1;
            for (let j = i; j < lm.count; j++) { if (lm.get(j).key === k) { cur = j; break; } }
            if (cur === -1) lm.insert(i, { key: k, iconName: it.iconName ?? "", glyph: it.glyph ?? "", plain: it.plain === true, picture: it.picture === true, title: it.title ?? "", subtitle: it.subtitle ?? "" });
            else if (cur !== i) lm.move(cur, i, 1);
        }
    }
    onActiveChanged: {
        if (active) {
            mode = "apps";
            copied = false;
            field.text = "";
            index = 0;
            Qt.callLater(() => field.forceActiveFocus());
        }
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Theme.s3

        // search bar (TOP), the morphed island itself: magnifier + input
        Item {
            id: searchBar
            width: parent.width
            height: Theme.s6 + Theme.s1

            Icon {
                id: glass
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                name: root.calc ? "calculator" : root.clipMode ? "clipboard" : "search"
                color: Theme.inkDim
            }

            TextInput {
                id: field
                cursorDelegate: Caret { tint: Theme.hue("launcher") }
                anchors.left: glass.right
                anchors.leftMargin: Theme.s3
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: Theme.inkPrimary
                selectionColor: Theme.alpha(Theme.hue("launcher"), 0.4)
                font.family: Theme.fontBody
                font.pixelSize: Theme.fsBody

                // typing is always about the live answer: if the selection was down in the
                // history it comes back up to the result
                onTextChanged: if (root.calc) { root.index = -1; Calc.setInput(text); }
                onAccepted: root.activate()
                Keys.onUpPressed: root.index = Math.max(root.topIndex, root.index - 1)
                Keys.onDownPressed: root.index = Math.min(root.items.length - 1, root.index + 1)
                Keys.onEscapePressed: root.close()
                Keys.onPressed: event => {
                    if (!root.calc && !root.clipMode) return;
                    if (root.calc && event.key === Qt.Key_Tab) { root.useResult(); event.accepted = true; }
                    else if (event.key === Qt.Key_Backspace && field.text === "") { root.leaveMode(); event.accepted = true; }
                    else if (event.key === Qt.Key_Delete && root.index >= 0) { root.forget(); event.accepted = true; }
                }

                StyledText {
                    capCenterIn: parent
                    visible: field.text.length === 0
                    variant: "body"
                    color: Theme.inkFaint
                    text: root.calc ? "Calculate…" : root.clipMode ? "Search what you copied…" : "Search…"
                }
            }

        }

        // results group (BELOW), staggers in just after the bar forms
        Column {
            id: resultsGroup
            width: parent.width
            spacing: Theme.s3

            opacity: root.active ? 1 : 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: Theme.dur(Theme.stagger) }
                    NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.hairline
            }

            // The calculator's answer: how qalc read what was typed, small, and the result
            // under it, big. It is the top "row" of the calculator (index -1), so it wears
            // the selection tint while it is the thing Enter would act on.
            Item {
                id: answer
                width: parent.width
                // Tall enough for the big result only while there is one. With nothing typed
                // (or only an error to show) it is one line, the hint, so there is no empty
                // band sitting under it.
                readonly property int fullH: 76
                readonly property int hintH: 20
                height: !root.calc ? 0 : Calc.has ? fullH : hintH
                visible: root.calc
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rSm
                    color: Theme.glassHigh
                    opacity: (root.index < 0 && Calc.has) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(root.selFade) } }
                }
                StyledText {
                    id: answerExpr
                    x: Theme.s3
                    // on top of the result when there is one, in the middle of the short
                    // block when it stands alone
                    y: Calc.has ? 12 : Math.round((answer.hintH - height) / 2)
                    width: parent.width - 2 * Theme.s3 - copiedTag.width - Theme.s2
                    variant: "caption"
                    color: Calc.error !== "" && !Calc.has ? Theme.bad : Theme.inkDim
                    elide: Text.ElideRight
                    text: Calc.has ? Calc.expr + (Calc.approx ? " ≈" : " =")
                        : Calc.error !== "" ? Calc.error
                        : "Try: 12 * 7      10 km to miles      20 usd to eur"
                }
                Text {
                    x: Theme.s3
                    y: 30
                    width: parent.width - 2 * Theme.s3
                    height: 36
                    verticalAlignment: Text.AlignVCenter
                    text: Calc.result
                    color: Theme.inkPrimary
                    font.family: Theme.fontDisplay
                    font.weight: Theme.wSemiBold
                    font.pixelSize: 28
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 14
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }
                // the one piece of feedback for Enter: the result went to the clipboard
                StyledText {
                    id: copiedTag
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.s3
                    // on the small line's own line, wherever that is: it moves to the
                    // middle of the short block once Enter has cleared the field, which
                    // is exactly when this shows
                    y: answerExpr.y
                    variant: "caption"
                    color: Theme.accent
                    text: "Copied"
                    opacity: root.copied ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dFast) } }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.hairline
                visible: root.calc && root.items.length > 0
            }

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, root.listCap)
                visible: root.items.length > 0
                clip: true
                model: resultModel
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                // keep the current row in view. Safe for the glide only because the
                // highlight is positioned by hand below: with ListView's own tracking this
                // call snaps the highlight item onto the row.
                onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

                // the selection is ONE item that glides between rows on the spring (keys and
                // hover alike), drawn over the opaque rows: the tint plus the accent marker.
                // Positioned by hand from the index (rows are fixed height): ListView's own
                // tracking targets the current item's PRE-move position during a `move`
                // transition and never re-aims, so the highlight got stranded off-list.
                highlightFollowsCurrentItem: false
                highlight: Rectangle {
                    z: 2
                    // Leaving for the live answer (index -1, the calculator only) it fades
                    // where it is, on the same clock as the answer block's own tint fades
                    // in, so the selection hands over between the two; it used to blink.
                    opacity: root.index >= 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(root.selFade) } }
                    visible: opacity > 0
                    width: list.width
                    height: root.rowH
                    // content coords, not viewport: ListView shifts originY as rows above
                    // the first visible one are removed, so index*rowH alone drifts off-list
                    y: list.originY + Math.max(0, root.index) * root.rowH
                    Behavior on y { NumberAnimation { duration: Theme.dur(Theme.dBase); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                    radius: Theme.rSm
                    color: Theme.glassHigh
                    Rectangle {
                        width: 3
                        height: parent.height * 0.5
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        color: Theme.hue("launcher")
                    }
                }

                // filter animations: new rows fade in, dead rows fade out, the rest glide
                // (no `add` transition: a new row fades itself in, see the delegate's `entered`.
                // The view cancels an add transition when the row is moved again before it
                // ends, and leaves the row at whatever opacity it had reached. Reopening the
                // clipboard after copying something did exactly that, the list arrives and
                // then shifts down a row for the new entry, and every older row stayed
                // invisible: blank rows in an island still sized for them.)
                remove: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                displaced: Transition { NumberAnimation { properties: "x,y"; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }
                move: Transition { NumberAnimation { properties: "x,y"; duration: Theme.dur(Theme.dSpring); easing.type: Easing.Bezier; easing.bezierCurve: Theme.springBezier } }

                delegate: ListRow {
                    id: row
                    required property string key
                    required property string iconName
                    required property string glyph      // an Icon name, for rows that are not apps
                    required property bool plain        // no badge at all (the calculator's history)
                    required property bool picture      // a copied image: it shows the image itself
                    required property string title
                    required property string subtitle
                    required property int index

                    property real entered: 0
                    opacity: entered
                    Component.onCompleted: enterAnim.start()
                    NumberAnimation { id: enterAnim; target: row; property: "entered"; to: 1; duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier }

                    width: ListView.view.width
                    implicitHeight: root.rowH
                    baseColor: Theme.base     // opaque BLACK (matches the island), not the wallpaper-tinted bg, so reflowing rows cover each other (no text bleed during the filter anims)
                    selected: false   // the gliding highlight item draws the selection
                    onClicked: { root.index = index; root.activate(); }
                    onEntered: root.index = index

                    readonly property string iconSrc: row.iconName !== ""
                        ? Quickshell.iconPath(row.iconName, "application-x-executable")
                        : ""

                    // icon badge: rounded square in a flat tint
                    Rectangle {
                        id: badge
                        visible: !row.plain
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: Theme.rSm
                        color: Theme.fillLow

                        Image {
                            id: ic
                            anchors.centerIn: parent
                            source: row.iconSrc
                            visible: source != ""
                            width: 24
                            height: 24
                            sourceSize.width: 24
                            sourceSize.height: 24
                            asynchronous: true
                            cache: true
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: !ic.visible
                            name: row.glyph !== "" ? row.glyph : "apps"
                            color: Theme.hue("launcher")
                        }
                    }

                    // A copied picture, small, where an app's badge would be. The file is
                    // cliphist's entry decoded into the cache (Clipboard.ready), read at
                    // twice the size it is drawn so it stays sharp on a scaled screen. It is
                    // cropped to the box and rounded like the badge; until the file is
                    // there the box is a quiet surface.
                    Item {
                        id: pic
                        visible: row.picture
                        readonly property string file: row.picture ? (Clipboard.ready[row.key] ?? "") : ""
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.picW
                        height: root.picH
                        Image {
                            id: picImg
                            readonly property bool ready: status === Image.Ready && source.toString() !== ""
                            anchors.fill: parent
                            source: pic.file !== "" ? "file://" + pic.file : ""
                            sourceSize.width: root.picW * 2
                            sourceSize.height: root.picH * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: false
                            layer.enabled: true
                        }
                        Rectangle { id: picMask; anchors.fill: parent; radius: Theme.rSm; visible: false; layer.enabled: true }
                        Rectangle { anchors.fill: parent; radius: Theme.rSm; color: Theme.fillLow; visible: !picImg.ready }
                        MultiEffect {
                            anchors.fill: parent
                            source: picImg
                            maskSource: picMask
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            opacity: picImg.ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.dEffects); easing.type: Easing.Bezier; easing.bezierCurve: Theme.effectsBezier } }
                        }
                    }

                    Column {
                        // by x, not by anchoring to the badge: a plain row has no badge, and
                        // an anchor cannot be switched while the row lives
                        x: row.picture ? root.picW + Theme.s3 : row.plain ? 0 : badge.width + Theme.s3
                        width: parent.width - x
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        StyledText {
                            width: parent.width
                            variant: "body"
                            font.weight: Theme.wMedium
                            text: row.title
                            color: Theme.inkPrimary
                            elide: Text.ElideRight
                        }
                        StyledText {
                            width: parent.width
                            variant: "caption"
                            visible: row.subtitle !== ""
                            text: row.subtitle
                            color: Theme.inkDim
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // empty state. Only while active: items empties the instant the launcher is
            // dismissed, and this was flashing "No results" over the fade-out.
            StyledText {
                width: parent.width
                visible: root.active && !root.calc && root.items.length === 0
                horizontalAlignment: Text.AlignHCenter
                topPadding: Theme.s2
                bottomPadding: Theme.s2
                variant: "body"
                color: Theme.inkFaint
                text: !root.clipMode ? "No results" : Clipboard.entries.length === 0 ? "Nothing copied yet" : "Nothing matches"
            }
        }
    }
}

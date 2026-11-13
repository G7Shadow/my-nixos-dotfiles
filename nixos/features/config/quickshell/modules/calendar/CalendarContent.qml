import QtQuick
import Quickshell
import "../../theme"
import "../../config"
import "../../components"

// Calendar shown INSIDE the bar island: it morphs into this when you press the
// clock (see Bar.qml). Flat, compact month grid: today is the one accent mark, the
// other months dimmed. ◀ / ▶ page through months (identical buttons); tapping the
// title (or the arrow keys) jumps back to today. Esc and click-outside dismiss (the
// bar handles that).
Item {
    id: root

    property bool active: false
    implicitHeight: col.implicitHeight
    clip: true

    SystemClock { id: sysclock; precision: SystemClock.Minutes }
    readonly property date today: sysclock.date

    // which month we're showing, as an offset from today's month (0 = this month)
    property int monthOffset: 0
    onActiveChanged: {
        if (active) Qt.callLater(() => keyCatcher.forceActiveFocus());
        else monthOffset = 0;   // always pop back open on the current month
    }

    readonly property date shown: new Date(root.today.getFullYear(), root.today.getMonth() + root.monthOffset, 1)
    readonly property int shownYear: root.shown.getFullYear()
    readonly property int shownMonth: root.shown.getMonth()    // 0-11
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                       "July", "August", "September", "October", "November", "December"]

    function close() { GlobalState.calendarOpen = false; }

    // The three calendar settings (Settings > Clock & Date). They had stopped reaching
    // this file: weeks always began on Sunday, the day rows were a fixed 32px whatever the
    // slider said (it moved the header instead), and the neighboring months were always
    // drawn.
    readonly property int firstDay: Math.max(0, Math.min(6, Config.weekStartsOn))   // 0 = Sunday
    readonly property int cellH: Config.calendarCellHeight
    readonly property bool showAdjacent: Config.calendarShowAdjacent
    readonly property var dayLetters: ["S", "M", "T", "W", "T", "F", "S"]

    // 42 cells (6 weeks, starting on `firstDay`): { day, inMonth, today }
    readonly property var cells: {
        const y = root.shownYear, m = root.shownMonth;
        // how many cells of the first row belong to the month before
        const startDow = (new Date(y, m, 1).getDay() - root.firstDay + 7) % 7;
        const daysInMonth = new Date(y, m + 1, 0).getDate();
        const daysInPrev = new Date(y, m, 0).getDate();
        const t = root.today;
        const curMonth = (t.getFullYear() === y && t.getMonth() === m);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const dn = i - startDow + 1;
            let day, inMonth;
            if (dn < 1) { day = daysInPrev + dn; inMonth = false; }
            else if (dn > daysInMonth) { day = dn - daysInMonth; inMonth = false; }
            else { day = dn; inMonth = true; }
            out.push({ day: day, inMonth: inMonth, today: inMonth && curMonth && day === t.getDate() });
        }
        return out;
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.monthOffset--
        Keys.onRightPressed: root.monthOffset++
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Theme.s2

        // header: ◀ Month Year ▶
        Item {
            width: parent.width
            height: 32

            // the empty part of the header (under the arrows and the title, which are
            // declared after it and so take their own clicks) goes back to the expanded
            // island the calendar was opened from
            MouseArea { anchors.fill: parent; onClicked: GlobalState.calendarBack() }

            // previous month. Identical to nextBtn below in look + behavior (only the
            // anchor side, arrow direction, and offset step differ).
            Rectangle {
                id: prevBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: prevMa.pressed ? Theme.hue("calendar") : prevMa.containsMouse ? Theme.fillHigh : Theme.fillLow
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                Icon { anchors.centerIn: parent; name: "back"; size: Theme.icon(14); color: prevMa.pressed ? Theme.onAccent : Theme.inkPrimary }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset--
                }
            }

            Rectangle {
                id: titleBtn
                anchors.centerIn: parent
                width: titleText.implicitWidth + Theme.s3
                height: 28
                radius: Theme.rMd
                color: titleMa.containsMouse ? Theme.fillLow : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                StyledText {
                    id: titleText
                    anchors.centerIn: parent
                    variant: "label"
                    font.weight: Theme.wSemiBold
                    text: root.monthNames[root.shownMonth] + " " + root.shownYear
                    color: Theme.inkPrimary
                }
                MouseArea { id: titleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.monthOffset = 0 }
            }

            // next month. Mirror of prevBtn.
            Rectangle {
                id: nextBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: nextMa.pressed ? Theme.hue("calendar") : nextMa.containsMouse ? Theme.fillHigh : Theme.fillLow
                Behavior on color { ColorAnimation { duration: Theme.dur(Theme.dFast) } }
                Icon { anchors.centerIn: parent; name: "back"; rotation: 180; size: Theme.icon(14); color: nextMa.pressed ? Theme.onAccent : Theme.inkPrimary }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset++
                }
            }
        }

        // weekday header
        Row {
            width: parent.width
            Repeater {
                model: 7
                delegate: Item {
                    required property int index
                    readonly property string modelData: root.dayLetters[(index + root.firstDay) % 7]
                    width: col.width / 7
                    height: 18
                    StyledText {
                        anchors.centerIn: parent
                        variant: "caption"
                        text: modelData
                        color: Theme.inkDim
                    }
                }
            }
        }

        // day grid (6 weeks)
        Grid {
            width: parent.width
            columns: 7
            rowSpacing: 2
            Repeater {
                model: root.cells
                delegate: Item {
                    required property var modelData
                    width: col.width / 7
                    height: root.cellH
                    // a day of a neighboring month is dimmed, or left out altogether
                    // (its cell stays, so the grid keeps its six rows and the island its
                    // height from month to month)
                    visible: modelData.inMonth || root.showAdjacent
                    Rectangle {
                        anchors.centerIn: parent
                        // the today mark fits the row, up to its usual 28
                        width: Math.max(16, Math.min(28, root.cellH - 2)); height: width; radius: width / 2
                        color: modelData.today ? Theme.hue("calendar") : "transparent"
                        StyledText {
                            anchors.centerIn: parent
                            variant: "caption"
                            font.weight: modelData.today ? Theme.wSemiBold : Theme.wRegular
                            text: modelData.day
                            color: modelData.today ? Theme.onAccent
                                 : modelData.inMonth ? Theme.inkPrimary : Theme.inkFaint
                        }
                    }
                }
            }
        }
    }
}

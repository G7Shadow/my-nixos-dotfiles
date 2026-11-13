pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import "../config"

// Wallpapers for the picker: the folder Settings points at (Config.wallpaperFolder),
// which by default is ~/Pictures/Wallpapers/<theme>, every theme with its own set.
// Reactive to the theme and to the two settings, so switching themes or moving the
// folder repopulates the picker on its own. Native, no external daemon.
Singleton {
    id: root

    readonly property string dir: Config.wallpaperFolder
    property alias model: fm
    // what the picker's search box holds: the list is narrowed to file names containing
    // it (any case). The characters a name filter treats as wildcards are dropped.
    property string query: ""
    readonly property string needle: query.trim().replace(/[\[\]*?]/g, "")
    readonly property var kinds: ["jpg", "jpeg", "png", "webp"]

    FolderListModel {
        id: fm
        folder: "file://" + root.dir
        nameFilters: root.kinds.map(k => (root.needle === "" ? "*." : "*" + root.needle + "*.") + k)
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name
    }
}

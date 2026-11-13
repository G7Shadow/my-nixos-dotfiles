pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, through cliphist. cliphist does the remembering (text and images,
// whether or not this shell is running: Hyprland's autostart runs
// `wl-paste --type text --watch cliphist store` and the same for `--type image`); this
// only lists what it has, puts an entry back on the clipboard, and forgets one.
//
// `entries` is cliphist's own order, newest first:
//   { id, t: the preview text, image: true for a picture, kind: "png", info: "png  ·  800x600  ·  12 KiB" }
// A picture also gets a file to show: cliphist decodes it once into the cache folder, and
// `ready[id]` is its path from then on (empty until it is there). Files of entries that
// are no longer in the history are removed on the same pass.
// The list is read when the launcher asks for it (refresh()), not kept live.
Singleton {
    id: root

    property var entries: []
    readonly property int previewWidth: 240     // how much of each text cliphist hands over

    function refresh() { if (!lister.running) lister.running = true; }

    Process {
        id: lister
        command: ["cliphist", "-preview-width", String(root.previewWidth), "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab <= 0) continue;
                    const id = line.slice(0, tab), t = line.slice(tab + 1);
                    if (!/^[0-9]+$/.test(id)) continue;
                    // a picture is listed as "[[ binary data 12 KiB png 800x600 ]]"
                    const m = t.match(/^\[\[ binary data (.+?) ([a-z0-9]+) ([0-9]+x[0-9]+) \]\]$/);
                    if (m) out.push({ id: id, t: "image " + m[2], image: true, kind: m[2], info: m[2] + "  ·  " + m[3] + "  ·  " + m[1] });
                    else out.push({ id: id, t: t, image: false, kind: "", info: "" });
                }
                root.entries = out;
                root.fetchPictures();
            }
        }
    }

    // The id is checked to be digits before it goes anywhere near a shell line.
    function ok(id) { return /^[0-9]+$/.test(String(id)); }

    // back onto the clipboard, whatever it is: cliphist decodes it and wl-copy takes it.
    // A picture is handed over with its type named, so the app it is pasted into is
    // offered an image and not a blob to guess at.
    function copy(id) {
        if (!ok(id)) return;
        const e = entries.find(x => x.id === String(id));
        const type = (e && e.image && /^[a-z0-9]+$/.test(e.kind)) ? ` --type image/${e.kind === "jpg" ? "jpeg" : e.kind}` : "";
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy${type}`]);
    }

    // ── pictures ──
    readonly property string picDir: Quickshell.cachePath("clipboard")
    readonly property int picMax: 40          // only the newest pictures get a file
    property var ready: ({})
    property var wanted: []
    function picPath(e) { return picDir + "/" + e.id + "." + e.kind; }
    function fetchPictures() {
        if (pics.running) return;
        wanted = entries.filter(e => e.image && ok(e.id) && /^[a-z0-9]+$/.test(e.kind)).slice(0, picMax);
        // one pass: make the folder, drop the files nobody lists any more, decode the missing
        const keepNames = wanted.map(e => e.id + "." + e.kind).join(" ");
        const decode = wanted.map(e => `[ -s "$d/${e.id}.${e.kind}" ] || cliphist decode ${e.id} > "$d/${e.id}.${e.kind}"`).join("; ");
        pics.command = ["sh", "-c",
            `d="$1"; mkdir -p "$d" || exit 1; for f in "$d"/*; do [ -e "$f" ] || continue; case " ${keepNames} " in *" \${f##*/} "*) ;; *) rm -f "$f";; esac; done; ${decode}`,
            "pics", picDir];
        pics.running = true;
    }
    Process {
        id: pics
        onExited: {
            const r = {};
            for (const e of root.wanted) r[e.id] = root.picPath(e);
            root.ready = r;
        }
    }

    // forget one. It leaves the list here at once; cliphist is told right after.
    function remove(id) {
        if (!ok(id)) return;
        entries = entries.filter(e => e.id !== String(id));
        Quickshell.execDetached(["sh", "-c", `printf '%s\\t\\n' ${id} | cliphist delete`]);
    }
}

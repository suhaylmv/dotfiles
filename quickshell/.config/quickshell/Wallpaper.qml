pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Fuzzy.js" as Fuzzy

// Wallpaper state and the picker's data; Background.qml draws it (this
// replaced awww), the picker lives in the launcher (`>wall`).
// The source of truth is the state link ~/.local/state/theme/wallpaper, which
// `wall` and theme-switch repoint (hyprlock reads the same link). They run
// `qs ipc call wallpaper reload` afterwards.
//   qs ipc call wallpaper reload
Singleton {
    id: root

    // real path of the wallpaper on screen ("" = none: the bg color shows)
    property string current: ""
    // the picker's highlighted image, shown live on the desktop ("" = none)
    property string preview: ""
    readonly property string shown: preview || current

    // ---- current: resolve the state link ----
    // Resolved to its real path: Qt caches images by URL, so a repointed link
    // with the same path would never reload.
    Process {
        id: resolve
        command: ["readlink", "-e", "/home/suhaylmv/.local/state/theme/wallpaper"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.current = text.trim()
        }
        // missing link (or broken target): readlink prints nothing
        onExited: code => { if (code !== 0) root.current = "" }
    }

    function reload() { resolve.running = false; resolve.running = true }

    IpcHandler {
        target: "wallpaper"
        function reload(): void { root.reload() }
    }

    // ---- the list: `wall --list` does all the file work ----
    // items: { path, category, thumb (1280px JPEG in ~/.cache/wall), name }
    property var items: []
    // folder names, in the order the chips show them
    readonly property var categories: {
        const seen = []
        for (const w of items) if (!seen.includes(w.category)) seen.push(w.category)
        return seen.sort()
    }
    // path -> thumbnail, for Background's instant first frame
    readonly property var thumbs: {
        const t = {}
        for (const w of items) t[w.path] = w.thumb
        return t
    }

    // run at startup and every time the picker opens (new files show up)
    function refresh() { if (!lister.running) lister.running = true }
    Process {
        id: lister
        command: ["/home/suhaylmv/.local/bin/wall", "--list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const f = line.split("\t")
                    if (f.length < 3) continue
                    const file = f[3] || f[0].split("/").pop()
                    out.push({ path: f[0], category: f[1], thumb: f[2],
                               name: file.replace(/\.[^.]*$/, "") })
                }
                // folder, then name (QML's sort isn't stable: path breaks ties)
                out.sort((a, b) => a.category.localeCompare(b.category)
                                   || a.name.localeCompare(b.name) || a.path.localeCompare(b.path))
                root.items = out
            }
        }
    }

    // "big-sur_daylight" -> "big-sur daylight"
    function label(category) { return category.replace(/_/g, " ") }

    // The picker's list: one folder ("" = all), then the typed text matched
    // against name and folder. Without text it keeps the folder order, so the
    // carousel reads like the folders on disk.
    function filter(query, category) {
        const pool = category ? items.filter(w => w.category === category) : items
        const q = query.trim()
        if (!q) return pool
        return pool
            .map(w => ({ w: w, s: Math.max(Fuzzy.score(q, w.name), 0.8 * Fuzzy.score(q, label(w.category))) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s || pool.indexOf(x.w) - pool.indexOf(y.w))
            .map(x => x.w)
    }

    // Keep it: `wall` repoints the links (this mode, or both) and calls reload.
    // `current` is set right away, so the preview just stays on screen.
    function apply(path, both) {
        current = path
        preview = ""
        Quickshell.execDetached(["/home/suhaylmv/.local/bin/wall", path].concat(both ? ["--both"] : []))
    }
}

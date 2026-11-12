pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history state; ClipboardWindow.qml draws it (SUPER+SHIFT+V,
// replaces the clipse TUI). `clipse -listen` stays the recorder: it runs
// `clipse --wl-store` once per copy, and that process reads and rewrites
// clipboard_history.json each time, so pinning and deleting here just edit
// the file (clipse has no flags for single entries).
//   File: {"clipboardHistory": [{value, recorded, filePath, pinned}]},
//   newest first; text entries have filePath "null", images
//   "📷 <name>.png" as value and the file in ~/.config/clipse/tmp_files.
//   qs ipc call clipboard toggle | close
Singleton {
    id: root

    property bool open: false
    function show() {
        Launcher.close()              // all three drop from the same spot under the bar
        Notifs.panelOpen = false
        open = true
    }
    function close() { open = false }

    // the panel or the launcher opening closes this
    Connections {
        target: Notifs
        function onPanelOpenChanged() { if (Notifs.panelOpen) root.open = false }
    }
    Connections {
        target: Launcher
        function onOpenChanged() { if (Launcher.open) root.open = false }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { if (root.open) root.close(); else root.show() }
        function close(): void { root.close() }
    }

    // ---- the history file ----
    readonly property string imageDir: "/home/suhaylmv/.config/clipse/tmp_files/"
    property var data: ({ clipboardHistory: [] })
    FileView {
        id: file
        path: "/home/suhaylmv/.config/clipse/clipboard_history.json"
        watchChanges: true                    // every copy rewrites it
        onFileChanged: reload()
        onLoaded: {
            try { root.data = JSON.parse(text()) } catch (e) { /* mid-write: the next change fixes it */ }
        }
    }

    // entries for the UI: pinned first, then newest first (the file's order)
    readonly property var entries: {
        const h = data.clipboardHistory || []
        const out = h.map((e, i) => {
            const image = !!e.filePath && e.filePath !== "null"
            return {
                value: e.value,
                recorded: e.recorded,
                pinned: !!e.pinned,
                image: image ? e.filePath : "",
                order: i,
                // one line for the list: whitespace runs collapsed
                line: image ? "Image" : e.value.replace(/\s+/g, " ").trim()
            }
        })
        return out.sort((a, b) => (b.pinned - a.pinned) || (a.order - b.order))
    }

    // every word must appear somewhere (case-insensitive); fuzzy matching
    // finds nonsense in long snippets
    function filter(query) {
        const words = query.toLowerCase().split(/\s+/).filter(w => w)
        if (!words.length) return entries
        return entries.filter(e => {
            const t = (e.image ? "image " + e.value : e.value).toLowerCase()
            return words.every(w => t.includes(w))
        })
    }

    // ---- actions ----
    // Copying makes clipse record it again, which moves it to the top.
    function copy(e) {
        if (e.image) {
            const type = e.image.toLowerCase().endsWith(".png") ? "image/png" : "image/" + e.image.split(".").pop()
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type "$1" < "$2"', "sh", type, e.image])
        } else {
            // through stdin, so the text arrives byte for byte
            Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | wl-copy', "sh", e.value])
        }
    }

    // find the entry in the file by when it was recorded (unique per copy)
    function edit(e, change) {
        const d = JSON.parse(JSON.stringify(data))
        const h = d.clipboardHistory || []
        const i = h.findIndex(x => x.recorded === e.recorded && x.value === e.value)
        if (i < 0) return
        change(h, i)
        data = d                              // the UI updates at once
        file.setText(JSON.stringify(d))       // clipse writes it compact too
    }
    function togglePin(e) { edit(e, (h, i) => { h[i].pinned = !h[i].pinned }) }
    function remove(e) {
        edit(e, (h, i) => { h.splice(i, 1) })
        // its image file too, but only ever inside clipse's own folder
        if (e.image && e.image.startsWith(imageDir) && !e.image.includes(".."))
            Quickshell.execDetached(["rm", "-f", e.image])
    }

    // "2026-11-11 17:53:34.068888597" (local time) -> "5 min"
    function age(recorded) {
        const t = new Date(recorded.slice(0, 23).replace(" ", "T"))
        const s = (Date.now() - t.getTime()) / 1000
        if (isNaN(s)) return ""
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + " min"
        if (s < 86400) return Math.floor(s / 3600) + " h"
        return Math.floor(s / 86400) + " d"
    }
}

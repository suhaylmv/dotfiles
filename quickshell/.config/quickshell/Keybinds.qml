pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Keybind cheat sheet state; KeybindsWindow.qml draws it (SUPER+?).
// The list comes from `hyprctl binds -j`, read each time it opens, so it's
// always what Hyprland has loaded. Only binds with a description show; a
// description is "Section: what it does" (see the note above the binds in
// hyprland.lua), and binds sharing one become a single row.
//   qs ipc call keybinds toggle | close
Singleton {
    id: root

    property bool open: false
    function show() {
        Launcher.close()              // everything drops from the same spot under the bar
        Clipboard.close()
        Notifs.panelOpen = false
        open = true
        reader.running = true
    }
    function close() { open = false }

    // anything else opening closes this
    Connections {
        target: Notifs
        function onPanelOpenChanged() { if (Notifs.panelOpen) root.open = false }
    }
    Connections {
        target: Launcher
        function onOpenChanged() { if (Launcher.open) root.open = false }
    }
    Connections {
        target: Clipboard
        function onOpenChanged() { if (Clipboard.open) root.open = false }
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void { if (root.open) root.close(); else root.show() }
        function close(): void { root.close() }
    }

    // ---- sections ----
    // Which column each section goes in (hand-balanced: about 13 rows each).
    // A section not listed here goes to the shortest column.
    readonly property var layout: [
        ["Apps", "Screenshots"],
        ["Windows", "Scratchpads"],
        ["Workspaces", "Media"],
    ]

    // [{ title, rows: [{ text, chords: [{ mods: [..], keys: [..] }] }] }] per column
    property var columns: [[], [], []]

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.columns = root.build(JSON.parse(text)) } catch (e) { console.warn("keybinds:", e) }
            }
        }
    }

    function build(binds) {
        // section -> description -> modmask -> keys, all in bind order
        const sections = {}, order = []
        for (const b of binds) {
            if (!b.has_description) continue
            const cut = b.description.indexOf(": ")
            const title = cut > 0 ? b.description.slice(0, cut) : "Other"
            const text = cut > 0 ? b.description.slice(cut + 2) : b.description
            if (!sections[title]) { sections[title] = { title: title, rows: [], byText: {} }; order.push(title) }
            const sec = sections[title]
            let row = sec.byText[text]
            if (!row) { row = { text: text, chords: [] }; sec.byText[text] = row; sec.rows.push(row) }
            let chord = row.chords.find(c => c.mask === b.modmask)
            if (!chord) { chord = { mask: b.modmask, mods: mods(b.modmask), keys: [] }; row.chords.push(chord) }
            const k = keyName(b.key)
            if (!chord.keys.includes(k)) chord.keys.push(k)
        }
        const cols = layout.map(names => names.filter(n => sections[n]).map(n => sections[n]))
        const size = col => col.reduce((n, s) => n + s.rows.length + 2, 0)
        for (const t of order) {
            if (layout.some(names => names.includes(t))) continue
            cols.reduce((a, b) => size(b) < size(a) ? b : a).push(sections[t])
        }
        return cols
    }

    // Hyprland modmask bits
    function mods(mask) {
        const out = []
        if (mask & 64) out.push("Super")
        if (mask & 4) out.push("Ctrl")
        if (mask & 8) out.push("Alt")
        if (mask & 1) out.push("Shift")
        return out
    }

    readonly property var names: ({
        "SPACE": "Space", "TAB": "Tab", "RETURN": "Enter", "ESCAPE": "Esc", "Print": "Print",
        "slash": "/", "comma": ",", "period": ".", "grave": "`", "apostrophe": "'",
        "braceright": "}", "braceleft": "{", "asciitilde": "~", "backslash": "\\",
        "mouse:272": "Left click", "mouse:273": "Right click"
    })
    function keyName(k) {
        if (names[k] !== undefined) return names[k]
        return k.length === 1 ? k.toUpperCase() : k
    }
}

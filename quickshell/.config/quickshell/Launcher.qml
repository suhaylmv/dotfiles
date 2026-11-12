pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Fuzzy.js" as Fuzzy

// Launcher state, search and actions; LauncherWindow.qml draws it.
//   apps:     type to search; empty shows the 5 most-launched apps
//   commands: start with ">" (lock, reboot, theme, night light, ...)
//   power:    three tiles, Lock / Reboot / Power off (never suspend:
//             this laptop doesn't wake from it)
//   wallpaper: ">wall" turns the window into the carousel picker
//             (LauncherWindow + Wallpaper.qml); text after it filters
//   qs ipc call launcher toggle | power | wallpaper | close
Singleton {
    id: root

    property bool open: false
    property string mode: "apps"      // "apps" | "power" | "wallpaper" (opens with ">wall ")
    property bool picking: false      // the wallpaper carousel is showing (set by LauncherWindow)

    // LauncherWindow resets its text and selection for the mode
    signal reset()

    function show(m) {
        mode = m
        open = true
        Notifs.panelOpen = false      // both drop from the same spot under the bar
        reset()
    }
    function close() { open = false }

    // the panel opening closes the launcher
    Connections {
        target: Notifs
        function onPanelOpenChanged() { if (Notifs.panelOpen) root.open = false }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { if (root.open && root.mode === "apps") root.close(); else root.show("apps") }
        function power(): void { if (root.open && root.mode === "power") root.close(); else root.show("power") }
        function wallpaper(): void { if (root.open && root.picking) root.close(); else root.show("wallpaper") }
        function close(): void { root.close() }
    }

    // ---- running things ----
    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    // close first, so a new window doesn't open under the launcher
    function run(item) {
        close()
        item.action()
    }

    function launchApp(entry) {
        bump(entry.id)
        if (entry.runInTerminal) {
            // the same Ghostty flags as float-tui: a second Ghostty process
            // can't take Super+Escape and would pop up a warning about it
            Quickshell.execDetached({
                command: ["ghostty", "--keybind=global:super+escape=unbind", "-e"].concat(entry.command),
                workingDirectory: entry.workingDirectory || Quickshell.env("HOME")
            })
        } else {
            entry.execute()
        }
    }

    // ---- apps ----
    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    function appItem(entry) {
        const image = entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
        return {
            key: "app:" + entry.id,
            name: entry.name,
            detail: entry.genericName || entry.comment || "",
            image: image,
            glyph: image ? "" : Icons.app,
            action: () => root.launchApp(entry)
        }
    }

    function appScore(q, a) {
        // the program name too, so "zeditor" or "nautilus" finds its app
        const program = (a.command[0] || "").split("/").pop()
        let best = Math.max(Fuzzy.score(q, a.name),
                            0.8 * Fuzzy.score(q, a.genericName),
                            0.7 * Fuzzy.score(q, program))
        for (const k of a.keywords) best = Math.max(best, 0.6 * Fuzzy.score(q, k))
        if (best === 0) return 0
        // often-launched apps float up, but a better match still wins
        return best + Math.min(15, 4 * Math.log2(1 + (counts[a.id] || 0)))
    }

    // ---- commands (after ">") ----
    readonly property var commands: [
        { key: "cmd:lock", name: "Lock", detail: "Lock the screen", glyph: Icons.lock,
          words: "screen", action: () => sh("pidof hyprlock || hyprlock") },
        { key: "cmd:reboot", name: "Reboot", detail: "Restart the laptop", glyph: Icons.reboot,
          words: "restart", action: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { key: "cmd:poweroff", name: "Power off", detail: "Shut down", glyph: Icons.power,
          words: "shutdown halt", action: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { key: "cmd:theme", name: Theme.dark ? "Light mode" : "Dark mode",
          detail: "Switch the desktop theme", glyph: Icons.themeToggle,
          words: "theme dark light", action: () => sh("~/.local/bin/theme-switch") },
        // fill: Enter puts this text in the search field instead of running
        // something (">wall" switches the window to the carousel)
        { key: "cmd:wallpaper", name: "Wallpaper", detail: "Pick a wallpaper", glyph: Icons.wallpaper,
          words: "background wall", fill: ">wall " },
        { key: "cmd:night", name: "Night light", detail: NightLight.active ? "Turn off" : "Turn on",
          glyph: Icons.night, words: "warm hyprsunset", action: () => NightLight.toggle() },
        { key: "cmd:dnd", name: "Do not disturb", detail: Notifs.dnd ? "Turn off" : "Turn on",
          glyph: Icons.bellOff, words: "notifications silent dnd", action: () => { Notifs.dnd = !Notifs.dnd } },
        { key: "cmd:clipboard", name: "Clipboard", detail: "Clipboard history", glyph: Icons.clipboard,
          words: "clipse paste history", action: () => Clipboard.show() },
    ]

    readonly property var power: commands.slice(0, 3)

    // ---- search ----
    // Plain function, called from a binding: QML still tracks what it reads
    // (apps, counts, commands), so results refresh when those change.
    function results(text) {
        if (text.startsWith(">")) {
            const q = text.slice(1).trim()
            if (!q) return commands
            return commands
                .map(c => ({ c: c, s: Math.max(Fuzzy.score(q, c.name), 0.6 * Fuzzy.score(q, c.words)) }))
                .filter(x => x.s > 0)
                .sort((x, y) => y.s - x.s || commands.indexOf(x.c) - commands.indexOf(y.c))
                .map(x => x.c)
        }
        const q = text.trim()
        if (!q) {
            // most launched first; before there's any history, alphabetical
            // (QML's sort isn't stable, so ties always need the name)
            return apps.slice()
                .sort((a, b) => (counts[b.id] || 0) - (counts[a.id] || 0) || a.name.localeCompare(b.name))
                .slice(0, 5)
                .map(appItem)
        }
        return apps
            .map(a => ({ a: a, s: appScore(q, a) }))
            .filter(x => x.s > 0)
            .sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
            .slice(0, 30)
            .map(x => appItem(x.a))
    }

    // ---- launch counts, outside the repo (~/.local/state/quickshell/...) ----
    property var counts: ({})
    function bump(id) {
        const c = Object.assign({}, counts)
        c[id] = (c[id] || 0) + 1
        counts = c
        countsFile.setText(JSON.stringify(c))
    }
    FileView {
        id: countsFile
        path: Quickshell.statePath("launcher-counts.json")
        onLoaded: {
            try { root.counts = JSON.parse(text()) } catch (e) { root.counts = {} }
        }
    }
}

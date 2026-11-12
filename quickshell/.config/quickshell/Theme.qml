pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colors come from the active theme's colors.css (the GTK palette file),
// so there's no separate palette to keep in sync.
// theme-switch runs `qs ipc call theme reload` after repointing the theme.
Singleton {
    id: root

    property var palette: ({})
    function pick(name, fallback) {
        return palette[name] !== undefined ? palette[name] : fallback
    }

    readonly property color crust:    pick("crust", "#0B0C10")
    readonly property color bg:       pick("bg", "#0F1015")
    readonly property color surface:  pick("surface", "#15171D")
    readonly property color overlay:  pick("overlay", "#20232B")
    readonly property color fg:       pick("fg", "#A1BDCE")
    readonly property color fgStrong: pick("fg-strong", "#E8EDF0")
    readonly property color muted:    pick("muted", "#7A8494")
    readonly property color accent:   pick("accent", "#92C6F0")
    readonly property color blue:     pick("blue", "#81A0EA")
    readonly property color purple:   pick("purple", "#C6D0FF")
    readonly property color sand:     pick("sand", "#F5DBC2")
    readonly property color green:    pick("green", "#B9E29D")
    readonly property color red:      pick("red", "#F07F87")
    readonly property bool dark: bg.hslLightness < 0.5
    // text drawn on top of the accent (dark text in dark mode, light in light)
    readonly property color textOnAccent: bg

    readonly property string font: "Readex Pro"
    readonly property string iconFont: "JetBrainsMono Nerd Font Propo"

    FileView {
        id: file
        // absolute path: "current" is the symlink theme-switch repoints
        path: "/home/suhaylmv/.local/state/theme/current/colors.css"
        onLoaded: root.parse(text())
    }

    // @define-color name #RRGGBB;  ->  palette[name] = "#RRGGBB"
    function parse(css) {
        const found = {}
        const re = /@define-color\s+([\w-]+)\s+(#[0-9a-fA-F]{6})/g
        let m
        while ((m = re.exec(css)) !== null) found[m[1]] = m[2]
        palette = found
    }

    IpcHandler {
        target: "theme"
        function reload(): void { file.reload() }
    }
}

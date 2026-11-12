import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

// Volume / brightness OSD: drops down under the bar when a level changes and
// fades out 1.5s after the last change. Volume follows PipeWire directly, so
// it also shows when another app changes it. Brightness has no change events:
// the brightness binds run `timeout 1 qs ipc call osd brightness` afterwards.
//   qs ipc call osd brightness | volume
PanelWindow {
    id: win
    property string kind: "volume"    // which level the pill shows
    property bool shown: false

    visible: pop.live                 // stays mapped while it animates out
    anchors.top: true                 // only top: centered horizontally
    margins.top: 8                    // same spot as the panel
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: 280
    implicitHeight: 62
    color: "transparent"
    mask: Region {}                   // never takes clicks: they go to what's below
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"

    // ---- volume ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    PwObjectTracker { objects: [win.sink] }

    // PipeWire reports the starting values once the sink is bound (at startup
    // and after switching outputs); those aren't key presses, so ignore them.
    property bool armed: false
    onSinkChanged: { armed = false; arm.restart() }
    Timer { id: arm; interval: 1000; running: true; onTriggered: win.armed = true }

    Connections {
        target: win.audio
        function onVolumeChanged() {
            if (!win.armed) return
            // no blips while dragging the panel's slider
            if (!Notifs.panelOpen) Sounds.volumeStep()
            win.request("volume")
        }
        function onMutedChanged() { if (win.armed) win.request("volume") }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { Brightness.refresh(); win.request("brightness") }
        function volume(): void { win.request("volume") }
    }

    // ---- show / hide ----
    function request(k) {
        // same spot as the panel, launcher, clipboard and cheat sheet; the panel has its own sliders
        if (Notifs.panelOpen || Launcher.open || Clipboard.open || Keybinds.open) return
        kind = k
        if (shown) { hide.restart(); return }
        // volume and brightness keys also work on the lock screen: don't pop up
        // there (or right after unlocking)
        if (!lockCheck.running) lockCheck.running = true
    }
    Process {
        id: lockCheck
        command: ["pidof", "hyprlock"]
        onExited: code => { if (code !== 0) { win.shown = true; hide.restart() } }
    }
    Timer { id: hide; interval: 1500; onTriggered: win.shown = false }

    // the same open/close motion as the panel and the launcher
    Pop {
        id: pop
        shown: win.shown
        target: card

        Surface {
            id: card
            width: parent.width
            height: parent.height
            radius: height / 2

            PillSlider {
                anchors.fill: parent
                anchors.margins: 8
                readonly property bool vol: win.kind === "volume"
                readonly property bool muted: vol && (win.audio?.muted ?? false)
                icon: vol ? (muted ? Icons.volumeOff : Icons.volume) : Icons.brightness
                value: vol ? Math.min(1, win.audio?.volume ?? 0) : Brightness.value
                dimmed: muted
            }
        }
    }
}

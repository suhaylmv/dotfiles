pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness (0..1) through brightnessctl. The kernel sends no change
// event for it, so refresh() re-reads it: the panel calls it when it opens,
// the OSD when a brightness key runs `qs ipc call osd brightness`.
Singleton {
    id: root
    readonly property string device: "amdgpu_bl1"
    property real value: 0.5

    // a held key asks again while a read is still running: read once more after
    property bool again: false
    function refresh() {
        if (reader.running) again = true
        else reader.running = true
    }

    function set(v) {
        value = Math.max(0.01, Math.min(1, v))
        Quickshell.execDetached(["brightnessctl", "-q", "-d", device, "set",
                                 Math.round(value * 100) + "%"])
    }

    Process {
        id: reader
        command: ["brightnessctl", "-d", root.device, "-m"]   // amdgpu_bl1,backlight,cur,NN%,max
        stdout: StdioCollector {
            onStreamFinished: root.value = parseInt(text.split(",")[3]) / 100
        }
        onExited: if (root.again) { root.again = false; reader.running = true }
    }
}

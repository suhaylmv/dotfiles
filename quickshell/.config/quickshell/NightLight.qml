pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light (warm screen) through hyprsunset, which Hyprland autostarts.
// Quickshell keeps the state and runs the schedule, because hyprsunset can't
// report whether it's on. The panel tile toggles it; a manual toggle lasts
// until the next scheduled change. Right-click the tile to edit this file.
Singleton {
    id: root

    // ================= settings (saved changes apply right away) =================
    property bool   scheduled:   true      // false: only on/off by hand
    property string startsAt:    "01:00"   // 24-hour clock
    property string endsAt:      "06:00"
    property int    temperature: 4000      // Kelvin: lower is warmer/redder (6000 is neutral)
    // ===============================================================================

    property bool active: false
    property var lastWindow: null           // was "now" inside the schedule at the last check

    function minutes(hhmm) {
        const parts = hhmm.split(":")
        return parseInt(parts[0]) * 60 + parseInt(parts[1])
    }
    // also works when the window crosses midnight (21:00 -> 07:00)
    function inWindow(d) {
        const t = d.getHours() * 60 + d.getMinutes()
        const a = minutes(startsAt), b = minutes(endsAt)
        return a <= b ? (t >= a && t < b) : (t >= a || t < b)
    }

    function set(on) {
        active = on
        Quickshell.execDetached(on ? ["hyprctl", "hyprsunset", "temperature", String(temperature)]
                                   : ["hyprctl", "hyprsunset", "identity"])
    }
    function toggle() { set(!active) }

    // Apply the schedule only when it changes, so a manual toggle sticks.
    function check() {
        const w = inWindow(new Date())
        if (scheduled && w !== lastWindow) set(w)
        lastWindow = w
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.check() }
    // first check a few seconds after login, once hyprsunset is up
    Timer { interval: 3000; running: true; onTriggered: root.check() }
    // a new warmth while it's on applies immediately
    onTemperatureChanged: if (active) set(true)

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle() }
        function on(): void { root.set(true) }
        function off(): void { root.set(false) }
    }
}

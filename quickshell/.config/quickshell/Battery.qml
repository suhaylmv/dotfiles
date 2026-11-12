pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Battery level from the kernel (sysfs), read every 5s for the bar.
// Not UPower: that daemon isn't running here, and enabling it brings a
// critical-battery action that defaults to HybridSleep (suspend), which
// this laptop never wakes from.
// Plays the low-battery sound once when it drops to `low` while discharging;
// charging or climbing back above `low` re-arms it.
Singleton {
    id: root

    readonly property string dir: "/sys/class/power_supply/BAT0/"
    readonly property int low: 15                 // the bar's red level
    readonly property int warning: 30             // the bar's purple level

    property int capacity: 100
    property string status: "Unknown"             // Charging, Discharging, Full, Not charging
    readonly property bool discharging: status === "Discharging"
    readonly property bool charging: status === "Charging"
    // on the charger: charging, or holding at its limit
    readonly property bool plugged: charging || status === "Not charging"

    // µW and µWh from sysfs
    property real powerNow: 0
    property real energyNow: 0
    property real energyFull: 0

    // "Time to empty: 3 h 12 min", like Waybar's {timeTo}; else the status
    readonly property string timeTo: {
        const target = discharging ? energyNow : charging ? energyFull - energyNow : -1
        if (target < 0 || powerNow <= 0) return status
        const min = Math.round(target / powerNow * 60)
        return "Time to " + (discharging ? "empty" : "full") + ": "
            + Math.floor(min / 60) + " h " + (min % 60) + " min"
    }

    property bool warned: false
    function check() {
        if (!discharging || capacity > low) { warned = false; return }
        if (!warned) { warned = true; Sounds.batteryLow() }
    }

    // sysfs files don't send change events, so poll (FileView: no process)
    FileView { id: capacityFile; path: root.dir + "capacity"; onLoaded: { root.capacity = parseInt(text()) || 0; root.check() } }
    FileView { id: statusFile; path: root.dir + "status"; onLoaded: { root.status = text().trim() || "Unknown"; root.check() } }
    FileView { id: powerFile; path: root.dir + "power_now"; onLoaded: root.powerNow = parseFloat(text()) || 0 }
    FileView { id: energyFile; path: root.dir + "energy_now"; onLoaded: root.energyNow = parseFloat(text()) || 0 }
    FileView { id: fullFile; path: root.dir + "energy_full"; onLoaded: root.energyFull = parseFloat(text()) || 0 }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: { for (const f of [capacityFile, statusFile, powerFile, energyFile, fullFile]) f.reload() }
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and network for the bar. CPU every 3s, memory and Wi-Fi
// signal every 5s, read straight from /proc (FileView: no process per read).
// The rest of the network info comes from nmcli, run only when NetworkManager
// reports a change (`nmcli monitor`), plus once a minute as a fallback.
Singleton {
    id: root

    // ---- memory (/proc/meminfo; "used" = total - available, like Waybar) ----
    property real memTotal: 0         // GiB
    property real memUsed: 0
    readonly property int memPercent: memTotal > 0 ? Math.round(memUsed / memTotal * 100) : 0

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text()
            const kb = name => parseInt((t.match(new RegExp("^" + name + ":\\s+(\\d+)", "m")) || [0, 0])[1])
            const total = kb("MemTotal")
            root.memTotal = total / 1048576
            root.memUsed = (total - kb("MemAvailable")) / 1048576
        }
    }

    // ---- CPU: share of non-idle time since the last read (/proc/stat) ----
    property int cpu: 0               // percent
    property var last: null

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            // first line: cpu  user nice system idle iowait irq softirq steal
            const v = text().split("\n")[0].trim().split(/\s+/).slice(1, 9).map(Number)
            const idle = v[3] + v[4]
            const total = v.reduce((a, b) => a + b, 0)
            if (root.last && total > root.last.total)
                root.cpu = Math.round(100 * (1 - (idle - root.last.idle) / (total - root.last.total)))
            root.last = { idle: idle, total: total }
        }
    }

    // ---- network (NetworkManager) ----
    property string netType: "none"   // "wifi" | "ethernet" | "none"
    property string ssid: ""
    property int signal: 0            // percent
    property string ifname: ""
    property string ip: ""

    Process {
        id: net
        // three sections: devices, Wi-Fi networks (cached, no rescan), IPv4 addresses.
        // Its signal is from the last scan and goes stale; `wireless` below
        // keeps it current.
        command: ["sh", "-c",
            "nmcli -t -e no -f TYPE,STATE,DEVICE device; echo ---; " +
            "nmcli -t -e no -f IN-USE,SIGNAL,SSID device wifi list --rescan no; echo ---; " +
            "ip -4 -o addr show scope global"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const [devs, wifis, addrs] = text.split("---\n").map(s => s.split("\n").filter(l => l))
                // first connected device, Wi-Fi or Ethernet
                const dev = (devs || []).map(l => l.split(":"))
                    .find(f => (f[0] === "wifi" || f[0] === "ethernet") && f[1].startsWith("connected"))
                if (!dev) { root.netType = "none"; root.ifname = ""; root.ip = ""; return }
                root.netType = dev[0]
                root.ifname = dev[2]
                // "*:74:Network name" (the SSID may contain ':')
                const inUse = (wifis || []).find(l => l.startsWith("*:"))
                if (inUse) {
                    const f = inUse.split(":")
                    root.signal = parseInt(f[1]) || 0
                    root.ssid = f.slice(2).join(":")
                }
                // "3: wlan0    inet 192.168.1.5/24 brd ..."
                const a = (addrs || []).find(l => l.split(/\s+/)[1] === root.ifname)
                root.ip = a ? a.split(/\s+/)[3].split("/")[0] : ""
                wireless.reload()             // the live signal over the scan's
            }
        }
    }

    // Live signal of the connected interface: /proc/net/wireless has its
    // level in dBm, turned into a percentage the way NetworkManager does
    // (-100 dBm = 0%, -40 dBm or better = 100%).
    FileView {
        id: wireless
        path: "/proc/net/wireless"
        onLoaded: {
            if (root.netType !== "wifi") return
            // "wlp2s0: 0000   70.  -40.  -256  ..."
            const line = text().split("\n").find(l => l.trim().startsWith(root.ifname + ":"))
            if (!line) return
            const dbm = parseFloat(line.split(/\s+/).filter(f => f)[3])
            if (isNaN(dbm) || dbm >= 0) return
            root.signal = Math.round(100 - 100 * (-40 - Math.min(-40, Math.max(-100, dbm))) / 60)
        }
    }

    // NetworkManager prints a line on every change (device state, connection,
    // connectivity); refresh shortly after, once per burst of lines
    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser { onRead: _ => netSoon.restart() }
        // stopped (NetworkManager restarted?): start again in a bit
        onExited: monitorRestart.start()
    }
    Timer { id: monitorRestart; interval: 5000; onTriggered: { monitor.running = true; netSoon.restart() } }
    Timer { id: netSoon; interval: 500; onTriggered: net.running = true }

    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: stat.reload()
    }
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: { meminfo.reload(); wireless.reload() }
    }
    Timer {
        // fallback, in case a change slipped past the monitor
        interval: 60000; running: true; repeat: true
        onTriggered: net.running = true
    }
}

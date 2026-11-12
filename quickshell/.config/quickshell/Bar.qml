import QtQuick
import Quickshell
import Quickshell.Wayland

// The top bar (replaces Waybar), one per screen, same sizes:
//   left:   NixOS logo, workspaces, now playing
//   center: date (hover: this month and the next)
//   right:  tray drawer, network, memory, CPU, battery, clock, bell
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData

        anchors { top: true; left: true; right: true }
        margins { top: 7; left: 7; right: 7 }     // Hyprland gaps_out
        implicitHeight: 38
        exclusiveZone: 38
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bar"

        Rectangle {
            id: box
            anchors.fill: parent
            radius: 14
            color: Theme.bg

            // ================= left =================
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                height: parent.height

                BarIcon {
                    icon: Icons.nix
                    size: 22
                    color: Theme.accent
                    padLeft: 8
                    padRight: 10
                }
                BarWorkspaces { screen: win.modelData; height: parent.height }
                BarMedia {}
            }

            // ================= center =================
            Item {
                id: date
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                implicitWidth: dateText.implicitWidth + 16
                property date now: new Date()

                Text {
                    id: dateText
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1   // Waybar: 3px top, 1px bottom margin
                    // English names like before (LC_TIME is Spanish)
                    text: Qt.locale("en_US").toString(date.now, "dddd, dd MMMM")
                    font.family: Theme.font
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.fg
                }
                MouseArea {
                    id: dateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
                // hover: this month and the next, side by side
                BarTooltip {
                    target: date
                    hovered: dateMouse.containsMouse
                    radius: 24
                    body: Row {
                        CalendarCard {
                            implicitWidth: 260
                            color: "transparent"
                            today: date.now
                        }
                        CalendarCard {
                            implicitWidth: 260
                            color: "transparent"
                            today: date.now
                            monthOffset: 1
                        }
                    }
                }
            }

            // ================= right =================
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                height: parent.height

                BarTray { height: parent.height }

                BarIcon {
                    readonly property bool wifi: SysInfo.netType === "wifi"
                    icon: wifi ? Icons.wifi[Math.min(3, Math.floor(SysInfo.signal / 25))]
                        : SysInfo.netType === "ethernet" ? Icons.ethernet : Icons.wifiOff
                    size: 17
                    color: SysInfo.netType === "none" ? Theme.muted : Theme.fg
                    tip: wifi ? SysInfo.ssid + " · " + SysInfo.signal + "%\n" + SysInfo.ip
                        : SysInfo.netType === "ethernet" ? SysInfo.ifname + " · " + SysInfo.ip
                        : "Disconnected"
                    onClicked: Quickshell.execDetached(["sh", "-c", "~/.local/bin/float-tui nmtui Network nmtui"])
                    onRightClicked: Quickshell.execDetached(["sh", "-c", "~/.local/bin/float-tui wifi Wi-Fi nmtui connect"])
                }
                BarIcon {
                    icon: Icons.memory
                    size: 20
                    color: SysInfo.memPercent >= 90 ? Theme.red : Theme.fg
                    tip: "Memory " + SysInfo.memUsed.toFixed(1) + " / " + SysInfo.memTotal.toFixed(1)
                         + " GiB (" + SysInfo.memPercent + "%)"
                }
                BarIcon {
                    icon: Icons.cpu
                    size: 20
                    color: SysInfo.cpu >= 90 ? Theme.red : Theme.fg
                    tip: "CPU " + SysInfo.cpu + "%"
                }
                BarIcon {
                    icon: Battery.plugged ? Icons.charging
                        : Icons.battery[Math.min(10, Math.floor(Battery.capacity / 9))]
                    size: 18
                    padRight: 10
                    // purple at 30% and below, red at 15%, unless on the charger
                    // (also "Not charging": plugged in, holding at its limit)
                    color: Battery.plugged ? Theme.fg
                        : Battery.capacity <= Battery.low ? Theme.red
                        : Battery.capacity <= Battery.warning ? Theme.purple : Theme.fg
                    tip: Battery.capacity + "% · " + Battery.timeTo
                }

                // clock
                Item {
                    id: clock
                    height: parent.height
                    implicitWidth: clockText.implicitWidth + 20
                    property date now: new Date()
                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        text: Qt.locale("en_US").toString(clock.now, "hh:mm AP")
                        font.family: Theme.font
                        font.pixelSize: 15
                        font.weight: Font.Bold      // Readex Pro stops at 700
                        color: Theme.fg
                    }
                }

                BarIcon {
                    icon: Notifs.dnd ? Icons.bellOff : Notifs.count > 0 ? Icons.bellBadge : Icons.bell
                    size: 17
                    padLeft: 7
                    padRight: 8
                    hoverAccent: true
                    // accent = unread, muted = Do not disturb
                    color: Notifs.dnd ? Theme.muted : Notifs.count > 0 ? Theme.accent : Theme.fg
                    onClicked: Notifs.togglePanel()
                    onRightClicked: Notifs.dnd = !Notifs.dnd
                }
            }
        }

        // tick on the minute, for the clock and the date
        Timer {
            id: tick
            running: true
            interval: 60000 - Date.now() % 60000 + 50
            onTriggered: {
                const now = new Date()
                clock.now = now
                date.now = now
                interval = 60000 - Date.now() % 60000 + 50
                restart()
            }
        }
    }
}

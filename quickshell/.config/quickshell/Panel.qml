import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// The dashboard (SUPER+V or the bell in the bar). Left: quick settings,
// sliders, media, calendar. Right: notifications. Click outside or Esc closes.
PanelWindow {
    id: win
    visible: pop.live                 // stays up while it animates closed
    anchors.top: true                 // only top: centered horizontally
    margins.top: 8
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0                  // sits below the bar, reserves nothing
    implicitWidth: 820
    implicitHeight: left.implicitHeight + 32
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    // while closing: no keys, and clicks go through to what's below
    WlrLayershell.keyboardFocus: Notifs.panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: Notifs.panelOpen ? frame : null }

    // clicking anywhere else closes the panel
    HyprlandFocusGrab {
        active: Notifs.panelOpen
        windows: [win]
        onCleared: Notifs.panelOpen = false
    }

    // run a command after closing the panel (for things that open windows)
    function launch(cmd) {
        Notifs.panelOpen = false
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    // ---- volume: the default output through PipeWire ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [win.sink] }

    readonly property var adapter: Bluetooth.defaultAdapter

    // both columns the same width
    readonly property real column: (width - 16 * 3) / 2

    // on open (also when reopened while still closing)
    readonly property bool shown: Notifs.panelOpen
    onShownChanged: if (shown) { Brightness.refresh(); calendar.monthOffset = 0; frame.forceActiveFocus() }

    Pop {
        id: pop
        shown: Notifs.panelOpen
        target: frame

        Rectangle {
            id: frame
            width: parent.width
            height: parent.height
            radius: 32
            color: Theme.bg
            border.width: 1
            border.color: Theme.overlay
            focus: true
            Keys.onEscapePressed: Notifs.panelOpen = false

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // ================= left: controls =================
                ColumnLayout {
                    id: left
                    Layout.preferredWidth: win.column
                    Layout.minimumWidth: win.column
                    Layout.maximumWidth: win.column
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Toggle {
                            Layout.fillWidth: true
                            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
                            label: Notifs.dnd ? "Silent" : "Notify"
                            active: Notifs.dnd
                            onClicked: Notifs.dnd = !Notifs.dnd
                        }
                        Toggle {
                            // click: Bluetooth on/off; right-click: devices (bluetui)
                            Layout.fillWidth: true
                            readonly property bool on: win.adapter?.enabled ?? false
                            icon: on ? Icons.bluetooth : Icons.bluetoothOff
                            label: win.adapter ? (on ? "On" : "Off") : "None"
                            active: on
                            onClicked: if (win.adapter) win.adapter.enabled = !win.adapter.enabled
                            onRightClicked: win.launch("~/.local/bin/float-tui bluetui Bluetooth bluetui")
                        }
                        Toggle {
                            // click: warm screen on/off; right-click: edit the schedule
                            Layout.fillWidth: true
                            icon: Icons.night
                            label: NightLight.active ? "Warm" : "Off"
                            active: NightLight.active
                            onClicked: NightLight.toggle()
                            onRightClicked: win.launch("zeditor ~/.config/quickshell/NightLight.qml")
                        }
                        Toggle {
                            Layout.fillWidth: true
                            icon: Icons.wallpaper
                            label: "Wallpaper"
                            onClicked: Launcher.show("wallpaper")   // the launcher's carousel; closes the panel
                        }
                        Toggle {
                            Layout.fillWidth: true
                            icon: Icons.power
                            label: "Power"
                            onClicked: Launcher.show("power")   // closes the panel
                        }
                    }

                    PillSlider {
                        Layout.fillWidth: true
                        icon: Icons.brightness
                        value: Brightness.value
                        onMoved: v => Brightness.set(v)
                    }
                    PillSlider {
                        // right-click mutes
                        Layout.fillWidth: true
                        icon: win.sink?.audio?.muted ? Icons.volumeOff : Icons.volume
                        value: win.sink?.audio?.volume ?? 0
                        dimmed: win.sink?.audio?.muted ?? false
                        onMoved: v => { if (win.sink?.audio) { win.sink.audio.muted = false; win.sink.audio.volume = v } }
                        onRightClicked: if (win.sink?.audio) win.sink.audio.muted = !win.sink.audio.muted
                    }

                    MediaCard { Layout.fillWidth: true }
                    CalendarCard {
                        // arrows or the wheel for other months; back to this one on open
                        id: calendar
                        Layout.fillWidth: true
                        navigable: true
                    }
                }

                // ================= right: notifications =================
                ColumnLayout {
                    Layout.preferredWidth: win.column
                    Layout.minimumWidth: win.column
                    Layout.maximumWidth: win.column
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.topMargin: 4
                        spacing: 8
                        Text {
                            text: "Notifications"
                            font.family: Theme.font
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: Theme.fgStrong
                        }
                        Rectangle {
                            visible: Notifs.count > 0
                            implicitWidth: countText.implicitWidth + 14
                            implicitHeight: 20
                            radius: 10
                            color: Theme.overlay
                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: Notifs.count
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.fg
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            visible: Notifs.count > 0
                            implicitWidth: clearText.implicitWidth + 24
                            implicitHeight: 28
                            radius: 14
                            color: clearMouse.containsMouse ? Theme.red : Theme.surface
                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: "Clear"
                                font.family: Theme.font
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: clearMouse.containsMouse ? Theme.bg : Theme.muted
                            }
                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.clearAll()
                            }
                        }
                    }

                    // cards slide in and out, the rest close the gap (NotifListView.qml)
                    NotifListView {
                        id: list
                        visible: busy                 // else the empty state gets the whole column
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        source: Notifs.all
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: NotificationCard {
                            id: card
                            required property int nid
                            notif: list.objects[nid]
                            width: list.width
                            onActivated: if (Notifs.activate(notif)) Notifs.panelOpen = false
                            // keeps a dismissed notification alive until its card is gone
                            RetainableLock { object: card.notif; locked: true }
                        }
                    }

                    // empty state, fading in once the last card has left
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !list.busy
                        opacity: visible ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Motion.openMs
                                easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.enter
                            }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Glyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Icons.bellCheck
                                size: 48
                                color: Theme.overlay
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "All caught up"
                                font.family: Theme.font
                                font.pixelSize: 13
                                color: Theme.muted
                            }
                        }
                    }
                }
            }
        }
    }
}

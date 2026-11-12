import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// The tray, hidden behind a chevron left of the network icon: click the
// chevron to slide the icons out to its left, click again to hide them.
// Icons: click activates (or opens the menu if that's all the app has),
// right click opens the menu, middle click is the app's secondary action.
Row {
    id: root
    property bool open: false

    // Papirus one-color panel icons instead of the apps' own colorful ones;
    // they follow the mode. Keys are tray item Ids:
    //   busctl --user get-property <service> /StatusNotifierItem org.kde.StatusNotifierItem Id
    readonly property string iconDir: "/home/suhaylmv/.local/state/theme/current/tray-icons/"
    readonly property var icons: ({
        "vesktop_status_icon_1": "discord-tray.svg",
        "TelegramDesktop": "telegram-panel.svg",
        "qBittorrent": "qbittorrent-tray.svg",
        "spotify-client": "spotify-linux-32.svg"
    })
    function iconFor(item) {
        const own = root.icons[item.id]
        // Qt caches images by URL and "current" points to the other mode
        // after a switch: the query makes each mode its own URL
        return own ? "file://" + iconDir + own + "?" + (Theme.dark ? "dark" : "light") : item.icon
    }

    // ---- the sliding part ----
    Item {
        id: drawer
        implicitHeight: root.height
        implicitWidth: root.open ? iconRow.implicitWidth : 0
        clip: true
        // fast start, long gentle stop (OutExpo); closes on a plain ease
        Behavior on implicitWidth {
            NumberAnimation {
                duration: root.open ? 420 : 280
                easing.type: root.open ? Easing.OutExpo : Easing.InOutCubic
            }
        }

        Row {
            id: iconRow
            anchors.right: parent.right     // slides out from the chevron
            height: parent.height
            // 10px between icons; the last one sits about as close to the
            // chevron (2px + its 7px padding), not Waybar's wide 10px + 7px
            leftPadding: 8
            rightPadding: 2
            spacing: 10

            Repeater {
                id: items
                model: SystemTray.items
                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index
                    implicitWidth: 16
                    implicitHeight: iconRow.height

                    // 0 = hidden, 1 = shown. Opening fades each icon in while it
                    // glides 8px into place, a few ms apart from the chevron
                    // outwards; closing fades them all back toward it.
                    property real t: root.open ? 1 : 0
                    Component.onCompleted: t = root.open ? 1 : 0
                    Connections {
                        target: root
                        function onOpenChanged() {
                            if (root.open) { hideAnim.stop(); showAnim.restart() }
                            else { showAnim.stop(); hideAnim.restart() }
                        }
                    }
                    SequentialAnimation {
                        id: showAnim
                        PauseAnimation { duration: 40 + (items.count - 1 - slot.index) * 30 }
                        NumberAnimation {
                            target: slot; property: "t"; to: 1
                            duration: 340; easing.type: Easing.OutCubic
                        }
                    }
                    NumberAnimation {
                        id: hideAnim
                        target: slot; property: "t"; to: 0
                        duration: 150; easing.type: Easing.InCubic
                    }

                    IconImage {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (1 - slot.t) * 8
                        implicitSize: 16
                        source: root.iconFor(slot.modelData)
                        opacity: slot.t
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        anchors.margins: -5          // the gaps count too
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: e => {
                            const item = slot.modelData
                            if (e.button === Qt.MiddleButton) item.secondaryActivate()
                            else if (e.button === Qt.RightButton || item.onlyMenu) {
                                if (item.hasMenu) trayMenu.toggle(slot, item.menu)
                            } else item.activate()
                        }
                        onWheel: w => slot.modelData.scroll(w.angleDelta.y / 120, false)
                    }

                    BarTooltip {
                        target: slot
                        hovered: mouse.containsMouse && !trayMenu.shown
                        text: slot.modelData.tooltipTitle || slot.modelData.title
                    }
                }
            }
        }
    }

    BarIcon {
        // turns to point right while open ("push them back in")
        icon: Icons.chevronLeft
        size: 17
        hoverAccent: true
        rotation: root.open ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        onClicked: { root.open = !root.open; if (!root.open) trayMenu.close() }
    }

    TrayMenu { id: trayMenu }
}

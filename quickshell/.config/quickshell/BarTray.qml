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
    // `unread` is used while the app signals unread messages: Telegram by
    // switching to an "...-attention" icon name, Vesktop (`probe`) only by
    // sending a different picture, so that one is checked for its red dot.
    readonly property var icons: ({
        "vesktop_status_icon_1": { normal: "discord-tray.svg", unread: "discord-tray-unread.svg", probe: true },
        "TelegramDesktop": { normal: "telegram-panel.svg", unread: "telegram-attention-panel.svg" },
        "qBittorrent": { normal: "qbittorrent-tray.svg" }
    })
    // Tray items not shown at all (same Ids). Spotify: the bar's now playing
    // already has its controls, and closing its window quits it anyway.
    readonly property var hidden: ["spotify-client"]
    function iconFor(item, unread) {
        const own = root.icons[item.id]
        if (!own) return item.icon
        const file = unread && own.unread ? own.unread : own.normal
        // Qt caches images by URL and "current" points to the other mode
        // after a switch: the query makes each mode its own URL
        return "file://" + iconDir + file + "?" + (Theme.dark ? "dark" : "light")
    }
    function probes(item) {
        const own = root.icons[item.id]
        return own !== undefined && own.probe === true
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
                    // a Row skips invisible items, spacing included
                    visible: !root.hidden.includes(modelData.id)
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

                    // Unread messages: the app asks for attention, its icon
                    // name says so, or (probe) its picture has a red dot
                    property bool dotted: false
                    readonly property bool unread:
                        modelData.status === Status.NeedsAttention
                        || /attention/.test(modelData.icon)
                        || dotted

                    IconImage {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: (1 - slot.t) * 8
                        implicitSize: 16
                        source: root.iconFor(slot.modelData, slot.unread)
                        opacity: slot.t
                    }

                    // Draws the app's own picture, invisibly, and counts
                    // strongly colored pixels: Vesktop's normal icon is
                    // grey, the unread one has a red dot (51 of 576 pixels).
                    // Quickshell gives every new picture a new URL.
                    Loader {
                        active: root.probes(slot.modelData)
                        sourceComponent: Canvas {
                            width: 24; height: 24
                            opacity: 0
                            readonly property string src: slot.modelData.icon
                            onSrcChanged: loadImage(src)
                            Component.onCompleted: loadImage(src)
                            onImageLoaded: requestPaint()
                            onPaint: {
                                if (!isImageLoaded(src)) return
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.drawImage(src, 0, 0, width, height)
                                const d = ctx.getImageData(0, 0, width, height).data
                                let colored = 0
                                for (let i = 0; i < d.length; i += 4) {
                                    const hi = Math.max(d[i], d[i + 1], d[i + 2])
                                    const lo = Math.min(d[i], d[i + 1], d[i + 2])
                                    if (d[i + 3] > 128 && hi - lo > 80) colored++
                                }
                                slot.dotted = colored >= 4
                            }
                        }
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

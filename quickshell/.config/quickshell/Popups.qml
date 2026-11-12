import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// New notifications in the top-right corner. They stay in the panel after
// the popup goes. Hidden while Do not disturb is on (critical ones still show).
// Cards slide in from the screen edge and back out (NotifListView.qml).
PanelWindow {
    id: win
    readonly property int gap: 7          // Hyprland gaps_out

    // The window runs to the screen edge (cards slide out past it) and is
    // tall enough for four cards, so it never resizes under an animation;
    // only the cards take clicks.
    // shows as soon as there's something to pop up; the cards are added
    // once it's on screen (`ready`), so even the first one slides in
    visible: list.busy || Notifs.popups.length > 0
    anchors.top: true
    anchors.right: true
    margins.top: gap
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: 400 + gap
    implicitHeight: 760
    color: "transparent"
    mask: Region { item: hit }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popups"

    Item {
        id: hit
        width: list.width
        height: Math.min(list.contentHeight, list.height)
    }

    NotifListView {
        id: list
        width: 400
        height: parent.height
        interactive: false
        ready: win.backingWindowVisible
        source: Notifs.popups.slice(0, 4)

        delegate: NotificationCard {
            id: popup
            required property int nid
            notif: list.objects[nid]
            floating: true
            width: list.width
            onActivated: { Notifs.activate(notif); Notifs.hidePopup(notif) }

            // keeps a dismissed notification alive until its card is gone
            RetainableLock { object: popup.notif; locked: true }

            // 4s low, 6s normal, critical stays; paused on hover
            Timer {
                interval: popup.notif.urgency === NotificationUrgency.Low ? 4000 : 6000
                running: !popup.critical && !popup.hovered
                onTriggered: Notifs.hidePopup(popup.notif)
            }
        }
    }
}

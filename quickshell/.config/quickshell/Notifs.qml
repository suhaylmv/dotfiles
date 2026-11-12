pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon plus shared state: panel open, Do not disturb, popups.
Singleton {
    id: root

    property bool panelOpen: false
    property bool dnd: false

    // Every notification stays here until dismissed; newest first.
    readonly property var all: server.trackedNotifications.values.slice().reverse()
    readonly property int count: all.length

    // Ids currently shown as popups (they stay in `all` after the popup goes)
    property var popupIds: []
    readonly property var popups: all.filter(n => popupIds.includes(n.id))

    // When each notification arrived (id -> ms), for "5 min" labels. Kept
    // across reloads like the notifications themselves (keepOnReload), as a
    // JSON string: a JS object can't move to the reloaded config's engine.
    PersistentProperties {
        id: kept
        reloadableId: "notifs"
        property string receivedJson: "{}"
        // loaded: first start and after each reload (the old value is back)
        onLoaded: {
            try { root.received = JSON.parse(receivedJson) || {} } catch (e) { root.received = {} }
        }
    }
    property var received: ({})
    property date now: new Date()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            // keepOnReload hands every kept notification back through here
            // after a reload (saving any Quickshell file): back in the panel,
            // but no popup or sound, they aren't new
            if (n.lastGeneration) return
            root.received[n.id] = Date.now()
            kept.receivedJson = JSON.stringify(root.received)
            const critical = n.urgency === NotificationUrgency.Critical
            if (!root.panelOpen && (!root.dnd || critical))
                root.popupIds = [n.id].concat(root.popupIds.filter(i => i !== n.id))
            // silent in Do not disturb, except critical
            if (!root.dnd || critical) Sounds.notify(n)
        }
    }

    function hidePopup(n) { popupIds = popupIds.filter(i => i !== n.id) }
    function clearAll() { for (const n of all) n.dismiss() }

    // Click on a notification: run its default action if it has one
    function activate(n) {
        const def = n.actions.find(a => a.identifier === "default")
        if (def) { def.invoke(); return true }
        return false
    }

    function ago(n) {
        const t = received[n.id]
        if (!t) return ""
        const min = Math.floor((now - t) / 60000)
        if (min < 1) return "now"
        if (min < 60) return min + " min"
        const h = Math.floor(min / 60)
        return h < 24 ? h + " h" : Math.floor(h / 24) + " d"
    }

    // When it last closed: clicking the bell while the panel is open first
    // closes it (click outside), then the bell's toggle must not reopen it.
    property double closedAt: 0
    function togglePanel() {
        if (!panelOpen && Date.now() - closedAt < 400) return
        panelOpen = !panelOpen
    }
    onPanelOpenChanged: {
        if (panelOpen) popupIds = []      // the panel shows them all
        else closedAt = Date.now()
    }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.togglePanel() }
        function open(): void { root.panelOpen = true }
        function close(): void { root.panelOpen = false }
        function toggleDnd(): void { root.dnd = !root.dnd }
        function clearNotifs(): void { root.clearAll() }
    }
}

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspace dots for this bar's monitor: filled = active. 1-8 are
// persistent (hyprland.lua), so they always show; scratchpads don't.
// Click switches; hover turns a dot accent.
Row {
    id: root
    required property ShellScreen screen
    readonly property var monitor: Hyprland.monitorFor(screen)

    // Waybar: module padding 1px 4px 0 4px, buttons 0 4px
    leftPadding: 4
    rightPadding: 4

    Repeater {
        model: Hyprland.workspaces.values
            .filter(w => w.id > 0 && w.monitor === root.monitor)
            .sort((a, b) => a.id - b.id)

        delegate: Item {
            id: button
            required property var modelData
            // GTK buttons are at least 16px wide, plus 4px padding each side
            implicitWidth: Math.max(16, dot.implicitWidth) + 8
            implicitHeight: root.height

            Glyph {
                id: dot
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0.5     // the module's 1px top padding
                text: button.modelData.active ? Icons.wsActive : Icons.wsEmpty
                size: 15
                color: mouse.containsMouse ? Theme.accent : Theme.fg
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: button.modelData.activate()
            }
        }
    }
}

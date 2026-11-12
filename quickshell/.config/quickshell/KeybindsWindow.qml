import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Keybind cheat sheet (SUPER+?): drops down under the bar like the launcher.
// Three columns of sections; each row is its key chips, then what it does.
// Esc, a click outside or SUPER+? again closes it. Data: Keybinds.qml.
PanelWindow {
    id: win
    visible: pop.live                 // stays up while it animates closed
    anchors.top: true                 // only top: centered horizontally
    margins.top: 8                    // same spot as the panel and the launcher
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: card.width
    implicitHeight: card.height
    color: "transparent"
    // while closing: clicks go through and keys go back to the windows
    mask: Region { item: Keybinds.open ? card : null }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-keybinds"
    WlrLayershell.keyboardFocus: Keybinds.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None   // for Esc

    readonly property int pad: 24
    readonly property int columnGap: 36
    readonly property int rowHeight: 30
    readonly property int chipHeight: 24

    HyprlandFocusGrab {
        active: Keybinds.open
        windows: [win]
        onCleared: Keybinds.close()
    }

    // on open (also when reopened while still closing)
    readonly property bool shown: Keybinds.open
    onShownChanged: if (shown) keys.forceActiveFocus()

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: Keybinds.close()
    }

    Pop {
        id: pop
        shown: Keybinds.open
        target: card

        Surface {
            id: card
            x: (win.width - width) / 2
            width: cols.implicitWidth + win.pad * 2
            height: cols.implicitHeight + win.pad * 2 - 6
            radius: 32                           // the panel's


            Row {
                id: cols
                x: win.pad
                y: win.pad - 4
                spacing: win.columnGap

                Repeater {
                    model: Keybinds.columns
                    delegate: Column {
                        id: column
                        required property var modelData
                        spacing: 18

                        Repeater {
                            model: column.modelData
                            delegate: Column {
                                id: section
                                required property var modelData
                                spacing: 0
                                // the widest key area in this section, so its
                                // descriptions line up
                                property real keyWidth: 0

                                Text {
                                    height: 26
                                    verticalAlignment: Text.AlignTop
                                    text: section.modelData.title
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: Theme.accent
                                }

                                Repeater {
                                    model: section.modelData.rows
                                    delegate: Row {
                                        id: row
                                        required property var modelData
                                        height: win.rowHeight
                                        spacing: 14

                                        // key chips: Super Shift [1 2 3 4], several chords joined by "or"
                                        Item {
                                            width: section.keyWidth
                                            height: parent.height
                                            Row {
                                                id: chords
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6
                                                onImplicitWidthChanged: section.keyWidth = Math.max(section.keyWidth, implicitWidth)
                                                Repeater {
                                                    model: row.modelData.chords
                                                    delegate: Row {
                                                        id: chord
                                                        required property var modelData
                                                        required property int index
                                                        spacing: 4
                                                        Text {
                                                            visible: chord.index > 0
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            rightPadding: 2
                                                            text: "or"
                                                            font.family: Theme.font
                                                            font.pixelSize: 12
                                                            color: Theme.muted
                                                        }
                                                        Repeater {
                                                            // modifiers, then all the keys in one chip
                                                            model: chord.modelData.mods.concat([chord.modelData.keys.join("  ")])
                                                            delegate: Rectangle {
                                                                required property string modelData
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                width: Math.max(win.chipHeight, label.implicitWidth + 16)
                                                                height: win.chipHeight
                                                                radius: 8
                                                                color: Theme.surface
                                                                border.width: 1
                                                                border.color: Theme.overlay
                                                                Text {
                                                                    id: label
                                                                    anchors.centerIn: parent
                                                                    text: parent.modelData
                                                                    font.family: Theme.font
                                                                    font.pixelSize: 12
                                                                    font.weight: Font.Medium
                                                                    color: Theme.fgStrong
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: row.modelData.text
                                            font.family: Theme.font
                                            font.pixelSize: 13
                                            color: Theme.fg
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

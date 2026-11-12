import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets

// A tray app's menu, drawn in the theme (Qt's own menus ignore it).
// Opens under the icon; submenus open in place with a Back row on top.
// Click outside or Esc closes it. Opens and closes like the other popups
// (Pop.qml), with a shorter drop.
PopupWindow {
    id: menu
    property Item target: null        // the tray icon it hangs from
    property var handle: null         // the app's root menu
    property var stack: []            // submenus opened, innermost last
    readonly property var current: stack.length ? stack[stack.length - 1] : handle

    // clicking the same icon to close it first clears the grab (menu closes),
    // then the click would reopen it: ignore reopening right after closing
    property Item closedFrom: null
    property double closedAt: 0

    // open; the window stays up a moment longer while it animates closed
    property bool shown: false
    visible: pop.live

    function toggle(item, h) {
        if (shown && target === item) { close(); return }
        if (!shown && closedFrom === item && Date.now() - closedAt < 400) return
        target = item
        handle = h
        stack = []
        shown = true
    }
    function close() {
        if (!shown) return
        closedFrom = target
        closedAt = Date.now()
        shown = false
    }

    anchor.item: target
    anchor.rect.x: target ? target.width / 2 : 0
    // the window starts `room` px above the card, so the card's drop isn't
    // cut off at the window's top edge; only the card takes the mouse
    readonly property int room: 6
    anchor.rect.y: target ? target.height + 6 - room : 0
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: card.width
    implicitHeight: card.height + room
    color: "transparent"
    mask: Region { item: menu.shown ? card : null }

    onShownChanged: if (shown) card.forceActiveFocus()

    HyprlandFocusGrab {
        active: menu.shown
        windows: [menu]
        onCleared: menu.close()
    }

    QsMenuOpener { id: opener; menu: menu.current }

    Pop {
        id: pop
        shown: menu.shown
        target: card
        dropIn: menu.room
        dropOut: 3

        Surface {
            id: card
            y: menu.room
            readonly property int pad: 6
            width: Math.min(360, Math.max(180, list.implicitWidth + pad * 2))
            height: list.implicitHeight + pad * 2
            radius: 10 + pad
            focus: true
            Keys.onEscapePressed: menu.close()

            ColumnLayout {
                id: list
                x: card.pad
                y: card.pad
                width: card.width - card.pad * 2
                spacing: 0

                // ---- back to the parent menu ----
                MenuRow {
                    visible: menu.stack.length > 0
                    lead: Icons.chevronLeft
                    label: "Back"
                    muted: true
                    onActivated: menu.stack = menu.stack.slice(0, -1)
                }
                Rectangle {
                    visible: menu.stack.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    implicitHeight: 1
                    color: Theme.overlay
                }

                Repeater {
                    model: opener.children
                    delegate: Loader {
                        id: entryLoader
                        required property var modelData
                        Layout.fillWidth: true
                        sourceComponent: modelData.isSeparator ? separator : row

                        Component {
                            id: separator
                            Item {
                                implicitHeight: 9
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 1
                                    color: Theme.overlay
                                }
                            }
                        }
                        Component {
                            id: row
                            MenuRow {
                                readonly property var entry: entryLoader.modelData
                                // checkboxes and radio buttons: a check when on
                                lead: entry.buttonType !== QsMenuButtonType.None
                                      ? (entry.checkState === Qt.Checked ? Icons.check : " ") : ""
                                iconSource: entry.icon
                                // DBus menus mark mnemonics with "_" ("__" is a real one)
                                label: entry.text.replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
                                trail: entry.hasChildren ? Icons.chevronRight : ""
                                enabled: entry.enabled
                                onActivated: {
                                    if (entry.hasChildren) { menu.stack = menu.stack.concat([entry]); return }
                                    entry.triggered()
                                    menu.close()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: r
        property string lead: ""
        property string iconSource: ""
        property string label: ""
        property string trail: ""
        property bool muted: false
        signal activated()

        Layout.fillWidth: true
        implicitWidth: content.implicitWidth + 20
        implicitHeight: 30
        radius: 10
        color: hover.containsMouse && enabled ? Theme.overlay : "transparent"
        opacity: enabled ? 1 : 0.45

        Row {
            id: content
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Glyph {
                visible: r.lead !== ""
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                text: r.lead
                size: 16
                color: r.muted ? Theme.muted : Theme.accent
            }
            IconImage {
                visible: r.iconSource !== ""
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: r.iconSource
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: r.label
                textFormat: Text.PlainText
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
                color: r.muted ? Theme.muted : Theme.fg
            }
            // room for the submenu chevron
            Item { visible: r.trail !== ""; width: 22; height: 1 }
        }
        Glyph {
            visible: r.trail !== ""
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: r.trail
            size: 16
            color: Theme.muted
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (r.enabled) r.activated()
        }
    }
}

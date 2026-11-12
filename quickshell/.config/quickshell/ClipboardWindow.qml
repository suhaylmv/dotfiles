import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// Clipboard history (SUPER+SHIFT+V, the launcher's >clipboard). Drops down
// under the bar like the launcher: search on top, the history on the left
// (pinned first), the selected entry in full on the right.
// Enter copies and closes, Ctrl+P pins, Ctrl+D removes. Logic: Clipboard.qml.
PanelWindow {
    id: win
    visible: pop.live                 // stays up while it animates closed
    anchors.top: true                 // only top: centered horizontally
    margins.top: 8                    // same spot as the panel and the launcher
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    implicitWidth: 900
    implicitHeight: card.height
    color: "transparent"
    // while closing: clicks go through and keys go back to the windows
    mask: Region { item: Clipboard.open ? card : null }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: Clipboard.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int pad: 8
    readonly property int searchHeight: 46    // the launcher's search pill
    readonly property int rowHeight: 44
    readonly property int rowSpacing: 2
    readonly property int maxRows: 8
    readonly property int listWidth: 360
    readonly property int bodyHeight: maxRows * rowHeight + (maxRows - 1) * rowSpacing

    readonly property var items: Clipboard.filter(input.text)
    readonly property var current: items[list.currentIndex] ?? null
    property double now: Date.now()           // for the ages; set on open

    HyprlandFocusGrab {
        active: Clipboard.open
        windows: [win]
        onCleared: Clipboard.close()
    }

    // on open (also when reopened while still closing)
    readonly property bool shown: Clipboard.open
    onShownChanged: if (shown) {
        input.text = ""
        list.currentIndex = 0
        now = Date.now()
        input.forceActiveFocus()
    }
    onItemsChanged: list.currentIndex = Math.min(list.currentIndex, Math.max(0, items.length - 1))

    function move(step) {
        if (list.count === 0) return
        list.currentIndex = (list.currentIndex + step + list.count) % list.count
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }
    function copyCurrent() {
        if (!current) return
        Clipboard.copy(current)
        Clipboard.close()
    }

    Pop {
        id: pop
        shown: Clipboard.open
        target: card

        Surface {
            id: card
            x: (win.width - width) / 2
            width: win.width
            height: win.pad * 3 + win.searchHeight + win.bodyHeight
            radius: 31                           // search pill radius 23 + 8


            // ---- search pill ----
            Rectangle {
                id: search
                x: win.pad
                y: win.pad
                width: parent.width - win.pad * 2
                height: win.searchHeight
                radius: height / 2
                color: Theme.surface

                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    x: (search.height - width) / 2
                    text: Icons.clipboard
                    size: 20
                    color: Theme.muted
                }

                TextInput {
                    id: input
                    anchors.left: parent.left
                    anchors.right: hint.left
                    anchors.leftMargin: search.height
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: Theme.fgStrong
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.textOnAccent
                    clip: true

                    Text {
                        visible: !input.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search clipboard"
                        font: input.font
                        color: Theme.muted
                    }

                    Keys.onPressed: e => {
                        const ctrl = e.modifiers & Qt.ControlModifier
                        const k = e.key
                        if (k === Qt.Key_Down || k === Qt.Key_Tab || (ctrl && (k === Qt.Key_N || k === Qt.Key_J))) win.move(1)
                        else if (k === Qt.Key_Up || k === Qt.Key_Backtab || (ctrl && k === Qt.Key_K)) win.move(-1)
                        else if (k === Qt.Key_Return || k === Qt.Key_Enter) win.copyCurrent()
                        else if (ctrl && k === Qt.Key_P) { if (win.current) Clipboard.togglePin(win.current) }
                        else if (ctrl && k === Qt.Key_D) { if (win.current) Clipboard.remove(win.current) }
                        else if (k === Qt.Key_Escape) Clipboard.close()
                        else return
                        e.accepted = true
                    }
                }

                Text {
                    id: hint
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter: copy  ·  Ctrl+P: pin  ·  Ctrl+D: delete"
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: Theme.muted
                }
            }

            // ---- the list ----
            Item {
                id: body
                x: win.pad
                y: win.pad * 2 + win.searchHeight
                width: win.listWidth
                height: win.bodyHeight

                Text {
                    visible: list.count === 0
                    anchors.centerIn: parent
                    text: Clipboard.entries.length ? "No matches" : "Clipboard history is empty"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.muted
                }

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: win.rowSpacing
                    model: win.items
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool selected: ListView.isCurrentItem
                        readonly property color ink: selected ? Theme.textOnAccent : Theme.fgStrong

                        width: list.width
                        height: win.rowHeight
                        radius: height / 2
                        color: selected ? Theme.accent : "transparent"

                        // text starts at the left edge (images say "Image"; the
                        // preview pane shows the picture)
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.right: when.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.line
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: row.ink
                        }
                        // age, or a pin for pinned entries
                        Text {
                            id: when
                            readonly property bool pinned: row.modelData.pinned
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: pinned ? Icons.pin : (win.now, Clipboard.age(row.modelData.recorded))
                            font.family: pinned ? Theme.iconFont : Theme.font   // nf-md-pin
                            font.pixelSize: pinned ? 15 : 12
                            color: row.selected ? Theme.textOnAccent : pinned ? Theme.accent : Theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: list.currentIndex = row.index
                            // the clicked row, not the highlighted one: the highlight
                            // only follows real pointer moves (not the wheel)
                            onClicked: { Clipboard.copy(row.modelData); Clipboard.close() }
                        }
                    }
                }
            }

            // ---- the selected entry in full ----
            Rectangle {
                id: preview
                anchors.left: body.right
                anchors.leftMargin: win.pad
                anchors.right: parent.right
                anchors.rightMargin: win.pad
                y: body.y
                height: win.bodyHeight
                radius: 23
                color: Theme.surface
                visible: win.current !== null

                readonly property var e: win.current
                readonly property bool isImage: !!e && !!e.image

                // text: as copied, in the monospace font (mostly code and commands)
                Text {
                    visible: !preview.isImage
                    anchors.fill: parent
                    anchors.margins: 18
                    anchors.bottomMargin: 40
                    text: preview.e && !preview.isImage ? preview.e.value : ""
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    elide: Text.ElideRight
                    font.family: Theme.iconFont
                    font.pixelSize: 13
                    color: Theme.fgStrong
                    clip: true
                }

                // image: fitted, rounded
                ClippingRectangle {
                    visible: preview.isImage
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -10
                    readonly property real boxW: preview.width - 36
                    readonly property real boxH: preview.height - 76
                    readonly property real ratio: big.implicitHeight > 0 ? big.implicitWidth / big.implicitHeight : 16 / 10
                    width: Math.min(boxW, boxH * ratio)
                    height: width / ratio
                    radius: 12
                    color: Theme.overlay
                    Image {
                        id: big
                        anchors.fill: parent
                        source: preview.isImage ? "file://" + preview.e.image : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        mipmap: true
                    }
                }

                // what it is and when
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    spacing: 8
                    Glyph {
                        visible: preview.e?.pinned ?? false
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.pin
                        size: 14
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            const e = preview.e
                            if (!e) return ""
                            let what
                            if (preview.isImage) {
                                what = big.status === Image.Ready
                                    ? "Image  " + big.sourceSize.width + "×" + big.sourceSize.height : "Image"
                            } else {
                                const lines = e.value.split("\n").length
                                what = e.value.length + " characters" + (lines > 1 ? "  ·  " + lines + " lines" : "")
                            }
                            const a = (win.now, Clipboard.age(e.recorded))
                            return what + "  ·  " + (a === "now" ? "just now" : a + " ago")
                        }
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.muted
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell

// Waybar-style tooltip under a bar item: surface card with a thin overlay
// border and 13px text, after a short hover delay. Set `body` to show
// something other than text (the date's calendar). Opens and closes like
// the other popups (Pop.qml), with a shorter drop.
PopupWindow {
    id: tip
    required property Item target
    property bool hovered: false
    property string text: ""
    property Component body: textBody
    property real radius: 10
    property real padding: 0

    readonly property bool wanted: hovered && (text !== "" || body !== textBody)
    property bool shown: false
    onWantedChanged: {
        if (wanted) delay.restart()
        else { delay.stop(); shown = false }
    }
    Timer { id: delay; interval: 400; onTriggered: tip.shown = true }
    visible: pop.live                 // stays up while it animates closed

    // centered under the item, a little below the bar. The window starts
    // `room` px higher than the card, so the card's drop isn't cut off at
    // the window's top edge; only the card takes the mouse.
    readonly property int room: 6
    anchor.item: target
    anchor.rect.x: target.width / 2
    anchor.rect.y: target.height + 6 - room
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide
    implicitWidth: card.width
    implicitHeight: card.height + room
    color: "transparent"
    mask: Region { item: card }

    Pop {
        id: pop
        shown: tip.shown
        target: card
        dropIn: tip.room
        dropOut: 3

        Rectangle {
            id: card
            y: tip.room
            width: loader.implicitWidth + tip.padding * 2
            height: loader.implicitHeight + tip.padding * 2
            radius: tip.radius
            color: Theme.surface
            border.width: 1
            border.color: Theme.overlay

            Loader {
                id: loader
                x: tip.padding
                y: tip.padding
                sourceComponent: tip.body
            }
        }
    }

    Component {
        id: textBody
        Text {
            // Waybar: 13px label with 2px 4px padding inside GTK's tooltip box
            leftPadding: 10; rightPadding: 10
            topPadding: 6; bottomPadding: 6
            text: tip.text
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.fg
            lineHeight: 1.1
        }
    }
}

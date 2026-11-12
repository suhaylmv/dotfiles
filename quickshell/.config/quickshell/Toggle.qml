import QtQuick

// Quick setting tile: icon over a short label. Filled with the accent when on.
Rectangle {
    id: tile
    property string icon
    property string label
    property bool active: false
    signal clicked()
    signal rightClicked()

    implicitHeight: 70
    radius: 22
    color: active ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.06) : Theme.accent)
                  : (mouse.containsMouse ? Theme.overlay : Theme.surface)
    Behavior on color { ColorAnimation { duration: 150 } }

    Column {
        anchors.centerIn: parent
        spacing: 4
        Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.icon
            size: 21
            color: tile.active ? Theme.textOnAccent : Theme.fg
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.label
            font.family: Theme.font
            font.pixelSize: 11
            font.weight: Font.Medium
            color: tile.active ? Theme.textOnAccent : Theme.muted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
    }
}

import QtQuick

// Thick pill slider: the filled part carries the icon. Click or drag anywhere
// to set, scroll to nudge by 5%, right-click for the secondary action.
Item {
    id: slider
    property real value: 0          // 0..1
    property string icon
    property bool dimmed: false     // grey fill, e.g. muted
    signal moved(real value)
    signal rightClicked()

    implicitHeight: 46

    function set(v) { slider.moved(Math.max(0, Math.min(1, v))) }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface

        Rectangle {
            id: fill
            height: parent.height
            radius: height / 2
            // never narrower than a circle, so the icon always sits inside it
            width: Math.max(height, parent.width * slider.value)
            color: slider.dimmed ? Theme.muted : Theme.accent
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on width { enabled: !mouse.pressed; NumberAnimation { duration: 120 } }
        }

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            x: (track.height - width) / 2
            text: slider.icon
            size: 20
            color: Theme.textOnAccent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20
            text: Math.round(slider.value * 100) + "%"
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.Medium
            // readable on the fill or on the track, whichever it's over
            color: fill.width > track.width - 56 ? Theme.textOnAccent : Theme.muted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: e => { if (e.button === Qt.LeftButton) slider.set(e.x / width) }
        onPositionChanged: e => { if (pressedButtons & Qt.LeftButton) slider.set(e.x / width) }
        onClicked: e => { if (e.button === Qt.RightButton) slider.rightClicked() }
        onWheel: w => slider.set(slider.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}

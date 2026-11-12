import QtQuick

// One icon module in the bar: a Nerd Font glyph with Waybar's per-module
// padding, an optional accent on hover, a tooltip and click handlers.
Item {
    id: root
    property string icon: ""
    property real size: 17
    property color color: Theme.fg
    property bool hoverAccent: false
    property real padLeft: 7
    property real padRight: 7
    property string tip: ""
    readonly property bool hovered: mouse.containsMouse

    signal clicked()
    signal rightClicked()
    signal middleClicked()

    implicitWidth: padLeft + glyph.implicitWidth + padRight
    implicitHeight: parent ? parent.height : 38

    Glyph {
        id: glyph
        x: root.padLeft
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        size: root.size
        color: root.hoverAccent && mouse.containsMouse ? Theme.accent : root.color
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: e => {
            if (e.button === Qt.RightButton) root.rightClicked()
            else if (e.button === Qt.MiddleButton) root.middleClicked()
            else root.clicked()
        }
    }

    BarTooltip { target: root; hovered: root.hovered; text: root.tip }
}

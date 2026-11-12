import QtQuick

// A Nerd Font icon. Icons have no bold (faked bold smears them).
Text {
    property real size: 20
    font.family: Theme.iconFont
    font.pixelSize: size
    font.weight: Font.Normal
    color: Theme.fg
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}

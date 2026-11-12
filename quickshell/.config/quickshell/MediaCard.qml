import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

// What's playing (any MPRIS player: Spotify, browsers, mpv...).
// One row: art | title + artist (centered) | previous, play/pause, next.
Rectangle {
    id: card
    // the same player as the bar (Media.qml)
    readonly property var player: Media.player

    implicitHeight: 84
    radius: 24
    color: Theme.surface

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 12
        visible: card.player !== null

        ClippingRectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            Layout.alignment: Qt.AlignVCenter
            radius: 14
            color: Theme.overlay
            Image {
                anchors.fill: parent
                source: card.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 152
                sourceSize.height: 152
            }
            Glyph {
                anchors.centerIn: parent
                visible: !(card.player?.trackArtUrl)
                text: Icons.music
                size: 28
                color: Theme.muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: card.player?.trackTitle || card.player?.identity || ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.fgStrong
            }
            Text {
                Layout.fillWidth: true
                text: card.player?.trackArtist || card.player?.identity || ""
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.muted
            }
        }

        // previous, play/pause, next
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            Repeater {
                model: [
                    { icon: Icons.previous, main: false, act: () => card.player.previous(), ok: card.player?.canGoPrevious },
                    { icon: card.player?.isPlaying ? Icons.pause : Icons.play, main: true, act: () => card.player.togglePlaying(), ok: card.player?.canTogglePlaying },
                    { icon: Icons.next, main: false, act: () => card.player.next(), ok: card.player?.canGoNext }
                ]
                delegate: Rectangle {
                    required property var modelData
                    implicitWidth: modelData.main ? 38 : 30
                    implicitHeight: implicitWidth
                    radius: width / 2
                    opacity: modelData.ok ? 1 : 0.4
                    color: modelData.main ? Theme.accent : (btn.containsMouse ? Theme.overlay : "transparent")
                    Glyph {
                        anchors.centerIn: parent
                        text: modelData.icon
                        size: modelData.main ? 20 : 18
                        color: modelData.main ? Theme.textOnAccent : Theme.fg
                    }
                    MouseArea {
                        id: btn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (modelData.ok) modelData.act()
                    }
                }
            }
        }
    }

    // nothing playing
    Row {
        anchors.centerIn: parent
        spacing: 10
        visible: card.player === null
        Glyph { text: Icons.music; size: 20; color: Theme.muted }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Nothing playing"
            font.family: Theme.font
            font.pixelSize: 13
            color: Theme.muted
        }
    }
}

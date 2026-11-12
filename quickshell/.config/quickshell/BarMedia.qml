import QtQuick
import Quickshell.Services.Mpris

// Now playing, like Waybar's mpris module: a note while playing, a pause
// sign while paused, then "title - artist" cut to 50 characters (no album,
// no track time). Hidden when nothing plays.
// Click: play/pause; middle click: previous; right click: next.
Item {
    id: root
    readonly property var player: Media.player
    readonly property bool shown: player !== null && player.playbackState !== MprisPlaybackState.Stopped
    readonly property int maxLength: 50

    visible: shown
    // Waybar: padding 0 8px, 12px on the left
    implicitWidth: shown ? 12 + row.implicitWidth + 8 : 0
    implicitHeight: parent ? parent.height : 38

    readonly property string main: {
        if (!player) return ""
        const s = [player.trackTitle || player.identity, player.trackArtist]
            .filter(p => p).join(" - ")
        // by code point, so an emoji isn't cut in half. Qt's JavaScript has
        // no trimEnd(): an error here would freeze the text on the old track
        const chars = Array.from(s)
        return chars.length > maxLength
            ? chars.slice(0, maxLength - 1).join("").replace(/\s+$/, "") + "…" : s
    }

    Row {
        id: row
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.player?.isPlaying ? Icons.music : Icons.pause
            size: 13
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: root.main
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.Bold
            color: Theme.fg
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: e => {
            const p = root.player
            if (!p) return
            if (e.button === Qt.MiddleButton) { if (p.canGoPrevious) p.previous() }
            else if (e.button === Qt.RightButton) { if (p.canGoNext) p.next() }
            else if (p.canTogglePlaying) p.togglePlaying()
        }
    }

    BarTooltip {
        target: root
        hovered: mouse.containsMouse
        // "Firefox (Paused) title - artist", uncut
        text: root.player ? root.player.identity + " (" + (root.player.isPlaying ? "Playing" : "Paused") + ") "
              + [root.player.trackTitle, root.player.trackArtist, root.player.trackAlbum].filter(p => p).join(" - ") : ""
    }
}

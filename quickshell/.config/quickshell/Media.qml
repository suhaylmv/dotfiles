pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Which MPRIS player the bar and the panel's media card show: the one
// playing, else the last one that played, else the first that isn't stopped.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var last: null

    readonly property var player: players.find(p => p.isPlaying)
        ?? (players.includes(last) ? last : null)
        ?? players.find(p => p.playbackState !== MprisPlaybackState.Stopped)
        ?? players[0] ?? null

    // remember whichever started playing last
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() { if (modelData.isPlaying) root.last = modelData }
        }
    }
}

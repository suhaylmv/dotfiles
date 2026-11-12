pragma Singleton
import QtQuick
import Quickshell

// Feedback sounds, played with pw-play (PipeWire), all from Plasma's Ocean
// theme (kdePackages.ocean-sound-theme in configuration.nix; xdg.sounds links
// it into /run/current-system/sw/share/sounds). Settings first: any
// .oga/.ogg/.wav works. To listen to every installed sound (plays as you
// move, Ctrl+R replays, Enter prints the path), in a terminal:
//   find -L /run/current-system/sw/share/sounds ~/.local/share/sounds -type f \
//     \( -name '*.oga' -o -name '*.ogg' -o -name '*.wav' \) |
//     sed 's|^\(.*/share/sounds/\(.*\)\)$|\2\t\1|' | sort |
//     fzf --delimiter='\t' --with-nth=1 \
//       --bind 'focus:execute-silent(pkill -x pw-play; pw-play {2} &)' \
//       --bind 'ctrl-r:execute-silent(pw-play {2} &)' | cut -f2
// Other packs to try without installing: `nix build --no-link nixpkgs#<pkg>`
// (cosmic-sound-theme, lomiri.lomiri-sounds, kdePackages.oxygen-sounds,
// pantheon.elementary-sound-theme, yaru-theme), then point find at the
// printed store path.
Singleton {
    id: root

    // ---- settings ----
    readonly property string dir: "/run/current-system/sw/share/sounds/ocean/stereo/"
    property string notificationSound: dir + "device-added.oga"
    property string volumeSound: dir + "audio-volume-change.oga"
    property string batteryLowSound: dir + "battery-low.oga"   // at 15%, see Battery.qml
    // loudness per sound, 0-1 (pw-play --volume: linear, 0.5 = -6 dB)
    property real notificationLevel: 0.1               // owner set it (for Soft delay); file unmodified
    property real volumeLevel: 0.4                     // the click was too loud at 1
    property real batteryLowLevel: 1.0
    // Play both channels to both ears (measured equal), for sounds mixed to
    // one side; makes them softer. Off: device-added is nearly balanced
    // (right +1 dB). Ocean's message-highlight needed it (right +9 dB). Stereo only.
    property bool centerNotification: false
    property bool notificationsOn: true
    property bool volumeOn: true
    property bool batteryOn: true
    // apps that already play their own sound (match the notification's appName)
    property var quietApps: []
    // The kernel powers the sound chip down after ~10s of silence (power
    // saving, kept on purpose). Waking it takes a moment, and the start of a
    // short sound got cut. So when it's asleep, a silent copy (volume 0)
    // wakes it first and the real sound starts wakeDelay ms later. When it's
    // awake, sounds play at once.
    property int wakeDelay: 300
    readonly property string chipState: "/sys/bus/hdaudio/devices/hdaudioC1D0/power/runtime_status"

    // ---- playing ----
    // center: label both channels front-center, so PipeWire sends each one to
    // both speakers (pw-play can't downmix a file to mono itself)
    function play(file, level, center) {
        const opts = ["--volume", String(level ?? 1)]
        if (center) opts.push("--channel-map", "FC,FC")
        // sh args: $1 file, $2 delay in seconds, the rest are pw-play options
        Quickshell.execDetached(["sh", "-c",
            'f=$1; d=$2; shift 2\n' +
            'if [ "$(cat ' + chipState + ' 2>/dev/null)" = suspended ]; then\n' +
            '  pw-play --volume 0 "$f" & sleep "$d"\n' +
            'fi\n' +
            'exec pw-play "$@" "$f"',
            "sh", file, String(wakeDelay / 1000)].concat(opts))
    }

    // A held volume key repeats about 25 times a second, and a burst of
    // notifications can arrive at once: at most one sound per gap.
    property double lastVolume: 0
    function volumeStep() {
        if (!volumeOn || Date.now() - lastVolume < 120) return
        lastVolume = Date.now()
        play(volumeSound, volumeLevel)
    }

    function batteryLow() { if (batteryOn) play(batteryLowSound, batteryLowLevel) }

    property double lastNotification: 0
    function notify(n) {
        if (!notificationsOn || quietApps.includes(n.appName)) return
        const hints = n.hints || {}
        if (hints["suppress-sound"]) return
        if (Date.now() - lastNotification < 500) return
        lastNotification = Date.now()
        // an app can ask for its own sound (played as is: it may be mono)
        if (hints["sound-file"]) play(hints["sound-file"], notificationLevel)
        else if (hints["sound-name"]) play(dir + hints["sound-name"] + ".oga", notificationLevel)
        else play(notificationSound, notificationLevel, centerNotification)
    }
}

pragma Singleton
import QtQuick
import Quickshell

// How popups open and close (Pop.qml: panel, launcher, clipboard, cheat
// sheet, OSD; Popups.qml: notification toasts). Opening decelerates into
// place; closing is a quick fade that starts at once and eases off, so a
// popup never stands in the way.
Singleton {
    readonly property int openMs: 220
    readonly property int closeMs: 160

    // Qt's format: x1, y1, x2, y2, 1, 1.
    // enter: Material 3's emphasized decelerate (= Hyprland's md3_decel).
    // exit: ease-out cubic. Fading needs an ease-out: an accelerating curve
    // keeps the card fully visible, then snaps it away at the end.
    readonly property var enter: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var exit: [0.33, 1, 0.68, 1, 1, 1]
}

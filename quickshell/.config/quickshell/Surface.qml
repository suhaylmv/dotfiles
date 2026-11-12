import QtQuick

// The card every popup sits on (OSD, launcher): bg with a thin overlay border,
// like the panel. Set the radius to the inner item's radius + its margin so
// the corners stay concentric.
Rectangle {
    color: Theme.bg
    border.width: 1
    border.color: Theme.overlay
}

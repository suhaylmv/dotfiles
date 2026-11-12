import QtQuick

// Opens and closes a popup. Put the window's card inside, point `target` at
// it, drive `shown`, and bind the window's visible to `live` (it stays true
// while the card animates out). Timings and curves: Motion.qml.
// Used by the panel, launcher, clipboard, cheat sheet, OSD, bar tooltips
// and the tray menu.
//   open:  drops 14px and grows from 96% at its top edge, fading in
//   close: fades out with just a hint of the same motion (rises 6px,
//          shrinks to 98%), so it dissolves rather than flies off
//
// Hyprland's own layer fade is off for these windows (no_anim layer rule in
// hyprland.lua), so this is the only animation they get.
Item {
    id: pop
    anchors.fill: parent

    property bool shown: false
    property Item target: null
    signal opened()                       // finished opening (not on close)

    // how far it travels: the full drop on the way in, a hint on the way out
    // (small popups like tooltips use less)
    property real dropIn: 14
    property real dropOut: 6

    // The three animate on their own (not as functions of one progress
    // value), so a popup reopened while closing, or closed while opening,
    // turns around from exactly where it is.
    property real dy: 0
    property real zoom: 1
    opacity: 0
    readonly property bool live: shown || opacity > 0

    ParallelAnimation {
        id: anim
        NumberAnimation { id: fadeTo; target: pop; property: "opacity"; easing.type: Easing.BezierSpline }
        NumberAnimation { id: dyTo; target: pop; property: "dy"; easing.type: Easing.BezierSpline }
        NumberAnimation { id: zoomTo; target: pop; property: "zoom"; easing.type: Easing.BezierSpline }
        onFinished: if (pop.shown) pop.opened()
    }
    function run() {
        anim.stop()
        // from fully closed, start from the top of the drop
        if (shown && opacity === 0) { dy = -dropIn; zoom = 0.96 }
        const ms = shown ? Motion.openMs : Motion.closeMs
        const curve = shown ? Motion.enter : Motion.exit
        fadeTo.to = shown ? 1 : 0
        dyTo.to = shown ? 0 : -dropOut
        zoomTo.to = shown ? 1 : 0.98
        for (const a of [fadeTo, dyTo, zoomTo]) { a.duration = ms; a.easing.bezierCurve = curve }
        anim.start()
    }
    onShownChanged: run()
    Component.onCompleted: if (shown) run()

    transform: [
        Scale {
            origin.x: pop.target ? pop.target.x + pop.target.width / 2 : pop.width / 2
            origin.y: pop.target ? pop.target.y : 0
            xScale: pop.zoom
            yScale: pop.zoom
        },
        Translate { y: pop.dy }
    ]
}

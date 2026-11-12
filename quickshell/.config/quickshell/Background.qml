import QtQuick
import Quickshell
import Quickshell.Wayland

// The desktop wallpaper, one window per screen on the background layer.
// Shows Wallpaper.shown. Each change stacks new layers on top: the cached
// 1280px thumbnail first (decodes in a few ms, so the picker's live preview
// reacts at once), then the full image, decoded off the UI thread at screen
// size. Each layer fades in when ready and removes what's under it once
// it's opaque. With no wallpaper set, the bg color shows.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property ShellScreen modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore      // full screen, under the bar too
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-wallpaper"
        color: Theme.bg

        // the screen's real pixels (2560x1600 at scale 1.33)
        readonly property size pixels: Qt.size(Math.ceil(width * devicePixelRatio),
                                               Math.ceil(height * devicePixelRatio))

        readonly property string target: Wallpaper.shown
        onTargetChanged: show(target)
        Component.onCompleted: show(target)

        function show(path) {
            // layers still loading are stale now: drop them
            for (const c of stack.children) if (!c.done) c.destroy()
            if (!path) {
                for (const c of stack.children) c.opacity = 0   // fade to bg, then destroyed
                return
            }
            // browsing in the picker: quicker fades, and the full image waits
            // until the selection rests, so holding an arrow key doesn't queue
            // a big decode per step
            const browsing = Wallpaper.preview !== ""
            const fade = browsing ? 220 : 500
            const thumb = Wallpaper.thumbs[path]
            if (thumb && thumb !== path)
                layer.createObject(stack, { file: thumb, fade: fade, full: false })
            layer.createObject(stack, { file: path, fade: fade, full: true, delay: browsing ? 150 : 0 })
        }

        Item { id: stack; anchors.fill: parent }

        Component {
            id: layer
            Image {
                id: img
                property string file
                property bool full: true             // false: a thumbnail, decoded as is
                property int fade: 500
                property int delay: 0                // ms before decoding starts
                property bool armed: delay === 0
                property bool done: false            // decoded and fading in (or in)

                anchors.fill: parent
                // encode each path segment: a "#" or "?" in a file name would
                // otherwise end the URL early
                source: armed ? "file://" + file.split("/").map(encodeURIComponent).join("/") : ""
                fillMode: Image.PreserveAspectCrop
                // Full images decode straight to the screen's real pixels.
                // Qt doesn't apply the 1.33 scale to sourceSize here (measured:
                // the logical size gave 1920px images), and 6K-8K originals
                // would otherwise sit in memory at full size.
                sourceSize: full ? win.pixels : undefined
                asynchronous: true
                cache: false                         // one copy per layer, freed with it
                smooth: true
                opacity: 0

                Timer { running: !img.armed; interval: img.delay; onTriggered: img.armed = true }

                onStatusChanged: {
                    if (status === Image.Ready && !done) { done = true; fadeIn.start() }
                    else if (status === Image.Error) destroy()
                }
                NumberAnimation on opacity {
                    id: fadeIn
                    running: false
                    to: 1; duration: img.fade; easing.type: Easing.InOutQuad
                    // opaque: everything below is hidden now
                    onFinished: {
                        for (const c of stack.children) { if (c === img) break; c.destroy() }
                    }
                }
                // fading out to the bg color (no wallpaper)
                Behavior on opacity {
                    enabled: !fadeIn.running
                    NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
                }
                onOpacityChanged: if (opacity === 0 && done && !fadeIn.running) destroy()
            }
        }
    }
}

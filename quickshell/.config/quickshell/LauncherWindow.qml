import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

// The launcher (CTRL+SPACE), the power tiles (SUPER+M, the panel's Power
// tile) and the wallpaper carousel (">wall", the panel's Wallpaper tile).
// Drops down under the bar like the panel; the card grows downward as
// results come in and widens for the carousel. Logic lives in Launcher.qml
// and Wallpaper.qml.
PanelWindow {
    id: win
    visible: pop.live                 // stays up while it animates closed
    anchors.top: true                 // only top: centered horizontally
    margins.top: 8                    // same spot as the panel and the OSD
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    // sized for the biggest card; only the card itself takes clicks (mask),
    // so the card can grow and shrink without resizing the window
    implicitWidth: wallWidth
    implicitHeight: Math.max(pad * 3 + searchHeight + maxRows * rowHeight + (maxRows - 1) * rowSpacing,
                             wallCardHeight)
    color: "transparent"
    // while closing: clicks go through and keys go back to the windows
    mask: Region { item: Launcher.open ? card : null }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int pad: 8
    readonly property int searchHeight: 46    // the PillSlider's height
    readonly property int rowHeight: 52       // 36px icon + 8px around
    readonly property int rowSpacing: 2
    readonly property int maxRows: 8
    readonly property int tileSize: 120
    readonly property int tileHeight: 96

    // ---- wallpaper carousel sizes ----
    readonly property int appsWidth: 560
    readonly property int wallWidth: 1040
    readonly property int chipHeight: 30
    readonly property int thumbWidth: 320         // the selected one; 16:10 like the screen
    readonly property int thumbHeight: 200
    readonly property int captionHeight: 20
    readonly property int wallCardHeight: pad + searchHeight + pad + chipHeight + 14
                                          + thumbHeight + 12 + captionHeight + pad + 4

    readonly property bool power: Launcher.mode === "power"
    readonly property bool commandMode: input.text.startsWith(">")
    // ">wall", ">wallpaper", ">wall city": the carousel, filtered by the rest
    readonly property var wallMatch: power ? null : input.text.match(/^>\s*wall\S*\s*(.*)$/)
    readonly property bool picking: wallMatch !== null
    readonly property string wallQuery: picking ? wallMatch[1] : ""
    readonly property var items: power || picking ? [] : Launcher.results(input.text)

    property string category: ""                  // "" = All
    readonly property var walls: picking ? Wallpaper.filter(wallQuery, category) : []

    // clicking anywhere else closes it
    HyprlandFocusGrab {
        active: Launcher.open
        windows: [win]
        onCleared: Launcher.close()
    }

    // on open (also when reopened while still closing)
    readonly property bool shown: Launcher.open
    onShownChanged: {
        if (shown) {
            settled = false
        } else {
            Wallpaper.preview = ""        // closed without Enter: back to the real one
        }
    }
    Connections {
        target: Launcher
        // every open goes through Launcher.show(), also a mode switch while
        // already open (SUPER+M over the search), so focus is set here
        function onReset() {
            const wasPicking = win.picking
            input.text = Launcher.mode === "wallpaper" ? ">wall " : ""
            list.currentIndex = 0
            tiles.current = 0
            // reopened on the carousel: picking stays true, so
            // onPickingChanged doesn't run the setup again
            if (wasPicking && win.picking) win.startPicking()
            if (win.power) tiles.forceActiveFocus(); else input.forceActiveFocus()
        }
    }
    onItemsChanged: list.currentIndex = 0

    // ---- carousel selection ----
    // selPath survives filtering: the selection stays on the same image while
    // it's still in the list
    property string selPath: ""
    onPickingChanged: {
        Launcher.picking = picking
        if (picking) {
            startPicking()
        } else {
            Wallpaper.preview = ""
        }
    }
    function startPicking() {
        category = ""
        selPath = Wallpaper.current       // opens centered on the one on screen
        Wallpaper.preview = ""
        Wallpaper.refresh()
        // after the walls binding has caught up with picking/category
        Qt.callLater(() => select(walls.findIndex(w => w.path === selPath), true))
    }
    // a new list (typing, a chip, the file list arriving) jumps; arrows slide
    onWallsChanged: if (picking) select(walls.findIndex(w => w.path === selPath), true)

    // The carousel loops: index i and i + n are the same place. step() moves
    // by k (Right on the last one goes on to the first); select() jumps to
    // an index (a filter result, a click), the short way round.
    function wrap(k, n) { const m = ((k % n) + n) % n; return m > n / 2 ? m - n : m }
    function select(i, snap) {
        const n = walls.length
        if (n === 0) { Wallpaper.preview = ""; return }
        i = Math.max(0, Math.min(i, n - 1))           // findIndex's -1 -> first
        const delta = snap ? 0 : wrap(i - strip.current, n)
        moveTo(i, snap ? i : strip.target + delta, snap)
    }
    function step(k) {
        const n = walls.length
        if (n > 1) moveTo(((strip.current + k) % n + n) % n, strip.target + k, false)
    }
    function moveTo(i, target, snap) {
        strip.current = i
        strip.slide(target, snap)
        selPath = walls[i].path
        // live preview on the desktop (nothing to do for the one on screen)
        if (shown) Wallpaper.preview = selPath === Wallpaper.current ? "" : selPath
    }
    function cycleCategory(n) {
        const all = [""].concat(Wallpaper.categories)
        category = all[(all.indexOf(category) + n + all.length) % all.length]
    }
    function keepWall(both) {
        if (!walls.length) return
        Wallpaper.apply(walls[strip.current].path, both)
        Launcher.close()
    }


    // Enter / click on a result: a command with `fill` (Wallpaper) types
    // into the search instead of running
    function choose(item) {
        if (item.fill) { input.text = item.fill; input.cursorPosition = input.text.length }
        else Launcher.run(item)
    }

    function move(step) {
        if (list.count === 0) return
        list.currentIndex = (list.currentIndex + step + list.count) % list.count
        list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }
    function activate() {
        if (list.count > 0) choose(items[list.currentIndex])
    }

    // the card's height only animates after it has opened at its first size
    property bool settled: false

    Pop {
        id: pop
        shown: Launcher.open
        target: card
        onOpened: win.settled = true

        Surface {
            id: card
            x: (win.width - width) / 2
            width: win.power ? tiles.width + win.pad * 2 : win.picking ? win.wallWidth : win.appsWidth
            height: win.power ? win.tileHeight + win.pad * 2
                  : win.picking ? win.wallCardHeight
                  : win.pad + win.searchHeight + (results.height > 0 ? win.pad + results.height : 0) + win.pad
            // concentric with what's inside: tile radius 24 / search pill 23, + 8
            radius: win.power ? 32 : 31
            clip: true
            Behavior on height {
                enabled: win.settled
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                enabled: win.settled
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // ================= apps and commands =================
            Item {
                visible: !win.power
                anchors.fill: parent
                anchors.margins: win.pad

                // search pill
                Rectangle {
                    id: search
                    width: parent.width
                    height: win.searchHeight
                    radius: height / 2
                    color: Theme.surface

                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        x: (search.height - width) / 2
                        text: win.picking ? Icons.wallpaper : win.commandMode ? Icons.command : Icons.search
                        size: 20
                        color: win.commandMode ? Theme.accent : Theme.muted
                    }

                    TextInput {
                        id: input
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: search.height
                        anchors.rightMargin: win.picking ? keysHint.width + 28 : 20
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.font
                        font.pixelSize: 15
                        color: Theme.fgStrong
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.textOnAccent
                        clip: true

                        Text {
                            visible: !input.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search apps, or > for commands"
                            font: input.font
                            color: Theme.muted
                        }

                        Keys.onPressed: e => {
                            const ctrl = e.modifiers & Qt.ControlModifier
                            if (win.picking) {
                                // the carousel takes the arrows (no cursor moving in
                                // the filter text) and Tab (folders)
                                const k = e.key
                                if (k === Qt.Key_Right || k === Qt.Key_Down
                                        || (ctrl && (k === Qt.Key_N || k === Qt.Key_J || k === Qt.Key_L))) win.step(1)
                                else if (k === Qt.Key_Left || k === Qt.Key_Up
                                        || (ctrl && (k === Qt.Key_P || k === Qt.Key_K || k === Qt.Key_H))) win.step(-1)
                                else if (k === Qt.Key_Tab) win.cycleCategory(1)
                                else if (k === Qt.Key_Backtab) win.cycleCategory(-1)
                                else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                                    win.keepWall(e.modifiers & Qt.ShiftModifier)
                                else if (k === Qt.Key_Escape) Launcher.close()
                                else return
                                e.accepted = true
                                return
                            }
                            if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab
                                    || (ctrl && (e.key === Qt.Key_N || e.key === Qt.Key_J))) {
                                win.move(1); e.accepted = true
                            } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab
                                    || (ctrl && (e.key === Qt.Key_P || e.key === Qt.Key_K))) {
                                win.move(-1); e.accepted = true
                            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                win.activate(); e.accepted = true
                            } else if (e.key === Qt.Key_Escape) {
                                Launcher.close(); e.accepted = true
                            }
                        }
                    }

                    // carousel keys, right side of the pill
                    Text {
                        id: keysHint
                        visible: win.picking
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enter: " + (Theme.dark ? "dark" : "light") + " mode  ·  Shift+Enter: both  ·  Tab: folder"
                        font.family: Theme.font
                        font.pixelSize: 12
                        color: Theme.muted
                    }
                }

                // results: up to 8 rows, then it scrolls
                Item {
                    id: results
                    visible: !win.picking
                    anchors.top: search.bottom
                    anchors.topMargin: win.pad
                    width: parent.width
                    readonly property int rows: Math.min(list.count, win.maxRows)
                    height: rows > 0 ? rows * win.rowHeight + (rows - 1) * win.rowSpacing
                                     : (input.text ? 40 : 0)    // "No matches"

                    Text {
                        visible: list.count === 0 && input.text !== ""
                        anchors.centerIn: parent
                        text: "No matches"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.muted
                    }

                    ListView {
                        id: list
                        anchors.fill: parent
                        clip: true
                        spacing: win.rowSpacing
                        model: win.items
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool selected: ListView.isCurrentItem
                            readonly property color ink: selected ? Theme.textOnAccent : Theme.fgStrong

                            width: list.width
                            height: win.rowHeight
                            radius: height / 2
                            color: selected ? Theme.accent : "transparent"

                            Item {
                                id: iconBox
                                x: 8
                                width: 36
                                height: 36
                                anchors.verticalCenter: parent.verticalCenter
                                Image {
                                    anchors.fill: parent
                                    visible: !!row.modelData.image
                                    source: row.modelData.image || ""
                                    sourceSize: Qt.size(72, 72)      // sharp at scale 1.33
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }
                                Glyph {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.glyph
                                    text: row.modelData.glyph || ""
                                    size: 22
                                    color: row.selected ? Theme.textOnAccent : Theme.fg
                                }
                            }

                            Text {
                                id: name
                                anchors.left: iconBox.right
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, row.width * 0.55)
                                text: row.modelData.name
                                elide: Text.ElideRight
                                font.family: Theme.font
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                color: row.ink
                            }
                            Text {
                                anchors.left: name.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.detail
                                elide: Text.ElideRight
                                font.family: Theme.font
                                font.pixelSize: 13
                                color: row.selected ? Theme.textOnAccent : Theme.muted
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // only a real mouse move selects, not rows sliding
                                // under a resting pointer while you type
                                onPositionChanged: list.currentIndex = row.index
                                onClicked: win.choose(row.modelData)
                            }
                        }
                    }
                }
            }

            // ================= wallpaper carousel =================
            Item {
                id: picker
                visible: win.picking
                anchors.fill: parent
                anchors.margins: win.pad
                anchors.topMargin: win.pad * 2 + win.searchHeight   // under the search pill

                // folder chips: All + one per folder; click, or Tab / Shift+Tab
                Row {
                    id: chips
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Repeater {
                        model: [""].concat(Wallpaper.categories)
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            readonly property bool active: win.category === modelData
                            width: chipText.implicitWidth + 28
                            height: win.chipHeight
                            radius: height / 2
                            color: active ? Theme.accent : chipMouse.containsMouse ? Theme.overlay : Theme.surface
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: chip.modelData ? Wallpaper.label(chip.modelData) : "All"
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: chip.active ? Theme.textOnAccent : Theme.fg
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.category = chip.modelData
                            }
                        }
                    }
                }

                // The strip. Each thumbnail sits by its distance from the selection
                // (o, fractional while sliding): the selected one is full size, then
                // smaller and dimmer outwards, five in view.
                Item {
                    id: strip
                    anchors.top: chips.bottom
                    anchors.topMargin: 14
                    width: parent.width
                    height: win.thumbHeight

                    property int current: 0
                    // target counts steps without wrapping (so Right always slides
                    // right); pos animates toward it. Only pos modulo the count
                    // matters for where things sit.
                    property real target: 0
                    property real pos: 0
                    property bool sliding: true
                    Behavior on pos {
                        enabled: strip.sliding
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    function slide(t, snap) { sliding = !snap; target = t; pos = t; sliding = true }
                    // where index sits relative to the selection, the short way
                    // round the loop (fractional while sliding)
                    function offset(index) {
                        const n = win.walls.length
                        let o = ((index - pos) % n + n) % n
                        return o > n / 2 ? o - n : o
                    }

                    // by distance 0, 1, 2, 3: center x, scale, opacity
                    readonly property var centers: [0, 270, 444, 560]
                    readonly property var scales:  [1, 0.625, 0.4, 0.3]
                    readonly property var fades:   [1, 0.6, 0.35, 0]
                    function at(keys, d) {
                        const i = Math.min(Math.floor(d), keys.length - 2)
                        const t = Math.min(d - i, 1)
                        return keys[i] + (keys[i + 1] - keys[i]) * t
                    }

                    Text {
                        visible: win.walls.length === 0
                        anchors.centerIn: parent
                        text: Wallpaper.items.length ? "No matches" : "No wallpapers found"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.muted
                    }

                    // scroll wheel / touchpad: one step per notch
                    WheelHandler {
                        property real acc: 0
                        onWheel: e => {
                            acc += e.angleDelta.y !== 0 ? -e.angleDelta.y : e.angleDelta.x
                            while (Math.abs(acc) >= 120) { win.step(acc > 0 ? 1 : -1); acc -= acc > 0 ? 120 : -120 }
                        }
                    }

                    Repeater {
                        model: win.walls
                        delegate: Item {
                            id: thumb
                            required property var modelData
                            required property int index
                            readonly property real o: strip.offset(index)
                            readonly property real d: Math.min(Math.abs(o), 3)
                            readonly property bool selected: index === strip.current
                            // with under 7 results an item crosses from one end
                            // to the other in view: fade it out near that seam
                            // while sliding (at rest, 2 or 4 results put one
                            // exactly on it, and it should show)
                            readonly property bool resting: Math.abs(o - Math.round(o)) < 0.001
                            readonly property real seam: resting ? 1
                                : Math.max(0, Math.min(1, (win.walls.length / 2 - Math.abs(o)) * 2))

                            visible: Math.abs(o) < 3
                            width: win.thumbWidth
                            height: win.thumbHeight
                            x: (strip.width - width) / 2 + Math.sign(o) * strip.at(strip.centers, d)
                            scale: strip.at(strip.scales, d)
                            opacity: strip.at(strip.fades, d) * seam
                            z: -d                              // the selected one on top while sliding

                            // decode only once it's been near the selection
                            property bool wanted: false
                            readonly property bool near: Math.abs(o) < 4
                            onNearChanged: if (near) wanted = true
                            Component.onCompleted: if (near) wanted = true

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: 16
                                color: Theme.surface           // until the thumbnail is in
                                Image {
                                    anchors.fill: parent
                                    source: thumb.wanted ? "file://" + thumb.modelData.thumb.split("/").map(encodeURIComponent).join("/") : ""
                                    fillMode: Image.PreserveAspectCrop
                                    // real pixels of the selected size (scale 1.33)
                                    sourceSize: Qt.size(Math.ceil(win.thumbWidth * win.devicePixelRatio),
                                                        Math.ceil(win.thumbHeight * win.devicePixelRatio))
                                    asynchronous: true
                                    smooth: true
                                }
                            }
                            // accent ring on the selected one
                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                color: "transparent"
                                border.width: 3
                                border.color: Theme.accent
                                opacity: Math.max(0, 1 - thumb.d * 2)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                // click a neighbor to bring it in, the selected one to keep it
                                onClicked: thumb.selected ? win.keepWall(false) : win.select(thumb.index, false)
                            }
                        }
                    }
                }

                // name of the selected one, and its folder
                Row {
                    anchors.top: strip.bottom
                    anchors.topMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: win.captionHeight
                    spacing: 8
                    readonly property var sel: win.walls[strip.current] ?? null
                    visible: sel !== null
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.sel?.name ?? ""
                        font.family: Theme.font
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Theme.fgStrong
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.sel ? Wallpaper.label(parent.sel.category) : ""
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.muted
                    }
                }
            }

            // ================= power tiles =================
            Row {
                id: tiles
                visible: win.power
                anchors.centerIn: parent
                spacing: 8
                property int current: 0

                Keys.onPressed: e => {
                    const n = Launcher.power.length
                    if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                        current = (current + 1) % n; e.accepted = true
                    } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                        current = (current + n - 1) % n; e.accepted = true
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        Launcher.run(Launcher.power[current]); e.accepted = true
                    } else if (e.key === Qt.Key_Escape) {
                        Launcher.close(); e.accepted = true
                    }
                }

                Repeater {
                    model: Launcher.power
                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool selected: tiles.current === index

                        width: win.tileSize
                        height: win.tileHeight
                        radius: 24
                        color: selected ? Theme.accent : Theme.surface
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Glyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.glyph
                                size: 30
                                color: tile.selected ? Theme.textOnAccent : Theme.fg
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.name
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: tile.selected ? Theme.textOnAccent : Theme.muted
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPositionChanged: tiles.current = tile.index
                            onClicked: Launcher.run(tile.modelData)
                        }
                    }
                }
            }
        }
    }
}

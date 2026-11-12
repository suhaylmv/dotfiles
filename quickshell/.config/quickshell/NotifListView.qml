import QtQuick

// A list of notification cards that animates changes: a new card slides in
// from the right while fading in, a leaving one slides back out while
// fading, and the others glide to close the gap or make room. Used by the
// popups and the panel. Timings and curves: Motion.qml.
//
// Set `source` (an array of Notifications) and a delegate with
// `required property int nid` that draws `objects[nid]` and holds a
// RetainableLock on it: a dismissed notification is destroyed at once
// otherwise, in the middle of its card's exit.
ListView {
    id: view
    property var source: []
    property real slide: 48           // how far cards travel in from the side

    // false holds changes back until it turns true. A ListView in a hidden
    // window doesn't animate: a card added there is just present once the
    // window shows. So the popups keep this false until their window is
    // actually on screen, then the card slides in.
    property bool ready: true
    // a beat later: syncing right away changes `busy` while the popups
    // window is still evaluating the visibility that flipped `ready`
    onReadyChanged: Qt.callLater(sync)

    // id -> Notification, for the rows in the list. Mutated, never
    // reassigned. An entry outlives its row until the card's exit is over
    // (prune), and it's tied to the row, not to a card: the panel's list
    // destroys cards scrolled out of view and makes new ones when they
    // scroll back.
    property var objects: ({})
    Timer {
        id: prune
        interval: Motion.closeMs + 300
        onTriggered: {
            const kept = []
            for (let i = 0; i < rows.count; i++) kept.push(rows.get(i).nid)
            for (const id of Object.keys(view.objects))
                if (!kept.includes(Number(id))) delete view.objects[id]
        }
    }

    // true while there are cards, and a moment longer while the last one
    // leaves (the count drops as soon as its exit starts). The model's
    // count, not the view's: a ListView in a hidden window doesn't update
    // its own, so the popups' window would never show.
    readonly property bool busy: rows.count > 0 || linger.running
    Timer { id: linger; interval: Motion.closeMs + 100 }

    spacing: 8

    // The cards come from a ListModel of ids, not from the array itself: a
    // new array as the model would rebuild every card and replay the
    // slide-in; a ListModel keeps the cards that stay and animates only
    // what changed.
    model: ListModel {
        id: rows
        onCountChanged: if (count === 0) linger.restart()
    }
    onSourceChanged: sync()
    Component.onCompleted: sync()

    function sync() {
        if (!ready) return
        const ids = source.map(n => n.id)
        for (let i = rows.count - 1; i >= 0; i--)
            if (!ids.includes(rows.get(i).nid)) { rows.remove(i); prune.restart() }
        source.forEach((n, i) => {
            objects[n.id] = n
            let j = -1
            for (let k = 0; k < rows.count; k++) if (rows.get(k).nid === n.id) { j = k; break }
            if (j < 0) rows.insert(i, { nid: n.id })
            else if (j !== i) rows.move(j, i, 1)
        })
    }

    add: Transition {
        NumberAnimation {
            property: "x"; from: view.slide; to: 0; duration: Motion.openMs + 60
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.enter
        }
        NumberAnimation {
            property: "opacity"; from: 0; to: 1; duration: Motion.openMs
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.enter
        }
    }
    remove: Transition {
        NumberAnimation {
            property: "x"; to: view.slide; duration: Motion.closeMs + 30
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.exit
        }
        NumberAnimation {
            property: "opacity"; to: 0; duration: Motion.closeMs + 30
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.exit
        }
    }
    // the others make room; x/opacity finish a slide-in this interrupted
    displaced: Transition {
        NumberAnimation {
            property: "y"; duration: Motion.openMs
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.enter
        }
        NumberAnimation { property: "x"; to: 0; duration: Motion.openMs }
        NumberAnimation { property: "opacity"; to: 1; duration: Motion.openMs }
    }
    // ...and close the gap once the leaving one has mostly gone
    removeDisplaced: Transition {
        SequentialAnimation {
            PauseAnimation { duration: 60 }
            NumberAnimation {
                property: "y"; duration: Motion.openMs
                easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.enter
            }
        }
        NumberAnimation { property: "x"; to: 0; duration: Motion.openMs }
        NumberAnimation { property: "opacity"; to: 1; duration: Motion.openMs }
    }
    move: Transition {
        NumberAnimation {
            property: "y"; duration: Motion.openMs
            easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.enter
        }
    }
}

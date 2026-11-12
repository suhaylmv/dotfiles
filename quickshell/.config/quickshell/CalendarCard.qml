import QtQuick
import QtQuick.Layouts

// A month's days, weeks starting on Monday; today is filled with the accent.
// monthOffset shows another month (the bar's date popup shows this one and
// the next). navigable adds previous/next buttons and wheel scrolling (the
// panel); clicking the title goes back to this month.
Rectangle {
    id: card
    property date today: new Date()
    property int monthOffset: 0
    property bool navigable: false
    // re-check once a minute so it rolls over at midnight
    Timer { interval: 60000; running: true; repeat: true; onTriggered: card.today = new Date() }

    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()
    readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7   // Monday = 0
    readonly property int days: new Date(year, month + 1, 0).getDate()

    implicitHeight: col.implicitHeight + 28
    radius: 24
    color: Theme.surface

    WheelHandler {
        enabled: card.navigable
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        // one month per notch (120): a touchpad sends many small deltas, so
        // they add up first (same as the wallpaper carousel)
        property real acc: 0
        onWheel: e => {
            acc += e.angleDelta.y !== 0 ? -e.angleDelta.y : e.angleDelta.x
            while (Math.abs(acc) >= 120) { card.monthOffset += acc > 0 ? 1 : -1; acc -= acc > 0 ? 120 : -120 }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // header: the buttons hang over the title's line, so the card keeps its height
        Item {
            Layout.fillWidth: true
            implicitHeight: title.implicitHeight

            Text {
                id: title
                x: 6
                // English month name like the bar (LC_TIME is Spanish)
                text: Qt.locale("en_US").toString(card.shown, "MMMM yyyy")
                font.family: Theme.font
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.fgStrong
                MouseArea {
                    anchors.fill: parent
                    enabled: card.monthOffset !== 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: card.monthOffset = 0
                }
            }

            Row {
                visible: card.navigable
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: [{ icon: Icons.chevronLeft, step: -1 }, { icon: Icons.chevronRight, step: 1 }]
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 13
                        color: navMouse.containsMouse ? Theme.overlay : "transparent"
                        Glyph {
                            anchors.centerIn: parent
                            text: modelData.icon
                            size: 18
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.monthOffset += modelData.step
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1      // equal columns, whatever the text width
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.muted
                }
            }

            Repeater {
                // blanks before the 1st, the days, blanks after: always 6
                // weeks, so every month is the same height
                model: 42
                delegate: Item {
                    required property int index
                    readonly property int day: index - card.offset + 1
                    readonly property bool isToday: card.monthOffset === 0 && day === card.today.getDate()
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 30
                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28; radius: 14
                        visible: parent.isToday
                        color: Theme.accent
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: parent.day > 0 && parent.day <= card.days
                        text: parent.day
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: parent.isToday ? Font.DemiBold : Font.Normal
                        color: parent.isToday ? Theme.textOnAccent : Theme.fg
                    }
                }
            }
        }
    }
}

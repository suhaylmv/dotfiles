import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification. Used in the panel list and for popups (`floating`).
Rectangle {
    id: card
    required property var notif
    property bool floating: false
    signal activated()
    readonly property bool hovered: hover.hovered
    readonly property bool critical: notif.urgency === NotificationUrgency.Critical

    // image hint (screenshots, avatars) first, then the app's icon
    readonly property string iconSource: {
        if (notif.image) return notif.image
        const i = notif.appIcon
        if (!i) return ""
        if (i.startsWith("/") || i.includes("://")) return i
        return Quickshell.iconPath(i, true)
    }

    implicitHeight: body.implicitHeight + 28
    radius: 20
    color: floating ? Theme.bg : (hover.hovered ? Theme.overlay : Theme.surface)
    border.width: floating || critical ? 1 : 0
    border.color: critical ? Theme.red : Theme.overlay
    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: hover }
    TapHandler { onTapped: card.activated() }

    RowLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: Theme.overlay
            Image {
                anchors.fill: parent
                visible: card.iconSource !== ""
                source: card.iconSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 80
                sourceSize.height: 80
            }
            Glyph {
                anchors.centerIn: parent
                visible: card.iconSource === ""
                text: Icons.bell
                size: 18
                color: Theme.muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: card.notif.summary || card.notif.appName
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.fgStrong
                }
                Text {
                    visible: !closeBtn.visible
                    text: Notifs.ago(card.notif)
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.muted
                }
                // close: shows on hover, in place of the time
                Rectangle {
                    id: closeBtn
                    visible: card.hovered
                    implicitWidth: 22; implicitHeight: 22; radius: 11
                    color: closeMouse.containsMouse ? Theme.red : "transparent"
                    Glyph {
                        anchors.centerIn: parent
                        text: Icons.close
                        size: 14
                        color: closeMouse.containsMouse ? Theme.bg : Theme.muted
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.notif.dismiss()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.fg
            }

            // buttons the app offers ("Reply", "Open"...), except the default
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6
                visible: actionRepeater.count > 0
                Repeater {
                    id: actionRepeater
                    model: card.notif.actions.filter(a => a.identifier !== "default")
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: label.implicitWidth + 24
                        implicitHeight: 28
                        radius: 14
                        color: actMouse.containsMouse ? Theme.accent : Theme.overlay
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.text
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: actMouse.containsMouse ? Theme.textOnAccent : Theme.fg
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}

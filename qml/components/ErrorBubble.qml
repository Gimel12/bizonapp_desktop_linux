import QtQuick
import QtQuick.Layouts

Rectangle {
    id: errorBubble
    width: parent ? parent.width : 400
    implicitHeight: row.implicitHeight + 24
    color: "transparent"

    property string errorText: ""

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28
        anchors.verticalCenter: parent.verticalCenter
        height: row.implicitHeight + 20
        radius: Theme.radiusMedium
        color: Qt.rgba(1, 0.27, 0.23, 0.08)
        border.color: Qt.rgba(1, 0.27, 0.23, 0.2)
        border.width: 1

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: "\u26A0"
                font.pixelSize: 16
                color: Theme.error
            }

            Text {
                Layout.fillWidth: true
                text: errorBubble.errorText
                font.pixelSize: 13
                color: Theme.error
                wrapMode: Text.Wrap
                lineHeight: 1.4
            }
        }
    }
}

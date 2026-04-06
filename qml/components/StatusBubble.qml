import QtQuick
import QtQuick.Layouts

Rectangle {
    id: statusBubble
    width: parent ? parent.width : 400
    implicitHeight: 40
    color: "transparent"

    property string statusText: ""

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Animated spinner dot
        Text {
            id: spinner
            text: "\u25E0"
            font.pixelSize: 16
            color: Theme.accent

            RotationAnimation on rotation {
                from: 0; to: 360
                duration: 1200
                loops: Animation.Infinite
            }
        }

        Text {
            text: statusBubble.statusText
            font.pixelSize: 13
            color: Theme.textTertiary
        }
    }
}

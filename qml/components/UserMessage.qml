import QtQuick
import QtQuick.Layouts

Rectangle {
    id: userMsg
    width: parent ? parent.width : 400
    implicitHeight: col.implicitHeight + 32
    color: "transparent"

    property string messageText: ""

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Header: avatar + "You"
        RowLayout {
            spacing: 10

            Rectangle {
                width: 30; height: 30; radius: 15
                color: Theme.bgTertiary

                Text {
                    anchors.centerIn: parent
                    text: "\u{1F464}"
                    font.pixelSize: 14
                }
            }

            Text {
                text: "You"
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Theme.textPrimary
            }
        }

        // Message text
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 40
            text: userMsg.messageText
            font.pixelSize: 14
            color: Theme.textSecondary
            wrapMode: Text.Wrap
            lineHeight: 1.5
        }
    }

    // Bottom divider
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.divider
    }
}

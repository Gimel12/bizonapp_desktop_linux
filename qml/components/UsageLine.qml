import QtQuick

Rectangle {
    id: usageLine
    width: parent ? parent.width : 400
    implicitHeight: 32
    color: "transparent"

    property string usageText: ""

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        text: usageLine.usageText
        font.pixelSize: 11
        color: Theme.textMuted
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.divider
    }
}

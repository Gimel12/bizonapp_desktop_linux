import QtQuick

Rectangle {
    id: navBtn
    width: 32
    height: 28
    radius: Theme.radiusSmall
    color: mouseArea.containsMouse ? Theme.bgTertiary : "transparent"

    property alias icon: iconText.text
    signal clicked()

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text {
        id: iconText
        anchors.centerIn: parent
        font.pixelSize: 14
        color: mouseArea.containsMouse ? Theme.textPrimary : Theme.textTertiary
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: navBtn.clicked()
    }
}

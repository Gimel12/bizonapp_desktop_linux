import QtQuick
import QtQuick.Controls

Item {
    id: tabBtn
    width: label.implicitWidth + 28
    height: 52

    property string tabLabel: ""
    property int tabIndex: 0
    property bool isActive: false
    signal tabClicked(int idx)

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Theme.bgHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: tabBtn.tabLabel
        font.pixelSize: 13
        font.weight: tabBtn.isActive ? Font.Bold : Font.Medium
        font.letterSpacing: 0.3
        color: tabBtn.isActive ? Theme.textPrimary
             : mouseArea.containsMouse ? Theme.textSecondary
             : Theme.textTertiary

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    // Active indicator bar
    Rectangle {
        id: indicator
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: tabBtn.isActive ? label.implicitWidth + 8 : 0
        height: 2
        radius: 1
        color: Theme.accent
        opacity: tabBtn.isActive ? 1 : 0

        Behavior on width  { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tabBtn.tabClicked(tabBtn.tabIndex)
    }
}

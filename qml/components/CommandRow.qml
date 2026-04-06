import QtQuick
import QtQuick.Layouts

Rectangle {
    id: cmdRow
    width: parent ? parent.width : 400
    implicitHeight: 36
    color: "transparent"

    property string command: ""
    property bool isRunning: false
    property bool hasError: false
    property int durationMs: 0

    function truncate(cmd, maxLen) {
        if (cmd.length > maxLen) return cmd.substring(0, maxLen) + " ...";
        return cmd;
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 52
        anchors.rightMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Status icon
        Text {
            text: cmdRow.isRunning ? "\u25CB"
                : cmdRow.hasError  ? "\u2718"
                :                    "\u2714"
            font.pixelSize: 13
            font.weight: Font.Bold
            color: cmdRow.isRunning ? Theme.accent
                 : cmdRow.hasError  ? Theme.error
                 :                    Theme.success
            Layout.preferredWidth: 16
            horizontalAlignment: Text.AlignHCenter

            // Pulse animation when running
            SequentialAnimation on opacity {
                running: cmdRow.isRunning
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }

        // Command text
        Text {
            Layout.fillWidth: true
            text: truncate(cmdRow.command, 65)
            font.pixelSize: 13
            font.family: "monospace"
            color: Theme.textTertiary
            elide: Text.ElideRight
        }

        // Duration
        Text {
            visible: !cmdRow.isRunning
            text: "(" + (cmdRow.durationMs / 1000).toFixed(1) + "s)"
            font.pixelSize: 12
            color: cmdRow.hasError ? Theme.error : Theme.textMuted
        }
    }
}

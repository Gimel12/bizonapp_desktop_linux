import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BizonBackend 1.0
import "../components"

Rectangle {
    id: chatView
    color: Theme.bgPrimary

    property var chatHandler: null

    // ── Chat message model ──────────────────────────────────────────────
    // Types: "user", "assistant", "command", "status", "error", "usage"
    ListModel { id: chatModel }

    // Track commands in progress (for updating when done)
    property var pendingCommands: ({})

    // ── Connect signals from backend ────────────────────────────────────
    Connections {
        target: chatHandler

        function onUserMessageAdded(text) {
            chatModel.append({ type: "user", content: text, cmd: "",
                               isRunning: false, hasError: false, durationMs: 0 });
            scrollToBottom();
        }

        function onStatusChanged(msg) {
            // Remove previous status if any
            removePreviousStatus();
            if (msg && msg.length > 0) {
                chatModel.append({ type: "status", content: msg, cmd: "",
                                   isRunning: false, hasError: false, durationMs: 0 });
                scrollToBottom();
            }
        }

        function onCommandStarted(cmd, iteration) {
            removePreviousStatus();
            var idx = chatModel.count;
            chatModel.append({ type: "command", content: "", cmd: cmd,
                               isRunning: true, hasError: false, durationMs: 0 });
            chatView.pendingCommands[cmd] = idx;
            scrollToBottom();
        }

        function onCommandFinished(cmd, duration, error) {
            var idx = chatView.pendingCommands[cmd];
            if (idx !== undefined && idx < chatModel.count) {
                chatModel.set(idx, {
                    type: "command", content: "", cmd: cmd,
                    isRunning: false,
                    hasError: error && error.length > 0,
                    durationMs: duration
                });
            }
            delete chatView.pendingCommands[cmd];
        }

        function onAssistantMessageAdded(text) {
            removePreviousStatus();
            chatModel.append({ type: "assistant", content: text, cmd: "",
                               isRunning: false, hasError: false, durationMs: 0 });
            scrollToBottom();
        }

        function onUsageInfo(text) {
            chatModel.append({ type: "usage", content: text, cmd: "",
                               isRunning: false, hasError: false, durationMs: 0 });
            scrollToBottom();
        }

        function onErrorOccurred(text) {
            removePreviousStatus();
            chatModel.append({ type: "error", content: text, cmd: "",
                               isRunning: false, hasError: false, durationMs: 0 });
            scrollToBottom();
        }
    }

    function removePreviousStatus() {
        for (var i = chatModel.count - 1; i >= 0; i--) {
            if (chatModel.get(i).type === "status") {
                chatModel.remove(i);
                break;
            }
        }
    }

    function scrollToBottom() {
        Qt.callLater(function() {
            chatList.positionViewAtEnd();
        });
    }

    // ── Layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Chat list ───────────────────────────────────────────────────
        ListView {
            id: chatList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds

            model: chatModel

            // Empty state
            header: Item {
                width: chatList.width
                height: chatModel.count === 0 ? chatList.height : 0
                visible: chatModel.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    visible: chatModel.count === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "BIZON AI"
                        font.pixelSize: 28
                        font.weight: Font.Black
                        font.letterSpacing: 4
                        color: Theme.accent
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Diagnostic Assistant"
                        font.pixelSize: 16
                        color: Theme.textTertiary
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Ask me to run diagnostics, check for errors,\nor troubleshoot your workstation."
                        font.pixelSize: 13
                        color: Theme.textMuted
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.5
                    }
                }
            }

            delegate: Loader {
                id: delegateLoader
                width: chatList.width

                // Expose model data to loaded components
                property string mType: model.type || ""
                property string mContent: model.content || ""
                property string mCmd: model.cmd || ""
                property bool mIsRunning: model.isRunning || false
                property bool mHasError: model.hasError || false
                property int mDurationMs: model.durationMs || 0

                sourceComponent: {
                    switch (mType) {
                        case "user":      return userComp;
                        case "assistant": return assistantComp;
                        case "command":   return commandComp;
                        case "status":    return statusComp;
                        case "error":     return errorComp;
                        case "usage":     return usageComp;
                        default:          return null;
                    }
                }
            }

            // Custom scrollbar
            ScrollBar.vertical: ScrollBar {
                width: 6
                policy: ScrollBar.AsNeeded

                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: 3
                    color: Theme.textMuted
                    opacity: parent.active ? 0.8 : 0.3
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }

        // ── Input area ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            color: Theme.bgSecondary

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 12

                // Text input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgInput
                    border.color: inputField.activeFocus ? Theme.accent : Theme.border
                    border.width: inputField.activeFocus ? 1.5 : 1

                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    TextInput {
                        id: inputField
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        clip: true
                        enabled: !(chatHandler && chatHandler.busy)

                        // Placeholder
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Ask me to run diagnostics, check for errors, or troubleshoot issues..."
                            font.pixelSize: 14
                            color: Theme.textMuted
                            visible: !inputField.text && !inputField.activeFocus
                        }

                        Keys.onReturnPressed: sendAction()
                        Keys.onEnterPressed: sendAction()
                    }
                }

                // Send button
                Rectangle {
                    width: 44; height: 44
                    radius: 12
                    color: (chatHandler && chatHandler.busy) ? Theme.bgTertiary
                         : sendMouse.containsMouse ? Theme.accentLight
                         : Theme.accent
                    opacity: (chatHandler && chatHandler.busy) ? 0.5 : 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: (chatHandler && chatHandler.busy) ? "\u25F7" : "\u27A4"
                        font.pixelSize: 18
                        color: "#ffffff"
                        font.weight: Font.Bold

                        RotationAnimation on rotation {
                            running: chatHandler ? chatHandler.busy : false
                            from: 0; to: 360
                            duration: 1200
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !(chatHandler && chatHandler.busy)
                        onClicked: sendAction()
                    }
                }

                // Clear button
                Rectangle {
                    width: 44; height: 44
                    radius: 12
                    color: clearMouse.containsMouse ? Theme.bgTertiary : "transparent"
                    border.color: Theme.border
                    border.width: 1
                    visible: chatModel.count > 0

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        font.pixelSize: 16
                        color: Theme.textTertiary
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            chatHandler.clearChat();
                            chatModel.clear();
                        }
                    }
                }
            }
        }
    }

    // ── Send action ─────────────────────────────────────────────────────
    function sendAction() {
        var text = inputField.text.trim();
        if (text.length === 0 || chatHandler.busy) return;
        chatHandler.sendMessage(text);
        inputField.text = "";
    }

    // ── Delegate components ─────────────────────────────────────────────
    Component {
        id: userComp
        UserMessage {
            messageText: parent ? parent.mContent : ""
        }
    }

    Component {
        id: assistantComp
        AssistantMessage {
            messageText: parent ? parent.mContent : ""
        }
    }

    Component {
        id: commandComp
        CommandRow {
            command: parent ? parent.mCmd : ""
            isRunning: parent ? parent.mIsRunning : false
            hasError: parent ? parent.mHasError : false
            durationMs: parent ? parent.mDurationMs : 0
        }
    }

    Component {
        id: statusComp
        StatusBubble {
            statusText: parent ? parent.mContent : ""
        }
    }

    Component {
        id: errorComp
        ErrorBubble {
            errorText: parent ? parent.mContent : ""
        }
    }

    Component {
        id: usageComp
        UsageLine {
            usageText: parent ? parent.mContent : ""
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Full-screen overlay panel for viewing/editing the system prompt
Rectangle {
    id: promptEditor
    color: Qt.rgba(0, 0, 0, 0.85)
    visible: false
    opacity: visible ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

    property var chatHandler: null
    property bool hasUnsavedChanges: false

    signal closed()

    function open() {
        if (chatHandler) {
            promptArea.text = chatHandler.systemPrompt;
        }
        hasUnsavedChanges = false;
        visible = true;
        promptArea.forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
    }

    // Click outside the card to close (only if no unsaved changes)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!promptEditor.hasUnsavedChanges) {
                promptEditor.close();
            }
        }
    }

    // ── Editor card ─────────────────────────────────────────────────────
    Rectangle {
        id: editorCard
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 720)
        height: Math.min(parent.height - 80, 620)
        radius: Theme.radiusLarge
        color: Theme.bgSecondary
        border.color: Theme.border
        border.width: 1

        // Prevent click-through
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ── Header ──────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 16
                    spacing: 12

                    // Icon
                    Text {
                        text: "\u2699"
                        font.pixelSize: 18
                        color: Theme.accent
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: "System Prompt"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: Theme.textPrimary
                        }

                        Text {
                            text: chatHandler ? chatHandler.systemPromptPath : ""
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: Theme.textMuted
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    // Unsaved indicator
                    Rectangle {
                        visible: promptEditor.hasUnsavedChanges
                        width: 8; height: 8; radius: 4
                        color: Theme.warning
                    }

                    // Close button
                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: closeMouse.containsMouse ? Theme.bgTertiary : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            font.pixelSize: 14
                            color: Theme.textTertiary
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: promptEditor.close()
                        }
                    }
                }

                // Divider
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
            }

            // ── Info banner ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: Qt.rgba(0.13, 0.59, 0.95, 0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 8

                    Text {
                        text: "\u2139"
                        font.pixelSize: 14
                        color: Theme.accent
                    }

                    Text {
                        text: "This prompt is sent with every AI request. Push changes to GitHub to update all clients."
                        font.pixelSize: 12
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
            }

            // ── Text editor ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.bgPrimary

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    anchors.margins: 4
                    contentWidth: promptArea.width
                    contentHeight: promptArea.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: promptArea
                        width: flickable.width
                        font.pixelSize: 13
                        font.family: "monospace"
                        color: Theme.textPrimary
                        selectionColor: Theme.accent
                        selectedTextColor: "#ffffff"
                        wrapMode: TextEdit.Wrap
                        padding: 20
                        tabStopDistance: 28

                        onTextChanged: {
                            if (chatHandler) {
                                promptEditor.hasUnsavedChanges =
                                    (promptArea.text !== chatHandler.systemPrompt);
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        width: 6
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: Theme.textMuted
                            opacity: parent.active ? 0.6 : 0.2
                        }
                    }
                }
            }

            // ── Footer with actions ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 12

                    // Character count
                    Text {
                        text: promptArea.text.length + " chars"
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }

                    // Save status message
                    Text {
                        id: saveStatus
                        text: ""
                        font.pixelSize: 12
                        color: Theme.success
                        opacity: 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animNormal }
                        }

                        Timer {
                            id: statusTimer
                            interval: 3000
                            onTriggered: saveStatus.opacity = 0
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Reload button
                    Rectangle {
                        width: reloadRow.implicitWidth + 24
                        height: 34
                        radius: 8
                        color: reloadMouse.containsMouse ? Theme.bgTertiary : "transparent"
                        border.color: Theme.border
                        border.width: 1

                        RowLayout {
                            id: reloadRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "\u27F3"
                                font.pixelSize: 13
                                color: Theme.textSecondary
                            }
                            Text {
                                text: "Reload"
                                font.pixelSize: 13
                                color: Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: reloadMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (chatHandler) {
                                    chatHandler.reloadSystemPrompt();
                                    promptArea.text = chatHandler.systemPrompt;
                                    promptEditor.hasUnsavedChanges = false;
                                    saveStatus.text = "Reloaded from disk";
                                    saveStatus.color = Theme.info;
                                    saveStatus.opacity = 1;
                                    statusTimer.restart();
                                }
                            }
                        }
                    }

                    // Save button
                    Rectangle {
                        width: saveRow.implicitWidth + 24
                        height: 34
                        radius: 8
                        color: promptEditor.hasUnsavedChanges
                            ? (saveMouse.containsMouse ? Theme.accentLight : Theme.accent)
                            : Theme.bgTertiary
                        opacity: promptEditor.hasUnsavedChanges ? 1 : 0.5

                        RowLayout {
                            id: saveRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "\u2714"
                                font.pixelSize: 13
                                color: "#ffffff"
                            }
                            Text {
                                text: "Save"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: "#ffffff"
                            }
                        }

                        MouseArea {
                            id: saveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: promptEditor.hasUnsavedChanges
                                ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (chatHandler && promptEditor.hasUnsavedChanges) {
                                    chatHandler.saveSystemPrompt(promptArea.text);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Handle save result from backend ─────────────────────────────────
    Connections {
        target: chatHandler
        function onSystemPromptSaved(success, message) {
            if (success) {
                promptEditor.hasUnsavedChanges = false;
                saveStatus.text = "\u2714 " + message;
                saveStatus.color = Theme.success;
            } else {
                saveStatus.text = "\u2718 " + message;
                saveStatus.color = Theme.error;
            }
            saveStatus.opacity = 1;
            statusTimer.restart();
        }
    }
}

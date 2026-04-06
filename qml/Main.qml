import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import BizonBackend 1.0
import "views"
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 780
    minimumWidth: 900
    minimumHeight: 600
    title: "Bizon App 2.0"
    color: Theme.bgPrimary

    // ── Chat backend ────────────────────────────────────────────────────
    ChatHandler {
        id: chatHandler
    }

    // ── Tab model ───────────────────────────────────────────────────────
    property int currentTab: 0
    onCurrentTabChanged: {
        var tab = tabModel[currentTab];
        if (tab && !tab.isChat && tab.url) {
            browserView.loadUrl(tab.url);
        }
    }
    Component.onCompleted: {
        var tab = tabModel[currentTab];
        if (tab && !tab.isChat && tab.url) {
            browserView.loadUrl(tab.url);
        }
    }
    property var tabModel: [
        { label: "Home",        url: "https://bizonbizon.notion.site/Getting-Started-Guide-6956f7a535ed44bdb4ee77e61a88aad5?pvs=4", isChat: false },
        { label: "Guides",      url: "https://www.notion.so/bizonbizon/Bizon-Technical-Support-Portal-a1201a84f86b4797982e06d360351f54", isChat: false },
        { label: "AI Catalog",  url: "https://catalog.ngc.nvidia.com/?filters=&orderBy=scoreDESC&query=", isChat: false },
        { label: "BizonROS",    url: "https://build.nvidia.com/explore/automotive", isChat: false },
        { label: "Support",     url: "", isChat: true }
    ]

    // ── Layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Top bar ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: Theme.bgSecondary

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 0

                // Logo / brand
                Text {
                    text: "BIZON"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    font.letterSpacing: 3
                    color: Theme.accent
                    Layout.rightMargin: 24
                }

                // Tab bar
                Repeater {
                    model: root.tabModel.length
                    delegate: TabButton {
                        tabLabel: root.tabModel[index].label
                        tabIndex: index
                        isActive: root.currentTab === index
                        onTabClicked: function(idx) { root.currentTab = idx }
                    }
                }

                Item { Layout.fillWidth: true }

                // Dark / Light mode toggle (always visible)
                Rectangle {
                    width: 34; height: 28
                    radius: 6
                    color: modeMouse.containsMouse ? Theme.bgTertiary : "transparent"
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: Theme.darkMode ? "\u263E" : "\u2600"
                        font.pixelSize: 15
                        color: Theme.darkMode ? Theme.textSecondary : Theme.warning
                    }

                    MouseArea {
                        id: modeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.darkMode = !Theme.darkMode
                    }
                }

                // Chat controls (only when chat is active)
                Row {
                    spacing: 8
                    visible: root.tabModel[root.currentTab].isChat
                    opacity: visible ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    // ── Backend selector ─────────────────────────
                    Text {
                        text: "Backend"
                        font.pixelSize: 12
                        color: Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ComboBox {
                        id: backendCombo
                        model: ["Ollama", "Claude"]
                        width: 100
                        height: 28
                        font.pixelSize: 12

                        onCurrentTextChanged: {
                            chatHandler.setBackend(currentText)
                        }

                        background: Rectangle {
                            color: Theme.bgTertiary
                            radius: 6
                            border.color: Theme.border
                            border.width: 1
                        }

                        contentItem: Text {
                            text: backendCombo.displayText
                            color: Theme.textSecondary
                            font: backendCombo.font
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }

                        popup: Popup {
                            y: backendCombo.height + 2
                            width: backendCombo.width
                            padding: 4

                            background: Rectangle {
                                color: Theme.bgSecondary
                                radius: 8
                                border.color: Theme.border
                            }

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: backendCombo.popup.visible ? backendCombo.delegateModel : null
                                currentIndex: backendCombo.highlightedIndex
                            }
                        }

                        delegate: ItemDelegate {
                            width: backendCombo.width - 8
                            height: 30
                            contentItem: Text {
                                text: modelData
                                color: Theme.textPrimary
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 6
                            }
                            background: Rectangle {
                                color: highlighted ? Theme.bgTertiary : "transparent"
                                radius: 4
                            }
                            highlighted: backendCombo.highlightedIndex === index
                        }
                    }

                    // ── Model selector (Ollama only) ────────────
                    Rectangle {
                        width: 1; height: 20
                        color: Theme.border
                        anchors.verticalCenter: parent.verticalCenter
                        visible: backendCombo.currentText === "Ollama"
                    }

                    Text {
                        text: "Model"
                        font.pixelSize: 12
                        color: Theme.textTertiary
                        anchors.verticalCenter: parent.verticalCenter
                        visible: backendCombo.currentText === "Ollama"
                    }

                    ComboBox {
                        id: modelCombo
                        visible: backendCombo.currentText === "Ollama"
                        width: 160
                        height: 28
                        font.pixelSize: 12
                        model: chatHandler ? chatHandler.ollamaModels : []

                        onCurrentTextChanged: {
                            if (chatHandler && currentText) {
                                chatHandler.setModel(currentText)
                            }
                        }

                        background: Rectangle {
                            color: Theme.bgTertiary
                            radius: 6
                            border.color: Theme.border
                            border.width: 1
                        }

                        contentItem: Text {
                            text: modelCombo.displayText || "No models"
                            color: modelCombo.count > 0 ? Theme.textSecondary : Theme.textMuted
                            font: modelCombo.font
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                            elide: Text.ElideRight
                        }

                        popup: Popup {
                            y: modelCombo.height + 2
                            width: Math.max(modelCombo.width, 200)
                            padding: 4

                            background: Rectangle {
                                color: Theme.bgSecondary
                                radius: 8
                                border.color: Theme.border
                            }

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: modelCombo.popup.visible ? modelCombo.delegateModel : null
                                currentIndex: modelCombo.highlightedIndex
                            }
                        }

                        delegate: ItemDelegate {
                            width: Math.max(modelCombo.width, 200) - 8
                            height: 30
                            contentItem: Text {
                                text: modelData
                                color: Theme.textPrimary
                                font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 6
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                color: highlighted ? Theme.bgTertiary : "transparent"
                                radius: 4
                            }
                            highlighted: modelCombo.highlightedIndex === index
                        }
                    }

                    // Refresh models button
                    Rectangle {
                        visible: backendCombo.currentText === "Ollama"
                        width: 28; height: 28
                        radius: 6
                        color: refreshMouse.containsMouse ? Theme.bgTertiary : "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "\u27F3"
                            font.pixelSize: 14
                            color: Theme.textTertiary
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (chatHandler) chatHandler.refreshModels()
                            }
                        }
                    }
                }
            }

            // Bottom accent line
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ── Nav bar (browser only) ──────────────────────────────────────
        Rectangle {
            id: navBar
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 40 : 0
            visible: !root.tabModel[root.currentTab].isChat
            color: Theme.bgSecondary

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 4

                NavButton { icon: "\u25C0"; onClicked: browserView.goBack() }
                NavButton { icon: "\u25B6"; onClicked: browserView.goForward() }
                NavButton { icon: "\u27F3"; onClicked: browserView.reload() }
                NavButton {
                    icon: "\u2302"
                    onClicked: { root.currentTab = 0 }
                }

                Item { Layout.fillWidth: true }

                // URL indicator
                Text {
                    text: {
                        var tab = root.tabModel[root.currentTab];
                        if (tab && !tab.isChat && tab.url) {
                            var m = tab.url.match(/^https?:\/\/([^\/]+)/);
                            return m ? m[1] : "";
                        }
                        return "";
                    }
                    font.pixelSize: 11
                    color: Theme.textTertiary
                    Layout.rightMargin: 8
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.border
            }
        }

        // ── Content area ────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tabModel[root.currentTab].isChat ? 1 : 0

            // Page 0: Browser
            BrowserView {
                id: browserView
            }

            // Page 1: Chat
            ChatView {
                id: chatView
                chatHandler: chatHandler
            }
        }
    }

}

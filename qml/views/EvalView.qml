import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import BizonBackend 1.0
import "../components"

Rectangle {
    id: evalView
    color: Theme.bgPrimary

    property var evalHandler: null

    // ── State ─────────────────────────────────────────────────────────────
    property string resultA: ""
    property string resultB: ""
    property string errorA: ""
    property string errorB: ""
    property string statusA: ""
    property string statusB: ""
    property bool doneA: false
    property bool doneB: false
    property var statsA: ({})
    property var statsB: ({})

    // ── Signals from backend ──────────────────────────────────────────────
    // ── Format helpers ────────────────────────────────────────────────
    function formatNumber(n) {
        if (!n) return "0";
        return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    function formatTime(ms) {
        if (!ms) return "0s";
        if (ms < 1000) return ms + "ms";
        return (ms / 1000).toFixed(1) + "s";
    }

    Connections {
        target: evalHandler

        function onResultReady(side, text, usageJson) {
            var stats = {};
            try { stats = JSON.parse(usageJson); } catch(e) {}
            if (side === "A") { evalView.resultA = text; evalView.doneA = true; evalView.statusA = ""; evalView.statsA = stats; }
            else              { evalView.resultB = text; evalView.doneB = true; evalView.statusB = ""; evalView.statsB = stats; }
        }

        function onErrorOccurred(side, text) {
            if (side === "A") { evalView.errorA = text; evalView.doneA = true; evalView.statusA = ""; }
            else              { evalView.errorB = text; evalView.doneB = true; evalView.statusB = ""; }
        }

        function onStatusUpdate(side, text) {
            if (side === "A") evalView.statusA = text;
            else              evalView.statusB = text;
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    function labelForConfig(backend, model) {
        if (backend === "Claude") return "Claude";
        if (model) return model;
        return "Ollama";
    }

    function resetResults() {
        resultA = ""; resultB = "";
        errorA  = ""; errorB  = "";
        statusA = ""; statusB = "";
        doneA   = false; doneB = false;
        statsA  = {}; statsB = {};
    }

    // ── Layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // ── Header row ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "\uD83E\uDDEA"
                font.pixelSize: 20
            }

            Text {
                text: "Model Evaluation"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: Theme.textPrimary
            }

            Text {
                text: "Compare side by side"
                font.pixelSize: 13
                color: Theme.textTertiary
                Layout.leftMargin: 4
            }

            Item { Layout.fillWidth: true }

            // New comparison button
            Rectangle {
                width: newBtnRow.implicitWidth + 20
                height: 32
                radius: 8
                color: newMouse.containsMouse ? Theme.bgTertiary : "transparent"
                border.color: Theme.border
                border.width: 1

                Row {
                    id: newBtnRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "\u25CB"; font.pixelSize: 12; color: Theme.textSecondary }
                    Text { text: "New"; font.pixelSize: 12; color: Theme.textSecondary }
                }

                MouseArea {
                    id: newMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        evalView.resetResults();
                        promptInput.text = "";
                    }
                }
            }

            // Refresh models
            Rectangle {
                width: 32; height: 32; radius: 8
                color: refreshEvalMouse.containsMouse ? Theme.bgTertiary : "transparent"
                border.color: Theme.border; border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\u27F3"; font.pixelSize: 14; color: Theme.textTertiary
                }

                MouseArea {
                    id: refreshEvalMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (evalHandler) evalHandler.refreshModels() }
                }
            }
        }

        // ── Model selectors row ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            // ── Model A selector ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: Theme.radiusMedium
                color: Theme.bgSecondary
                border.color: Theme.accent
                border.width: 1.5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Text {
                        text: "MODEL A"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.accent
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ComboBox {
                            id: backendA
                            model: ["Ollama", "Claude"]
                            width: 90; height: 28; font.pixelSize: 12
                            background: Rectangle { color: Theme.bgTertiary; radius: 6; border.color: Theme.border; border.width: 1 }
                            contentItem: Text { text: backendA.displayText; color: Theme.textSecondary; font: backendA.font; verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
                            popup: Popup {
                                y: backendA.height + 2; width: backendA.width; padding: 4
                                background: Rectangle { color: Theme.bgSecondary; radius: 8; border.color: Theme.border }
                                contentItem: ListView { clip: true; implicitHeight: contentHeight; model: backendA.popup.visible ? backendA.delegateModel : null; currentIndex: backendA.highlightedIndex }
                            }
                            delegate: ItemDelegate {
                                width: backendA.width - 8; height: 30
                                contentItem: Text { text: modelData; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; leftPadding: 6 }
                                background: Rectangle { color: highlighted ? Theme.bgTertiary : "transparent"; radius: 4 }
                                highlighted: backendA.highlightedIndex === index
                            }
                        }

                        ComboBox {
                            id: modelA
                            visible: backendA.currentText === "Ollama"
                            Layout.fillWidth: true
                            height: 28; font.pixelSize: 12
                            model: evalHandler ? evalHandler.ollamaModels : []
                            background: Rectangle { color: Theme.bgTertiary; radius: 6; border.color: Theme.border; border.width: 1 }
                            contentItem: Text { text: modelA.displayText || "No models"; color: modelA.count > 0 ? Theme.textSecondary : Theme.textMuted; font: modelA.font; verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
                            popup: Popup {
                                y: modelA.height + 2; width: Math.max(modelA.width, 200); padding: 4
                                background: Rectangle { color: Theme.bgSecondary; radius: 8; border.color: Theme.border }
                                contentItem: ListView { clip: true; implicitHeight: contentHeight; model: modelA.popup.visible ? modelA.delegateModel : null; currentIndex: modelA.highlightedIndex }
                            }
                            delegate: ItemDelegate {
                                width: Math.max(modelA.width, 200) - 8; height: 30
                                contentItem: Text { text: modelData; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; leftPadding: 6; elide: Text.ElideRight }
                                background: Rectangle { color: highlighted ? Theme.bgTertiary : "transparent"; radius: 4 }
                                highlighted: modelA.highlightedIndex === index
                            }
                        }

                        Text {
                            visible: backendA.currentText === "Claude"
                            text: "Claude (API default)"
                            font.pixelSize: 12
                            color: Theme.textTertiary
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // VS label
            Text {
                text: "VS"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Theme.textTertiary
                Layout.alignment: Qt.AlignVCenter
            }

            // ── Model B selector ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: Theme.radiusMedium
                color: Theme.bgSecondary
                border.color: Theme.warning
                border.width: 1.5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Text {
                        text: "MODEL B"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: Theme.warning
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ComboBox {
                            id: backendB
                            model: ["Claude", "Ollama"]
                            width: 90; height: 28; font.pixelSize: 12
                            background: Rectangle { color: Theme.bgTertiary; radius: 6; border.color: Theme.border; border.width: 1 }
                            contentItem: Text { text: backendB.displayText; color: Theme.textSecondary; font: backendB.font; verticalAlignment: Text.AlignVCenter; leftPadding: 8 }
                            popup: Popup {
                                y: backendB.height + 2; width: backendB.width; padding: 4
                                background: Rectangle { color: Theme.bgSecondary; radius: 8; border.color: Theme.border }
                                contentItem: ListView { clip: true; implicitHeight: contentHeight; model: backendB.popup.visible ? backendB.delegateModel : null; currentIndex: backendB.highlightedIndex }
                            }
                            delegate: ItemDelegate {
                                width: backendB.width - 8; height: 30
                                contentItem: Text { text: modelData; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; leftPadding: 6 }
                                background: Rectangle { color: highlighted ? Theme.bgTertiary : "transparent"; radius: 4 }
                                highlighted: backendB.highlightedIndex === index
                            }
                        }

                        ComboBox {
                            id: modelB
                            visible: backendB.currentText === "Ollama"
                            Layout.fillWidth: true
                            height: 28; font.pixelSize: 12
                            model: evalHandler ? evalHandler.ollamaModels : []
                            background: Rectangle { color: Theme.bgTertiary; radius: 6; border.color: Theme.border; border.width: 1 }
                            contentItem: Text { text: modelB.displayText || "No models"; color: modelB.count > 0 ? Theme.textSecondary : Theme.textMuted; font: modelB.font; verticalAlignment: Text.AlignVCenter; leftPadding: 8; elide: Text.ElideRight }
                            popup: Popup {
                                y: modelB.height + 2; width: Math.max(modelB.width, 200); padding: 4
                                background: Rectangle { color: Theme.bgSecondary; radius: 8; border.color: Theme.border }
                                contentItem: ListView { clip: true; implicitHeight: contentHeight; model: modelB.popup.visible ? modelB.delegateModel : null; currentIndex: modelB.highlightedIndex }
                            }
                            delegate: ItemDelegate {
                                width: Math.max(modelB.width, 200) - 8; height: 30
                                contentItem: Text { text: modelData; color: Theme.textPrimary; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; leftPadding: 6; elide: Text.ElideRight }
                                background: Rectangle { color: highlighted ? Theme.bgTertiary : "transparent"; radius: 4 }
                                highlighted: modelB.highlightedIndex === index
                            }
                        }

                        Text {
                            visible: backendB.currentText === "Claude"
                            text: "Claude (API default)"
                            font.pixelSize: 12
                            color: Theme.textTertiary
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // ── Prompt input + Run button ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 10
                color: Theme.bgInput
                border.color: promptInput.activeFocus ? Theme.accent : Theme.border
                border.width: promptInput.activeFocus ? 1.5 : 1

                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                TextInput {
                    id: promptInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 14
                    color: Theme.textPrimary
                    clip: true
                    enabled: !(evalHandler && evalHandler.busy)

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Enter a prompt to test both models with the same input..."
                        font.pixelSize: 14
                        color: Theme.textMuted
                        visible: !promptInput.text && !promptInput.activeFocus
                    }

                    Keys.onReturnPressed: runEval()
                    Keys.onEnterPressed: runEval()
                }
            }

            // Run button
            Rectangle {
                width: runBtnRow.implicitWidth + 28
                height: 44
                radius: 10
                color: {
                    if (evalHandler && evalHandler.busy) return Theme.bgTertiary;
                    return runMouse.containsMouse ? Theme.accentLight : Theme.accent;
                }
                opacity: (evalHandler && evalHandler.busy) ? 0.5 : 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    id: runBtnRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: (evalHandler && evalHandler.busy) ? "\u25F7" : "\u25B6"
                        font.pixelSize: 14
                        color: "#ffffff"

                        RotationAnimation on rotation {
                            running: evalHandler ? evalHandler.busy : false
                            from: 0; to: 360; duration: 1200
                            loops: Animation.Infinite
                        }
                    }
                    Text {
                        text: (evalHandler && evalHandler.busy) ? "Running..." : "Run"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    id: runMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !(evalHandler && evalHandler.busy)
                    onClicked: runEval()
                }
            }
        }

        // ── Results panels (side by side) ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // ── Panel A ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMedium
                color: Theme.bgSecondary
                border.color: Theme.accent
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.1)
                        radius: Theme.radiusMedium

                        // Square off bottom corners
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: parent.radius
                            color: parent.color
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Rectangle {
                                width: modelALabel.implicitWidth + 16; height: 22; radius: 4
                                color: Theme.accent

                                Text {
                                    id: modelALabel
                                    anchors.centerIn: parent
                                    text: "Model A"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: "#ffffff"
                                }
                            }

                            Text {
                                text: evalView.labelForConfig(backendA.currentText, modelA.currentText)
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Done / loading indicator
                            Text {
                                visible: evalView.doneA
                                text: evalView.errorA ? "\u26A0" : "\u2713"
                                font.pixelSize: 14
                                color: evalView.errorA ? Theme.error : Theme.success
                            }
                        }
                    }

                    // Divider
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    // Content
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: resultAText.implicitHeight + 32
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            width: 5; policy: ScrollBar.AsNeeded
                            contentItem: Rectangle { implicitWidth: 5; radius: 2.5; color: Theme.textMuted; opacity: 0.4 }
                        }

                        Text {
                            id: resultAText
                            width: parent.width - 32
                            x: 16; y: 16
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                            font.pixelSize: 13
                            lineHeight: 1.5
                            color: {
                                if (evalView.errorA) return Theme.error;
                                if (evalView.resultA) return Theme.textPrimary;
                                return Theme.textMuted;
                            }
                            text: {
                                if (evalView.statusA) return evalView.statusA;
                                if (evalView.errorA) return evalView.errorA;
                                if (evalView.resultA) return evalView.resultA;
                                return "Run a comparison to see results";
                            }
                        }
                    }

                    // ── Stats bar A ───────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: evalView.doneA && !evalView.errorA ? 52 : 0
                        visible: evalView.doneA && !evalView.errorA
                        color: Theme.bgTertiary
                        radius: Theme.radiusMedium

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width; height: parent.radius
                            color: parent.color
                        }

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width; height: 1
                            color: Theme.border
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 16

                            // Input tokens
                            Column {
                                spacing: 2
                                Text { text: "INPUT"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatNumber(evalView.statsA.inputTokens || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }

                            // Output tokens
                            Column {
                                spacing: 2
                                Text { text: "OUTPUT"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatNumber(evalView.statsA.outputTokens || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }

                            // Total
                            Column {
                                spacing: 2
                                Text { text: "TOTAL"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatNumber(evalView.statsA.totalTokens || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.accent }
                            }

                            Item { Layout.fillWidth: true }

                            // Time
                            Column {
                                spacing: 2
                                Text { text: "TIME"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatTime(evalView.statsA.elapsedMs || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }

                            // Tokens per second
                            Column {
                                spacing: 2
                                Text { text: "TOK/S"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: (evalView.statsA.tokensPerSecond || 0).toFixed(1); font.pixelSize: 13; font.weight: Font.Bold; color: Theme.success }
                            }
                        }
                    }
                }
            }

            // ── Panel B ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMedium
                color: Theme.bgSecondary
                border.color: Theme.warning
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.1)
                        radius: Theme.radiusMedium

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: parent.radius
                            color: parent.color
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Rectangle {
                                width: modelBLabel.implicitWidth + 16; height: 22; radius: 4
                                color: Theme.warning

                                Text {
                                    id: modelBLabel
                                    anchors.centerIn: parent
                                    text: "Model B"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: "#ffffff"
                                }
                            }

                            Text {
                                text: evalView.labelForConfig(backendB.currentText, modelB.currentText)
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: evalView.doneB
                                text: evalView.errorB ? "\u26A0" : "\u2713"
                                font.pixelSize: 14
                                color: evalView.errorB ? Theme.error : Theme.success
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: resultBText.implicitHeight + 32
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            width: 5; policy: ScrollBar.AsNeeded
                            contentItem: Rectangle { implicitWidth: 5; radius: 2.5; color: Theme.textMuted; opacity: 0.4 }
                        }

                        Text {
                            id: resultBText
                            width: parent.width - 32
                            x: 16; y: 16
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                            font.pixelSize: 13
                            lineHeight: 1.5
                            color: {
                                if (evalView.errorB) return Theme.error;
                                if (evalView.resultB) return Theme.textPrimary;
                                return Theme.textMuted;
                            }
                            text: {
                                if (evalView.statusB) return evalView.statusB;
                                if (evalView.errorB) return evalView.errorB;
                                if (evalView.resultB) return evalView.resultB;
                                return "Run a comparison to see results";
                            }
                        }
                    }

                    // ── Stats bar B ───────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: evalView.doneB && !evalView.errorB ? 52 : 0
                        visible: evalView.doneB && !evalView.errorB
                        color: Theme.bgTertiary
                        radius: Theme.radiusMedium

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width; height: parent.radius
                            color: parent.color
                        }

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width; height: 1
                            color: Theme.border
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 16

                            Column {
                                spacing: 2
                                Text { text: "INPUT"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatNumber(evalView.statsB.inputTokens || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }

                            Column {
                                spacing: 2
                                Text { text: "OUTPUT"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatNumber(evalView.statsB.outputTokens || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }

                            Column {
                                spacing: 2
                                Text { text: "TOTAL"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatNumber(evalView.statsB.totalTokens || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.accent }
                            }

                            Item { Layout.fillWidth: true }

                            Column {
                                spacing: 2
                                Text { text: "TIME"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: evalView.formatTime(evalView.statsB.elapsedMs || 0); font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textSecondary }
                            }

                            Column {
                                spacing: 2
                                Text { text: "TOK/S"; font.pixelSize: 9; font.weight: Font.Bold; font.letterSpacing: 1; color: Theme.textMuted }
                                Text { text: (evalView.statsB.tokensPerSecond || 0).toFixed(1); font.pixelSize: 13; font.weight: Font.Bold; color: Theme.success }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Run eval action ───────────────────────────────────────────────────
    function runEval() {
        var text = promptInput.text.trim();
        if (text.length === 0 || evalHandler.busy) return;

        resetResults();
        evalHandler.runComparison(
            text,
            backendA.currentText,
            backendA.currentText === "Ollama" ? modelA.currentText : "",
            backendB.currentText,
            backendB.currentText === "Ollama" ? modelB.currentText : ""
        );
    }
}

pragma Singleton
import QtQuick

QtObject {
    // ── Mode toggle ───────────────────────────────────────────────────
    property bool darkMode: true

    // ── Background ──────────────────────────────────────────────────────
    property color bgPrimary:   darkMode ? "#0a0a0a" : "#ffffff"
    property color bgSecondary: darkMode ? "#111111" : "#f5f5f5"
    property color bgTertiary:  darkMode ? "#1a1a1a" : "#e8e8e8"
    property color bgCard:      darkMode ? "#151515" : "#f9f9f9"
    property color bgInput:     darkMode ? "#1e1e1e" : "#ffffff"
    property color bgHover:     darkMode ? "#222222" : "#e0e0e0"
    property color bgElevated:  darkMode ? "#1c1c1c" : "#f0f0f0"

    // ── Text ────────────────────────────────────────────────────────────
    property color textPrimary:   darkMode ? "#f0f0f0" : "#1a1a1a"
    property color textSecondary: darkMode ? "#a0a0a0" : "#555555"
    property color textTertiary:  darkMode ? "#666666" : "#888888"
    property color textMuted:     darkMode ? "#444444" : "#bbbbbb"

    // ── Accent ──────────────────────────────────────────────────────────
    property color accent:       "#2196F3"
    property color accentLight:  darkMode ? "#64B5F6" : "#1E88E5"
    property color accentDim:    darkMode ? "#1565C0" : "#90CAF9"

    // ── Semantic ────────────────────────────────────────────────────────
    property color success:   darkMode ? "#34c759" : "#2da44e"
    property color error:     darkMode ? "#ff453a" : "#d1242f"
    property color warning:   darkMode ? "#ffd60a" : "#bf8700"
    property color info:      darkMode ? "#5ac8fa" : "#0969da"

    // ── Border / Dividers ───────────────────────────────────────────────
    property color border:    darkMode ? "#222222" : "#d8d8d8"
    property color divider:   darkMode ? "#1e1e1e" : "#e5e5e5"

    // ── HTML color strings (for rich text in AssistantMessage) ──────────
    property string htmlTextColor:    darkMode ? "#c8c8c8" : "#1a1a1a"
    property string htmlBoldColor:    darkMode ? "#e8e8e8" : "#111111"
    property string htmlHeadColor:    darkMode ? "#f0f0f0" : "#111111"
    property string htmlBulletColor:  darkMode ? "#666666" : "#999999"
    property string htmlCodeBg:       darkMode ? "#141414" : "#f0f4f8"
    property string htmlCodeColor:    darkMode ? "#d4d4d4" : "#1a1a1a"
    property string htmlCodeBorder:   darkMode ? "#222222" : "#d0d7de"
    property string htmlInlineCodeBg: darkMode ? "#1a2332" : "#dbeafe"
    property string htmlInlineCodeFg: darkMode ? "#64B5F6" : "#1565C0"
    property string htmlTableHeaderBg: darkMode ? "#1a1a1a" : "#f0f0f0"
    property string htmlTableRowAlt:   darkMode ? "#111111" : "#f8f8f8"
    property string htmlTableRowBg:    darkMode ? "#0d0d0d" : "#ffffff"
    property string htmlTableBorder:   darkMode ? "#222222" : "#e0e0e0"
    property string htmlTableHeadText: darkMode ? "#e0e0e0" : "#333333"
    property string htmlTableCellText: darkMode ? "#b0b0b0" : "#444444"
    property string htmlHrColor:       darkMode ? "#262626" : "#e0e0e0"
    property string htmlNumColor:      darkMode ? "#64B5F6" : "#1565C0"

    // ── Typography ──────────────────────────────────────────────────────
    readonly property string fontFamily: "Inter, SF Pro Display, Segoe UI, system-ui, sans-serif"
    readonly property string monoFont:   "JetBrains Mono, SF Mono, Consolas, monospace"

    // ── Radius ──────────────────────────────────────────────────────────
    readonly property int radiusSmall:  6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge:  16

    // ── Animation ───────────────────────────────────────────────────────
    readonly property int animFast:    150
    readonly property int animNormal:  250
    readonly property int animSlow:    400
}
